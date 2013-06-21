//
//  CloverPrefPane.m
//  CloverPrefPane
//
//  Created by Kozlek on 15/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

#import "CloverPrefPane.h"
#import "AnyPreferencesController.h"
#import "Localizer.h"

#import "Definitions.h"
#import "NSPopover+Message.h"

#include <mach/mach_error.h>
#include <sys/mount.h>

#define GetLocalizedString(key) \
[self.bundle localizedStringForKey:(key) value:@"" table:nil]

@implementation CloverPrefPane

#pragma mark -
#pragma mark Properties

- (NSDictionary *)diskutilList
{
    if (nil == _diskutilList) {
        
        // Get diskutil list -plist output
        NSTask *task = [[NSTask alloc] init];
        
        [task setLaunchPath: @"/usr/sbin/diskutil"];
        [task setArguments:[NSArray arrayWithObjects: @"list", @"-plist", nil]];
        
        NSPipe *pipe = [NSPipe pipe];
        
        [task setStandardOutput: pipe];
        
        NSFileHandle *file = [pipe fileHandleForReading];
        
        [task launch];
        
        NSData *data = [file readDataToEndOfFile];
        
        _diskutilList = (__bridge NSDictionary *)(CFPropertyListCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)data, kCFPropertyListImmutable, NULL, NULL));
    }
    
    return _diskutilList;
}

- (NSArray*)allDisks
{
    return [[self diskutilList] objectForKey:@"AllDisks"];
}

- (NSArray*)wholeDisks
{
    return [[self diskutilList] objectForKey:@"WholeDisks"];
}

- (NSArray*)mountedVolumes
{
    if (!_mountedVolumes) {
        
        NSMutableArray *list = [[NSMutableArray alloc] init];
        
        NSArray *urls = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:[NSArray arrayWithObject:NSURLVolumeURLKey] options:0];
        
        for (NSURL *url in urls) {
            NSError *error;
            NSURL *volumeURL = nil;
            
            [url getResourceValue:&volumeURL forKey:NSURLVolumeURLKey error:&error];
            
            if (volumeURL) {
                [list addObject:volumeURL];
            }
        }
        
        _mountedVolumes = [list copy];
    }
    
    return _mountedVolumes;//[[self diskutilList] objectForKey:@"VolumesFromDisks"];
}

- (void)addMenuItemToSourceList:(NSMutableArray*)list title:(NSString*)title value:(NSString*)value
{
    [list addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                       title, @"Title",
                       value, @"Value", nil]];
}

- (NSArray*)efiPartitions
{
    if (nil == _efiPartitions) {
        
        NSMutableArray *list = [[NSMutableArray alloc] init];
        
        [self addMenuItemToSourceList:list title:GetLocalizedString(@"None") value: @"No"];
        [self addMenuItemToSourceList:list title:GetLocalizedString(@"Boot Volume") value:@"Yes"];
        
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
                            NSMutableArray *volumeNames = [[NSMutableArray alloc] init];
                            NSString *espIdentifier = nil;
                            
                            for (NSDictionary *partitionEntry in partitions) {
                                
                                NSString *content = [partitionEntry objectForKey:@"Content"];
                                
                                if (content != nil && [content isEqualToString:@"EFI"]) {
                                    
                                    NSString *identifier = [partitionEntry objectForKey:@"DeviceIdentifier"];
                                    
                                    if (identifier != nil) {
                                        espIdentifier = [self getUuidForBsdVolume:identifier];
                                        
                                        if (!espIdentifier) {
                                            espIdentifier = identifier;
                                        }
                                    }
                                }
                                
                                NSString *volumeName = [partitionEntry objectForKey:@"VolumeName"];
                                
                                if (volumeName) {
                                    [volumeNames addObject:volumeName];
                                }
                            }
                            
                            if (espIdentifier) {
                                NSString *name = [NSString stringWithFormat:GetLocalizedString(@"EFI on %@ (%@)"), [volumeNames componentsJoinedByString:@", "], diskIdentifier];
                                
                                [self addMenuItemToSourceList:list title:name value:espIdentifier];
                            }
                        }
                    }
                }
            }
        }
        
        //        for (NSString *volume in [self volumes]) {
        //            [list addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        //                             [NSString stringWithFormat:GetLocalizedString(@"%@'s disk ESP"), volume], @"Title",
        //                             volume, @"Value",
        //                             nil]];
        //        }
        
        _efiPartitions = [NSArray arrayWithArray:list];
    }
    
    return _efiPartitions;
}

/*- (NSArray*)nvramPartitions
{
    if (nil == _nvramPartitions) {
        
        NSMutableArray *list = [[NSMutableArray alloc] init];
        
        [self addMenuItemToSourceList:list title:GetLocalizedString(@"No") value:@"No"];
        [self addMenuItemToSourceList:list title:GetLocalizedString(@"Default") value:@"Yes"];
        
        NSArray *disksAndPartitions = [[self diskutilList] objectForKey:@"AllDisksAndPartitions"];
        
        if (disksAndPartitions != nil) {
            for (NSDictionary *diskEntry in disksAndPartitions) {
                
                NSString *content = [diskEntry objectForKey:@"Content"];
                
                if (content != nil) {
                    // Disk has partitions
                    if ([content isEqualToString:@"GUID_partition_scheme"] || [content isEqualToString:@"FDisk_partition_scheme"]) {
                        
                        NSArray *partitions = [diskEntry objectForKey:@"Partitions"];
                        
                        if (partitions != nil) {
                            for (NSDictionary *partitionEntry in partitions) {
                                
                                NSString *content = [partitionEntry objectForKey:@"Content"];
                                
                                if (content != nil && ([content isEqualToString:@"Apple_HFS"] || [content isEqualToString:@"Apple_Boot"] || [content isEqualToString:@"EFI"])) {
                                    
                                    NSString *identifier = [partitionEntry objectForKey:@"DeviceIdentifier"];
                                    
                                    if (identifier != nil) {
                                        NSDictionary *partitionInfo = [self getPartitionInfo:identifier];
                                        
                                        if (partitionInfo != nil) {
                                            
                                            NSNumber *writable = [partitionInfo objectForKey:@"Writable"];
                                            
                                            if (writable != nil && [writable boolValue] == YES) {
                                                
                                                NSString *name = [partitionInfo objectForKey:@"VolumeName"];
                         
                                                name = [NSString stringWithFormat:@"%@ (%@)", identifier, name == nil || [name length] == 0 ? [content isEqualToString:@"EFI"] ? @"EFI" : identifier : name];
                                                
                                                [self addMenuItemToSourceList:list title:name value:identifier];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // Logical RAID volume or Fusion Drive
                    else if ([content isEqualToString:@"Apple_HFS"]) {
                        NSString *identifier = [diskEntry objectForKey:@"DeviceIdentifier"];
                        NSString *name = [diskEntry objectForKey:@"VolumeName"];
                        
                        if (identifier && name) {
                            name = [NSString stringWithFormat:@"%@ (%@)", identifier, name];
                            
                            [self addMenuItemToSourceList:list title:name value:identifier];
                        }
                    }
                }
            }
        }
        
        _nvramPartitions = [NSArray arrayWithArray:list];
    }
    
    return _nvramPartitions;
}*/

-(NSString *)kernelBootArgs
{
    return [self getNvramKey:"boot-args"];
}

-(void)setKernelBootArgs:(NSString *)kernelBootArgs
{
    if (![self.kernelBootArgs isEqualToString:kernelBootArgs]) {
        [self setNvramKey:"boot-args" value:[kernelBootArgs UTF8String]];
    }
}


- (NSArray*)cloverPathsCollection
{
    if (!_cloverPathsCollection) {
        _cloverPathsCollection = [self getCloverPathsCollection];
    }
    
    return _cloverPathsCollection;
}

-(void)setCloverPathsCollection:(NSArray *)booterPaths
{
    if (!booterPaths) {
        _cloverPathsCollection = [self getCloverPathsCollection];
    }
    else {
        _cloverPathsCollection = booterPaths;
    }
    
    self.cloverOemCollection = nil;
    self.cloverThemesCollection = nil;
}

- (NSString*)cloverPath
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"pathToClover"];
}

- (void)setCloverPath:(NSString *)cloverPath
{
    if (![self.cloverPath isEqualToString:cloverPath]) {
        [[NSUserDefaults standardUserDefaults] setObject:cloverPath forKey:@"pathToClover"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Reset current themes db forsing it to reload from new path
        self.cloverThemesCollection = nil;
        self.cloverOemCollection = nil;
    }
}

-(NSArray *)cloverOemCollection
{
    if (!_cloverOemCollection) {
        _cloverOemCollection = [self getCloverOemCollectionFromPath:self.cloverPath];
    }
    
    return _cloverOemCollection;
}

-(void)setCloverOemCollection:(NSArray *)cloverOemProductsCollection
{
    if (!cloverOemProductsCollection) {
        _cloverOemCollection = [self getCloverOemCollectionFromPath:self.cloverPath];
    }
    else {
        _cloverOemCollection = cloverOemProductsCollection;
    }
    
    //self.cloverOemPath = nil;
}

-(NSString *)cloverOemPath
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"lastOemProductSelected"];
}

-(void)setCloverOemPath:(NSString *)cloverOemProduct
{
    if (![self.cloverOemPath isEqualToString:cloverOemProduct]) {
        [[NSUserDefaults standardUserDefaults] setObject:cloverOemProduct forKey:@"lastOemProductSelected"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.cloverConfigPath = nil;
    }
}

-(NSString*)cloverConfigPath
{
    if (!_cloverConfigPath) {
        NSString *configPath = [self.cloverOemPath stringByAppendingPathComponent:@"config.plist"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
            _cloverConfigPath = configPath;
        }
        else {
            _cloverConfigPath = nil;
        }
        
//        _configurationController.configuration = (__bridge NSMutableDictionary *)(CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)[NSData dataWithContentsOfFile:_cloverConfigPath], kCFPropertyListMutableContainersAndLeaves, NULL));
    }
    
    return _cloverConfigPath;
}

-(void)setCloverConfigPath:(NSString *)cloverConfigPath
{
    if (_cloverConfigPath && ![_cloverConfigPath isEqualToString:cloverConfigPath]) {
        _cloverConfigPath = cloverConfigPath;
        
//        _configurationController.configuration = (__bridge NSMutableDictionary *)(CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)[NSData dataWithContentsOfFile:_cloverConfigPath], kCFPropertyListMutableContainersAndLeaves, NULL));
    }
}

- (NSDictionary*)cloverThemesCollection
{
    if (nil == _themesInfo) {
        _themesInfo = [self getCloverThemesFromPath:self.cloverPath];
    }
    
    return _themesInfo;
}

-(void)setCloverThemesCollection:(NSDictionary *)themesInfo
{
    if (nil == themesInfo) {
        _themesInfo = [self getCloverThemesFromPath:self.cloverPath];
    }
    else {
        _themesInfo = themesInfo;
    }
}

- (NSString*)cloverTheme
{
    if (!_cloverTheme) {
        _cloverTheme = [self getNvramKey:kCloverThemeName];
        
        self.CloverThemeInfo = [self.cloverThemesCollection objectForKey:_cloverTheme];
    }
    
    return _cloverTheme;
}

- (void)setCloverTheme:(NSString *)cloverTheme
{
    if (![self.cloverTheme isEqualToString:cloverTheme]) {
        _cloverTheme = cloverTheme;
        [self setNvramKey:kCloverThemeName value:[cloverTheme UTF8String]];
    }
    
    self.CloverThemeInfo = [self.cloverThemesCollection objectForKey:cloverTheme];
}

- (NSNumber*)cloverPreviousLogLines
{
    if (!_cloverOldLogLineCount) {
        _cloverOldLogLineCount = [self getNvramKey:kCloverLogLineCount];
    }
    
    return [NSNumber numberWithInteger:[_cloverOldLogLineCount integerValue]];
}

-(void)setCloverPreviousLogLines:(NSNumber*)cloverPreviousLogLines
{
    if (![self.cloverPreviousLogLines isEqualToNumber:cloverPreviousLogLines]) {
        _cloverOldLogLineCount = [cloverPreviousLogLines stringValue];
        
        [self setNvramKey:kCloverLogLineCount value:[_cloverOldLogLineCount UTF8String]];
    }
}

- (NSNumber*)cloverLogEveryBootEnabled
{
    if (!_cloverLogEveryBoot) {
        _cloverLogEveryBoot = [self getNvramKey:kCloverLogEveryBoot];
    }
    
    if ([_cloverLogEveryBoot isCaseInsensitiveLike:@"No"]) {
        return [NSNumber numberWithBool:NO];
    }
    else if ([_cloverLogEveryBoot isCaseInsensitiveLike:@"Yes"] || [_cloverLogEveryBoot integerValue] >= 0) {
        return [NSNumber numberWithBool:YES];
    }
    
    return [NSNumber numberWithBool:NO];
}

- (void)setCloverLogEveryBootEnabled:(NSNumber *)cloverTimestampLogsEnabled
{
    if (![self.cloverLogEveryBootEnabled isEqualToNumber:cloverTimestampLogsEnabled]) {
        _cloverLogEveryBoot = [cloverTimestampLogsEnabled boolValue] ? @"Yes" : @"No";
        [self setNvramKey:kCloverLogEveryBoot value:[_cloverLogEveryBoot UTF8String]];
    }
}

- (NSNumber*)cloverLogEveryBootNumber
{
    if (!_cloverLogEveryBoot) {
        _cloverLogEveryBoot = [self getNvramKey:kCloverLogEveryBoot];
    }
    
    if ([_cloverLogEveryBoot isCaseInsensitiveLike:@"No"] || [_cloverLogEveryBoot isCaseInsensitiveLike:@"Yes"]) {
        return [NSNumber numberWithInteger:0];
    }

    return [NSNumber numberWithInteger:[_cloverLogEveryBoot integerValue]];
}

- (void)setCloverLogEveryBootNumber:(NSNumber *)cloverLogEveryBootLimit
{
    if (![self.cloverLogEveryBootNumber isEqualToNumber:cloverLogEveryBootLimit]) {
        _cloverLogEveryBoot = [NSString stringWithFormat:@"%ld", [cloverLogEveryBootLimit integerValue]];
        [self setNvramKey:kCloverLogEveryBoot value:[_cloverLogEveryBoot UTF8String]];
    }
}

-(NSString *)cloverMountEfiPartition
{
    if (!_cloverMountEfiPartition) {
        _cloverMountEfiPartition = [self getNvramKey:kCloverMountEFI];
    }
    
    return _cloverMountEfiPartition;
}

-(void)setCloverMountEfiPartition:(NSString *)cloverMountEfiPartition
{
    if (![self.cloverMountEfiPartition isEqualToString:cloverMountEfiPartition]) {
        _cloverMountEfiPartition = cloverMountEfiPartition;
        
        [self setNvramKey:kCloverMountEFI value:[cloverMountEfiPartition UTF8String]];
    }
}

- (NSNumber *)cloverEmulateNvram
{
    if (!_cloverNvramPartition) {
        _cloverNvramPartition = [self getNvramKey:kCloverNVRamDisk];
    }
    
    return [NSNumber numberWithBool:_cloverNvramPartition && [_cloverNvramPartition isCaseInsensitiveLike:@"Yes"]];
}

-(void)setCloverEmulateNvram:(NSNumber *)cloverEmulateNvram
{
    if (![self.cloverEmulateNvram isEqualToNumber:cloverEmulateNvram]) {
        _cloverNvramPartition = [cloverEmulateNvram boolValue] ? @"Yes" : @"No";
        [self setNvramKey:kCloverNVRamDisk value:[_cloverNvramPartition UTF8String]];
    }
}

- (NSNumber*)cloverBackupsOnDestinationVolumeEnabled
{
    if (!_cloverBackupsOnDestinationVolume) {
        _cloverBackupsOnDestinationVolume = [self getNvramKey:kCloverBackupDirOnDestVol];
    }
    
    return [NSNumber numberWithBool:[_cloverBackupsOnDestinationVolume isCaseInsensitiveLike:@"Yes"]];
}

-(void)setCloverBackupsOnDestinationVolumeEnabled:(NSNumber*)cloverBackupsOnDestinationVolume
{
    if (![self.cloverBackupsOnDestinationVolumeEnabled isEqualToNumber:cloverBackupsOnDestinationVolume]) {
        _cloverBackupsOnDestinationVolume = [cloverBackupsOnDestinationVolume boolValue]? @"Yes" : @"";
        
        [self setNvramKey:kCloverBackupDirOnDestVol value:[_cloverBackupsOnDestinationVolume UTF8String]];
    }
}

- (NSNumber*)cloverBackupsLimit
{
    if (!_cloverEfiFolderBackupsLimit) {
        _cloverEfiFolderBackupsLimit = [self getNvramKey:kCloverKeepBackupLimit];
    }
    
    return [NSNumber numberWithInteger:[_cloverEfiFolderBackupsLimit integerValue]];;
}

-(void)setCloverBackupsLimit:(NSNumber *)cloverBackupsLimit
{
    if (![self.cloverBackupsLimit isEqualToNumber:cloverBackupsLimit]) {
        _cloverEfiFolderBackupsLimit = [cloverBackupsLimit stringValue];
        [self setNvramKey:kCloverKeepBackupLimit value:[_cloverEfiFolderBackupsLimit UTF8String]];
    }
}

#pragma mark -
#pragma mark Methods

- (void)changeProgressionTitle:(NSString*)title isInProgress:(BOOL)isInProgress
{
    [_checkNowButton setTitle:GetLocalizedString(title)];
    [_checkNowButton setEnabled:!isInProgress];
    [_updatesIndicator setHidden:!isInProgress];
    
    if (isInProgress) {
        [_updatesIndicator startAnimation:self];
    }
    else {
        [_updatesIndicator stopAnimation:self];
    }

}

- (void)readAndSetInstallerRevision
{
    // Initialize revision fields
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
    NSString *preferenceFolder = [[searchPaths objectAtIndex:0] stringByAppendingPathComponent:@"Preferences"];
    NSString *cloverInstallerPlist = [[preferenceFolder stringByAppendingPathComponent:@"com.projectosx.clover.installer"] stringByAppendingPathExtension:@"plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cloverInstallerPlist]) {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:cloverInstallerPlist];
        NSNumber* revision = [dict objectForKey:@"CloverRevision"];
        if (revision) {
            [_installedRevisionTextField setStringValue:[revision stringValue]];
        }
    }
}

- (NSString*)getUuidForBsdVolume:(NSString*)bsdName
{
    CFMutableDictionaryRef	matchingDict;
    io_service_t			service;
    NSString *              uuid = @"-";
    
    matchingDict = IOBSDNameMatching(kIOMasterPortDefault, 0, [bsdName UTF8String]);
    
    if (NULL == matchingDict) {
        NSLog(@"IOBSDNameMatching returned a NULL dictionary");
    }
    else {
        // Fetch the object with the matching BSD node name.
		// Note that there should only be one match, so IOServiceGetMatchingService is used instead of
		// IOServiceGetMatchingServices to simplify the code.
        service = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict);
        
		if (IO_OBJECT_NULL == service) {
			NSLog(@"IOServiceGetMatchingService returned IO_OBJECT_NULL");
		}
		else {
			if (IOObjectConformsTo(service, "IOMedia")) {
                
                CFTypeRef valueRef;
                
                valueRef = IORegistryEntryCreateCFProperty(service, CFSTR("UUID"), kCFAllocatorDefault, 0);
                
                if (NULL == valueRef) {
                    NSLog(@"Could not retrieve UUID property");
                }
                else {
                    
                    uuid = (__bridge NSString*)CFStringCreateCopy(kCFAllocatorDefault, valueRef);
                    
                    CFRelease(valueRef);
                }
            }
            
			IOObjectRelease(service);
		}
    }
    
    return uuid;
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

- (NSArray*)getCloverPathsCollection
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    for (NSURL *volume in [self mountedVolumes]) {
        
        NSString *path = [[volume path] stringByAppendingPathComponent:@"EFI/CLOVER"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"config.plist"]]) {
            NSString *name = [NSString stringWithFormat:GetLocalizedString(@"Clover on %@"), [volume.pathComponents objectAtIndex:volume.pathComponents.count - 1]];
            
            [self addMenuItemToSourceList:list title:name value:path];
        }
    }
    
    if ([list count]) {
        return [list copy];
    }
    
    return nil;
}

- (NSDictionary*)getCloverThemesFromPath:(NSString*)path
{
    NSString *themesPath = [path stringByAppendingPathComponent:@"themes"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:themesPath]) {
        themesPath = [[self.bundle resourcePath] stringByAppendingPathComponent:@"Themes"];
    }
    
    NSLog(@"loading themes from: %@", themesPath);
    
    NSMutableDictionary *themes = [[NSMutableDictionary alloc] init];
    
    NSArray *subPaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:themesPath error:NULL];
    
    for (NSString *themeSubPath in subPaths) {
        
        NSString *themePath = [themesPath stringByAppendingPathComponent:themeSubPath];
        
        NSMutableDictionary *themeInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:[themePath stringByAppendingPathComponent:@"theme.plist"]];
        
        if (themeInfo) {
            NSString *themeName = [themeInfo objectForKey:@"Name"];
            
            if (!themeName) {
                themeName = themeSubPath;
            }
            
            if (![themes objectForKey:themeName]) {
                [themes setObject:themeInfo forKey:themeName];
                
                if (![themeInfo objectForKey:@"Name"]) {
                    [themeInfo setObject:themeName forKey:@"Name"];
                }
                
                if (![themeInfo objectForKey:@"Author"]) {
                    [themeInfo setObject:GetLocalizedString(@"Not specified") forKey:@"Author"];
                }
                
                if (![themeInfo objectForKey:@"Year"]) {
                    [themeInfo setObject:GetLocalizedString(@"Not specified") forKey:@"Year"];
                }
                
                if (![themeInfo objectForKey:@"Description"]) {
                    [themeInfo setObject:GetLocalizedString(@"No description available") forKey:@"Description"];
                }
                
                NSString *imagePath = [themePath stringByAppendingPathComponent:@"screenshot.png"];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                    imagePath = [self.bundle pathForResource:@"NoPreview" ofType:@"png"];
                }
                                
                //[themeInfo setObject:[[NSImage alloc] initWithContentsOfFile:imagePath] forKey:@"Preview"];
                [themeInfo setObject:imagePath forKey:@"Preview"];
            }
        }
    }
    
    return [themes copy];
}

- (NSArray*)getCloverOemCollectionFromPath:(NSString*)path
{
    if (!path || ![path length]) {
        return nil;
    }
    
    NSString *oemPath = [path stringByAppendingPathComponent:@"OEM"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:oemPath]) {
        return [NSArray array];
    }
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"config.plist"]]) {
        [self addMenuItemToSourceList:list title:GetLocalizedString(@"Default") value:path];
    }
    
    NSDirectoryEnumerator *enumarator = [[NSFileManager defaultManager] enumeratorAtPath:oemPath];
    
    NSString *productSubPath = nil;
    
    while (productSubPath = [enumarator nextObject]) {
        
        NSString *productPath = [oemPath stringByAppendingPathComponent:productSubPath];

        if ([[NSFileManager defaultManager] fileExistsAtPath:[productPath stringByAppendingPathComponent:@"config.plist"]]) {
            [self addMenuItemToSourceList:list title:productSubPath value:productPath];
        }
    }
    
    if ([list count]) {
        return [list copy];
    }
    
    return nil;
}

- (void)setUpdatesInterval:(NSInteger)checkInterval
{
    CFDictionaryRef launchInfo = SMJobCopyDictionary(kSMDomainUserLaunchd, CFSTR(kCloverUpdaterIdentifier));
    
    if (launchInfo != NULL) {
        CFRelease(launchInfo);
        
        CFErrorRef error = NULL;
        if (!SMJobRemove(kSMDomainUserLaunchd, CFSTR(kCloverUpdaterIdentifier), NULL/*[[_authorizationView authorization] authorizationRef]*/, YES, &error))
            NSLog(@"Error in SMJobRemove: %@", error);
        if (error)
            CFRelease(error);
    }
    
    [AnyPreferencesController setKey:CFSTR(kCloverScheduledCheckInterval) forAppID:CFSTR(kCloverUpdaterIdentifier) fromInteger:checkInterval];
    
    NSString *updaterPath = [[self.bundle resourcePath] stringByAppendingPathComponent:@kCloverUpdaterExecutable];
    
    if (checkInterval > 0) {
        // Create a new plist
        NSArray* call = [NSArray arrayWithObjects:
                        updaterPath,
                         @"startup",
                         nil];
        
        NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      @kCloverUpdaterIdentifier, @"Label",
                                      [NSNumber numberWithInteger:checkInterval], @"StartInterval",
                                      [NSNumber numberWithBool:YES], @"RunAtLoad",
                                      updaterPath, @"Program",
                                      call, @"ProgramArguments",
                                      nil];
        
        [plist writeToFile:_updaterPlistPath atomically:YES];
        
		CFErrorRef error = NULL;
        
		if (!SMJobSubmit(kSMDomainUserLaunchd, (__bridge CFDictionaryRef)plist, NULL/*[[_authorizationView authorization] authorizationRef]*/, &error)) {
			if (error) {
				NSLog(@"Error in SMJobSubmit: %@", error);
			} else {
				NSLog(@"Error in SMJobSubmit without details. Check /var/db/launchd.db/com.apple.launchd.peruser.NNN/overrides.plist for %@ set to disabled.", @kCloverUpdaterIdentifier);
            }
		}
		if (error) {
			CFRelease(error);
        }
    }
    
    [AnyPreferencesController synchronizeforAppID:CFSTR(kCloverUpdaterIdentifier)];
}

#pragma mark -
#pragma mark Events

- (void)mainViewDidLoad
{
    [Localizer localizeView:self.mainView withBunde:self.bundle];
    
    // Setup security.
	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &items};
    
  	_authorizationView.delegate = self;
	[_authorizationView setAuthorizationRights:&rights];
	[_authorizationView updateStatus:nil];
    
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *agentsFolder = [[searchPaths objectAtIndex:0] stringByAppendingPathComponent:@"LaunchAgents"];
    [[NSFileManager defaultManager] createDirectoryAtPath:agentsFolder withIntermediateDirectories:YES attributes:nil error:nil];
    _updaterPlistPath = [[agentsFolder stringByAppendingPathComponent:@kCloverUpdaterIdentifier] stringByAppendingPathExtension:@"plist"];
    
    // Initialize revision fields    
    NSString* bootedRevision = @"-";
    io_registry_entry_t ioRegistryEFI = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/efi/platform");
    if (ioRegistryEFI) {
        CFStringRef nameRef = CFStringCreateWithCString(kCFAllocatorDefault, "clovergui-revision", kCFStringEncodingUTF8);
        if (nameRef) {
            CFTypeRef valueRef = IORegistryEntryCreateCFProperty(ioRegistryEFI, nameRef, 0, 0);
            CFRelease(nameRef);
            if (valueRef) {
                // Get the OF variable's type.
                CFTypeID typeID = CFGetTypeID(valueRef);
                if (typeID == CFDataGetTypeID()) {
                    bootedRevision = [NSString stringWithFormat:@"%u",*((uint32_t*)CFDataGetBytePtr(valueRef))];
                    self.cloverRevision = [NSNumber numberWithInteger:[bootedRevision integerValue]];
                }
                CFRelease(valueRef);
            }
        }
        IOObjectRelease(ioRegistryEFI);
    }
    [_bootedRevisionTextField setStringValue:bootedRevision];
    
    // Initialize popUpCheckInterval
    NSInteger checkInterval = [AnyPreferencesController getIntegerFromKey:CFSTR(kCloverScheduledCheckInterval) forAppID:CFSTR(kCloverUpdaterIdentifier) withDefault:0];
    [_updatesIntervalPopup selectItemWithTag:checkInterval];
    
    // Init last updates check date
    NSDate *lastCheckTimestamp = [AnyPreferencesController getDateFromKey:CFSTR(kCloverLastCheckTimestamp) forAppID:CFSTR(kCloverUpdaterIdentifier)];
    
    if (lastCheckTimestamp) {
        [_lastUpdateTextField setStringValue:[_lastUpdateTextField.formatter stringFromDate:lastCheckTimestamp]];
    } else {
        [_lastUpdateTextField setStringValue:@"-"];
    }
    
    [self readAndSetInstallerRevision];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector: @selector(volumesChanged:) name:NSWorkspaceDidMountNotification object: nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector: @selector(volumesChanged:) name:NSWorkspaceDidUnmountNotification object:nil];
    
    NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@kCloverLatestInstallerURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    
    if (![[NSURLConnection alloc]initWithRequest:request delegate:self]) {
        [_lastUpdateTextField setStringValue:@"-"];
    }
    else {
        [self changeProgressionTitle:@"Checking..." isInProgress:YES];
    }
}

- (void) willUnselect
{
    //
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_lastUpdateTextField setStringValue:@"-"];
    [self changeProgressionTitle:@"Check now" isInProgress:NO];
}

//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
//{
//    _remoteDocumentData = [[NSMutableData alloc] init];
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    if (_remoteDocumentData) {
//        [_remoteDocumentData appendData:data];
//    }
//}
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
//    
//    [_lastUpdateTextField setStringValue:[_lastUpdateTextField.formatter stringFromDate:now]];
//    [AnyPreferencesController setKey:CFSTR(kCloverLastCheckTimestamp) forAppID:CFSTR(kCloverUpdaterIdentifier) fromDate:now];
//    
//    if (_remoteDocumentData) {
//        [[NSFileManager defaultManager] createFileAtPath:@"~/Desktop/Document.txt" contents:_remoteDocumentData attributes:nil];
//        
//        NSString *document = [[NSString alloc] initWithData:_remoteDocumentData encoding:NSASCIIStringEncoding];
//        
//        NSError *error;
//        
//        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"s#^.*Installer/Clover_v2_r([0-9]+).*#\1#p" options:NSRegularExpressionCaseInsensitive error:&error];
//        
//        if (!error) {
//            NSRange range = [regex rangeOfFirstMatchInString:document options:kNilOptions range:NSMakeRange(0, [document length])];
//            
//            if(range.location != NSNotFound)
//            {
//                NSString *foundModel = [document substringWithRange:range];
//                NSLog(@"found: %@", foundModel);
//            }
//            else {
//                [self changeProgressionTitle:@"Check now" isInProgress:NO];
//            }
//        }
//        else {
//            NSLog(@"NSRegularExpression error: %@", error);
//            [self changeProgressionTitle:@"Check now" isInProgress:NO];
//        }
//    }
//    else {
//        [self changeProgressionTitle:@"Check now" isInProgress:NO];
//    }
//}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // Do not download the installer
    [connection cancel];
    
    [self readAndSetInstallerRevision];
    
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    
    _installerFilename = response.suggestedFilename;
    
    NSLog(@"installer: %@", _installerFilename);
    
    NSString *remoteRevision = [[[[[_installerFilename componentsSeparatedByString:@"."] objectAtIndex:0] componentsSeparatedByString:@"_"] objectAtIndex:2] substringFromIndex:1];
    
    [_availableRevisionTextField setStringValue:remoteRevision];
    
    [_lastUpdateTextField setStringValue:[_lastUpdateTextField.formatter stringFromDate:now]];
    [AnyPreferencesController setKey:CFSTR(kCloverLastCheckTimestamp) forAppID:CFSTR(kCloverUpdaterIdentifier) fromDate:now];
    
    if ([_bootedRevisionTextField intValue] < [_availableRevisionTextField intValue]) {
        [self changeProgressionTitle:@"Download..." isInProgress:NO];
    }
    else if (_hasForcedUpdateCheck) {
        _hasForcedUpdateCheck = NO;
        
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert setIcon:[NSImage imageNamed:NSImageNameInfo]];
        [alert setMessageText:GetLocalizedString(@"No new Clover revisions are avaliable at this time!")];
        [alert setInformativeText:GetLocalizedString(@"Clover updates check completed")];
        [alert addButtonWithTitle:GetLocalizedString(@"Ok")];
        
        [alert beginSheetModalForWindow:[self.mainView window] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        
        [self changeProgressionTitle:@"Check now" isInProgress:NO];
    }
    else {
        [self changeProgressionTitle:@"Check now" isInProgress:NO];
    }
}

- (void)volumesChanged:(id)sender
{
    // Force update booter paths
    _diskutilList = nil;
    _mountedVolumes = nil;
    
    // force rfresh clover paths
    self.cloverPathsCollection = nil;
}

- (void)updatesIntervalChanged:(id)sender
{
    [self setUpdatesInterval:[sender tag]];
}

- (void)checkForUpdatePressed:(id)sender
{
    if ([_bootedRevisionTextField intValue] < [_availableRevisionTextField intValue]) {

        //[[NSWorkspace sharedWorkspace] launchApplication:updaterPath];
        NSSavePanel *panel = [NSSavePanel savePanel];
        
        [panel setNameFieldStringValue:[_installerFilename lastPathComponent]];
        [panel setTitle:GetLocalizedString(@"Set Clover installer location")];
        
        [panel beginSheetModalForWindow:[self.mainView window] completionHandler:^(NSInteger result) {
        
            if (result == NSFileHandlingPanelOKButton) {
                
                _installerFilename = panel.URL.path;
                [NSTask launchedTaskWithLaunchPath:[[self.bundle resourcePath] stringByAppendingPathComponent:@kCloverUpdaterExecutable] arguments:[NSArray arrayWithObjects:@"update", _installerFilename, nil]];
            }
        }];
    }
    else {
        _hasForcedUpdateCheck = YES;
        
        NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@kCloverLatestInstallerURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
        
        if ([NSURLConnection connectionWithRequest:request delegate:self]) {
            [self changeProgressionTitle:@"Checking..." isInProgress:YES];
        }
    }
}

-(void)setCurrentCloverPathPressed:(NSString *)cloverPath
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setResolvesAliases:YES];
    
    [panel setTitle:GetLocalizedString(@"Set custom Clover location")];
    [panel setPrompt:GetLocalizedString(@"Choose EFI folder")];
        
    [panel beginSheetModalForWindow:[self.mainView window] completionHandler:^(NSInteger result){
        
        // Hide the open panel.
        [panel orderOut:self];
        
        // If the return code wasn't OK, don't do anything.
        if (result != NSOKButton) {
            return;
        }
        // Get the first URL returned from the Open Panel and set it at the first path component of the control.
        NSURL *url = [[panel URLs] objectAtIndex:0];
        
        if ([url.path.lastPathComponent isCaseInsensitiveLike:@"EFI"]) {
            self.cloverPath = [url.path stringByAppendingPathComponent:@"CLOVER"];
        }
        if ([url.path.lastPathComponent isCaseInsensitiveLike:@"BOOT"]) {
            self.cloverPath = [[url.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"CLOVER"];
        }
        else if ([url.path.lastPathComponent isCaseInsensitiveLike:@"CLOVER"]) {
            self.cloverPath = url.path;
        }
    }];
}

- (void)saveSettingsPressed:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"plist", nil]];
    [panel setAllowsOtherFileTypes:NO];
    [panel setCanCreateDirectories:YES];
    [panel setCanSelectHiddenExtension:NO];

    [panel setTitle:GetLocalizedString(@"Save Clover setting")];
    [panel setNameFieldStringValue:@"config.plist"];
    
    [panel beginSheetModalForWindow:[self.mainView window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSString *command = [NSString stringWithFormat:@"%@ >%@", [self.bundle pathForResource:@"getconfig" ofType:@""], [[panel URL] path]];
            
            system([command UTF8String]);
        }
    }];
}

- (void)revealCurrentConfigPressed:(id)sender
{
    [[NSWorkspace sharedWorkspace] selectFile:self.cloverConfigPath inFileViewerRootedAtPath:nil];
    //[[NSWorkspace sharedWorkspace] openFile:self.cloverConfigPath withApplication:@"Finder"];
}

- (void)popupToolTip:(id)sender
{
    [NSPopover showRelativeToRect:[sender frame]
                           ofView:[sender superview]
                    preferredEdge:NSMaxXEdge
                           string:[sender toolTip]
                  backgroundColor:[NSColor colorWithCalibratedWhite:0.95 alpha:0.95]
                         maxWidth:250.0];
}

#pragma mark -
#pragma mark NVRAM methods

- (NSString*)getNvramKey:(const char *)key
{
    if (!_ioRegistryOptions) {
        _ioRegistryOptions = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/options");
    }
    
    NSString* result = @"-";
    
    CFStringRef nameRef = CFStringCreateWithCString(kCFAllocatorDefault, key, kCFStringEncodingUTF8);
    if (nameRef == 0) {
        NSLog(@"Error creating CFString for key %s", key);
        return result;
    }
    
    CFTypeRef valueRef = IORegistryEntryCreateCFProperty(_ioRegistryOptions, nameRef, 0, 0);
    CFRelease(nameRef);
    if (valueRef == 0) {
        return result;
    }
    
    // Get the OF variable's type.
    CFTypeID typeID = CFGetTypeID(valueRef);
    
    if (typeID == CFDataGetTypeID()) {
        result = [NSString stringWithUTF8String:(const char*)CFDataGetBytePtr(valueRef)];
    }
    else if (typeID == CFStringGetTypeID()) {
        result = (__bridge NSString *)(CFStringCreateCopy(kCFAllocatorDefault, valueRef));
    }
    
    CFRelease(valueRef);
    
    return result;
}

- (OSErr)setNvramKey:(const char *)key value:(const char *)value
{
    if (!_ioRegistryOptions) {
        _ioRegistryOptions = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/options");
    }
    
    OSErr processError = 0;
    
    if (key) {
        if (!value) {
            value="";
        }
        
        // Size for key=value + null terminal char
        size_t len=strlen(key) + 1 + strlen(value) + 1;
        char* nvram_arg=(char*) malloc(sizeof(char) * len);
        snprintf(nvram_arg, len, "%s=%s", key, value);
        
        // Need 2 parameters: key=value and NULL
        const char **argv = (const char **)malloc(sizeof(char *) * 2);
        argv[0] = nvram_arg;
        argv[1] = NULL;
        
        processError = AuthorizationExecuteWithPrivileges([[_authorizationView authorization] authorizationRef], [@"/usr/sbin/nvram" UTF8String], kAuthorizationFlagDefaults, (char *const *)argv, nil);
        
        if (processError != errAuthorizationSuccess) {
            NSLog(@"Error trying to set nvram %s:%d", nvram_arg, processError);
        }
        
        free(argv);
        free(nvram_arg);
    }
    
    
    return processError;
}

#pragma mark -
#pragma mark SFAuthorization delegate

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self setIsUnlocked:[NSNumber numberWithBool:YES]];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{
    [self setIsUnlocked:[NSNumber numberWithBool:NO]];
}

@end
