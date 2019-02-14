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
    private let tag = String(describing: AddCredentialViewController.self)

    let readDirectory : URL
    let writeDirectory : URL
    
    init(readFrom: URL = Paths.certificatesDirectory, writeTo: URL = Paths.certificatesDirectory) {
        Logger.main.tag(tag).debug("init with readFrom: \(readFrom), writeTo: \(writeTo)")
        readDirectory = readFrom
        writeDirectory = writeTo
    }
    
    func loadCertificates() -> [Certificate] {
        Logger.main.tag(tag).info("loading_certificates")
        let existingFiles = try? FileManager.default.contentsOfDirectory(at: readDirectory, includingPropertiesForKeys: nil, options: [])
        let files = existingFiles ?? []

        let loadedCertificates : [Certificate] = files.compactMap { fileURL in
            Logger.main.tag(tag).debug("loading_certificate in: \(fileURL)")
            guard let data = try? Data(contentsOf: fileURL) else {
                Logger.main.tag(tag).error("data for: \(fileURL) is nil")
                return nil
            }
            Logger.main.tag(tag).info("trying parse")
            return try? CertificateParser.parse(data: data)
        }

        Logger.main.tag(tag).debug("loaded \(loadedCertificates.count) certificates from \(files.count) files")
        
        return loadedCertificates
    }
    
    // TODO: Make this throw if any one of the certificates fails to save?
    
    func save(certificates: [Certificate]) {
        // Make sure the `certificatesDirectory` exists by trying to create it every time.
        try? FileManager.default.createDirectory(at: writeDirectory, withIntermediateDirectories: false, attributes: nil)
        Logger.main.tag(tag).info("saving \(certificates.count) certificates.")
        for certificate in certificates {
            Logger.main.tag(tag).info("saving certificate \(certificate.getDebugDescription())")
            guard let fileName = certificate.filename else {
                Logger.main.tag(tag).warning("couldn't convert \(certificate.title) to character encoding.")
                continue
            }
            let fileURL = writeDirectory.appendingPathComponent(fileName)
            do {
                try certificate.file.write(to: fileURL)
            } catch {
                Logger.main.tag(tag).error("ERROR: Couldn't save \(certificate.title) to \(fileURL): \(error)")
            }
        }
    }
    
    
    func save(certificate: Certificate) {
        Logger.main.tag(tag).debug("save certificate")
        var certificates = loadCertificates()
        certificates.append(certificate)
        save(certificates: certificates)
    }
    
    func load(certificateAt url: URL) -> Certificate? {
        Logger.main.tag(tag).debug("load certificate at:\(url)")
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
            Logger.main.tag(tag).debug("load certificate data was nil")
            return nil
        }
        
        do {
            Logger.main.tag(tag).debug("trying parse")
            let certificate = try CertificateParser.parse(data: certificateData)
            return certificate
        } catch {
            Logger.main.tag(tag).warning("Certificate failed to parse with \(error)")
        }

        return nil
    }
}
