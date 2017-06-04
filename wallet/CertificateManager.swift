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
    let certificatesDirectory = Paths.certificatesDirectory
    
    func loadCertificates() -> [Certificate] {
        let existingFiles = try? FileManager.default.contentsOfDirectory(at: certificatesDirectory, includingPropertiesForKeys: nil, options: [])
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
        try? FileManager.default.createDirectory(at: certificatesDirectory, withIntermediateDirectories: false, attributes: nil)
        
        for certificate in certificates {
            guard let fileName = certificate.assertion.uid.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
                print("ERROR: Couldn't convert \(certificate.title) to character encoding.")
                continue
            }
            let fileURL = certificatesDirectory.appendingPathComponent(fileName)
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
//    func add(certificate: Certificate)
//        let isKnownIssuer = managedIssuers.contains(where: { (existingManager) -> Bool in
//            return existingManager.issuer?.id == certificate.issuer.id
//        })
//        
//        if !isKnownIssuer {
//            add(issuer: certificate.issuer)
//        }
//        
//        certificates.append(certificate)
//        saveCertificates()
//    }
    
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
//    
//    func add(certificateURL: URL, silently: Bool = false, animated: Bool = true) -> Bool {
//        var components = URLComponents(url: certificateURL, resolvingAgainstBaseURL: false)
//        let formatQueryItem = URLQueryItem(name: "format", value: "json")
//        
//        if components?.queryItems == nil {
//            components?.queryItems = [
//                formatQueryItem
//            ]
//        } else {
//            components?.queryItems?.append(formatQueryItem)
//        }
//        
//        var data: Data? = nil
//        if let dataURL = components?.url {
//            // TODO: I believe Data(contentsOf: ) is disfavored in place of a true data task.
//            data = try? Data(contentsOf: dataURL)
//        }
//        
//        guard data != nil, let certificate = try? CertificateParser.parse(data: data!) else {
//            let title = NSLocalizedString("Invalid Certificate", comment: "Title for an alert when importing an invalid certificate")
//            let message = NSLocalizedString("That file doesn't appear to be a valid certificate.", comment: "Message in an alert when importing an invalid certificate")
//            
//            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm action"), style: .default, handler: nil))
//            
//            present(alertController, animated: true, completion: nil)
//            
//            return false
//        }
//        
//        let assertionUid = certificate.assertion.uid;
//        guard !certificates.contains(where: { $0.assertion.uid == assertionUid }) else {
//            if !silently {
//                let title = NSLocalizedString("File already imported", comment: "Alert title when you re-import an existing certificate")
//                let message = NSLocalizedString("You've already imported that file. Want to view it?", comment: "Longer explanation about importing an existing file.")
//                
//                let viewAction = UIAlertAction(title: NSLocalizedString("View", comment: "Action prompt to view the imported certificate"), style: .default, handler: { [weak self] _ in
//                    if let certificate = self?.certificates.first(where: { $0.assertion.uid == assertionUid }) {
//                        self?.navigateTo(certificate: certificate, animated: true)
//                    }
//                })
//                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dismiss action"), style: .cancel, handler: nil)
//                
//                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//                alertController.addAction(cancelAction)
//                alertController.addAction(viewAction)
//                
//                present(alertController, animated: true, completion: nil)
//            }
//            return true
//        }
//        
//        add(certificate: certificate)
//        reloadCollectionView()
//        
//        if !silently {
//            navigateTo(certificate: certificate, animated: animated)
//        }
//        
//        return true
//    }
}
