//
//  OnboardingUITests.swift
//  wallet
//
//  Created by Chris Downie on 6/16/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

let testPassphrase = "view virtual ice oven upon material humor vague vessel jacket aim clarify moral gesture canvas wing shoot average charge section issue inmate waste large"

class OnboardingUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        
        let app = XCUIApplication()
        app.launchArguments = [ "--reset-data" ]
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    func testGeneratedPassphraseMatchesSettingsPassphrase() {
        let app = XCUIApplication()
        app.buttons["NEW ACCOUNT"].tap()
        app.buttons["GENERATE PASSPHRASE"].tap()
        
        // Capture the generated passphrase
        let generatedPassphrase = app.staticTexts.matching(identifier: "GeneratedPassphrase").element(boundBy: 0).label
        XCTAssertFalse(generatedPassphrase.isEmpty)
        
        app.buttons["DONE"].tap()
        
        let settingsButton = app.navigationBars["certificates.IssuerCollectionView"].buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)

        // TODO: This test can really only be useful when we can compare the generated passphrase with that displayed on the settings page.
        // We'll be able to pass the touchid check in xcode 9. Just not before then.
        //        settingsButton.tap()
        //
        //        let tablesQuery = app.tables
        //        tablesQuery.staticTexts["Reveal Passphrase"].tap()
    }
    
    func testSuppliedPassphraseMatchesSettingsPassphrase() {
        let app = XCUIApplication()
        app.buttons["I ALREADY HAVE ONE"].tap()
        
        let scrollViewsQuery = app.scrollViews
        let textView = scrollViewsQuery.otherElements.containing(.image, identifier:"Logo").children(matching: .other).element.children(matching: .textView).element
        textView.tap()
        textView.typeText(testPassphrase)
        app.buttons["Done"].tap()

        let settingsButton = app.navigationBars["certificates.IssuerCollectionView"].buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)
        
        
        // TODO: This test can really only be useful when we can compare the generated passphrase with that displayed on the settings page.
        // We'll be able to pass the touchid check in xcode 9. Just not before then.
        //        settingsButton.tap()
        //
        //        let tablesQuery = app.tables
        //        tablesQuery.staticTexts["Reveal Passphrase"].tap()
    }
}

class PostOnboardingUITests : XCTestCase {
    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        app.launchArguments = [ "--reset-data", "--use-passphrase", testPassphrase ]
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    func testLandingOnIssuerScreenIfPassphraseExists() {
        let app = XCUIApplication()
        
        XCTAssertFalse(app.buttons["I ALREADY HAVE ONE"].exists)
        
        let settingsButton = app.navigationBars["certificates.IssuerCollectionView"].buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)
    }
    
}
