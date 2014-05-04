//
//  PrefsWindowController.h
//  MacFace
//
//  Created by rryu on 06/01/15.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PatternViewerController.h"
#import "Preferences.h"

@interface PrefsWindowController : NSObject {
	Preferences *prefs;
    IBOutlet NSWindow *window;
    IBOutlet NSPopUpButton *faceDefSelector;
    IBOutlet NSImageView *imageView;
    IBOutlet NSForm *infoForm;
    IBOutlet NSTextField *urlLabel;
    IBOutlet NSTextField *pathLabel;
    IBOutlet PatternViewerController *patternViewerController;
}

- (IBAction)showWindow:(id)sender;
- (void)updateWindow;

- (void)updateFaceDefMenu:(NSNotification*)aNotification;
- (void)faceDefMenuResetSelection;
- (IBAction)selectFaceDef:(id)sender;

- (IBAction)showFaceDefSelectSheet:(id)sender;
- (void)faceDefSelectSheetDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;

- (void)changeBuiltinFaceDef;
- (void)changeCustomFaceDefAtPath:(NSString*)path;

@end
