//
//  PhotoPreviewController.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import UIKit

// 代理协议定义
public protocol PhotoPreviewControllerDelegate: AnyObject {
    /// 点击重拍按钮回调
    func photoPreviewControllerDidRetake(_ controller: PhotoPreviewController)
    /// 点击使用照片按钮回调
    func photoPreviewController(_ controller: PhotoPreviewController, didUsePhoto image: UIImage)
}

/**
 图片预览，适用于场景：相机拍照后预览图片的页面
 */
open class PhotoPreviewController: UIViewController {
    
    // MARK: - 公共属性
    /// 需要预览的照片
    public var previewImage: UIImage?
    /// 代理对象
    public weak var delegate: PhotoPreviewControllerDelegate?
    
    // MARK: - 私有控件
    private let imagePreviewView = UIImageView()
    private let buttonContainer = UIView()
    private let retakeButton = UIButton(type: .custom)
    private let usePhotoButton = UIButton(type: .custom)
    
    // MARK: - 生命周期
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupPreviewView()
        setupButtons()
        setupLayout()
    }
    
    // MARK: - UI 配置
    private func setupBaseUI() {
        view.backgroundColor = .black
        // 隐藏导航栏（如果需要全屏预览）
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupPreviewView() {
        imagePreviewView.contentMode = .scaleAspectFit
        imagePreviewView.clipsToBounds = true
        imagePreviewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imagePreviewView)
        
        // 设置预览图片
        imagePreviewView.image = previewImage
    }
    
    private func setupButtons() {
        buttonContainer.backgroundColor = UIColor.systemGray2
        view.addSubview(buttonContainer)
        
        // 重拍按钮
        retakeButton.setTitle("重拍", for: .normal)
        retakeButton.setTitleColor(.white, for: .normal)
        retakeButton.layer.masksToBounds = true
        retakeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        retakeButton.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
        retakeButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(retakeButton)
        
        // 使用照片按钮
        usePhotoButton.setTitle("使用照片", for: .normal)
        usePhotoButton.setTitleColor(.white, for: .normal)
        usePhotoButton.layer.masksToBounds = true
        usePhotoButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        usePhotoButton.addTarget(self, action: #selector(usePhotoButtonTapped), for: .touchUpInside)
        usePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(usePhotoButton)
    }
    
    // MARK: - 布局约束
    private func setupLayout() {
        
        NSLayoutConstraint.activate([
            // 预览图约束（充满安全区域，底部留按钮空间）
            imagePreviewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imagePreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imagePreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // 重拍按钮约束
            retakeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 使用照片按钮约束
            usePhotoButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        buttonContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
            make.bottom.equalTo(view.snp.bottom).offset(0)
            make.top.equalTo(imagePreviewView.snp.bottom)
        }
        retakeButton.snp.makeConstraints { make in
            make.leading.equalTo(26)
            make.top.equalTo(14)
        }
        usePhotoButton.snp.makeConstraints { make in
            make.trailing.equalTo(-26)
            make.top.equalTo(retakeButton.snp.top)
        }
    }
    
    // MARK: - 按钮事件
    @objc private func retakeButtonTapped() {
        delegate?.photoPreviewControllerDidRetake(self)
    }
    
    @objc private func usePhotoButtonTapped() {
        guard let image = previewImage else { return }
        delegate?.photoPreviewController(self, didUsePhoto: image)
    }
    
    // MARK: - 导航栏控制
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 恢复导航栏（如果之前隐藏了）
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
