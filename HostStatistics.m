//
//  HostStatistic.m
//  face
//
//  Created by rryu on Fri Apr 05 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <mach/mach.h>
#import <mach/mach_types.h>
#import "HostStatistics.h"

@implementation HostStatistics

//
// カーネルのバージョン文字列を返す
//
+ (NSString*)kernelVersion
{
    kernel_version_t kver;
    host_kernel_version(mach_host_self(),kver);
    return [NSString stringWithUTF8String:kver];
}

//
// 初期化
//   capacity: リングバッファの容量
//
- (id)initWithCapacity:(unsigned)capacity
{
	kern_return_t kr;
	host_basic_info_data_t basic_info;
	mach_msg_type_number_t basic_info_count;

	hostPort = mach_host_self();
	
	basic_info_count = HOST_BASIC_INFO_COUNT;
	kr = host_info(hostPort, HOST_BASIC_INFO, (host_info_t)&basic_info, &basic_info_count);
	
	processorCount = basic_info.avail_cpus;
	
    kr = host_page_size(hostPort, &pageSize);
	
    memoryHistory = calloc(sizeof(MemoryStats), capacity);
    totalProcessorHistory = calloc(sizeof(ProcessorStats), capacity);
    processorHistories = calloc(sizeof(ProcessorStats), capacity * processorCount);

    bufMaxLen = capacity;
    bufHead = 0;
    bufTail = 0;
    bufLen = 1;

	[self setMemoryStats:&memoryHistory[0]];
	[self setTotalProcessorTicks:&totalProcessorHistory[0]];
	[self setAllProcessorTicks:&processorHistories[0]];
	
	
    totalProcessorHistory[0].usage.user = 0;
    totalProcessorHistory[0].usage.system = 0;
    totalProcessorHistory[0].usage.idle = 100.0;
    totalProcessorHistory[0].usage.nice = 0;
	
    totalPages = memoryHistory[0].wirePages + memoryHistory[0].activePages + memoryHistory[0].inactivePages + memoryHistory[0].freePages;

    minUsedPages = memoryHistory[0].wirePages + memoryHistory[0].activePages;
    maxUsedPages = minUsedPages;

    return self;
}

//
// 後始末
//
- (void)dealloc
{
    free(memoryHistory);
    free(totalProcessorHistory);
    free(processorHistories);

	[super dealloc];
}


- (unsigned long)pageSize     { return pageSize; }
- (unsigned long)totalPages   { return totalPages; }
- (unsigned long)minUsedPages { return minUsedPages; }
- (unsigned long)maxUsedPages { return maxUsedPages; }

- (int)processorCount { return processorCount; }


- (int)length       { return bufLen; }



- (void)setMemoryStats:(MemoryStats*)data
{
	kern_return_t kr;
    vm_statistics_data_t vm_stat;
    mach_msg_type_number_t vm_count = HOST_VM_INFO_COUNT;
	
    kr = host_statistics(hostPort, HOST_VM_INFO, (host_info_t)&vm_stat, &vm_count);
	
    data->freePages     = vm_stat.free_count;
    data->activePages   = vm_stat.active_count;
    data->inactivePages = vm_stat.inactive_count;
    data->wirePages     = vm_stat.wire_count;
    data->faults        = vm_stat.faults;
    data->pageins       = vm_stat.pageins;
    data->pageouts      = vm_stat.pageouts;
}

- (void)setTotalProcessorTicks:(ProcessorStats*)data
{
	kern_return_t kr;
    host_cpu_load_info_data_t load_info;
    mach_msg_type_number_t load_info_count = HOST_CPU_LOAD_INFO_COUNT;
	
    kr = host_statistics(hostPort, HOST_CPU_LOAD_INFO, (host_info_t)&load_info, &load_info_count);

    data->ticks.user   = load_info.cpu_ticks[CPU_STATE_USER];
    data->ticks.system = load_info.cpu_ticks[CPU_STATE_SYSTEM];
    data->ticks.idle   = load_info.cpu_ticks[CPU_STATE_IDLE];
    data->ticks.nice   = load_info.cpu_ticks[CPU_STATE_NICE];
}

- (void)setAllProcessorTicks:(ProcessorStats*)data
{
	kern_return_t kr;
	processor_cpu_load_info_t cpu_load_info;
	natural_t cpu_count;
	mach_msg_type_number_t info_count;
	int i;

	kr = host_processor_info(hostPort, PROCESSOR_CPU_LOAD_INFO, &cpu_count, (processor_info_array_t*)&cpu_load_info, &info_count);
	if (kr) {
		mach_error("host_processor_info error:", kr);
		return;
	}

	for (i = 0; i < processorCount; i++)
	{	
		data[i].ticks.user   = cpu_load_info[i].cpu_ticks[CPU_STATE_USER];
		data[i].ticks.system = cpu_load_info[i].cpu_ticks[CPU_STATE_SYSTEM];
		data[i].ticks.idle   = cpu_load_info[i].cpu_ticks[CPU_STATE_IDLE];
		data[i].ticks.nice   = cpu_load_info[i].cpu_ticks[CPU_STATE_NICE];
	}

	vm_deallocate(mach_task_self(), (vm_address_t)cpu_load_info, info_count);
}

//
// 履歴の更新
//
- (void)update
{
	int newHead;
	int newLen;
	int newTail;
    int user,sys,idle,nice,total;
    int usedPages;
	MemoryStats *curMemStats, *lastMemStats;
	ProcessorStats *curProcStats, *lastProcStats;
	int i;

	newHead = bufHead;
	newTail = bufTail;
	newLen = bufLen;

    if (newLen < bufMaxLen) newLen++;
    if (++newHead >= newLen) newHead = 0;
    if (newHead == bufTail) {
        if (++newTail >= newLen) newTail = 0;
	}

	[self setMemoryStats:&memoryHistory[newHead]];
	[self setTotalProcessorTicks:&totalProcessorHistory[newHead]];
	[self setAllProcessorTicks:&processorHistories[processorCount * newHead]];

	
	curMemStats = &memoryHistory[newHead];
	lastMemStats = &memoryHistory[bufHead];

    curMemStats->pageinDelta  = curMemStats->pageins - lastMemStats->pageins;
    curMemStats->pageoutDelta = curMemStats->pageouts - lastMemStats->pageouts;

	usedPages = curMemStats->wirePages + curMemStats->activePages;
    if( minUsedPages < usedPages) minUsedPages = usedPages;
    if( maxUsedPages > usedPages) maxUsedPages = usedPages;
	
	
	curProcStats = &totalProcessorHistory[newHead];
	lastProcStats = &totalProcessorHistory[bufHead];
	
    user  = curProcStats->ticks.user - lastProcStats->ticks.user;
    sys   = curProcStats->ticks.system - lastProcStats->ticks.system;
    idle  = curProcStats->ticks.idle - lastProcStats->ticks.idle;
    nice  = curProcStats->ticks.nice - lastProcStats->ticks.nice;
    total = user + sys + idle + nice;

    if (total > 0) {
        curProcStats->usage.user   = user * 100.0 / total;
        curProcStats->usage.system = sys  * 100.0 / total;
        curProcStats->usage.idle   = idle * 100.0 / total;
        curProcStats->usage.nice   = nice * 100.0 / total;
    } else {
        curProcStats->usage = lastProcStats->usage;
    }

	for (i = 0; i < processorCount; i++) {
		curProcStats = &processorHistories[processorCount * newHead + i];
		lastProcStats = &processorHistories[processorCount * bufHead + i];
	
		user  = curProcStats->ticks.user - lastProcStats->ticks.user;
		sys   = curProcStats->ticks.system - lastProcStats->ticks.system;
		idle  = curProcStats->ticks.idle - lastProcStats->ticks.idle;
		nice  = curProcStats->ticks.nice - lastProcStats->ticks.nice;
		total = user + sys + idle + nice;
	
		if (total > 0) {
			curProcStats->usage.user   = user * 100.0 / total;
			curProcStats->usage.system = sys  * 100.0 / total;
			curProcStats->usage.idle   = idle * 100.0 / total;
			curProcStats->usage.nice   = nice * 100.0 / total;
		} else {
			curProcStats->usage = lastProcStats->usage;
		}
	}

	bufHead = newHead;
	bufTail = newTail;
	bufLen  = newLen;
}


- (const MemoryStats*)memoryStatsIndexAt:(unsigned)index
{
    if (index >= bufLen) return nil;
    index = (index <= bufHead) ? bufHead - index : bufLen + bufHead - index;
    return &memoryHistory[index];
}

- (const ProcessorStats*)totalProcessorUsageIndexAt:(unsigned)index
{
    if (index >= bufLen) return nil;
    index = (index <= bufHead) ? bufHead - index : bufLen + bufHead - index;
    return &totalProcessorHistory[index];
}

- (const ProcessorStats*)processorOf:(int)number usageIndexAt:(unsigned)index
{
    if (index >= bufLen) return nil;
    index = (index <= bufHead) ? bufHead - index : bufLen + bufHead - index;
    return &processorHistories[processorCount * index + number];
}

@end
