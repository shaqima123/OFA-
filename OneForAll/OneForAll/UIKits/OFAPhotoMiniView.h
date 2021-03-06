//
//  OFAPhotoMiniView.h
//  OneForAll
//
//  Created by Kira on 2018/8/13.
//  Copyright © 2018 Kira. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol OFAPhotoMiniViewDelegate <NSObject>

@optional
- (void)miniViewTapped;
- (void)miniViewPanEnded;

@end


@interface OFAPhotoMiniView : UIView
@property (nonatomic, weak) id<OFAPhotoMiniViewDelegate> delegate;

- (void)updatePhoto:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
