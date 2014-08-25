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
@property (nonatomic, assign) UIInterfaceOrientation orientation;

@end

@implementation GMOverlayWindow

+ (GMOverlayWindow *)defaultWindow {
    static GMOverlayWindow *backgroundWindow = nil;
    if (backgroundWindow == nil) {
        CGRect bound = [UIScreen mainScreen].bounds;
        backgroundWindow = [[self alloc] initWithFrame:bound];
    }
    return backgroundWindow;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar - 1;
        self.hidden = YES;
        self.backgroundColor = [UIColor clearColor];
        
        self.orientation = [UIApplication sharedApplication].statusBarOrientation;
        [self updateFrameForOrientation:self.orientation];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationDidChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];

    }
    return self;
}

- (CGAffineTransform) rotateTransformForOrientation:(UIInterfaceOrientation) orientation {
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation(M_PI*1.5);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI/2);
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGAffineTransformMakeRotation(-M_PI);
    } else {
        return CGAffineTransformIdentity;
    }
}

- (NSTimeInterval) rotateDurationForOrientation:(UIInterfaceOrientation) orientation {
    if (orientation != self.orientation ) {
        NSTimeInterval statusBarOrientationAnimationDuration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        
        if ((UIInterfaceOrientationIsLandscape(orientation) && UIInterfaceOrientationIsLandscape(self.orientation))
            || (UIInterfaceOrientationIsPortrait(orientation) && UIInterfaceOrientationIsPortrait(self.orientation))) {
            return statusBarOrientationAnimationDuration * 2;
        } else {
            return statusBarOrientationAnimationDuration;
        }
    }
    return 0;
}

- (void)updateFrameForOrientation:(UIInterfaceOrientation)orientation {
//    self.transform = CGAffineTransformIdentity;
//    self.transform = [self rotateTransformForOrientation:orientation];
//    self.bounds = CGRectApplyAffineTransform(self.bounds, self.transform);
}

- (void)statusBarOrientationDidChange:(NSNotification *)notification {
    if (!self.hidden) {
        UIInterfaceOrientation orientation = [[notification.userInfo objectForKey:UIApplicationStatusBarOrientationUserInfoKey] intValue];
        if (orientation != self.orientation) {
            NSTimeInterval statusBarOrientationAnimationDuration  = [self rotateDurationForOrientation:orientation];
            [UIView animateWithDuration:statusBarOrientationAnimationDuration delay:0 options:UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self updateFrameForOrientation:orientation];
            } completion:nil];
            self.orientation = orientation;
        }
    }
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
    self.previousKeyWindow = nil;
    [super dealloc];
}

@end
