//
//  LayoutAttributes.swift
//  Swiper
//
//  Created by melvyn on 10/11/2017.
//  Copyright © 2017 NEET. All rights reserved.
//

import Foundation

public struct LayoutAttributes {
    
    public var frame: CGRect {
        didSet {
            size = frame.size
        }
    }
    public var size: CGSize
    public var index: Int
    
    init(_ idx: Int) {
        frame = .zero
        size = frame.size
        index = idx
    }
}

