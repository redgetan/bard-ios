//
//  VideoMergeManager.swift
//  VideoMerger
//
//  Created by 1 on 23/08/16.
//  Copyright © 2016 Example. All rights reserved.
//

import Foundation
import AVFoundation

public let VideoMergeManagerVerbose: Bool = false // TODO: implement
public let VideoMergeManagerPrintPts: Bool = false
public let VideoMergeManagerDomain: String = "co.bard"

public enum VideoMergeManagerErrorCode: Int {
    case WrongInputParameters = -10000
    case CannotFindVideoDescriptionInSourceFile = -10001
    case CannotCreateAssetVideoWriter = -10002
    case CannotCreateVideoInput = -10003
}

private let kVideoMergeManagerOutFps = 30

class VideoMergeManager
{
    static func mergeMultipleVideos(destinationPath destinationPath: String, filePaths: [String], finished: ((NSError?, NSURL?) -> Void))
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            // Check input parametes
            if filePaths.count < 1 {
                let error = NSError(domain: VideoMergeManagerDomain,
                                    code: VideoMergeManagerErrorCode.WrongInputParameters.rawValue,
                                    userInfo: [NSLocalizedDescriptionKey: "Please, check [filePaths]."])
                dispatch_async(dispatch_get_main_queue(), {
                    finished(error, nil)
                })
                return
            }
            
            // Get audio and video format description
            let formatDescriptionTuple: (videoFormatHint: CMFormatDescriptionRef?,
                audioFormatHint: CMFormatDescriptionRef?) = findFormatDescription(filePaths.first!)
            
            if formatDescriptionTuple.videoFormatHint == nil {
                let error = NSError(domain: VideoMergeManagerDomain,
                                    code: VideoMergeManagerErrorCode.CannotFindVideoDescriptionInSourceFile.rawValue,
                                    userInfo: [NSLocalizedDescriptionKey: "Can't find video format description in source file."])
                dispatch_async(dispatch_get_main_queue(), {
                    finished(error, nil)
                })
                return
            }
            
            let videoFormatHint: CMFormatDescriptionRef = formatDescriptionTuple.videoFormatHint!
            let audioFormatHint: CMFormatDescriptionRef? = formatDescriptionTuple.audioFormatHint
            
            let audioStreamBasicDescription  = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatHint!).memory
            let sampleRate = audioStreamBasicDescription.mSampleRate
            let framesPerPacket = audioStreamBasicDescription.mFramesPerPacket
            
            // Prepare asset writer
            var assetWriter: AVAssetWriter
            var videoInput: AVAssetWriterInput
            var audioInput: AVAssetWriterInput? // optional
            
            let assetWriterTuple: (writer: AVAssetWriter?,
                videoInput: AVAssetWriterInput?,
                audioInput:AVAssetWriterInput?) = prepareAssetWriter(destinationPath: destinationPath,
                                                                     videoFormatHint: videoFormatHint,
                                                                     audioFormatHint: audioFormatHint)
            if let test = assetWriterTuple.writer {
                assetWriter = test
            }
            else {
                let error = NSError(domain: VideoMergeManagerDomain,
                                    code: VideoMergeManagerErrorCode.CannotCreateAssetVideoWriter.rawValue,
                                    userInfo: [NSLocalizedDescriptionKey: "Can't create asset video writer"])
                dispatch_async(dispatch_get_main_queue(), {
                    finished(error, nil)
                })
                return
            }
            
            if let test = assetWriterTuple.videoInput {
                videoInput = test
            }
            else {
                let error = NSError(domain: VideoMergeManagerDomain,
                                    code: VideoMergeManagerErrorCode.CannotCreateVideoInput.rawValue,
                                    userInfo: [NSLocalizedDescriptionKey: "Can't create video input"])
                dispatch_async(dispatch_get_main_queue(), {
                    finished(error, nil)
                })
                return
            }
            
            if let test = assetWriterTuple.audioInput {
                audioInput = test
            }
            else {
                print("Can't create audio input")
            }
            
            // Start writing
            assetWriter.startWriting()
            assetWriter.startSessionAtSourceTime(kCMTimeZero)
            
            var index = 0
            var isLastFilePath = false
            var audioSampleBuffer: CMSampleBuffer
            var videoSampleBuffer: CMSampleBuffer
            var audioBasePts: CMTime = kCMTimeZero
            var videoBasePts: CMTime = kCMTimeZero
            var lastAudioPts: CMTime = kCMTimeZero
            var lastVideoPts: CMTime = kCMTimeZero
            
            //
            for filePath in filePaths
            {
                isLastFilePath = index == (filePaths.count - 1)
                
                // Prepare asset reader
                var assetReader: AVAssetReader
                var videoOutput: AVAssetReaderTrackOutput
                var audioOutput: AVAssetReaderTrackOutput? // optional
                
                let assetReaderTuple: (reader: AVAssetReader?,
                    videoOutput: AVAssetReaderTrackOutput?,
                    audioOutput: AVAssetReaderTrackOutput?) = prepareAssetReader(filePath: filePath)
                
                if let test = assetReaderTuple.reader {
                    assetReader = test
                }
                else {
                    print("Can't create asset reader for this path: \(filePath)")
                    continue;
                }
                
                if let test = assetReaderTuple.videoOutput {
                    videoOutput = test
                }
                else {
                    print("Can't create video output for this path: \(filePath)")
                    continue;
                }
                
                if let test = assetReaderTuple.audioOutput {
                    audioOutput = test
                }
                else {
                    print("Can't create audio output for this path: \(filePath)")
                }
                
                // Start reading
                assetReader.startReading()
                
                while assetReader.status == .Reading
                {
                    // Video
                    if let test = videoOutput.copyNextSampleBuffer() {
                        videoSampleBuffer = test
                        
                        while !videoInput.readyForMoreMediaData {
                            usleep(100) // TODO: add limit
                        }
                        
                        if videoBasePts.value != 0 {
                            let newPts: CMTime = CMTimeAdd(CMSampleBufferGetPresentationTimeStamp(videoSampleBuffer), videoBasePts)
                            let changedSampleBuffer:CMSampleBuffer? = copySampleBufferWithPresentationTime(sampleBuffer: videoSampleBuffer,
                                                                                                           pts: newPts)
                            if let test = changedSampleBuffer {
                                videoSampleBuffer = test
                            }
                        }
                        
                        videoInput.appendSampleBuffer(videoSampleBuffer)
                        lastVideoPts = CMSampleBufferGetPresentationTimeStamp(videoSampleBuffer)
                        
                        if VideoMergeManagerPrintPts {
                            print("v: \(String(format: "%.4f", Double(lastVideoPts.value)/Double(lastVideoPts.timescale)))")
                        }
                    }
                    else {
                        assetReader.cancelReading()
                        break
                    }
                    
                    // Audio
                    if audioInput == nil || audioOutput == nil {
                        continue
                    }
                    
                    if let test = audioOutput!.copyNextSampleBuffer() {
                        audioSampleBuffer = test
                        
                        while !audioInput!.readyForMoreMediaData {
                            usleep(100) // TODO: add limit
                        }
                        
                        if audioBasePts.value != 0 {
                            let newPts: CMTime = CMTimeAdd(CMSampleBufferGetPresentationTimeStamp(audioSampleBuffer), audioBasePts)
                            let changedSampleBuffer:CMSampleBuffer? = copySampleBufferWithPresentationTime(sampleBuffer: audioSampleBuffer,
                                                                                                           pts: newPts)
                            if let test = changedSampleBuffer {
                                audioSampleBuffer = test
                            }
                        }
                        
                        let currentPts = CMSampleBufferGetPresentationTimeStamp(audioSampleBuffer)
                        let duration = CMSampleBufferGetDuration(audioSampleBuffer)
                        if !isLastFilePath && CMTIME_IS_VALID(currentPts) && duration.value > 0 {
                            audioInput!.appendSampleBuffer(audioSampleBuffer)
                            lastAudioPts = currentPts
                            
                            if VideoMergeManagerPrintPts {
                                print("a: \(String(format: "%.4f", Double(lastAudioPts.value)/Double(lastAudioPts.timescale)))")
                            }
                        }
                        else {
                            audioInput!.appendSampleBuffer(audioSampleBuffer)
                            lastAudioPts = currentPts
                            
                            if VideoMergeManagerPrintPts {
                                print("a: \(String(format: "%.4f", Double(lastAudioPts.value)/Double(lastAudioPts.timescale)))")
                            }
                        }
                    }
                    
                    if VideoMergeManagerPrintPts {
                        print("")
                    }
                }
                
                if !isLastFilePath {
                    if VideoMergeManagerPrintPts {
                        print("--")
                    }
                    
                    videoBasePts = CMTimeAdd(lastVideoPts, CMTimeMake(1, Int32(kVideoMergeManagerOutFps)))
                    audioBasePts = CMTimeAdd(lastAudioPts, CMTimeMake(Int64(framesPerPacket), Int32(sampleRate)))
                    
                    if VideoMergeManagerPrintPts {
                        print("vb: \(String(format: "%.4f", Double(videoBasePts.value)/Double(videoBasePts.timescale)))")
                        print("ab: \(String(format: "%.4f", Double(audioBasePts.value)/Double(audioBasePts.timescale)))")
                        print("")
                    }
                }
                
                index += 1
            }
            
            assetWriter.finishWritingWithCompletionHandler {
                switch assetWriter.status {
                case .Cancelled:
                    print("Cancelled")
                    break
                    
                case .Completed:
                    print("Completed")
                    break
                    
                case .Failed:
                    print("Failed")
                    break
                    
                case .Unknown:
                    print("Unknown")
                    break
                    
                case .Writing:
                    print("Writing")
                    break
                }
                
                print(destinationPath)
                dispatch_async(dispatch_get_main_queue(), {
                    finished(nil, NSURL(fileURLWithPath: destinationPath))
                })
            }
        }
    }
    
    static func copySampleBufferWithPresentationTime(sampleBuffer sampleBuffer: CMSampleBuffer, pts: CMTime) -> CMSampleBuffer?
    {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &count)
        let pInfo = UnsafeMutablePointer<CMSampleTimingInfo>(malloc(sizeof(CMSampleTimingInfo) * count))
        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, count, pInfo, &count)
        
        for i in 0..<count {
            pInfo[i].decodeTimeStamp = kCMTimeInvalid;
            pInfo[i].presentationTimeStamp = pts;
        }
        
        var newSampleBuffer: CMSampleBufferRef?
        CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBuffer, count, pInfo, &newSampleBuffer);
        free(pInfo);
        
        return newSampleBuffer
    }
    
    static func prepareAssetWriter(destinationPath destinationPath: String,
                                                   videoFormatHint: CMAudioFormatDescription,
                                                   audioFormatHint: CMAudioFormatDescription?) ->
        (writer: AVAssetWriter?,
        videoInput: AVAssetWriterInput?,
        audioInput:AVAssetWriterInput?)
    {
        var assetWriter: AVAssetWriter?
        do {
            assetWriter = try AVAssetWriter(URL: NSURL(fileURLWithPath: destinationPath), fileType: AVFileTypeMPEG4)
        }
        catch {
            print("Can't create asset writer. Check destinationPath: \(destinationPath).")
            return (nil, nil, nil)
        }
        assetWriter?.shouldOptimizeForNetworkUse = true
        
        // Video input
        let videoDimensions: CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(videoFormatHint as CMVideoFormatDescription)
        let videoSettings: [String : AnyObject] = [AVVideoCodecKey: AVVideoCodecH264,
                                                   AVVideoWidthKey: Int(videoDimensions.width),
                                                   AVVideoHeightKey: Int(videoDimensions.height)]
        let videoInput: AVAssetWriterInput? = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                                                                 outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true
        
        if assetWriter!.canAddInput(videoInput!) {
            assetWriter!.addInput(videoInput!)
        }
        else {
            print("Can't add video input")
            return (nil, nil, nil)
        }
        
        let audioInput: AVAssetWriterInput? = AVAssetWriterInput(mediaType: AVMediaTypeAudio,
                                                                 outputSettings: nil,
                                                                 sourceFormatHint: audioFormatHint)
        audioInput?.expectsMediaDataInRealTime = true
        
        if assetWriter!.canAddInput(audioInput!) {
            assetWriter!.addInput(audioInput!)
        }
        else {
            print("Can't add audio input.")
            return (assetWriter, videoInput, nil)
        }
        
        return (assetWriter, videoInput, audioInput)
    }
    
    static func prepareAssetReader(filePath filePath: String) ->
        (reader: AVAssetReader?,
        videoOutput: AVAssetReaderTrackOutput?,
        audioOutput: AVAssetReaderTrackOutput?)
    {
        var assetReader: AVAssetReader?
        var videoOutput: AVAssetReaderTrackOutput?
        var audioOutput: AVAssetReaderTrackOutput?
        
        let url = NSURL.fileURLWithPath(filePath)
        let asset = AVAsset(URL: url)
        
        do {
            assetReader = try AVAssetReader(asset: asset)
        }
        catch {
            print("Can't create asset reader.")
            return (nil, nil, nil)
        }
        
        // Video output
        let videoTracks = asset.tracksWithMediaType(AVMediaTypeVideo)
        if videoTracks.count > 0 {
            let outputVideoSetting: [String: AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(unsignedInt: kCVPixelFormatType_32ARGB),
                                                           String(kCVPixelBufferIOSurfacePropertiesKey): [:]]
            videoOutput = AVAssetReaderTrackOutput(track: videoTracks.first!, outputSettings: outputVideoSetting)
            
            if assetReader!.canAddOutput(videoOutput!) {
                assetReader!.addOutput(videoOutput!)
            }
            else {
                print("Can't add video ouput.")
                return (nil, nil, nil)
            }
        }
        
        // Audio output
        let audioTracks = asset.tracksWithMediaType(AVMediaTypeAudio)
        if audioTracks.count > 0 {
            audioOutput = AVAssetReaderTrackOutput(track: asset.tracksWithMediaType(AVMediaTypeAudio).first!, outputSettings: nil)
            if assetReader!.canAddOutput(audioOutput!) {
                assetReader!.addOutput(audioOutput!)
            }
            else {
                print("Can't add audio ouput.")
                return (assetReader, videoOutput, nil)
            }
        }
        
        return (assetReader, videoOutput, audioOutput)
    }
    
    static func findFormatDescription(filePath: String) ->
        (videoFormatHint: CMFormatDescriptionRef?,
        audioFormatHint: CMFormatDescriptionRef?)
    {
        let tuple: (reader: AVAssetReader?,
            videoOutput: AVAssetReaderTrackOutput?,
            audioOutput: AVAssetReaderTrackOutput?) = prepareAssetReader(filePath: filePath)
        
        var assetReader: AVAssetReader
        if let test = tuple.reader {
            assetReader = test
        }
        else {
            print("Can't create asset reader.")
            return (nil, nil)
        }
        
        var videoOutput: AVAssetReaderTrackOutput
        if let test = tuple.videoOutput {
            videoOutput = test
        }
        else {
            print("Can't create video output")
            return (nil, nil)
        }
        
        let audioOutput: AVAssetReaderTrackOutput? = tuple.audioOutput
        
        if !assetReader.startReading() {
            print("Can't start reading.")
            return (nil, nil)
        }
        
        var videoFormatHint: CMFormatDescriptionRef?
        var audioFormatHint: CMFormatDescriptionRef?
        while assetReader.status == .Reading
        {
            if let sampleBuffer = videoOutput.copyNextSampleBuffer() {
                videoFormatHint = CMSampleBufferGetFormatDescription(sampleBuffer)
            }
            
            if let sampleBuffer = audioOutput?.copyNextSampleBuffer() {
                audioFormatHint = CMSampleBufferGetFormatDescription(sampleBuffer)
            }
            
            return (videoFormatHint, audioFormatHint)
        }
        
        return (nil, nil)
    }
}