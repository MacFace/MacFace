//
//  PatternWindowController.swift
//  MacFace2
//
//  Created by rryu on 2014/07/01.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import Foundation
import Cocoa

class PatternWindowController : NSWindowController {
    @IBOutlet var imageView : NSImageView
    var faceImage : FaceImage?

    override func windowDidLoad()
    {
        window.styleMask = NSBorderlessWindowMask
        window.backgroundColor = NSColor.clearColor()
        window.opaque = false

        window.movable = true
        window.movableByWindowBackground = true
    }

    func update(record:HistoryRecord, processorFactor:ProcessorFactor)
    {
        if let face = faceImage {
            face.update(record, processorFactor:processorFactor)
            imageView.image = face.image
            imageView.needsDisplay = true
            window.invalidateShadow()
        }
    }
}
