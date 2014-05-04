//
//  Preferences.m
//  MacFace
//
//  Created by rryu on Mon Apr 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"

// ユーザーデフォルトのキー
#define UD_USE_BUILTIN_FACEDEF	@"Use Builtin FaceDef"
#define UD_CUSTOM_FACEDEF	@"Custom FaceDef"
#define UD_FACEDEF_LIST		@"FaceDef List"
#define UD_DISK_HISTORY_LIST	@"Disk Historys"


@implementation Preferences

static Preferences *sharedInstance = nil;

// 共有インスタンスを返す
+ (id)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

+ (NSDictionary*)initialValues
{
    static NSDictionary *dict = nil;

    if (dict) return dict;

    dict = [[NSDictionary alloc] initWithObjectsAndKeys:
        [NSArray array],UD_FACEDEF_LIST,
        [NSNumber numberWithBool:YES],UD_USE_BUILTIN_FACEDEF,
        nil];

    return dict;
}

// 初期化
- (id)init
{
    NSUserDefaults *defaults;
    NSString *faceDefPath;

    // うっかり呼ばれてしまった場合にも対処しておく
    if (sharedInstance != nil) {
        [self release];
        return sharedInstance;
    }

    [super init];

    defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:[[self class] initialValues]];

    // 顔パターン定義の読み込み
    faceDefPath = [defaults stringForKey:UD_CUSTOM_FACEDEF];

    if (faceDefPath == nil) {
        curFaceDef = [[self loadBuiltinFaceDef] retain];
    } else {
        curFaceDef = [[FaceDef alloc] initWithContentOfFile:faceDefPath];
        if (curFaceDef == nil) {
            curFaceDef = [[self loadBuiltinFaceDef] retain];
            [defaults removeObjectForKey:UD_CUSTOM_FACEDEF];
        }
    }

    // 顔パターン履歴
    faceDefHistory = [[defaults arrayForKey:UD_FACEDEF_LIST] mutableCopy];

    sharedInstance = self;
    return self;
}

- (void)dealloc
{
    [curFaceDef release];
    [faceDefHistory release];
	[super dealloc];
}

- (FaceDef*)faceDef
{
    return curFaceDef;
}

- (void)setCustomFaceDef:(FaceDef*)faceDef
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if (faceDef == nil) {
		[curFaceDef release];
		curFaceDef = [[self loadBuiltinFaceDef] retain];
		[defaults removeObjectForKey:UD_CUSTOM_FACEDEF];
	} else {
		[curFaceDef release];
		curFaceDef = [faceDef retain];
		[defaults setObject:[faceDef path] forKey:UD_CUSTOM_FACEDEF];
		[self addFaceDefHistory:[faceDef path]];
	}

    [[NSNotificationCenter defaultCenter]
		postNotificationName:NOTIFY_FACEDEF_CHANGED object:self];
}

- (NSString*)customFaceDefPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults stringForKey:UD_CUSTOM_FACEDEF];
}

- (void)setCustomFaceDefAtPath:(NSString*)path
{
    FaceDef *faceDef;

	if (path == nil) {
		[self setCustomFaceDef:nil];
	} else {
		faceDef = [self loadCustomFaceDef:path];
		if (faceDef != nil) {
			[self setCustomFaceDef:faceDef];
		}
	}

}

- (FaceDef*)loadBuiltinFaceDef
{
    NSString *path;
    FaceDef *faceDef;

    path = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"mcface"];
    faceDef = [FaceDef faceDefWithContentOfFile:path];
    if (faceDef == nil) {
        NSRunCriticalAlertPanel(
            NSLocalizedString(@"LDE Message",@""),
            NSLocalizedString(@"LDE Info",@""),
            NSLocalizedString(@"Terminate",@""),nil,nil
        );
        [NSApp terminate:self];
        return nil;
    }

    return faceDef;
}

- (FaceDef*)loadCustomFaceDef:(NSString*)path
{
    NSFileManager *manager;
    NSString *displayName;
    FaceDef *faceDef;

	manager = [NSFileManager defaultManager];
	displayName = [manager displayNameAtPath:path];

	if ([manager fileExistsAtPath:path] == NO) {
		NSRunAlertPanel(
			NSLocalizedString(@"FileMissing Message",@""),
			NSLocalizedString(@"FileMissing Info",@""),
			NSLocalizedString(@"OK",@""),nil,nil,
			displayName
		);
		return nil;
	}

	faceDef = [[FaceDef alloc] initWithContentOfFile:path];

	if (faceDef == nil) {
		NSRunAlertPanel(
			NSLocalizedString(@"OpenErr Message",@""),
			NSLocalizedString(@"OpenErr Info",@""),
			NSLocalizedString(@"OK",@""),nil,nil,
			displayName
		);
		return nil;
	}

	return faceDef;
}

- (NSArray*)faceDefHistory
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults arrayForKey:UD_FACEDEF_LIST];
}

- (void)addFaceDefHistory:(NSString*)path
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    unsigned index;

    index = [faceDefHistory indexOfObject:path];
    if (index != NSNotFound) {
        [faceDefHistory removeObjectAtIndex:index];
        [faceDefHistory insertObject:path atIndex:0];
    } else {
        [faceDefHistory insertObject:path atIndex:0];
        if ([faceDefHistory count] > 10) {
            [faceDefHistory removeLastObject];
        }
    }

    [defaults setObject:faceDefHistory forKey:UD_FACEDEF_LIST];
}

- (NSDictionary*)diskHistoryForMountPoint:(NSString*)path
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *diskHistoryList;

    diskHistoryList = [defaults objectForKey:UD_DISK_HISTORY_LIST];
    return [diskHistoryList objectForKey:path];
}

- (void)setDiskHistory:(DiskHistory*)diskHistory forMountPoint:(NSString*)path
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *diskHistoryList;

    diskHistoryList = [[defaults dictionaryForKey:UD_DISK_HISTORY_LIST] mutableCopy];
    if (diskHistoryList == nil) {
        diskHistoryList = [[NSMutableDictionary alloc] initWithCapacity:1];
    }

    [diskHistoryList setObject:[diskHistory dictionaryRepresentation] forKey:path];
    [defaults setObject:diskHistoryList forKey:UD_DISK_HISTORY_LIST];

    [diskHistoryList release];
}

- (void)saveVisiblityForWindow:(NSWindow*)win
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[win isVisible] forKey:[@"Window Visible " stringByAppendingString:[win frameAutosaveName]]];
}

- (bool)visiblityForWindow:(NSWindow*)win
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:[@"Window Visible " stringByAppendingString:[win frameAutosaveName]]];
}

@end
