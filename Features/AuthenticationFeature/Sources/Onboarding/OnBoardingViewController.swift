//
//  OnBoardingViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 20/08/24.
//

import UIKit
import TTUI
import Utility
import RxSwift
import RxCocoa


struct OnboardingItem: Equatable {
    let image: UIImage?
    let title: String
    let subtitle: String
    let bgImage: UIImage?
}

class OnBoardingViewController: BaseViewController {
    
    let collectionView: UICollectionView = {
        let layout = CarouselLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    let pageControl: UIPageControl = {
        let pc = UIPageControl()
        return pc
    }()
    
    let skipButton: UIButton = {
        let bt = UIButton()
        bt.setTitle("Skip", for: .normal)
        return bt
    }()
    
    let nextButton: UIButton = {
        let bt = UIButton()
        bt.setTitle("NEXT", for: .normal)
        bt.layer.cornerRadius = 20
        bt.backgroundColor = UIColor.foodBrightBlue
        return bt
    }()
    
    let backgroundImage: UIImageView = {
        // Set the background image
        let bgImage = UIImageView()
        bgImage.image = UIImage(named: "bg-1")
        bgImage.contentMode = .scaleAspectFill
        bgImage.alpha = 0.3
        return bgImage
    }()
    
    
    weak var coordinator: OnBoardingCoordinator!
    
    private let items: [OnboardingItem] = [
        .init(image: UIImage(named: "onboarding-1"), title: "Manage your tasks", subtitle: "You can easily manage all of your daily tasks in DoMe for free", bgImage: UIImage(named: "bg-1")),
        .init(image: UIImage(named: "onboarding-2"), title: "Create daily routine", subtitle: "In Uptodo  you can create your personalized routine to stay productive", bgImage: UIImage(named: "bg-2")),
        .init(image: UIImage(named: "onboarding-3"), title: "Orgonaize your tasks", subtitle: "You can organize your daily tasks by adding your tasks into separate categories", bgImage: UIImage(named: "bg-3"))
    ]
    
    private var currentPage: Int = 0

    
    // MARK: used if screen using NIB file
    init(coordinator: OnBoardingCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: "OnBoardingViewController", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollection()
        setupView()
        setupAction()
    }
    
    func setupAction() {
        nextButton.rx.tap.subscribe(onNext:  { [weak self] _ in
            guard let self = self else { return }
            self.coordinator.goToLogin()
        }).disposed(by: disposeBag)
    }
    
    func setupView() {
        pageControl.pageIndicatorTintColor = .foodBrightCoral1
        pageControl.currentPageIndicatorTintColor = .gray
        
        view.addSubview(backgroundImage)
        view.addSubview(collectionView)
        view.addSubview(skipButton)
        view.addSubview(nextButton)
        view.addSubview(pageControl) // Tambahkan pageControl ke view
        
        collectionView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(400)
        }
        
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
        }
        
        nextButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-60)
            make.height.equalTo(40)
        }
        
        
        skipButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(50)
            make.height.equalTo(34)
        }
        
        backgroundImage.frame = view.bounds
            
    }
    
    func configureCollection() {
        collectionView.register(OnBoardCell.self, forCellWithReuseIdentifier: "OnBoardCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
    }
    


}

extension OnBoardingViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pageControl.numberOfPages = self.items.count
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(forIndexPath: indexPath) as OnBoardCell
        let item = items[indexPath.item]
        cell.configure(with: item)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard collectionView.frame.width > 0 else { return }

        let page = (collectionView.contentOffset.x / collectionView.frame.width)
            .rounded(.toNearestOrAwayFromZero)
        
        
        
        pageControl.currentPage = Int(page)
        
         let nextPage = page + 1
         let alphaValue = max(0.0, 1.0 - CGFloat(page / nextPage))

         UIView.animate(withDuration: 0.3) {
             self.backgroundImage.alpha = alphaValue
         }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let indexPath = collectionView.indexPathsForVisibleItems.first {
            currentPage = indexPath.row
            updateBackgroundImage(for: currentPage)
        }
    }

    private func updateBackgroundImage(for page: Int) {
        UIView.transition(with: backgroundImage, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.backgroundImage.image = self.items[page].bgImage
        }, completion: nil)
    }
}


