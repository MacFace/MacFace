//
//  DiskHistory.h
//  MacFace
//
//  Created by rryu on Sat Jan 18 2003.
//  Copyright (c) 2003-2006 rryu. All rights reserved.
//  $Id: DiskHistory.h 48 2006-06-03 10:01:58Z rryu $
//

#import <Cocoa/Cocoa.h>

typedef long long FSSize;

@class ConsumptionForecastInfo;

@interface DiskHistory : NSObject
{
    NSString *path;
    FSSize *history;
    unsigned count;
    unsigned capacity;
    FSSize maxFreeSize;
    FSSize minFreeSize;
    NSDate *lastCheckDate;

	int preferredUnit;
}

- (id)initWithPath:(NSString*)aPath capacity:(unsigned)aCapacity;
- (id)initWithPath:(NSString*)aPath capacity:(unsigned)aCapacity dictionaryRepresentation:(NSDictionary*)dict;

- (BOOL)update;

- (NSDictionary*)dictionaryRepresentation;

- (NSString*)path;
- (unsigned)count;
- (unsigned)capacity;
- (FSSize)freeSizeAtIndex:(unsigned)index;
- (FSSize)currentFreeSize;
- (FSSize)maxFreeSize;
- (FSSize)minFreeSize;

- (int)preferredUnit;
- (int)preferredIntPartDigit;
- (int)preferredFractionDigit;

- (int)unitOfSize:(FSSize)size;
- (int)intPartDigitOfSize:(FSSize)size byUnit:(int)unit;
- (int)fractionDigittOfSize:(FSSize)size byUnit:(int)unit;
- (float)unitValueOfSize:(FSSize)size byUnit:(int)unit;
- (FSSize)sizeOfUnitValue:(float)value byUnit:(int)unit;
- (FSSize)unitSizeByUnit:(int)unit;
- (NSString*)symbolStringByUnit:(int)unit;

- (ConsumptionForecastInfo*)calculateConsumptionForcast;

@end
