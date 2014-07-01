//
//  FaceImage.swift
//  MacFace2
//
//  Created by rryu on 2014/06/29.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import Foundation
import Cocoa

class FaceImage
{
    var faceDef : FaceDef
    var image : NSImage
    var health : Int
    var activity : Int
    var pageout : Int
    var marker : MarkerSpecifier
    var pageoutDate : NSDate?

    init(faceDef:FaceDef)
    {
        self.faceDef = faceDef
        self.image = NSImage(size:faceDef.imageSize)
        self.activity = 0
        self.health = 0
        self.pageout = 0
        self.marker = MarkerSpecifier.None
        self.pageoutDate = nil
    }
    
    func changeFaceDef(faceDef:FaceDef)
    {
        self.faceDef = faceDef
        updateImage()
    }
    
    func update(record:HistoryRecord, processorFactor:ProcessorFactor)
    {
        NSLog("\(processorFactor.idle) \(pageout) \(record.pageoutDelta)")
        activity = Int(10 - processorFactor.idle * 10)
        pageout = Int(Double(pageout)*0.97) + record.pageoutDelta;
        
        if (record.pageoutDelta > 0) {
            pageoutDate = NSDate()
        }
        
        if (pageout > 40) {
            health = 2;
        } else if pageoutDate?.timeIntervalSinceNow > -15.0*60 {
            health = 1;
        } else {
            health = 0;
        }
        
        marker = MarkerSpecifier.None;
        if record.pageoutDelta > 0 {
            marker = marker | MarkerSpecifier.Pageout
        }
        if record.pageinDelta > 0 {
            marker = marker | MarkerSpecifier.Pagein
        }

        updateImage()
    }

    func updateImage()
    {
        image.lockFocus()
        NSColor.clearColor().set()
        NSRectFill(faceDef.imageRect)
        faceDef.drawImage(health, col:activity, marker:marker, point:NSZeroPoint)
        image.unlockFocus()
    }
}
