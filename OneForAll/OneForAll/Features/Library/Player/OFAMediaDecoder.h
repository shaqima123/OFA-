//
//  OFAMediaDecoder.h
//  OneForAll
//
//  Created by Kira on 2019/4/7.
//  Copyright © 2019 Kira. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef SUBSCRIBE_VIDEO_DATA_TIME_OUT
#define SUBSCRIBE_VIDEO_DATA_TIME_OUT               20
#endif

#ifndef RTMP_TCURL_KEY
#define RTMP_TCURL_KEY                              @"RTMP_TCURL_KEY"
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^OFAMediaDecoderError)(NSError *error);

@interface OFAMediaDecoder : NSObject

@property (nonatomic, copy) OFAMediaDecoderError errorBlock;

@end

NS_ASSUME_NONNULL_END
