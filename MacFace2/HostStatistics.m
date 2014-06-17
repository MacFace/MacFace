//
//  HostStatistics.m
//  MacFace2
//
//  Created by rryu on 2014/06/15.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

#import "HostStatistics.h"
#import <mach/mach.h>


@implementation VMStatistics

- (id)init
{
    return self;
}

@end

@implementation ProcessorTicks

- (id)init
{
    return self;
}

@end

@implementation HostStatistics
{
    mach_port_t hostPort;
}

- (id)init
{
    kern_return_t result;
    host_basic_info_data_t basic_info;
    mach_msg_type_number_t basic_info_count;
    vm_size_t pageSize;
    
    
    hostPort = mach_host_self();
    
    basic_info_count = HOST_BASIC_INFO_COUNT;
    result = host_info(hostPort, HOST_BASIC_INFO, (host_info_t)&basic_info, &basic_info_count);
    
    self.processorCount = basic_info.avail_cpus;
    
    result = host_page_size(hostPort, &pageSize);
    self.pageSize = pageSize;
    
    return self;
}


- (void)getVMStatistics:(VMStatistics*)vmStats
{
    kern_return_t result;
    vm_statistics_data_t vm_stat;
    mach_msg_type_number_t vm_count = HOST_VM_INFO_COUNT;
    
    result = host_statistics(hostPort, HOST_VM_INFO, (host_info_t)&vm_stat, &vm_count);
    
    vmStats.freePages     = vm_stat.free_count;
    vmStats.activePages   = vm_stat.active_count;
    vmStats.inactivePages = vm_stat.inactive_count;
    vmStats.wirePages     = vm_stat.wire_count;
    vmStats.faults        = vm_stat.faults;
    vmStats.pageins       = vm_stat.pageins;
    vmStats.pageouts      = vm_stat.pageouts;
}

- (void)getTotalProcessorTicks:(ProcessorTicks *)ticks
{
    kern_return_t result;
    host_cpu_load_info_data_t load_info;
    mach_msg_type_number_t load_info_count = HOST_CPU_LOAD_INFO_COUNT;
    
    result = host_statistics(hostPort, HOST_CPU_LOAD_INFO, (host_info_t)&load_info, &load_info_count);
    
    ticks.user   = load_info.cpu_ticks[CPU_STATE_USER];
    ticks.system = load_info.cpu_ticks[CPU_STATE_SYSTEM];
    ticks.idle   = load_info.cpu_ticks[CPU_STATE_IDLE];
    ticks.nice   = load_info.cpu_ticks[CPU_STATE_NICE];
}

- (void)getAllProcessorTicks:(NSArray*)ticksList
{
    kern_return_t result;
    processor_cpu_load_info_t cpu_load_info;
    natural_t cpu_count;
    mach_msg_type_number_t info_count;
    int i;
    
    result = host_processor_info(hostPort, PROCESSOR_CPU_LOAD_INFO, &cpu_count, (processor_info_array_t*)&cpu_load_info, &info_count);
    if (result) {
        mach_error("host_processor_info error:", result);
        return;
    }

    i = 0;
    for (ProcessorTicks* ticks in ticksList)
    {
        ticks.user   = cpu_load_info[i].cpu_ticks[CPU_STATE_USER];
        ticks.system = cpu_load_info[i].cpu_ticks[CPU_STATE_SYSTEM];
        ticks.idle   = cpu_load_info[i].cpu_ticks[CPU_STATE_IDLE];
        ticks.nice   = cpu_load_info[i].cpu_ticks[CPU_STATE_NICE];
        i++;
    }
    
    vm_deallocate(mach_task_self(), (vm_address_t)cpu_load_info, info_count);
}

- (void)getGPUStatistics
{
    
}

- (void)getDefaultPagerStatistics
{
    
}

@end
