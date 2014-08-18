//
//  UITAssistiveTouch.h
//
//
//  Created by Thilong on 13-12-12.
//  Copyright (c) 2013年 TYC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef void (^OnAssistiveTouch)(id pAssistiveTouch);

/**
 *  Assistive touch, should always appear in screen
 */
@interface UITAssistiveTouch : NSObject

/**
 *  AssistiveTouch
 *
 *  @param icon          normal icon
 *  @param highLightIcon hight-light icon
 *
 *  @return Assistive touch instance.
 */
- (instancetype)initWithIcon:(UIImage *)icon highLightIcon:(UIImage *)highLightIcon;

/**
 *  assistiveTouchButton
 */
@property (nonatomic, copy) OnAssistiveTouch touchHandle;

/**
 *  setAssistiveTouchHiden
 *
 *  @param hide if YES will hide assistive touch
 */
- (void)setAssistiveTouchHiden:(BOOL)hide onWindow:(UIWindow *)window;

@end
