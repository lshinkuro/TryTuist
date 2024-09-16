//
//  MissionCell.swift
//  HomeFeature
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import UIKit
import SnapKit
import TTUI

import UIKit
import SnapKit

class MissionCell: UITableViewCell {
    
    private let cardStackView = UIStackView()
    private var cardViews: [UIView] = []
    private var currentIndex: Int = 0
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        selectionStyle = .none
        cardStackView.axis = .horizontal
        cardStackView.alignment = .center
        cardStackView.distribution = .fillEqually
        cardStackView.spacing = 20
        contentView.addSubview(cardStackView)
        
        cardStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        
        // Creating cards with different content/colors
        for i in 0..<4 {
            let cardView = InputField()
            cardView.layer.cornerRadius = 10
            cardView.clipsToBounds = true
            cardView.layer.backgroundColor = colorForIndex(i).cgColor
            cardStackView.addArrangedSubview(cardView)
            cardViews.append(cardView)
        }
        
        // Only show the first card initially
        for i in 1..<cardViews.count {
            cardViews[i].isHidden = true
        }
    }
    
    private func colorForIndex(_ index: Int) -> UIColor {
        switch index {
        case 0: return .red
        case 1: return .green
        case 2: return .blue
        case 3: return .yellow
        default: return .clear
        }
    }
    
    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        contentView.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentView)
        let velocity = gesture.velocity(in: contentView)
        
        if gesture.state == .changed {
            cardViews[currentIndex].transform = CGAffineTransform(translationX: translation.x, y: 0)
        } else if gesture.state == .ended {
            if abs(velocity.x) > 500 || abs(translation.x) > contentView.frame.width / 2 {
                // Determine swipe direction and update the current index
                if translation.x < 0 { // Swipe to left
                    currentIndex = (currentIndex + 1) % cardViews.count
                } else { // Swipe to right
                    currentIndex = (currentIndex - 1 + cardViews.count) % cardViews.count
                }
                
                let nextCardIndex = (translation.x < 0) ? (currentIndex + 1) % cardViews.count : (currentIndex - 1 + cardViews.count) % cardViews.count
                
                let direction: CGFloat = translation.x < 0 ? -1 : 1
                let nextCardView = cardViews[nextCardIndex]
                nextCardView.isHidden = false
                nextCardView.transform = CGAffineTransform(translationX: direction * contentView.frame.width, y: 0)
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.cardViews[self.currentIndex].transform = CGAffineTransform(translationX: -direction * self.contentView.frame.width, y: 0)
                    nextCardView.transform = .identity
                }) { _ in
                    self.cardViews[self.currentIndex].isHidden = true
                    self.cardViews[self.currentIndex].transform = .identity
                    self.currentIndex = nextCardIndex
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.cardViews[self.currentIndex].transform = .identity
                }
            }
        }
    }
}
