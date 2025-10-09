//
//  AMAudioPlayer.swift
//  ChinaHomelife247
//
//  Created by shen xiaofei on 2025/9/22.
//  Copyright © 2025 fei. All rights reserved.
//

import AVFoundation

class AMAudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    
    var playerDidFinished: ((Bool)->(Void))?
    
    // 播放本地音频文件
    func playLocalAudio(fileName: String, fileType: String) {
        // 停止当前播放（如果有）
        stop()
        
        // 获取音频文件路径
        guard let path = Bundle.main.path(forResource: fileName, ofType: fileType) else {
            AMLogDebug("找不到音频文件：\(fileName).\(fileType)")
            return
        }
        let url = URL(fileURLWithPath: path)
        
        do {
            // 初始化音频播放器
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            // 设置代理以监听播放完成事件
            audioPlayer?.delegate = self
            // 准备播放（预加载音频数据到内存）
            if audioPlayer?.prepareToPlay() ?? false {
                // 设置音量（0.0 ~ 1.0）
                audioPlayer?.volume = 1.0
                // 开始播放
                audioPlayer?.play()
                AMLogDebug("开始播放音频：\(fileName).\(fileType)")
            } else {
                AMLogDebug("音频准备失败")
            }
        } catch {
            AMLogDebug("音频初始化失败：\(error.localizedDescription)")
        }
    }
    
    // 暂停播放
    func pause() {
        if audioPlayer?.isPlaying ?? false {
            audioPlayer?.pause()
            AMLogDebug("音频已暂停")
        }
    }
    
    // 停止播放
    func stop() {
        audioPlayer?.stop()
        // 重置播放进度到开头
        audioPlayer?.currentTime = 0
        AMLogDebug("音频已停止")
    }
    
    // 音频播放完成回调
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            AMLogDebug("音频播放完成")
        } else {
            AMLogDebug("音频播放中断")
        }
        playerDidFinished?(flag)
    }
    
    // 音频解码错误回调
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            AMLogDebug("音频解码错误：\(error.localizedDescription)")
        }
    }
}
