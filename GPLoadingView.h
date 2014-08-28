//
//  GPLoadingView.h
//  GPLoadingView
//
//  Created by crazypoo on 14/7/29.
//  Copyright (c) 2014年  广州文思海辉亚信外派iOS开发小组. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPLoadingView : UIButton

@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, readonly) BOOL isAnimating;

- (id)initWithFrame:(CGRect)frame;
- (void)startAnimation;
- (void)stopAnimation;
@end
