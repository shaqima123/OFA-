//
//  OFAStillCamera.m
//  OneForAll
//
//  Created by Kira on 2018/8/11.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFAStillCamera.h"

@interface OFAStillCamera ()<
    AVCapturePhotoCaptureDelegate
>
{
    AVCaptureSession *_session;
    AVCaptureDeviceInput *_videoInput;
    AVCapturePhotoOutput *_photoOutput;
    AVCapturePhotoSettings *_photoSettings;
}

@end

@implementation OFAStillCamera

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupSession];
    }
    return self;
}

#pragma mark Init - Dealloc

- (void)dealloc {
    [self removeAllNotification];
}

#pragma mark Public Methods
- (void)startCamera {
    if (!_session.isRunning) {
        [_session startRunning];
    }
}

- (void)stopCamera {
    if (_session.isRunning) {
        [_session stopRunning];
    }
}

- (void)capturePhoto {
    if (_photoOutput && _photoSettings) {
        [_photoOutput capturePhotoWithSettings:_photoSettings delegate:self];
    }
}


#pragma mark Setup
- (void)setupSession {
    _session = [[AVCaptureSession alloc] init];
    _session.sessionPreset = AVCaptureSessionPresetPhoto;
    [self setupSessionInput];
    [self setupSessionOutPut];
}

- (void)setupSessionInput {
    NSError *error;
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (!_videoInput) {
        NSLog(@"DeviceInput Error,%@",error.description);
    }
    if ([_session canAddInput:_videoInput]) {
        [_session addInput:_videoInput];
    } else {
        NSLog(@"Session Error in add DeviceInput!");
    }
}

- (void)setupSessionOutPut {
    //AVCaptureStillImageOutput 在iOS10之后就被弃用了
     _photoOutput = [[AVCapturePhotoOutput alloc] init];
     _photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecJPEG}];
    
}

#pragma mark Set - get
- (AVCaptureSession *)session {
    return _session;
}

#pragma mark Notification
- (void)addNotificationToCaptureSession {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionError:) name:AVCaptureSessionRuntimeErrorNotification object:_session];
    [_session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    [_session addObserver:self forKeyPath:@"interrupted" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeAllNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_session removeObserver:self forKeyPath:@"running"];
    [_session removeObserver:self forKeyPath:@"interrupted"];
}

- (void)sessionError:(NSNotification *)notification {
    NSLog(@"Session Error in Runtime");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"running"]) {
        BOOL isRunning = ((AVCaptureSession *)object).running;
        if (isRunning) {
            NSLog(@"Session is Running...");
        } else {
            NSLog(@"Session Stop running!");
        }
    }
    
    if ([keyPath isEqualToString:@"interrupted"]) {
        BOOL isInterrupted = ((AVCaptureSession *)object).interrupted;
        if (isInterrupted) {
            NSLog(@"Session is interrupted!");
        } else {
            NSLog(@"Session is not interrupted.");
        }
    }
}

#pragma mark AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(nonnull AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error {
    if (error) {
        NSLog(@"Take Photo Error occured.%@",error.description);
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureDidFinishProcessingPhotoAsJPEGImage:error:)]) {
            [self.delegate captureDidFinishProcessingPhotoAsJPEGImage:nil error:error];
        }
    }
    if (photoSampleBuffer) {
        NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
        UIImage *image = [UIImage imageWithData:data];
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureDidFinishProcessingPhotoAsJPEGImage:error:)]) {
            [self.delegate captureDidFinishProcessingPhotoAsJPEGImage:image error:nil];
        }
    }
}

@end
