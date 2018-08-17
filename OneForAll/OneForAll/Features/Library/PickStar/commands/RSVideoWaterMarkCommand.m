//
//  RSVideoWaterMarkCommand.m
//  RealSocial
//
//  Created by Kira on 2018/7/9.
//  Copyright © 2018 scnukuncai. All rights reserved.
//

#import "RSVideoWaterMarkCommand.h"
#import "RSStickModel.h"
#import "RSWordElementModel.h"
#import "RSCardModel.h"
#import <YYImage/YYImageCoder.h>

#import "SDWebImageWebPCoder.h"
#import "SDWebImageCoderHelper.h"
#import "NSImage+WebCache.h"
#import <SDWebImage/UIImage+MultiFormat.h>
#import <SDWebImage/SDWebImageWebPCoder.h>
#import <SDWebImage/SDWebImageFrame.h>

@interface RSVideoWaterMarkCommand ()

@end

@implementation RSVideoWaterMarkCommand
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
    
    CMTime insertionPoint = kCMTimeZero;
    NSError *error = nil;
    
    
    // Step 1
    // Create a composition with the given asset and insert audio and video tracks into it from the asset
    if(!self.mutableComposition) {
        
        // Check if a composition already exists, else create a composition using the input asset
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
    // Create a water mark layer of the same size as that of a video frame from the asset
    if ([[self.mutableComposition tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        
        if(!self.mutableVideoComposition) {
            
            // build a pass through video composition
            self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
            self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
            self.mutableVideoComposition.renderSize = assetVideoTrack.naturalSize;
            
            AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]);
            AVAssetTrack *videoTrack = nil;
            if ([self.mutableComposition tracksWithMediaType:AVMediaTypeVideo].count > 0) {
                videoTrack = [self.mutableComposition tracksWithMediaType:AVMediaTypeVideo][0];
            }
            AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            passThroughInstruction.layerInstructions = @[passThroughLayer];
            self.mutableVideoComposition.instructions = @[passThroughInstruction];
            
        }
        
        if (self.elementArray && self.elementArray.count > 0) {
            CALayer *parentLayer = [CALayer layer];
            CALayer *videoLayer = [CALayer layer];
            parentLayer.frame = CGRectMake(0, 0, self.mutableVideoComposition.renderSize.width, self.mutableVideoComposition.renderSize.height);
            videoLayer.frame = CGRectMake(0, 0, self.mutableVideoComposition.renderSize.width, self.mutableVideoComposition.renderSize.height);
            
            [parentLayer addSublayer:videoLayer];
//            if (self.watermarkLayer) {
//                self.watermarkLayer.frame = parentLayer.frame;
//                [parentLayer addSublayer:self.watermarkLayer];
//            }
            self.coordinateRatio = parentLayer.frame.size.width / SCREEN_WIDTH;
            for (RSEditElementModel *elementModel in self.elementArray) {
                if ([elementModel isMemberOfClass:[RSWordElementModel class]]) {
                    RSWordElementModel *wordModel =(RSWordElementModel *)elementModel;
                    UIImage *wordImage = wordModel.wordImage;
                    CALayer *wordLayer = [CALayer layer];
                    wordLayer.center = CGPointMake(wordModel.position.x * self.coordinateRatio, parentLayer.frame.size.height - wordModel.position.y * self.coordinateRatio);//矫正位置
                    wordLayer.bounds = CGRectMake(0, 0, wordImage.size.width / wordModel.wordRatio * self.coordinateRatio , wordImage.size.height / wordModel.wordRatio * self.coordinateRatio);
                    wordLayer.contents = (id)wordImage.CGImage;
                    CGFloat trans = CGAffineTransformGetRotation(wordModel.transform);
                    wordModel.transform  = CGAffineTransformRotate(wordModel.transform, -trans * 2);//矫正旋转
                    [wordLayer setAffineTransform:wordModel.transform];
                    [parentLayer addSublayer:wordLayer];
                }
                
                if ([elementModel isMemberOfClass:[RSStickModel class]]) {
                    RSStickModel *stickModel = (RSStickModel *)elementModel;

                    UIImage *webpImage = stickModel.stickImage;
                    
                    CALayer *stickLayer = [CALayer layer];
                    stickLayer.center = CGPointMake(stickModel.position.x * self.coordinateRatio, parentLayer.frame.size.height - stickModel.position.y * self.coordinateRatio);//矫正位置
                    stickLayer.bounds = CGRectMake(0, 0, webpImage.size.width * self.coordinateRatio , webpImage.size.height * self.coordinateRatio);
                    CGFloat trans = CGAffineTransformGetRotation(stickModel.transform);
                    CGFloat a = stickModel.transform.a;
                    CGFloat d = stickModel.transform.d;
                    
                    if ((a > 0 && d > 0) || (a < 0 && d < 0) ) {
                        stickModel.transform  = CGAffineTransformRotate(stickModel.transform, -trans * 2);//矫正旋转
                    }
                    if ((a > 0 && d < 0) || (a < 0 && d > 0) ) {
                        stickModel.transform  = CGAffineTransformRotate(stickModel.transform, trans * 2);//矫正旋转
                    }
                    stickModel.transform = CGAffineTransformScale(stickModel.transform, stickModel.originalScale, stickModel.originalScale);//矫正缩放
                    [stickLayer setAffineTransform:stickModel.transform];
                    
                    if (webpImage.sd_frames && webpImage.sd_frames.count > 0) {
                        CAKeyframeAnimation * animation = [self animationForWebPImage:webpImage];
                        [stickLayer addAnimation:animation forKey:@"contents"];
                    } else {
                        stickLayer.contents = (id)webpImage.CGImage;
                    }
                    [parentLayer addSublayer:stickLayer];
                }
                
                if ([elementModel isKindOfClass:[RSCardElementModel class]]) {
                    RSCardElementModel *cardModel = (RSCardElementModel *)elementModel;
                    UIImage *image = cardModel.produceImg;
                    
                    CALayer *cardLayer = [CALayer layer];
                    cardLayer.center = CGPointMake(cardModel.position.x * _coordinateRatio, parentLayer.height - cardModel.position.y * _coordinateRatio);
                    cardLayer.bounds = CGRectMake(0, 0, image.size.width * _coordinateRatio, image.size.height * _coordinateRatio);
                    CGFloat rotation = CGAffineTransformGetRotation(cardModel.transform);
                    cardModel.transform  = CGAffineTransformRotate(cardModel.transform, -rotation * 2);//矫正旋转
                    cardLayer.affineTransform = cardModel.transform;
                    cardLayer.contents =(id)image.CGImage;
                    [parentLayer addSublayer:cardLayer];
                }
                
            }
            self.mutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
        }
    }
}

- (void)watermarkWithImage:(UIImage *)image
{
    // Create a layer for the title
    if (image) {
        CALayer *_watermarkLayer = [CALayer layer];
        _watermarkLayer.bounds = CGRectMake(0, 0, self.mutableVideoComposition.renderSize.width, self.mutableVideoComposition.renderSize.height);
        
        _watermarkLayer.contents = (id)image.CGImage;
        
        self.watermarkLayer = _watermarkLayer;
    }
}


- (CAKeyframeAnimation *)animationForWebPImage:(UIImage *)stickImage {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    NSMutableArray *frames = [NSMutableArray new];
    NSMutableArray *delayTimes = [NSMutableArray new];
    CGFloat totalTimes = 0.0;
    
    NSMutableArray *sd_frames = @[].mutableCopy;
    if (stickImage.sd_frames) {
        sd_frames = stickImage.sd_frames;
    }
    for (int i = 0; i < sd_frames.count; i++) {
        SDWebImageFrame *frame = [sd_frames objectAtIndex:i];
        UIImage *image = frame.image;
        [frames addObject:(__bridge id)image.CGImage];
        NSTimeInterval time = frame.duration;
        [delayTimes addObject:[NSNumber numberWithDouble:time]];
        totalTimes = totalTimes + time;
    }
    NSMutableArray *times = @[].mutableCopy;
    CGFloat currentTime = 0;
    NSInteger count = delayTimes.count;
    
    for (int i = 0; i < count; ++i) {
        [times addObject:[NSNumber numberWithFloat:(currentTime / totalTimes)]];
        currentTime += [[delayTimes objectAtIndex:i] floatValue];
    }
    animation.keyTimes = times;
    animation.values = frames;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.duration = totalTimes;
    animation.repeatCount = HUGE_VALF;
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    animation.removedOnCompletion = NO;
    
    return animation;
}

- (CAKeyframeAnimation *)animationForGifWithURL:(NSURL *)url {
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    
    NSMutableArray * frames = [NSMutableArray new];
    NSMutableArray *delayTimes = [NSMutableArray new];
    
    CGFloat totalTime = 0.0;
    CGFloat gifWidth;
    CGFloat gifHeight;
    
    CGImageSourceRef gifSource = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    
    // get frame count
    size_t frameCount = CGImageSourceGetCount(gifSource);
    for (size_t i = 0; i < frameCount; ++i) {
        // get each frame
        CGImageRef frame = CGImageSourceCreateImageAtIndex(gifSource, i, NULL);
        [frames addObject:(__bridge id)frame];
        CGImageRelease(frame);
        
        // get gif info with each frame
//        CFDictionaryRef
        NSDictionary *dict = (NSDictionary*)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(gifSource, i, NULL));
        NSLog(@"kCGImagePropertyGIFDictionary %@", [dict valueForKey:(NSString*)kCGImagePropertyGIFDictionary]);
        
        // get gif size
        gifWidth = [[dict valueForKey:(NSString*)kCGImagePropertyPixelWidth] floatValue];
        gifHeight = [[dict valueForKey:(NSString*)kCGImagePropertyPixelHeight] floatValue];
        
        // kCGImagePropertyGIFDictionary中kCGImagePropertyGIFDelayTime，kCGImagePropertyGIFUnclampedDelayTime值是一样的
        NSDictionary *gifDict = [dict valueForKey:(NSString*)kCGImagePropertyGIFDictionary];
        [delayTimes addObject:[gifDict valueForKey:(NSString*)kCGImagePropertyGIFDelayTime]];
        
        totalTime = totalTime + [[gifDict valueForKey:(NSString*)kCGImagePropertyGIFDelayTime] floatValue];
    }
    
    if (gifSource) {
        CFRelease(gifSource);
    }
    
    NSMutableArray *times = [NSMutableArray arrayWithCapacity:3];
    CGFloat currentTime = 0;
    NSInteger count = delayTimes.count;
    for (int i = 0; i < count; ++i) {
        [times addObject:[NSNumber numberWithFloat:(currentTime / totalTime)]];
        currentTime += [[delayTimes objectAtIndex:i] floatValue];
    }
    
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:3];
    for (int i = 0; i < count; ++i) {
        [images addObject:[frames objectAtIndex:i]];
    }
    
    animation.keyTimes = times;
    animation.values = images;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.duration = totalTime;
    animation.repeatCount = HUGE_VALF;
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    animation.removedOnCompletion = NO;
    
    return animation;
}

@end
