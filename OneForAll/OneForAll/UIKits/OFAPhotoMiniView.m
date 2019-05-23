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
{
    CGFloat originX;
}
@property (nonatomic, strong) UIImageView *photoImageView;
@property (nonatomic, strong) UIImage *photo;

@end
@implementation OFAPhotoMiniView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        originX = frame.origin.x;
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
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(actionTap:)];
    [self addGestureRecognizer:tap];
    
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] init];
    [pan addTarget:self action:@selector(actionPan:)];
    [self addGestureRecognizer:pan];
}

- (void)updatePhoto:(UIImage *)image {
    self.photo = image;
    [self.photoImageView setImage:image];
}

- (UIImage *)getPhoto {
    return self.photo;
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

- (void)actionTap:(UITapGestureRecognizer *)tap {
    if (self.delegate && [self.delegate respondsToSelector:@selector(miniViewTapped:)]) {
        [self.delegate miniViewTapped:self];
    }
}

- (void)actionPan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [pan translationInView:self];
        CGFloat absX = fabs(translation.x);
        CGFloat absY = fabs(translation.y);
        // 设置滑动有效距离
        if (MAX(absX, absY) < 5)
            return;
        
        if (absX > absY ) {
            if (self.center.x + translation.x < originX) {
                [self setCenter:CGPointMake(originX, self.center.y)];
            } else {
                [self setCenter:CGPointMake(self.center.x + translation.x, self.center.y)];
            }
        }
    }
    
    if (pan.state == UIGestureRecognizerStateEnded) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(miniViewPanEnded:)]) {
            [self.delegate miniViewPanEnded:self];
        }
    }
    [pan setTranslation:CGPointZero inView:self];
}

@end
