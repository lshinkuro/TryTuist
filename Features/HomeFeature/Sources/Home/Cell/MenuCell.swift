//
//  MenuCell.swift
//  HomeFeature
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import UIKit
import TTUI

class MenuCell: UITableViewCell {
    
    let formView: FormView = {
        let fvw = FormView()
        return fvw
    }()

    let menuStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        configureCollection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        collectionView.backgroundColor = .clear
        
        contentView.addSubview(formView)
        formView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.verticalEdges.equalToSuperview().inset(8)

        }
        
        formView.addSubview(menuStackView)
        menuStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(80) // Adjust height as needed
        }
        
        formView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
          make.top.equalTo(menuStackView.snp.bottom).offset(16)
          make.left.right.equalToSuperview().inset(16)
          make.height.equalTo(100) // Adjust height as needed
          make.bottom.equalToSuperview().offset(-16)
       }
    }
    
    func configureCollection() {
        collectionView.register(TopBannerItemCell.self, forCellWithReuseIdentifier: "MenuItemCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
    }
}

extension MenuCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4 // Adjust based on your data
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuItemCell", for: indexPath)
        cell.backgroundColor = .gray // Customize the cell as needed
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.bounds.width/4, height: 80) // Adjust size as needed
    }
}
