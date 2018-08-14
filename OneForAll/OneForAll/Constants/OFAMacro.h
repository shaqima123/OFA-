//
//  OFAMacro.h
//  OneForAll
//
//  Created by Kira on 2018/8/10.
//  Copyright © 2018 Kira. All rights reserved.
//

#ifndef OFAMacro_h
#define OFAMacro_h


#endif /* OFAMacro_h */

// 屏幕大小
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

//weak - strong

#define OFAWeakObj(o) autoreleasepool{} __weak typeof(o) weak##o = o;
#define OFAStrongObj(o) autoreleasepool{} __strong typeof(o) o = weak##o;

// 浮点值比较
#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)
#define flessthan(a,b) (fabs(a) < fabs(b)+FLT_EPSILON)

// 角度转弧度
#define MT_DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) * 0.01745329252f) // PI / 180

// 弧度转角度
#define MT_RADIANS_TO_DEGREES(__ANGLE__) ((__ANGLE__) * 57.29577951f) // PI * 180

// 版本判断
#define SYSTEM_VERSION_EQUAL_TO(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)

#define SYSTEM_VERSION_GREATER_THAN(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define SYSTEM_VERSION_LESS_THAN(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define STRINGIFY(S) #S
#define DEFER_STRINGIFY(S) STRINGIFY(S)
#define PRAGMA_MESSAGE(MSG) _Pragma(STRINGIFY(message(MSG)))
#define FORMATTED_MESSAGE(MSG) "[TODO-" DEFER_STRINGIFY(__COUNTER__) "] " MSG " \n" \
DEFER_STRINGIFY(__FILE__) " line " DEFER_STRINGIFY(__LINE__)
#define KEYWORDIFY try {} @catch (...) {}
// 添加备忘 TODO 宏
#define TODO(MSG) KEYWORDIFY PRAGMA_MESSAGE(FORMATTED_MESSAGE(MSG))

/**
 *  是否是X.X寸屏幕
 */
#define IS_3_5_INCH                 (CGRectGetHeight([UIScreen mainScreen].bounds) == 480)
#define IS_4_INCH                   (CGRectGetHeight([UIScreen mainScreen].bounds) == 568)
#define IS_4_7_INCH                 (CGRectGetHeight([UIScreen mainScreen].bounds) == 667)
#define IS_5_5_INCH                 (CGRectGetHeight([UIScreen mainScreen].bounds) == 736)
#define IS_5_8_INCH                 (CGRectGetHeight([UIScreen mainScreen].bounds) == 812)
#define IS_IPHONE_X                 (CGRectGetHeight([UIScreen mainScreen].bounds) == 812)

#define Height_Top_Addtion ((IS_IPHONE_X == YES) ? 44.0f : 0)
#define Height_Bottom_Addtion ((IS_IPHONE_X == YES) ? 34.0f : 0)

//手机系统版本
#define phoneVersion [[UIDevice currentDevice] systemVersion]
#define kNaviBarHeightAndStatusBarHeight (kNaviBarHeight+[[UIApplication sharedApplication] statusBarFrame].size.height)
#define StatusBarHeight ([[UIApplication sharedApplication] statusBarFrame].size.height)
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define RGB(r,g,b) RGBA(r,g,b,1.0f)
#define COLOR_WITH_HEX(hexValue) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16)) / 255.0 green:((float)((hexValue & 0xFF00) >> 8)) / 255.0 blue:((float)(hexValue & 0xFF)) / 255.0 alpha:1.0f]
#define RGBAHEX(hex,a)    RGBA((float)((hex & 0xFF0000) >> 16),(float)((hex & 0xFF00) >> 8),(float)(hex & 0xFF),a)


/*** Definitions of inline functions. ***/

CG_INLINE CGRect CGRectChangeSize(CGRect rect, CGSize size)
{ return CGRectMake(rect.origin.x, rect.origin.y, size.width, size.height); }

CG_INLINE CGRect CGRectChangeWidth(CGRect rect, CGFloat width)
{ return CGRectMake(rect.origin.x, rect.origin.y, width, rect.size.height); }

CG_INLINE CGRect CGRectChangeHeight(CGRect rect, CGFloat height)
{ return CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height); }

CG_INLINE CGRect CGRectChangeOrigin(CGRect rect, CGPoint origin)
{ return CGRectMake(origin.x, origin.y, rect.size.width, rect.size.height); }

CG_INLINE CGRect CGRectChangeY(CGRect rect, CGFloat y)
{ return CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height); }

CG_INLINE CGRect CGRectChangeX(CGRect rect, CGFloat x)
{ return CGRectMake(x, rect.origin.y, rect.size.width, rect.size.height); }

CG_INLINE CGRect CGRectMakeFromOriginAndSize(CGPoint origin, CGSize size)
{ return CGRectMake(origin.x, origin.y, size.width, size.height); }

CG_INLINE CGSize CGSizeAspectFit(CGSize parentSize, CGSize childSize)
{
    return (parentSize.width / parentSize.height > childSize.width / childSize.height) ?
    CGSizeMake(childSize.width * parentSize.height / childSize.height, parentSize.height) :
    CGSizeMake(parentSize.width, childSize.height * parentSize.width / childSize.width);
}

CG_INLINE CGSize CGSizeAspectFill(CGSize parentSize, CGSize childSize)
{
    return (parentSize.width / parentSize.height > childSize.width / childSize.height) ?
    CGSizeMake(parentSize.width, childSize.height * parentSize.width / childSize.width) :
    CGSizeMake(childSize.width * parentSize.height / childSize.height, parentSize.height);
}

CG_INLINE CGRect CGRectAspectFit(CGRect parentRect, CGSize childSize)
{
    CGSize resultSize = CGSizeAspectFit(parentRect.size, childSize);
    CGPoint resultOrigin = CGPointMake(parentRect.origin.x + (parentRect.size.width - resultSize.width) / 2.0,
                                       parentRect.origin.y + (parentRect.size.height - resultSize.height) / 2.0);
    return CGRectMakeFromOriginAndSize(resultOrigin, resultSize);
}

CG_INLINE CGRect CGRectAspectFill(CGRect parentRect, CGSize childSize)
{
    CGSize resultSize = CGSizeAspectFill(parentRect.size, childSize);
    CGPoint resultOrigin = CGPointMake(parentRect.origin.x + (parentRect.size.width - resultSize.width) / 2.0,
                                       parentRect.origin.y + (parentRect.size.height - resultSize.height) / 2.0);
    return CGRectMakeFromOriginAndSize(resultOrigin, resultSize);
}

CG_INLINE CGSize CGSizeChangeHeigth(CGSize size, CGFloat height)
{ return CGSizeMake(size.width, height); }

CG_INLINE CGSize CGSizeChangeWidth(CGSize size, CGFloat width)
{ return CGSizeMake(width, size.height); }
