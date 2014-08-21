//
//  TKOverlayWindow.m
//  ActionSheetAndAlert
//
//  Created by luobin on 13-3-16.
//  Copyright (c) 2013年 luobin. All rights reserved.
//

#import "GMOverlayWindow.h"

@implementation GMOverlayWindow

+ (GMOverlayWindow *)defaultWindow {
    static GMOverlayWindow *backgroundWindow = nil;
    if (backgroundWindow == nil) {
        backgroundWindow = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return backgroundWindow;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar;
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
    }
    return [super hitTest:point withEvent:event];
}

- (void)reduceAlphaIfEmpty {
    if (self.subviews.count == 1 || (self.subviews.count == 2 && [[self.subviews objectAtIndex:0] isKindOfClass:[UIImageView class]])){
        self.alpha = 0.0f;
        self.userInteractionEnabled = NO;
    }
}

- (void)removeOverlay:(UIView *)overlay {
    [overlay removeFromSuperview];
    self.hidden = YES;
}

@end
