//
//  FlippedClipView.m
//  MacFace
//
//  Created by rryu on Mon Apr 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "FlippedClipView.h"


@implementation FlippedClipView

- (id)initWithClipView:(NSClipView*)clipView
{
    self = [super initWithFrame:[clipView frame]];

    [self setDocumentView:[clipView documentView]];
    [self setDrawsBackground:[clipView drawsBackground]];
    [self setBackgroundColor:[clipView backgroundColor]];

    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

@end
