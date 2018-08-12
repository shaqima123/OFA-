//
//  OFACameraPreviewView.m
//  OneForAll
//
//  Created by Kira on 2018/8/11.
//  Copyright © 2018 Kira. All rights reserved.
//
@import AVFoundation;

#import "OFACameraPreviewView.h"

@implementation OFACameraPreviewView

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session
{
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    self.videoPreviewLayer.session = session;
    //设置预览view适配方式
    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

@end
