//
//  PrefsWindowController.m
//  MacFace
//
//  Created by rryu on 06/01/15.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PrefsWindowController.h"
#import "FaceDef.h"

@implementation PrefsWindowController

- (void)awakeFromNib
{
	prefs = [Preferences sharedInstance];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateFaceDefMenu:)
        name:NSPopUpButtonWillPopUpNotification object:faceDefSelector];
    [center addObserver:self selector:@selector(showWindow:)
		name:NOTIFY_FACEDEF_CHANGED object:nil];
	
    [faceDefSelector setAutoenablesItems:NO];
}

- (IBAction)showWindow:(id)sender
{
    [self updateWindow];
    [window makeKeyAndOrderFront:self];
}

- (void)updateWindow
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *faceDefPath;
    NSMutableArray *dispComponents;
    NSString *path;
	FaceDef *curFaceDef;

	curFaceDef = [prefs faceDef];

    [patternViewerController setFaceDef:curFaceDef];

    [[infoForm cellAtIndex:0] setStringValue:[curFaceDef title]]; 
    [[infoForm cellAtIndex:1] setStringValue:[curFaceDef author]]; 
    [[infoForm cellAtIndex:2] setStringValue:[curFaceDef version]]; 

    [urlLabel setStringValue:[curFaceDef siteURL]];

    faceDefPath = [prefs customFaceDefPath];
    if (faceDefPath != nil) {
        // パスの全要素を表示名に変換する
        dispComponents = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
        path = faceDefPath;
        while ([path length] > 0) {
            [dispComponents insertObject:[manager displayNameAtPath:path] atIndex:0];
            if ([path caseInsensitiveCompare:@"/"] == NSOrderedSame) break;
            path = [path stringByDeletingLastPathComponent];
            if ([path caseInsensitiveCompare:@"/Volumes"] == NSOrderedSame
             || [path caseInsensitiveCompare:@"/Network"] == NSOrderedSame) {
                break;
            }
        }
        [pathLabel setStringValue: [dispComponents componentsJoinedByString:@":"]];
    } else {
        [pathLabel setStringValue:@"---"];
    }

    [imageView setImage:[curFaceDef titleImage]];

    [self updateFaceDefMenu:nil];
}

- (void)updateFaceDefMenu:(NSNotification*)aNotification
{
    NSDictionary *faceDefInfo;
    NSString *path;
    NSString *title;
    NSString *menuTitle;
    NSString *folderName;
    NSFileManager *manager = [NSFileManager defaultManager];
    int i;
    int no;
	int menuIndex;

    // メニューから顔パターン履歴を削除
    while ([faceDefSelector numberOfItems] > 3) {
        [faceDefSelector removeItemAtIndex:1];
    }

    // 顔パターン履歴をメニューに挿入
	menuIndex = 1;
    if ([[prefs faceDefHistory] count] > 0) {
        for (i = 0; i < [[prefs faceDefHistory] count]; i++) {
            path = [[prefs faceDefHistory] objectAtIndex:i];
            faceDefInfo = [FaceDef infoAtPath:path];

            if (faceDefInfo != nil) {
                title = [faceDefInfo objectForKey:@"title"];

				if ([faceDefSelector itemWithTitle:title] != nil) {
					folderName = [manager displayNameAtPath:[path stringByDeletingLastPathComponent]];
					menuTitle = [NSString stringWithFormat:@"%@ (%@)",title,folderName];

					for (no = 1; [faceDefSelector itemWithTitle:menuTitle] != nil; no++) {
						menuTitle = [NSString stringWithFormat:@"%@ (%@) %d",title,folderName,no];
					}
				} else {
					menuTitle = title;
				}

				[faceDefSelector insertItemWithTitle:menuTitle atIndex:menuIndex];
				[[faceDefSelector itemAtIndex:menuIndex] setEnabled:(faceDefInfo != nil)];
				menuIndex++;
			}
        }

        [[faceDefSelector menu] insertItem:[NSMenuItem separatorItem] atIndex:1];
    }

    [self faceDefMenuResetSelection];
}

- (void)faceDefMenuResetSelection
{
    unsigned index;

    index = [[prefs faceDefHistory] indexOfObject:[[prefs faceDef] path]];
    if (index == NSNotFound) {
        [faceDefSelector selectItemAtIndex:0];
    } else {
        [faceDefSelector selectItemAtIndex:2 + index];
    }
}

- (IBAction)selectFaceDef:(id)sender
{
    int index;
    NSString *path;
    index = [faceDefSelector indexOfSelectedItem];
    if (index < 2) {
        [self changeBuiltinFaceDef];
    } else {
        path = [[prefs faceDefHistory] objectAtIndex:index-2];
        [self changeCustomFaceDefAtPath:path];
    }
    [self faceDefMenuResetSelection];
}

- (IBAction)showFaceDefSelectSheet:(id)sender
{
    NSOpenPanel *openPanel;
    NSArray *types = [NSArray arrayWithObjects:@"mcface",nil];

    openPanel = [NSOpenPanel openPanel];
    [openPanel beginSheetForDirectory:nil file:@"" types:types
        modalForWindow:window modalDelegate:self didEndSelector:@selector(faceDefSelectSheetDidEnd:returnCode:contextInfo:) 	contextInfo:nil];
}

- (void)faceDefSelectSheetDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    NSString *path;

    if (returnCode == NSOKButton) {
        path = [[sheet filenames] objectAtIndex:0];
        [self changeCustomFaceDefAtPath:path];
    } else {
        [self faceDefMenuResetSelection];
    }
}

- (void)changeBuiltinFaceDef
{
	[prefs setCustomFaceDefAtPath:nil];

    [self updateWindow];
}

- (void)changeCustomFaceDefAtPath:(NSString*)path
{
	[prefs setCustomFaceDefAtPath:path];
    [self updateWindow];
}

@end
