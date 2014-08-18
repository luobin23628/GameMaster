//
//  UIImage+Color.h
//
//
//  Created by thilong on 5/3/13.
//  org author : Jack Flintermann
//  Copyright (c) 2013 TYC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (TK)

+ (UIImage *)imageWithColor:(UIColor *)color
               cornerRadius:(CGFloat)cornerRadius;

+ (UIImage *)buttonImageWithColor:(UIColor *)color
                     cornerRadius:(CGFloat)cornerRadius
                      shadowColor:(UIColor *)shadowColor
                     shadowInsets:(UIEdgeInsets)shadowInsets;

+ (UIImage *)circularImageWithColor:(UIColor *)color
                               size:(CGSize)size;
+ (UIImage *)stepperPlusImageWithColor:(UIColor *)color;

+ (UIImage *)stepperMinusImageWithColor:(UIColor *)color;

+ (UIImage *)backButtonImageWithColor:(UIColor *)color
                           barMetrics:(UIBarMetrics)metrics
                         cornerRadius:(CGFloat)cornerRadius;

- (UIImage *)imageWithMinimumSize:(CGSize)size;

- (UIImage *) imageWithTintColor:(UIColor *)tintColor;

- (UIImage *) imageWithGradientTintColor:(UIColor *)tintColor;


@end
