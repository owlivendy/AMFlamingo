//
//  PCMVolumeCalculator.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/28.
//
import UIKit

/// PCM 音频位深枚举
enum PCMBitDepth: Int {
    case bit16 = 16
    case bit32 = 32
}
/// PCM 音频音量计算器（峰值/平均音量转分贝）
final class PCMVolumeCalculator {
    
    // MARK: - 计算峰值音量（分贝）
    static func calculatePeakVolume(inDBFromPCM pcmData: Data,
                                    bitDepth: PCMBitDepth,
                                    channels: UInt) -> CGFloat {
        // 空数据防护
        guard !pcmData.isEmpty else { return -CGFloat.infinity }
        
        let bytesPerSample = bitDepth.rawValue / 8
        let totalSamples = pcmData.count / bytesPerSample
        guard totalSamples > 0 else { return -CGFloat.infinity }
        
        // 转换 Data 为原始字节指针
        let bytes = pcmData.withUnsafeBytes { $0.baseAddress }
        guard let bytes = bytes else { return -CGFloat.infinity }
        
        var maxAmplitude: CGFloat = 0
        
        // 根据位深处理样本
        switch bitDepth {
        case .bit16:
            let samples = bytes.assumingMemoryBound(to: Int16.self)
            maxAmplitude = PCMVolumeCalculator.maxAmplitude(from16BitSamples: samples,
                                       sampleCount: totalSamples,
                                       channels: channels)
            
        case .bit32:
            let samples = bytes.assumingMemoryBound(to: Int32.self)
            maxAmplitude = PCMVolumeCalculator.maxAmplitude(from32BitSamples: samples,
                                       sampleCount: totalSamples,
                                       channels: channels)
        }
        
        // 振幅转分贝
        return amplitudeToDB(amplitude: maxAmplitude, bitDepth: bitDepth)
    }
    
    // MARK: - 计算平均音量（分贝）
    static func calculateAverageVolume(inDBFromPCM pcmData: Data,
                                       bitDepth: PCMBitDepth,
                                       channels: UInt) -> CGFloat {
        // 空数据防护
        guard !pcmData.isEmpty else { return -CGFloat.infinity }
        
        let bytesPerSample = bitDepth.rawValue / 8
        let totalSamples = pcmData.count / bytesPerSample
        guard totalSamples > 0 else { return -CGFloat.infinity }
        
        // 转换 Data 为原始字节指针
        let bytes = pcmData.withUnsafeBytes { $0.baseAddress }
        guard let bytes = bytes else { return -CGFloat.infinity }
        
        var averageAmplitude: CGFloat = 0
        
        // 根据位深处理样本
        switch bitDepth {
        case .bit16:
            let samples = bytes.assumingMemoryBound(to: Int16.self)
            averageAmplitude = PCMVolumeCalculator.averageAmplitude(from16BitSamples: samples,
                                               sampleCount: totalSamples,
                                               channels: channels)
            
        case .bit32:
            let samples = bytes.assumingMemoryBound(to: Int32.self)
            averageAmplitude = PCMVolumeCalculator.averageAmplitude(from32BitSamples: samples,
                                               sampleCount: totalSamples,
                                               channels: channels)
        }
        
        // 振幅转分贝
        return amplitudeToDB(amplitude: averageAmplitude, bitDepth: bitDepth)
    }
}

// MARK: - 私有辅助方法（16位/32位样本处理）
private extension PCMVolumeCalculator {
    
    /// 16位 PCM 样本获取最大振幅
    static func maxAmplitude(from16BitSamples samples: UnsafePointer<Int16>,
                             sampleCount: Int,
                             channels: UInt) -> CGFloat {
        var max: Int16 = 0
        let channelCount = Int(channels)
        
        // 按声道间隔遍历（只取第一个声道计算，与原 OC 逻辑一致）
        for i in stride(from: 0, to: sampleCount, by: channelCount) {
            let currentSample = abs(samples[i])
            if currentSample > max {
                max = currentSample
            }
        }
        return CGFloat(max)
    }
    
    /// 16位 PCM 样本获取平均振幅
    static func averageAmplitude(from16BitSamples samples: UnsafePointer<Int16>,
                                 sampleCount: Int,
                                 channels: UInt) -> CGFloat {
        var total: Int64 = 0
        let channelCount = Int(channels)
        var validSamples: UInt = 0
        
        // 按声道间隔遍历（只取第一个声道计算）
        for i in stride(from: 0, to: sampleCount, by: channelCount) {
            total += Int64(abs(samples[i]))
            validSamples += 1
        }
        
        guard validSamples > 0 else { return 0 }
        return CGFloat(total / Int64(validSamples))
    }
    
    /// 32位 PCM 样本获取最大振幅
    static func maxAmplitude(from32BitSamples samples: UnsafePointer<Int32>,
                             sampleCount: Int,
                             channels: UInt) -> CGFloat {
        var max: Int32 = 0
        let channelCount = Int(channels)
        
        // 按声道间隔遍历（只取第一个声道计算）
        for i in stride(from: 0, to: sampleCount, by: channelCount) {
            let currentSample = abs(samples[i])
            if currentSample > max {
                max = currentSample
            }
        }
        return CGFloat(max)
    }
    
    /// 32位 PCM 样本获取平均振幅
    static func averageAmplitude(from32BitSamples samples: UnsafePointer<Int32>,
                                 sampleCount: Int,
                                 channels: UInt) -> CGFloat {
        var total: Int64 = 0
        let channelCount = Int(channels)
        var validSamples: UInt = 0
        
        // 按声道间隔遍历（只取第一个声道计算）
        for i in stride(from: 0, to: sampleCount, by: channelCount) {
            total += Int64(abs(samples[i]))
            validSamples += 1
        }
        
        guard validSamples > 0 else { return 0 }
        return CGFloat(total / Int64(validSamples))
    }
    
    /// 振幅值转分贝（核心公式：20 * log10(相对振幅)）
    static func amplitudeToDB(amplitude: CGFloat, bitDepth: PCMBitDepth) -> CGFloat {
        // 避免 0 振幅导致 log10 出错
        guard amplitude > 0 else { return -CGFloat.infinity }
        
        // 计算对应位深的最大振幅（16位：32767，32位：2147483647）
        let maxAmplitude: CGFloat = switch bitDepth {
        case .bit16: 32767.0
        case .bit32: 2147483647.0
        }
        
        // 相对振幅（0.0 ~ 1.0）→ 转分贝
        let relativeAmplitude = amplitude / maxAmplitude
        return 20 * log10(relativeAmplitude)
    }
}
