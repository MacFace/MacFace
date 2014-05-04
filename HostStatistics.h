//
//  HostStatistics.h
//  face
//
//  Created by rryu on Fri Apr 05 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mach/mach_types.h>

typedef struct {
    unsigned long freePages;
    unsigned long activePages;
    unsigned long inactivePages;
    unsigned long wirePages;
    unsigned long faults;
    unsigned long pageins;
    unsigned long pageouts;
    unsigned long pageinDelta;
    unsigned long pageoutDelta;
} MemoryStats;

typedef struct {
    float user;
    float system;
    float idle;
    float nice;
} ProcessorUsage;

typedef struct {
    unsigned long  user;
    unsigned long  system;
    unsigned long  idle;
    unsigned long  nice;
} ProcessorTicks;

typedef struct {
	ProcessorTicks ticks;
	ProcessorUsage usage;
} ProcessorStats;


@interface HostStatistics : NSObject
{
	mach_port_t hostPort;

	mach_msg_type_number_t processorCount;

    vm_size_t pageSize;
    unsigned long totalPages;
    unsigned long minUsedPages;
    unsigned long maxUsedPages;
	
	MemoryStats    *memoryHistory;
	ProcessorStats *totalProcessorHistory;
	ProcessorStats *processorHistories;
    
	int bufMaxLen;
    int bufHead;
    int bufTail;
    int bufLen;
}

+ (NSString*)kernelVersion;

- (id)initWithCapacity:(unsigned)capacity;

- (void)update;

- (unsigned long)pageSize;
- (unsigned long)totalPages;
- (unsigned long)minUsedPages;
- (unsigned long)maxUsedPages;

- (int)processorCount;

- (int)length;

- (const MemoryStats*)memoryStatsIndexAt:(unsigned)index;
- (const ProcessorStats*)totalProcessorUsageIndexAt:(unsigned)index;
- (const ProcessorStats*)processorOf:(int)number usageIndexAt:(unsigned)index;

@end
