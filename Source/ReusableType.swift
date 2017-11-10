//
//  ReusableType.swift
//  Swiper
//
//  Created by melvyn on 10/11/2017.
//  Copyright © 2017 NEET. All rights reserved.
//

import UIKit

public protocol ReusableType: class {
    
    var contentView: UIView { get }
    var reuseIdentifier: String { get }
    
    func prepareForReuse()
    func apply(_ layoutAttributes: LayoutAttributes)
    
    init(style: Any?, reuseIdentifier: String)
}

public extension ReusableType {
    var reuseIdentifier: String {
        return String.init(describing: self)
    }
    
    func prepareForReuse() { }
    
    func apply(_ layoutAttributes: LayoutAttributes) { }
}

