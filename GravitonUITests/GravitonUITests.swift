//
//  GravitonUITests.swift
//  GravitonUITests
//
//  Created by Sihao Lu on 12/12/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest

class GravitonUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments.append("--ui-testing")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        app.launch()
        app.navigationBars["Graviton.ObserverView"].buttons["menu icon settings"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Debugging"]/*[[".cells.staticTexts[\"Debugging\"]",".staticTexts[\"Debugging\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Horizontal Directions"]/*[[".cells.staticTexts[\"Horizontal Directions\"]",".staticTexts[\"Horizontal Directions\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["West"]/*[[".cells.buttons[\"West\"]",".buttons[\"West\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
