//
//  SFMemoryHandler.h
//  SC2HDB
//
//  Created by Pol Eyschen on 11.04.13.
//
//

#import <Foundation/Foundation.h>

@interface SFMemoryHandler : NSObject

+ (pid_t) getPidForProcess: (NSString*)processName;
+ (addr64_t) getBaseAddressForProcessWithPid: (pid_t)pid;
+ (NSString *)readProcessMemoryTextFromPid: (pid_t)pid AtAddress: (addr64_t)addr WithSize:(mach_msg_type_number_t*)size;
@end
