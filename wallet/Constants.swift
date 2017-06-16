//
//  .swift
//  wallet
//
//  Created by Chris Downie on 10/21/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import Foundation
import Blockcerts

extension UIColor {
    static let brandColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    static let tintColor = #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)
    static let titleColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    static let baseColor = UIColor(red:0.97, green:0.97, blue:0.98, alpha:1.0)
    
    static let primaryTextColor = UIColor(red:0.31, green:0.35, blue:0.38, alpha:1.0)
    static let secondaryTextColor = UIColor(red:0.65, green:0.67, blue:0.66, alpha:1.0)
    static let placeholderTextColor = UIColor(red:0.72, green:0.75, blue:0.79, alpha:1.0)
    static let disabledTextColor = UIColor(red:0.56, green:0.58, blue:0.60, alpha:1.0)
    static let borderColor = UIColor(red:0.84, green:0.86, blue:0.88, alpha:1.0)
}

enum UserKeys {
    static let firstNameKey = "ACCOUNT_FIRST_NAME"
    static let lastNameKey = "ACCOUNT_LAST_NAME"
    static let emailKey = "ACCOUNT_EMAIL"
    static let avatarURLKey = "ACCOUNT_AVATAR_URL"
}

enum Paths {
    static let issuersArchiveURL     = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Issuers")
    static let certificatesDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Certificates", isDirectory: true)
}
    
enum Dimensions {
    static let issuerCornerRadius : CGFloat = 5
}

enum Fonts {
    static let brandFont = UIFont.systemFont(ofSize: 18)
    static let placeholderFont = UIFont.systemFont(ofSize: 18)
}

enum Identifiers {
    static let sampleCertificateUID = "sample-certificate"
}

