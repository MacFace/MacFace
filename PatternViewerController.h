//
//  PatternViewerController.h
//  MacFace
//
//  Created by rryu on Sun Apr 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PlacardScrollView.h"
#import "FaceDef.h"

@interface PatternViewerController : NSObject
{
    IBOutlet NSWindow *window;
    IBOutlet PlacardScrollView *scrollView;
    IBOutlet NSImageView *imageView;
    IBOutlet NSView *magnifyControl;
    IBOutlet NSSlider *magnifySlider;

    float magnify;
    FaceDef *faceDef;
}

- (void)setFaceDef:(FaceDef*)aFaceDef;
- (FaceDef*)faceDef;

- (void)showWindow;
- (void)hideWindow;
- (BOOL)isVisibleWindow;

- (IBAction)magnifyChanged:(id)sender;

- (void)changeImageSize;

- (NSImage*)createPatternImage;

- (IBAction)dumpPatterm:(id)sender;
- (IBAction)dumpTitlePatterm:(id)sender;

@end
