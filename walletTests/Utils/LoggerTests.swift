//
//  LoggerTests.swift
//  certificatesTests
//
//  Created by Chris Downie on 10/25/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest


class LoggerTests: XCTestCase {
    func testBasicLogging() {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("test1")
        let l = Logger(logFile: file)
        
        l.debug("Debug String")
        l.info("Info String")
        l.warning("Warning String")
        l.error("Error String")
        l.fatal("Fatal String")
        
        l.flushLogs()
        
        let fileData = FileManager.default.contents(atPath: file.path)
        XCTAssertNotNil(fileData)
        let contents = String(data: fileData!, encoding: .utf8)
        XCTAssertNotNil(contents)
        print(contents!)
    }
}
