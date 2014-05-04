//
//  PlacardScrollView.h
//  MacFace
//
//  Created by rryu on Sun Apr 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface PlacardScrollView : NSScrollView
{
    IBOutlet NSView *placard;
}

- (void)setPlacard:(NSView*)inView;
- (NSView*)placard;

@end
