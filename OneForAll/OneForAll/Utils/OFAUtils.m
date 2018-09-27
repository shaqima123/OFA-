//
//  OFAUtils.m
//  OneForAll
//
//  Created by Kira on 2018/9/27.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFAUtils.h"

@implementation OFAUtils
+ (UIViewController *)getViewControllerFrom:(UIView *)view {
    for (UIView* next = [view superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

@end
