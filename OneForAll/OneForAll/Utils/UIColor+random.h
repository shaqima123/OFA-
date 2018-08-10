//
//  UIColor+random.h
//  SybPlatform
//
//  Created by kuncai on 15-2-10.
//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (random)

+(UIColor *)randomColor;

+ (UIColor *)colorFromHexString:(NSString *)hexString /** like '#ffffff' **/;

@end
