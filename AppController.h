//
//  AppController.h
//  MacFace
//
//  Created by rryu on Wed Apr 17 2002.
//  Copyright (c) 2001-2006 rryu. All rights reserved.
//  $Id: AppController.h 36 2006-02-19 15:27:41Z rryu $
//

#import <Cocoa/Cocoa.h>
#import "HostStatistics.h"
#import "DiskHistory.h"
#import "Face.h"
#import "CustomDrawView.h"
#import "PrefsWindowController.h"

@interface AppController : NSObject
{
    HostStatistics *hostHistory;
    DiskHistory *diskHistory;
    Face *faceObj;

    NSTimer *refreshTimer;
    NSTimer *diskCheckTimer;

    IBOutlet NSMenuItem *statusWindowMenuItem;
    IBOutlet NSMenuItem *diskGraphMenuItem;

    IBOutlet NSWindow *statusWindow;
    IBOutlet NSForm *memoryInfoView;
    IBOutlet NSForm *cpuInfoView;
    IBOutlet CustomDrawView *memoryGraphView;
    IBOutlet CustomDrawView *cpuGraphView;

    IBOutlet NSWindow *diskGraphWindow;

    IBOutlet PrefsWindowController *prefsWindowController;

    NSWindow *patternWindow;
}

- (HostStatistics*)hostHistory;
- (DiskHistory*)diskHistory;
- (Face*)faceObject;

- (void)faceDefChanged:(NSNotification*)aNotification;

- (void)updateStatus:(NSTimer*)timer;
- (void)updateDiskHistory:(NSTimer*)timer;

// ステータスウインドウ
- (void)refreshStatusWindow;
- (void)drawMemoryGraph:(CustomDrawView*)aView;
- (void)drawCPUGraph:(CustomDrawView*)aView;

- (IBAction)statusWindowOrderFrontRegardless:(id)sender;
- (IBAction)showStatusWindow:(id)sender;
- (IBAction)hideStatusWindow:(id)sender;
- (IBAction)toggleStatusWindow:(id)sender;

// ディスク消費グラフウインドウ
- (void)refreshDiskGraphWindow;
- (void)drawDiskGraph:(CustomDrawView*)aView;
- (void)drawPredictInfoWithFrame:(NSRect)frame unit:(int)unit scale:(float)scale lowerLimit:(float)lowerLimit;
- (void)drawCurrentDiskSizeAtPoint:(NSPoint)pt frame:(NSRect)frame;

- (IBAction)diskGraphWindowOrderFrontRegardless:(id)sender;
- (IBAction)showDiskGraphWindow:(id)sender;
- (IBAction)hideDiskGraphWindow:(id)sender;
- (IBAction)toggleDiskGraphWindow:(id)sender;


@end
