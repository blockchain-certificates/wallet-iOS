//
//  Extensions.swift
//  wallet
//
//  Created by Chris Downie on 4/19/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import Foundation

extension UILabel {
    
    func isTruncated() -> Bool {
        guard let string = self.text else {
            return false
        }
        layoutIfNeeded()
        
        let size: CGSize = (string as NSString).boundingRect(
            with: CGSize(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: self.font],
            context: nil).size
        
        return (size.height > self.bounds.size.height)
    }
}
