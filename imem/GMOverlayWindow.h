//
//  TKOverlayWindow.h
//  ActionSheetAndAlert
//
//  Created by luobin on 13-3-16.
//  Copyright (c) 2013年 luobin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GMOverlayWindow : UIWindow {
}

+ (GMOverlayWindow *)defaultWindow;

+ (void)cleanUp;

@end
