//
//  PatternWindowController.swift
//  MacFace2
//
//  Created by rryu on 2014/07/01.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import Foundation
import Cocoa

public class PatternWindowController : NSWindowController {
    @IBOutlet weak var patternView : PatternView! = nil
    @IBOutlet weak var label : NSTextField! = nil

    public var faceImage : FaceImage? {
        didSet {
            if let view = patternView {
                view.faceImage = faceImage
            }
        }
    }

    public var fixedWindow : Bool {
    get {
        return window.ignoresMouseEvents
    }
    set {
        window.ignoresMouseEvents = newValue
        if newValue {
            window.level = Int(CGWindowLevelForKey(Int32(kCGFloatingWindowLevelKey)))
        } else {
            window.level = Int(CGWindowLevelForKey(Int32(kCGNormalWindowLevelKey)))
        }
    }
    }
    
    public var alphaValue : CGFloat {
    get {
        return window.alphaValue
    }
    set  {
        window.alphaValue = newValue
    }
    }
        
    public override func windowDidLoad()
    {
        //window.styleMask = NSBorderlessWindowMask
        window.backgroundColor = NSColor.clearColor()
        window.opaque = false

        window.movable = true
        window.movableByWindowBackground = true

        patternView.faceImage = faceImage
    }

    public func minimizeWindow()
    {
        window.miniaturize(nil)
    }
    
    public func update(record:HistoryRecord, processorFactor:ProcessorFactor)
    {
        if let face = faceImage {
            face.update(record, processorFactor:processorFactor)
            if window.miniaturized {
                window.miniwindowImage = face.image
            } else {
                patternView.display()
            }
        }
    }
}
