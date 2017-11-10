//
//  MLVTabBar.swift
//  MLVTabKit Example
//
//  Created by melvyn on 29/08/2017.
//  Copyright © 2017 NEET. All rights reserved.
//

import UIKit

open class Swiper: UIScrollView {
    open var indexesForVisibleRows: [Int]?
    open var minimumInteritemSpacing: CGFloat = 20.0
    open var visibleCells: [ReusableType]? {
        return reusableForVisibleRows?.values.map { $0 }
    }
    open var numberOfRows: Int {
        return self.dataSource?.numberOfRows(in: self) ?? 0
    }
    // require SwiperDelegate
    weak open override var delegate: UIScrollViewDelegate? {
        set {
            guard let d = newValue as? SwiperDelegate else {
                super.delegate = newValue
                return
            }
            _delegate = d
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
            reloadData()
        }
    }
    
    private var reusableForVisibleRows: [Int : ReusableType]?
    private var layoutAttributesKeyedByIndex: [Int : LayoutAttributes] = [:]
    private var isLayouting: Bool = false
    private var reusePool: [String : ReusableType.Type] = [:]
    private var reusablePool: [String : [ReusableType]] = [:]
    private var observation: [NSKeyValueObservation]?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    private func initialize() {
        observation = [ observe(\Swiper.contentOffset) { [weak self](swiper, c) in
            guard let strongSelf = self else { return }
            strongSelf.applyLayoutAttributes()
            }
        ]
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !isLayouting else {
            return
        }
        reloadData()
        isLayouting = true
    }
    
    open func register(_ cellClass: ReusableType.Type?, forCellReuseIdentifier identifier: String) {
        assert(reusePool[identifier] == nil, "reduance")
        
        reusePool[identifier] = cellClass
    }
    
    // Used by the delegate to acquire an already allocated cell, in lieu of allocating a new one.
    open func dequeueReusableCell(withIdentifier identifier: String) -> ReusableType? {
        assert(reusePool[identifier] != nil, "You haven't register reusable for identifier: \(identifier)")
        
        guard let cell = reusablePool[identifier]?.first else {
            return nil
        }
        reusablePool[identifier]?.removeFirst()
        cell.prepareForReuse()
        return cell
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
        
        assert(dataSource != nil, "data source can't be nil")
        
        indexesForVisibleRows = nil
        reusableForVisibleRows = nil
        layoutAttributesKeyedByIndex.removeAll()
        reusablePool.removeAll()
        
        contentSize = .zero
        for index in 0..<numberOfRows {
            let width = _delegate?.swiper(self, widthForRowAt: index) ?? frame.width
            
            var attributes = LayoutAttributes.init(index)
            attributes.frame = CGRect.init(x: contentSize.width, y: 0, width: width, height: bounds.height)
            
            layoutAttributesKeyedByIndex[index] = attributes
            
            contentSize.width += width
        }
        
        contentSize.height = bounds.height
        applyLayoutAttributes()
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
                let layoutAttributes = layoutAttributesKeyedByIndex[$0],
                cell.contentView.frame.equalTo(layoutAttributes.frame) else {
                    return
            }
            cell.apply(layoutAttributes)
            cell.contentView.frame = layoutAttributes.frame
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
        
        indexesForVisibleRows = newValue
    }
    
    func indexForRow(at point: CGPoint) -> Int? {
        return layoutAttributesKeyedByIndex.values.filter {
            point.x >= $0.frame.origin.x && point.x <= $0.frame.origin.x + $0.size.width
            }.first?.index
    }
    
    func indexesForRows(in rect: CGRect) -> [Int]? {
        guard numberOfRows > 0, !rect.equalTo(.zero) else {
            return nil
        }
        
        return layoutAttributesKeyedByIndex.values
            .filter { $0.frame.intersects(rect) }
            .map { $0.index }
    }
    
    private func enqueue(_ cell: ReusableType, identifier: String) {
        var cells = reusablePool[identifier] ?? []
        cells.append(cell)
        reusablePool[identifier] = cells
    }
}

public protocol SwiperDataSource: class {
    
    func numberOfRows(in swiper: Swiper) -> Int
    
    func swiper(_ swiper: Swiper, cellForRowAt index: Int) -> ReusableType
}

public protocol SwiperDelegate: UIScrollViewDelegate {
    func swiper(_ swiper: Swiper, willDisplay cell: ReusableType, forRowAt index: Int)
    func swiper(_ swiper: Swiper, widthForRowAt index: Int) -> CGFloat
    func swiper(_ swiper: Swiper, didSelectRowAt index: Int)
}

