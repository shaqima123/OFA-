//
//  RSVideoCommand.m
//  RealSocial
//
//  Created by Kira on 2018/5/4.
//  Copyright © 2018年 scnukuncai. All rights reserved.
//

#import "RSVideoCommand.h"

NSString* const AVSEEditCommandCompletionNotification = @"AVSEEditCommandCompletionNotification";
NSString* const AVSEExportCommandCompletionNotification = @"AVSEExportCommandCompletionNotification";

@implementation RSVideoCommand

- (id)initWithComposition:(AVMutableComposition *)composition videoComposition:(AVMutableVideoComposition *)videoComposition audioMix:(AVMutableAudioMix *)audioMix
{
    self = [super init];
    if(self != nil) {
        self.mutableComposition = composition;
        self.mutableVideoComposition = videoComposition;
        self.mutableAudioMix = audioMix;
    }
    return self;
}

- (void)performWithAsset:(AVAsset*)asset
{
    [self doesNotRecognizeSelector:_cmd];
}


@end
