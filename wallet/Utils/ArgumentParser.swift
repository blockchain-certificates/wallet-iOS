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
    let shouldLoadIssuersFrom: URL?
    let shouldLoadCertificatesFrom: URL?
    
    init(shouldDeletePassphrase: Bool = false,
         shouldDeleteIssuersAndCertificates: Bool = false,
         shouldDeleteCertificates: Bool = false,
         shouldResetAfterConfiguring: Bool = false,
         shouldSetPassphraseTo: String? = nil,
         shouldLoadIssuersFrom: URL? = nil,
         shouldLoadCertificatesFrom: URL? = nil) {
        self.shouldDeletePassphrase = shouldDeletePassphrase
        self.shouldDeleteIssuersAndCertificates = shouldDeleteIssuersAndCertificates
        self.shouldDeleteCertificates = shouldDeleteIssuersAndCertificates || shouldDeleteCertificates
        self.shouldResetAfterConfiguring = shouldResetAfterConfiguring
        self.shouldSetPassphraseTo = shouldSetPassphraseTo
        self.shouldLoadIssuersFrom = shouldLoadIssuersFrom
        self.shouldLoadCertificatesFrom = shouldLoadCertificatesFrom
    }
    
    public static let asIs = AppConfiguration()
    public static let resetEverything = AppConfiguration(
        shouldDeletePassphrase: true,
        shouldDeleteIssuersAndCertificates: true,
        shouldDeleteCertificates: true,
        shouldResetAfterConfiguring: false
    )
}

extension AppConfiguration : CustomStringConvertible {
    var description : String {
        var result = "This config should...\n"
        if shouldDeletePassphrase {
            result += "  ...delete the passphrase\n"
        }
        if shouldDeleteIssuersAndCertificates {
            result += "  ...delete the issuers & certificates\n"
        }
        if shouldDeleteCertificates {
            result += "  ...delete the certificates\n"
        }
        if let newPassphrase = shouldSetPassphraseTo {
            result += "  ...set the passphrase to \(newPassphrase)\n"
        }
        if let issuerURL = shouldLoadIssuersFrom {
            result += "  ...load issuers from \(issuerURL)\n"
        }
        if shouldResetAfterConfiguring {
            result += "  ...and reset after configuring\n"
        }
        return result
    }
}

enum ArgumentLabels : String {
    case resetData = "--reset-data"
    case usePassphrase = "--use-passphrase"
    case useIssuerData = "--use-issuer-data"
    case useCertificatesInDirectory = "--use-certificates-in-directory"
}

enum Argument {
    case resetData
    case using(passphrase: String)
    case usingIssuerData(from: URL)
    case usingCertificates(from: URL)
    
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
            case ArgumentLabels.useIssuerData.rawValue:
                index += 1
                if let url = URL(string: array[index]) {
                    args.append(.usingIssuerData(from: url))
                } else {
                    print("\(ArgumentLabels.useIssuerData.rawValue) observed, but \(array[index]) isn't a valid URL.")
                }
            case ArgumentLabels.useCertificatesInDirectory.rawValue:
                index += 1
                if let url = URL(string: array[index]) {
                    args.append(.usingCertificates(from: url))
                } else {
                    print("\(ArgumentLabels.useCertificatesInDirectory.rawValue) observed, but \(array[index]) isn't a valid URL.")
                }
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
        case (.usingIssuerData(let left), .usingIssuerData(let right)):
            return left == right
        case (.usingCertificates(let left), .usingCertificates(let right)):
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
        var shouldLoadIssuersFrom: URL? = nil
        var shouldLoadCertificatesFrom: URL? = nil

        for arg in arguments {
            if arg == .resetData {
                shouldDeletePassphrase = true
                shouldDeleteIssuersAndCertificates = true
            }
            if case .using(let passphrase) = arg {
                shouldSetPassphraseTo = passphrase
            }
            if case .usingIssuerData(let url) = arg {
                shouldLoadIssuersFrom = url
            }
            if case .usingCertificates(let url) = arg {
                shouldLoadCertificatesFrom = url
            }
        }
        
        return AppConfiguration(
            shouldDeletePassphrase: shouldDeletePassphrase,
            shouldDeleteIssuersAndCertificates: shouldDeleteIssuersAndCertificates,
            shouldDeleteCertificates: shouldDeleteCertificates,
            shouldResetAfterConfiguring: shouldResetAfterConfiguring,
            shouldSetPassphraseTo: shouldSetPassphraseTo,
            shouldLoadIssuersFrom: shouldLoadIssuersFrom,
            shouldLoadCertificatesFrom: shouldLoadCertificatesFrom
        )
    }
}

struct ConfigurationManager {
    func configure(with configuration: AppConfiguration) throws {
        print(configuration)
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
        
        if let issuerLoadURL = configuration.shouldLoadIssuersFrom {
            let sideloadManager = ManagedIssuerManager(readFrom: issuerLoadURL,
                                                       writeTo: Paths.managedIssuersListURL,
                                                       convertFrom: issuerLoadURL)
            var issuers = sideloadManager.load()
            let manager = ManagedIssuerManager()
            
            if !configuration.shouldDeleteIssuersAndCertificates {
                issuers.append(contentsOf: manager.load())
            }

            _ = manager.save(issuers)
        }
        
        if let certificateDirectory = configuration.shouldLoadCertificatesFrom {
            let sideloadManager = CertificateManager(readFrom: certificateDirectory, writeTo: certificateDirectory)
            var certificates = sideloadManager.loadCertificates()
            
            let manager = CertificateManager()
            certificates.append(contentsOf: manager.loadCertificates())
            manager.save(certificates: certificates)
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
        if FileManager.default.fileExists(atPath: Paths.issuersNSCodingArchiveURL.path) {
            do {
                try FileManager.default.removeItem(at: Paths.issuersNSCodingArchiveURL)
            } catch {
                print("Failed to delete the old nscoding issuers archive. Error: \(error)")
            }
        }
        
        if FileManager.default.fileExists(atPath: Paths.managedIssuersListURL.path) {
            do {
                try FileManager.default.removeItem(at: Paths.managedIssuersListURL)
            } catch {
                print("Something went wrong deleting issuers... Error: \(error)")
            }
        }
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
