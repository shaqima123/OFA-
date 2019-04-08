//
//  OFAConstants.h
//  OneForAll
//
//  Created by Kira on 2018/9/22.
//  Copyright © 2018 Kira. All rights reserved.
//

#ifndef OFAConstants_h
#define OFAConstants_h


#endif /* OFAConstants_h */

static NSString * kOFAHomeCell = @"OFAHomeCell";

static NSString * kOFACameraChooseCell = @"OFACameraChooseCell";



#pragma mark ErrorCode
//[-8000,-9000)范围内为 media 编解码失败 code
static const int OFADecoderOpenInputError = -8000;//打开文件失败
static const int OFADecoderFindStreamError = -8001;//寻找音频或者视频流失败
static const int OFADecoderFindDecoderError = -8002;//寻找解码器失败
static const int OFADecoderOpenCodecError = -8003;//打开codec失败

static const int OFAFrameCreateError = -8004;//创建avframe失败
static const int OFADecodeReSampleError = -8005;//重采样错误
static const int OFAScalerCreateError = -8006;//Scaler 创建错误
