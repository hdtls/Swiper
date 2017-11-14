//
//  Swiper.swift
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

import UIKit

public protocol SwiperDataSource: NSObjectProtocol {
    
    func numberOfRows(in swiper: Swiper) -> Int
    func swiper(_ swiper: Swiper, cellForRowAt index: Int) -> ReusableType
}

public protocol SwiperDelegate: UIScrollViewDelegate {
    func swiper(_ swiper: Swiper, willDisplay cell: ReusableType, forRowAt index: Int)
    func swiper(_ swiper: Swiper, widthForRowAt index: Int) -> CGFloat
    func swiper(_ swiper: Swiper, didSelectRowAt index: Int)
}

public enum SwiperScrollDirection {
    case vertical
    case horizontal
}

open class Swiper: UIScrollView {
    open var indexesForVisibleRows: [Int]? {
        return _indexesForVisibleRows
    }
    private var _indexesForVisibleRows: [Int]?
    open var interitemSpacing: CGFloat = 0 {
        didSet {
            invalidateLayout()
            setNeedsLayout()
        }
    }
    open var scrollDirection: SwiperScrollDirection = .horizontal {
        didSet {
            invalidateLayout()
            setNeedsLayout()
        }
    }
    
    open var visibleCells: [ReusableType]? {
        return reusableForVisibleRows?.values.map { $0 }
    }
    open var numberOfRows: Int {
        return self.dataSource?.numberOfRows(in: self) ?? 0
    }
    // Adapt SwiperDelegate
    weak open override var delegate: UIScrollViewDelegate? {
        set {
            guard let delegate = newValue as? SwiperDelegate else {
                super.delegate = newValue
                return
            }
            _delegate = delegate
        }
        get {
            return _delegate ?? super.delegate
        }
    }
    
    weak open var dataSource: SwiperDataSource? {
        didSet {
            reloadData()
        }
    }
    
    weak private var _delegate: SwiperDelegate? {
        didSet {
            invalidateLayout()
        }
    }
    
    private var reusableForVisibleRows: [Int : ReusableType]?
    private var layoutAttributesKeyedByIndex: [Int : LayoutAttributes] = [:]
    private var reusePool: [String : ReusableType.Type] = [:]
    private var reusablePool: [String : [ReusableType]] = [:]
    private var viewSize: CGSize = .zero
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !frame.isEmpty else { return }
        
        // If view's size changed we need invalidate and reload layout. e.g. device orientantion changed.
        let index = indexesForVisibleRows?.first ?? 0
        
        if !__CGSizeEqualToSize(viewSize, bounds.size) {
            invalidateLayout()
        }
        
        applyLayoutAttributes()
        
        if !__CGSizeEqualToSize(viewSize, bounds.size) {
            contentOffset = layoutAttributesKeyedByIndex[index]?.frame.origin ?? .zero
        }
        viewSize = bounds.size
    }
    
    open func indexForRow(at point: CGPoint) -> Int? {
        
        let scrollDirection = self.scrollDirection
        return layoutAttributesKeyedByIndex.values.filter {
            if scrollDirection == .horizontal {
                return point.x >= $0.frame.origin.x && point.x <= $0.frame.origin.x + $0.size.width
            } else {
                return point.y >= $0.frame.origin.y && point.y <= $0.frame.origin.y + $0.size.height
            }
            }.first?.index
    }
    
    open func indexesForRows(in rect: CGRect) -> [Int]? {
        guard numberOfRows > 0, !rect.isEmpty else {
            return nil
        }
        
        return layoutAttributesKeyedByIndex.values
            .filter { $0.frame.intersects(rect) }
            .map { $0.index }
    }
    
    open func register(_ cellClass: ReusableType.Type?, forCellReuseIdentifier identifier: String) {
        assert(reusePool[identifier] == nil, "reduance")
        
        reusePool[identifier] = cellClass
    }
    
    // Used by the delegate to acquire an already allocated cell, in lieu of allocating a new one.
    open func dequeueReusableCell(withIdentifier identifier: String) -> ReusableType? {
        
        guard let cell = reusablePool[identifier]?.first else {
            return nil
        }
        reusablePool[identifier]?.removeFirst()
        cell.prepareForReuse()
        return cell
    }
    
    open func dequeueReusableCell(withIdentifier identifier: String, forIndex index: Int) -> ReusableType {
        assert(reusePool[identifier] != nil, "You haven't register reusable for identifier: \(identifier)")
        
        let cell = reusablePool[identifier]?.first ?? reusePool[identifier]!.init(reuseIdentifier: identifier)
        
        if reusablePool[identifier]?.isEmpty != true {
            reusablePool[identifier]?.removeFirst()
        }
        
        cell.prepareForReuse()
        
        return cell
    }
    
    private func enqueue(_ cell: ReusableType, identifier: String) {
        var cells = reusablePool[identifier] ?? []
        cells.append(cell)
        reusablePool[identifier] = cells
    }
    
    open func reloadData() {
        guard !reusePool.isEmpty else {
            return
        }
        
        subviews.forEach { (subview) in
            // FIXME: system indicator view
            guard !(subview is UIImageView) else {
                return
            }
            subview.removeFromSuperview()
        }
        
        _indexesForVisibleRows = nil
        reusableForVisibleRows = nil
        reusablePool.removeAll()
        
        setNeedsLayout()
    }
    
    private func applyLayoutAttributes() {
        let oldValue = indexesForVisibleRows ?? []
        
        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
        let newValue = indexesForRows(in: visibleRect) ?? []
        
        func intersects<Element: Equatable>(_ lhs: [Element], _ rhs: [Element]) -> [Element] {
            return lhs.filter { rhs.contains($0) }
        }
        
        func diff<Element: Equatable>(_ lhs: [Element], _ rhs: [Element]) -> [Element] {
            return lhs.filter { !rhs.contains($0) }
        }
        
        let delete = diff(oldValue, newValue)
        let modify = intersects(oldValue, newValue)
        let add = diff(newValue, oldValue)
        
        delete.forEach {
            if let cell = reusableForVisibleRows?[$0] {
                enqueue(cell, identifier: cell.reuseIdentifier)
                cell.contentView.removeFromSuperview()
                reusableForVisibleRows?[$0] = nil
            } else {
                assert(false, "assert failure")
            }
        }
        
        modify.forEach {
            guard let cell = reusableForVisibleRows?[$0],
                let layoutAttributes = layoutAttributesKeyedByIndex[$0] else {
                    return
            }
            
            cell.apply(layoutAttributes)
            cell.contentView.frame = layoutAttributes.frame
            cell.contentView.alpha = layoutAttributes.alpha
            cell.contentView.isHidden = layoutAttributes.isHidden
        }
        
        add.forEach {
            guard let cell = dataSource?.swiper(self, cellForRowAt: $0),
                let layoutAttributes = layoutAttributesKeyedByIndex[$0] else {
                    return
            }
            
            cell.apply(layoutAttributes)
            cell.contentView.frame = layoutAttributes.frame
            addSubview(cell.contentView)
            
            var reusablePair = reusableForVisibleRows ?? [:]
            reusablePair[$0] = cell
            reusableForVisibleRows = reusablePair
        }
        
        _indexesForVisibleRows = newValue
    }
    
    private func invalidateLayout() {
        layoutAttributesKeyedByIndex.removeAll()
        
        var contentSize: CGSize = .zero
        var origin: CGPoint = .zero
        
        for index in 0..<numberOfRows {
            
            var width: CGFloat = 0
            var attributes = LayoutAttributes.init(index)
            let interitemSpacing = index == 0 ? 0 : self.interitemSpacing
            
            if scrollDirection == .horizontal {
                width = _delegate?.swiper(self, widthForRowAt: index) ?? bounds.width
                origin.x = contentSize.width + interitemSpacing
                contentSize.width += width
                attributes.frame = CGRect.init(x: origin.x, y: origin.y, width: width, height: bounds.height)
                contentSize.height = bounds.height
            } else {
                width = _delegate?.swiper(self, widthForRowAt: index) ?? bounds.height
                origin.y = contentSize.height + interitemSpacing
                contentSize.height += width
                attributes.frame = CGRect.init(x: origin.x, y: origin.y, width: bounds.width, height: width)
                contentSize.width = bounds.width
            }
            
            layoutAttributesKeyedByIndex[index] = attributes
        }
        
        self.contentSize = contentSize
    }
}
