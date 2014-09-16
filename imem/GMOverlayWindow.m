//
//  TKOverlayWindow.m
//  ActionSheetAndAlert
//
//  Created by luobin on 13-3-16.
//  Copyright (c) 2013年 luobin. All rights reserved.
//

#import "GMOverlayWindow.h"

@interface GMOverlayWindow()

@property (nonatomic, retain) UIWindow *previousKeyWindow;

@end

static GMOverlayWindow *backgroundWindow = nil;

@implementation GMOverlayWindow

+ (GMOverlayWindow *)defaultWindow {
    if (backgroundWindow == nil) {
        CGRect bound = [UIScreen mainScreen].bounds;
        backgroundWindow = [[self alloc] initWithFrame:bound];
    }
    return backgroundWindow;
}

+ (void)cleanUp {
    if (backgroundWindow) {
        backgroundWindow.hidden = YES;
        [backgroundWindow release];
        backgroundWindow = nil;
    }
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar - 1;
        self.hidden = YES;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *rootView = [self.rootViewController view];
    if (rootView.window) {
        for (UIView *subView in rootView.subviews) {
            point = [subView convertPoint:point fromView:self];
            if ([subView pointInside:point withEvent:event]) {
                return subView;
            }
        }
    } else {
        return [super hitTest:point withEvent:event];
    }
    return nil;
}

- (void)makeKeyWindow {
    self.previousKeyWindow = [[UIApplication sharedApplication].keyWindow retain];
    [super makeKeyWindow];
}

- (void)resignKeyWindow {
    [self.previousKeyWindow makeKeyWindow];
    self.previousKeyWindow = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.previousKeyWindow = nil;
    [super dealloc];
}

@end
