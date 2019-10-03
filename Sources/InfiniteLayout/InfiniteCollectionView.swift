//Copyright (c) 2017 Arnoymous <ineox@me.com>
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

//
//  InfiniteCollectionView.swift
//  InfiniteLayout
//
//  Created by Arnaud Dorgans on 20/12/2017.
//
//  Updated by Vladimír Horký on 30/07/2018.

import UIKit

@objc public protocol InfiniteCollectionViewDelegate {

    @objc optional func infiniteCollectionView(_ infiniteCollectionView: InfiniteCollectionView,
                                               didChangeCenteredIndexPath centeredIndexPath: IndexPath?)
}

open class InfiniteCollectionView: UICollectionView {

    lazy var dataSourceProxy = InfiniteCollectionViewDataSourceProxy(collectionView: self)
    lazy var delegateProxy = InfiniteCollectionViewDelegateProxy(collectionView: self)

    @IBOutlet open weak var infiniteDelegate: InfiniteCollectionViewDelegate?

    open private(set) var centeredIndexPath: IndexPath?
    open var preferredCenteredIndexPath: IndexPath? = IndexPath(item: 0, section: 0)
    private var lastFocusedIndexPath: IndexPath?
    var shouldLayoutSubviews = true

    var forwardDelegate: Bool { return true }
    var _contentSize: CGSize?

    override open var delegate: UICollectionViewDelegate? {
        get { return super.delegate }
        set {
            guard forwardDelegate else {
                super.delegate = newValue
                return
            }
            guard let newValue = newValue else {
                super.delegate = nil
                return
            }
            let isProxy = newValue is InfiniteCollectionViewDelegateProxy
            let delegate = isProxy ? newValue : delegateProxy
            if !isProxy {
                delegateProxy.delegate = newValue
            }
            super.delegate = delegate
        }
    }

    override open var dataSource: UICollectionViewDataSource? {
        get { return super.dataSource }
        set {
            guard forwardDelegate else {
                super.dataSource = newValue
                return
            }
            guard let newValue = newValue else {
                super.dataSource = nil
                return
            }
            let isProxy = newValue is InfiniteCollectionViewDataSourceProxy
            let dataSource = isProxy ? newValue : dataSourceProxy
            if !isProxy {
                dataSourceProxy.delegate = newValue
            }
            super.dataSource = dataSource
        }
    }

    @IBInspectable open var isItemPagingEnabled: Bool = false
    @IBInspectable open var velocityMultiplier: CGFloat = 1 {
        didSet {
            self.infiniteLayout.velocityMultiplier = velocityMultiplier
        }
    }

    public var infiniteLayout: InfiniteLayout! {
        return collectionViewLayout as? InfiniteLayout
    }

    private static func infiniteLayout(layout: UICollectionViewLayout) -> InfiniteLayout {
        guard let infiniteLayout = layout as? InfiniteLayout else {
            return InfiniteLayout(layout: layout)
        }
        return infiniteLayout
    }

    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: InfiniteCollectionView.infiniteLayout(layout: layout))
        sharedInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let infiniteLayout = InfiniteCollectionView.infiniteLayout(layout: collectionViewLayout)
        if collectionViewLayout != infiniteLayout {
            collectionViewLayout = infiniteLayout
        }
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        sharedInit()
    }

    private func sharedInit() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        #if os(iOS)
            scrollsToTop = false
        #endif
    }

    open override func layoutSubviews() {
        if shouldLayoutSubviews {
            super.layoutSubviews()
            updateLayoutIfNeeded()
        } else {
            shouldLayoutSubviews = true
        }
    }

    func scrollToItem(at indexPath: IndexPath, animated: Bool) {
        if infiniteLayout.isEnabled {
            let point = CGPoint(x: 250, y: contentOffset.y)
            let rect = (collectionViewLayout as? InfiniteLayout)?.layoutAttributesForItem(at: indexPath, page: point)?.frame ?? .zero
            let offset = CGPoint(x: rect.origin.x - 90, y: contentOffset.y)
            setContentOffset(offset, animated: animated)
        } else {
            setContentOffset(CGPoint(x: -90, y: contentOffset.y), animated: animated)
        }
    }

    private func scrollToCenterToItem(at indexPath: IndexPath, animated: Bool) {
        if infiniteLayout.isEnabled {
            let point = CGPoint(x: 250, y: contentOffset.y)
            let rect = (collectionViewLayout as? InfiniteLayout)?.layoutAttributesForItem(at: indexPath, page: point)?.frame ?? .zero
            let centerOffset = center.x - (rect.size.width/2)
            let offset = CGPoint(x: rect.origin.x - centerOffset, y: contentOffset.y)
            setContentOffset(offset, animated: animated)
        } else {
            super.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        }
    }

    override open func scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        switch scrollPosition {
        case .centeredHorizontally: scrollToCenterToItem(at: indexPath, animated: animated)
        default: scrollToItem(at: indexPath, animated: animated)
        }
    }

    func selectItem(at indexPath: IndexPath,
                    animated: Bool,
                    scrollPosition: UICollectionView.ScrollPosition,
                    direction: UISwipeGestureRecognizer.Direction = .right) {

        if infiniteLayout.isEnabled {
            var selectedIndexPath: IndexPath?
            if let focusedCell = UIScreen.main.focusedView as? UICollectionViewCell, focusedCell.isDescendant(of: self) {
                selectedIndexPath = self.indexPath(for: focusedCell)
            }
            if selectedIndexPath == nil {
                selectedIndexPath = indexPathsForSelectedItems?.first
            }

            if let previouslySelected = selectedIndexPath {
                var visibleIndexPath: IndexPath?
                indexPathsForVisibleItems.forEach { (i) in
                    if indexPath == self.indexPath(from: i) {
                        visibleIndexPath = i
                    }
                }
                func superSelect(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition) {
                    super.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
                }

                func manualSelection(direction: UISwipeGestureRecognizer.Direction) {
                    var rect: CGRect = .zero
                    var pageIndexOffset = 0
                    switch direction {
                    case .left: pageIndexOffset = -1
                    case .right: pageIndexOffset = 1
                    default: pageIndexOffset = 0
                    }
                    if let visible = visibleIndexPath, let cell = cellForItem(at: visible) {
                        rect = cell.frame
                    } else {
                        rect = (collectionViewLayout as? InfiniteLayout)?.layoutAttributesForItem(
                            at: indexPath,
                            pageOffset: CGPoint(x: pageIndexOffset, y: 0)
                            )?.frame ?? .zero
                    }

                    let centerOffset = center.x - (rect.size.width/2)
                    let offset = CGPoint(x: rect.origin.x - centerOffset, y: contentOffset.y)

                    UIView.animate(withDuration: 0.2, animations: { [unowned self] in
                        self.contentOffset = offset
                        }, completion: { _ in
                            superSelect(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                    })
                }

                switch direction {
                case .left:
                    if previouslySelected.item == 0, previouslySelected.section == 0 {
                        manualSelection(direction: .left)
                        return
                    }
                case .right:
                    if indexPath.item == 0, indexPath.section == 0 {
                        manualSelection(direction: .right)
                        return
                    }
                default: break
                }
            }
        }

        super.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
    }

    open override func selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition) {
        let warning = """
            Are you sure about it? It can have weird behavior for Infinite Layout.
            You may want to use selectItem(at:animated:scrollPosition: direction:)
            """
        LogUtils.logger.warning(warning)
        super.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
    }

    func resetFocus() {
        crashLog()
        lastFocusedIndexPath = nil
    }

    public func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        guard let indexPath = lastFocusedIndexPath ?? delegateProxy.delegate?.indexPathForPreferredFocusedView?(in: collectionView),
            collectionView.hasCellAtIndexPath(indexPath) else {
            return nil
        }
        return indexPath
    }
}

// MARK: DataSource
extension InfiniteCollectionView: UICollectionViewDataSource {

    private var delegateNumberOfSections: Int {
        guard let sections = dataSourceProxy.delegate.flatMap({ $0.numberOfSections?(in: self) ?? 1 }) else {
            fatalError("collectionView dataSource is required")
        }
        return sections
    }

    private func delegateNumberOfItems(in section: Int) -> Int {
        guard let items = dataSourceProxy.delegate.flatMap({ $0.collectionView(self, numberOfItemsInSection: self.section(from: section)) })
            else {
                fatalError("collectionView dataSource is required")
        }
        return items
    }

    private var multiplier: Int {
        var count = 0
        for section in 0..<delegateNumberOfSections {
            count += delegateNumberOfItems(in: section)
        }

        return InfiniteDataSources.multiplier(infiniteLayout: infiniteLayout,
                                              numberOfSections: delegateNumberOfSections,
                                              numberOfItems: count,
                                              scrollDirection: infiniteLayout.scrollDirection)

    }

    public func section(from infiniteSection: Int) -> Int {
        return InfiniteDataSources.section(from: infiniteSection, numberOfSections: delegateNumberOfSections)
    }

    public func indexPath(from infiniteIndexPath: IndexPath) -> IndexPath {
        return InfiniteDataSources.indexPath(from: infiniteIndexPath,
                                             numberOfSections: delegateNumberOfSections,
                                             numberOfItems: delegateNumberOfItems(in: infiniteIndexPath.section))
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return InfiniteDataSources.numberOfSections(numberOfSections: delegateNumberOfSections, multiplier: multiplier)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return InfiniteDataSources.numberOfItemsInSection(numberOfItemsInSection: delegateNumberOfItems(in: section),
                                                          numberOfSections: delegateNumberOfSections,
                                                          multiplier: multiplier)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("collectionView dataSource is required")
    }
}

extension InfiniteCollectionView: UICollectionViewDelegate {

    func updateLayoutIfNeeded() {
        loopCollectionViewIfNeeded()
        centerCollectionViewIfNeeded()

        if let preferredVisibleIndexPath = infiniteLayout.preferredVisibleLayoutAttributes()?.indexPath,
            centeredIndexPath != preferredVisibleIndexPath,
            hasCellAtIndexPath(preferredVisibleIndexPath) {

            centeredIndexPath = preferredVisibleIndexPath
            infiniteDelegate?.infiniteCollectionView?(self, didChangeCenteredIndexPath: preferredVisibleIndexPath)
        }
    }

    // MARK: Loop
    func loopCollectionViewIfNeeded() {
        self.infiniteLayout.loopCollectionViewIfNeeded()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegateProxy.delegate?.scrollViewDidScroll?(scrollView)
        updateLayoutIfNeeded()
    }

    // MARK: Paging
    func centerCollectionViewIfNeeded() {
        guard isItemPagingEnabled,
            !isDragging && !isDecelerating else {
                return
        }
        guard _contentSize != contentSize else {
            return
        }
        _contentSize = contentSize
        infiniteLayout.centerCollectionViewIfNeeded(indexPath: preferredCenteredIndexPath)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if isItemPagingEnabled {
            infiniteLayout.centerCollectionView(withVelocity: velocity, targetContentOffset: targetContentOffset)
        }

        delegateProxy.delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
                               with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedIndexPath != nil {
            lastFocusedIndexPath = context.nextFocusedIndexPath
        }

        delegateProxy.delegate?.collectionView?(collectionView, didUpdateFocusIn: context, with: coordinator)
    }
}
