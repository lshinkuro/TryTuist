//
//  Layout+CollectionView.swift
//  HomeFeature
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import UIKit


public final class CarouselLayout: UICollectionViewFlowLayout {
    public override init() {
        super.init()
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
        self.scrollDirection = .horizontal
        self.sectionInset = .zero
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepare() {
        super.prepare()
        if let collectionView = collectionView {
            itemSize = collectionView.frame.size
        }
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard itemSize != newBounds.size else { return false }
        itemSize = newBounds.size
        return true
    }
}
