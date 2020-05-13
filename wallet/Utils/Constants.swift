//
//  Constants.swift
//  wallet
//
//  Created by Chris Downie on 10/21/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Foundation
import Blockcerts

struct Paths {
    static let managedIssuersListURL     = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("managed-issuers.json")
    static let issuersNSCodingArchiveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Issuers")
    static let certificatesDirectory     = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Certificates", isDirectory: true)
}

struct Identifiers {
    static let sampleCertificateUID = "sample-certificate"
}

struct NotificationNames {
    static let redirectToCertificate = Notification.Name("RedirectToCertificate")
    static let onboardingComplete = Notification.Name("OnboardingComplete")
    static let reloadCertificates = Notification.Name("ReloadCertificates")
}

struct UserDefaultsKey {
    static let hasPerformedBackup = "backup-performed"
    static let hasReenteredPassphrase = "reentered-passphrase"
}
