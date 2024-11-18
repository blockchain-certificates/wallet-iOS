//
//  ManagedIssuerManager.swift
//  wallet
//
//  Created by Chris Downie on 8/9/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import Foundation
import Blockcerts

struct ManagedIssuerManager {
    let issuerReadURL : URL
    let issuerWriteURL : URL
    let backwardsCompatibilityURL : URL?
    
    init(readFrom readURL: URL = Paths.managedIssuersListURL,
         writeTo writeURL: URL = Paths.managedIssuersListURL,
         convertFrom oldReadURL: URL? = Paths.issuersNSCodingArchiveURL) {
        issuerReadURL = readURL
        issuerWriteURL = writeURL
        backwardsCompatibilityURL = oldReadURL
    }
    
    public func load() -> [ManagedIssuer] {
        var loadedIssuers : [ManagedIssuer]? = nil
        // First, load from the new Codable path. If that fails, then try loading from the old NSCoding path.
        if FileManager.default.fileExists(atPath: issuerReadURL.path) {
            if var jsonData = FileManager.default.contents(atPath: issuerReadURL.path) {
//                if let str = String(data: jsonData, encoding: .utf8) {
//                    Logger.main.info("Start check of optional\n")
//                    if str.contains(";base64,Optional") {
//                        Logger.main.info("string has ;base64,Optional\n")
//                        Logger.main.info(str)
//                        
//                        let noOptionalStr = removeIssuerImageOptionalWrapper(str: str)
//                        if let updatedJsonData = noOptionalStr.data(using: .utf8) {
//                            Logger.main.info(noOptionalStr)
//                            Logger.main.info("string has been cleaned, saving now\n")
//                            jsonData = updatedJsonData
//                            let success = saveIssuersDataToFile(updatedJsonData)
//                        }
//                    }
//                }
                
                let decoder = JSONDecoder()
                do {
                    let issuerList = try decoder.decode(ManagedIssuerList.self, from: jsonData)
                    loadedIssuers = issuerList.managedIssuers
                } catch {
                    Logger.main.info(String(data: jsonData, encoding: .utf8)!)
                    Logger.main.error("Failed to decode file at \(issuerReadURL)")
                }
            } else {
                Logger.main.error("MIM had no data at \(issuerReadURL.path)")
            }
        } else if let oldReadURL = backwardsCompatibilityURL {
            loadedIssuers = NSKeyedUnarchiver.unarchiveObject(withFile: oldReadURL.path) as? [ManagedIssuer]
        }
        
        return loadedIssuers ?? []
    }
    
    private func removeIssuerImageOptionalWrapper(str: String) -> String {
        let expr = #"(data:image\\\/)([a-z]+);base64,Optional\(\\"([^"]*)\\"\)\""#
        let repl = "$1$2;base64,$3\""
        
        return str.replacingOccurrences(
            of: expr,
            with: repl,
            options: .regularExpression
        )
    }
    
    public func save(_ managedIssuers: [ManagedIssuer]) -> Bool {
        let list = ManagedIssuerList(managedIssuers: managedIssuers)
        let encoder = JSONEncoder()
        Logger.main.debug("Saving \(managedIssuers.count) managed issuers...")
        do {
            let data = try encoder.encode(list)
            let success = FileManager.default.createFile(atPath: issuerWriteURL.path, contents: data, attributes: nil)
            Logger.main.debug("...it was \(success ? "great" : "a failure")")
            return success
        } catch {
            Logger.main.error("An exception was thrown saving the managed issuers list: \(error)")
            return false
        }
    }
    
    private func saveIssuersDataToFile(_ issuersData: Data) -> Bool {
        let success = FileManager.default.createFile(atPath: issuerWriteURL.path, contents: issuersData, attributes: nil)
        Logger.main.debug("\(success ? "Issuers data saved" : "Failed to save issuers data")")
        return success
    }
}

