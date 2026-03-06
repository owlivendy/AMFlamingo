//
//  AMChunkAudioPlayer.swift
//  ChinaHomelife247
//
//  使用 AVAudioEngine + AVAudioPlayerNode 实现句子级流式播放。
//  每次 addChunk(data:) 传入的是一句完整音频（MP3/AAC/PCM），按调用顺序排队播放。
//
//  Copyright © 2026 吕欢. All rights reserved.
//

import AVFoundation

class AMChunkAudioPlayer: NSObject {

    // MARK: - Public Callbacks
    var onError: ((Error) -> Void)?

    // MARK: - Private: AVAudioEngine
    private let engine     = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    // MARK: - Private: 串行队列
    private let serialQueue = DispatchQueue(label: "com.chinahomelife.chunkAudioPlayer")

    // MARK: - Public: 状态
    /// 当前是否正在播放
    var isPlaying: Bool { return engineStarted && playerNode.isPlaying && !isStopped }
    
    // MARK: - Private: 状态
    private var engineStarted   = false
    private var isStopped       = false
    private var connectedFormat: AVAudioFormat? = nil

    // MARK: - Init
    override init() {
        super.init()
        // 只 attach，不 connect——等第一个 buffer 拿到真实 format 后再 connect
        engine.attach(playerNode)
    }

    deinit {
        _teardown()
        AMLogDebug("AMChunkAudioPlayer deinit")
    }

    // MARK: - Public API

    /// 追加一句完整音频 Data（MP3/AAC/PCM），按调用顺序排队播放
    func addChunk(data: Data) {
        serialQueue.async { [weak self] in
            guard let self, !self.isStopped else { return }

            guard let buffer = self._decodeToBuffer(data: data) else {
                AMLogError("[AMChunkAudioPlayer] 无法解码音频")
                self.onError?(AMChunkAudioPlayerError.decodeFailed)
                return
            }

            do {
                try self._startEngineIfNeeded(format: buffer.format)
            } catch {
                AMLogError("[AMChunkAudioPlayer] engine 启动失败: \(error)")
                self.onError?(error)
                return
            }

            self.playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                AMLogDebug("[AMChunkAudioPlayer] 句子播放完毕")
            }
            AMLogDebug("[AMChunkAudioPlayer] 已调度句子 format=\(buffer.format)")
        }
    }

    /// 停止播放，重置所有状态
    func stop() {
        serialQueue.async { [weak self] in
            self?._stopInternal()
        }
    }
    
    /// 恢复播放状态
    func resume() {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            self.isStopped = false
        }
    }

    // MARK: - Private: Engine

    /// 第一次调用时用 buffer 真实 format 建立连接，避免 channel count 不匹配崩溃
    private func _startEngineIfNeeded(format: AVAudioFormat) throws {
        if engineStarted {
            // format 变化时重建连接（同一 TTS session 通常不会变）
            guard connectedFormat?.channelCount != format.channelCount ||
                  connectedFormat?.sampleRate   != format.sampleRate else { return }
            playerNode.stop()
            engine.stop()
            engine.disconnectNodeOutput(playerNode)
            engineStarted   = false
            connectedFormat = nil
        }

        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        connectedFormat = format

        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
        try engine.start()
        playerNode.play()
        engineStarted = true
        AMLogDebug("[AMChunkAudioPlayer] engine 已启动 format=\(format)")
    }

    private func _teardown() {
        playerNode.stop()
        if engine.isRunning { engine.stop() }
    }

    private func _stopInternal() {
        guard !isStopped else { return }
        isStopped       = true
        engineStarted   = false
        connectedFormat = nil
        playerNode.stop()
        if engine.isRunning { engine.stop() }
    }

    // MARK: - Private: 解码（完整 MP3 → AVAudioPCMBuffer）

    private func _decodeToBuffer(data: Data) -> AVAudioPCMBuffer? {
        do {
            let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString + ".mp3")
            try data.write(to: tmpURL)
            defer { try? FileManager.default.removeItem(at: tmpURL) }

            let audioFile  = try AVAudioFile(forReading: tmpURL)
            let frameCount = AVAudioFrameCount(audioFile.length)
            guard frameCount > 0,
                  let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                                   frameCapacity: frameCount) else { return nil }
            try audioFile.read(into: pcmBuffer)
            return pcmBuffer
        } catch {
            AMLogError("[AMChunkAudioPlayer] 解码失败: \(error)")
            return nil
        }
    }

    // MARK: - Error
    enum AMChunkAudioPlayerError: LocalizedError {
        case decodeFailed
        var errorDescription: String? { "音频解码失败" }
    }
}
