//
//  Colors.swift
//  wallet
//
//  Created by Chris Downie on 10/21/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import Foundation

enum Colors {
    static let brandColor = #colorLiteral(red: 0.2352941176, green: 0.6901960784, blue: 0.4862745098, alpha: 1)
    static let translucentBrandColor = #colorLiteral(red: 0.2039215686, green: 0.5882352941, blue: 0.4117647059, alpha: 1)
    static let tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    static let baseColor = UIColor(red:0.97, green:0.97, blue:0.98, alpha:1.0)
}

enum UserKeys {
    static let firstNameKey = "ACCOUNT_FIRST_NAME"
    static let lastNameKey = "ACCOUNT_LAST_NAME"
    static let emailKey = "ACCOUNT_EMAIL"
    static let avatarURLKey = "ACCOUNT_AVATAR_URL"
}

enum Paths {
    static let certificatesDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Certificates", isDirectory: true)
}
    
