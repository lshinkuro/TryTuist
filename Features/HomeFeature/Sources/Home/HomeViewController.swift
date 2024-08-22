//
//  HomeViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import UIKit

class HomeViewController: UIViewController {
    
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

        // Do any additional setup after loading the view.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
