//
// Created by Javier Moreno on 2019-02-14.
// Copyright (c) 2019 Learning Machine, Inc. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork
import CoreTelephony

struct InformationLogger {
    private static let tag = String(describing: InformationLogger.self)

    static func logInfo() {
        Logger.main.tag(tag).debug("INFO START---------------")

        let systemVersion = UIDevice.current.systemVersion
        Logger.main.tag(tag).debug("systemVersion: \(systemVersion)")

        let model = UIDevice.current.model
        Logger.main.tag(tag).debug("model: \(model)")

        let name = UIDevice.current.name
        Logger.main.tag(tag).debug("name: \(name)")

        let systemName = UIDevice.current.systemName
        Logger.main.tag(tag).debug("systemName: \(systemName)")

        let language = String(describing: Locale.preferredLanguages[0])
        Logger.main.tag(tag).debug("language: \(language)")

        let networkReachable = Reachability.isNetworkReachable()
        if let ssids = currentSSIDs() {
            Logger.main.tag(tag).debug("wifi network: \(ssids). Network is \(networkReachable ? "" : "not") reachable")
        } else {
            if (networkReachable) {
                Logger.main.tag(tag).debug("not in wifi, but network is reachable")
            } else {
                Logger.main.tag(tag).debug("not in wifi, and network is not reachable")
            }
        }

        if let carrier = getCarrierName() {
            Logger.main.tag(tag).debug("carrier: \(carrier)")
        } else {
            Logger.main.tag(tag).debug("no carrier found")
        }

        Logger.main.tag(tag).debug("INFO END---------------")
    }

    private static func currentSSIDs() -> String? {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        return ssid
    }

    private static func getCarrierName() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
        return carrier?.carrierName
    }

}