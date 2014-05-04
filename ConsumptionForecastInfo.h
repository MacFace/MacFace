//
//  ConsumptionForecastInfo.h
//  MacFace
//
//  Created by rryu on 06/02/19.
//  Copyright 2006 rryu. All rights reserved.
//  $Id: ConsumptionForecastInfo.h 37 2006-02-25 20:04:09Z rryu $
//

#import <Cocoa/Cocoa.h>
#import "DiskHistory.h"

typedef struct {
    int pos;
    FSSize size;
} EnvelopePoint;

@interface ConsumptionForecastInfo : NSObject {
	EnvelopePoint *envelopePointList;
	int envelopePointCountMax;
	int envelopePointCount;
    double consumeRate;
    double remainDay;
}

- (id)initWithDiskHistory:(DiskHistory*)diskHistory;
+ (id)consumptionForecastInfoWithDiskHistory:(DiskHistory*)diskHistory;

- (double)consumeRate;
- (double)remainDay;
- (int)envelopePointCount;
- (EnvelopePoint)envelopePointAt:(int)index;

@end
