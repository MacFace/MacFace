//
//  FaceDef.swift
//  MacFace2
//
//  Created by rryu on 2014/06/28.
//  Copyright (c) 2014年 rryu. All rights reserved.
//

import Foundation
import Cocoa

public class PartDef
{
    public var filename : String
    public var image : NSImage
    public var pos : NSPoint

    public init(filename:String, image:NSImage, pos:NSPoint)
    {
        self.filename = filename
        self.image = image
        self.pos = pos
    }
}

typealias PatternDef = Array<Int>

public struct MarkerSpecifier : RawOptionSet {
    var value: UInt = 0
    init(_ value: UInt) { self.value = value }
    public func toRaw() -> UInt { return self.value }
    public func getLogicValue() -> Bool { return self.value != 0 }

    public static func fromRaw(raw: UInt) -> MarkerSpecifier? { return MarkerSpecifier(raw) }
    public static func fromMask(raw: UInt) -> MarkerSpecifier { return MarkerSpecifier(raw) }

    public static func convertFromNilLiteral() -> MarkerSpecifier { return None; }
    
    static var None: MarkerSpecifier  { return MarkerSpecifier(0) }
    static var Pagein: MarkerSpecifier  { return MarkerSpecifier(1 << 0) }
    static var Pageout: MarkerSpecifier { return MarkerSpecifier(1 << 1) }
}

public class FaceDefInfo
{
    public var title : String
    public var author : String
    public var version : String
    public var siteURL : String
    public var titleImage : NSImage

    public init(title:String, author:String, version:String, siteURL:String, titleImage:NSImage)
    {
        self.title = title
        self.author = author
        self.version = version
        self.siteURL = siteURL
        self.titleImage = titleImage
    }
}

let FACE_ROWMAX  = 3
let FACE_COLMAX  = 11

//
let FACE_INFO_TITLE		= "title"
let FACE_INFO_AUTHOR    = "author"
let FACE_INFO_VERSION   = "version"
let FACE_INFO_SITE_URL	= "web site"

let FACE_INFO_PARTS		    = "parts"
let FACE_INFO_PATTERN       = "pattern"
let FACE_INFO_MARKER        = "markers"
let FACE_INFO_TITLE_PATTERN = "title pattern"
let FACE_INFO_MARK_PGOUT	= "pagein pattern"
let FACE_INFO_MARK_PGIN	    = "pageout pattern"

let FACE_PART_IMAGE		= "filename"
let FACE_PART_POSX		= "pos x"
let FACE_PART_POSY		= "pos y"

public class FaceDef
{


    // private properties
    // var definition : Dictionary
/*
    class func infoAtPath(path:String) -> FaceDefInfo
    {
        class func info(definition:NSDictionary) -> FaceDefInfo
        {
            titleImage: definition.objectForKey(FACE_INFO_TITLE_PATTERN) as? Array<Int>
            
            return FaceDefInfo(
                title: definition.objectForKey(FACE_INFO_TITLE) as? String
                author: definition.objectForKey(FACE_INFO_TITLE) as? String
                version: definition.objectForKey(FACE_INFO_TITLE) as? String
            
        }
        
    }
*/

    // public properties (readonly)
    public var packagePath : String
    var parts : [PartDef]
    var patterns : Array<Array<PatternDef>>
    var markers : [Int]
    var titlePattern : PatternDef

    public init(path:String)
    {
        var plistPath = path.stringByAppendingPathComponent("faceDef.plist")
        var definition = NSDictionary(contentsOfFile: plistPath)
        
        packagePath = path
        self.parts = Array<PartDef>()
        
        // パーツ定義の読み込み
        if let partArray = definition.objectForKey(FACE_INFO_PARTS) as? Array<NSDictionary> {
            for partDefDict in partArray {
                let filename = partDefDict.objectForKey(FACE_PART_IMAGE) as String;
                let x = CGFloat(partDefDict.objectForKey(FACE_PART_POSX).doubleValue)
                let y = CGFloat(partDefDict.objectForKey(FACE_PART_POSY).doubleValue)

                let imagePath = path.stringByAppendingPathComponent(filename);
                let image = NSImage(contentsOfFile: imagePath)

                if image == nil { // 画像が読み込めなかった
                    NSException(name: "FaceDefPartLoadException", reason: "failed in loading of image '\(filename)'", userInfo:nil).raise()
                }

                self.parts.append(PartDef(filename: filename, image: image, pos: NSPoint(x: x,y: y)))
            }
        } else {
            NSException(name: "FaceDefPartListLoadException", reason: "failed in reading part list.",userInfo:nil).raise()
        }

        // パターン定義の読み込み
        var maxPartNo = self.parts.count - 1;

        if let patternArray = definition.objectForKey(FACE_INFO_PATTERN) as? Array<Array<PatternDef>> {
            if patternArray.count != FACE_ROWMAX {
                NSException(name:"FaceDefPatternLoadException", reason:"number of pattern rows is not 3", userInfo:nil).raise()
            }

            for var row = 0; row < FACE_ROWMAX; row++ {
                let colArray = patternArray[row]
                
                if colArray.count != FACE_COLMAX {
                    NSException(name:"FaceDefPatternLoadException", reason:"number of pattern columns is not 10 at row \(row)", userInfo:nil).raise()
                }
                
                for var col = 0; col < FACE_COLMAX; col++ {
                    let elemArray = colArray[col]
                    // パーツ番号チェック
                    for var i = 0; i < elemArray.count; i++ {
                        let number = elemArray[i];
                        if 0 > number || number > maxPartNo {
                            NSException(name:"FaceDefPatternLoadException", reason:"illigal part number \(number) in patterns[\(row),\(col),\(i)]", userInfo:nil).raise()
                        }
                    }
                }
            }

            self.patterns = patternArray
        }
        else
        {
            self.patterns = Array<Array<PatternDef>>()
            NSException(name:"FaceDefPatternLoadException", reason:"failed in reading pattern list.", userInfo:nil).raise()
        }
    
        // マーカーリストの読み込み
        if let markerArray = definition.objectForKey(FACE_INFO_MARKER) as? Array<Int> {
            self.markers = markerArray
        }
        else
        {
            self.markers = Array<Int>()
            NSException(name:"FaceDefPatternLoadException", reason:"failed in reading marker list.", userInfo:nil).raise()
        }
        
        // 代表画像パターンの読み込み
        if let titlePartsArray = definition.objectForKey(FACE_INFO_TITLE_PATTERN) as? Array<Int> {
            for number in titlePartsArray {
                if 0 > number || number > maxPartNo {
                    NSException(name:"FaceDefPatternLoadException", reason:"illigal part no \(number) in title pattern", userInfo:nil).raise()
                }
            }
            self.titlePattern = titlePartsArray
        }
        else
        {
            self.titlePattern = PatternDef();
            NSException(name:"FaceDefPatternLoadException", reason:"failed in reading title pattern.", userInfo:nil).raise()
        }
    }


    //@lazy var info : FaceDefInfo = FaceDef.infoAtPath(self.packagePath)

    let imageSize = NSSize(width:128, height:128)
    let imageRect = NSRect(x:0, y:0, width:128, height:128)
    
    public func imageOf(row:Int, col:Int, marker:MarkerSpecifier) -> NSImage
    {
        var image = NSImage(size: imageSize)
        image.lockFocus()
        drawImage(row, col: col, marker: marker, point: NSZeroPoint)
        image.unlockFocus()
        return image
    }

    public func drawImage(row:Int, col:Int, marker:MarkerSpecifier, point:NSPoint)
    {
        for part in patterns[row][col] {
            drawPart(parts[part], point: point)
        }
        
        if marker != MarkerSpecifier.None {
            for var i = 0; i < 8; i++ {
                if marker.toRaw() & UInt(1<<i) != 0 {
                    drawPart(parts[markers[i]], point: point)
                }
            }
        }
    }

    func drawPart(part:PartDef, point:NSPoint)
    {
        var pos = NSPoint(x: point.x + part.pos.x, y: point.y + part.pos.y)
        part.image.drawAtPoint(pos, fromRect: NSZeroRect, operation: NSCompositingOperation.CompositeSourceOver, fraction: CGFloat(1.0))
    }

    public func dumpPattern(path:String)
    {
        var rows = parts.count / FACE_COLMAX + 1;
        var patternSize = self.imageSize

        var offset = CGFloat(rows) * patternSize.width + 10.0;
        var imageSize = NSSize(width:patternSize.width * CGFloat(FACE_COLMAX), height:patternSize.height * CGFloat(FACE_ROWMAX) + offset + 14)

        var img = NSImage(size:imageSize)
        if img == nil {
            NSLog("failure dump pattern!")
            return;
        }
        
        img.lockFocus()

        NSColor.whiteColor().set()
        NSRectFill(NSRect(x:0, y:0, width:imageSize.width, height:imageSize.height))
        
        NSColor.blackColor().set()
        NSRectFill(NSRect(x:0, y: offset - 6, width:imageSize.width, height:2))

        var attr = [
            NSFontAttributeName: NSFont.systemFontOfSize(14.0),
            NSForegroundColorAttributeName: NSColor.blackColor(),
        ]
        
        for var i = 0; i < parts.count; i++ {
            var x = CGFloat(i % FACE_COLMAX) * patternSize.width
            var y = CGFloat(rows-1 - i / FACE_COLMAX) * patternSize.height
            drawPart(parts[i], point:NSPoint(x:x, y:y))

            NSColor.lightGrayColor().set()
            NSFrameRect(NSRect(x:x, y:y, width:patternSize.width, height:patternSize.height))
            
            NSColor.blackColor().set()
            var str = NSString(format:"%d", i)
            x = CGFloat(i % FACE_COLMAX) * patternSize.width
            y = CGFloat(rows-1 - i / FACE_COLMAX) * patternSize.height + patternSize.height - 12
            str.drawAtPoint(NSPoint(x:x, y:y), withAttributes:attr)
        }
        
        for var i = 0; i < FACE_ROWMAX; i++ {
            let y = CGFloat(FACE_ROWMAX-1 - i) * patternSize.height + offset
            for var j=0; j<FACE_COLMAX; j++ {
                let x = CGFloat(j) * patternSize.width;
                drawImage(i, col:j, marker:MarkerSpecifier.None, point:NSPoint(x:x, y:y))
            }
        }
        
        var y = imageSize.height - 14
        for var i = 0; i < FACE_COLMAX-1; i++ {
            var str = NSString(format:"%d-%d%%", i*10, (i+1)*10-1)
            var x = CGFloat(i) * patternSize.width;
            str.drawAtPoint(NSPoint(x:x, y:y), withAttributes:attr)
        }
        var str = NSString(format:"%d%%", 100)
        var x = CGFloat(FACE_COLMAX-1) * patternSize.width
        str.drawAtPoint(NSPoint(x:x, y:y), withAttributes:attr)
        
        img.unlockFocus()
        
        img.TIFFRepresentation.writeToFile(path, atomically:false)
    }

}
