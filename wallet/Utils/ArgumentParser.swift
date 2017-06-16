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
    let shouldResetAfterConfiguring: Bool
    
    public static let asIs = AppConfiguration(
        shouldDeleteAllData: false,
        shouldDeleteIssuersAndCertificates: false,
        shouldDeleteCertificates: false,
        shouldResetAfterConfiguring: false
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
            shouldDeleteCertificates: false,
            shouldResetAfterConfiguring: false
        )
    }
}

struct ConfigurationManager {
    func configure(with configuration: AppConfiguration) {
        if configuration.shouldDeleteAllData {
            deleteAllData()
        }
        
        if configuration.shouldDeleteIssuersAndCertificates {
            deleteIssuersAndCertifiates()
        }
        
        if configuration.shouldDeleteCertificates {
            deleteCertificates()
        }
        
        if configuration.shouldResetAfterConfiguring {
            // Eventually, this would be great if the app could jsut reset itself. For now, crash to force a reset.
            fatalError("Crash requested by configuration change.")
        }
    }
    
    private func deleteAllData() {
        deletePassphrase()
        deleteIssuersAndCertifiates()
    }
    
    private func deletePassphrase() {
        Keychain.destroyShared()
    }
    
    private func deleteIssuersAndCertifiates() {
        deleteCertificates()

        // Delete issuers
        NSKeyedArchiver.archiveRootObject([], toFile: Paths.issuersArchiveURL.path)
    }
    
    private func deleteCertificates() {
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: Paths.certificatesDirectory.path)
            for filePath in filePaths {
                try FileManager.default.removeItem(at: Paths.certificatesDirectory.appendingPathComponent(filePath))
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
}
