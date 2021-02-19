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

// MARK: ScreenStoring
// Store SomeScreens for later

public protocol ScreenStoring {
    func store(screens: [SomeScreen]) -> AnyPublisher<Void, Error>
}

public struct UserDefaultScreenStorer: ScreenStoring {
    // ...
}
```
