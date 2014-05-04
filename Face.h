//
//  Face.h
//  face
//
//  Created by rryu on Wed Apr 17 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HostStatistics.h"
#import "FaceDef.h"

@interface Face : NSObject
{
    FaceDef *faceDef;
    NSImage *image;
    int health;
    int activity;
    int pageout;
    unsigned marker;
    NSDate *pageoutDate;
}

- (id)initWithDefinition:(FaceDef*)def;

- (int)activity;
- (int)health;
- (NSImage*)image;
- (FaceDef*)definition;
- (void)setDefinition:(FaceDef*)definition;

- (void)update:(const HostStatistics*)stats;

@end
