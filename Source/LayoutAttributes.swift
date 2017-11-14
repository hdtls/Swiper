//
//  LayoutAttributes.swift
//
//  Copyright (c) 2017 NEET. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
    public var alpha: CGFloat
    public var isHidden: Bool
    
    public init(_ idx: Int) {
        self.init(frame: .zero, size: .zero, index: idx, alpha: 1, isHidden: false)
    }
    
    public init(
        frame: CGRect,
        size: CGSize,
        index: Int,
        alpha: CGFloat,
        isHidden: Bool
        ) {
        self.frame = frame
        self.size = size
        self.index = index
        self.alpha = alpha
        self.isHidden = isHidden
    }
}

extension LayoutAttributes: Equatable {
    public static func ==(lhs: LayoutAttributes, rhs: LayoutAttributes) -> Bool {
        guard lhs.frame == rhs.frame,
            lhs.size == rhs.size,
            lhs.index == rhs.index,
            lhs.alpha == rhs.alpha,
            lhs.isHidden == rhs.isHidden else {
                return false
        }
        return true
    }
}
