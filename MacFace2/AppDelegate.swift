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

    var patternWindowControllers : PatternWindowController[] = PatternWindowController[]()

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        statsHistory = StatsHistory()
        
        var path = NSBundle.mainBundle().pathForResource("default", ofType:"mcface")
        var faceDef = FaceDef(path:path)

        for i in (0..statsHistory.processorCount)
        {
            var patternWindowController = PatternWindowController(windowNibName:"PatternWindow")
            patternWindowController.faceImage = FaceImage(faceDef:faceDef)
            patternWindowControllers.append(patternWindowController)
        }
        
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target:self, selector:Selector("updateStatus:"),
            userInfo:nil, repeats:true
        )

        for i in (0..statsHistory.processorCount)
        {
            patternWindowControllers[i].window.setFrameTopLeftPoint(NSPoint(x:i * 130, y:200))
            patternWindowControllers[i].showWindow(nil)
        }
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

        for i in (0..statsHistory.processorCount)
        {
            patternWindowControllers[i].update(curRecord, processorFactor:curRecord.processorFactors[i])
        }
    }
}

