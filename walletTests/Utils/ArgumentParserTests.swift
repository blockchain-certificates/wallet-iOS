//
//  ArgumentParserTests.swift
//  wallet
//
//  Created by Chris Downie on 6/16/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

class ArgumentParserTests: XCTestCase {
    let parser = ArgumentParser()
    
    func testEmptyArguments() {
        let config = parser.parse(arguments: [String]())
        XCTAssertFalse(config.shouldDeletePassphrase)
        XCTAssertFalse(config.shouldDeleteIssuersAndCertificates)
        XCTAssertFalse(config.shouldDeleteCertificates)
        XCTAssertFalse(config.shouldResetAfterConfiguring)
    }
    
    func testResetArgumentWithString() {
        let config = parser.parse(arguments: [Arguments.resetData.rawValue])
        
        XCTAssert(config.shouldDeletePassphrase)
        XCTAssert(config.shouldDeleteIssuersAndCertificates)
        XCTAssert(config.shouldDeleteCertificates)
    }
    
    func testResetArgument() {
        let config = parser.parse(arguments: [Arguments.resetData])
        
        XCTAssert(config.shouldDeletePassphrase)
        XCTAssert(config.shouldDeleteIssuersAndCertificates)
        XCTAssert(config.shouldDeleteCertificates)
    }

}
