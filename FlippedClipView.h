//
//  FlippedClipView.h
//  MacFace
//
//  Created by rryu on Mon Apr 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface FlippedClipView : NSClipView

- (id)initWithClipView:(NSClipView*)clipView;

- (BOOL)isFlipped;

@end
