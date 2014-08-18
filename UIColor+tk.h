//
//  UIColor+extention.h
//  GameMaster
//
//  Created by Thilong on 13-11-27.
//  Copyright (c) 2013年 tyc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (extention)

/**
 *  create UIColor with int RGB value.
 *
 *  @param red   red
 *  @param green green
 *  @param blue  blue
 *  @param alpha alpha
 *
 *  @return UIColor instance.
 */
+ (UIColor *)colorWithiRed:(int)red igreen:(int)green iblue:(int)blue alpha:(CGFloat)alpha;

/**
 *  UIColor with hex value string
 *
 *  @param hexColorString hex value string of color. eg: 0xff7229
 *
 *  @return UIColor instance.
 */
+ (UIColor *)colorWithHexString:(NSString *)hexColorString;

@end
