//
//  GMMem.m
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

#import "GMMem.h"
#import <mach/mach.h>
#include <sys/sysctl.h>


#define MaxCount 100

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

GMMemRef GMMemRefCreate(int pid) {
    GMMemRef mem = (GMMemRef)CFAllocatorAllocate(NULL, sizeof(struct __GMMem), 0);
    // Get task of specified PID
	kern_return_t kret;
	mach_port_t task; // type vm_map_t = mach_port_t in mach_types.defs
	if ((kret = task_for_pid(mach_task_self(), pid, &task)) != KERN_SUCCESS)
	{
		NSLog(@"task_for_pid() failed, error %d: %s. Forgot to run as root?\n", kret, mach_error_string(kret));
        exit(1);
        return NULL;
    }
//    CFArrayCreateMutable(NULL, 666, const CFArrayCallBacks *callBacks)
    mem->task = task;
    mem->results = [[NSMutableArray arrayWithCapacity:MaxCount] retain]; // Store searched memory addresses for review, saving another iteration of mach_vm_region
    
    return mem;
}

BOOL GMMemRefSearchAgain (GMMemRef mem, int64_t value) {
    kern_return_t kret;
    mach_vm_size_t size;
    mach_vm_offset_t address = 0;
    
    NSMutableArray *results = [NSMutableArray array];
    
    for (int i = 0; i < [mem->results count]; i++) {
        GMResult result;
        [[mem->results objectAtIndex:i] getValue:&result];
        pointer_t buffer;
        size = sizeof(int); // because oldValue and newValue are int
        mach_msg_type_number_t bufferSize = (mach_msg_type_number_t)size;
        
        if ((kret = vm_read(mem->task, (mach_vm_address_t)address, size, &buffer, &bufferSize)) == KERN_SUCCESS)
		{
			void *substring = NULL;
			if ((substring = memmem((const void *)buffer, bufferSize, &value, sizeof(value))) != NULL) {
                result.value = value;
				[results addObject:[NSValue value:&result withObjCType:@encode(GMResult)]];
			}
		}
    }
    [mem->results removeAllObjects];
    [mem->results addObjectsFromArray:results];
    
    return YES;
}

NSArray *GMMemRefSearch(GMMemRef mem, int64_t value, bool isFirst) {
    //	int oldValue = 0; // change type: unsigned int, long, unsigned long, etc. Should be customizable!
    
    if(isFirst){
        GMMemRefSearchFirst(mem, value);
    } else {
        GMMemRefSearchAgain(mem, value);
    }
    return mem->results;
}

void GMMemRefReset(GMMemRef mem) {
    [mem->results removeAllObjects];
}

void GMMemRefModify(GMMemRef mem, uint64_t address, int64_t value) {
    if ([mem->results indexOfObject:[NSNumber numberWithLongLong:address]] == NSNotFound){
        NSLog("This address is not in search results, hence invalid. Please re-enter.\n");
        return;
    }
    
    kern_return_t kret;
    if ((kret = vm_write(mem->task, address, (pointer_t)&value, sizeof(value))) != KERN_SUCCESS) {
        NSLog("mach_vm_write failed, error %d: %s\n", kret, mach_error_string(kret));
    }
}

void GMMemRefRelease(GMMemRef mem) {
    if (mem) {
        [mem->results release];
        mem->results = NULL;
        CFAllocatorDeallocate(NULL, mem);
    }
}













