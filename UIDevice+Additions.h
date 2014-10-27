//
//  UIDevice+_Additions.h
//  imem
//
//  Created by luobin on 14-10-27.
//
//

#import <UIKit/UIKit.h>

@interface UIDevice (Additions)

@property(nonatomic, readonly) NSInteger majorVersion;
@property(nonatomic, readonly, getter=isIOS7) BOOL iOS7;

@end
