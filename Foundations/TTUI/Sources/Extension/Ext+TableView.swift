//
//  Ext+TableView.swift
//  TTUI
//
//  Created by Phincon on 24/08/24.
//

import Foundation
import UIKit

public extension UITableView {
    func registerCell<Cell: UITableViewCell>(_ cellClass: Cell.Type) {
        register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
    }
    
    func registerCellWithNib<Cell: UITableViewCell>(_ cellClass: Cell.Type) {
        let identifier = String(describing: cellClass)
        let nib = UINib(nibName: identifier, bundle: .main)
        register(nib, forCellReuseIdentifier: identifier)
    }
    
    func registerHeaderFooterWithNib<Header: UITableViewHeaderFooterView>(_ headerClass: Header.Type) {
        let identifier = String(describing: headerClass)
        let nib = UINib(nibName: identifier, bundle: .main)
        register(nib, forHeaderFooterViewReuseIdentifier: identifier)
    }
    
    func dequeueReusableCell<Cell: UITableViewCell>(forIndexPath indexPath: IndexPath) -> Cell {
        let identifier = String(describing: Cell.self)
        guard let cell = self.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? Cell else {
            fatalError("Error for cell if: \(identifier) at \(indexPath)")
        }
        return cell
    }
    
    func dequeueReusableHeaderFooter<Header: UITableViewHeaderFooterView>() -> Header {
        let identifier = String(describing: Header.self)
        guard let header = self.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? Header else {
            fatalError("Error for header: \(identifier)")
        }
        return header
    }
}
