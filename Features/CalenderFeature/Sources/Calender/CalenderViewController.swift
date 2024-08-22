//
//  CalenderViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 21/08/24.
//

import UIKit

class CalenderViewController: UIViewController {

    weak var coordinator: CalenderCoordinator!
    
    init(coordinator: CalenderCoordinator!) {
      self.coordinator = coordinator
      super.init(nibName: "CalenderViewController", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "calender"
    }

}
