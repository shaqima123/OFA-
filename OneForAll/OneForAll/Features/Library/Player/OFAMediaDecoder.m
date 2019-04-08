//
//  OFAMediaDecoder.m
//  OneForAll
//
//  Created by Kira on 2019/4/7.
//  Copyright © 2019 Kira. All rights reserved.
//

#import <CoreVideo/CVImageBuffer.h>
#import "OFAMediaDecoder.h"
#import "avformat.h"
#import "avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"

//category
#import "NSError+Util.h"

@interface OFAMediaDecoder()

@property (nonatomic, assign) int readLastestFrameTime;
@property (nonatomic, assign) int subscribeTimeOutTimeInSecs;
@property (nonatomic, assign) BOOL interrupted;
@property (nonatomic, assign) BOOL isSubscribe;


@property (nonatomic, assign) AVFormatContext* formatCtx;

//音视频流的索引
@property (nonatomic, assign) NSInteger videoStreamIndex;
@property (nonatomic, assign) NSInteger audioStreamIndex;

@property (nonatomic, strong) NSArray* videoStreamIndexs;
@property (nonatomic, strong) NSArray* audioStreamIndexs;


@property (nonatomic, assign) AVCodecContext* videoCodecCtx;
@property (nonatomic, assign) AVCodecContext* audioCodecCtx;;
@property (nonatomic, assign) SwrContext* swrContext;

@property (nonatomic, assign) AVFrame* videoFrame;
@property (nonatomic, assign) AVFrame* audioFrame;                  ;

@end
@implementation OFAMediaDecoder

static int interrupt_callback(void *ctx)
{
    if (!ctx)
        return 0;
    __unsafe_unretained OFAMediaDecoder *p = (__bridge OFAMediaDecoder *)ctx;
    const BOOL r = [p detectInterrupted];
    if (r) NSLog(@"DEBUG: INTERRUPT_CALLBACK!");
    return r;
}

static NSArray *collectStreamIndexs(AVFormatContext *formatCtx, enum AVMediaType codecType)
{
    NSMutableArray *ma = [NSMutableArray array];
    for (NSInteger i = 0; i < formatCtx->nb_streams; ++i)
        if (codecType == formatCtx->streams[i]->codec->codec_type)
            [ma addObject: [NSNumber numberWithInteger: i]];
    return [ma copy];
}

- (void)interrupt
{
    _subscribeTimeOutTimeInSecs = -1;
    _interrupted = YES;
    _isSubscribe = NO;
}

- (BOOL)detectInterrupted
{
    if ([[NSDate date] timeIntervalSince1970] - _readLastestFrameTime > _subscribeTimeOutTimeInSecs) {
        return YES;
    }
    return _interrupted;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)setupParameters {
    _interrupted = NO;
    _isSubscribe = YES;
    _subscribeTimeOutTimeInSecs = SUBSCRIBE_VIDEO_DATA_TIME_OUT;
    _readLastestFrameTime = [[NSDate date] timeIntervalSince1970];
}

- (void)protocolParser {
    
}

- (void)formatDemuxer {
    
}

- (void)decoder {
    
}

- (void)openFile:(NSURL *)fileURL parameter:(NSDictionary *)parameters error:(NSError **)error {
    //将所有编码器注册到ffmpeg中，内部包含 avcodec_register_all 方法。
    av_register_all();
    
    AVFormatContext *formatCtx = avformat_alloc_context();
    //注册中断的回调方法
    AVIOInterruptCB int_cb  = {interrupt_callback, (__bridge void *)(self)};
    formatCtx->interrupt_callback = int_cb;
    
    //打开文件以及错误的异常处理
    int openInputErrCode = 0;
    if((openInputErrCode = [self avformatOpenInput:&formatCtx path:fileURL.absoluteString parameter:nil]) != 0) {
        NSString *errString = [NSString stringWithFormat:@"MediaDecoder: Video decoder open input file failed. videoSourceURI is %@ openInputErr is %s", fileURL.absoluteString, av_err2str(openInputErrCode)];
        if (formatCtx)
            avformat_free_context(formatCtx);
        [self dealThingsWhenErrorOccurs:errString code:OFADecoderOpenInputError];
        return;
    }
    
    //寻找Stream
    int findStreamErrCode = 0;
    if ((findStreamErrCode = avformat_find_stream_info(formatCtx, NULL)) < 0) {
        NSString *errString = [NSString stringWithFormat:@"MediaDecoder: Video decoder find stream info failed... find stream ErrCode is %s", av_err2str(findStreamErrCode)];
        avformat_close_input(&formatCtx);
        avformat_free_context(formatCtx);
        [self dealThingsWhenErrorOccurs:errString code:OFADecoderFindStreamError];
        return;
    }
    
    self.formatCtx = formatCtx;
}

- (int)avformatOpenInput:(AVFormatContext **)formatContext path:(NSString *)path parameter:(NSDictionary*) params {
    NSString *p = nil;
    if ([path isKindOfClass:[NSURL class]]) {
        p = ((NSURL *)path).absoluteString;
    } else {
        p = path;
    }
    const char *videoSourceURI = [p cStringUsingEncoding:NSUTF8StringEncoding];
    AVDictionary *options = nil;
    
    //TODO:待理解，和RTMP协议有关
    NSString* rtmpTcurl = params[RTMP_TCURL_KEY];
    if([rtmpTcurl length] > 0){
        const char *rtmp_tcurl = [rtmpTcurl cStringUsingEncoding: NSUTF8StringEncoding];
        av_dict_set(&options, "rtmp_tcurl", rtmp_tcurl, 0);
    }
    return avformat_open_input(formatContext, videoSourceURI, NULL, &options);
}

- (BOOL)openVideoStream {
    self.videoStreamIndex = -1;
    self.videoStreamIndexs = collectStreamIndexs(self.formatCtx, AVMEDIA_TYPE_VIDEO);
    if (self.videoStreamIndexs.count) {
        //stream 中的 codecContext 将弃用，用 AVCodecParameters 代替
        int index = ((NSNumber *)[self.videoStreamIndexs objectAtIndex:0]).intValue;
        AVCodecParameters *codecParam = self.formatCtx->streams[index]->codecpar;
        AVCodec *codec = avcodec_find_decoder(codecParam->codec_id);
        AVCodecContext *codecCtx = avcodec_alloc_context3(codec);
        if (!codec) {
            NSString *errString = [NSString stringWithFormat:@"MediaDecoder: Find Video Decoder Failed codec_id %d", codecParam->codec_id];
            [self dealThingsWhenErrorOccurs:errString code:OFADecoderFindDecoderError];
            return NO;
        }
        
        int openCodecError = 0;
        if ((openCodecError = avcodec_open2(codecCtx, codec, NULL)) < 0) {
            NSString *errString = [NSString stringWithFormat:@"MediaDecoder: open Video Codec Failed openCodecErr is %s", av_err2str(openCodecError)];
            [self dealThingsWhenErrorOccurs:errString code:OFADecoderFindDecoderError];
            return NO;
        }
        
        self.videoFrame = av_frame_alloc();
        if (!self.videoFrame) {
            NSString *errString = @"MediaDecoder: Alloc Video Frame Failed...";
            avcodec_close(codecCtx);
            [self dealThingsWhenErrorOccurs:errString code:OFAFrameCreateError];
            return NO;
        }
        
        self.videoStreamIndex = index;
        self.videoCodecCtx = codecCtx;
        //此处可以增加解码的fps
    }
    return YES;
}

- (BOOL)openAudioStream {
    self.audioStreamIndex = -1;
    self.audioStreamIndexs = collectStreamIndexs(self.formatCtx, AVMEDIA_TYPE_AUDIO);
    if (self.audioStreamIndexs.count) {
        //stream 中的 codecContext 将弃用，用 AVCodecParameters 代替
        int index = ((NSNumber *)[self.audioStreamIndexs objectAtIndex:0]).intValue;
        AVCodecParameters *codecParam = self.formatCtx->streams[index]->codecpar;
        AVCodec *codec = avcodec_find_decoder(codecParam->codec_id);
        AVCodecContext *codecCtx = avcodec_alloc_context3(codec);

        if (!codec) {
            NSString *errString = [NSString stringWithFormat:@"MediaDecoder: Find Audio Decoder Failed codec_id %d", codecParam->codec_id];
            [self dealThingsWhenErrorOccurs:errString code:OFADecoderFindDecoderError];
            return NO;
        }
        
        int openCodecError = 0;
        if ((openCodecError = avcodec_open2(codecCtx, codec, NULL)) < 0) {
            NSString *errString = [NSString stringWithFormat:@"MediaDecoder: open Audio Codec Failed openCodecErr is %s", av_err2str(openCodecError)];
            [self dealThingsWhenErrorOccurs:errString code:OFADecoderFindDecoderError];
            return NO;
        }
        
        
        
        
        SwrContext *swrContext = nil;
        if (![self audioCodecIsSupported:codecCtx]) {
            //不支持AV_SAMPLE_FMT_S16，需要初始化swresampler
            swrContext = swr_alloc_set_opts(NULL,
                                            av_get_default_channel_layout(codecCtx->channels),
                                            AV_SAMPLE_FMT_S16,
                                            codecCtx->sample_rate,
                                            av_get_default_channel_layout(codecCtx->channels),
                                            codecCtx->sample_fmt,
                                            codecCtx->sample_rate,
                                            0,
                                            NULL);
            
            if (!swrContext || swr_init(swrContext)) {
                if (swrContext)
                    swr_free(&swrContext);
                avcodec_close(codecCtx);
                NSString *errString = [NSString stringWithFormat:@"MediaDecoder: init resampler failed.."];
                [self dealThingsWhenErrorOccurs:errString code:OFADecodeReSampleError];
                return NO;
            }
        }

        self.audioFrame = av_frame_alloc();
        if (!self.audioFrame) {
            NSString *errString = @"MediaDecoder: Alloc Audio Frame Failed...";
            if (swrContext)
                swr_free(&swrContext);
            avcodec_close(codecCtx);
            [self dealThingsWhenErrorOccurs:errString code:OFAFrameCreateError];
            return NO;
        }
        
        
        self.swrContext = swrContext;
        self.audioStreamIndex = index;
        self.audioCodecCtx = codecCtx;
        //此处可以增加解码的fps检测
    }
    return YES;
}

- (BOOL)audioCodecIsSupported:(AVCodecContext *) audioCodecCtx;
{
    if (audioCodecCtx->sample_fmt == AV_SAMPLE_FMT_S16) {
        return true;
    }
    return false;
}

+ (void)closeFile {
    
}

+ (BOOL)isEOF {
    return NO;
}

+ (void)decodeFrame:(NSTimeInterval)duration {
    
}


#pragma mark Error

- (void)dealThingsWhenErrorOccurs:(NSString*)errString code:(NSInteger)errCode {
    NSLog(@"%@",errString);
    NSError *error = [NSError errorWithString:errString code:errCode];
    self.errorBlock(error);
}
@end
