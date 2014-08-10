//
//  darwin_memory_usage.h .h
//  imem
//
//  Created by LuoBin on 14-7-23.
//
//

#ifndef imem_darwin_memory_usage_h__h
#define imem_darwin_memory_usage_h__h

#if defined(__APPLE__)

// Returns the virtual size of the current process. This will match what "top" reports for VSIZE
unsigned long long darwin_virtual_size();

#endif

#endif
