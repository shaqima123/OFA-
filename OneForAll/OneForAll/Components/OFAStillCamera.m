//
//  OFAStillCamera.m
//  OneForAll
//
//  Created by Kira on 2018/8/11.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFAStillCamera.h"
#import "OFAPhotoCaptureDelegate.h"
@interface OFAStillCamera ()<
    AVCapturePhotoCaptureDelegate
>
{
    AVCaptureSession *_session;
    AVCaptureDeviceDiscoverySession *_videoDeviceDiscoverySession;
    AVCaptureDeviceInput *_videoInput;
    AVCapturePhotoOutput *_photoOutput;
}

@property (nonatomic) NSMutableDictionary<NSNumber *, OFAPhotoCaptureDelegate*> *inProgressPhotoCaptureDelegates;
@property (nonatomic) dispatch_queue_t sessionQueue;


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

- (void)capturePhoto {
    dispatch_async( self.sessionQueue, ^{
        if (self->_photoOutput) {
            //如果是前置相机，拍照为镜像
            AVCaptureDevice *currentVideoDevice = self ->_videoInput.device;
            AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
            if (currentPosition == AVCaptureDevicePositionFront) {
                AVCaptureConnection * connection = [self->_photoOutput connectionWithMediaType:AVMediaTypeVideo];
                if ([connection isVideoMirroringSupported]) {
                    [connection setVideoMirrored:YES];
                }
            }
            
            //AVCapturePhotoSetting不能重复使用
            AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecJPEG}];
            photoSettings.flashMode = AVCaptureFlashModeOff;
            photoSettings.highResolutionPhotoEnabled = YES;
            if (photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 ) {
                photoSettings.previewPhotoFormat = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject };
            }
            if (@available(iOS 11.0, *)) {
                if (self->_photoOutput.isDepthDataDeliverySupported ) {
                    photoSettings.depthDataDeliveryEnabled = YES;
                } else {
                    photoSettings.depthDataDeliveryEnabled = NO;
                }
            }
            OFAPhotoCaptureDelegate *photoCaptureDelegate = [[OFAPhotoCaptureDelegate alloc] initWithRequestedPhotoSettings:photoSettings willCapturePhotoAnimation:^{
                
            } completionHandler:^(OFAPhotoCaptureDelegate * _Nonnull photoCaptureDelegate) {
                dispatch_async( self.sessionQueue, ^{
                    self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = nil;
                } );
            }];
            self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = photoCaptureDelegate;
            [self->_photoOutput capturePhotoWithSettings:photoSettings delegate:photoCaptureDelegate];
        }
    });
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
        [self->_session commitConfiguration];
    } );
}

- (BOOL)setupSessionInput {
    NSError *error = nil;
    _session.sessionPreset = AVCaptureSessionPresetPhoto;
    AVCaptureDevice *videoDevice = nil;
    if (@available(iOS 10.2, *)) {
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    }
    if (!videoDevice) {
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        if (!videoDevice ) {
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        }
    }
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (!_videoInput) {
        NSLog(@"DeviceInput Error,%@",error.description);
        self.setupResult = OFACameraSetupResultFailed;
        [_session commitConfiguration];
        return NO;
    }
    if ([_session canAddInput:_videoInput]) {
        [_session addInput:_videoInput];
    } else {
        NSLog(@"Session Error in add DeviceInput!");
        self.setupResult = OFACameraSetupResultFailed;
        [_session commitConfiguration];
        return NO;
    }
    return YES;
}

- (BOOL)setupSessionOutPut {
    //AVCaptureStillImageOutput 在iOS10之后就被弃用了
     _photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([_session canAddOutput:_photoOutput]) {
        [_session addOutput:_photoOutput];
        _photoOutput.highResolutionCaptureEnabled = YES;
        if (@available(iOS 11.0, *)) {
            _photoOutput.depthDataDeliveryEnabled = _photoOutput.depthDataDeliverySupported;
        }
        self.inProgressPhotoCaptureDelegates = @{}.mutableCopy;
    } else {
        NSLog(@"Could not add photo output to the session" );
        self.setupResult = OFACameraSetupResultFailed;
        [_session commitConfiguration];
        return NO;
    }
    return YES;
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
