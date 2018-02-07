//
//  Style.swift
//  certificates
//
//  Created by Quinn McHenry on 2/5/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import Foundation

struct Style {
    struct Color {
        // C1
        static let C1 = UIColor.white
        
        // C2 / default background / light grey
        static let C2 = UIColor(hexString: "#F2F5FA")
        
        // C3 / primary brand color / dark blue
        static let C3 = UIColor(hexString: "#062451")
        
        // C4 / secondary brand color / green
        static let C4 = UIColor(hexString: "#2AB27B")
        
        // C5 / Headlines
        static let C5 = UIColor(hexString: "#1B66AE")
        
        // C6 / Primary text
        static let C6 = UIColor(hexString: "#333333")
        
        // C7 / Secondary text
        static let C7 = UIColor(hexString: "#919396")
        
        // C8 / Strokes
        static let C8 = UIColor(hexString: "#D8D8D8")
        
        // C9 / Error states
        static let C9 = UIColor(hexString: "#D0021B")
        
        // C10 // Text field highlight
        static let C10 = UIColor(hexString: "#EBEFF7")
    }

    struct Font {
        enum Weight {
        case regular
        case semiBold
        case bold
        }
        static func create(_ weight: Weight, size: CGFloat) -> UIFont {
            switch weight {
            case .regular:
                return UIFont.openSansFont(ofSize: size)
            case .semiBold:
                return UIFont.openSansSemiBoldFont(ofSize: size)
            case .bold:
                return UIFont.openSansBoldFont(ofSize: size)
            }
        }
        
        static let T1R = create(.regular, size: 12)

        static let T1B = create(.bold, size: 12)
        
        static let T2R = create(.regular, size: 14)
        
        static let T2S = create(.semiBold, size: 14)
        
        static let T2B = create(.bold, size: 14)
        
        static let T3R = create(.regular, size: 16)
        
        static let T3S = create(.semiBold, size: 16)
        
        static let T3B = create(.bold, size: 16)
        
        static let T4R = create(.regular, size: 18)
        
        static let T4S = create(.semiBold, size: 18)
        
        static let T5S = create(.semiBold, size: 22)
        
    }
    
    struct Measure {
        static let stroke = CGFloat(1)  // Color C9 / errorState
        
        static let gapXL = CGFloat(24)
        
        static let gapL = CGFloat(16)
        
        static let gapM = CGFloat(12)
        
        static let gapS = CGFloat(8)
        
        static let heightButtonSmall = CGFloat(40)
        
        static let heightButtonLarge = CGFloat(52)
        
        static let cornerRadius = CGFloat(7)
        
    }
    
}






extension UIColor {
    public convenience init(hexString: String) {
        var (r,g,b,a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 0.0, 1.0)
        guard hexString.hasPrefix("#"), let hexNumber = UInt32(String(hexString.dropFirst(1)), radix: 16) else {
            print("Error: could not parse hex color \(hexString)")
            self.init()
            return
        }
        switch hexString.count {
        case 9:
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255.0
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(hexNumber & 0x000000FF) / 255.0
        case 7:
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexNumber & 0x0000FF) / 255.0
        default: break
        }
        self.init(red: r, green:g, blue:b, alpha:a)
    }
}
