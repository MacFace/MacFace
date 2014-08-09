//
//  PatternView.swift
//  MacFace2
//
//  Created by rryu on 2014/07/19.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import Foundation
import Cocoa

public class PatternView : NSView
{
    var faceImage : FaceImage?

    public override func drawRect(dirtyRect: NSRect)
    {
        if let f = faceImage {
            f.image.drawAtPoint(NSZeroPoint, fromRect: NSZeroRect, operation: NSCompositingOperation.CompositeSourceOver, fraction: CGFloat(1.0))
        }
    }

    public override func mouseUp(theEvent: NSEvent!)
    {
        if theEvent.clickCount == 2 {
            window?.miniaturize(nil)
        }
    }
}