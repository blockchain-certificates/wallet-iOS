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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Required to set up the javascript environment for the 
        self.window?.addSubview(JSONLD.shared.webView)
        
        // debug:
        print("File path is \(Paths.certificatesDirectory)")
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL {
            
            return importState(from: url)
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
                let certificateURL = URL(string: urlString) {
                launchAddCertificate(at: certificateURL)
                return true
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
    
    func launchAddCertificate(at url: URL) {
        let rootController = window?.rootViewController as? UINavigationController
        
        rootController?.presentedViewController?.dismiss(animated: false, completion: nil)
        _ = rootController?.popToRootViewController(animated: false)
        
        let issuerCollection = rootController?.viewControllers.first as? IssuerCollectionViewController
        issuerCollection?.add(certificateURL: url)
    }

}

