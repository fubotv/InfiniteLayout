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
//  InfiniteDataSources.swift
//  InfiniteLayout
//
//  Created by Arnaud Dorgans on 03/01/2018.
//  Updated by Vladimír Horký on 29/08/2018.

import UIKit

class InfiniteDataSources {

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

    static func multiplier(estimatedItemSize: CGSize) -> Int {
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
        contentSize += CGFloat(numberOfSections - 1) * FuboGlobals.CarouselView.spaceAfterSecondSection

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
