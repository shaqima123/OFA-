//
//  RSVideoRotateCommand.m
//  RealSocial
//
//  Created by Kira on 2018/5/4.
//  Copyright © 2018年 scnukuncai. All rights reserved.
//

#import "RSVideoRotateCommand.h"

#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

@implementation RSVideoRotateCommand

- (void)performWithAsset:(AVAsset*)asset withDegress:(NSInteger) degress {
    AVMutableVideoCompositionInstruction *instruction = nil;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    CGAffineTransform t1;
    CGAffineTransform t2;
    CGAffineTransform t3;
    
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
        
        // Check whether a composition has already been created, i.e, some other tool has already been applied
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
    // Translate the composition to compensate the movement caused by rotation (since rotation would cause it to move out of frame)
    
    if (degress == 0) {
        t1 = CGAffineTransformMakeTranslation(0.0, 0.0);
        t2 = CGAffineTransformRotate(t1, 0);
    }else if (degress == 90){
        t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.height, 0.0);
        t2 = CGAffineTransformRotate(t1, degreesToRadians(90.0));
    }else if (degress == 180){
        t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
        t2 = CGAffineTransformRotate(t1, degreesToRadians(180.0));
    }else if (degress == 270){
        t1 = CGAffineTransformMakeTranslation(0 , assetVideoTrack.naturalSize.width);
        t2 = CGAffineTransformRotate(t1,  degreesToRadians(270.0));
    }
    
    // Step 3
    // Set the appropriate render sizes and rotational transforms
    if (self.mutableVideoComposition) {
        //TODO:此处强制置空mutableVideoComposition，需保证前面不出现该属性的修改（hard code）
        self.mutableVideoComposition = nil;
    }

    // Create a new video composition
    self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    if (degress == 0 || degress == 180) {
        self.mutableVideoComposition.renderSize = CGSizeMake(ceil(assetVideoTrack.naturalSize.width / 16) * 16,ceil(assetVideoTrack.naturalSize.width / 9.f) * 16);
        t3 = CGAffineTransformTranslate(t2, 0, self.mutableVideoComposition.renderSize.height / 2 - assetVideoTrack.naturalSize.height / 2);
    }
    if (degress == 90){
        self.mutableVideoComposition.renderSize = CGSizeMake(ceil(assetVideoTrack.naturalSize.height / 16) * 16,ceil(assetVideoTrack.naturalSize.height / 9.f) * 16);
        t3 = CGAffineTransformTranslate(t2, self.mutableVideoComposition.renderSize.height / 2 - assetVideoTrack.naturalSize.width / 2, 0);
    }
    if (degress == 270) {
        self.mutableVideoComposition.renderSize = CGSizeMake(ceil(assetVideoTrack.naturalSize.height / 16) * 16,ceil(assetVideoTrack.naturalSize.height / 9.f) * 16);
        t3 = CGAffineTransformTranslate(t2, - (self.mutableVideoComposition.renderSize.height / 2 - assetVideoTrack.naturalSize.width / 2), 0);
    }
    
    self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
    // The rotate transform is set on a layer instruction
    instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]);
    if(self.mutableComposition.tracks.count > 0) {
        layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(self.mutableComposition.tracks)[0]];
        [layerInstruction setTransform:t3 atTime:kCMTimeZero];
    }
    
    // Step 4
    // Add the transform instructions to the video composition
    instruction.layerInstructions = @[layerInstruction];
    self.mutableVideoComposition.instructions = @[instruction];
}

- (void)performWithAsset:(AVAsset*)asset
{
    AVMutableVideoCompositionInstruction *instruction = nil;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    CGAffineTransform t1;
    CGAffineTransform t2;
    
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
        
        // Check whether a composition has already been created, i.e, some other tool has already been applied
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
    // Translate the composition to compensate the movement caused by rotation (since rotation would cause it to move out of frame)
    t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.height, 0.0);
    // Rotate transformation
    t2 = CGAffineTransformRotate(t1, degreesToRadians(90.0));
    
    
    // Step 3
    // Set the appropriate render sizes and rotational transforms
    if (!self.mutableVideoComposition) {
        
        // Create a new video composition
        self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
        self.mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
        self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
        
        // The rotate transform is set on a layer instruction
        instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]);
        if (self.mutableComposition.tracks.count > 0) {
            layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(self.mutableComposition.tracks)[0]];
            [layerInstruction setTransform:t2 atTime:kCMTimeZero];
        }
        
    } else {
        
        self.mutableVideoComposition.renderSize = CGSizeMake(self.mutableVideoComposition.renderSize.height, self.mutableVideoComposition.renderSize.width);
        
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
            [layerInstruction setTransform:t2 atTime:kCMTimeZero];
        } else {
            // Note: the point of origin for rotation is the upper left corner of the composition, t3 is to compensate for origin
            CGAffineTransform t3 = CGAffineTransformMakeTranslation(-1*assetVideoTrack.naturalSize.height/2, 0.0);
            CGAffineTransform newTransform = CGAffineTransformConcat(existingTransform, CGAffineTransformConcat(t2, t3));
            [layerInstruction setTransform:newTransform atTime:kCMTimeZero];
        }
        
    }
    
    
    // Step 4
    // Add the transform instructions to the video composition
    instruction.layerInstructions = @[layerInstruction];
    self.mutableVideoComposition.instructions = @[instruction];
    
    
    // Step 5
    // Notify AVSEViewController about rotation operation completion
    [[NSNotificationCenter defaultCenter] postNotificationName:AVSEEditCommandCompletionNotification object:self];
}

- (void)writeVideoToPhotoLibrary:(NSURL *)url
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error){
        if (error) {
            NSLog(@"Video could not be saved");
        }
    }];
}


@end
