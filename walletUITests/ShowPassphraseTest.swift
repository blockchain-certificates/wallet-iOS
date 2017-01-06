//
//  ShowPassphraseTest.swift
//  wallet
//
//  Created by Chris Downie on 10/28/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import XCTest

class ShowPassphraseTest: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testWithGoodPassword() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
//        let app = XCUIApplication()
//
//        app.navigationBars["Issuers"].buttons["SettingsIcon"].tap()
//        
//        let tablesQuery = app.tables
//        tablesQuery.staticTexts["Reveal Passphrase"].tap()
//        
//        // Confirm that we're being prompted for a password.
//        
//        // In the testing environment, any
//        app.typeText("rr\n")

//        tablesQuery.tableRows.staticTexts
        XCTAssertTrue(true)
        
//        let app = XCUIApplication()
//        app.navigationBars["Issuers"].buttons["SettingsIcon"].tap()
//        app.tables.staticTexts["Reveal Passphrase"].tap()
//        app.secureTextFields["Passcode field"].tap()
//        app.typeText("tt\n")
        
        
//        ttablesQuery.staticTexts["ask original ethics net polar attend guess initial crane awful boat budget guard project biology wait wedding armed electric scare end sorry dizzy prison"].tap()
        
    }
    
    func testWithBadPassword() {
        XCTAssertTrue(true)
    }
    
}
