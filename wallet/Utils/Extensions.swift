//
//  Extensions.swift
//  wallet
//
//  Created by Chris Downie on 4/19/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Foundation
import Blockcerts

extension UIViewController {
    func presentAlert(_ alert: UIViewController, completion: (() -> Void)? = nil) {
        if let modal = presentedViewController {
            modal.dismiss(animated: false) {
                self.present(alert, animated: false, completion: completion)
            }
        } else {
            present(alert, animated: false, completion: completion)
        }
    }
}

extension UILabel {
    
    func isTruncated() -> Bool {
        guard let string = self.text else {
            return false
        }
        layoutIfNeeded()
        
        let size: CGSize = (string as NSString).boundingRect(
            with: CGSize(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSAttributedStringKey.font: self.font],
            context: nil).size
        
        return (size.height > self.bounds.size.height)
    }
}

extension Certificate {
    var filename : String? {
        return id.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }
}

protocol Localizable {
    var localized: String { get }
}

extension String: Localizable {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

protocol XibLocalizable {
    var LocalizedText: String? { get set }
}

extension UILabel: XibLocalizable {
    @IBInspectable var LocalizedText: String? {
        get { return nil }
        set(key) {
            text = key?.localized
        }
    }
}
extension UIButton: XibLocalizable {
    @IBInspectable var LocalizedText: String? {
        get { return nil }
        set(key) {
            setTitle(key?.localized, for: .normal)
        }
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
}
