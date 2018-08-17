//
//  RSVideoExportCommand.m
//  RealSocial
//
//  Created by Kira on 2018/5/4.
//  Copyright © 2018年 scnukuncai. All rights reserved.
//

#import "RSVideoExportCommand.h"

@interface RSVideoExportCommand (Internal)

- (void)writeVideoToPhotoLibrary:(NSURL *)url;

@end

@implementation RSVideoExportCommand

- (void)performWithAsset:(AVAsset*)asset complete:(void (^)(NSURL*))completeHandler fail:(void (^)(NSError *))failHandler
{    // Step 1
    // Create an outputURL to which the exported movie will be saved
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    outputURL = [outputURL stringByAppendingPathComponent:@"output.mp4"];
    // Remove Existing File
    [manager removeItemAtPath:outputURL error:nil];
    
    
    // Step 2
    // Create an export session with the composition and write the exported movie to the photo library
    
    if (!self.mutableComposition) {
        self.exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset1280x720];
    } else {
        self.exportSession = [[AVAssetExportSession alloc] initWithAsset:[self.mutableComposition copy] presetName:AVAssetExportPreset1280x720];
    }
    
    if (self.mutableVideoComposition) {
        self.exportSession.videoComposition = self.mutableVideoComposition;
    }
    if (self.mutableAudioMix) {
        self.exportSession.audioMix = self.mutableAudioMix;
    }
    
    CMTime delta = CMTimeMakeWithSeconds(0.05,asset.duration.timescale);

    self.exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(asset.duration, delta));
    
    self.exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
    self.exportSession.outputFileType=AVFileTypeQuickTimeMovie;
    
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        switch (self.exportSession.status) {
            case AVAssetExportSessionStatusCompleted:
                [self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outputURL]];
                // Step 3
                completeHandler(self.exportSession.outputURL);
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Failed:%@",self.exportSession.error);
                failHandler(self.exportSession.error);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Canceled:%@",self.exportSession.error);
                failHandler(self.exportSession.error);
                break;
            default:
                break;
        }
    }];
}

- (void)performWithAsset:(AVAsset *)asset
{
    // Step 1
    // Create an outputURL to which the exported movie will be saved
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    outputURL = [outputURL stringByAppendingPathComponent:@"output.mp4"];
    // Remove Existing File
    [manager removeItemAtPath:outputURL error:nil];
    
    
    // Step 2
    // Create an export session with the composition and write the exported movie to the photo library
    self.exportSession = [[AVAssetExportSession alloc] initWithAsset:[self.mutableComposition copy] presetName:AVAssetExportPreset1280x720];
    
    self.exportSession.videoComposition = self.mutableVideoComposition;
    self.exportSession.audioMix = self.mutableAudioMix;
    self.exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
    self.exportSession.outputFileType=AVFileTypeQuickTimeMovie;
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        switch (self.exportSession.status) {
            case AVAssetExportSessionStatusCompleted:
                [self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outputURL]];
                // Step 3
                // Notify AVSEViewController about export completion
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:AVSEExportCommandCompletionNotification
                 object:self];
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Failed:%@",self.exportSession.error);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Canceled:%@",self.exportSession.error);
                break;
            default:
                break;
        }
    }];
}

- (void)writeVideoToPhotoLibrary:(NSURL *)url
{
    return;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error){
        if (error) {
            NSLog(@"Video could not be saved");
        }
    }];
}

@end
