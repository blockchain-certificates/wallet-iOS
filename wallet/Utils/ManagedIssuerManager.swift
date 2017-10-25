//
//  ManagedIssuerManager.swift
//  wallet
//
//  So sorry for that name, by the way. That's definitely a bit unfortunate. sigh.
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
            if let jsonData = FileManager.default.contents(atPath: issuerReadURL.path) {
                let decoder = JSONDecoder()
                do {
                    let issuerList = try decoder.decode(ManagedIssuerList.self, from: jsonData)
                    loadedIssuers = issuerList.managedIssuers
                } catch {
                    Logger.main.error("Failed to decode file at \(issuerReadURL)")
                }
            } else {
                Logger.main.error("MIM had no data at \(issuerReadURL.path)")
            }
        } else if let oldReadURL = backwardsCompatibilityURL {
            loadedIssuers = NSKeyedUnarchiver.unarchiveObject(withFile: oldReadURL.path) as? [ManagedIssuer]
            Logger.main.debug("Loading issuers from the old read URL")
        }
        
        Logger.main.debug("Loaded \(loadedIssuers?.count ?? -1) from disk")
        
        return loadedIssuers ?? []
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
}

