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
