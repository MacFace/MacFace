//
//  MacFace2Tests.swift
//  MacFace2Tests
//
//  Created by rryu on 2014/06/08.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import XCTest

class HostStatisticsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testPageSize() {
        var stats = HostStatistics()
        XCTAssertGreaterThan(stats.pageSize, 0)
    }
    
    func testProcessorCount() {
        var stats = HostStatistics()
        XCTAssertGreaterThan(stats.processorCount, 0)
    }
    
    func testGetVMStatistics() {
        var stats = HostStatistics()
        var vmStats = VMStatistics()

        stats.getVMStatistics(vmStats);
        
        XCTAssertGreaterThan(vmStats.freePages, 0)
        XCTAssertGreaterThan(vmStats.activePages, 0)
        XCTAssertGreaterThan(vmStats.inactivePages, 0)
        XCTAssertGreaterThan(vmStats.wirePages, 0)
        XCTAssertGreaterThan(vmStats.faults, 0)
        XCTAssertGreaterThan(vmStats.pageins, 0)
        XCTAssertGreaterThan(vmStats.pageouts, 0)
    }
    
    func testGetTotalProcessorTicks() {
        var stats = HostStatistics()
        var ticks = ProcessorTicks()
        
        stats.getTotalProcessorTicks(ticks);
        
        XCTAssertGreaterThan(ticks.user, 0)
        XCTAssertGreaterThan(ticks.system, 0)
        XCTAssertGreaterThan(ticks.idle, 0)
        //XCTAssertGreaterThan(ticks.nice, 0)
    }
    
    func testGetAllProcessorTicks() {
        var stats = HostStatistics()
        var ticksList = ProcessorTicks[]()
        var i = 0;
        
        for i in 0..stats.processorCount
        {
            ticksList.append(ProcessorTicks())
        }

        stats.getAllProcessorTicks(ticksList);
        
        for ticks in ticksList
        {
            XCTAssertGreaterThan(ticks.user, 0)
            XCTAssertGreaterThan(ticks.system, 0)
            XCTAssertGreaterThan(ticks.idle, 0)
            //XCTAssertGreaterThan(ticks.nice, 0)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
