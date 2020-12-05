import ScreenData
import Combine
import Foundation

// MARK: ScreenProviding

public protocol ScreenProviding {
    func screen(forID id: String) -> Future<SomeScreen, Error>
}

// MARK: ScreenProviding Basic Implementation

public struct MockScreenProvider: ScreenProviding {
    public var mockScreen: SomeScreen
    
    public init(mockScreen: SomeScreen) {
        self.mockScreen = mockScreen
    }
    
    public func screen(forID id: String) -> Future<SomeScreen, Error> {
        Future { promise in
            var screen = mockScreen
            screen.id = id
            promise(.success(screen))
        }
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
    
    public func screen(forID id: String) -> Future<SomeScreen, Error> {
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
            }
        }
    }
}

public struct UserDefaultScreenProvider: ScreenProviding {
    public enum UserDefaultScreenProviderError: Error {
        case noData
    }
    
    public var baseKey: String
    
    public init(baseKey: String) {
        self.baseKey = baseKey
    }
    
    public func screen(forID id: String) -> Future<SomeScreen, Error> {
        Future { promise in
            guard let data = UserDefaults.standard.data(forKey: baseKey + id) else {
                promise(.failure(UserDefaultScreenProviderError.noData))
                return
            }
            
            do {
                promise(.success(try JSONDecoder().decode(SomeScreen.self, from: data)))
            } catch {
                promise(.failure(error))
            }
        }
    }
}

// MARK: ScreenStoring
public protocol ScreenStoring {
    func store(screens: [SomeScreen]) -> Future<Void, Error>
}

// MARK: ScreenStoring Basic Implementation

public struct UserDefaultScreenStorer: ScreenStoring {
    public var baseKey: String
    
    public init(baseKey: String) {
        self.baseKey = baseKey
    }
    
    public func store(screens: [SomeScreen]) -> Future<Void, Error> {
        Future { promise in
            do {
                try screens.forEach { screen in
                    let data = try JSONEncoder().encode(screen)
                    let key = baseKey + (screen.id ?? "")
                    UserDefaults.standard.set(data,
                                              forKey: key)
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
    }
}

// MARK: ScreenLoading
public protocol ScreenLoading {
    func load(withProvider provider: ScreenProviding) -> Future<[SomeScreen], Error>
}

// MARK: ScreenLoading Basic Implementation [WIP]
//
//extension SomeScreen: ScreenLoading {
//    
//    public func load(withProvider provider: ScreenProviding) -> Future<[SomeScreen], Error> {
//        Future { promise in
//            var bag = [AnyCancellable]()
//            var screens = [SomeScreen]()
//            
//            Publishers.MergeMany(
//                destinations
//                    .filter { $0.type == .screen }
//                    .map { destination in
//                        provider.screen(forID: destination.toID)
//                    }.lazy
//                    .publisher
//                    .collect()
//            )
//            .sink(receiveCompletion: { _ in }) { (result) in
//                
////                result.forEach { futureScreen in
////                    futureScreen
////                        .sink(receiveCompletion: { _ in }) { (screen) in
////                            screens.append(screen)
////                        }
////                        .store(in: &bag)
////                }
//            }
//            .store(in: &bag)
//            
//        }
//    }
//}

public extension SomeView {
    var destinations: [Destination] {
        guard let someContainer = someContainer else {
            if let someLabel = someLabel,
               let destination = someLabel.destination {
                return [destination]
            } else if let someImage = someImage,
                      let destination = someImage.destination {
                return [destination]
            } else if let someLabeledImage = someLabeledImage {
                return [someLabeledImage.destination,
                        someLabeledImage.someImage.destination]
                    .compactMap { $0 }
            } else if let someCustomView = someCustomView {
                let destinations = [someCustomView.destination,
                                    someCustomView.someImage?.destination]
                    .compactMap { $0 }
                let subViewDestinations = someCustomView.views
                    .map(\.destinations)
                    .reduce([], +)
                
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
