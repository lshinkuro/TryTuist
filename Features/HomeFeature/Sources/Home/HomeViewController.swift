//
//  HomeViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import UIKit
import SkeletonView

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var coordinator: HomeCoordinator!
    
    init(coordinator: HomeCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: "HomeViewController", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isSkeletonable = true
        
        let nib = UINib(nibName: "FoodItemTableViewCell", bundle: .module)
        tableView.register(nib, forCellReuseIdentifier: "FoodItemTableViewCell")
        // Menjalankan SkeletonView
        tableView.showAnimatedSkeleton(usingColor: .lightGray, animation: nil, transition: .crossDissolve(0.25))
        
        // Simulasi pemuatan data dari API dengan delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.loadData()
        }
    }
    
    private func loadData() {
        // Setelah data dimuat, sembunyikan SkeletonView
        tableView.stopSkeletonAnimation()
        view.hideSkeleton()
        tableView.reloadData()
    }
    
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10 // Ganti dengan jumlah data asli setelah data dimuat
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FoodItemTableViewCell", for: indexPath) as? FoodItemTableViewCell else {
               return UITableViewCell()
           }
        return cell
    }
}

extension HomeViewController: SkeletonTableViewDataSource {
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10 // Jumlah baris saat skeleton ditampilkan
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "FoodItemTableViewCell" // Identifier sel yang digunakan dalam skeleton view
    }
}
