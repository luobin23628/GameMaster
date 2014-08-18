//
//  UIColor+extention.m
//
//
//  Created by Thilong on 13-11-27.
//  Copyright (c) 2013年 tyc. All rights reserved.
//

#import "UIColor+tk.h"

@implementation UIColor (extention)

+ (UIColor *)colorWithiRed:(int)red igreen:(int)green iblue:(int)blue alpha:(CGFloat)alpha {
	return [UIColor colorWithRed:(red / 255.0) green:(green / 255.0f) blue:(blue / 255.0f) alpha:alpha];
}

+ (UIColor *)colorWithHexString:(NSString *)hexColorString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexColorString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
