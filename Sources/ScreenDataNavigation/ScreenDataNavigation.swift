import ScreenData
import Combine
import Foundation

// MARK: ScreenProviding

@available(iOS 13.0, OSX 10.15, *)
public protocol ScreenProviding {
    func screen(forID id: String) -> AnyPublisher<SomeScreen, Error>
}

// MARK: ScreenProviding Basic Implementation
@available(iOS 13.0, OSX 10.15, *)
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

@available(iOS 13.0, OSX 10.15, *)
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
            URLSession.shared.dataTask(with: baseURL.appendingPathComponent(id)) { (data, response, error) in
                if let error = error {
                    promise(.failure(error))
                }
                
                guard let _ = response else {
                    promise(.failure(URLScreenProviderError.noResponse))
                    return
                }
                
                guard let data = data else {
                    promise(.failure(URLScreenProviderError.noData))
                    return
                }
                
                do {
                    promise(.success(try JSONDecoder().decode(SomeScreen.self, from: data)))
                } catch {
                    promise(.failure(error))
                }
            }.resume()
        }
        .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, OSX 10.15, *)
public struct UserDefaultScreenProvider: ScreenProviding {
    public enum UserDefaultScreenProviderError: Error {
        case noData
    }
    
    public var baseKey: String
    
    public init(baseKey: String) {
        self.baseKey = baseKey
    }
    
    public func screen(forID id: String) -> AnyPublisher<SomeScreen, Error> {
        Future { promise in
            guard let data = UserDefaults.standard.data(forKey: key(forID: id)) else {
                promise(.failure(UserDefaultScreenProviderError.noData))
                return
            }
            
            do {
                promise(.success(try JSONDecoder().decode(SomeScreen.self, from: data)))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func key(forID id: String) -> String {
        "\(baseKey)-\(id)"
    }
    
    public func hasScreen(forId id: String) -> Bool {
        UserDefaults.standard.data(forKey: key(forID: id)) != nil
    }
}

@available(iOS 13.0, OSX 10.15, *)
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
            let path = FileManager.default.urls(
                for: .documentDirectory,
                   in: .userDomainMask
            )[0].appendingPathComponent(key(forID: id))
            
            guard let data = try? Data(contentsOf: path) else {
                promise(.failure(FileScreenProviderError.noData))
                return
            }
            
            do {
                promise(.success(try JSONDecoder().decode(SomeScreen.self, from: data)))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func key(forID id: String) -> String {
        "\(baseKey)-\(id)"
    }
    
    public func hasScreen(forId id: String) -> Bool {
        let path = FileManager.default.urls(
            for: .documentDirectory,
               in: .userDomainMask
        )[0].appendingPathComponent(key(forID: id))
        
        return (try? path.checkResourceIsReachable()) ?? false
    }
}

// MARK: ScreenStoring
@available(iOS 13.0, OSX 10.15, *)
public protocol ScreenStoring {
    func store(screens: [SomeScreen]) -> AnyPublisher<Void, Error>
}

// MARK: ScreenStoring Basic Implementation
@available(iOS 13.0, OSX 10.15, *)
public struct UserDefaultScreenStorer: ScreenStoring {
    public var baseKey: String
    
    public init(baseKey: String) {
        self.baseKey = baseKey
    }
    
    public func store(screens: [SomeScreen]) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try screens.forEach { screen in
                    let data = try JSONEncoder().encode(screen)
                    let key = self.key(forID: screen.id ?? "")
                    UserDefaults.standard.set(data,
                                              forKey: key)
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func key(forID id: String) -> String {
        "\(baseKey)-\(id)"
    }
}

// MARK: ScreenStoring File Implementation
@available(iOS 13.0, OSX 10.15, *)
public struct FileScreenStorer: ScreenStoring {
    public var baseKey: String
    
    public init(baseKey: String) {
        self.baseKey = baseKey
    }
    
    public func store(screens: [SomeScreen]) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try screens.forEach { screen in
                    let data = try JSONEncoder().encode(screen)
                    let key = self.key(forID: screen.id ?? "")
                    let path = FileManager.default.urls(
                        for: .documentDirectory,
                           in: .userDomainMask
                    )[0].appendingPathComponent(key)
                    
                    try data.write(to: path)
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func key(forID id: String) -> String {
        "\(baseKey)-\(id)"
    }
}

// MARK: ScreenLoading
@available(iOS 13.0, OSX 10.15, *)
public protocol ScreenLoading {
    func load(withProvider provider: ScreenProviding) -> AnyPublisher<[SomeScreen], Error>
}

// MARK: ScreenLoading Basic Implementation
@available(iOS 13.0, OSX 10.15, *)
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
