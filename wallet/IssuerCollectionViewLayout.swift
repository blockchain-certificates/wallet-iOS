//
//  IssuerCollectionViewLayout.swift
//  wallet
//
//  Created by Chris Downie on 2/10/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit

private let assumedWidth : CGFloat = 200

class IssuerCollectionViewLayout: UICollectionViewFlowLayout {
    let spacing : CGFloat = 29
    let textHeight : CGFloat = 35
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        print("Yep")
        return attributes
    }
    
//    func commonInit() {
//        let spacing : CGFloat = 8
//        minimumLineSpacing = spacing
//        minimumInteritemSpacing = spacing
//        sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
//        
//        let textHeight : CGFloat = 35
//        
//        let width = (targetWidth - (3 * spacing)) / 2
//        
//        let size = CGSize(width: width, height: width + textHeight)
//        
//        self.itemSize = size
//        self.estimatedItemSize = size
//    }
}
