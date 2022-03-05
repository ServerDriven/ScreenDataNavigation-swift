# ScreenDataNavigation

```swift
// MARK: ScreenProviding
// Provide ScreenDataUI with SomeScreen

public protocol ScreenProviding {
    func screen(forID id: String) -> AnyPublisher<SomeScreen, Error>
}

public struct MockScreenProvider: ScreenProviding {
    // ...
}

public struct URLScreenProvider: ScreenProviding {
    // ...
}

public struct UserDefaultScreenProvider: ScreenProviding {
    // ...
}

public struct FileScreenProvider: ScreenProviding {
    // ...
}

// MARK: ScreenStoring
// Store SomeScreens for later

public protocol ScreenStoring {
    func store(screens: [SomeScreen]) -> AnyPublisher<Void, Error>
}

public struct UserDefaultScreenStorer: ScreenStoring {
    // ...
}

public struct FileScreenStore: ScreenStoring {
    // ...
}

// MARK: ScreenLoading
public protocol ScreenLoading {
    func load(withProvider provider: ScreenProviding) -> AnyPublisher<[SomeScreen], Error>
}

// MARK: ScreenLoading Basic Implementation
extension SomeScreen: ScreenLoading {
    // ...
}
```

