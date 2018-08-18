//
//  RSVideoAddMusicCommand.m
//  OneForAll
//
//  Created by Kira on 2018/8/18.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "RSVideoAddMusicCommand.h"

@implementation RSVideoAddMusicCommand

- (void)performWithAsset:(AVAsset*)asset
{
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    NSError *error = nil;
    
    // Step 1
    // Extract the custom audio track to be added to the composition
    NSString *audioURL = [[NSBundle mainBundle] pathForResource:@"pickStar" ofType:@"mp3"];
    AVAsset *audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioURL] options:nil];
    AVAssetTrack *newAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
    
    
    // Step 2
    // Create a composition with the given asset and insert audio and video tracks into it from the asset
    if (!self.mutableComposition) {
        
        // Check whether a composition has already been created, i.e, some other tool has already been applied.
        // Create a new composition
        self.mutableComposition = [AVMutableComposition composition];
        
        // Add tracks to composition from the input video asset
        if (assetVideoTrack != nil) {
            AVMutableCompositionTrack *compositionVideoTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
        }
    } else {
        for (AVCompositionTrack * audioTrack in [self.mutableComposition tracksWithMediaType:AVMediaTypeAudio]) {
            [self.mutableComposition removeTrack:audioTrack];
        }
    }
    
    
    // Step 3
    // Add custom audio track to the composition
    AVMutableCompositionTrack *customAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [customAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]) ofTrack:newAudioTrack atTime:kCMTimeZero error:&error];
    
    
    // Step 4
    // Mix parameters sets a volume ramp for the audio track to be mixed with existing audio track for the duration of the composition
    AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:customAudioTrack];
    [mixParameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:CMTimeRangeMake(kCMTimeZero, self.mutableComposition.duration)];
    
    self.mutableAudioMix = [AVMutableAudioMix audioMix];
    self.mutableAudioMix.inputParameters = @[mixParameters];
}

@end
