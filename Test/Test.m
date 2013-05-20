//
//  Test.m
//  Test
//
//  Created by Kozlek on 18/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

#import "Test.h"

#define GetLocalizedString(key) \
[[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

@implementation Test

- (void)setUp
{
    [super setUp];
    
    _diskutilList = [self diskutilList];
    _efiPartitions = [self getEfiPartitionsList];
    NSDictionary *themesInfo = [self getCloverThemesFromPath:@"/Volumes/Boot OS X/EFI/Clover/Themes"];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    STAssertNotNil(_efiPartitions, @"Something wrong...");
}

- (NSDictionary*)getCloverThemesFromPath:(NSString*)path
{
    //    NSDictionary *themes = [NSDictionary dictionaryWithContentsOfFile:[self.bundle pathForResource:@"themes" ofType:@"plist"]];
    //
    //    NSMutableDictionary *list = [[NSMutableDictionary alloc] init];
    //
    //    [themes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    //        NSDictionary *themeInfo = (NSDictionary*)obj;
    //
    //        NSString *name = [themeInfo objectForKey:@"Name"];
    //        NSString *path = [self.bundle pathForResource:name ofType:@"png"];
    //
    //        if (!path) {
    //            path = [self.bundle pathForResource:@"NoPreview" ofType:@"png"];
    //        }
    //
    //        NSMutableDictionary *newEntry = [[NSMutableDictionary alloc] initWithDictionary:themeInfo];
    //
    //        [newEntry setObject:path forKey:@"ImagePath"];
    //
    //        [list setObject:newEntry forKey:name];
    //    }];
    //
    //    _themesInfo = [NSDictionary dictionaryWithDictionary:list];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"themes"];
    }
    
    NSMutableDictionary *themes = [[NSMutableDictionary alloc] init];
    
    NSDirectoryEnumerator *enumarator = [[NSFileManager defaultManager] enumeratorAtPath:path];
    
    NSString *themePath = nil;
    
    while (themePath = [enumarator nextObject]) {
        
        themePath = [path stringByAppendingPathComponent:themePath];
        
        NSMutableDictionary *themeInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:[themePath stringByAppendingPathComponent:@"theme.plist"]];
        
        if (themeInfo) {
            NSString *themeName = [themeInfo objectForKey:@"Name"];
            
            if (!themeName) {
                themeName = themePath;
            }
            
            if (![themes objectForKey:themeName]) {
                [themes setObject:themeInfo forKey:themeName];
                
                if (![themeInfo objectForKey:@"Name"]) {
                    [themeInfo setObject:themeName forKey:@"Name"];
                }
                
                NSString *imagePath = [themePath stringByAppendingPathComponent:@"screenshot.png"];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                    imagePath = [[NSBundle mainBundle] pathForResource:@"NoPreview" ofType:@"png"];
                }
                
                [themeInfo setObject:imagePath forKey:@"imagePath"];
            }
        }
    }
    
    return [themes copy];
}

- (NSDictionary *)diskutilList
{
    // Get diskutil list -plist output
    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath: @"/usr/sbin/diskutil"];
    [task setArguments:[NSArray arrayWithObjects: @"list", @"-plist", nil]];
    
    NSPipe *pipe = [NSPipe pipe];
    
    [task setStandardOutput: pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
        
    return (__bridge NSDictionary *)(CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)data,
                                                                     kCFPropertyListImmutable,
                                                                     NULL));
}

- (NSDictionary*)getPartitionInfo:(NSString*)partitionName
{
    if (!partitionName)
        return nil;
    
    // Get diskutil list -plist output
    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath: @"/usr/sbin/diskutil"];
    [task setArguments:[NSArray arrayWithObjects: @"info", @"-plist", partitionName, nil]];
    
    NSPipe *pipe = [NSPipe pipe];
    
    [task setStandardOutput: pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    
    return (__bridge NSDictionary *)(CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)data,
                                                                     kCFPropertyListImmutable,
                                                                     NULL));
}

- (NSArray*)getEfiPartitionsList
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    [list addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                     GetLocalizedString(@"Default"),    @"Name",
                     @"Yes",                            @"Value",
                     nil]];
    
    [list addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                     GetLocalizedString(@"None"),    @"Name",
                     @"No",                          @"Value",
                     nil]];
    
    NSArray *disksAndPartitions = [[self diskutilList] objectForKey:@"AllDisksAndPartitions"];
    
    if (disksAndPartitions != nil) {
        for (NSDictionary *diskEntry in disksAndPartitions) {
            
            NSString *content = [diskEntry objectForKey:@"Content"];
            
            if (content != nil) {
                // Disk has partitions
                if ([content isEqualToString:@"GUID_partition_scheme"] || [content isEqualToString:@"FDisk_partition_scheme"]) {
                    
                    NSString *diskIdentifier = [diskEntry objectForKey:@"DeviceIdentifier"];
                    NSArray *partitions = [diskEntry objectForKey:@"Partitions"];
                    
                    if (diskIdentifier != nil && partitions != nil) {
                        for (NSDictionary *partitionEntry in partitions) {
                            
                            NSString *content = [partitionEntry objectForKey:@"Content"];
                            
                            if (content != nil && [content isEqualToString:@"EFI"]) {
                                
                                NSString *identifier = [partitionEntry objectForKey:@"DeviceIdentifier"];
                                
                                if (identifier != nil) {
                                    NSDictionary *partitionInfo = [self getPartitionInfo:identifier];
                                    
                                    if (partitionInfo != nil) {
                                        
                                        NSString *uuid = [partitionInfo objectForKey:@"VolumeUUID"];
                                        
                                        [list addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         [NSString stringWithFormat:@"EFI on %@", diskIdentifier],  @"Name",
                                                         (uuid != nil ? uuid : identifier),                         @"Value",
                                                         nil]];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return list;
}

@end
