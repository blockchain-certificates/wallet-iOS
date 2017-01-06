//
//  AddIssuerUITests.swift
//  wallet
//
//  Created by Chris Downie on 1/6/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

class AddIssuerUITests: XCTestCase {
        
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
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let app = XCUIApplication()
        app.navigationBars["Issuers"].buttons["AddIcon"].tap()
        app.sheets.buttons["Add Issuer"].tap()

        let issuerUrlTextField = app.scrollViews.otherElements.textFields["Issuer URL"]
        issuerUrlTextField.tap()
        issuerUrlTextField.typeText("http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")
        
        let oneTimeCodeTextField = XCUIApplication().scrollViews.otherElements.textFields["One-Time Code"]
        oneTimeCodeTextField.tap()
        oneTimeCodeTextField.typeText("skfje")
        
        XCUIApplication().navigationBars["Add Issuer"].buttons["Save"].tap()
//        XCUIApplication().collectionViews.children(matching: .cell).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .image).element.tap()
        
        XCTAssert(true)
    }
    
}
