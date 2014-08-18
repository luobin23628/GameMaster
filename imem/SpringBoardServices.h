//
//  SpringBoardServices.h
//  TUIKit
//
//  Created by Thilong on 14-4-24.
//  Copyright (c) 2014年 TYC. All rights reserved.
//

#ifndef TUIKit_SpringBoardServices_h
#define TUIKit_SpringBoardServices_h


#include <CoreFoundation/CoreFoundation.h>

#if __cplusplus
extern "C" {
#endif
    
#pragma mark - API
    
    mach_port_t SBSSpringBoardServerPort();
    void SBSetSystemVolumeHUDEnabled(mach_port_t springBoardPort, const char *audioCategory, Boolean enabled);
    
    void SBSOpenNewsstand();
    void SBSSuspendFrontmostApplication();
    
    CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef displayIdentifier);
    CFStringRef SBSCopyBundlePathForDisplayIdentifier(CFStringRef displayIdentifier);
    CFStringRef SBSCopyExecutablePathForDisplayIdentifier(CFStringRef displayIdentifier);
    CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef displayIdentifier);
    
    CFSetRef SBSCopyDisplayIdentifiers();
    
    CFStringRef SBSCopyFrontmostApplicationDisplayIdentifier();
    CFStringRef SBSCopyDisplayIdentifierForProcessID(pid_t PID);
    CFArrayRef SBSCopyDisplayIdentifiersForProcessID(pid_t PID);
    BOOL SBSProcessIDForDisplayIdentifier(CFStringRef identifier, pid_t *pid);
    
    int SBSLaunchApplicationWithIdentifier(CFStringRef identifier, Boolean suspended);
    int SBSLaunchApplicationWithIdentifierAndLaunchOptions(CFStringRef identifier, CFDictionaryRef launchOptions, BOOL suspended);
    CFStringRef SBSApplicationLaunchingErrorString(int error);
    
#if __cplusplus
}
#endif

#endif
