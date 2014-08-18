//
//  TKOverlayWindow.m
//  ActionSheetAndAlert
//
//  Created by luobin on 13-3-16.
//  Copyright (c) 2013年 luobin. All rights reserved.
//

#import "GMOverlayWindow.h"

@implementation GMOverlayWindow

+(GMOverlayWindow *)defaultWindow {
    static GMOverlayWindow *backgroundWindow = nil;
    if (backgroundWindow == nil) {
        backgroundWindow = [[self alloc] init];
    }
    return backgroundWindow;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
//        self.windowLevel = NSIntegerMax;
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)addOverlayToMainWindow:(UIView *)overlay {
    if (self.hidden)
    {
//        _previousKeyWindow = [[[UIApplication sharedApplication] keyWindow] retain];
//        self.alpha = 0.0f;
        self.hidden = NO;
        self.userInteractionEnabled = YES;
//        [self makeKeyWindow];
    }
    
    if (self.subviews.count > 0)
    {
        ((UIView*)[self.subviews lastObject]).userInteractionEnabled = NO;
    }
    [self addSubview:overlay];
}

- (void)reduceAlphaIfEmpty {
    if (self.subviews.count == 1 || (self.subviews.count == 2 && [[self.subviews objectAtIndex:0] isKindOfClass:[UIImageView class]]))
    {
        self.alpha = 0.0f;
        self.userInteractionEnabled = NO;
    }
}

- (void)removeOverlay:(UIView *)overlay {
    [overlay removeFromSuperview];

    UIView *topView = [self.subviews lastObject];
    if ([topView isKindOfClass:[UIImageView class]])
    {
        // It's a background. Remove it too
        [topView removeFromSuperview];
    }
    
    if (self.subviews.count == 0)
    {
        self.hidden = YES;
        [_previousKeyWindow makeKeyWindow];
        [_previousKeyWindow release];
        _previousKeyWindow = nil;
    }
    else
    {
        ((UIView*)[self.subviews lastObject]).userInteractionEnabled = YES;
    }
}

@end
