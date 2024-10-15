//
//  Reachability.swift
//  certificates
//
//  Created by Michael Shin on 8/16/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import SystemConfiguration

class Reachability {
    
    static func isNetworkReachable() -> Bool {
        
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(SCNetworkReachabilityCreateWithName(nil, "certificates.learningmachine.com")!, &flags)
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
}
