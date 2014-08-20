//
//  UITAssistiveTouch.m
//
//
//  Created by Thilong on 13-12-12.
//  Copyright (c) 2013年 TYC. All rights reserved.
//

#import "UITAssistiveTouch.h"
#import "UIView+Sizes.h"

static NSInteger kAssistiveTouchWidth = 44;

typedef enum _RectZone {
	kRectZoneNone = 0,
	kRectZoneTopLeft,
	kRectZoneTopRight,
	kRectZoneButtomLeft,
	kRectZoneButtomRight
} RectZone;

/**
 *  UITAssistiveTouchButton
 */
@interface UITAssistiveTouchButton : UIButton
{
	CGPoint _beginPoint;
	CGPoint _selfBeginCenter;
    
	RectZone _direction;
    
	BOOL _animating;
	BOOL _moving;
}

@property (nonatomic, assign) BOOL moving;

- (void)flexCenterWhenDidChangeStatusBarOrientation;

- (void)setAssistiveTouchHiden:(BOOL)hide;

@end

/**
 *  DJAssistiveTouch
 */

@interface UITAssistiveTouch ()
{
	UITAssistiveTouchButton *_assistiveButton;
}

@property (nonatomic, assign) BOOL isVisible;

@end

/**
 *  implement DJAssistiveTouch
 */

@implementation UITAssistiveTouch

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_assistiveButton removeFromSuperview];
	[_assistiveButton release];
    
	Block_release(_touchHandle);
    
	[super dealloc];
}

- (id)init {
	self = [super init];
	if (self) {
		CGRect frame = [UIScreen mainScreen].bounds;
		frame.origin.y = (frame.size.height - kAssistiveTouchWidth) / 2;
		frame.size.width = kAssistiveTouchWidth;
		frame.size.height = kAssistiveTouchWidth;
        
        self.isVisible = NO;
        
		_assistiveButton = [[UITAssistiveTouchButton alloc] initWithFrame:frame];
        [_assistiveButton setBackgroundColor:[UIColor blackColor]];
		[_assistiveButton setAssistiveTouchHiden:NO];
        _assistiveButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleLeftMargin
        | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleRightMargin;
        
		[_assistiveButton addTarget:self
		                     action:@selector(onUITAssistiveTouchButton:)
		           forControlEvents:UIControlEventTouchUpInside];
	}
	return self;
}

- (instancetype)initWithIcon:(UIImage *)icon highLightIcon:(UIImage *)highLightIcon;
{
	self = [super init];
    
	if (self) {
		CGRect frame = [UIScreen mainScreen].bounds;
		frame.origin.y = (frame.size.height - kAssistiveTouchWidth) / 2;
		frame.size.width = kAssistiveTouchWidth;
		frame.size.height = kAssistiveTouchWidth;
        
		_assistiveButton = [[UITAssistiveTouchButton alloc] initWithFrame:frame];
		if (icon)
			[_assistiveButton setImage:icon forState:UIControlStateNormal];
		if (highLightIcon)
			[_assistiveButton setImage:highLightIcon forState:UIControlStateHighlighted];
        
		[_assistiveButton setAssistiveTouchHiden:NO];
        _assistiveButton.backgroundColor = [UIColor redColor];
		[_assistiveButton addTarget:self
		                     action:@selector(onUITAssistiveTouchButton:)
		           forControlEvents:UIControlEventTouchUpInside];
	}
    
	return self;
}

- (void)showInView:(UIView *)view {
    if (self.isVisible) {
        return;
    }
    self.isVisible = YES;
    [self retain];
	if (!view) {
        view = [UIApplication sharedApplication].keyWindow;
	}
    [view addSubview:_assistiveButton];
    
	[_assistiveButton setAssistiveTouchHiden:NO];
    
	if (view) {
		[view bringSubviewToFront:_assistiveButton];
	}
}

- (void)dismiss {
    if (!self.isVisible) {
        return;
    }
    self.isVisible = NO;
	[_assistiveButton setAssistiveTouchHiden:YES];
    [_assistiveButton removeFromSuperview];
    [self autorelease];
}

#pragma mark - orientation

- (void)applicationWillChangeStatusBarOrientation {
    
}

/**
 *  rotation DJAssistiveTouchButton when app status bar oriention did changed.
 */
- (void)applicationDidChangeStatusBarOrientation {
	CGFloat radians = .0f;
    
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		radians = orientation == UIInterfaceOrientationLandscapeLeft ? -M_PI_2 : M_PI_2;
	}
	else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		radians = M_PI;
	}
    
	[_assistiveButton.superview bringSubviewToFront:_assistiveButton];
    
	CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(radians);
    
	[UIView beginAnimations:nil context:nil];
    
	[_assistiveButton setTransform:rotationTransform];
    
	[_assistiveButton flexCenterWhenDidChangeStatusBarOrientation];
    
	[UIView commitAnimations];
}

- (void)onUITAssistiveTouchButton:(id)sender {
	if (!_assistiveButton.moving && self.touchHandle) {
		self.touchHandle(self);
	}
}

@end


#pragma  mark - UITAssistiveTouchButton


@implementation UITAssistiveTouchButton
{
	BOOL _didShown;
    
	NSTimer *_showTimer;
}

@synthesize moving = _moving;

- (void)dealloc {
	[self clearTimer];
    
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
    
	if (self) {
		self.center = [self underStatusBarPoint:self.center];
        
		_didShown = NO;
	}
    
	return self;
}

- (void)flexCenterWhenDidChangeStatusBarOrientation {
	self.center = [self underStatusBarPoint:self.center];
}

- (void)setAssistiveTouchHiden:(BOOL)hide {
	[super setHidden:hide];
    
	if (!hide && !_didShown) {
		_didShown = YES;
        
		[self scheduledTimer];
	}
}

- (void)scheduledTimer {
	[self clearTimer];
    
	_showTimer = [[NSTimer scheduledTimerWithTimeInterval:3.0f
	                                               target:self
	                                             selector:@selector(showAlpha)
	                                             userInfo:nil
	                                              repeats:NO] retain];
}

- (void)clearTimer {
	if (_showTimer) {
		[_showTimer invalidate];
		[_showTimer release];
		_showTimer = nil;
	}
}

- (void)showAlpha {
	self.alpha = .5f;
}

- (void)hideAlpha {
	[self clearTimer];
    
	self.alpha = 1.0f;
}

#pragma mark - touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
    
	[self hideAlpha];
    
	if (_animating) {
		return;
	}
    
	UITouch *touch = [touches anyObject];
	_beginPoint = [touch locationInView:self.window];
	_selfBeginCenter = self.center;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesMoved:touches withEvent:event];
    
	if (_animating) {
		return;
	}
    
	_moving = YES;
    
	UITapGestureRecognizer *ges = [self.gestureRecognizers lastObject];
	ges.enabled = NO;
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.window];
	self.center = CGPointMake(_selfBeginCenter.x + (point.x - _beginPoint.x),
	                          _selfBeginCenter.y + (point.y - _beginPoint.y));
    
	UITouch *previousTouch = [touches anyObject];
	CGPoint previousPoint = [previousTouch previousLocationInView:self.window];
    
	_direction = kRectZoneNone;
    
	NSInteger velocity = [self velocityByPoint:point andPoint:previousPoint];
	NSInteger maxVelocity = UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad ? 15 : 45;
    
	if (ABS(velocity) > maxVelocity) {
		int velocityX = point.x - previousPoint.x;
		int velocityY = point.y - previousPoint.y;
        
		if (abs(velocityY) > abs(velocityX)) {
			if (velocityY > 0) {
				_direction = velocityX > 0 ? kRectZoneButtomRight : kRectZoneButtomLeft;
			}
			else {
				_direction = velocityX > 0 ? kRectZoneTopRight : kRectZoneTopLeft;
			}
		}
		else {
			if (velocityX > 0) {
				_direction = velocityY > 0 ? kRectZoneButtomRight : kRectZoneTopRight;
			}
			else {
				_direction = velocityY > 0 ? kRectZoneButtomLeft : kRectZoneTopLeft;
			}
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
    
	[self scheduledTimer];
    
	if (_moving) {
		_moving = NO;
        
		UITapGestureRecognizer *ges = [self.gestureRecognizers lastObject];
		ges.enabled = YES;
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView:self.window];

		[UIView animateWithDuration:0.3
		                 animations: ^{
                             self.center = point;
                         }];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
    
	[self scheduledTimer];
    
	if (_moving) {
		_moving = NO;
        
		UITapGestureRecognizer *ges = [self.gestureRecognizers lastObject];
		ges.enabled = YES;
        
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView:self.window];
        
		self.center = CGPointMake(self.center.x + (point.x - _beginPoint.x),
		                          self.center.y + (point.y - _beginPoint.y));
	}
}

#pragma mark- tool

- (CGPoint)underStatusBarPoint:(CGPoint)point {
	if ([UIApplication sharedApplication].statusBarHidden) return point;
    
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationPortrait:
		{
			if (point.y == kAssistiveTouchWidth / 2) {
				point.y += 20;
			}
		}
            break;
            
		case UIInterfaceOrientationLandscapeLeft:
		{
			if (point.x == kAssistiveTouchWidth / 2) {
				point.x += 20;
			}
		}
            break;
            
		case UIInterfaceOrientationPortraitUpsideDown:
		{
			if (point.y == self.window.height - kAssistiveTouchWidth / 2) {
				point.y -= 20;
			}
		}
            break;
            
		case UIInterfaceOrientationLandscapeRight:
		{
			if (point.x == self.window.width - kAssistiveTouchWidth / 2) {
				point.x -= 20;
			}
		}
            break;
            
		default:
			break;
	}
    
	if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
		if (point.x == 20 + kAssistiveTouchWidth / 2) {
			point.x = kAssistiveTouchWidth / 2;
		}
		else if (point.x == self.window.width - kAssistiveTouchWidth / 2 - 20) {
			point.x = self.window.width - kAssistiveTouchWidth / 2;
		}
	}
	else {
		if (point.y == 20 + kAssistiveTouchWidth / 2) {
			point.y = kAssistiveTouchWidth / 2;
		}
		else if (point.y == self.window.height - kAssistiveTouchWidth / 2 - 20) {
			point.y = self.window.height - kAssistiveTouchWidth / 2;
		}
	}
    
	return point;
}

/**
 *  Get point by zone in rect
 *
 *  @param point scrouce point
 *  @param zone  target zone
 *  @param rect  target rect
 *
 *  @return target point
 */

- (CGPoint)point:(CGPoint)point nearZone:(RectZone)zone inRect:(CGRect)rect {
	if (zone == kRectZoneNone) {
		zone = [self point:point zoneFromRect:rect];
	}
    
	switch (zone) {
		case kRectZoneTopLeft:
		{
			if (point.x <= point.y) {
				point.x = kAssistiveTouchWidth / 2;
			}
			else {
				point.y = kAssistiveTouchWidth / 2;
			}
		}
            break;
            
		case kRectZoneTopRight:
		{
			if (rect.size.width - point.x <= point.y) {
				point.x = rect.size.width -  kAssistiveTouchWidth / 2;
			}
			else {
				point.y = kAssistiveTouchWidth / 2;
			}
		}
            break;
            
		case kRectZoneButtomLeft:
		{
			if (point.x <= rect.size.height - point.y) {
				point.x = kAssistiveTouchWidth / 2;
			}
			else {
				point.y = rect.size.height - kAssistiveTouchWidth / 2;
			}
		}
            break;
            
		case kRectZoneButtomRight:
		{
			if (rect.size.width - point.x <= rect.size.height - point.y) {
				point.x = rect.size.width - kAssistiveTouchWidth / 2;
			}
			else {
				point.y = rect.size.height - kAssistiveTouchWidth / 2;
			}
		}
            break;
            
		default:
			break;
	}
    
	return [self underStatusBarPoint:point];
}

- (RectZone)point:(CGPoint)point zoneFromRect:(CGRect)rect {
	RectZone zone = kRectZoneNone;
    
	if (point.x >= rect.size.width / 2) {
		zone = point.y >= rect.size.height / 2 ? kRectZoneButtomRight : kRectZoneTopRight;
	}
	else {
		zone = point.y >= rect.size.height / 2 ? kRectZoneButtomLeft : kRectZoneTopLeft;
	}
    
	return zone;
}

- (NSInteger)velocityByPoint:(CGPoint)point1 andPoint:(CGPoint)point2 {
	int velocityX = point1.x - point2.x;
	int velocityY = point1.y - point2.y;
    
	return abs(velocityX) > abs(velocityY) ? velocityX : velocityY;
}

#pragma mark - keep life cycle

- (void)removeFromSuperview {
}

- (void)setHidden:(BOOL)hidden {
	[super setHidden:NO];
}

- (oneway void)release {
	[self retain];
}

- (id)autorelease {
	return [self retain];
}

@end
