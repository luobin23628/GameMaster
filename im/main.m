//
//  main.m
//  imemXpcService
//
//  Created by luobin on 14-7-10.
//  Copyright (c) 2014年 __MyCompanyName__. All rights reserved.
//

// XPC Service: Lightweight helper tool that performs work on behalf of an application.
// see http://developer.apple.com/library/mac/#documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingXPCServices.html

#include <Foundation/Foundation.h>
#import "GMMemManager.h"
#import "GMStorageManager.h"
#import "GMAppSwitchUtils.h"
/*
 static void processMessage(SInt32 messageId, mach_port_t replyPort, CFDataRef dataRef) {
 
 NSLog(@"processMessage messageId:%d", (int)messageId);
 
 NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
 switch (messageId) {
 case GMMessageIdGetPid: {
 LMSendIntegerReply(replyPort, [GMMemManager shareInstance].pid);
 break;
 }
 case GMMessageIdCheckValid: {
 int pid;
 NSData *data = (NSData *)dataRef;
 [data getBytes:&pid range:NSMakeRange(0, sizeof(pid))];
 BOOL ok = [[GMMemManager shareInstance] isValid:pid];
 LMSendIntegerReply(replyPort, ok);
 break;
 }
 case GMMessageIdSetPid: {
 int pid;
 NSData *data = (NSData *)dataRef;
 [data getBytes:&pid range:NSMakeRange(0, sizeof(pid))];
 BOOL ok = [[GMMemManager shareInstance] setPid:pid];
 LMSendIntegerReply(replyPort, ok);
 break;
 }
 case GMMessageIdSearch: {
 NSData *data = (NSData *)dataRef;
 int value; BOOL isFirst;
 [data getBytes:&value range:NSMakeRange(0, sizeof(value))];
 [data getBytes:&isFirst range:NSMakeRange(sizeof(value), sizeof(isFirst))];
 NSArray *result = [[GMMemManager shareInstance] search:value isFirst:isFirst];
 UInt64 resultCount = [GMMemManager shareInstance].resultCount;
 if (result) {
 NSMutableData *data = [NSMutableData data];
 [data appendBytes:&resultCount length:sizeof(resultCount)];
 NSData *resultData = [NSPropertyListSerialization dataFromPropertyList:result format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
 [data appendData:resultData];
 LMSendNSDataReply(replyPort, data);
 } else {
 LMSendReply(replyPort, NULL, 0);
 }
 break;
 }
 case GMMessageIdGetMemoryAccessObject: {
 uint64_t address;
 NSData *data = (NSData *)dataRef;
 [data getBytes:&address range:NSMakeRange(0, sizeof(address))];
 GMMemoryAccessObject *accessObject = [[GMMemManager shareInstance] getMemoryAccessObject:address];
 LMSendArchiverObjectReply(replyPort, accessObject);
 break;
 }
 case GMMessageIdModify: {
 GMMemoryAccessObject *accessObject = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)dataRef];
 BOOL ok = NO;
 if (accessObject) {
 ok = [[GMMemManager shareInstance] modifyMemory:accessObject];
 }
 LMSendIntegerReply(replyPort, ok);
 break;
 }
 case GMMessageIdReset: {
 BOOL ok = [[GMMemManager shareInstance] reset];
 LMSendIntegerReply(replyPort, ok);
 break;
 }
 case GMMessageIdClearSearchData: {
 BOOL ok = [[GMMemManager shareInstance] clearSearchData];
 LMSendIntegerReply(replyPort, ok);
 break;
 }
 case GMMessageIdGetLockedList: {
 NSArray *lockList = [[GMStorageManager shareInstance] getLockedObjects];
 if (lockList) {
 LMSendArchiverObjectReply(replyPort, lockList);
 } else {
 LMSendReply(replyPort, NULL, 0);
 }
 break;
 }
 case GMMessageIdGetStoredList: {
 NSArray *storedList = [[GMStorageManager shareInstance] getStoredObjects];
 if (storedList) {
 LMSendArchiverObjectReply(replyPort, storedList);
 } else {
 LMSendReply(replyPort, NULL, 0);
 }
 break;
 }
 case GMMessageIdRemoveLockedOrStoredObjects: {
 BOOL ok = NO;
 if (dataRef) {
 NSArray *accessObjects = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)dataRef];
 if (accessObjects) {
 [[GMStorageManager shareInstance] removeObjects:accessObjects];
 ok = YES;
 }
 }
 LMSendIntegerReply(replyPort, ok);
 break;
 }
 case GMMessageIdAddAppIdentifier: {
 BOOL ok = NO;
 if (dataRef) {
 NSString *appIdentifier = [[[NSString alloc ] initWithData:(NSData *)dataRef encoding:NSUTF8StringEncoding] autorelease];
 if (appIdentifier) {
 [GMAppSwitchUtils addAppIdentifier:appIdentifier];
 ok = YES;
 }
 }
 LMSendIntegerReply(replyPort, ok);
 break;
 }
 case GMMessageIdRemoveAppIdentifier: {
 BOOL ok = NO;
 if (dataRef) {
 NSString *appIdentifier = [[[NSString alloc ] initWithData:(NSData *)dataRef encoding:NSUTF8StringEncoding] autorelease];
 if (appIdentifier) {
 [GMAppSwitchUtils removeAppIdentifier:appIdentifier];
 ok = YES;
 }
 }
 LMSendIntegerReply(replyPort, ok);
 break;
 }
 case GMMessageIdGetAppIdentifiers: {
 NSArray *appIdentifiers = [GMAppSwitchUtils getAppIdentifiers];
 if (appIdentifiers) {
 LMSendPropertyListReply(replyPort, appIdentifiers);
 } else {
 LMSendReply(replyPort, NULL, 0);
 }
 break;
 }
 
 default:
 LMSendReply(replyPort, NULL, 0);
 break;
 }
 [pool release];
 }
 
 static void machPortCallback(CFMachPortRef port, void *bytes, CFIndex size, void *info) {
 LMMessage *request = bytes;
 if (size < sizeof(LMMessage)) {
 LMSendReply(request->head.msgh_remote_port, NULL, 0);
 LMResponseBufferFree(bytes);
 return;
 }
 // Send Response
 const void *data = LMMessageGetData(request);
 size_t length = LMMessageGetDataLength(request);
 mach_port_t replyPort = request->head.msgh_remote_port;
 CFDataRef cfdata = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, data ?: &data, length, kCFAllocatorNull);
 processMessage(request->head.msgh_id, replyPort, cfdata);
 if (cfdata)
 CFRelease(cfdata);
 LMResponseBufferFree(bytes);
 }
 
 int main(int argc, const char *argv[]) {
 @autoreleasepool {
 
 NSLog(@"Service start...");
 while (YES) {
 kern_return_t err = LMStartService(connection.serverName, CFRunLoopGetCurrent(), machPortCallback);
 if (err) {
 NSLog(@"Unable to register mach server with error %x", err);
 [NSThread sleepForTimeInterval:60];
 } else {
 NSLog(@"Register mach server:%s with succeed.", connection.serverName);
 [[NSRunLoop currentRunLoop] run];
 }
 }
 NSLog(@"Service end...");
 }
 return EXIT_SUCCESS;
 }
 */


/*
 For an A to Z discussion, please visit http://iosre.com/forum.php?mod=viewthread&tid=105&extra=page%3D1
 
 mach_vm functions reference: http://www.opensource.apple.com/source/xnu/xnu-1456.1.26/osfmk/vm/vm_user.c
 
 OSX: clang -framework Foundation -o HippocampHairSalon_OSX main.m
 
 iOS: clang -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk -arch armv7 -arch armv7s -arch arm64 -framework Foundation -o HippocampHairSalon_iOS main.m
 Then: ldid -Sent.xml HippocampHairSalon_iOS
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <mach/mach.h>
#include <sys/sysctl.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#include <mach/mach_vm.h>
#else // import from /usr/lib/system/libsystem_kernel.dylib
extern kern_return_t
mach_vm_read(
             vm_map_t		map,
             mach_vm_address_t	addr,
             mach_vm_size_t		size,
             pointer_t		*data,
             mach_msg_type_number_t	*data_size);

extern kern_return_t
mach_vm_write(
              vm_map_t			map,
              mach_vm_address_t		address,
              pointer_t			data,
              __unused mach_msg_type_number_t	size);

extern kern_return_t
mach_vm_region(
               vm_map_t		 map,
               mach_vm_offset_t	*address,
               mach_vm_size_t		*size,
               vm_region_flavor_t	 flavor,
               vm_region_info_t	 info,
               mach_msg_type_number_t	*count,
               mach_port_t		*object_name);
#endif

static NSArray *AllProcesses(void) // taken from http://forrst.com/posts/UIDevice_Category_For_Processes-h1H
{
	int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
	size_t miblen = 4;
	size_t size;
	int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
	struct kinfo_proc *process = NULL;
	struct kinfo_proc *newprocess = NULL;
	do
	{
		size += size / 10;
		newprocess = realloc(process, size);
		if (!newprocess)
		{
			if (process)
			{
				free(process);
			}
			return nil;
		}
		process = newprocess;
		st = sysctl(mib, miblen, process, &size, NULL, 0);
	}
	while (st == -1 && errno == ENOMEM);
	if (st == 0)
	{
		if (size % sizeof(struct kinfo_proc) == 0)
		{
			int nprocess = size / sizeof(struct kinfo_proc);
			if (nprocess)
			{
				NSMutableArray * array = [[NSMutableArray alloc] init];
				for (int i = nprocess - 1; i >= 0; i--)
				{
					NSString * processID = [[NSString alloc] initWithFormat:@"%d", process[i].kp_proc.p_pid];
					NSString * processName = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];
					NSDictionary * dictionary = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:processID, processName, nil] forKeys:[NSArray arrayWithObjects:@"ProcessID", @"ProcessName", nil]];
					[processID release];
					[processName release];
					[array addObject:dictionary];
					[dictionary release];
				}
				free(process);
				return [array autorelease];
			}
		}
	}
	return nil;
}

int main(int argc, char *argv[])
{
	// Output all Process IDs and names
	printf("[PID] ProcessName\n");
	for (NSDictionary *process in AllProcesses())
	{
		printf("[%s] %s\n", [(NSString *)[process objectForKey:@"ProcessID"] UTF8String], [(NSString *)[process objectForKey:@"ProcessName"] UTF8String]);
	}
    
	// Prompt
	printf("Enter target PID: ");
	int pid = 0;
	scanf("%d", &pid);
    
	if (![[GMMemManager shareInstance] setPid:pid])
	{
		exit(1);
	}
    
Search:
	// Prompt
	printf("Enter the value to search: ");
	int oldValue = 0; // change type: unsigned int, long, unsigned long, etc. Should be customizable!
	scanf("%d", &oldValue);
    
	// Output all searched results
	[[GMMemManager shareInstance] clearSearchData];
	[[GMMemManager shareInstance] search:oldValue isFirst:YES];
    
    NSLog(@"%llu search results.", [GMMemManager shareInstance].resultCount);
    NSArray *results = nil;
    
NextAction:
	// Prompt
	printf("1. Modify search results;\n2. Search results again;\n3. Show search results\n4. Search something else.\nPlease choose your next action: ");
	int nextAction;
	scanf("%d", &nextAction);
    
	// Modify searched results or review them
	switch (nextAction)
	{
		case 1:
        {
            // Prompt
            while (getchar() != '\n') continue; // clear buffer
            printf("Enter the address of modification: ");
            mach_vm_address_t modAddress;
            scanf("0x%llx", &modAddress);
            
            while (getchar() != '\n') continue; // clear buffer
            printf("Enter the new value: ");
            int newValue; // change type: unsigned int, long, unsigned long, etc. Should be customizable!
            scanf("%d", &newValue);
            
            GMMemoryAccessObject *obj = [[GMMemoryAccessObject alloc] init];
            obj.address = modAddress;
            obj.value = newValue;
            obj.optType = GMOptTypeEdit;
            
            [[GMMemManager shareInstance] modifyMemory:obj];
            [obj release];
            
            goto NextAction;
        }
		case 2:
        {
            printf("Enter the value to search: ");
           	int againValue = 0; // change type: unsigned int, long, unsigned long, etc. Should be customizable!
            scanf("%d", &againValue);
            [results release];
            results = [[[GMMemManager shareInstance] search:againValue isFirst:NO] retain];
            
            if ([GMMemManager shareInstance].resultCount > 50) {
                NSLog(@"%llu search results.", [GMMemManager shareInstance].resultCount);
            } else {
                if ([GMMemManager shareInstance].resultCount) {
                    for (int i = 0; i < [GMMemManager shareInstance].resultCount; i++) {
                        NSNumber *addressObj = [results objectAtIndex:i];
                        GMMemoryAccessObject *o = [[GMMemManager shareInstance] getMemoryAccessObject:addressObj.longLongValue];
                        NSLog(@"%d. address:%llx, value:%lld", i, addressObj.longLongValue, o.value);
                    }
                } else {
                    NSLog(@"No result");
                }
            }
            goto NextAction;
        }
        case 3:
        {
            if ([GMMemManager shareInstance].resultCount) {
                for (int i = 0; i < [GMMemManager shareInstance].resultCount; i++) {
                    NSNumber *addressObj = [results objectAtIndex:i];
                    GMMemoryAccessObject *o = [[GMMemManager shareInstance] getMemoryAccessObject:addressObj.longLongValue];
                    NSLog(@"%d. address:%llx, value:%lld", i, addressObj.longLongValue, o.value);
                }
            } else {
                NSLog(@"No result");
            }
            goto NextAction;
        }
		case 4:
        {
            goto Search;
        }
		default:
        {
            printf("Unknown action. Please re-enter.\n");
            goto NextAction;
        }
	}
    [[GMMemManager shareInstance] reset];
	return 0;
}



