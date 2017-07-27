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
    let shouldSetPassphraseTo: String?
    
    init(shouldDeletePassphrase: Bool = false,
         shouldDeleteIssuersAndCertificates: Bool = false,
         shouldDeleteCertificates: Bool = false,
         shouldResetAfterConfiguring: Bool = false,
         shouldSetPassphraseTo: String? = nil) {
        self.shouldDeletePassphrase = shouldDeletePassphrase
        self.shouldDeleteIssuersAndCertificates = shouldDeleteIssuersAndCertificates
        self.shouldDeleteCertificates = shouldDeleteIssuersAndCertificates || shouldDeleteCertificates
        self.shouldResetAfterConfiguring = shouldResetAfterConfiguring
        self.shouldSetPassphraseTo = shouldSetPassphraseTo
    }
    
    public static let asIs = AppConfiguration()
    public static let resetEverything = AppConfiguration(
        shouldDeletePassphrase: true,
        shouldDeleteIssuersAndCertificates: true,
        shouldDeleteCertificates: true,
        shouldResetAfterConfiguring: false
    )
}

enum ArgumentLabels : String {
    case resetData = "--reset-data"
    case usePassphrase = "--use-passphrase"
}

enum Argument {
    case resetData
    case using(passphrase: String)
    
    static func from(array: [String]) -> [Argument] {
        var args = [Argument]()
        var index = 0
        while index < array.count {
            switch array[index] {
            case ArgumentLabels.resetData.rawValue:
                args.append(.resetData)
            case ArgumentLabels.usePassphrase.rawValue:
                index += 1
                args.append(.using(passphrase: array[index]))
            default:
                print("Unknown argument \(array[index]):  Ignoring.")
            }
            index += 1
        }
        
        return args
    }
}

extension Argument : Equatable {
    public static func ==(lhs: Argument, rhs: Argument) -> Bool {
        switch (lhs, rhs) {
        case (.resetData, .resetData):
            return true
        case (.using(let left), .using(let right)):
            return left == right
        default:
            return false
        }
    }
}


struct ArgumentParser {
    func parse(arguments stringArguments: [String]) -> AppConfiguration {
        let arguments = Argument.from(array: stringArguments)
        return parse(arguments: arguments)
    }
    
    func parse(arguments: [Argument]) -> AppConfiguration {
        var shouldDeletePassphrase = false
        var shouldDeleteIssuersAndCertificates = false
        let shouldDeleteCertificates = false
        let shouldResetAfterConfiguring = false
        var shouldSetPassphraseTo : String? = nil

        for arg in arguments {
            if arg == .resetData {
                shouldDeletePassphrase = true
                shouldDeleteIssuersAndCertificates = true
            }
            if case .using(let passphrase) = arg {
                shouldSetPassphraseTo = passphrase
            }
        }
        if arguments.contains(Argument.resetData) {
            
        }
        
        return AppConfiguration(
            shouldDeletePassphrase: shouldDeletePassphrase,
            shouldDeleteIssuersAndCertificates: shouldDeleteIssuersAndCertificates,
            shouldDeleteCertificates: shouldDeleteCertificates,
            shouldResetAfterConfiguring: shouldResetAfterConfiguring,
            shouldSetPassphraseTo: shouldSetPassphraseTo
        )
    }
}

struct ConfigurationManager {
    func configure(with configuration: AppConfiguration) throws {
        if configuration.shouldDeletePassphrase || configuration.shouldSetPassphraseTo != nil {
            deletePassphrase()
        }
        
        if configuration.shouldDeleteIssuersAndCertificates {
            deleteIssuersAndCertifiates()
        } else if configuration.shouldDeleteCertificates {
            deleteCertificates()
        }
        
        if let newPassphrase = configuration.shouldSetPassphraseTo {
            try Keychain.updateShared(with: newPassphrase)
        }
        
        if configuration.shouldResetAfterConfiguring {
            // Eventually, this would be great if the app could jsut reset itself. For now, crash to force a reset.
            fatalError("Crash requested by configuration change.")
        }
    }
    
    private func deletePassphrase() {
        Keychain.destroyShared()
    }
    
    // Why no "deleteIssuers"? If you delete issuers and leave their underlying certificates, the issuers will re-populate
    // when loading the certificates. If your intention is to delete issuers, then you'd need to delete the underlying
    // certificates as well.
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
