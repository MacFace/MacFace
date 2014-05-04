//
//  PatternViewerController.m
//  MacFace
//
//  Created by rryu on Sun Apr 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "PatternViewerController.h"
#import "FlippedClipView.h"


@implementation PatternViewerController

- (void)awakeFromNib
{
    NSClipView *clipView;
    FlippedClipView *newClipView;

    // クリップビューのY座標を反転させるために、それ用のビューとすり替える
    clipView = [scrollView contentView];
    newClipView = [[FlippedClipView alloc] initWithClipView:clipView];
    [scrollView setContentView:newClipView];
    [newClipView release];

    magnify = [[NSUserDefaults standardUserDefaults] floatForKey:@"PatternViewer Magnify"];
    if (magnify == 0.0) {
        magnify = [magnifySlider floatValue];
    } else {
        [magnifySlider setFloatValue:magnify];
    }
}

- (void)setFaceDef:(FaceDef*)aFaceDef
{
    [faceDef release];
    faceDef = [aFaceDef retain];

    if ([window isVisible]) {
        [imageView setImage:[self createPatternImage]];
        [self changeImageSize];
    }
}

- (FaceDef*)faceDef
{
    return faceDef;
}

- (BOOL)isVisibleWindow
{
    return [window isVisible];
}

- (void)showWindow
{
    [window makeKeyAndOrderFront:self];
}

- (void)hideWindow
{
    [window orderOut:self];
}

- (void)windowDidBecomeMain:(NSNotification*)aNotification
{
    [imageView setImage:[self createPatternImage]];
    [self changeImageSize];
}

- (void)windowWillClose:(NSNotification*)aNotification
{
    [imageView setImage:nil];
}

- (IBAction)magnifyChanged:(id)sender
{
    magnify = [magnifySlider floatValue];

    [self changeImageSize];
    [scrollView setNeedsDisplay:YES];

    [[NSUserDefaults standardUserDefaults] setFloat:magnify forKey:@"PatternViewer Magnify"];
}

- (void)changeImageSize
{
    NSSize imgSize;
    NSRect maxWindowFrame;

    imgSize = [[imageView image] size];

    imgSize.width *= magnify;
    imgSize.height *= magnify;

    [imageView setFrameSize:imgSize];
 
    maxWindowFrame.size = [NSScrollView frameSizeForContentSize:imgSize hasHorizontalScroller:YES hasVerticalScroller:YES borderType:NSNoBorder];
    
    maxWindowFrame = [NSWindow frameRectForContentRect:maxWindowFrame styleMask:[window styleMask]];
    [window setMaxSize:maxWindowFrame.size];
}

- (NSImage*)createPatternImage
{
    NSImage *img;
    NSSize imgSize;
    NSPoint pos;
    int i,j;
    NSDictionary *attr;
    NSString *str;
    NSSize size;

    if (faceDef == nil) return nil;

    imgSize.width = FACE_IMGW * FACE_COLMAX;
    imgSize.height = FACE_IMGH * FACE_ROWMAX + 14;

    img = [[NSImage alloc] initWithSize:imgSize];

    [img lockFocus];
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(0,0,imgSize.width,imgSize.height));

    attr = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                [NSFont systemFontOfSize:14.0], NSFontAttributeName,
                [NSColor blackColor], NSForegroundColorAttributeName,
                nil];

    for (i = 0; i < FACE_ROWMAX; i++) {
        pos.y = (FACE_ROWMAX-1 - i) * FACE_IMGW;
        for (j = 0; j<FACE_COLMAX; j++) {
            pos.x = j * FACE_IMGW;
            [faceDef drawImageOfRow:i col:j marker:0 atPoint:pos];
        }
    }

    pos.y = imgSize.height - 14;
    for (i = 0; i < FACE_COLMAX-1; i++) {
        str = [NSString stringWithFormat:@"%d-%d%%",i*10,i*10+9];
        size = [str sizeWithAttributes:attr];
        pos.x = i * FACE_IMGW + (FACE_IMGW - size.width) / 2;
        [str drawAtPoint:pos withAttributes:attr];
    }

    str = @"100%";
    size = [str sizeWithAttributes:attr];
    pos.x = i * FACE_IMGW + (FACE_IMGW - size.width) / 2;
    [str drawAtPoint:pos withAttributes:attr];

    [img unlockFocus];

    return [img autorelease];
}

- (IBAction)dumpPatterm:(id)sender
{
    NSString *path;
    path = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/facedump.tiff"];
	[faceDef dumpPattern:path];

//    NSImage *img = [imageView image];
//    [[img TIFFRepresentation] writeToFile:path atomically:NO];
}

- (IBAction)dumpTitlePatterm:(id)sender
{
    NSString *path;
	NSImage *img;
	NSBitmapImageRep *rep;

    img = [[NSImage alloc] initWithSize:FACE_IMGSIZE];
    [img lockFocus];
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(0,0,FACE_IMGSIZE.width,FACE_IMGSIZE.height));
    [[faceDef titleImage] compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];	
    [img unlockFocus];
	
    path = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/title-pattern.png"];	
	rep = [NSBitmapImageRep imageRepWithData: [img TIFFRepresentation]];
	[[rep representationUsingType:NSPNGFileType properties:nil] writeToFile:path atomically:NO];
}

@end
