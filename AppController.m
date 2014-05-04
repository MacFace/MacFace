//
//  AppController.m
//  MacFace
//
//  Created by rryu on Wed Apr 17 2002.
//  Copyright (c) 2001-2006 rryu. All rights reserved.
//  $Id: AppController.m 57 2011-01-02 15:55:59Z rryu $
//

#import "AppController.h"
#import "ConsumptionForecastInfo.h"
#import "Preferences.h"
#include <math.h>

#define HISTORY_MAX 61
#define GPOINT	5
#define GWIDTH  ((HISTORY_MAX-1)*GPOINT)
#define GHEIGHT 100
#define GLEFT	1
#define GBOTTOM 1

NSString *ticksToString(unsigned long ticks)
{
    return [NSString stringWithFormat:@"%3d:%02d:%02d:%02d",
         ticks / (24*60*60*100),
        (ticks / (60*60*100)) % 24,
        (ticks / (60*100)) % 60,
        (ticks / (100)) % 60];
}


@implementation AppController

/*
  アプリケーション初期化
*/
- (void)awakeFromNib
{
    Preferences *prefs = [Preferences sharedInstance];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    CustomDrawView *diskGraphView;

    // 顏パターンのセットアップ
    faceObj = [[Face alloc] initWithDefinition:[prefs faceDef]];

    // ホストステータス情報の準備
    hostHistory = [[HostStatistics alloc] initWithCapacity:HISTORY_MAX];

    // ディスク消費履歴の準備
    diskHistory = [[DiskHistory alloc] initWithPath:@"/" capacity:70
            dictionaryRepresentation:[prefs diskHistoryForMountPoint:@"/"]];

    // GUIセットアップ ---------------------------------------------

	// ステータスウインドウ
    [statusWindow setLevel:NSNormalWindowLevel];
    [statusWindow setHidesOnDeactivate:NO];
	[statusWindow setExcludedFromWindowsMenu:NO];
    [center addObserver:self selector:@selector(statusWindowWillClose:)
        name:NSWindowWillCloseNotification object:statusWindow];

    [memoryInfoView setIntercellSpacing:NSMakeSize(1,3)];
    [cpuInfoView setIntercellSpacing:NSMakeSize(1,3)];
    [memoryGraphView setDelegate:self];
    [memoryGraphView setDrawSelector:@selector(drawMemoryGraph:)];
    [cpuGraphView setDelegate:self];
    [cpuGraphView setDrawSelector:@selector(drawCPUGraph:)];

	if ([prefs visiblityForWindow:statusWindow] == YES) {
		[self showStatusWindow:self];
	} else {
		[self hideStatusWindow:self];
	}

    // ディスク消費グラフウインドウ
    [diskGraphWindow setLevel:NSNormalWindowLevel];
    [diskGraphWindow setHidesOnDeactivate:NO];
	[diskGraphWindow setExcludedFromWindowsMenu:NO];
    [center addObserver:self selector:@selector(diskGraphWindowWillClose:)
        name:NSWindowWillCloseNotification object:diskGraphWindow];

    diskGraphView = [diskGraphWindow contentView];
    [diskGraphView setDelegate:self];
    [diskGraphView setDrawSelector:@selector(drawDiskGraph:)];

	if ([prefs visiblityForWindow:diskGraphWindow] == YES) {
		[self showDiskGraphWindow:self];
	} else {
		[self hideDiskGraphWindow:self];
	}

	// パターンウインドウ
	patternWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0.0F, 0.0F, 128.0F, 128.0F)
									  styleMask:NSBorderlessWindowMask
									  backing:NSBackingStoreBuffered defer:YES];


    // アプリケーション
    [center addObserver:self selector:@selector(faceDefChanged:)
        name:NOTIFY_FACEDEF_CHANGED object:nil];

    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
        target:self selector:@selector(updateStatus:)
        userInfo:nil repeats:TRUE];

    [self updateDiskHistory:nil];
    diskCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1*60.0
        target:self selector:@selector(updateDiskHistory:)
        userInfo:nil repeats:TRUE];
}

/*
  アプリケーションの終了処理
*/
- (void)applicationWillTerminate:(NSNotification*)aNotification 
{
    [refreshTimer invalidate];
    [diskCheckTimer invalidate];

    if (diskHistory != nil) {
        [[Preferences sharedInstance] setDiskHistory:diskHistory forMountPoint:@"/"];
    }

    [faceObj release];
    [hostHistory release];
    [diskHistory release];

    [NSApp setApplicationIconImage:[NSImage imageNamed:@"appIcon.icns"]];
}


/*
  書類を開く
*/
- (BOOL)application:(NSApplication*)theApplication openFile:(NSString*)filename
{
    Preferences *prefs = [Preferences sharedInstance];
    FaceDef *faceDef;
    NSFileManager *manager;
    NSString *displayName;

    manager = [NSFileManager defaultManager];
    displayName = [manager displayNameAtPath:filename];

    if ([manager fileExistsAtPath:filename] == NO) {
        NSRunAlertPanel(
            NSLocalizedString(@"FileMissing Message",@""),
            NSLocalizedString(@"FileMissing Info",@""),
            NSLocalizedString(@"OK",@""),nil,nil,
            displayName
        );
        return NO;
    }

    faceDef = [FaceDef faceDefWithContentOfFile:filename];

    if (faceDef == nil) {
        NSRunAlertPanel(
            NSLocalizedString(@"OpenErr Message",@""),
            NSLocalizedString(@"OpenErr Info",@""),
            NSLocalizedString(@"OK",@""),nil,nil,
            displayName
        );
        return NO;
    }

    [prefs setCustomFaceDef:faceDef];

    [faceObj setDefinition:[prefs faceDef]];

    [NSApp setApplicationIconImage:[faceObj image]];

    return YES;
}

- (HostStatistics*)hostHistory
{
    return hostHistory;
}
- (DiskHistory*)diskHistory
{
    return diskHistory;
}

- (Face*)faceObject
{
    return faceObj;
}

- (void)faceDefChanged:(NSNotification*)aNotification
{
    Preferences *prefs = [Preferences sharedInstance];

    [faceObj setDefinition:[prefs faceDef]];

    [NSApp setApplicationIconImage:[faceObj image]];
}

- (void)updateStatus:(NSTimer*)timer
{

    [hostHistory update];
    [faceObj update:hostHistory];

    [NSApp setApplicationIconImage:[faceObj image]];
    if ([statusWindow isVisible]) [self refreshStatusWindow];
}

- (void)updateDiskHistory:(NSTimer*)timer
{
    BOOL isUpdate;

    isUpdate = [diskHistory update];

    if (isUpdate) [[Preferences sharedInstance] setDiskHistory:diskHistory forMountPoint:@"/"];
    if ([diskGraphWindow isVisible]) [self refreshDiskGraphWindow];
}

- (void)refreshStatusWindow
{
	const MemoryStats *memStats;
    const ProcessorStats *procStats;
    double pageSize;
    unsigned long totalTicks;
		
    [memoryGraphView setNeedsDisplay:YES];
    [cpuGraphView setNeedsDisplay:YES];

	memStats = [hostHistory memoryStatsIndexAt:0];
	procStats = [hostHistory totalProcessorUsageIndexAt:0];
    pageSize = (double)[hostHistory pageSize] / (1<<30) * 1000;

    [[memoryInfoView cellAtIndex:0]
        setStringValue:[NSString localizedStringWithFormat:@"%.2fMiB",memStats->wirePages * pageSize]];
    [[memoryInfoView cellAtIndex:1]
        setStringValue:[NSString localizedStringWithFormat:@"%.2fMiB",memStats->activePages * pageSize]];
    [[memoryInfoView cellAtIndex:2]
        setStringValue:[NSString localizedStringWithFormat:@"%.2fMiB",memStats->inactivePages * pageSize]];
    [[memoryInfoView cellAtIndex:3]
        setStringValue:[NSString localizedStringWithFormat:@"%.2fMiB",memStats->freePages * pageSize]];
    [[memoryInfoView cellAtIndex:4]
        setStringValue:[NSString localizedStringWithFormat:@"%d",memStats->pageins]];
    [[memoryInfoView cellAtIndex:5]
        setStringValue:[NSString localizedStringWithFormat:@"%d",memStats->pageouts]];

    totalTicks = procStats->ticks.user + procStats->ticks.system + procStats->ticks.nice + procStats->ticks.idle;

    [[cpuInfoView cellAtIndex:0]
        setStringValue:ticksToString(procStats->ticks.user)];
    [[cpuInfoView cellAtIndex:1]
        setStringValue:ticksToString(procStats->ticks.system)];
    [[cpuInfoView cellAtIndex:2]
        setStringValue:ticksToString(procStats->ticks.nice)];
    [[cpuInfoView cellAtIndex:3]
        setStringValue:ticksToString(procStats->ticks.idle)];
    [[cpuInfoView cellAtIndex:4]
        setStringValue:ticksToString(totalTicks)];
}

- (void)refreshDiskGraphWindow
{
    [[diskGraphWindow contentView] setNeedsDisplay:YES];
}

- (void)drawMemoryGraph:(CustomDrawView*)aView
{
	const MemoryStats *memStats;
    NSColor *wireColor,*activeColor,*inactiveColor,*freeColor;
    NSColor *pageinColor,*pageoutColor;
    int i,len;
    float scale;
    NSRect rect;

    wireColor = [[NSColor redColor] colorWithAlphaComponent:0.6];
    activeColor = [[NSColor orangeColor] colorWithAlphaComponent:0.6];
    inactiveColor = [NSColor colorWithDeviceRed:255/255.0 green:167/255.0 blue:78/255.0 alpha:0.6];
    freeColor = [[NSColor blueColor] colorWithAlphaComponent:0.6];
    pageinColor = [NSColor whiteColor];
    pageoutColor = [NSColor darkGrayColor];

    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(GLEFT,GBOTTOM,GWIDTH,GHEIGHT));

    len = [hostHistory length];
    if (len > HISTORY_MAX-1) len--;

    scale = (float)GHEIGHT / [hostHistory totalPages];

    [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
    rect.origin.x = GLEFT;
    rect.origin.y = GBOTTOM;
    rect.size.width = GWIDTH;
    rect.size.height = 1;
    while (rect.origin.y < GBOTTOM+GHEIGHT) {
        NSFrameRect(rect);
        rect.origin.y += GHEIGHT/10;
    }

    for (i = 0; i < len; i++){
		memStats = [hostHistory memoryStatsIndexAt:i];

        rect.origin.x = GLEFT + GWIDTH - i*GPOINT - GPOINT;
        rect.size.width = GPOINT;

        rect.origin.y = GBOTTOM;
        rect.size.height = memStats->wirePages * scale;
        [wireColor set];
        [NSBezierPath fillRect:rect];

        rect.origin.y += rect.size.height;
        rect.size.height = memStats->activePages * scale;
        [activeColor set];
        [NSBezierPath fillRect:rect];

        rect.origin.y += rect.size.height;
        rect.size.height = memStats->inactivePages * scale;
        [inactiveColor set];
        [NSBezierPath fillRect:rect];

        rect.origin.y += rect.size.height;
        rect.size.height = GBOTTOM + GHEIGHT - rect.origin.y;
        [freeColor set];
        [NSBezierPath fillRect:rect];

        rect.origin.x = GLEFT + GWIDTH - i*GPOINT - GPOINT;
        rect.size.width = 2;
        rect.origin.y = GBOTTOM;
        rect.size.height = memStats->pageinDelta;
        [pageinColor set];
        [NSBezierPath fillRect:rect];

        rect.origin.x = GLEFT + GWIDTH - i*GPOINT - (GPOINT-2);
        rect.size.height = memStats->pageoutDelta;
        [pageoutColor set];
        [NSBezierPath fillRect:rect];
    }
    [[NSColor blackColor] set];
    NSFrameRect(NSMakeRect(GLEFT-1,GBOTTOM-1,GWIDTH+2,GHEIGHT+2));
}

- (void)drawCPUGraph:(CustomDrawView*)aView
{
    const ProcessorStats *procStats;
    NSBezierPath *userGraph,*systemGraph;
    int i,len;
    NSRect rect;
    NSPoint pt;

    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(GLEFT,GBOTTOM,GWIDTH,GHEIGHT));

    [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
    rect.origin.x = GLEFT;
    rect.origin.y = GBOTTOM;
    rect.size.width = GWIDTH;
    rect.size.height = 1;
    while (rect.origin.y < GBOTTOM+GHEIGHT) {
        NSFrameRect(rect);
        rect.origin.y += GHEIGHT/10;
    }

    [[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] set];
    rect.origin.y = GBOTTOM + GHEIGHT/2;
    NSFrameRect(rect);

    len = [hostHistory length];

    userGraph = [NSBezierPath bezierPath];
    systemGraph = [NSBezierPath bezierPath];

    [userGraph moveToPoint:NSMakePoint(GWIDTH-(len-1)*GPOINT+1,0)];
    [userGraph lineToPoint:NSMakePoint(GWIDTH+10,0)];
    [systemGraph moveToPoint:NSMakePoint(GWIDTH-(len-1)*GPOINT+1,0)];
    [systemGraph lineToPoint:NSMakePoint(GWIDTH+2,0)];

    for (i = 0; i < len; i++){
		procStats = [hostHistory totalProcessorUsageIndexAt:i];
        pt.x = GWIDTH - i*GPOINT + GLEFT;
        pt.y = procStats->usage.system + GBOTTOM;
        [systemGraph lineToPoint:pt];
        pt.y += procStats->usage.user + procStats->usage.nice;
        [userGraph lineToPoint:pt];
    }

    [[[NSColor blueColor] colorWithAlphaComponent:0.2] set];
    [userGraph fill];
    [[[NSColor redColor] colorWithAlphaComponent:0.2] set];
    [systemGraph fill];

    [[NSColor blueColor] set];
    [userGraph setLineWidth:1.0];
    [userGraph stroke];

    [[NSColor blackColor] set];
    NSFrameRect(NSMakeRect(GLEFT-1,GBOTTOM-1,GWIDTH+2,GHEIGHT+2));
}

//
// ディスク消費グラフを描画する
//
- (void)drawDiskGraph:(CustomDrawView*)aView
{
    unsigned count;
    FSSize min,max;
    int unit;
    int numFractionDigit;
    float mark;
    float upperLimit, lowerLimit;
    float range;
    float scale;
    float val;
    float gleft, gbottom, gwidth, gheight;
    NSColor *barColor, *ruleColor, *ruleRevColor;
    NSDictionary *attr;
    NSString *unitSymbol;
    NSString *str;
    NSRect rect;
    NSSize strSize;
    NSPoint pt;
    NSRect frame;
    
    int i;
    float f;

    count = [diskHistory count];
    min = [diskHistory minFreeSize];
    max = [diskHistory maxFreeSize];
    unit = [diskHistory preferredUnit];
    numFractionDigit = [diskHistory preferredFractionDigit];

    mark = pow(0.1, numFractionDigit);
    val = [diskHistory unitValueOfSize:max-min byUnit:unit];
    for (; val > mark*10; mark *= 10,numFractionDigit--);
    if ( numFractionDigit < 0) numFractionDigit = 0;

    val = [diskHistory unitValueOfSize:max byUnit:unit];
    upperLimit = ceil(val / mark + 0.5) * mark;
    val = [diskHistory unitValueOfSize:min byUnit:unit];
    lowerLimit = floor(val / mark - 0.5) * mark;
    if (lowerLimit < 0.0) lowerLimit = 0;

    range = upperLimit - lowerLimit;

    rect = [aView bounds];
    gleft = 64;
    gbottom = 6;
    gwidth = rect.size.width - gleft - 4;
    gheight = rect.size.height - gbottom - 4;
    frame = NSMakeRect(gleft,gbottom,gwidth,gheight);

    scale = gheight / range;

    // グラフ関係の色の設定
    barColor = [NSColor colorWithCalibratedRed:0.05 green:0 blue:0.60 alpha:1.0];
    ruleRevColor = [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:1 alpha:1];
    ruleColor = [NSColor colorWithCalibratedWhite:0.60 alpha:1.0];
    attr = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSFont labelFontOfSize:11.0],NSFontAttributeName,
                [NSColor blackColor],NSForegroundColorAttributeName,
                nil];

	// グラフの背景を描画する ----------------------------------------------------

    // 背景を白で塗りつぶす
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(gleft,gbottom,gwidth,gheight));

    // 目盛りを描画する
    unitSymbol = [diskHistory symbolStringByUnit:unit];
    rect.origin.x = gleft - 6;
    rect.size.width = gwidth + 6;
    rect.size.height = 1;
    for (f = 0; f < range; f += mark) {
        rect.origin.y = floor(gbottom-1 + f * scale);
        str = [NSString localizedStringWithFormat:@"%.*f%@B"
                                        ,numFractionDigit,f + lowerLimit,unitSymbol];
        strSize = [str sizeWithAttributes:attr];
		if (rect.origin.y >= gbottom + gheight - strSize.height) continue;
		// 目盛りの線を描く
		[ruleColor set];
        NSRectFill(rect);
		// 目盛りのラベルを描画する
        pt.x = rect.origin.x - 2 - strSize.width;
        pt.y = rect.origin.y;
        [str drawAtPoint:pt withAttributes:attr];
    }

    // 左側の枠線を引く
    [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] set];
    NSFrameRect(NSMakeRect(gleft-2,gbottom-1,2,gheight+1));
	// グラフの下限が0であれば下側の枠線を引く
    if (lowerLimit == 0.0) {
        NSFrameRect(NSMakeRect(gleft-6,gbottom-2,gwidth+6,2));
    }

    // グラフ本体を描画する ------------------------------------------------------

    for (i = 0; i < count; i++){
        val = [diskHistory unitValueOfSize:[diskHistory freeSizeAtIndex:i] byUnit:unit] - lowerLimit;
        rect.origin.x = gleft + i * 5 + 1;
        rect.origin.y = gbottom;
        rect.size.width = 4;
        rect.size.height = val * scale;

        [barColor set];
        NSRectFill(rect);

        rect.size.width = 4;
        rect.size.height = 1;
        [ruleRevColor set];
        for (f = mark; f < val; f += mark) {
            rect.origin.y = floor(gbottom-1 + f * scale);
            NSRectFill(rect);
        }
    }

    // 消費予測情報を描く
    if (count >= 7) {
        [self drawPredictInfoWithFrame:frame unit:unit scale:scale lowerLimit:lowerLimit];
    }

    // 最新の空き容量を指示線付きで描く
    pt.x = floor(gleft + count*5 + 1);
    pt.y = floor(gbottom + ([diskHistory unitValueOfSize:[diskHistory currentFreeSize] byUnit:unit] - lowerLimit) * scale);
    [self drawCurrentDiskSizeAtPoint:pt frame:frame];
}

//
//  消費予測情報を描く
//
- (void)drawPredictInfoWithFrame:(NSRect)frame unit:(int)unit scale:(float)scale lowerLimit:(float)lowerLimit
{
    double remainDay;
    double consumeRate;
    double consumeRateByUnit;
    int consumeRateUnit;
    NSDictionary *attr;
    NSString *label;
    NSSize labelSize;
    NSBezierPath *line;
    const static float dashPattern[] = {2.0,3.0};
    NSPoint pt;
	int i;

	ConsumptionForecastInfo* info = [diskHistory calculateConsumptionForcast];

    // これまでの消費を示す包絡線を引く ------------------------------------------------------
	float val;
	EnvelopePoint ept;

    line = [NSBezierPath bezierPath];

	// 始点に移動する
	ept = [info envelopePointAt:0];
    val = ([diskHistory unitValueOfSize:ept.size byUnit:unit] - lowerLimit) * scale;
    pt.x = frame.origin.x + ept.pos * 5 + 3;
    pt.y = frame.origin.y + val;
	[line moveToPoint:pt];

	// 
	int envelopePointCount = [info envelopePointCount];
    for (i = 1; i < envelopePointCount; i++) {
		ept = [info envelopePointAt:i];
		val = ([diskHistory unitValueOfSize:ept.size byUnit:unit] - lowerLimit) * scale;
		pt.x = frame.origin.x + ept.pos * 5 + 3;
		pt.y = frame.origin.y + val;
		[line lineToPoint:pt];
	}

    [line setLineWidth:3.0];
	[[[NSColor redColor] colorWithAlphaComponent:0.5] set];
    [line stroke];


    // 未来の予測直線を引く ---------------------------------------------------------------
    consumeRate = [info consumeRate];
	FSSize sizeFrom = [diskHistory currentFreeSize];
	FSSize sizeTo = sizeFrom - (FSSize)(consumeRate * 13);
	NSPoint ptFrom;
	NSPoint ptTo;

	// 始点を計算する
    val = ([diskHistory unitValueOfSize:sizeFrom byUnit:unit] - lowerLimit) * scale;
    ptFrom.x = frame.origin.x + ept.pos * 5 + 3;
    ptFrom.y = frame.origin.y + val;

	// 終点を計算する
	val = ([diskHistory unitValueOfSize:sizeTo byUnit:unit] - lowerLimit) * scale;

	if (val >= 0) {
		ptTo.x = frame.origin.x + ([diskHistory count]+13) * 5 + 3;
		ptTo.y = frame.origin.y + val;
	} else {
		sizeTo = [diskHistory sizeOfUnitValue:lowerLimit byUnit:unit];
		ptTo.x = frame.origin.x + ([diskHistory count] + (sizeFrom - sizeTo) / consumeRate) * 5 + 3;
		ptTo.y = frame.origin.y + 0;
	}

	// 矢印をX軸に沿った形で作り、それを目的の位置と傾きに移動・回転させて描画する
	float len = sqrt((ptTo.x-ptFrom.x)*(ptTo.x-ptFrom.x) + (ptTo.y-ptFrom.y)*(ptTo.y-ptFrom.y));

    line = [NSBezierPath bezierPath];
	[line moveToPoint:NSMakePoint(0.0, 0.0)];
	[line lineToPoint:NSMakePoint(len - 12, 0.0)];
    [line setLineWidth:1.5];
    [line setLineDash:dashPattern count:2 phase:0.0];

    NSBezierPath *arrow = [NSBezierPath bezierPath];
    [arrow moveToPoint:NSMakePoint(len, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(-12.0, 4.0)];
    [arrow relativeLineToPoint:NSMakePoint(0.0, -8.0)];
    [arrow closePath];

    double theta = atan2(ptTo.y - ptFrom.y, ptTo.x - ptFrom.x);
	NSAffineTransform *t = [NSAffineTransform transform];
	[t translateXBy:ptFrom.x yBy:ptFrom.y];
	[t rotateByRadians:theta];

	[line transformUsingAffineTransform:t];
	[arrow transformUsingAffineTransform:t];

	[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
    [arrow fill];

    [arrow setLineWidth:1.0];
	[[[NSColor redColor] colorWithAlphaComponent:0.8] set];
    [arrow stroke];

	[[[NSColor redColor] colorWithAlphaComponent:0.8] set];
    [line stroke];

    // 残り日数の描画 --------------------------------------------------------------------
    if (consumeRate > 0) {
        remainDay = [info remainDay];
        consumeRateUnit = [diskHistory unitOfSize:(FSSize)consumeRate];
		consumeRateByUnit = consumeRate / [diskHistory unitSizeByUnit:consumeRateUnit];

        attr = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSFont labelFontOfSize:11.0], NSFontAttributeName,
                    [NSColor blackColor], NSForegroundColorAttributeName,
                    nil];

        label = [NSString localizedStringWithFormat:NSLocalizedString(@"GDF_REST",@"")
                    ,remainDay, consumeRateByUnit, [diskHistory symbolStringByUnit:consumeRateUnit]];
        labelSize = [label sizeWithAttributes:attr];

        pt.x = NSMaxX(frame) - labelSize.width - 2;
        pt.y = NSMaxY(frame) - labelSize.height - 2;
        [label drawAtPoint:pt withAttributes:attr];
    }
}

/*
  最新の空き容量を指示線付きで描く
*/
- (void)drawCurrentDiskSizeAtPoint:(NSPoint)pt frame:(NSRect)frame
{
	FSSize size;
    int unit;
    int numFractionDigit;
	float val;
    NSDictionary *attr;
    NSString *label;
    NSSize labelSize;
    NSPoint labelPos;
    NSBezierPath *line;
    NSPoint points[3];

	size = [diskHistory currentFreeSize];
    unit = [diskHistory unitOfSize:size];
    numFractionDigit = [diskHistory fractionDigittOfSize:size byUnit:unit];

    val = [diskHistory unitValueOfSize:size byUnit:unit];

    // ラベル文字列の作成
    attr = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSFont labelFontOfSize:11.0],NSFontAttributeName,
                [NSColor blackColor],NSForegroundColorAttributeName,
                nil];
    label = [NSString localizedStringWithFormat:@"%.*f%@B",
                            numFractionDigit, val, [diskHistory symbolStringByUnit:unit]];

    // 引き出し線やラベル描画位置の座標の計算
    labelSize = [label sizeWithAttributes:attr];

    points[0] = pt;

    points[1].x = points[0].x + 10;
    points[1].y = points[0].y + 10;
    labelPos.x = points[1].x + 6;
    labelPos.y = points[1].y;
    if (points[1].y + labelSize.height*3 > NSMaxY(frame)) {
        points[1].y = points[0].y - 10;
        labelPos.y = points[1].y - labelSize.height;
    }

    points[2].x = points[1].x + labelSize.width + 8;
    points[2].y = points[1].y;

    // 描画
    line = [NSBezierPath bezierPath];
    [line appendBezierPathWithPoints:points count:3];
    [line setLineWidth:1.0];
    [[NSColor blueColor] set];
    [line stroke];
    [label drawAtPoint:labelPos withAttributes:attr];
}



//----------------------------------------------------------------------------
// イベントハンドラ
//

- (IBAction)statusWindowOrderFrontRegardless:(id)sender
{
    [self refreshStatusWindow];
    [statusWindow orderFrontRegardless];
    [statusWindowMenuItem setTitle:NSLocalizedString(@"Hide Status Window",@"")];
	[[Preferences sharedInstance] saveVisiblityForWindow:statusWindow];
}

- (IBAction)showStatusWindow:(id)sender
{
    [self refreshStatusWindow];
    [statusWindow makeKeyAndOrderFront:self];
    [statusWindowMenuItem setTitle:NSLocalizedString(@"Hide Status Window",@"")];
	[[Preferences sharedInstance] saveVisiblityForWindow:statusWindow];
}

- (IBAction)hideStatusWindow:(id)sender
{
    [statusWindow orderOut:self];
    [statusWindowMenuItem setTitle:NSLocalizedString(@"Show Status Window",@"")];
	[[Preferences sharedInstance] saveVisiblityForWindow:statusWindow];
}

- (IBAction)toggleStatusWindow:(id)sender
{
    if ([statusWindow isVisible] == YES) {
        [self hideStatusWindow:sender];
    } else {
        [self showStatusWindow:sender];
    }
}

- (void)statusWindowWillClose:(NSNotification*)aNotification
{
    [self hideStatusWindow:self];
}

- (IBAction)showDiskGraphWindow:(id)sender
{
    [self refreshDiskGraphWindow];
	[NSApp activateIgnoringOtherApps:YES];
    [diskGraphWindow makeKeyAndOrderFront:self];
    [diskGraphMenuItem setTitle:NSLocalizedString(@"Hide DiskGraph Window",@"")];
	[[Preferences sharedInstance] saveVisiblityForWindow:diskGraphWindow];
}

- (IBAction)diskGraphWindowOrderFrontRegardless:(id)sender
{
    [self refreshStatusWindow];
    [diskGraphWindow orderFrontRegardless];
    [diskGraphMenuItem setTitle:NSLocalizedString(@"Hide DiskGraph Window",@"")];
	[[Preferences sharedInstance] saveVisiblityForWindow:diskGraphWindow];
}

- (IBAction)hideDiskGraphWindow:(id)sender
{
    [diskGraphWindow orderOut:self];
    [diskGraphMenuItem setTitle:NSLocalizedString(@"Show DiskGraph Window",@"")];
	[[Preferences sharedInstance] saveVisiblityForWindow:diskGraphWindow];
}

- (IBAction)toggleDiskGraphWindow:(id)sender
{
    if ([diskGraphWindow isVisible] == YES) {
        [self hideDiskGraphWindow:sender];
    } else {
        [self showDiskGraphWindow:sender];
    }
}

- (void)diskGraphWindowWillClose:(NSNotification*)aNotification
{
	[self hideDiskGraphWindow:self];
}

@end
