//
//  JsonLoader.swift
//  certificates
//
//  Created by Matthieu Collé on 18/08/2022.
//  Copyright © 2022 Learning Machine, Inc. All rights reserved.
//

import Foundation

class JsonLoader {
    static func loadJsonUrl(jsonUrl: String) throws -> Data? {
        do {
            let data = try Data(contentsOf: URL(string: jsonUrl)!)
            return data
        } catch let error {
            print("Could not load JSON", error)
            throw CertificateParserError.notValidJSON
        }
    }
}

