//
//  InfiniteDataSources.swift
//  InfiniteLayout
//
//  Created by Arnaud Dorgans on 03/01/2018.
//  Updated by Vladimír Horký on 29/08/2018.

import UIKit

class InfiniteDataSources {
    private enum Constants {
        static let spaceAfterSecondSection: CGFloat = 240
    }

    static func section(from infiniteSection: Int, numberOfSections: Int) -> Int {
        return infiniteSection % numberOfSections
    }

    static func indexPath(from infiniteIndexPath: IndexPath, numberOfSections: Int, numberOfItems: Int) -> IndexPath {
        guard numberOfItems != 0 else {
            return IndexPath(item: 0, section: self.section(from: infiniteIndexPath.section, numberOfSections: numberOfSections))
        }
        return IndexPath(item: infiniteIndexPath.item % numberOfItems,
                         section: self.section(from: infiniteIndexPath.section,
                                               numberOfSections: numberOfSections))
    }
    
    static func multiplier(estimatedItemSize: CGSize, enabled: Bool) -> Int {
        guard enabled else {
            return 1
        }
        let min = Swift.min(estimatedItemSize.width, estimatedItemSize.height)
        let count = ceil(InfiniteLayout.minimumContentSize / min)
        return Int(count)
    }

    static func multiplier(infiniteLayout: InfiniteLayout, numberOfSections: Int, numberOfItems: Int, scrollDirection: UICollectionView.ScrollDirection) -> Int {
        let estimatedItemSize = infiniteLayout.itemSize
        let itemSize = scrollDirection == .horizontal ? estimatedItemSize.width : estimatedItemSize.height
        let itemSpace = scrollDirection == .horizontal ? infiniteLayout.minimumLineSpacing : infiniteLayout.minimumInteritemSpacing
        let sectionSpace: CGFloat
        if scrollDirection == .horizontal {
            sectionSpace = infiniteLayout.sectionInset.left + infiniteLayout.sectionInset.right
        } else {
            sectionSpace = infiniteLayout.sectionInset.top + infiniteLayout.sectionInset.bottom
        }
        var contentSize = CGFloat(numberOfItems) * itemSize
        contentSize += CGFloat(numberOfItems - 1) * itemSpace
        contentSize += CGFloat(numberOfSections) * sectionSpace
        contentSize += CGFloat(numberOfSections - 1) * Constants.spaceAfterSecondSection

        if contentSize < InfiniteLayout.minimumContentSize(forScrollDirection: scrollDirection) {
            return 1
        }
        let count = ceil(InfiniteLayout.minimumContentSize(forScrollDirection: scrollDirection) / itemSize)
        return Int(count)
    }

    static func numberOfSections(numberOfSections: Int, multiplier: Int) -> Int {
        return numberOfSections > 1 ? numberOfSections * multiplier : numberOfSections
    }

    static func numberOfItemsInSection(numberOfItemsInSection: Int, numberOfSections: Int, multiplier: Int) -> Int {
        return numberOfSections > 1 ? numberOfItemsInSection : numberOfItemsInSection * multiplier
    }
}
