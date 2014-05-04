//
//  CustomDrawView.h
//  MacFace
//
//  Created by rryu on Thu Jan 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CustomDrawView : NSView
{
    id delegate;
    SEL drawSelector; 
}

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (SEL)drawSelector;
- (void)setDrawSelector:(SEL)aSelector;

@end
