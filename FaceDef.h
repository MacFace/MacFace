//
//  FaceDef.h
//  MacFace
//
//  Created by rryu on Tue Feb 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//
#define FACE_ROWMAX	3
#define FACE_COLMAX	11
#define FACE_PATMAX	8
#define FACE_IMGW	128
#define FACE_IMGH	128
#define FACE_IMGSIZE	(NSMakeSize(128,128))

// マーカービットマスク
#define FDMARKER_PAGEIN		0x0001
#define FDMARKER_PAGEOUT	0x0002

//
#define FACE_INFO_TITLE		@"title"
#define FACE_INFO_AUTHOR	@"author"
#define FACE_INFO_VERSION	@"version"
#define FACE_INFO_SITE_URL	@"web site"

#define FACE_INFO_PARTS		@"parts"
#define FACE_INFO_PATTERN	@"pattern"
#define FACE_INFO_MARKER	@"markers"
#define FACE_INFO_TITLE_PATTERN	@"title pattern"
#define FACE_INFO_MARK_PGOUT	@"pagein pattern"
#define FACE_INFO_MARK_PGIN	@"pageout pattern"

#define FACE_PART_IMAGE		@"filename"
#define FACE_PART_POSX		@"pos x"
#define FACE_PART_POSY		@"pos y"

typedef struct {
    NSString *filename;
    NSImage *image;
    NSPoint pos;
} PartDef;

typedef struct {
    unsigned count;
    int parts[FACE_PATMAX];
} PatternDef;


@interface FaceDef : NSObject
{
    NSString *packagePath;
    NSDictionary *definition;
    int partCount;
    PartDef *parts;
    PatternDef patterns[FACE_ROWMAX][FACE_COLMAX];
    int markers[8];
    PatternDef titlePattern;
}

+ (NSDictionary*)infoAtPath:(NSString*)path;

+ (id)faceDefWithContentOfFile:(NSString*)path;

- (id)initWithContentOfFile:(NSString*)path;

- (NSString*)path;

- (NSString*)title;
- (NSString*)author;
- (NSString*)version;
- (NSString*)siteURL;

- (NSImage*)titleImage;

- (int)partCount;
- (const PartDef*)partOfIndex:(int)index;
- (const PatternDef*)patternOfRow:(int)row col:(int)col;
- (int)patternCountOfRow:(int)row col:(int)col;
- (int)patternNoOfRow:(int)row col:(int)col index:(int)index;

- (NSImage*)imageOfRow:(int)row col:(int)col marker:(int)marker;

- (void)drawImageOfRow:(int)row col:(int)col marker:(int)marker atPoint:(NSPoint)pt;
- (void)drawPart:(PartDef*)part atPoint:(NSPoint)point;

- (void)dumpPattern:(NSString*)path;

@end
