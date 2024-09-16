//
//  HomeViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import UIKit
import SkeletonView
import UserNotifications
import CoreDataManager
import Toast
import TTUI

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    private let coreDataManager = CoreDataManager.shared
    private var quickSendDataArray: [UserModel] = []
    
    
    
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
        setup()
        loadData()
    }
    
    private func loadData() {
        fetchModel()
    }
    
    private let items: [TopBannerItem] = [
        .init(image: UIImage(named: "onboarding-1"), title: "Manage your tasks", subtitle: "You can easily manage all of your daily tasks in DoMe for free", bgImage: UIImage(named: "bg-1")),
        .init(image: UIImage(named: "onboarding-2"), title: "Create daily routine", subtitle: "In Uptodo  you can create your personalized routine to stay productive", bgImage: UIImage(named: "bg-2")),
        .init(image: UIImage(named: "onboarding-3"), title: "Orgonaize your tasks", subtitle: "You can organize your daily tasks by adding your tasks into separate categories", bgImage: UIImage(named: "bg-3"))
    ]
    
    private func fetchModel() {
        
        do {
            let newItemProperties: [String: Any] = [
                "id": "1",
                "avatar": "avatar",
                "userName": "bagus",
                "email": "bagus@gmail.com",
                "phoneNumber": "0857753810923"
            ]
            
            _ = try CoreDataManager.shared.create(entity: UserModel.self, properties: newItemProperties)
        }  catch {
            print("Failed to add to Quick Send: \(error)")
        }
        
        
        do {
            quickSendDataArray = try coreDataManager.fetch(entity: UserModel.self, fetchLimit: 5)
            if !quickSendDataArray.isEmpty {
                print("ada isinya")
            } else {
                print("kosong")
            }
            reloadSection(.sectionFour)
        } catch {
            print("Failed to fetch contacts: \(error.localizedDescription)")
        }
    }
    
}

extension HomeViewController {
    func setup() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        
        // Register custom cells and headers
        tableView.register(TopBannerCell.self, forCellReuseIdentifier: "TopBannerCell")
        tableView.register(MenuCell.self, forCellReuseIdentifier: "MenuCell")
        tableView.register(MissionCell.self, forCellReuseIdentifier: "MissionCell")
        tableView.register(MenuAdsCell.self, forCellReuseIdentifier: "MenuAdsCell")
        
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
                return 0
            }
        switch tableViewSection {
        case .sectionOne:
            return 1 // Top banner section
        case .sectionTwo:
            return 1 // Menu section
        case .sectionThree:
            return 0
        case .sectionFour:
            return quickSendDataArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
                return UITableViewCell()
            }
        switch tableViewSection {
        case .sectionOne:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopBannerCell", for: indexPath) as! TopBannerCell
            cell.items = items
            return cell
        case .sectionTwo:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath) as! MenuCell
            return cell
        case .sectionThree:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MissionCell", for: indexPath) as! MissionCell
            return cell
        case .sectionFour:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuAdsCell", for: indexPath) as! MenuAdsCell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func reloadSection(_ section: TableViewSection, with animation: UITableView.RowAnimation = .automatic) {
        let indexSet = IndexSet(integer: section.rawValue)
        tableView.reloadSections(indexSet, with: animation)
    }
}

extension HomeViewController: SkeletonTableViewDataSource {
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "MissionCell" // Identifier sel yang digunakan dalam skeleton view
    }
}

enum TableViewSection: Int, CaseIterable {
    case sectionOne
    case sectionTwo
    case sectionThree
    case sectionFour


    static func numberOfSections() -> Int {
        return TableViewSection.allCases.count
    }
}
