//
//  OFAPhotoCaptureDelegate.h
//  OneForAll
//
//  Created by Kira on 2018/8/11.
//  Copyright © 2018 Kira. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

@interface OFAPhotoCaptureDelegate : NSObject<AVCapturePhotoCaptureDelegate>

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings willCapturePhotoAnimation:(void (^)(void))willCapturePhotoAnimation completionHandler:(void (^)(OFAPhotoCaptureDelegate *photoCaptureDelegate ))completionHandler;

@property (nonatomic, readonly) AVCapturePhotoSettings *requestedPhotoSettings;
@end

NS_ASSUME_NONNULL_END
