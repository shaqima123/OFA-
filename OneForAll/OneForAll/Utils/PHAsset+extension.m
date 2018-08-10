//
//  PHAsset+extension.m
//  RealSocial
//
//  Created by kira on 2018/3/22.
//  Copyright © 2018年 scnukuncai. All rights reserved.
//

#import "PHAsset+extension.h"

@implementation PHAsset (extension)

+ (PHAsset *)latestAsset {
    // 获取所有资源的集合，并按资源的创建时间排序
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    return [assetsFetchResults firstObject];
}

@end
