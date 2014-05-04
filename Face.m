//
//  Face.m
//  face
//
//  Created by rryu on Wed Apr 17 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Face.h"

@implementation Face
/*
struct face_definition {
    @defs(FaceDef);
};
*/
- (id)initWithDefinition:(FaceDef*)def
{
    [super init];
    faceDef = [def retain];
    activity = 0;
    health = 0;
    image = [[NSImage alloc] initWithSize:NSMakeSize(128,128)];
    return self;
}

- (void)dealloc
{
    [faceDef release];
    [image release];
    if (pageoutDate != nil) [pageoutDate release];
    [super dealloc];
}

- (int)activity { return activity; }
- (int)health { return health; }
- (NSImage*)image { return image; }

- (FaceDef*)definition
{
    return faceDef;
}

- (void)setDefinition:(FaceDef*)definition
{
    [faceDef autorelease];
    faceDef = [definition retain];

    [image lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0,0,128,128));
    [faceDef drawImageOfRow:health col:activity marker:marker atPoint:NSMakePoint(0,0)];
    [image unlockFocus];
}

- (void)update:(const HostStatistics*)stats
{
	const MemoryStats *memStats;
    const ProcessorStats *procStats;

	memStats = [stats memoryStatsIndexAt:0];
	procStats = [stats totalProcessorUsageIndexAt:0];
	
	activity = (int)(100 - procStats->usage.idle) / 10;
    pageout = pageout*0.97 + memStats->pageoutDelta;

    if (memStats->pageoutDelta > 0) {
        if (pageoutDate != nil) [pageoutDate release];
        pageoutDate = [[NSDate alloc] init];
    }

    if (pageout > 40) {
        health = 2;
    } else if (pageoutDate && [pageoutDate timeIntervalSinceNow] > -15.0*60){
        health = 1;
    } else {
        health = 0;
    }

    marker = 0;
    if (memStats->pageoutDelta) {
        marker |= FDMARKER_PAGEOUT;
    }
    if (memStats->pageinDelta) {
        marker |= FDMARKER_PAGEIN;
    }

    [image lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0,0,128,128));
    [faceDef drawImageOfRow:health col:activity marker:marker atPoint:NSMakePoint(0,0)];
    [image unlockFocus];
}

@end
