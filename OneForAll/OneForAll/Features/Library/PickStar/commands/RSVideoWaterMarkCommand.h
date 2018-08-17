//
//  RSVideoWaterMarkCommand.h
//  RealSocial
//
//  Created by Kira on 2018/7/9.
//  Copyright © 2018 scnukuncai. All rights reserved.
//

#import "RSVideoCommand.h"
#import "QuartzCore/QuartzCore.h"
#import "RSEditElementModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RSVideoWaterMarkCommand : RSVideoCommand

@property (nonatomic ,strong) NSArray <RSEditElementModel *>* elementArray;
@property (nonatomic, assign) CGFloat coordinateRatio;//image.width / SCREEN_WIDTH

@end

NS_ASSUME_NONNULL_END
