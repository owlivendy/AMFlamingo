//
//  AMStreamAudioPlayer.swift
//  ChinaHomelife247
//
//  Created by shen xiaofei on 2025/9/22.
//  Copyright © 2025 fei. All rights reserved.
//

import AVFoundation

class AMStreamAudioPlayer: NSObject {
    // 核心播放器
    private var player: AVAudioPlayer?
    // 音频队列（处理分片顺序）
    private var fragmentQueue: [Int: Data] = [:]
    private var lastFragmentSeq: Int?
    // 下一个期望的分片序号
    private var nextExpectedSeq: Int = 0
    // 播放状态
    private(set) var isPlaying: Bool = false
    private var isFragmentPlaying: Bool = false
    
    // 播放完成回调
    var onFinish: ((Bool) -> Void)?
    // 错误回调
    var onError: ((Error) -> Void)?
    
    var workQueue = DispatchQueue(label: "com.meorient.steamAudioPlayer")
    
    var identifier: String?
    
    func onQueueFinished() {
        AMLogDebug("onQueueFinished")
        // 队列播放完成后的处理
        self.stop()
    }
    
    deinit {
        AMLogDebug("AMStreamAudioPlayer deinit!!!")
        cleanup()
    }
    
    // 配置音频会话
    static func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: [
                .duckOthers
            ])
            try AVAudioSession.sharedInstance().setActive(true)
            AMLogDebug("[CHSteamAudioPlayer] ✅ Audio Session 配置成功")
            AMLogDebug("[CHSteamAudioPlayer] 📊 当前路由: \(AVAudioSession.sharedInstance().currentRoute)")
        } catch {
            AMLogDebug("[CHSteamAudioPlayer] ❌ Audio Session 配置失败: \(error.localizedDescription)")
            AMLogDebug("[CHSteamAudioPlayer] Audio Session 错误详情: \(error)")
        }
    }
    
    // 清理资源
    private func cleanup() {
        // 移除所有observers
        NotificationCenter.default.removeObserver(self)
    }
    
    // 添加base64编码的MP3分片
    func addStreamFragment(base64Data: String, sequence: Int, last: Bool) {
        guard let mp3Data = Data(base64Encoded: base64Data, options: .ignoreUnknownCharacters) else {
            onError?(NSError(domain: "AMStreamAudioPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "base64解码失败"]))
            return
        }
        AMLogDebug("addStreamFragment seq: \(sequence), last: \(last)")
        if last {
            self.lastFragmentSeq = sequence
        }
        // 线程安全地添加到队列
        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.fragmentQueue[sequence] = mp3Data
            if !self.isFragmentPlaying && nextExpectedSeq == sequence {
                AMLogDebug("addStreamFragment & tryPlayNextFragment")
                self.tryPlayNextFragment()
            }
        }
    }
    
    // 尝试播放下一个分片（按序号顺序）
    private func tryPlayNextFragment() {
        guard let data = fragmentQueue[nextExpectedSeq] else {
            AMLogDebug("[CHSteamAudioPlayer] 没有找到下一个播放分片！！！ 索引\(nextExpectedSeq)")
            return
        }
        
        do {
            player = try AVAudioPlayer(data: data)
            if !isPlaying {
                Self.setupAudioSession()
            }
            player?.delegate = self
            let res = player?.play()
            if res == false {
                AMLogError("[AMStreamAudioPlayer] play failed")
                return
            }
            isPlaying = true
            isFragmentPlaying = true
            // 移除已处理的分片
            fragmentQueue.removeValue(forKey: nextExpectedSeq)
            nextExpectedSeq += 1
        } catch {
            onError?(error)
        }
    }
    
    // 停止播放并重置
    func stop() {
        AMLogDebug("steam audio player stoped!!")
        player?.stop()
        player = nil
        isPlaying = false
        isFragmentPlaying = false
        fragmentQueue.removeAll()
        nextExpectedSeq = 0
        lastFragmentSeq = nil
        cleanup()
    }
}

//MARK: AVAudioPlayerDelegate
extension AMStreamAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isFragmentPlaying = false
        
        if let lastSeq = lastFragmentSeq, nextExpectedSeq > lastSeq {
            //已经播放完最后一个分片
            self.onQueueFinished()
            self.onFinish?(true)
            
            isPlaying = false
            return
        }
        
        guard flag else {
            AMLogError("[AMStreamAudioPlayer] did finish play error!!!")
            self.onFinish?(false)
            return
        }
        workQueue.async {
            AMLogDebug("audioPlayerDidFinishPlaying & tryPlayNextFragment")
            self.tryPlayNextFragment()
        }
    }
}
