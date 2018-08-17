//
//  RSVideoCropCommand.m
//  RealSocial
//
//  Created by Kira on 2018/6/7.
//  Copyright © 2018 scnukuncai. All rights reserved.
//

#import "RSVideoCropCommand.h"

@implementation RSVideoCropCommand

- (void)performWithAsset:(AVAsset*)asset {
    AVMutableVideoCompositionInstruction *instruction = nil;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    CGAffineTransform t1;
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    CMTime insertionPoint = kCMTimeZero;
    NSError *error = nil;
    
    // Step 1
    // Create a composition with the given asset and insert audio and video tracks into it from the asset
    if (!self.mutableComposition) {
        
        // Check whether a composition has already been created, i.e, some other tool has already been applied.
        // Create a new composition
        self.mutableComposition = [AVMutableComposition composition];
        
        // Insert the video and audio tracks from AVAsset
        if (assetVideoTrack != nil) {
            AVMutableCompositionTrack *compositionVideoTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
        }
        if (assetAudioTrack != nil) {
            AVMutableCompositionTrack *compositionAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
        }
        
    }
    
    // Step 2
    // Set the appropriate render sizes and transforms to achieve cropping
    if (!self.mutableVideoComposition) {
        
        // Create a new video composition
        self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
        
        CGSize targetSize = CGSizeMake(ceil(assetVideoTrack.naturalSize.width / 16) * 16,ceil(assetVideoTrack.naturalSize.width / 9.f) * 16);
        
        self.mutableVideoComposition.renderSize = targetSize;
        self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
        
        // The crop transform is set on a layer instruction
        instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]);
        if (self.mutableComposition.tracks.count > 0) {
            layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(self.mutableComposition.tracks)[0]];
        }
        
        // Crop transformation (translation to move the bottom right half into the view)
//        t1 = CGAffineTransformMakeTranslation(-1*assetVideoTrack.naturalSize.width/2, -1*assetVideoTrack.naturalSize.height/2);
//        [layerInstruction setTransform:t1 atTime:kCMTimeZero];
        
    } else {
        CGSize targetSize = CGSizeMake(ceil(self.mutableVideoComposition.renderSize.width / 16) * 16, ceil(self.mutableVideoComposition.renderSize.width / 9.f) * 16);
        
        self.mutableVideoComposition.renderSize = targetSize;
        
        // Extract the existing layer instruction on the mutableVideoComposition
        if (self.mutableVideoComposition.instructions.count > 0) {
            instruction = (self.mutableVideoComposition.instructions)[0];
        }
        if (instruction.layerInstructions.count > 0) {
            layerInstruction = (instruction.layerInstructions)[0];
        }
        
        // Check if a transform already exists on this layer instruction, this is done to add the current transform on top of previous edits
        CGAffineTransform existingTransform;
        if (![layerInstruction getTransformRampForTime:[self.mutableComposition duration] startTransform:&existingTransform endTransform:NULL timeRange:NULL]) {
            t1 = CGAffineTransformMakeTranslation(0, - (assetVideoTrack.naturalSize.height / 2 - assetVideoTrack.naturalSize.width * 8 / 9));
            [layerInstruction setTransform:t1 atTime:kCMTimeZero];
        } else {
            t1 = CGAffineTransformMakeTranslation(0, - (assetVideoTrack.naturalSize.height / 2 - assetVideoTrack.naturalSize.width * 8 / 9));
            CGAffineTransform newTransform = CGAffineTransformConcat(existingTransform, t1);
            [layerInstruction setTransform:newTransform atTime:kCMTimeZero];
        }

    }
    
    instruction.layerInstructions = @[layerInstruction];
    self.mutableVideoComposition.instructions = @[instruction];
}

@end
