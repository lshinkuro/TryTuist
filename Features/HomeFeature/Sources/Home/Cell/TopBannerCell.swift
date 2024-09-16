//
//  TopBannerCell.swift
//  HomeFeature
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import UIKit
import TTUI

struct TopBannerItem: Equatable {
    let image: UIImage?
    let title: String
    let subtitle: String
    let bgImage: UIImage?
}

class TopBannerCell: UITableViewCell {

    private let bannerImageView = UIImageView()
    
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
    
    let headerView = CustomHeaderView()
    
    
    var items: [TopBannerItem] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        configureCollection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none
        
        contentView.addSubview(bannerImageView)
        bannerImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(400)
            make.bottom.equalToSuperview().offset(-40)
        }
        
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(400)
            make.bottom.equalToSuperview().offset(-40)

        }
        
        contentView.addSubview(pageControl)
        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(collectionView.snp.bottom).offset(-20)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(20)
        }
        
        contentView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(60)
            make.bottom.equalToSuperview()
        }
        
    }
    
    func configureCollection() {
        collectionView.register(TopBannerItemCell.self, forCellWithReuseIdentifier: "TopBannerItemCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
    }
        
}

extension TopBannerCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pageControl.numberOfPages = self.items.count
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(forIndexPath: indexPath) as TopBannerItemCell
        let item = items[indexPath.item]
        cell.configure(with: item)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
}


class CustomHeaderView: UIView {
    
    
    let formView: FormView = {
        let fvw = FormView()
        return fvw
    }()
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.text = "Hi, Ishinkuro"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let ticketsIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "tickets_icon") // Replace with your icon image name
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let ticketsLabel: UILabel = {
        let label = UILabel()
        label.text = "1"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black
        return label
    }()
    
    private let pointsIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "points_icon") // Replace with your icon image name
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.text = "104 pts"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(formView)
        formView.add(greetingLabel, ticketsIcon, ticketsLabel,pointsIcon, pointsLabel)
        setupConstraints()
    }
    
    private func setupConstraints() {
        
        formView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        greetingLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        ticketsIcon.snp.makeConstraints { make in
            make.leading.equalTo(greetingLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20) // Adjust size as needed
        }
        
        ticketsLabel.snp.makeConstraints { make in
            make.leading.equalTo(ticketsIcon.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        
        pointsIcon.snp.makeConstraints { make in
            make.leading.equalTo(ticketsLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20) // Adjust size as needed
        }
        
        pointsLabel.snp.makeConstraints { make in
            make.leading.equalTo(pointsIcon.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
    }
}

