//
//  RSVideoRotateCommand.h
//  RealSocial
//
//  Created by Kira on 2018/5/4.
//  Copyright © 2018年 scnukuncai. All rights reserved.
//

#import "RSVideoCommand.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface RSVideoRotateCommand : RSVideoCommand

@property AVAssetExportSession *exportSession;

- (void)performWithAsset:(AVAsset*)asset withDegress:(NSInteger) degress;

@end
