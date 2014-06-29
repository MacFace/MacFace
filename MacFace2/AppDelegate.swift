//
//  AppDelegate.swift
//  MacFace2
//
//  Created by rryu on 2014/06/08.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statsHistory: StatsHistory!
    var updateTimer: NSTimer!

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        statsHistory = StatsHistory()
        
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target:self, selector:Selector("updateStatus:"),
            userInfo:nil, repeats:true
        )
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        updateTimer.invalidate()
    }

    func applicationDidChangeOcclusionState(aNotification: NSNotification)
    {
        if NSApp.occlusionState & NSApplicationOcclusionState.Visible {
            // the app is visible; continue doing work
            NSLog("Visible")
        } else {
            // the app is not visible; stop doing work }
            NSLog("Invisible")
        }
    }

    func updateStatus(timer:NSTimer)
    {
        var history = statsHistory as StatsHistory
        statsHistory.update()
        
        var curRecord = statsHistory.currentRecord()
        print(curRecord.totalFactor.user)
        print(" [")
        for factor in curRecord.processorFactors
        {
            print("\(factor.user) ")
        }
        print("]")
    }
}

