//
//  CustomDrawView.m
//  MacFace
//
//  Created by rryu on Thu Jan 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CustomDrawView.h"


@implementation CustomDrawView

- (void)drawRect:(NSRect)rect
{
    if (delegate != nil && drawSelector != nil) {
        [delegate performSelector:drawSelector withObject:self];
    }
}

- (id)delegate
{
    return delegate;
}

- (void)setDelegate:(id)aDelegate
{
    [delegate release];
    delegate = [aDelegate retain];
}

- (SEL)drawSelector
{
    return drawSelector;
}

- (void)setDrawSelector:(SEL)aSelector
{
    drawSelector = aSelector;
}

@end
