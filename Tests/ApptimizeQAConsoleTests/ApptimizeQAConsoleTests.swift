//
//  ApptimizeQAConsoleTests.swift
//  ApptimizeQAConsole
//
//  Copyright © 2021 Urban Airship Inc., d/b/a Airship.
//

import XCTest
@testable import ApptimizeQAConsole

final class ApptimizeQAConsoleTests: XCTestCase {
    func test_shakeGestureEnabledByDefault() throws {
        XCTAssertEqual(ApptimizeQAConsole.isShakeGestureEnabled, true)
    }

    func test_viewControllerHiddenByDefault() throws {
        XCTAssertEqual(ApptimizeQAConsole.isViewControllerPresented, false)
    }
}
