//
//  OFAHomeCell.m
//  OneForAll
//
//  Created by Kira on 2018/8/10.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFAHomeCell.h"

@implementation OFAHomeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.layer setCornerRadius:10.f];
    [self.layer masksToBounds];
    [self.funcName setTextAlignment:NSTextAlignmentRight];
    [self.funcName setTextColor:[UIColor whiteColor]];
    [self.funcName setFont:[UIFont boldSystemFontOfSize:35.f]];
    [self.iconImage setContentMode:UIViewContentModeScaleAspectFit];
}

@end
