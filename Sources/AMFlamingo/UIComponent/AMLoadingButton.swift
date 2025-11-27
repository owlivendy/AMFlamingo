//
//  AMLoadingButton.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import UIKit

@objcMembers
open class AMLoadingButton: UIControl {
    // MARK: - Public Properties
    open var isLoading: Bool = false {
        didSet { updateLoadingState() }
    }
    open var loadingImage: UIImage? {
        didSet { imageView.image = loadingImage }
    }
    open var text: String? {
        didSet { label.text = text }
    }
    open var loadingText: String? = nil
    open var textColor: UIColor? {
        didSet { label.textColor = textColor }
    }
    open var font: UIFont? {
        didSet { label.font = font }
    }
    
    // MARK: - Private UI
    private let imageView = UIImageView()
    private let label = UILabel()
    private let hStack = UIStackView()
    
    // MARK: - Init
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 10
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.isUserInteractionEnabled = false
        addSubview(hStack)
        
        imageView.image = UIImage.am_Image(named: "loading-white-style1")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(imageView)
        
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(label)
        
        NSLayoutConstraint.activate([
            hStack.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            hStack.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            hStack.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 8),
            hStack.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -8),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        updateLoadingState()
    }
    
    private func updateLoadingState() {
        if isLoading {
            if let loadingText = loadingText {
                label.text = loadingText
            } else {
                label.text = text
            }
            imageView.isHidden = false
            startLoadingAnimation()
            self.isUserInteractionEnabled = false
        } else {
            label.text = text
            imageView.isHidden = true
            stopLoadingAnimation()
            self.isUserInteractionEnabled = true
        }
    }
    
    private func startLoadingAnimation() {
        guard imageView.layer.animation(forKey: "rotationAnimation") == nil else { return }
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = Float.infinity
        imageView.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    private func stopLoadingAnimation() {
        imageView.layer.removeAnimation(forKey: "rotationAnimation")
    }
}
