//
//  AMVideoPreviewController.swift
//  ChinaHomelife247
//
//  Created by meotech on 2025/9/25.
//  Copyright © 2025 吕欢. All rights reserved.
//

import AVKit
import UIKit
import Photos

class AMVideoPreviewController: AVPlayerViewController {
    private var overlayerView = UIView()
    private let savebutton = UIButton(type: .custom)
    
    var videoURL: URL?
    private var saveButtonHidden = false
    
    private var workItem: DispatchWorkItem?
    override func viewDidLoad() {
        super.viewDidLoad()
        if let videoURL = videoURL {
            let player = AVPlayer(url: videoURL)
            self.player = player
        }
        
        savebutton.alpha = saveButtonHidden ? 0 : 1
        savebutton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        savebutton.setTitle("保存", for: .normal)
        savebutton.setTitleColor(.white, for: .normal)
        savebutton.layer.cornerRadius = 10
        savebutton.addTarget(self, action: #selector(saveVideoToAlbum), for: .touchUpInside)
        
        view.addSubview(self.savebutton)
        savebutton.snp.makeConstraints { make in
            make.right.equalTo(view.snp.right).offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-100)
            make.size.equalTo(CGSize(width: 72, height: 36))
        }
        self.player?.play()
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // 已授权，执行保存操作
            } else {
                // 未授权，处理权限问题
            }
        }
        
        self.workItem = DispatchWorkItem {
            self.toggle(hidden: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: self.workItem!)
    }
    
    @objc func saveVideoToAlbum() {
        guard let videoURL = videoURL else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { success, error in
            if success {
                AMLogDebug("视频保存成功")
                performOnMainThread {
//                    Global.showSuccesToast(withText: "视频保存成功")
                }
            } else {
                AMLogDebug("视频保存失败: \(error?.localizedDescription ?? "未知错误")")
                performOnMainThread {
//                    Global.showErrorToast(withText: error?.localizedDescription ?? "未知错误")
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.workItem?.cancel()
        self.workItem = nil
        toggle()
    }
    
    func toggle(hidden: Bool? = nil) {
        saveButtonHidden = !saveButtonHidden
        if let hidden = hidden {
            saveButtonHidden = hidden
        }
        if saveButtonHidden {
            UIView.animate(withDuration: 0.3) {
                self.savebutton.alpha = 0
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.savebutton.alpha = 1
            }
        }
    }
}
