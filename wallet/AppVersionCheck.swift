//
//  AppVersionCheck.swift
//  certificates
//
//  Created by Michael Shin on 8/23/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import Foundation

class AppVersion {
    
    static func checkUpdateRequired(completion: @escaping (_ forceUpdate: Bool) -> Void) {
        let installedVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        let url = URL(string: "https://www.blockcerts.org/versions.json")!
        let task : URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard error == nil else { // JSON unreachable, assume no update needed
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
                guard let appStoreVersion = jsonObj?["ios"] as? String else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                let forceUpdate = appStoreVersion.compare(installedVersion, options: .numeric) == .orderedDescending
                DispatchQueue.main.async {
                    completion(forceUpdate)
                }
            }
        }
        task.resume()
    }
}
