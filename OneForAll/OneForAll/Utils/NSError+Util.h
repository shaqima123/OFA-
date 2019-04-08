//
//  NSError+Smart.h
//  FortunePlat
//
//  Created by kuncai on 15/11/13.
//  Copyright © 2015年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Util)
+(NSError*)errorWithString:(NSString *)msg;
+(NSError*)errorWithString:(NSString *)msg code:(NSInteger)code;
+(NSError*)errorWithString:(NSString *)msg code:(NSInteger)code type:(NSInteger)type;
@end
