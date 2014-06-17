//
//  HostStatistics.h
//  MacFace2
//
//  Created by rryu on 2014/06/15.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mach/mach_types.h>

@interface VMStatistics : NSObject

@property unsigned long freePages;
@property unsigned long activePages;
@property unsigned long inactivePages;
@property unsigned long wirePages;
@property unsigned long faults;
@property unsigned long pageins;
@property unsigned long pageouts;

@end

@interface ProcessorTicks : NSObject

@property unsigned long  user;
@property unsigned long  system;
@property unsigned long  idle;
@property unsigned long  nice;

@end

@interface HostStatistics : NSObject

@property unsigned long pageSize;
@property int processorCount;

- (void)getVMStatistics:(VMStatistics*)vmStats;
- (void)getTotalProcessorTicks:(ProcessorTicks*)ticks;
- (void)getAllProcessorTicks:(NSArray*)ticksList;
- (void)getGPUStatistics;
- (void)getDefaultPagerStatistics;

@end
