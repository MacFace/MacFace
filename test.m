#import <Cocoa/Cocoa.h>
#import "Face.h"
#import "DiskHistory.h"

#import <mach/mach.h>
#import <mach/mach_types.h>

#include <math.h>
#include <stdint.h>
#include <inttypes.h>

void testFace()
{
    FaceDefinition *faceDef;
    Face *faceObj;

    faceDef = [[FaceDefinition alloc] initWithContentOfFile:@"../defaultFace"];
    NSLog(@"%@",faceDef);
    [faceDef dumpPattern:[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/facedump.tiff"]];

    faceObj = [[Face alloc] initWithDefinition:faceDef];
    [faceDef release];
    NSLog(@"%@",faceObj);

    [faceObj release];
}


void volumeTest()
{
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fsAttr;
    NSArray *volumes;

    volumes = [workspace mountedLocalVolumePaths];
    NSLog(@"LocalVolumes\n%@",volumes);
    NSLog(@"removableMedias\n%@",[workspace mountedRemovableMedia]);

    NSLog(@"isFileSystem? %d",[volumes containsObject:@"/kijhu"]);

    fsAttr = [fileManager fileSystemAttributesAtPath:@"/"];
    NSLog(@"fileSystemAttributes\n%@",fsAttr);
    NSLog(@"%ldMB",[[fsAttr objectForKey:NSFileSystemFreeSize] longValue] / 1024 / 1024);
    NSLog(@"%d",[fsAttr retainCount]);

    BOOL result;
    BOOL removableFlag;
    BOOL writableFlag;
    BOOL unmountableFlag;
    NSString *description = @"";
    NSString *fileSystemType = @"";

    result = [workspace getFileSystemInfoForPath:@"/"
                isRemovable:&removableFlag
                isWritable:&writableFlag
                isUnmountable:&unmountableFlag
                description:&description
                type:&fileSystemType];

    NSLog(@"result: %d",result);
    NSLog(@"removableFlag: %d",removableFlag);
    NSLog(@"writableFlag: %d",writableFlag);
    NSLog(@"unmountableFlag: %d",unmountableFlag);
    NSLog(@"description: %@",description);
    NSLog(@"fileSystemType: %@",fileSystemType);

    NSURL *url;
    url = [NSURL fileURLWithPath:@"/Users/rryu/Desktop/sheep2.jpg"];
    [NSArchiver archiveRootObject:url toFile:@"/Users/rryu/Desktop/hoge.dat"];
}

void timeTest()
{
    NSTimeZone *gmtTimeZone;
    NSDate *date;
    NSCalendarDate *calendar;

    gmtTimeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    date = [NSDate date];
    calendar = [date dateWithCalendarFormat:nil timeZone:gmtTimeZone];
    NSLog(@"%@",gmtTimeZone);
    NSLog(@"%@",date);
    NSLog(@"%@",calendar);
    NSLog(@"%d",[calendar dayOfMonth]);
}

void test()
{
    const static long long maxFreeDisk = 1422839808;
    const static long long minFreeDisk = 1002532864;
//    const static long long maxFreeDisk = 1420000283;
//    const static long long minFreeDisk = 1420000283;

    static NSString *unitSymbols[] = {@"",@"K",@"M",@"G",@"T",@"P",@"E"};
    NSString *unitSymbol;
    int unit;
    int bunit;
    float mark;
    float upperLimit;
    float lowerLimit;
    float scale;
    float val;
//    int i;

    for (unit = 0; maxFreeDisk >> unit > 1<<10; unit += 10);
    unitSymbol = unitSymbols[unit/10];
    bunit = unit - 10;

    val = (float)(maxFreeDisk >> bunit) / (1<<10);
    for (mark = 1; val * mark < 1000; mark *= 10);
    mark = 1 / mark;

    val = (float)((maxFreeDisk - minFreeDisk) >> bunit) / (1<<10);
    for (; val / mark > 10; mark *= 10);

    val = (float)(maxFreeDisk >> bunit) / (1<<10);
    upperLimit = ceil(val / mark + 0.5) * mark;
    val = (float)(minFreeDisk >> bunit) / (1<<10);
    lowerLimit = floor(val / mark - 0.5) * mark;
    if (lowerLimit < 0.0) lowerLimit = 0;

    scale = 200 / (upperLimit-lowerLimit);

NSLog(@"unit: %d [%@]",unit,unitSymbol);
//NSLog(@"mark unit: %d [%@]",markUnit,unitSymbols[markUnit/10]);
NSLog(@"mark: %f%@",mark,unitSymbol);
//NSLog(@"range: %lld %f%@",range,(float)(range >> bunit) / (1<<10),unitSymbol);
//NSLog(@"unit: %4f%@",(float)unit / baseUnit,unitSymbol);
NSLog(@"max: %f%@",(float)(maxFreeDisk >> bunit) / (1<<10),unitSymbol);
NSLog(@"min: %f%@",(float)(minFreeDisk >> bunit) / (1<<10),unitSymbol);
NSLog(@"upperLimit: %f%@",upperLimit,unitSymbol);
NSLog(@"lowerLimit: %f%@",lowerLimit,unitSymbol);
NSLog(@"range: %f%@ (%3.1f)",upperLimit-lowerLimit,unitSymbol,scale);
//NSLog(@"divisions: %lld",divisions);
}

void test2()
{
//    default_pager_info();
    kern_return_t result;
    memory_object_default_t default_pager = MEMORY_OBJECT_DEFAULT_NULL;
    vm_size_t cluster_size = sizeof(memory_object_default_t);

NSLog(@"%p",default_pager);
    result = host_default_memory_manager(mach_host_self(),&default_pager,cluster_size);
NSLog(@"%d",result);
NSLog(@"%p",default_pager);
}

void test3()
{
    int unit;
    NSString *symbol;
    int place;
    float val;

    DiskHistory *history;
    history = [[DiskHistory alloc] initWithPath:@"/" capacity:70];
    [history update];

    unit = [history unit];
    symbol = [history symbolWithUnit:unit];
    val = (float)([history maxFreeSize] >> (unit-10)) / (1<<20) * 1000;
    place = [history placeByInteger:val];

    NSLog(@"max: %qd",[history maxFreeSize]);
    NSLog(@"unit: %2$@ [%1$d]",unit,symbol);
    NSLog(@"val: %f",val);
    NSLog(@"place: %d",place);

    NSLog(@"   0: %d",[history placeByInteger:0]);
    NSLog(@"   1: %d",[history placeByInteger:1]);
    NSLog(@"   9: %d",[history placeByInteger:9]);
    NSLog(@"  10: %d",[history placeByInteger:10]);
    NSLog(@"  11: %d",[history placeByInteger:11]);
    NSLog(@" 100: %d",[history placeByInteger:100]);
    NSLog(@"1000: %d",[history placeByInteger:1000]);
}

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int64_t val = 32;

    printf("%"PRId64"\n",val);

    [pool release];
    return 0;
}
