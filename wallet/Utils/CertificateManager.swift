//
//  CertificateManager.swift
//  wallet
//
//  Created by Chris Downie on 6/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import Foundation
import Blockcerts

struct CertificateManager {
    let readDirectory : URL
    let writeDirectory : URL
    
    init(readFrom: URL = Paths.certificatesDirectory, writeTo: URL = Paths.certificatesDirectory) {
        readDirectory = readFrom
        writeDirectory = writeTo
    }
    
    func loadCertificates() -> [Certificate] {
        let existingFiles = try? FileManager.default.contentsOfDirectory(at: readDirectory, includingPropertiesForKeys: nil, options: [])
        let files = existingFiles ?? []
        
        let loadedCertificates : [Certificate] = files.flatMap { fileURL in
            guard let data = try? Data(contentsOf: fileURL) else {
                return nil
            }
            return try? CertificateParser.parse(data: data)
        }

        return loadedCertificates
    }
    
    // TODO: Make this throw if any one of the certificates fails to save?
    
    func save(certificates: [Certificate]) {
        // Make sure the `certificatesDirectory` exists by trying to create it every time.
        try? FileManager.default.createDirectory(at: writeDirectory, withIntermediateDirectories: false, attributes: nil)
        
        for certificate in certificates {
            guard let fileName = certificate.filename else {
                print("ERROR: Couldn't convert \(certificate.title) to character encoding.")
                continue
            }
            let fileURL = writeDirectory.appendingPathComponent(fileName)
            do {
                try certificate.file.write(to: fileURL)
            } catch {
                print("ERROR: Couldn't save \(certificate.title) to \(fileURL): \(error)")
                dump(certificate)
                // TODO: Remove this fatalError call. It's really just in here during development.
                fatalError()
            }
        }
    }
    
    
    func save(certificate: Certificate) {
        var certificates = loadCertificates()
        certificates.append(certificate)
        save(certificates: certificates)
    }
    
    func load(certificateAt url: URL) -> Certificate? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let formatQueryItem = URLQueryItem(name: "format", value: "json")
        
        if components?.queryItems == nil {
            components?.queryItems = [
                formatQueryItem
            ]
        } else {
            components?.queryItems?.append(formatQueryItem)
        }
        
        var data: Data? = nil
        if let dataURL = components?.url {
            // TODO: I believe Data(contentsOf: ) is disfavored in place of a true data task.
            data = try? Data(contentsOf: dataURL)
        }

        guard let certificateData = data else {
            return nil
        }
        
        do {
            let certificate = try CertificateParser.parse(data: certificateData)
            return certificate
        } catch {
            print("Certificate failed to parse with \(error)")
        }

        return nil
    }
}
