//
//  SFMemoryHandler.m
//  SC2HDB
//
//  Created by Pol Eyschen on 11.04.13.
//
//
#include <sys/param.h>
#include <sys/sysctl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <mach-o/dyld_images.h>
#include <err.h>
#import "SFMemoryHandler.h"

@implementation SFMemoryHandler


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                             *
 * Original: http://programming-in-linux.blogspot.com/2008/03/get-process-id-by-name-in-c.html *
 *                                                                                             *
 * (Re)Implemented in Objective-C                                                              *
 *                                                                                             *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

+ (pid_t) getPidForProcess: (NSString*)processName
{
    struct kinfo_proc *sProcesses = NULL, *sNewProcesses;
    pid_t  iCurrentPid;
    int    aiNames[4];
    size_t iNamesLength;
    int    i, iRetCode, iNumProcs;
    size_t iSize;
    
    iSize = 0;
    aiNames[0] = CTL_KERN;
    aiNames[1] = KERN_PROC;
    aiNames[2] = KERN_PROC_ALL;
    aiNames[3] = 0;
    iNamesLength = 3;
    
    iRetCode = sysctl(aiNames, (u_int)iNamesLength, NULL, &iSize, NULL, 0);
    
    /*
     * Allocate memory and populate info in the  processes structure
     */
    
    do {
        iSize += iSize / 10;
        sNewProcesses = realloc(sProcesses, iSize);
        
        if (sNewProcesses == 0) {
            if (sProcesses)
                free(sProcesses);
            errx(1, "could not reallocate memory");
        }
        sProcesses = sNewProcesses;
        iRetCode = sysctl(aiNames, (u_int)iNamesLength, sProcesses, &iSize, NULL, 0);
    } while (iRetCode == -1 && errno == ENOMEM);
    
    iNumProcs = (int)iSize / sizeof(struct kinfo_proc);
    /*
     * Search for the given process name and return its pid.
     */
    
    for (i = 0; i < iNumProcs; i++) {
        iCurrentPid = sProcesses[i].kp_proc.p_pid;
        if( strncmp([processName cStringUsingEncoding:NSUTF8StringEncoding], sProcesses[i].kp_proc.p_comm, MAXCOMLEN) == 0 ) {
            free(sProcesses);
            return iCurrentPid;
        }
    }
    
    /*
     * Clean up and return -1 because the given proc name was not found
     */
    
    free(sProcesses);
    return (-1);
}

+ (addr64_t) getBaseAddressForProcessWithPid: (pid_t)pid
{
    mach_vm_address_t address = 0x0;
    mach_vm_size_t size;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t infoCount = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t objectName = MACH_PORT_NULL;
    task_t	processTask;
	task_for_pid(mach_task_self(),pid, &processTask);
    bool f = FALSE;
    
    do {
        if (mach_vm_region(processTask, &address, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &infoCount, &objectName) == KERN_SUCCESS)
        {
            if (address != 0)
            {
                return address;
                f = TRUE;
            } else {
                address += size;
            }
        } else {
            perror("Could not retrieve regions");
            return -2;
        }
        
    } while (!f);
    return -1;
}

+ (NSString *)readProcessMemoryTextFromPid: (pid_t)pid AtAddress: (addr64_t)addr WithSize:(mach_msg_type_number_t*)size
{
    task_t task;
    task_for_pid(mach_task_self(), pid, &task);
    vm_offset_t readBuffer;
    kern_return_t kr = vm_read(task,    addr,
                               *size,   &readBuffer, size);
    if (kr) {
        fprintf(stderr,"Unable to read memory at @%llu - kernel return code 0x%x",addr,kr);
        return NULL;
    }
    
    return [NSString stringWithUTF8String:(char*)readBuffer];
}

@end
