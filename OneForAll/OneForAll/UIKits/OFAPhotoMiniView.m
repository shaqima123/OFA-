//
//  OFAPhotoMiniView.m
//  OneForAll
//
//  Created by Kira on 2018/8/13.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFAPhotoMiniView.h"
#import <Photos/Photos.h>

@interface OFAPhotoMiniView()

@property (nonatomic, strong) UIImageView *photoImageView;

@end
@implementation OFAPhotoMiniView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self photoImageView];
    
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:8.f];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path2.CGPath;
    [self.layer setMask:maskLayer];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) cornerRadius:8.f];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = path.CGPath;
    layer.lineWidth = 6.f;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:layer];
}
- (void)updatePhoto:(UIImage *)image {
    [self.photoImageView setImage:image];
}

- (void)updatePhoto {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    PHAsset *asset = [assetsFetchResults firstObject];
    
    PHImageManager *manager = [PHImageManager defaultManager];
    @OFAWeakObj(self);
    [manager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        [weakself.photoImageView setImage:result];
    }];
}

- (UIImageView *)photoImageView {
    if (!_photoImageView) {
        _photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [_photoImageView setContentMode:UIViewContentModeScaleAspectFill];
        [self addSubview:_photoImageView];
        [_photoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return _photoImageView;
}
@end
