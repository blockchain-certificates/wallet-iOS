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
        do {
            let jsonData = try Data(contentsOf: issuerReadURL)
            
            let decoder = JSONDecoder()
            let issuerList = try decoder.decode(ManagedIssuerList.self, from: jsonData)
            loadedIssuers = issuerList.managedIssuers
        } catch {
            if let oldReadURL = backwardsCompatibilityURL {
                loadedIssuers = NSKeyedUnarchiver.unarchiveObject(withFile: oldReadURL.path) as? [ManagedIssuer]
            }
        }
        
        return loadedIssuers ?? []
    }
    
    public func save(_ managedIssuers: [ManagedIssuer]) -> Bool {
        let list = ManagedIssuerList(managedIssuers: managedIssuers)
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(list)
            let success = FileManager.default.createFile(atPath: issuerWriteURL.path, contents: data, attributes: nil)
            return success
        } catch {
            print("An exception was thrown saving the managed issuers list: \(error)")
            return false
        }
    }
}

