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
    
    public static let asIs = AppConfiguration(
        shouldDeleteAllData: false,
        shouldDeleteIssuersAndCertificates: false,
        shouldDeleteCertificates: false
    )
}

enum Arguments : String {
    case resetData = "--reset-data"
    case usePassphrase = "--use-passphrase"
}

struct ArgumentParser {
    func parse(arguments stringArguments: [String]) -> AppConfiguration {
        let arguments = stringArguments.flatMap { return Arguments(rawValue: $0) }
        return parse(arguments: arguments)
    }
    
    func parse(arguments: [Arguments]) -> AppConfiguration {
        let shouldDeleteAllData = arguments.contains(Arguments.resetData)
        
        return AppConfiguration(
            shouldDeleteAllData: shouldDeleteAllData,
            shouldDeleteIssuersAndCertificates: false,
            shouldDeleteCertificates: false
        )
    }
}
