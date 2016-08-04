//
//  VideoMerger.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import AVFoundation


class VideoMerger {
    static func mergeMultipleVideos(destinationPath destinationPath: String, filePaths: [String], finished: ((NSURL, String?) -> Void)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            
            let mixComposition = AVMutableComposition()
            var url: NSURL
            var asset: AVAsset
            var insertionTime: CMTime = kCMTimeZero
            
            for filePath in filePaths {
                url = NSURL.fileURLWithPath(filePath)
                asset = AVAsset(URL: url)
                insertionTime = appendAsset(asset, composition: mixComposition, atTime: insertionTime)
            }
            
            exportAsset(mixComposition, destinationPath: destinationPath, completion: { outputURL in
                Storage.copyFileToAlbum(localFileUrl: outputURL,
                    handler: { localIdentifier in
                        dispatch_async(dispatch_get_main_queue()) {
                            finished(outputURL, localIdentifier)
                        }
                        
                })
            })

        }
        
    }
    
    static func appendAsset(asset: AVAsset, composition: AVMutableComposition, atTime: CMTime) -> CMTime {
        var maxBounds: CMTime = kCMTimeInvalid
        var videoTime = atTime
        var audioTime = atTime
        
        initCompositionVideoTrack(composition, asset: asset)
        initCompositionAudioTrack(composition, asset: asset)
        
        
        for videoAssetTrack in asset.tracksWithMediaType(AVMediaTypeVideo) {
            let videoTrack = composition.tracksWithMediaType(AVMediaTypeVideo).first!
            videoTime = self.appendTrack(videoAssetTrack,
                                         toCompositionTrack: videoTrack,
                                         atTime: videoTime,
                                         withBounds: maxBounds)
            maxBounds = videoTime
            
        }
        
        for audioAssetTrack in asset.tracksWithMediaType(AVMediaTypeAudio) {
            let audioTrack = composition.tracksWithMediaType(AVMediaTypeAudio).first!
            audioTime = self.appendTrack(audioAssetTrack,
                                         toCompositionTrack: audioTrack,
                                         atTime: audioTime,
                                         withBounds: maxBounds)
            maxBounds = audioTime
            
        }
        
        return videoTime
        
    }
    
    static func appendTrack(track: AVAssetTrack, toCompositionTrack compositionTrack: AVMutableCompositionTrack, atTime time: CMTime, withBounds bounds: CMTime) -> CMTime {
        
        var timeRange = track.timeRange
        var startTime = time
        
        startTime = CMTimeAdd(startTime, timeRange.start)
        
        // ensure time range within bounds
        if (CMTIME_IS_VALID(bounds)) {
            let currentBounds = CMTimeAdd(startTime, timeRange.duration)
            
            if (CMTimeCompare(currentBounds, bounds) == 1) {
                timeRange = CMTimeRangeMake(timeRange.start,
                                            CMTimeSubtract(timeRange.duration, CMTimeSubtract(currentBounds, bounds)));
            }
        }
        
        // add track to composition
        if (CMTimeCompare(timeRange.duration, kCMTimeZero) == 1) {
            do {
                try compositionTrack.insertTimeRange(timeRange, ofTrack: track, atTime: time)
            } catch _ {
                NSLog("Failed to insert append %@ track: %@", compositionTrack.mediaType, track.debugDescription)
            }
            
            
            return CMTimeAdd(startTime, timeRange.duration);
        }
        
        return startTime;
        
    }
    
    
    
    static func initCompositionVideoTrack(composition: AVMutableComposition, asset: AVAsset) {
        var videoTrack: AVMutableCompositionTrack
        
        let videoTracks = composition.tracksWithMediaType(AVMediaTypeVideo)
        
        if (videoTracks.count == 0) {
            videoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                                                                  preferredTrackID: kCMPersistentTrackID_Invalid)
            videoTrack.preferredTransform = asset.tracksWithMediaType(AVMediaTypeVideo).first!.preferredTransform
        }
    }
    
    static func initCompositionAudioTrack(composition: AVMutableComposition, asset: AVAsset) {
        var audioTrack: AVMutableCompositionTrack
        
        let audioTracks = composition.tracksWithMediaType(AVMediaTypeAudio)
        
        if (audioTracks.count == 0) {
            audioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio,
                                                                  preferredTrackID: kCMPersistentTrackID_Invalid)
            audioTrack.preferredTransform = asset.tracksWithMediaType(AVMediaTypeAudio).first!.preferredTransform
        }
    }
    
    static func exportAsset(mixComposition: AVMutableComposition, destinationPath: String, completion: (NSURL -> Void) ) {
        // 5 - Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = NSURL(fileURLWithPath: destinationPath)
        exporter.outputFileType = AVFileTypeQuickTimeMovie // AVFileTypeMPEG4
        exporter.shouldOptimizeForNetworkUse = true
        
        exporter.exportAsynchronouslyWithCompletionHandler() {
            if exporter.status == AVAssetExportSessionStatus.Completed {
                completion(exporter.outputURL!)
            }
        }
    }

}