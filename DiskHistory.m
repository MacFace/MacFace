//
//  DiskHistory.m
//  MacFace
//
//  Created by rryu on Sat Jan 18 2003.
//  Copyright (c) 2003-2006 rryu. All rights reserved.
//  $Id: DiskHistory.m 48 2006-06-03 10:01:58Z rryu $
//

#import "DiskHistory.h"
#import "ConsumptionForecastInfo.h"
#include <string.h>	// memmove()
#include <math.h>	// ceil() floor()


@implementation DiskHistory

- (id)initWithPath:(NSString*)aPath capacity:(unsigned)aCapacity
{
    return [self initWithPath:aPath capacity:aCapacity dictionaryRepresentation:nil];
}

- (id)initWithPath:(NSString*)aPath capacity:(unsigned)aCapacity dictionaryRepresentation:(NSDictionary*)dict
{
    NSWorkspace *workspace;
    NSArray *localVolumes;
    NSMutableArray *array;
    NSString *lastCheckDateString;
	FSSize size;
    int offset;
    int i,j;

    [super init];

    workspace = [NSWorkspace sharedWorkspace];
    localVolumes = [workspace mountedLocalVolumePaths];
    if ([localVolumes containsObject:aPath] == NO) {
        [self release];
        return nil;
    }

    history = malloc(sizeof(FSSize) * aCapacity);
    if (history == nil) {
        [self release];
        return nil;
    }

    path = aPath;
    capacity = aCapacity;
    count = 0;
    minFreeSize = 0;
    maxFreeSize = 0;

    if (dict) {
        array = [dict objectForKey:@"History"];
        if (array != nil && [array isKindOfClass:[NSArray class]]) {
            count = [array count];
            offset = (count > capacity) ? count-capacity : 0;
            for (i = offset,j = 0; i < count; i++,j++) {
                history[j] = [[array objectAtIndex:i] longLongValue];
            }
            if (count > capacity) count = capacity;
        }

        lastCheckDateString = [dict objectForKey:@"Last Check Date"];
        if (lastCheckDateString != nil) {
            lastCheckDate = [[NSDate alloc] initWithString:lastCheckDateString];
        } else {
            lastCheckDate = nil;
        }

		maxFreeSize = 0;
		minFreeSize = history[0];
		for (i = 0; i < count; i++) {
			size = history[i];
			if (size > maxFreeSize) maxFreeSize = size;
			if (size < minFreeSize) minFreeSize = size;
		}

		preferredUnit = [self unitOfSize:maxFreeSize];
    }

    return self;
}

- (void)dealloc
{
    free(history);
    [path release];
    [lastCheckDate release];
    [super dealloc];
}


- (BOOL)update
{
    NSDictionary *fsAttr;
    FSSize freeSize;
    NSDate *dateNow;
    double dayOfNow = 0;
    double dayOfLastCheck = 0;

    dateNow = [NSDate date];
    fsAttr = [[NSFileManager defaultManager] fileSystemAttributesAtPath:path];
    freeSize = [[fsAttr objectForKey:NSFileSystemFreeSize] longLongValue];

    if (lastCheckDate != nil) {
        dayOfNow = ceil([dateNow timeIntervalSince1970] / (24*60*60));
        dayOfLastCheck = ceil([lastCheckDate timeIntervalSince1970] / (24*60*60));
        if (dayOfNow != dayOfLastCheck) {
            if (count >= capacity) {
                memmove(history,history+1,(capacity-1)*sizeof(FSSize));
            } else {
                count++;
            }
        }
    } else {
        count++;
    }

    history[count-1] = freeSize;
    [lastCheckDate release];
    lastCheckDate = [dateNow retain];

	if (freeSize > maxFreeSize) maxFreeSize = freeSize;
	if (freeSize < minFreeSize) minFreeSize = freeSize;

	preferredUnit = [self unitOfSize:maxFreeSize];

    return dayOfNow != dayOfLastCheck;
}

- (NSDictionary*)dictionaryRepresentation
{
    NSMutableArray *array;
    int i;

    array = [[[NSMutableArray alloc] initWithCapacity:count] autorelease];
    for (i = 0; i < count; i++) {
        [array addObject:[NSNumber numberWithLongLong:history[i]]];
    }

    return [NSDictionary dictionaryWithObjectsAndKeys:
        array,@"History",
        [lastCheckDate description],@"Last Check Date",
        nil];
}

- (NSString*)path
{
    return path;
}

- (unsigned)count
{
    return count;
}

- (unsigned)capacity
{
    return capacity;
}

- (FSSize)freeSizeAtIndex:(unsigned)index
{
    return history[index];
}

- (FSSize)currentFreeSize
{
    return history[count-1];
}

- (FSSize)maxFreeSize
{
    return maxFreeSize;
}

- (FSSize)minFreeSize
{
    return minFreeSize;
}

- (int)preferredUnit
{
	return preferredUnit;
}

- (int)preferredIntPartDigit
{
	return [self intPartDigitOfSize:maxFreeSize byUnit:preferredUnit];
}

- (int)preferredFractionDigit
{
    return (preferredUnit <= 0) ? 0 : 4 - [self preferredIntPartDigit];
}


- (int)unitOfSize:(FSSize)size
{
    int unit;
    for (unit = 0; (size>>unit) >= (1LL<<10); unit += 10);
    return unit;
}

- (int)intPartDigitOfSize:(FSSize)size byUnit:(int)unit
{
	int value = [self unitValueOfSize:size byUnit:unit];
    int place;
    for (place = 1; value >= 10; value /= 10,place++);
    return place;
}

- (int)fractionDigittOfSize:(FSSize)size byUnit:(int)unit
{
	int digit = [self intPartDigitOfSize:size byUnit:unit];
    return (digit <= 0) ? 0 : 4 - digit;
}

- (float)unitValueOfSize:(FSSize)size byUnit:(int)unit
{
	return (float)(size >> (unit-10)) / (1<<10);
}

- (FSSize)sizeOfUnitValue:(float)value byUnit:(int)unit
{
	return (FSSize)(value * (1LL << unit));
}

- (FSSize)unitSizeByUnit:(int)unit
{
	return 1LL << (unit);
}

- (NSString*)symbolStringByUnit:(int)unit
{
    static NSString *unitSymbols[] = {@"", @"Ki", @"Mi", @"Gi", @"Ti", @"Pi", @"Ei"};
    NSString *symbol;

    if (unit < 7*10) {
        symbol = unitSymbols[unit/10];
    } else {
        symbol = [NSString localizedStringWithFormat:@"E2^%d",unit/10];
    }
    return symbol;
}


- (ConsumptionForecastInfo*)calculateConsumptionForcast
{
	return [ConsumptionForecastInfo consumptionForecastInfoWithDiskHistory:self];
}

@end
