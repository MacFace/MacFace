//
//  PlacardScrollView.m
//  MacFace
//
//  Created by rryu on Sun Apr 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "PlacardScrollView.h"


@implementation PlacardScrollView

- (void) dealloc
{
    [placard release];
    [super dealloc];
}

- (void)setPlacard:(NSView*)view
{
    [view retain];
    if (placard != nil)
    {
        [placard removeFromSuperview];
        [placard release];
    }
    placard = view;
    [self addSubview:placard];
}

- (NSView*)placard
{
    return placard;
}

- (void)tile
{
    NSScroller *hscroller;
    NSRect hscrollerFrame;
    NSRect placardFrame;

    [super tile];
    if (placard != nil && [self hasHorizontalScroller]) {
        hscroller = [self horizontalScroller];
        hscrollerFrame = [hscroller frame];
        placardFrame = [placard frame];

        placardFrame.origin.x = NSMinX(hscrollerFrame);
        placardFrame.origin.y = hscrollerFrame.origin.y;
        placardFrame.size.height = hscrollerFrame.size.height;
        [placard setFrame:placardFrame];

        hscrollerFrame.size.width -= placardFrame.size.width;
        hscrollerFrame.origin.x = NSMaxX(placardFrame);
        [hscroller setFrame:hscrollerFrame];
    }
}

@end
