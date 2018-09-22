//
//  UIColor+Helper.m
//  OneForAll
//
//  Created by Kira on 2018/9/22.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "UIColor+Helper.h"

@implementation UIColor (Helper)

+(UIColor *)DARK{
    return RGB(33,33,33);
}
+(UIColor *)DARK02{
    return RGBA(33,33,33,.2f);
}
+(UIColor *)DARK04{
    return RGBA(33,33,33,.4f);
}
+(UIColor *)DARK06{
    return RGBA(33,33,33,.6f);
}
+(UIColor *)DARK08{
    return RGBA(33,33,33,.8f);
}

+(UIColor *)GRAY{
    return RGB(132, 133, 135);
}

+(UIColor *)GRAY02{
    return RGBA(132, 133, 135, 0.2);
}

+(UIColor *)GRAY04{
    return RGBA(132, 133, 135, 0.4);
}

+(UIColor *)GRAY06{
    return RGBA(132, 133, 135, 0.6);
}

+(UIColor *)GRAY08{
    return RGBA(132, 133, 135, 0.8);
}
@end
