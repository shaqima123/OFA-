//
//  OFAPhotoCaptureDelegate.m
//  OneForAll
//
//  Created by Kira on 2018/8/11.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFAPhotoCaptureDelegate.h"


@import Photos;

@interface OFAPhotoCaptureDelegate ()

@property (nonatomic, readwrite) AVCapturePhotoSettings *requestedPhotoSettings;
@property (nonatomic) void (^willCapturePhotoAnimation)(void);
@property (nonatomic) void (^completionHandler)(OFAPhotoCaptureDelegate *photoCaptureDelegate);
@property (nonatomic, strong, readwrite) UIImage *image;
@end

@implementation OFAPhotoCaptureDelegate

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings willCapturePhotoAnimation:(void (^)(void))willCapturePhotoAnimation completionHandler:(void (^)(OFAPhotoCaptureDelegate *))completionHandler
{
    self = [super init];
    if ( self ) {
        self.requestedPhotoSettings = requestedPhotoSettings;
        self.willCapturePhotoAnimation = willCapturePhotoAnimation;
        self.completionHandler = completionHandler;
    }
    return self;
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
    self.willCapturePhotoAnimation();
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    //如果设置 depthDataDeliveryEnabled 为yes，必须实现该代理方法
    if ( error != nil ) {
        NSLog( @"Error capturing photo: %@", error );
        return;
    }
    NSData *data = [photo fileDataRepresentation];
    [self savePhotoData:data];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(nonnull AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error {
    if (error) {
        NSLog(@"Take Photo Error occured.%@",error.description);
        self.completionHandler(self);
    }
    if (photoSampleBuffer) {
        NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
        [self savePhotoData:data];
    }
}

- (void)savePhotoData:(NSData *)data {
    UIImage *image = [UIImage imageWithData:data];
    self.image = image;
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                
                PHAssetCollection *targetCollection = [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil]lastObject];
                
                PHAssetCollectionChangeRequest *changeCollectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:targetCollection];
                
                PHObjectPlaceholder *assetPlaceholder = [changeAssetRequest placeholderForCreatedAsset];
                
                [changeCollectionRequest addAssets:@[assetPlaceholder]];
                
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    NSLog( @"Error occurred while saving photo to photo library: %@", error );
                }
                self.completionHandler(self);
            }];
        } else {
            NSLog( @"Not authorized to save photo" );
            self.completionHandler(self);
        }
    }];
}

@end
