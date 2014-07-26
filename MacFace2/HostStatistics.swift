//
//  HostStatistics.swift
//  MacFace2
//
//  Created by rryu on 2014/07/26.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import Foundation


public class VMStatistics
{
    public var freePages     : UInt32 = 0
    public var activePages   : UInt32 = 0
    public var inactivePages : UInt32 = 0
    public var wirePages     : UInt32 = 0
    public var faults        : UInt32 = 0
    public var pageins       : UInt32 = 0
    public var pageouts      : UInt32 = 0
}

public class ProcessorTicks
{
    public var user   : UInt32 = 0
    public var system : UInt32 = 0
    public var idle   : UInt32 = 0
    public var nice   : UInt32 = 0
}

public class HostStatistics
{
    public var pageSize : UInt
    public var processorCount : Int
    
    var hostPort : mach_port_t

    public init()
    {
        var result : kern_return_t = 0
        
        self.hostPort = mach_host_self()
        
        var buffer = UnsafePointer<host_basic_info>.alloc(1)
        var buffer_count = mach_msg_type_number_t(sizeof(host_basic_info))
        var ptr = host_info_t(buffer)

        result = host_info(hostPort, HOST_BASIC_INFO, ptr, &buffer_count)

        var basic_info = buffer.memory

        self.processorCount = Int(basic_info.avail_cpus)

        buffer.destroy()

        var pageSize : vm_size_t = 0
        result = host_page_size(hostPort, &pageSize)
        self.pageSize = pageSize
    }

    public func getVMStatistics(vmStats:VMStatistics)
    {
        var result : kern_return_t = 0

        var buffer = UnsafePointer<vm_statistics_data_t>.alloc(1)
        var buffer_count = mach_msg_type_number_t(sizeof(vm_statistics_data_t))
        var ptr = host_info_t(buffer)
        
        result = host_statistics(hostPort, HOST_VM_INFO, ptr, &buffer_count)

        var vm_stat = buffer.memory

        vmStats.freePages     = vm_stat.free_count;
        vmStats.activePages   = vm_stat.active_count;
        vmStats.inactivePages = vm_stat.inactive_count;
        vmStats.wirePages     = vm_stat.wire_count;
        vmStats.faults        = vm_stat.faults;
        vmStats.pageins       = vm_stat.pageins;
        vmStats.pageouts      = vm_stat.pageouts;

        buffer.destroy()
    }
    
    public func getTotalProcessorTicks(ticks:ProcessorTicks)
    {
        var result : kern_return_t = 0
        
        var buffer = host_info_t.alloc(Int(HOST_INFO_MAX))
        var buffer_count = mach_msg_type_number_t(HOST_INFO_MAX)

        result = host_statistics(hostPort, HOST_CPU_LOAD_INFO, buffer, &buffer_count)

        var load_info = UnsafePointer<host_cpu_load_info>(buffer).memory

        ticks.user   = load_info.cpu_ticks.0
        ticks.system = load_info.cpu_ticks.1
        ticks.idle   = load_info.cpu_ticks.2
        ticks.nice   = load_info.cpu_ticks.3

        buffer.destroy()
    }
    
    public func getAllProcessorTicks(ticksList:[ProcessorTicks])
    {
        var result : kern_return_t = 0
        
        var buffer : processor_info_array_t = processor_info_array_t.convertFromNilLiteral()
        var buffer_count : mach_msg_type_number_t = 0
        var cpu_count : natural_t = 0
        
        result = host_processor_info(hostPort, PROCESSOR_CPU_LOAD_INFO, &cpu_count, &buffer, &buffer_count)

        if (result != 0)
        {
            mach_error("host_processor_info error:", result)
            return;
        }

        var cpu_load_info_ptr = UnsafePointer<processor_cpu_load_info>(buffer)
        for (var i = 0; i < Int(cpu_count); i++)
        {
            var cpu_load_info = cpu_load_info_ptr.memory
            ticksList[i].user   = cpu_load_info.cpu_ticks.0
            ticksList[i].system = cpu_load_info.cpu_ticks.1
            ticksList[i].idle   = cpu_load_info.cpu_ticks.2
            ticksList[i].nice   = cpu_load_info.cpu_ticks.3
            cpu_load_info_ptr = cpu_load_info_ptr.successor()
        }

        var addr = COpaquePointer(buffer).encode()[0]
        result = vm_deallocate(mach_thread_self(), vm_address_t(addr), vm_size_t(buffer_count))
    }
    
    public func getGPUStatistics()
    {
        
    }
        
    public func getDefaultPagerStatistics()
    {
        
    }
        
}