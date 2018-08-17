//
//  OFAVideoCamera.h
//  OneForAll
//
//  Created by Kira on 2018/8/17.
//  Copyright © 2018 Kira. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OFAStillCamera.h"

@protocol OFAVideoCameraDelegate <NSObject>

@optional
- (void)didStartRecordingToOutputFileAtURL:(NSURL *)fileURL;
- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)fileURL;

@end


NS_ASSUME_NONNULL_BEGIN

@interface OFAVideoCamera : NSObject
@property (nonatomic, weak) id<OFAVideoCameraDelegate> delegate;
@property (nonatomic, strong, readonly) AVCaptureSession* session;
@property (nonatomic, assign) OFACameraSetupResult setupResult;

- (void)startCamera;
- (void)stopCamera;

- (void)startRecord;
- (void)endRecord;

- (void)rotateCamera;

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

- (void)configureSession;

- (void)addNotificationToCaptureSession;
- (void)removeAllNotification;


@end

NS_ASSUME_NONNULL_END
