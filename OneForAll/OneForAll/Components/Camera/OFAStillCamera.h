//
//  OFAStillCamera.h
//  OneForAll
//
//  Created by Kira on 2018/8/11.
//  Copyright © 2018 Kira. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "OFACameraPreviewView.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM( NSInteger, OFACameraSetupResult ) {
    OFACameraSetupResultSuccess,
    OFACameraSetupResultNotAuthorized,
    OFACameraSetupResultFailed
};

@protocol OFAStillCameraDelegate <NSObject>

@optional

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

- (void)captureDidFinishProcessingPhotoAsJPEGImage:(nullable UIImage *)photo error:(nullable NSError *)error;
- (void)captureAnimation;

@end

@interface OFAStillCamera : NSObject
@property (nonatomic, weak) id<OFAStillCameraDelegate> delegate;
@property (nonatomic, strong, readonly) AVCaptureSession* session;
@property (nonatomic, assign) OFACameraSetupResult setupResult;

- (void)startCamera;
- (void)stopCamera;

- (void)capturePhoto;
- (void)rotateCamera;

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

- (void)configureSession;

- (void)addNotificationToCaptureSession;
- (void)removeAllNotification;
@end

NS_ASSUME_NONNULL_END
