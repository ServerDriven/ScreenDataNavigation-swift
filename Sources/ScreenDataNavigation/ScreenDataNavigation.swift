import ScreenData
import Combine
import Foundation
import FLet

// MARK: ScreenProviding

public protocol ScreenProviding {
    func screen(forID id: String) -> AnyPublisher<SomeScreen, Error>
}

// MARK: ScreenProviding Basic Implementation
public struct MockScreenProvider: ScreenProviding {
    public var mockScreen: SomeScreen
    
    public init(mockScreen: SomeScreen) {
        self.mockScreen = mockScreen
    }
    
    public func screen(forID id: String) -> AnyPublisher<SomeScreen, Error> {
        Future { promise in
            var screen = mockScreen
            screen.id = id
            promise(.success(screen))
        }
        .eraseToAnyPublisher()
    }
}

public struct URLScreenProvider: ScreenProviding {
    public enum URLScreenProviderError: Error {
        case noResponse
        case noData
    }
    
    public var baseURL: URL
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    public func screen(forID id: String) -> AnyPublisher<SomeScreen, Error> {
        Future { promise in
            __.transput.url.in(
                url: baseURL.appendingPathComponent(id),
                successHandler: { (screen: SomeScreen, response) in
                    promise(.success(screen))
                },
                errorHandler: { promise(.failure($0)) },
                noResponseHandler: { promise(.failure(URLScreenProviderError.noResponse)) },
                failureHandler: { _ in promise(.failure(URLScreenProviderError.noData)) },
                decodingErrorHandler: { promise(.failure($0)) }
            )
        }
        .eraseToAnyPublisher()
    }
}

public struct FileScreenProvider: ScreenProviding {
    public enum FileScreenProviderError: Error {
        case noData
    }
    
    public var baseKey: String
    
    public init(baseKey: String) {
        self.baseKey = baseKey
    }
    
    public func screen(forID id: String) -> AnyPublisher<SomeScreen, Error> {
        Future { promise in
            do {
                promise(.success(try __.transput.file.in(filename: key(forID: id))))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func key(forID id: String) -> String {
        "\(baseKey)-\(id)".replacingOccurrences(of: "/", with: "-")
    }
    
    public func hasScreen(forId id: String) -> Bool {
        (try? __.transput.file.documentDirectoryURL.appendingPathComponent(key(forID: id)).checkResourceIsReachable()) ?? false
    }
}

// MARK: ScreenStoring
public protocol ScreenStoring {
    func store(screens: [SomeScreen]) -> AnyPublisher<Void, Error>
}

// MARK: ScreenStoring File Implementation
public struct FileScreenStore: ScreenStoring {
    public var baseKey: String
    
    public init(baseKey: String) {
        self.baseKey = baseKey
    }
    
    public func store(screens: [SomeScreen]) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try screens.forEach { screen in
                    try __.transput.file.out(screen, filename: key(forID: screen.id ?? ""))
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func key(forID id: String) -> String {
        "\(baseKey)-\(id)".replacingOccurrences(of: "/", with: "-")
    }
}

// MARK: ScreenLoading
public protocol ScreenLoading {
    func load(withProvider provider: ScreenProviding) -> AnyPublisher<[SomeScreen], Error>
}

// MARK: ScreenLoading Basic Implementation
extension SomeScreen: ScreenLoading {
    
    public func load(withProvider provider: ScreenProviding) -> AnyPublisher<[SomeScreen], Error> {
        Publishers.MergeMany(
            destinations.filter { $0.type == .screen }
                .map { destination in
                    provider.screen(forID: destination.toID)
                }
        )
        .collect()
        .eraseToAnyPublisher()
    }
}

public extension SomeView {
    var destinations: [Destination] {
        guard let someContainer = someContainer else {
            if let someLabel = someLabel,
               let destination = someLabel.destination {
                return [destination]
            } else if let someImage = someImage,
                      let destination = someImage.destination {
                return [destination]
            } else if let someCustomView = someCustomView {
                let destinations = [someCustomView.destination,
                                    someCustomView.someImage?.destination]
                    .compactMap { $0 }
                guard let subViewDestinations = someCustomView.views?
                        .map(\.destinations)
                        .reduce([], +) else {
                    return destinations
                }
                
                return destinations + subViewDestinations
            }
            
            return []
        }
        
        return someContainer.views
            .map(\.destinations)
            .reduce([], +)
    }
}

public extension SomeScreen {
    var destinations: [Destination] {
        let headerViewDestinations = headerView?.destinations ?? []
        let footerViewDestinations = footerView?.destinations ?? []
        
        return headerViewDestinations +
            someView.destinations +
            footerViewDestinations
    }
}
