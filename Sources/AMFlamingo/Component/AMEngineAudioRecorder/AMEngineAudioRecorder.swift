//
//  AMEngineAudioRecorder.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//


import AVFoundation

@objcMembers
class AMEngineAudioRecorder: NSObject {
    // 音频引擎
    private let audioEngine = AVAudioEngine()
    // 输入节点
    private var inputNode: AVAudioInputNode!
    // 音频格式转换器
    private var converter: AVAudioConverter!
    // 录音状态
    private var isRecording = false
    // 音频索引
    private var audioIndex = 1
    // 音量更新回调
    var onVolumeUpdated: ((Float) -> Void)?
    // 音频数据回调
    var onAudioDataReceived: ((Data, Int) -> Void)?
    
    /// 开始录音
    /// - Parameters:
    ///   - pcmFormat: 位深格式，默认16位整数
    ///   - sampleRate: 采样率，默认16000Hz
    ///   - channels: 通道数，默认1（单声道）
    func startRecord(
        pcmFormat: AVAudioCommonFormat = .pcmFormatInt16,
        sampleRate: Double = 16000,
        channels: AVAudioChannelCount = 1
    ) {
        // 重置索引
        audioIndex = 1
        // 获取输入节点
        inputNode = audioEngine.inputNode
        // 获取输入格式
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // 创建目标录音格式
        guard let recordingFormat = AVAudioFormat(
            commonFormat: pcmFormat,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: true
        ) else {
            CHLogDebug("无法创建录音格式")
            return
        }
        
        // 创建格式转换器
        converter = AVAudioConverter(from: inputFormat, to: recordingFormat)
        
        // 安装音频输入监听
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, when in
            guard let self = self else { return }
            
            // 准备转换后的缓冲区
            let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: recordingFormat,
                frameCapacity: buffer.frameCapacity
            )!
            
            var inputStatus: AVAudioConverterInputStatus = .haveData
            
            // 输入数据块
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = inputStatus
                inputStatus = .noDataNow
                return buffer
            }
            
            // 执行格式转换
            var error: NSError?
            let conversionStatus = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            
            if error == nil {
                // 处理转换后的音频数据
                self.processAudioBuffer(convertedBuffer, format: pcmFormat)
            } else {
                CHLogDebug("音频转换失败: \(error!.localizedDescription)")
            }
        }
        
        // 准备并启动音频引擎
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            CHLogDebug("录音已开始")
        } catch {
            CHLogDebug("启动录音失败: \(error.localizedDescription)")
            isRecording = false
        }
    }
    
    /// 处理转换后的音频缓冲区
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, format: AVAudioCommonFormat) {
        let frameLength = buffer.frameLength
        guard frameLength > 0 else { return }
        
        // 根据位深获取音频数据
        let audioData: Data?
        switch format {
        case .pcmFormatInt16:
            guard let int16Buffer = buffer.int16ChannelData?[0] else { return }
            audioData = Data(bytes: int16Buffer, count: Int(frameLength) * MemoryLayout<Int16>.stride)
            
        case .pcmFormatInt32:
            guard let int32Buffer = buffer.int32ChannelData?[0] else { return }
            audioData = Data(bytes: int32Buffer, count: Int(frameLength) * MemoryLayout<Int32>.stride)
            
        case .pcmFormatFloat32:
            guard let float32Buffer = buffer.floatChannelData?[0] else { return }
            audioData = Data(bytes: float32Buffer, count: Int(frameLength) * MemoryLayout<Float32>.stride)
        default:
            CHLogDebug("不支持的音频格式")
            return
        }
        
        guard let data = audioData else { return }
        
        // 计算音量
        let bitDepth: PCMBitDepth
        switch format {
        case .pcmFormatInt16: bitDepth = .bit16
        case .pcmFormatInt32: bitDepth = .bit32
        default: bitDepth = .bit16
        }
        
        if onVolumeUpdated != nil {
            let channels = UInt(buffer.format.channelCount)            
            let volume = PCMVolumeCalculator.calculateAverageVolume(inDBFromPCM: data, bitDepth: bitDepth, channels: channels)
            onVolumeUpdated?(Float(volume))
        }
        
        // 转换为Base64并回调
//        let base64String = data.base64EncodedString().replacingOccurrences(of: "\n", with: "")
//        CHLogDebug("发送音频数据，索引: \(audioIndex)")
        onAudioDataReceived?(data, audioIndex)
        
        // 递增索引
        audioIndex += 1
    }
    
    /// 停止录音
    func stopRecord() {
        guard isRecording else { return }
        
        // 移除输入监听
        inputNode.removeTap(onBus: 0)
        // 停止音频引擎
        audioEngine.stop()
        isRecording = false
        CHLogDebug("录音已停止")
    }
}
