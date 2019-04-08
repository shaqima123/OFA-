//
//  NSError+Smart.m
//  FortunePlat
//
//  Created by kuncai on 15/11/13.
//  Copyright © 2015年 Tencent. All rights reserved.
//

#import "NSError+Util.h"

@implementation NSError (Util)
+(NSError*)errorWithString:(NSString *)msg code:(NSInteger)code {
    if (!msg) {
        msg = @"";
    }
    NSError *error = [NSError errorWithDomain:@"" code:code userInfo:@{NSLocalizedDescriptionKey:msg}];
    return error;
}

+(NSError*)errorWithString:(NSString *)msg code:(NSInteger)code type:(NSInteger)type {
    if (!msg) {
        msg = @"";
    }
    NSError *error = [NSError errorWithDomain:@"" code:code userInfo:@{NSLocalizedDescriptionKey:msg, NSRecoveryAttempterErrorKey: @(type)}];
    return error;
}
+(NSError*)errorWithString:(NSString *)msg {
    return [NSError errorWithString:msg code:0];
    
    
}
@end
