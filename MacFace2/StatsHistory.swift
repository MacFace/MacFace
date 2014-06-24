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

    func update(ticks:ProcessorTicks)
    {
        var total = Float(ticks.user +  ticks.system + ticks.idle + ticks.nice)
        self.user = Float(ticks.user) / total
        self.system = Float(ticks.system) / total
        self.idle = Float(ticks.idle) / total
        self.nice = Float(ticks.nice) / total
    }
}

class HistoryRecord {
    var vmStats: VMStatistics
    var pageinDelta: Int
    var pageoutDelta: Int
    var totalFactor: ProcessorFactor
    var processorFactors: ProcessorFactor[]
    
    init(processorCount:Int)
    {
        vmStats = VMStatistics()
        pageinDelta = 0
        pageoutDelta = 0
        totalFactor = ProcessorFactor()
        processorFactors = ProcessorFactor[]()

        for i in 0..processorCount
        {
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
        records = HistoryRecord[]()
        processorCount = Int(hostStats.processorCount)
    }

    func update()
    {
        var record = HistoryRecord(processorCount: processorCount)

        hostStats.getVMStatistics(record.vmStats)

        var ticks = ProcessorTicks()

        hostStats.getTotalProcessorTicks(ticks)
        record.totalFactor.update(ticks)

        var ticksList = ProcessorTicks[]()
        for i in 0..processorCount
        {
            ticksList.append(ProcessorTicks())
        }
        hostStats.getAllProcessorTicks(ticksList)
        
        for i in 0..processorCount
        {
            record.processorFactors[i].update(ticksList[i])
        }

        records.append(record)
    }
    
    func currentRecord() -> HistoryRecord
    {
        return records[records.count - 1]
    }
}
