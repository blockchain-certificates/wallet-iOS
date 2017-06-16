//
//  OnboardingUITests.swift
//  wallet
//
//  Created by Chris Downie on 6/16/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

class OnboardingUITests: XCTestCase {
        
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
    
    func testGeneratedPasswordMatchesSettigsPassword() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        
        let app = XCUIApplication()
        
        // After the onboarding flow
        app.navigationBars["Issuers"].buttons["Settings"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Reveal Passphrase"].tap()
        app.typeText("s\n")
        tablesQuery.staticTexts["view virtual ice oven upon material humor vague vessel jacket aim clarify moral gesture canvas wing shoot average charge section issue inmate waste large"].tap()
        tablesQuery.staticTexts["Current Passphrase"].tap()
        
    }
    
}
