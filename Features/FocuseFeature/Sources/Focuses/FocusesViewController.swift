//
//  FocusesViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 21/08/24.
//

import UIKit
import SnapKit
import TTUI
import Utility
import SkeletonView

class FocusesViewController: BaseViewController {
    
    // MARK: - UI Elements
    let tabBar = UISegmentedControl(items: [TypeSegment.store.rawValue, TypeSegment.voucher.rawValue])
    let tableView = UITableView()

    var displayedOrders: [Order] = []
    weak var coordinator: FocuseCoordinator!
    
    init(coordinator: FocuseCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: "FocusesViewController", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTabBar()
        setupTableView()
    }
    
    override func bindingData() {
        super.bindingData()
        displayedOrders = orders
    }
    
    
    func setupTabBar() {
        view.addSubview(tabBar)
        tabBar.selectedSegmentIndex = 0
        tabBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        tabBar.addTarget(self, action: #selector(tabBarChanged), for: .valueChanged)
    }
    
    @objc func tabBarChanged() {
        if tabBar.selectedSegmentIndex == 0 {
            displayedOrders = orders
        } else {
            displayedOrders = vouchers
        }
        tableView.reloadData()
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OrderCell.self, forCellReuseIdentifier: "OrderCell")
        tableView.separatorStyle = .none
        tableView.snp.makeConstraints { make in
            make.top.equalTo(tabBar.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
}

extension FocusesViewController: UITableViewDelegate, UITableViewDataSource  {
    // MARK: - UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedOrders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "OrderCell", for: indexPath) as? OrderCell else {
            return UITableViewCell()
        }
        let order = displayedOrders[indexPath.row]
        cell.configure(with: order)
        return cell
    }
    
}
