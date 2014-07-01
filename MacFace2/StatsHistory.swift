//
//  StatsHistory.swift
//  MacFace2
//
//  Created by rryu on 2014/06/22.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import Foundation

class ProcessorFactor {
    var user: Float = 0.0
    var system: Float = 0.0
    var idle: Float = 0.0
    var nice: Float = 0.0

    func update(ticks:ProcessorTicks, lastTicks:ProcessorTicks)
    {
        var user   = ticks.user - lastTicks.user
        var system = ticks.system - lastTicks.system
        var idle   = ticks.idle - lastTicks.idle
        var nice   = ticks.nice - lastTicks.nice
        var total = Float(user + system + idle + nice)
        
        self.user   = Float(user) / total
        self.system = Float(system) / total
        self.idle   = Float(idle) / total
        self.nice   = Float(nice) / total
    }
}

class HistoryRecord {
    var vmStats: VMStatistics
    var pageinDelta: Int
    var pageoutDelta: Int

    var totalTicks: ProcessorTicks
    var totalFactor: ProcessorFactor
    
    var processorTicks: ProcessorTicks[]
    var processorFactors: ProcessorFactor[]
    
    init(processorCount:Int)
    {
        vmStats = VMStatistics()
        pageinDelta = 0
        pageoutDelta = 0

        totalTicks = ProcessorTicks()
        totalFactor = ProcessorFactor()

        processorTicks = ProcessorTicks[]()
        processorFactors = ProcessorFactor[]()

        for i in 0..processorCount
        {
            processorTicks.append(ProcessorTicks())
            processorFactors.append(ProcessorFactor())
        }
    }
}


class StatsHistory {
    var hostStats: HostStatistics
    var records: HistoryRecord[]
    var processorCount: Int

    init()
    {
        hostStats = HostStatistics()
        processorCount = Int(hostStats.processorCount)

        records = HistoryRecord[]()
        
        records.append(createRecord())
    }

    func update()
    {
        var record = createRecord()
        var lastRecord = currentRecord()

        record.pageinDelta = Int(record.vmStats.pageins - lastRecord.vmStats.pageins)
        record.pageoutDelta = Int(record.vmStats.pageouts - lastRecord.vmStats.pageouts)
        
        record.totalFactor.update(record.totalTicks, lastTicks:lastRecord.totalTicks)

        for i in 0..processorCount
        {
            record.processorFactors[i].update(record.processorTicks[i], lastTicks:lastRecord.processorTicks[i])
        }

        records.append(record)
    }

    func createRecord() -> HistoryRecord
    {
        var record = HistoryRecord(processorCount: processorCount)
    
        hostStats.getVMStatistics(record.vmStats)
        hostStats.getTotalProcessorTicks(record.totalTicks)
        hostStats.getAllProcessorTicks(record.processorTicks)
        
        return record
    }

    func currentRecord() -> HistoryRecord
    {
        return records[records.count - 1]
    }
}
