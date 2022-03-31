import Combine
import t
import XCTest
import ScreenData
@testable import ScreenDataNavigation

final class ScreenDataNavigationTests: XCTestCase {
    func testScreenDestinations() {
        let destinations = [
            Destination(type: .url, toID: "https://github.com/ServerDriven/ScreenData"),
            Destination(type: .screen, toID: "/some/data/5")
        ]
        
        let screen = SomeScreen(title: "Title",
                                backgroundColor: SomeColor(red: 0, green: 0, blue: 0),
                                headerView: SomeView(type: .container, someContainer: SomeContainerView(isScrollable: true, axis: .vertical, views: [
                                    SomeView(type: .label, someLabel: SomeLabel(title: "Hello World", subtitle: nil, font: .largeTitle, style: nil, destination: Destination(type: .url, toID: "https://github.com/ServerDriven/ScreenData")))
                                ], style: nil)),
                                someView: SomeView(type: .label, someLabel: SomeLabel(title: "Hello World", subtitle: nil, font: .largeTitle, style: nil, destination: Destination(type: .screen, toID: "/some/data/5"))))
        
        XCTAssertEqual(
            destinations.map { $0.toID },
            screen.destinations.map { $0.toID }
        )
    }
    
    func testMockScreenService() {
        let mockScreen = SomeScreen(id: "mock-id", title: "Mock", backgroundColor: .init(red: 0, green: 0, blue: 0), someView: SomeSpacer(size: -1).someView)
        let provider = MockScreenProvider(mockScreen: mockScreen)
        
        XCTAssert(
            t.suite {
                var task: AnyCancellable?
                var providedScreen: SomeScreen?
                try t.async(
                    "that the MockScreenProvider provides the mock screen it was given.",
                    expect: {
                        try t.assert(isNotNil: providedScreen)
                        try t.assert(providedScreen, isEqualTo: mockScreen)
                    },
                    eventually: { completion in
                        t.log("Getting screen from provider...")
                        task = provider.screen(forID: "mock-id")
                            .sink(
                                receiveCompletion: { _ in completion() },
                                receiveValue: {
                                    providedScreen = $0
                                    t.log("Got a Screen! (\($0))")
                                }
                            )
                    }
                )
                
                try t.assert(isNotNil: task)
            }
        )
    }
}
