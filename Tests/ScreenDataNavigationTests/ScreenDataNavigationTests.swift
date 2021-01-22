import XCTest
import ScreenData
@testable import ScreenDataNavigation

final class ScreenDataNavigationTests: XCTestCase {
    func testExample() {
        let destinations = [
            Destination(type: .url, toID: "https://github.com/ServerDriven/ScreenData"),
            Destination(type: .screen, toID: "/some/data/5")
        ]
        
        let screen = SomeScreen(title: "Title",
                                subtitle: nil,
                                backgroundColor: SomeColor(red: 0, green: 0, blue: 0),
                                headerView: SomeView(type: .container, someContainer: SomeContainerView(isScrollable: true, axis: .vertical, views: [
                                    SomeView(type: .label, someLabel: SomeLabel(title: "Hello World", subtitle: nil, style: nil, destination: Destination(type: .url, toID: "https://github.com/ServerDriven/ScreenData")))
                                ], style: nil)),
                                someView: SomeView(type: .label, someLabel: SomeLabel(title: "Hello World", subtitle: nil, style: nil, destination: Destination(type: .screen, toID: "/some/data/5"))))
        
        XCTAssertEqual(destinations.map { $0.toID },
                       screen.destinations.map { $0.toID })
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
