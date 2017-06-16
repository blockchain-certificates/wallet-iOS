//
//  ArgumentParser.swift
//  wallet
//
//  Created by Chris Downie on 6/16/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import Foundation

struct AppConfiguration {
    let shouldDeletePassphrase: Bool
    let shouldDeleteIssuersAndCertificates: Bool
    let shouldDeleteCertificates: Bool
    let shouldResetAfterConfiguring: Bool
    
    init(shouldDeletePassphrase: Bool = false,
         shouldDeleteIssuersAndCertificates: Bool = false,
         shouldDeleteCertificates: Bool = false,
         shouldResetAfterConfiguring: Bool = false) {
        self.shouldDeletePassphrase = shouldDeletePassphrase
        self.shouldDeleteIssuersAndCertificates = shouldDeleteIssuersAndCertificates
        self.shouldDeleteCertificates = shouldDeleteIssuersAndCertificates || shouldDeleteCertificates
        self.shouldResetAfterConfiguring = shouldResetAfterConfiguring
    }
    
    public static let asIs = AppConfiguration()
    public static let resetEverything = AppConfiguration(
        shouldDeletePassphrase: true,
        shouldDeleteIssuersAndCertificates: true,
        shouldDeleteCertificates: true,
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
        var shouldDeletePassphrase = false
        var shouldDeleteIssuersAndCertificates = false
        let shouldDeleteCertificates = false
        let shouldResetAfterConfiguring = false
        
        if arguments.contains(Arguments.resetData) {
            shouldDeletePassphrase = true
            shouldDeleteIssuersAndCertificates = true
        }
        
        return AppConfiguration(
            shouldDeletePassphrase: shouldDeletePassphrase,
            shouldDeleteIssuersAndCertificates: shouldDeleteIssuersAndCertificates,
            shouldDeleteCertificates: shouldDeleteCertificates,
            shouldResetAfterConfiguring: shouldResetAfterConfiguring
        )
    }
}

struct ConfigurationManager {
    func configure(with configuration: AppConfiguration) {
        if configuration.shouldDeletePassphrase {
            deletePassphrase()
        }
        
        if configuration.shouldDeleteIssuersAndCertificates {
            deleteIssuersAndCertifiates()
        } else if configuration.shouldDeleteCertificates {
            deleteCertificates()
        }
        
        if configuration.shouldResetAfterConfiguring {
            // Eventually, this would be great if the app could jsut reset itself. For now, crash to force a reset.
            fatalError("Crash requested by configuration change.")
        }
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
