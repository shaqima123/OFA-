//
//  OFAStillCamera.h
//  OneForAll
//
//  Created by Kira on 2018/8/11.
//  Copyright © 2018 Kira. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol OFAStillCameraDelegate <NSObject>

@optional

- (void)captureDidFinishProcessingPhotoAsJPEGImage:(nullable UIImage *)photo error:(nullable NSError *)error;
- (void)successFromAvatarEditAfterCamera;

@end

@interface OFAStillCamera : NSObject
@property (nonatomic, weak) id<OFAStillCameraDelegate> delegate;
@property (nonatomic, strong, readonly) AVCaptureSession* session;

- (void)startCamera;
- (void)stopCamera;
- (void)capturePhoto;

@end

NS_ASSUME_NONNULL_END
