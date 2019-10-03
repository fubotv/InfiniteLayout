//
//  InfiniteCollectionView.swift
//  InfiniteLayout
//
//  Created by Arnaud Dorgans on 20/12/2017.
//  Updated by Vladimír Horký on 30/07/2018.

import UIKit

open class InfiniteLayout: UICollectionViewFlowLayout {
    
    public var velocityMultiplier: CGFloat = 1 // used to simulate paging
    
    private let multiplier: CGFloat = 500 // contentOffset multiplier
    
    private var contentSize: CGSize = .zero
    
    private var hasValidLayout: Bool = false
    private var oldContentSize: CGSize?
    
    @IBInspectable public var isEnabled: Bool = true {
        didSet {
            self.invalidateLayout()
        }
    }
    
    public var currentPage: CGPoint {
        guard let collectionView = collectionView else {
            return .zero
        }
        return page(for: collectionView.contentOffset)
    }
        
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    public convenience init(layout: UICollectionViewLayout) {
        self.init()
        guard let layout = layout as? UICollectionViewFlowLayout else {
            return
        }
        scrollDirection = layout.scrollDirection
        minimumLineSpacing = layout.minimumLineSpacing
        minimumInteritemSpacing = layout.minimumInteritemSpacing
        itemSize = layout.itemSize
        sectionInset = layout.sectionInset
        headerReferenceSize = layout.headerReferenceSize
        footerReferenceSize = layout.footerReferenceSize
    }
    
    static var minimumContentSize: CGFloat {
        return max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 4
    }

    static func minimumContentSize(forScrollDirection scrollDirection: UICollectionView.ScrollDirection) -> CGFloat {
        return scrollDirection == .horizontal ? UIScreen.main.bounds.width : UIScreen.main.bounds.height
    }
    
    override open func prepare() {
        let collectionViewContentSize = super.collectionViewContentSize
        contentSize = CGSize(width: collectionViewContentSize.width + minimumLineSpacing, height: collectionViewContentSize.height)
        self.hasValidLayout = {
            guard let collectionView = self.collectionView, collectionView.bounds != .zero, self.isEnabled else {
                return false
            }
            return (scrollDirection == .horizontal ? contentSize.width : contentSize.height) >=
                InfiniteLayout.minimumContentSize(forScrollDirection: scrollDirection)
        }()

        if oldContentSize == nil {
            oldContentSize = contentSize
        } else {
            guard let collectionView = collectionView, collectionView.bounds != .zero else {
                super.prepare()
                return
            }
            if let oldContentSize = oldContentSize, oldContentSize != contentSize {
                let offset = CGPoint(x: -collectionView.contentInset.left, y: collectionView.contentOffset.y)
                updateContentOffset(offset)
            }
            oldContentSize = contentSize
        }

        super.prepare()
    }
    
    override open var collectionViewContentSize: CGSize {
        guard hasValidLayout else {
            return self.contentSize
        }
        return CGSize(width: scrollDirection == .horizontal ? contentSize.width * multiplier : contentSize.width,
                      height: scrollDirection == .vertical ? contentSize.height * multiplier : contentSize.height)
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath) else {
            return nil
        }
        return layoutAttributes(from: attributes, page: currentPage)
    }

    func layoutAttributesForItem(at indexPath: IndexPath, page: CGPoint) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath) else {
            return nil
        }
        return layoutAttributes(from: attributes, page: page)
        }

    func layoutAttributesForItem(at indexPath: IndexPath, pageOffset: CGPoint) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView, let attributes = super.layoutAttributesForItem(at: indexPath) else {
            return nil
        }

        let page = self.page(for: collectionView.contentOffset)
        let pageWithOffset = self.page(from: page, offset: pageOffset.x)
        return self.layoutAttributes(from: attributes, page: pageWithOffset)
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard hasValidLayout else {
            return super.layoutAttributesForElements(in: rect)
        }
        let page = self.page(for: rect.origin)
        var elements = [UICollectionViewLayoutAttributes]()
        var rect = self.rect(from: rect)
        if (scrollDirection == .horizontal && rect.maxX > contentSize.width) ||
            (scrollDirection == .vertical && rect.maxY > contentSize.height) {
            let diffRect = CGRect(origin: .zero,
                                  size: CGSize(width: scrollDirection == .horizontal ? rect.maxX - contentSize.width : rect.width,
                                               height: scrollDirection == .vertical ? rect.maxY - contentSize.height : rect.height))
            elements.append(contentsOf: self.elements(in: diffRect, page: self.page(from: page, offset: 1)))
            if scrollDirection == .horizontal {
                rect.size.width -= diffRect.width
            } else {
                rect.size.height -= diffRect.height
            }
        }
        elements.append(contentsOf: self.elements(in: rect, page: page))
        return elements
    }
    
    private func page(for point: CGPoint) -> CGPoint {
        let xPage: CGFloat = floor(point.x / contentSize.width)
        let yPage: CGFloat = floor(point.y / contentSize.height)

        return CGPoint(x: scrollDirection == .horizontal ? xPage : 0,
                       y: scrollDirection == .vertical ? yPage : 0)
    }
    
    private func page(from page: CGPoint, offset: CGFloat) -> CGPoint {
        return CGPoint(x: scrollDirection == .horizontal ? page.x + offset : page.x,
                       y: scrollDirection == .vertical ? page.y + offset : page.y)
    }
    
    private func pageIndex(from page: CGPoint) -> CGFloat {
        return scrollDirection == .horizontal ? page.x : page.y
    }
    
    public func rect(from rect: CGRect, page: CGPoint = .zero) -> CGRect {
        var rect = rect
        if scrollDirection == .horizontal && rect.origin.x < 0 {
            rect.origin.x += abs(floor(contentSize.width / rect.origin.x)) * contentSize.width
        } else if scrollDirection == .vertical && rect.origin.y < 0 {
            rect.origin.y += abs(floor(contentSize.height / rect.origin.y)) * contentSize.height
        }
        rect.origin.x = rect.origin.x.truncatingRemainder(dividingBy: contentSize.width)
        rect.origin.y = rect.origin.y.truncatingRemainder(dividingBy: contentSize.height)
        rect.origin.x += page.x * contentSize.width
        rect.origin.y += page.y * contentSize.height
        return rect
    }
    
    private func elements(in rect: CGRect, page: CGPoint) -> [UICollectionViewLayoutAttributes] {
        let rect = self.rect(from: rect)
        let elements = super.layoutAttributesForElements(in: rect)?
            .map { layoutAttributes(from: $0, page: page) }
            .filter { $0 != nil }
            .map { $0! } ?? []
        return elements
    }
    
    private func layoutAttributes(from layoutAttributes: UICollectionViewLayoutAttributes, page: CGPoint) -> UICollectionViewLayoutAttributes! {
        guard let attributes = copyLayoutAttributes(layoutAttributes) else {
            return nil
        }
        attributes.frame = rect(from: attributes.frame, page: page)
        return attributes
    }
    
    // MARK: Loop
    private func updateContentOffset(_ offset: CGPoint) {
        guard let collectionView = collectionView else {
            return
        }
        //collectionView.contentOffset = offset
        collectionView.setContentOffset(offset, animated: false)
        collectionView.layoutIfNeeded()
    }
    private func preferredContentOffset(forContentOffset contentOffset: CGPoint) -> CGPoint {
        return rect(from: CGRect(origin: contentOffset, size: .zero), page: page(from: .zero, offset: multiplier / 2)).origin
    }
    
    public func loopCollectionViewIfNeeded() {
        guard let collectionView = self.collectionView, self.hasValidLayout else {
            return
        }
        let page = pageIndex(from: self.page(for: collectionView.contentOffset))
        let offset = preferredContentOffset(forContentOffset: collectionView.contentOffset)
        if (page < 2 || page > multiplier - 2) && collectionView.contentOffset != offset {
            self.updateContentOffset(offset)
        }
    }
    
    // MARK: Paging
    public func collectionViewRect() -> CGRect? {
        guard let collectionView = collectionView else {
            return nil
        }
        let margins = UIEdgeInsets(top: collectionView.contentInset.top + collectionView.layoutMargins.top,
                                   left: collectionView.contentInset.left + collectionView.layoutMargins.left,
                                   bottom: collectionView.contentInset.bottom + collectionView.layoutMargins.bottom,
                                   right: collectionView.contentInset.right + collectionView.layoutMargins.right)
        
        var visibleRect = CGRect()
        visibleRect.origin.x = margins.left
        visibleRect.origin.y = margins.top
        visibleRect.size.width = collectionView.bounds.width - visibleRect.origin.x - margins.right
        visibleRect.size.height = collectionView.bounds.height - visibleRect.origin.y - margins.bottom
        return visibleRect
    }
    
    public func visibleCollectionViewRect() -> CGRect? {
        guard let collectionView = collectionView,
            var collectionViewRect = collectionViewRect() else {
                return nil
        }
        collectionViewRect.origin.x += collectionView.contentOffset.x
        collectionViewRect.origin.y += collectionView.contentOffset.y
        return collectionViewRect
    }
    
    public func visibleLayoutAttributes(at offset: CGPoint? = nil) -> [UICollectionViewLayoutAttributes] {
        guard let collectionView = collectionView else {
            return []
        }
        return (layoutAttributesForElements(in: CGRect(origin: offset ?? collectionView.contentOffset,
                                                            size: collectionView.frame.size)) ?? [])
            .sorted(by: { lhs, rhs in
                guard let lhs = centeredContentOffset(forRect: lhs.frame) else {
                    return false
                }
                guard let rhs = centeredContentOffset(forRect: rhs.frame) else {
                    return true
                }
                let value: (CGPoint) -> CGFloat = {
                    let isHorizontal = self.scrollDirection == .horizontal
                    return isHorizontal ? abs(collectionView.contentOffset.x - $0.x) : abs(collectionView.contentOffset.y - $0.y)
                }
                return value(lhs) < value(rhs)
            })
    }
    
    public func preferredVisibleLayoutAttributes(at offset: CGPoint? = nil, velocity: CGPoint = .zero, targetOffset: CGPoint? = nil, indexPath: IndexPath? = nil) -> UICollectionViewLayoutAttributes? {
        guard let currentOffset = collectionView?.contentOffset else {
            return nil
        }
        let direction: (CGPoint) -> Bool = {
            return self.scrollDirection == .horizontal ? $0.x > currentOffset.x : $0.y > currentOffset.y
        }
        let velocity = scrollDirection == .horizontal ? velocity.x : velocity.y
        let targetDirection = direction(targetOffset ?? currentOffset)
        let attributes = visibleLayoutAttributes(at: offset)
        if let indexPath = indexPath,
            let attributes = attributes.first(where: { $0.indexPath == indexPath }) {
            return attributes
        }
        return attributes
            .first { attributes in
                guard let offset = centeredContentOffset(forRect: attributes.frame) else {
                    return false
                }
                return direction(offset) == targetDirection || velocity == 0
        }
    }
    
    func centeredContentOffset(forRect rect: CGRect) -> CGPoint? {
        guard let collectionView = collectionView,
            let collectionRect = collectionViewRect() else {
            return nil
        }

        let x: CGFloat
        let y: CGFloat

        if scrollDirection == .horizontal {
            x = abs(rect.midX - collectionRect.origin.x - collectionRect.width/2)
        } else {
            x = collectionView.contentOffset.x
        }

        if scrollDirection == .vertical {
            y = abs(rect.midY - collectionRect.origin.y - collectionRect.height/2)
        } else {
            y = collectionView.contentOffset.y
        }

        return CGPoint(x: x, y: y)
    }
    
    public func centerCollectionView(withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let collectionView = self.collectionView, self.hasValidLayout else {
            return
        }

        let x: CGFloat
        let y: CGFloat

        if scrollDirection == .horizontal {
            x =  collectionView.contentOffset.x + velocity.x * velocityMultiplier
        } else {
            x = targetContentOffset.pointee.x
        }
        
        if scrollDirection == .vertical {
            y = collectionView.contentOffset.y + velocity.y * velocityMultiplier
        } else {
            y = targetContentOffset.pointee.y
        }

        let newTarget = CGPoint(x: x, y: y)
        let preferredVisibleLayoutAttributes = self.preferredVisibleLayoutAttributes(at: newTarget,
                                                                                     velocity: velocity,
                                                                                     targetOffset: targetContentOffset.pointee)
        guard let preferredAttributes = preferredVisibleLayoutAttributes,
            let offset = centeredContentOffset(forRect: preferredAttributes.frame) else { return }
        targetContentOffset.pointee = offset
    }
    
    public func centerCollectionViewIfNeeded(indexPath: IndexPath? = nil) {
        guard let collectionView = self.collectionView, self.hasValidLayout else {
            return
        }
        guard let preferredAttributes = preferredVisibleLayoutAttributes(indexPath: indexPath),
            let offset = centeredContentOffset(forRect: preferredAttributes.frame),
            collectionView.contentOffset != offset else {
                return
        }
        updateContentOffset(offset)
    }
    
    // MARK: Copy
    public func copyLayoutAttributes(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes? {
        return attributes.copy() as? UICollectionViewLayoutAttributes
    }
    
    public func copyLayoutAttributes(from array: [UICollectionViewLayoutAttributes]) -> [UICollectionViewLayoutAttributes] {
        return array.map { copyLayoutAttributes($0) }
            .filter { $0 != nil }
            .map { $0! }
    }
}
