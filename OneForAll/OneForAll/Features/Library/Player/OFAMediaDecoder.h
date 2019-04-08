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
typedef enum {
    OFAAudioFrameType,
    OFAVideoFrameType,
    OFAiOSCVVideoFrameType,
} OFAFrameType;

@interface OFAMediaDecoder : NSObject

@property (nonatomic, copy) OFAMediaDecoderError errorBlock;

@end


@interface OFAFrame : NSObject
@property (readwrite, nonatomic) OFAFrameType type;
@property (readwrite, nonatomic) CGFloat position;
@property (readwrite, nonatomic) CGFloat duration;
@end

@interface OFAAudioFrame : OFAFrame
@property (readwrite, nonatomic, strong) NSData *samples;
@end

@interface OFAVideoFrame : OFAFrame
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
@property (readwrite, nonatomic) NSUInteger linesize;
@property (readwrite, nonatomic, strong) NSData *luma;
@property (readwrite, nonatomic, strong) NSData *chromaB;
@property (readwrite, nonatomic, strong) NSData *chromaR;
@property (readwrite, nonatomic, strong) id imageBuffer;
@end

NS_ASSUME_NONNULL_END
