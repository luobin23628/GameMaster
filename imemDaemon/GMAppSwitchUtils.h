//
//  GMLockManager.h
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import <Foundation/Foundation.h>

@interface GMAppSwitchUtils : NSObject

+ (void)addAppIdentifier:(NSString *)identifier;

+ (void)removeAppIdentifier:(NSString *)identifier;

+ (NSArray *)getAppIdentifiers;

@end
