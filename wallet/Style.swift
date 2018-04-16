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
        /// C1: white
        static let C1 = UIColor.white
        
        /// C2: default background / light grey
        static let C2 = UIColor(hexString: "#F2F5FA")
        
        /// C3: primary brand color / dark blue
        static let C3 = UIColor(hexString: "#062451")
        
        /// C4: secondary brand color / green
        static let C4 = UIColor(hexString: "#2AB27B")

        /// C5: Headlines
        static let C5 = UIColor(hexString: "#207BD3")
        
        /// C6: Primary text
        static let C6 = UIColor(hexString: "#333333")

        /// C7: Secondary text
        static let C7 = UIColor(hexString: "#919396")
        
        /// C8: Strokes
        static let C8 = UIColor(hexString: "#D8D8D8")
        
        /// C9: Error states
        static let C9 = UIColor(hexString: "#D0021B")
        
        /// C10: Text field highlight/background light blue
        static let C10 = UIColor(hexString: "#ECF5FE")
        
        /// C11: Selected primary button background
        static let C11 = UIColor(hexString: "#97CEB8")
        
        /// C12: highlighted button fill/outline
        static let C12 = UIColor(hexString: "#11493E")
        
        /// C13: drop shadow, 5% black
        static let C13 = UIColor(hexString: "#0000000C")
        
        /// C14: button disabled text
        static let C14 = UIColor(hexString: "#888888")
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
        
        static let T4B = create(.bold, size: 18)

        static let T5S = create(.semiBold, size: 22)
        
    }
    
    struct Measure {
        static let stroke = CGFloat(1)  // Color C9 / errorState
        
        static let gapXL = CGFloat(24)
        
        static let gapL = CGFloat(16)
        
        static let gapM = CGFloat(12)
        
        static let gapS = CGFloat(8)
        
        static let heightButtonSmall = CGFloat(44)
        
        static let heightButtonLarge = CGFloat(52)
        
        static let cornerRadius = CGFloat(7)
        
        /// Padding between right edge of button and right edge of checkmark image
        static let buttonCheckPadding = CGFloat(12)
        
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

extension UIImage {
    func color(at point: CGPoint) -> UIColor {
        guard let cgImage = cgImage , let dataProvider = cgImage.dataProvider, let pixelData = dataProvider.data else { return .white }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo: Int = ((Int(self.size.width) * Int(point.y)) + Int(point.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

