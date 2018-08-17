//
//  OFAVideoCamera.m
//  OneForAll
//
//  Created by Kira on 2018/8/17.
//  Copyright © 2018 Kira. All rights reserved.
//
@import Photos;
@import AVFoundation;

#import "OFAVideoCamera.h"

@interface OFAVideoCamera ()
<
AVCaptureFileOutputRecordingDelegate
>
{
    AVCaptureSession *_session;
    AVCaptureDeviceDiscoverySession *_videoDeviceDiscoverySession;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureMovieFileOutput *_movieFileOutput;
}

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@end

@implementation OFAVideoCamera

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
    dispatch_async( self.sessionQueue, ^{
        if (!self->_session.isRunning) {
            [self->_session startRunning];
        }
    });
}

- (void)stopCamera {
    dispatch_async( self.sessionQueue, ^{
        if (self->_session.isRunning) {
            [self->_session stopRunning];
        }
    });
}

- (void)startRecord {
    dispatch_async( self.sessionQueue, ^{
        if (!self->_movieFileOutput.isRecording ) {
            if ( [UIDevice currentDevice].isMultitaskingSupported ) {
                //设置后台任务，因为captureoutput didfinishrecord方法在应用返回前台之前不会被调用到，除非设置了后台任务。在didfinishrecord回调中会结束这个后台执行
                self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
            }
            
            //TODO 视频方向的设置
//            // Update the orientation on the movie file output video connection before starting recording.
            AVCaptureConnection *movieFileOutputConnection = [self->_movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//            movieFileOutputConnection.videoOrientation = videoPreviewLayerVideoOrientation;
            
            // Use HEVC codec if supported
            if (@available(iOS 11.0, *)) {
                if ( [self ->_movieFileOutput.availableVideoCodecTypes containsObject:AVVideoCodecTypeHEVC] ) {
                    [self ->_movieFileOutput setOutputSettings:@{ AVVideoCodecKey : AVVideoCodecTypeHEVC } forConnection:movieFileOutputConnection];
                }
            }
            
            
            NSString *outputFileName = @"pickStarMovie";
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
            
            //TODO:better
//            if ( [[NSFileManager defaultManager] fileExistsAtPath:outputFilePath] ) {
//                [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:NULL];
//            }
            
            [self-> _movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
        }
    } );
}

- (void)endRecord {
    [_movieFileOutput stopRecording];
}

- (void)rotateCamera {
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *currentVideoDevice = self ->_videoInput.device;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        AVCaptureDevicePosition preferredPosition;
        AVCaptureDeviceType preferredDeviceType;
        
        switch ( currentPosition )
        {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                if (@available(iOS 10.2, *)) {
                    preferredDeviceType = AVCaptureDeviceTypeBuiltInDualCamera;
                }
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
                break;
        }
        
        NSArray<AVCaptureDevice *> *devices = self ->_videoDeviceDiscoverySession.devices;
        AVCaptureDevice *newVideoDevice = nil;
        
        for ( AVCaptureDevice *device in devices ) {
            if ( device.position == preferredPosition && [device.deviceType isEqualToString:preferredDeviceType] ) {
                newVideoDevice = device;
                break;
            }
        }
        
        if ( ! newVideoDevice ) {
            for ( AVCaptureDevice *device in devices ) {
                if ( device.position == preferredPosition ) {
                    newVideoDevice = device;
                    break;
                }
            }
        }
        
        if ( newVideoDevice ) {
            AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];
            
            [self.session beginConfiguration];
            
            // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
            [self.session removeInput:self->_videoInput];
            
            if ( [self.session canAddInput:videoDeviceInput] ) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newVideoDevice];
                
                [self.session addInput:videoDeviceInput];
                self-> _videoInput = videoDeviceInput;
            }
            else {
                [self.session addInput:self ->_videoInput];
            }
            [self.session commitConfiguration];
        }
    } );
}


- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice *device = self->_videoInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            /*
             Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
             Call set(Focus/Exposure)Mode() to apply the new point of interest.
             */
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

#pragma mark Setup
- (void)setupSession {
    _session = [[AVCaptureSession alloc] init];
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    NSArray<AVCaptureDeviceType> *deviceTypes = @[].mutableCopy;
    if (@available(iOS 10.2, *)) {
        deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera];
    } else {
        deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
    }
    _videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    self.setupResult = OFACameraSetupResultSuccess;
}


- (void)configureSession {
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            dispatch_suspend(self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = OFACameraSetupResultNotAuthorized;
                }
                dispatch_resume(self.sessionQueue);
            }];
            break;
        }
        default:
        {
            // The user has previously denied access.
            self.setupResult = OFACameraSetupResultNotAuthorized;
            break;
        }
    }
    //session修改有关的操作都是耗时的，为了防止阻塞主线程，使用异步
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult != OFACameraSetupResultSuccess) {
            return;
        }
        [self->_session beginConfiguration];
        if (![self setupSessionInput]) return;
        if (![self setupSessionOutPut]) return;
        self.backgroundRecordingID = UIBackgroundTaskInvalid;
        [self->_session commitConfiguration];
    } );
}

- (BOOL)setupSessionInput {
    NSError *error = nil;
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    //set videoInput
    AVCaptureDevice *videoDevice = nil;
    videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    if (!videoDevice ) {
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    }
    
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (!_videoInput) {
        NSLog(@"DeviceInput Error Video,%@",error.description);
        self.setupResult = OFACameraSetupResultFailed;
        [_session commitConfiguration];
        return NO;
    }
    if ([_session canAddInput:_videoInput]) {
        [_session addInput:_videoInput];
    } else {
        NSLog(@"Session Error in add DeviceInput Video!");
        self.setupResult = OFACameraSetupResultFailed;
        [_session commitConfiguration];
        return NO;
    }
    
    //set AudioInput
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!audioDeviceInput) {
        NSLog(@"DeviceInput Error Audio,%@",error.description);
        //没有声音不中断，只是可以只录制画面
    }
    if ( [self.session canAddInput:audioDeviceInput] ) {
        [self.session addInput:audioDeviceInput];
    }
    else {
        NSLog( @"Session Error in add DeviceInput Audio!" );
    }
    return YES;
}

- (BOOL)setupSessionOutPut {
    _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([_session canAddOutput:_movieFileOutput]) {
        [_session addOutput:_movieFileOutput];
        AVCaptureConnection *connection = [_movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoStabilizationSupported ) {
            //设置适合设备和格式的视频稳定模式，可以设置防抖功能
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    } else {
        NSLog(@"Could not add movie output to the session" );
        self.setupResult = OFACameraSetupResultFailed;
        [_session commitConfiguration];
        return NO;
    }
    return YES;
}

#pragma mark AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    dispatch_async( dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(didStartRecordingToOutputFileAtURL:)]) {
            [self.delegate didStartRecordingToOutputFileAtURL:fileURL];
        }
    });
}



- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    dispatch_block_t cleanUp = ^{
//        if ( [[NSFileManager defaultManager] fileExistsAtPath:outputFileURL.path] ) {
//            [[NSFileManager defaultManager] removeItemAtPath:outputFileURL.path error:NULL];
//        }
//
        if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
            [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
        }
    };
    
    BOOL success = YES;
    
    if ( error ) {
        NSLog( @"Movie file finishing error: %@", error );
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    if ( success ) {
//        [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
//            if ( status == PHAuthorizationStatusAuthorized ) {
//                // Save the movie file to the photo library and cleanup.
//                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//                    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
//                    options.shouldMoveFile = YES;
//                    PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
//                    [creationRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
//                } completionHandler:^( BOOL success, NSError *error ) {
//                    if ( ! success ) {
//                        NSLog( @"Movie Save Error: %@", error.description );
//                    }
//                    cleanUp();
//                }];
//            }
//            else {
//                cleanUp();
//            }
//        }];
    }
    else {
        cleanUp();
    }
    
    dispatch_async( dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:)]) {
            [self.delegate didFinishRecordingToOutputFileAtURL:outputFileURL];
        }
    });
}

#pragma mark Set - get
- (AVCaptureSession *)session {
    return _session;
}

#pragma mark Notification
- (void)addNotificationToCaptureSession {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:_videoInput.device];
}

- (void)removeAllNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    //    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

@end
