//
//  CustomTabBar.swift
//  TTUI
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import UIKit
import SnapKit

public class CustomTabBar: UIView {

    private var buttons: [UIButton] = []
    private let selectorView = UIView()
    private var selectedIndex: Int = 0

    public var titles: [String] = [] {
        didSet {
            setupButtons()
        }
    }

    public var buttonTapped: ((_ index: Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSelectorView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupButtons() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.gray, for: .normal)
            button.setTitleColor(.white, for: .selected)
            button.titleLabel?.font = UIFont.omoBold(16)
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            button.tag = index
            buttons.append(button)
            addSubview(button)
        }

        buttons[selectedIndex].isSelected = true
        layoutButtons()
    }

    private func setupSelectorView() {
        selectorView.backgroundColor = .systemBlue
        selectorView.layer.cornerRadius = 15
        addSubview(selectorView)
    }

    private func layoutButtons() {
        for (index, button) in buttons.enumerated() {
            button.snp.makeConstraints { make in
                if index == 0 {
                    make.leading.equalToSuperview()
                } else {
                    make.leading.equalTo(buttons[index - 1].snp.trailing)
                    make.width.equalTo(buttons[index - 1])
                }
                if index == buttons.count - 1 {
                    make.trailing.equalToSuperview()
                }
                make.top.bottom.equalToSuperview()
            }
        }

        layoutSelectorView()
    }

    private func layoutSelectorView() {
        guard selectedIndex < buttons.count else { return }
        let selectedButton = buttons[selectedIndex]

        selectorView.snp.remakeConstraints { make in
            make.leading.equalTo(selectedButton.snp.leading)
            make.trailing.equalTo(selectedButton.snp.trailing)
            make.height.equalToSuperview().multipliedBy(0.8)
            make.centerY.equalToSuperview()
        }

        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        let index = sender.tag
        selectTab(at: index)
        buttonTapped?(index)
    }

    func selectTab(at index: Int) {
        guard index != selectedIndex, index < buttons.count else { return }
        buttons[selectedIndex].isSelected = false
        buttons[index].isSelected = true
        buttons[index].backgroundColor = .clear

        selectedIndex = index
        layoutSelectorView()
    }
}
