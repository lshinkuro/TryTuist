//
//  Ext+CollectionView.swift
//  AuthenticationFeature
//
//  Created by Phincon on 21/08/24.
//

import Foundation
import UIKit


public extension UICollectionView {
    
    func indexPath(for supplementaryView: UICollectionReusableView?, ofKind kind: String = UICollectionView.elementKindSectionHeader) -> IndexPath? {
        let elements = visibleSupplementaryViews(ofKind: kind)
        let indexPaths = indexPathsForVisibleSupplementaryElements(ofKind: kind)
        
        for (element, indexPath) in zip(elements, indexPaths) where element === supplementaryView {
            return indexPath
        }
        return nil
    }
    
    func scrollToNearestVisibleCollectionViewCell() {
        self.decelerationRate = UIScrollView.DecelerationRate.fast
            let visibleCenterPositionOfScrollView = Float(self.contentOffset.x + (self.bounds.size.width / 2))
            var closestCellIndex = -1
            var closestDistance: Float = .greatestFiniteMagnitude
            for count in 0..<self.visibleCells.count {
                let cell = self.visibleCells[count]
                let cellWidth = cell.bounds.size.width
                let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)

                // Now calculate closest cell
                let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
                if distance < closestDistance {
                    closestDistance = distance
                    closestCellIndex = self.indexPath(for: cell)!.row
                }
            }
            if closestCellIndex != -1 {
                self.scrollToItem(at: IndexPath(row: closestCellIndex, section: 0), at: .centeredHorizontally, animated: true)
            }
        }
    
    func registerCellWithNib<Cell: UICollectionViewCell>(_ cellClass: Cell.Type) {
        let identifier = String(describing: cellClass)
        let nib = UINib(nibName: identifier, bundle: .main)
        register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    func dequeueReusableCell<Cell: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> Cell {
        let identifier = String(describing: Cell.self)
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? Cell else {
            fatalError("Error for cell if: \(identifier) at \(indexPath)")
        }
        return cell
    }
    
    func registerHeaderFooterNib<Cell: UICollectionReusableView>(kind: String, _ cellClass: Cell.Type) {
        let identifier = String(describing: cellClass)
        let nib = UINib(nibName: identifier, bundle: .main)
        register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }
}
