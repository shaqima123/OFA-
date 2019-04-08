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

@implementation OFAFrame : NSObject

@end

@implementation OFAAudioFrame : OFAFrame

@end

@implementation OFAVideoFrame : OFAFrame

@end


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
@property (nonatomic, assign) void* swrBuffer;
@property (nonatomic, assign) NSUInteger swrBufferSize;

@property (nonatomic, assign) struct SwsContext* swsContext;
@property (nonatomic, assign) AVPicture picture;
@property (nonatomic, assign) BOOL pictureValid;

@property (nonatomic, assign) AVFrame* videoFrame;
@property (nonatomic, assign) AVFrame* audioFrame;
@property (nonatomic, assign) BOOL isEOF;

@property (nonatomic, assign) int totalVideoFramecount;

@property (nonatomic, assign) CGFloat decodePosition;

@end
@implementation OFAMediaDecoder

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

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
    _totalVideoFramecount = 0;
}

- (void)protocolParser {
    
}

- (void)formatDemuxer {
    
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
    
    //---------
    //解码音频和视频
    if (![self openVideoStream] || [self openAudioStream]) {
        // 视频和音频任何一方解封装失败则关闭文件返回
        [self closeFile];
    }
    
    NSInteger videoWidth = [self frameWidth];
    NSInteger videoHeight = [self frameHeight];
    //TODO：重试逻辑
    
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

- (NSArray *)decodeFrame:(NSTimeInterval)duration {
    if (self.videoStreamIndex == -1 && self.audioStreamIndex == -1) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    AVPacket packet;
    CGFloat decodedDuration = 0;
    BOOL finished = NO;
    while (!finished) {
        if (av_read_frame(_formatCtx, &packet) < 0) {
            self.isEOF = YES;
            break;
        }
        int pktSize = packet.size;
        int pktStreamIndex = packet.stream_index;
        if (pktStreamIndex == self.videoStreamIndex) {
            OFAVideoFrame *frame = [self decodeVideo:packet packetSize:pktSize];
            if(frame){
                self.totalVideoFramecount++;
                [result addObject:frame];
                decodedDuration += frame.duration;
                if (decodedDuration > duration)
                    finished = YES;
            }
        } else if (pktStreamIndex == self.audioStreamIndex) {
            while (pktSize > 0) {
                int gotframe = 0;
                int len = avcodec_decode_audio4(self.audioCodecCtx, self.audioFrame,
                                                &gotframe,
                                                &packet);
                
                if (len < 0) {
                    NSString *errString = @"decode video error, skip packet";
                    NSLog(@"%@",errString);
                    break;
                }
                if (gotframe) {
                    OFAAudioFrame * frame = [self handleAudioFrame];
                    if (frame) {
                        [result addObject:frame];
                        if (self.videoStreamIndex == -1) {
                            self.decodePosition = frame.position;
                            decodedDuration += frame.duration;
                            if (decodedDuration > duration)
                                finished = YES;
                        }
                    }
                }
                if (0 == len)
                    break;
                pktSize -= len;
            }
        } else {
            NSLog(@"We Can Not Process Stream Except Audio And Video Stream...");
        }
        av_free_packet(&packet);
    }
    _readLastestFrameTime = [[NSDate date] timeIntervalSince1970];
    return result;
}

- (OFAVideoFrame*) decodeVideo:(AVPacket) packet packetSize:(int) pktSize
{
    OFAVideoFrame *frame = nil;
    while (pktSize > 0) {
        int gotframe = 0;
        int len = avcodec_decode_video2(_videoCodecCtx, _videoFrame,
                                        &gotframe,
                                        &packet);
        if (len < 0) {
            NSString *errString = [NSString stringWithFormat:@"decode video error, skip packet %s", av_err2str(len)];
            NSLog(@"%@",errString);
            break;
        }
        if (gotframe) {
            frame = [self handleVideoFrame];
        }
        if (0 == len)
            break;
        pktSize -= len;
    }
    return frame;
}

- (OFAVideoFrame *)handleVideoFrame {
    if (!self.videoFrame->data[0]) {
        return nil;
    }
    OFAVideoFrame *frame = [[OFAVideoFrame alloc] init];
    if(self.videoCodecCtx->pix_fmt == AV_PIX_FMT_YUV420P || self.videoCodecCtx->pix_fmt == AV_PIX_FMT_YUVJ420P){
        frame.luma = copyFrameData(self.videoFrame->data[0],
                                   self.videoFrame->linesize[0],
                                   self.videoCodecCtx->width,
                                   self.videoCodecCtx->height);
        
        frame.chromaB = copyFrameData(self.videoFrame->data[1],
                                      self.videoFrame->linesize[1],
                                      self.videoCodecCtx->width / 2,
                                      self.videoCodecCtx->height / 2);
        
        frame.chromaR = copyFrameData(self.videoFrame->data[2],
                                      self.videoFrame->linesize[2],
                                      self.videoCodecCtx->width / 2,
                                      self.videoCodecCtx->height / 2);
    } else {
        if (!self.swsContext &&
            ![self setupScaler]) {
            NSString *errString = @"fail setup video scaler";
            [self dealThingsWhenErrorOccurs:errString code:OFAScalerCreateError];
            return nil;
        }
        sws_scale(_swsContext,
                  (const uint8_t **)_videoFrame->data,
                  _videoFrame->linesize,
                  0,
                  _videoCodecCtx->height,
                  _picture.data,
                  _picture.linesize);
        frame.luma = copyFrameData(_picture.data[0],
                                   _picture.linesize[0],
                                   _videoCodecCtx->width,
                                   _videoCodecCtx->height);
        
        frame.chromaB = copyFrameData(_picture.data[1],
                                      _picture.linesize[1],
                                      _videoCodecCtx->width / 2,
                                      _videoCodecCtx->height / 2);
        
        frame.chromaR = copyFrameData(_picture.data[2],
                                      _picture.linesize[2],
                                      _videoCodecCtx->width / 2,
                                      _videoCodecCtx->height / 2);
    }
    frame.width = _videoCodecCtx->width;
    frame.height = _videoCodecCtx->height;
    frame.linesize = _videoFrame->linesize[0];
    frame.type = OFAVideoFrameType;
//    frame.position = av_frame_get_best_effort_timestamp(self.videoFrame) * _videoTimeBase;
    const int64_t frameDuration = av_frame_get_pkt_duration(self.videoFrame);
    if (frameDuration) {
    //TODO:完善
//        frame.duration = frameDuration * _videoTimeBase;
//        frame.duration += _videoFrame->repeat_pict * _videoTimeBase * 0.5;
    } else {
//        frame.duration = 1.0 / _fps;
    }
    
    return frame;
}

- (OFAAudioFrame *) handleAudioFrame
{
    if (!self.audioFrame->data[0])
        return nil;
    
    const NSUInteger numChannels = self.audioCodecCtx->channels;
    NSInteger numFrames;
    
    void * audioData;
    
    if (self.swrContext) {
        const NSUInteger ratio = 2;
        const int bufSize =  av_samples_get_buffer_size(NULL, (int)numChannels, (int)(self.audioFrame->nb_samples * ratio), AV_SAMPLE_FMT_S16, 1);
        if (!self.swrBuffer || self.swrBufferSize < bufSize) {
            self.swrBufferSize = bufSize;
            self.swrBuffer = realloc(self.swrBuffer, self.swrBufferSize);
        }
        Byte *outbuf[2] = { self.swrBuffer, 0 };
        numFrames = swr_convert(self.swrContext,
                                outbuf,
                                (int)(self.audioFrame->nb_samples * ratio),
                                (const uint8_t **)self.audioFrame->data,
                                self.audioFrame->nb_samples);
        if (numFrames < 0) {
            NSLog(@"fail resample audio");
            return nil;
        }
        audioData = self.swrBuffer;
    } else {
        if (self.audioCodecCtx->sample_fmt != AV_SAMPLE_FMT_S16) {
            NSLog(@"Audio format is invalid");
            return nil;
        }
        audioData = self.audioFrame->data[0];
        numFrames = self.audioFrame->nb_samples;
    }
    const NSUInteger numElements = numFrames * numChannels;
    NSMutableData *pcmData = [NSMutableData dataWithLength:numElements * sizeof(SInt16)];
    memcpy(pcmData.mutableBytes, audioData, numElements * sizeof(SInt16));
    OFAAudioFrame *frame = [[OFAAudioFrame alloc] init];
    //TODO:添加上去
//    frame.position = av_frame_get_best_effort_timestamp(_audioFrame) * _audioTimeBase;
//    frame.duration = av_frame_get_pkt_duration(_audioFrame) * _audioTimeBase;
    frame.samples = pcmData;
    frame.type = OFAAudioFrameType;
    return frame;
}
- (BOOL)setupScaler
{
    [self closeScaler];
    self.pictureValid = avpicture_alloc(&_picture,
                                        AV_PIX_FMT_YUV420P,
                                    self.videoCodecCtx->width,
                                    self.videoCodecCtx->height) == 0;
    if (!self.pictureValid)
        return NO;
    self.swsContext = sws_getCachedContext(self.swsContext,
                                       self.videoCodecCtx->width,
                                       self.videoCodecCtx->height,
                                       self.videoCodecCtx->pix_fmt,
                                       self.videoCodecCtx->width,
                                       self.videoCodecCtx->height,
                                           AV_PIX_FMT_YUV420P,
                                       SWS_FAST_BILINEAR,
                                       NULL, NULL, NULL);
    return self.videoCodecCtx != NULL;
}

- (void)closeFile
{
    [self interrupt];
    
    [self closeAudioStream];
    [self closeVideoStream];
    
    self.videoStreamIndexs = nil;
    self.audioStreamIndexs = nil;
    
    if (_formatCtx) {
        _formatCtx->interrupt_callback.opaque = NULL;
        _formatCtx->interrupt_callback.callback = NULL;
        avformat_close_input(&_formatCtx);
        _formatCtx = NULL;
    }
}

- (void) closeAudioStream
{
    self.audioStreamIndex = -1;
    
    if (_swrBuffer) {
        free(_swrBuffer);
        _swrBuffer = NULL;
        self.swrBufferSize = 0;
    }
    
    if (_swrContext) {
        swr_free(&_swrContext);
        _swrContext = NULL;
    }
    
    if (_audioFrame) {
        av_free(_audioFrame);
        _audioFrame = NULL;
    }
    
    if (_audioCodecCtx) {
        avcodec_close(_audioCodecCtx);
        _audioCodecCtx = NULL;
    }
}

- (void) closeVideoStream
{
    _videoStreamIndex = -1;
    
    [self closeScaler];
    
    if (_videoFrame) {
        av_free(_videoFrame);
        _videoFrame = NULL;
    }
    
    if (_videoCodecCtx) {
        avcodec_close(_videoCodecCtx);
        _videoCodecCtx = NULL;
    }
}

- (void) closeScaler
{
    if (_swsContext) {
        sws_freeContext(_swsContext);
        _swsContext = NULL;
    }

    if (_pictureValid) {
        avpicture_free(&_picture);
        _pictureValid = NO;
    }
}

- (BOOL)isEOF {
    return _isEOF;
}


- (NSUInteger) frameWidth
{
    return _videoCodecCtx ? _videoCodecCtx->width : 0;
}

- (NSUInteger) frameHeight
{
    return _videoCodecCtx ? _videoCodecCtx->height : 0;
}

#pragma mark Error

- (void)dealThingsWhenErrorOccurs:(NSString*)errString code:(NSInteger)errCode {
    NSLog(@"%@",errString);
    NSError *error = [NSError errorWithString:errString code:errCode];
    self.errorBlock(error);
}
@end
