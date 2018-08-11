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
    AVCapturePhotoSettings *_photoSettings;
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
        if (!_session.isRunning) {
            [_session startRunning];
        }
    });
}

- (void)stopCamera {
    dispatch_async( self.sessionQueue, ^{
        if (_session.isRunning) {
            [_session stopRunning];
        }
    });
}

- (void)capturePhoto {
    if (_photoOutput && _photoSettings) {
        _photoSettings.flashMode = AVCaptureFlashModeOff;
        _photoSettings.highResolutionPhotoEnabled = YES;
        if (_photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 ) {
            _photoSettings.previewPhotoFormat = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : _photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject };
        }
        if (@available(iOS 11.0, *)) {
            if (_photoOutput.isDepthDataDeliverySupported ) {
                _photoSettings.depthDataDeliveryEnabled = YES;
            } else {
                _photoSettings.depthDataDeliveryEnabled = NO;
            }
        }
        OFAPhotoCaptureDelegate *photoCaptureDelegate = [[OFAPhotoCaptureDelegate alloc] initWithRequestedPhotoSettings:_photoSettings willCapturePhotoAnimation:^{
      
        } completionHandler:^(OFAPhotoCaptureDelegate * _Nonnull photoCaptureDelegate) {
            dispatch_async( self.sessionQueue, ^{
                self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = nil;
            } );
        }];
        self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = photoCaptureDelegate;
        [_photoOutput capturePhotoWithSettings:_photoSettings delegate:self];
    }
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
     _photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecJPEG}];
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
