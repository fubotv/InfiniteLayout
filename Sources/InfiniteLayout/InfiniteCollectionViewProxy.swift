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
//  Proxy.swift
//  InfiniteLayout
//
//  Created by Arnaud Dorgans on 20/12/2017.
//

import UIKit
import CocoaProxy

class InfiniteCollectionViewProxy<T: NSObjectProtocol>: CocoaProxy {

    var collectionView: InfiniteCollectionView! {
        get { return self.proxies.first as? InfiniteCollectionView }
        set {
            if !self.proxies.isEmpty {
                self.proxies.removeFirst()
            }
            self.proxies.insert(newValue, at: 0)
        }
    }

    var delegate: T? {
        get {
            guard self.proxies.count > 1 else {
                return nil
            }
            return self.proxies.last as? T
        } set {
            while self.proxies.count > 1 {
                self.proxies.removeLast()
            }
            guard let delegate = newValue else {
                return
            }
            self.proxies.append(delegate)
        }
    }

    override func proxies(for aSelector: Selector) -> [NSObjectProtocol] {
         return super.proxies(for: aSelector).reversed()
    }

    init(collectionView: InfiniteCollectionView) {
        super.init(proxies: [])
        self.collectionView = collectionView
    }

    deinit {
        self.proxies.removeAll()
    }
}

class InfiniteCollectionViewDelegateProxy: InfiniteCollectionViewProxy<UICollectionViewDelegate>, UICollectionViewDelegate {

    override func proxies(for aSelector: Selector) -> [NSObjectProtocol] {
        return super.proxies(for: aSelector)
            .first { proxy in
                guard !(aSelector == #selector(UIScrollViewDelegate.scrollViewDidScroll(_:)) ||
                    aSelector == #selector(UIScrollViewDelegate.scrollViewWillEndDragging(_:withVelocity:targetContentOffset:)) ||
                    aSelector == #selector(UICollectionViewDelegate.collectionView(_:didUpdateFocusIn:with:)) ||
                    aSelector == #selector(UICollectionViewDelegate.indexPathForPreferredFocusedView(in:))) else {
                        return proxy is InfiniteCollectionView
                }
                return true
            }.flatMap { [$0] } ?? []
    }
}

class InfiniteCollectionViewDataSourceProxy: InfiniteCollectionViewProxy<UICollectionViewDataSource>, UICollectionViewDataSource {

    override func proxies(for aSelector: Selector) -> [NSObjectProtocol] {
        return super.proxies(for: aSelector)
            .first { proxy in
                guard !(aSelector == #selector(UICollectionViewDataSource.numberOfSections(in:)) ||
                    aSelector == #selector(UICollectionViewDataSource.collectionView(_:numberOfItemsInSection:))) else {
                        return proxy is InfiniteCollectionView
                }
                return true
            }.flatMap { [$0] } ?? []
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.collectionView.collectionView(collectionView, numberOfItemsInSection: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.delegate?.collectionView(collectionView, cellForItemAt: indexPath) ??
            self.collectionView.collectionView(collectionView, cellForItemAt: indexPath)
    }
}
