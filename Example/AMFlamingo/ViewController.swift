//
//  ViewController.swift
//  AMFlamingo
//
//  Created by sxf on 06/11/2025.
//  Copyright (c) 2025 sxf. All rights reserved.
//

import UIKit
import AMFlamingo

class ViewController: UIViewController {
    
    private let tagContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupTagContainer()
    }
    
    private func setupTagContainer() {
        // 设置 tagContainer
        tagContainer.backgroundColor = .systemBackground
        tagContainer.layer.cornerRadius = 8
        tagContainer.layer.borderWidth = 1
        tagContainer.layer.borderColor = UIColor.systemGray5.cgColor
        view.addSubview(tagContainer)
        
        // 设置 tagContainer 的约束
        tagContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tagContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            tagContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tagContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 创建标签
        let tags = ["Swift", "iOS", "UIKit", "SwiftUI", "Xcode", "Objective-C"]
        var tagViews: [UIView] = []
        
        for tag in tags {
            let tagView = createTagView(text: tag)
            tagViews.append(tagView)
        }
        
        // 使用 flowHorizontalSubViews 布局标签
        let config = AMFlowlayoutConfig(maxWidth: UIScreen.main.bounds.width - 40)
        config.spacing = 8
        config.verticalSpacing = 8
        config.padding = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        
        let height = tagContainer.flowHorizontalSubViews(tagViews, config: config)
        
        // 更新 tagContainer 的高度约束
        tagContainer.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    private func createTagView(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray4.cgColor
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.textAlignment = .center
        
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        
        return container
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

