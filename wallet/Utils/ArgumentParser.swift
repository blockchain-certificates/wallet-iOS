//
//  ArgumentParser.swift
//  wallet
//
//  Created by Chris Downie on 6/16/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import Foundation

struct AppConfiguration {
    let shouldDeleteAllData: Bool
    let shouldDeleteIssuersAndCertificates: Bool
    let shouldDeleteCertificates: Bool
}

enum Arguments : String {
    case resetData = "--reset-data"
    case usePassphrase = "--use-passphrase"
}

struct ArgumentParser {
    func parse(arguments: [String]) -> AppConfiguration {
        let shouldDeleteAllData = arguments.contains(Arguments.resetData.rawValue)
        
        return AppConfiguration(
            shouldDeleteAllData: shouldDeleteAllData,
            shouldDeleteIssuersAndCertificates: false,
            shouldDeleteCertificates: false
        )
    }
}
