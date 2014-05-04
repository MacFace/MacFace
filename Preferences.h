//
//  Preferences.h
//  MacFace
//
//  Created by rryu on Mon Apr 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DiskHistory.h"
#import "Face.h"

// 通知名
#define NOTIFY_FACEDEF_CHANGED	@"FaceDefChangedNotification"

@interface Preferences : NSObject
{
	FaceDef *curFaceDef;
    NSMutableArray *faceDefHistory;
}

+ (id)sharedInstance;

- (FaceDef*)faceDef;
- (void)setCustomFaceDef:(FaceDef*)faceDef;
- (NSString*)customFaceDefPath;
- (void)setCustomFaceDefAtPath:(NSString*)path;

- (FaceDef*)loadBuiltinFaceDef;
- (FaceDef*)loadCustomFaceDef:(NSString*)path;

- (NSArray*)faceDefHistory;
- (void)addFaceDefHistory:(NSString*)path;

- (NSDictionary*)diskHistoryForMountPoint:(NSString*)path;
- (void)setDiskHistory:(DiskHistory*)diskHistory forMountPoint:(NSString*)path;

- (void)saveVisiblityForWindow:(NSWindow*)window;
- (bool)visiblityForWindow:(NSWindow*)window;

@end
