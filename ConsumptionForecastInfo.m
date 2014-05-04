//
//  ConsumptionForecastInfo.m
//  MacFace
//
//  Created by rryu on 06/02/19.
//  Copyright 2006 rryu. All rights reserved.
//  $Id: ConsumptionForecastInfo.m 48 2006-06-03 10:01:58Z rryu $
//

#import "ConsumptionForecastInfo.h"


@implementation ConsumptionForecastInfo

- (id)initWithDiskHistory:(DiskHistory*)diskHistory
{
    int i;
	FSSize val1,val2,val3;
	FSSize range;

	int count = [diskHistory count];

	// 消費履歴が3件以下の場合は予測ができないので残り日数としてマイナスを返す
	if (count < 3) {
		consumeRate = 0;
		remainDay = -1;
		envelopePointCountMax = 0;
		envelopePointCount = 0;
		envelopePointList = malloc(sizeof(EnvelopePoint) * envelopePointCountMax);
		return self;
	}

	// 上側包絡線を求める --------------------------------------------------------
	envelopePointCountMax = count;
	envelopePointCount = 0;
	envelopePointList = malloc(sizeof(EnvelopePoint) * envelopePointCountMax);
    if (envelopePointList == nil) {
        [self release];
        return nil;
    }

	// 同じ値として扱うための閾値を求める
	int unit = [diskHistory preferredUnit];
	int numFractionDigit = [diskHistory preferredFractionDigit];
	range = [diskHistory maxFreeSize] - [diskHistory minFreeSize];
	FSSize th = (1LL << unit);
	for (i = 0; i < numFractionDigit; i++) {
		th /= 10;
	}
    for (; range > th*100; th *= 10);

	envelopePointList[envelopePointCount].pos = 0;
	envelopePointList[envelopePointCount].size = [diskHistory freeSizeAtIndex:0];
	envelopePointCount++;

    for (i = 1; i < count-1; i++){
        val1 = [diskHistory freeSizeAtIndex:i-1];
        val2 = [diskHistory freeSizeAtIndex:i  ];
        val3 = [diskHistory freeSizeAtIndex:i+1];

        if ((val1 - val2 <= th && val2 - val3 > th) ||	// 右エッジ
		    (val3 - val2 <= th && val2 - val1 > th)) {	// 左エッジ
			envelopePointList[envelopePointCount].pos = i;
			envelopePointList[envelopePointCount].size = val2;
			envelopePointCount++;
		}
    }

	envelopePointList[envelopePointCount].pos = i;
	envelopePointList[envelopePointCount].size = [diskHistory freeSizeAtIndex:i];
	envelopePointCount++;

	// 消費予測を行う -----------------------------------------------------------
    double sx = 0.0;
	double sy = 0.0;
	double sxy = 0.0;
	double sxx = 0.0;
	int start_pos;
	int end_pos;
	int p_count = 0;
	int pos;

	// 消費率を求める
    for (i = envelopePointCount-2; i >= 0; i--) {
		start_pos = envelopePointList[i].pos+1;
		end_pos = envelopePointList[i+1].pos;
		p_count += end_pos - start_pos + 1;

		// 最小二乗法で消費率を求める
		for (pos = start_pos; pos <= end_pos; pos++) {
			val1 = [diskHistory freeSizeAtIndex:pos];
			sx += pos;
			sy += val1;
			sxy += (double)pos * val1;
			sxx += pos * pos;
		}

		consumeRate = -(p_count*sxy - sx*sy) / (p_count*sxx - sx*sx);

		if (p_count >= 5 && consumeRate > 0.0) break;
	}

	// 残り日数を求める
	if (consumeRate > 0) {
		remainDay = [diskHistory currentFreeSize] / consumeRate;
	} else {
		remainDay = -1;	// 消費率がマイナスの場合は仮にー1としておく
	}

	return self;
}

- (void)dealloc
{
    free(envelopePointList);
    [super dealloc];
}

+ (id)consumptionForecastInfoWithDiskHistory:(DiskHistory*)diskHistory
{
	return [[[ConsumptionForecastInfo alloc] initWithDiskHistory:diskHistory] autorelease];
}

- (double)consumeRate
{
	return consumeRate;
}

- (double)remainDay
{
	return remainDay;
}

- (int)envelopePointCount
{
	return envelopePointCount;
}

- (EnvelopePoint)envelopePointAt:(int)index
{
	return envelopePointList[index];
}

@end
