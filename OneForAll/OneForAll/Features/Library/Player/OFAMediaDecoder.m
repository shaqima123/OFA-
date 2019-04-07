//
//  OFAMediaDecoder.m
//  OneForAll
//
//  Created by Kira on 2019/4/7.
//  Copyright © 2019 Kira. All rights reserved.
//

#import "OFAMediaDecoder.h"
#import "avformat.h"

@implementation OFAMediaDecoder

- (instancetype)init
{
    self = [super init];
    if (self) {
        av_register_all();
    }
    return self;
}
@end
