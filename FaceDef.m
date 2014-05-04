//
//  FaceDef.m
//  MacFace
//
//  Created by rryu on Tue Feb 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "FaceDef.h"


@implementation FaceDef

+ (NSDictionary*)infoAtPath:(NSString*)path
{
    NSDictionary *info;

    info = [NSDictionary dictionaryWithContentsOfFile:
        [path stringByAppendingPathComponent:@"faceDef.plist"]];

    return info;
}

+ (id)faceDefWithContentOfFile:(NSString*)path
{
    return [[[self alloc] initWithContentOfFile:path] autorelease];
}

- (id)initWithContentOfFile:(NSString*)path
{
    NSDictionary *partDefDict;
    NSArray *partArray,*patternArray,*colArray,*elemArray;
    NSEnumerator *enumerator;
    NSString *imagePath;
    NSNumber *value;
    int i,count;
    int row,col,no;
    int maxPartNo;

    [super init];

    NS_DURING
        definition = [FaceDef infoAtPath:path];

        if (definition == nil) {
            [NSException raise:@"FaceDefInfoLoadException" format:@"failuer loading faceDef.plist"];
        }

        [definition retain];

        packagePath = [path retain];

        // パーツ定義の読み込み
        partArray = [definition objectForKey:FACE_INFO_PARTS];

        if ([partArray isMemberOfClass:[NSArray class]]) {
            [NSException raise:@"FaceDefPartListLoadException" format:@"failed in reading part list."];
        }

        parts = calloc([partArray count],sizeof(PartDef));
        count = [partArray count];

        for (partCount = 0; partCount < count; partCount++){
            partDefDict = [partArray objectAtIndex:partCount];
            parts[partCount].filename = [[partDefDict objectForKey:FACE_PART_IMAGE] retain];
            parts[partCount].pos.x = [(NSNumber*)[partDefDict objectForKey:FACE_PART_POSX] floatValue];
            parts[partCount].pos.y = [(NSNumber*)[partDefDict objectForKey:FACE_PART_POSY] floatValue];
            imagePath = [path stringByAppendingPathComponent:parts[partCount].filename];
            parts[partCount].image = [[NSImage alloc]initWithContentsOfFile:imagePath];

            if (parts[partCount].image == nil){ // 画像が読み込めなかった
                [NSException raise:@"FaceDefPartLoadException"
                    format:@"failed in loading of image '%@'",parts[partCount].filename];
            }
        }

        maxPartNo = count - 1;

        // パターン定義の読み込み
        patternArray = [definition objectForKey:FACE_INFO_PATTERN];

        for (row = 0; row < FACE_ROWMAX; row++){
            colArray = [patternArray objectAtIndex:row];

            if ([colArray count] != FACE_COLMAX) {
                [NSException raise:@"FaceDefPatternLoadException"
                    format:@"number of pattern columns is not 10 at row %d",row];
            }

            for (col = 0; col < FACE_COLMAX; col++){
                elemArray = [colArray objectAtIndex:col];
                enumerator = [[colArray objectAtIndex:col] objectEnumerator];
                for (i = 0; i <= FACE_PATMAX && (value = [enumerator nextObject]) != nil; i++){
                    no = [value intValue];
                    patterns[row][col].parts[i] = no;
                    if (0 > no || no > maxPartNo) { // パーツ番号チェック
                        [NSException raise:@"FaceDefPatternLoadException"
                            format:@"illigal part no %d in patterns[%d,%d,%d]",no,row,col,i];
                    }
                }
                patterns[row][col].count = i;
            }
        }

        // マーカーリストの読み込み
        enumerator = [[definition objectForKey:FACE_INFO_MARKER] objectEnumerator];
        for (i = 0; i < 8 && (value = [enumerator nextObject]) != nil; i++){
            markers[i] = [value intValue];
        }

        // 代表画像パターンの読み込み
        enumerator = [[definition objectForKey:FACE_INFO_TITLE_PATTERN] objectEnumerator];
        for (i = 0; i <= FACE_PATMAX && (value = [enumerator nextObject]) != nil; i++){
            no = [value intValue];
            titlePattern.parts[i] = no;
            if (0 > no || no > maxPartNo) { // パーツ番号チェック
                [NSException raise:@"FaceDefPatternLoadException"
                    format:@"illigal part no %d in title pattern",no];
            }
        }
        titlePattern.count = i;
    NS_HANDLER
        NSLog(@"FaceDef load error: %@",localException);
        [self dealloc];
        self = nil;
    NS_ENDHANDLER

    return self;
}

- (void)dealloc
{
    int i;

    [packagePath release];
    [definition release];

    if (parts != nil) {
        for (i = 0; i < partCount; i++){
            [parts[i].filename release];
            [parts[i].image release];
        }
        free(parts);
    }
	[super dealloc];
}

-(NSString*)path
{
    return packagePath;
}

-(NSString*)title
{
    NSString *str;
    str = [definition objectForKey:@"title"];
    return  (str != nil) ? str : @"";
}

-(NSString*)author
{
    NSString *str;
    str = [definition objectForKey:@"author"];
    return  (str != nil) ? str : @"";
}

-(NSString*)version
{
    NSString *str;
    str = [definition objectForKey:@"version"];
    return  (str != nil) ? str : @"";
}

- (NSString*)siteURL
{
    NSString *str;
    str = [definition objectForKey:@"web site"];
    return  (str != nil) ? str : @"";
}

- (NSImage*)titleImage
{
    NSImage *image;
    int i;

    image = [[NSImage alloc] initWithSize:FACE_IMGSIZE];
    [image lockFocus];

    if (titlePattern.count > 0) {
        for (i=0; i<titlePattern.count; i++) {
            [self drawPart:&parts[titlePattern.parts[i]] atPoint:NSMakePoint(0,0)];
        }
    } else {
        [self drawImageOfRow:0 col:FACE_COLMAX marker:0 atPoint:NSMakePoint(0,0)];
    }

    [image unlockFocus];
    return [image autorelease];
}

- (int)partCount
{
    return partCount;
}

- (const PartDef*)partOfIndex:(int)index
{
    if (0 <= index && index < partCount) return &parts[index];
    else return nil;
}

- (const PatternDef*)patternOfRow:(int)row col:(int)col
{
    if (0 <= row && row < FACE_ROWMAX
     && 0 <= col && col < FACE_COLMAX) return &patterns[row][col];
    else return nil;
}

- (int)patternCountOfRow:(int)row col:(int)col
{
    if (0 <= row && row < FACE_ROWMAX
     && 0 <= col && col < FACE_COLMAX) return patterns[row][col].count;
    else return -1;
}

- (int)patternNoOfRow:(int)row col:(int)col index:(int)index
{
    if (0 <= row && row < FACE_ROWMAX
     && 0 <= col && col < FACE_COLMAX
     && 0 <= index && index < patterns[row][col].count) return patterns[row][col].parts[index];
    else return -1;
}

- (NSImage*)imageOfRow:(int)row col:(int)col marker:(int)marker
{
    NSImage *image;
    image = [[NSImage alloc] initWithSize:FACE_IMGSIZE];
    [image lockFocus];
    [self drawImageOfRow:row col:col marker:marker atPoint:NSMakePoint(0,0)];
    [image unlockFocus];
    return [image autorelease];
}

- (void)drawImageOfRow:(int)row col:(int)col marker:(int)marker atPoint:(NSPoint)point
{
    int count;
    int i;

    count = patterns[row][col].count;
    for (i=0; i<count; i++){
        [self drawPart:&parts[patterns[row][col].parts[i]] atPoint:point];
    };

    if (marker != 0) {
        for (i=0; i<8; i++) {
            if (marker & (1<<i)) {
                [self drawPart:&parts[markers[i]] atPoint:point];
            }
        }
    }
}

- (void)drawPart:(PartDef*)part atPoint:(NSPoint)point
{
    point.x += part->pos.x;
    point.y += part->pos.y;
    [part->image compositeToPoint:point operation:NSCompositeSourceOver];
}

-(void)dumpPattern:(NSString*)path;
{
    NSImage *img;
    NSSize imgSize;
    NSPoint pos;
    float offset;
    int i,j,rows;
    NSMutableDictionary	*attr;
    NSString *str;

    rows = partCount / FACE_COLMAX + 1;
    offset = rows * FACE_IMGW + 10;
    imgSize.width = FACE_IMGW * FACE_COLMAX;
    imgSize.height = FACE_IMGH * FACE_ROWMAX + offset + 14;

    img = [[NSImage alloc] initWithSize:imgSize];
    if (img == nil) {
        NSLog(@"failure dump pattern!");
        return;
    }

    [img lockFocus];
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(0,0,imgSize.width,imgSize.height));

    [[NSColor blackColor] set];
    NSRectFill(NSMakeRect(0,offset-6,imgSize.width,2));

    attr = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                [NSFont systemFontOfSize:14.0], NSFontAttributeName,
                [NSColor blackColor], NSForegroundColorAttributeName,
                nil];

    for (i = 0; i < partCount; i++) {
        pos.x = (i % FACE_COLMAX) * FACE_IMGW;
        pos.y = (rows-1 - i / FACE_COLMAX) * FACE_IMGH;
        [self drawPart:&parts[i] atPoint:pos];

		[[NSColor lightGrayColor] set];
		NSFrameRect(NSMakeRect(pos.x,pos.y,FACE_IMGW,FACE_IMGH));

		[[NSColor blackColor] set];
        str = [NSString stringWithFormat:@"%d",i];
        pos.x = (i % FACE_COLMAX) * FACE_IMGW;
        pos.y = (rows-1 - i / FACE_COLMAX) * FACE_IMGH + FACE_IMGH - 12;
        [str drawAtPoint:pos withAttributes:attr];
    }

    for (i = 0; i < FACE_ROWMAX; i++) {
        pos.y = (FACE_ROWMAX-1 - i) * FACE_IMGH + offset;
        for (j=0; j<FACE_COLMAX; j++) {
            pos.x = j * FACE_IMGW;
            [self drawImageOfRow:i col:j marker:0 atPoint:pos];
        }
    }

    pos.y = imgSize.height - 14;
    for (i = 0; i < FACE_COLMAX-1; i++) {
        str = [NSString stringWithFormat:@"%d-%d%%",i*10,(i+1)*10-1];
        pos.x = i * FACE_IMGW;
        [str drawAtPoint:pos withAttributes:attr];
    }
    str = [NSString stringWithFormat:@"%d%%",100];
    pos.x = (FACE_COLMAX-1) * FACE_IMGW;
    [str drawAtPoint:pos withAttributes:attr];

    [img unlockFocus];

    [[img TIFFRepresentation] writeToFile:path atomically:NO];
    [img release];
}

@end
