//
//  RSVideoWaterMarkCommand.m
//  RealSocial
//
//  Created by Kira on 2018/7/9.
//  Copyright © 2018 scnukuncai. All rights reserved.
//

#import "RSVideoWaterMarkCommand.h"
#import <YYImage/YYImageCoder.h>

#import "NSImage+WebCache.h"
#import <SDWebImage/UIImage+MultiFormat.h>
#import <SDWebImage/SDWebImageFrame.h>

@interface RSVideoWaterMarkCommand ()<CALayerDelegate>


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
        
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, self.mutableVideoComposition.renderSize.width, self.mutableVideoComposition.renderSize.height);
        videoLayer.frame = CGRectMake(0, 0, self.mutableVideoComposition.renderSize.width, self.mutableVideoComposition.renderSize.height);
        [parentLayer addSublayer:videoLayer];
        
        NSString *imagePath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"pickStarMask.png"];
        [self watermarkWithImage:[UIImage imageWithContentsOfFile:imagePath]];
        if (self.watermarkLayer) {
            self.watermarkLayer.frame = parentLayer.frame;
            [parentLayer addSublayer:self.watermarkLayer];
        }
        
        self.coordinateRatio = parentLayer.frame.size.width / SCREEN_WIDTH;

        CATextLayer *nameLayer = [CATextLayer layer];
        nameLayer.string = @"Kira";
        nameLayer.fontSize = 44.f;
        nameLayer.foregroundColor = [[UIColor whiteColor] CGColor];
        nameLayer.alignmentMode = kCAAlignmentRight;
        nameLayer.frame = CGRectMake(510, 1000, 300, 132);
        [parentLayer addSublayer:nameLayer];
        
        CATextLayer *wordLayer = [CATextLayer layer];
        wordLayer.string = @"可爱的园子，你想要我都给你～";
        wordLayer.fontSize = 44.f;
        wordLayer.foregroundColor = [[UIColor blackColor] CGColor];
        wordLayer.alignmentMode = kCAAlignmentLeft;
        wordLayer.frame = CGRectMake(65 * self.coordinateRatio, 228 * self.coordinateRatio, SCREEN_WIDTH * self.coordinateRatio, 132);
        [parentLayer addSublayer:wordLayer];
        
        CFTimeInterval timeline = 0;
        
        NSMutableArray <CALayer *> *layerArr = @[].mutableCopy;
        for (int i = 1; i < 5; i++) {
            CALayer *layer0 = [self layerWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d",i]]];
            CALayer *layer1 = [self layerWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d",i]]];
            layer0.opacity = 0;
            layer1.opacity = 0;
            [layerArr addObject:layer0];
            [layerArr addObject:layer1];
            [parentLayer addSublayer:layer0];
            [parentLayer addSublayer:layer1];
        }
        
        for (int i = 1; i < 5; i++) {
            CALayer *layer0 = [self layerWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d",i]]];
            CALayer *layer1 = [self layerWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d",i]]];
            if (i == 4) {
                layer1 = [self layerWithImage:[UIImage imageNamed:@"6.jpg"]];
            }
            layer0.opacity = 0;
            layer1.opacity = 0;
            [layerArr addObject:layer0];
            [layerArr addObject:layer1];
            [parentLayer addSublayer:layer0];
            [parentLayer addSublayer:layer1];
        }
        
        CALayer * layer = nil;
        CAAnimation *ani;
        
        timeline = 1;
        
        layer = [layerArr objectAtIndex:0];
        layer.frame = CGRectMake(150 * self.coordinateRatio, 500 * self.coordinateRatio , 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"100"];
        timeline += 0.1;
        ani = [self starPickAnimation:timeline];
        [layer addAnimation:ani forKey:@"101"];
        timeline += 1;
 
        layer = [layerArr objectAtIndex:1];
        layer.frame = CGRectMake(80 * self.coordinateRatio , 100 * self.coordinateRatio, 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"110"];
        timeline += 0.1;
        ani = [self starSendAnimation:timeline];
        [layer addAnimation:ani forKey:@"111"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:2];
        layer.frame = CGRectMake(150 * self.coordinateRatio, 500 * self.coordinateRatio , 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"200"];
        timeline += 0.1;
        ani = [self starPickAnimation:timeline];
        [layer addAnimation:ani forKey:@"201"];
        timeline += 0.5;
        
        layer = [layerArr objectAtIndex:3];
        layer.frame = CGRectMake(80 * self.coordinateRatio , 100 * self.coordinateRatio, 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"210"];
        timeline += 0.1;
        ani = [self starSendAnimation:timeline];
        [layer addAnimation:ani forKey:@"211"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:4];
        layer.frame = CGRectMake(150 * self.coordinateRatio, 500 * self.coordinateRatio , 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"300"];
        timeline += 0.1;
        ani = [self starPickAnimation:timeline];
        [layer addAnimation:ani forKey:@"301"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:5];
        layer.frame = CGRectMake(80 * self.coordinateRatio , 100 * self.coordinateRatio, 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"310"];
        timeline += 0.1;
        ani = [self starSendAnimation:timeline];
        [layer addAnimation:ani forKey:@"311"];
        timeline += 0.5;
        
        layer = [layerArr objectAtIndex:6];
        layer.frame = CGRectMake(150 * self.coordinateRatio, 500 * self.coordinateRatio , 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"400"];
        timeline += 0.1;
        ani = [self starPickAnimation:timeline];
        [layer addAnimation:ani forKey:@"401"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:7];
        layer.frame = CGRectMake(80 * self.coordinateRatio , 100 * self.coordinateRatio, 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"410"];
        timeline += 0.1;
        ani = [self starSendAnimation:timeline];
        [layer addAnimation:ani forKey:@"411"];
        timeline += 1;
    
        //第二遍
        layer = [layerArr objectAtIndex:8];
        layer.frame = CGRectMake(150 * self.coordinateRatio, 500 * self.coordinateRatio , 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"500"];
        timeline += 0.1;
        ani = [self starPickAnimation:timeline];
        [layer addAnimation:ani forKey:@"501"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:9];
        layer.frame = CGRectMake(80 * self.coordinateRatio , 100 * self.coordinateRatio, 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"510"];
        timeline += 0.1;
        ani = [self starSendAnimation:timeline];
        [layer addAnimation:ani forKey:@"511"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:10];
        layer.frame = CGRectMake(150 * self.coordinateRatio, 500 * self.coordinateRatio , 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"600"];
        timeline += 0.1;
        ani = [self starPickAnimation:timeline];
        [layer addAnimation:ani forKey:@"601"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:11];
        layer.frame = CGRectMake(80 * self.coordinateRatio , 100 * self.coordinateRatio, 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"610"];
        timeline += 0.1;
        ani = [self starSendAnimation:timeline];
        [layer addAnimation:ani forKey:@"611"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:12];
        layer.frame = CGRectMake(150 * self.coordinateRatio, 500 * self.coordinateRatio , 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"700"];
        timeline += 0.1;
        ani = [self starPickAnimation:timeline];
        [layer addAnimation:ani forKey:@"701"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:13];
        layer.frame = CGRectMake(80 * self.coordinateRatio , 100 * self.coordinateRatio, 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"710"];
        timeline += 0.1;
        ani = [self starSendAnimation:timeline];
        [layer addAnimation:ani forKey:@"711"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:14];
        layer.frame = CGRectMake(150 * self.coordinateRatio, 500 * self.coordinateRatio , 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"800"];
        timeline += 0.1;
        ani = [self starPickAnimation:timeline];
        [layer addAnimation:ani forKey:@"801"];
        timeline += 1;
        
        layer = [layerArr objectAtIndex:15];
        layer.frame = CGRectMake(80 * self.coordinateRatio , 100 * self.coordinateRatio, 300, 300);
        ani = [self appearAnimation:timeline];
        [layer addAnimation:ani forKey:@"810"];
        timeline += 0.1;
        ani = [self starSendAnimation:timeline];
        [layer addAnimation:ani forKey:@"811"];
        timeline += 1;

        self.mutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];

//        AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
//        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, assetAudioTrack.asset.duration);
//        AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
//        instruction.layerInstructions = [NSArray arrayWithObjects:layerInstruction, nil];
//        self.mutableVideoComposition.instructions = [NSArray arrayWithObject: instruction];
    }
}

- (void)watermarkWithImage:(UIImage *)image
{
    // Create a layer for the title
    if (image) {
        CALayer *_watermarkLayer = [CALayer layer];
        _watermarkLayer.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
        
        _watermarkLayer.contents = (id)image.CGImage;
        
        self.watermarkLayer = _watermarkLayer;
    }
}

- (CALayer *)layerWithImage:(UIImage *)image
{
    // Create a layer for the title
    if (image) {
        CALayer *_watermarkLayer = [CALayer layer];
        _watermarkLayer.bounds = CGRectMake(0, 0, image.size.width * image.scale, image.size.height * image.scale);
        
        _watermarkLayer.contents = (id)image.CGImage;
        return _watermarkLayer;
    }
    return nil;
}

- (CABasicAnimation *)appearAnimation:(CFTimeInterval)startTime {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.1;
    animation.repeatCount = 1;
    animation.fromValue = [NSNumber numberWithFloat:0];
    animation.toValue = [NSNumber numberWithFloat:1];
    animation.beginTime = startTime;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

- (CAAnimationGroup *)starSendAnimation:(CFTimeInterval)startTime {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];

    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:2.0];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];

    animation2.fromValue = [NSNumber numberWithFloat:1.0];
    animation2.toValue = [NSNumber numberWithFloat:0];
    CAAnimationGroup *group = [CAAnimationGroup animation];
    
    // 动画选项设定
    group.duration = 1.0;
    group.repeatCount = 1;
    group.beginTime = startTime;
    // 添加动画
    group.animations = [NSArray arrayWithObjects:animation, animation2, nil];
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    return group;
}

- (CABasicAnimation *)starPickAnimation:(CFTimeInterval)startTime {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.2f;
    animation.repeatCount = 1;
    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:0];
    animation.beginTime = startTime;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

-(void)animationDidStart:(CAAnimation *)anim{
    
}

#pragma mark 动画结束
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
   
}

@end
