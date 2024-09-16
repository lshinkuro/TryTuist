//
//  MenuAdsCell.swift
//  HomeFeature
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import Foundation
import UIKit
import TTUI


class MenuAdsCell: UITableViewCell {

    private let adsImageView = UIImageView()
    
    let formView: FormView = {
        let fvw = FormView()
        fvw.clipsToBounds = true
        return fvw
    }()
 

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupStyles()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Mengatur gaya tampilan (opsional)
    private func setupStyles() {
        selectionStyle = .none
        adsImageView.contentMode = .scaleToFill
        adsImageView.image = UIImage(named: "bg-1")
        adsImageView.contentMode = .scaleToFill
    }

    private func setupViews() {
        contentView.addSubview(formView)
        formView.addSubview(adsImageView)
        
        formView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.verticalEdges.equalToSuperview().inset(8)
        }

        // Configure your views and add layout constraints
        adsImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(100)
        }
    }
    
    func populate(image: UIImage) {
        adsImageView.image = image
    }
}
