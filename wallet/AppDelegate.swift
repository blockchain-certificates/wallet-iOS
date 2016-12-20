//
//  AppDelegate.swift
//  wallet
//
//  Created by Chris Downie on 10/4/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import JSONLD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // The app has launched normally
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Required to set up the javascript environment for the 
        self.window?.addSubview(JSONLD.shared.webView)
        
        // debug:
        print("File path is \(Paths.certificatesDirectory)")
        return true
    }
    
    // The app has launched from a universal link
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL {
            
            return importState(from: url)
        }

        return true
    }
    
    // The app is launching with a document
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return launchAddCertificate(at: url)
    }
    
    func importState(from url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        switch components.path {
        case "/demourl":
            var identificationURL: URL?
            var nonce : String?
            
            components.queryItems?.forEach { (queryItem) in
                switch queryItem.name {
                case "identificationURL":
                    if let urlString = queryItem.value,
                        let urlDecodedString = urlString.removingPercentEncoding {
                        identificationURL = URL(string: urlDecodedString)
                    }
                case "nonce":
                    nonce = queryItem.value
                default:
                    break;
                }
            }
            
            if identificationURL != nil && nonce != nil {
                print("got url \(identificationURL!) and nonce \(nonce!)")
                launchAddIssuer(at: identificationURL!, with: nonce!)
                return true
            } else {
                print("Got demo url but didn't have both components")
                return false
            }
        case "/importCertificate":
            let urlComponents = components.queryItems?.filter { queryItem -> Bool in
                return queryItem.name == "certificateURL"
            }
            if let urlString = urlComponents?.first?.value,
                let urlDecodedString = urlString.removingPercentEncoding,
                let certificateURL = URL(string: urlDecodedString) {
                return launchAddCertificate(at: certificateURL)
            } else {
                return false
            }
        default:
            print("I don't know about \(components.path)")
            return false
        }
    }
    
    func launchAddIssuer(at introductionURL: URL, with nonce: String) {
        let rootController = window?.rootViewController as? UINavigationController
        
        rootController?.presentedViewController?.dismiss(animated: false, completion: nil)
        _ = rootController?.popToRootViewController(animated: false)
        
        let issuerCollection = rootController?.viewControllers.first as? IssuerCollectionViewController
        
        issuerCollection?.showAddIssuerFlow(identificationURL: introductionURL, nonce: nonce)
    }
    
    func launchAddCertificate(at url: URL) -> Bool {
        let rootController = window?.rootViewController as? UINavigationController
        
        rootController?.presentedViewController?.dismiss(animated: false, completion: nil)
        _ = rootController?.popToRootViewController(animated: false)
        
        let issuerCollection = rootController?.viewControllers.first as? IssuerCollectionViewController
        return issuerCollection?.add(certificateURL: url) ?? false
    }

}

