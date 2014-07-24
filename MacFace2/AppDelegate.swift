//
//  AppDelegate.swift
//  MacFace2
//
//  Created by rryu on 2014/06/08.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import Cocoa

public class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statsHistory: StatsHistory!
    var updateTimer: NSTimer!

    var patternWindowControllers : [PatternWindowController] = [PatternWindowController]()

    public func applicationDidFinishLaunching(aNotification: NSNotification?) {
        statsHistory = StatsHistory()
        
        var path = NSBundle.mainBundle().pathForResource("default", ofType:"mcface")
        var faceDef = FaceDef(path:path)

        for i in (0..<statsHistory.processorCount)
        {
            var patternWindowController = PatternWindowController(windowNibName:"PatternWindow")
            patternWindowController.faceImage = FaceImage(faceDef:faceDef)
            patternWindowController.window.title = "Processor \(i+1)"
            patternWindowController.window.setFrameAutosaveName("processor\(i+1)")
            patternWindowController.label.stringValue = patternWindowController.window.title
            
            patternWindowController.alphaValue = 0.5
            patternWindowController.fixedWindow = false

            patternWindowControllers.append(patternWindowController)
        }
        
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target:self, selector:Selector("updateStatus:"),
            userInfo:nil, repeats:true
        )

        for i in (0..<statsHistory.processorCount)
        {
            patternWindowControllers[i].window.setFrameTopLeftPoint(NSPoint(x:i * 130, y:800))
            patternWindowControllers[i].showWindow(nil)
        }
    }

    public func applicationWillTerminate(aNotification: NSNotification?) {
        updateTimer.invalidate()
    }

    public func applicationDidChangeOcclusionState(aNotification: NSNotification)
    {
        if NSApp.occlusionState & NSApplicationOcclusionState.Visible {
            // the app is visible; continue doing work
            NSLog("Visible")
        } else {
            // the app is not visible; stop doing work }
            NSLog("Invisible")
        }
    }

    public func updateStatus(timer:NSTimer)
    {
        var history = statsHistory as StatsHistory
        statsHistory.update()
        
        var curRecord = statsHistory.currentRecord()

        for i in (0..<statsHistory.processorCount)
        {
            patternWindowControllers[i].update(curRecord, processorFactor:curRecord.processorFactors[i])
        }
    }
}

