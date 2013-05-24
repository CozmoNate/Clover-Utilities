//
//  CloverPrefPane.m
//  CloverPrefPane
//
//  Created by Kozlek on 15/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

#import "CloverPrefPane.h"

#include <mach/mach_error.h>
#include <sys/mount.h>

#define kCloverUpdaterIdentifier "com.projectosx.Clover.Updater"
#define kCloverUpdaterExecutable "/Library/Application Support/Clover/CloverUpdaterUtility"

#define GetLocalizedString(key) \
[self.bundle localizedStringForKey:(key) value:@"" table:nil]

@implementation CloverPrefPane

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
        
        NSArray *urls = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:[NSArray arrayWithObject:NSURLVolumeNameKey] options:0];
        
        for (NSURL *url in urls) {
            NSError *error;
            NSString *volumeName = nil;
            
            [url getResourceValue:&volumeName forKey:NSURLVolumeNameKey error:&error];
            
            if (volumeName) {
                [list addObject:volumeName];
            }
        }
        
        _mountedVolumes = [list copy];
    }
    
    return _mountedVolumes;//[[self diskutilList] objectForKey:@"VolumesFromDisks"];
}

#define AddMenuItemToSourceList(list, title, value) \
[list addObject:[NSDictionary dictionaryWithObjectsAndKeys: \
(title), @"Title", \
(value), @"Value", nil]]

- (NSArray*)efiPartitions
{
    if (nil == _efiPartitions) {
        NSMutableArray *list = [[NSMutableArray alloc] init];
        
        AddMenuItemToSourceList(list, GetLocalizedString(@"None"), @"No");
        AddMenuItemToSourceList(list, GetLocalizedString(@"Boot Volume"), @"Yes");
        
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
                                        NSDictionary *partitionInfo = [self getPartitionInfo:identifier];
                                        
                                        if (partitionInfo != nil) {
                                            
                                            //NSString *name = [NSString stringWithFormat:GetLocalizedString(@"EFI on %@"), diskIdentifier];
                                            //NSString *uuid = [partitionInfo objectForKey:@"VolumeUUID"];
                                            
                                            //AddMenuItemToSourceList(list, name, (uuid != nil ? uuid : identifier));
                                            espIdentifier = [partitionInfo objectForKey:@"VolumeUUID"];
                                            
                                            if (!espIdentifier) {
                                                espIdentifier = identifier;
                                            }
                                        }
                                    }
                                }
                                
                                NSString *volumeName = [partitionEntry objectForKey:@"VolumeName"];
                                
                                if (volumeName) {
                                    [volumeNames addObject:volumeName];
                                }
                            }
                            
                            if (espIdentifier) {
                                NSString *name = [NSString stringWithFormat:GetLocalizedString(@"EFI on %@ [%@]"), [volumeNames componentsJoinedByString:@","], diskIdentifier];
                                
                                AddMenuItemToSourceList(list, name, espIdentifier);
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

- (NSArray*)nvramPartitions
{
    if (nil == _nvramPartitions) {
        NSMutableArray *list = [[NSMutableArray alloc] init];
        
        AddMenuItemToSourceList(list, GetLocalizedString(@"No"), @"No");
        AddMenuItemToSourceList(list, GetLocalizedString(@"Default"), @"Yes");
        
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
                                                
                                                name = [NSString stringWithFormat:@"%@ [%@]", identifier, name == nil || [name length] == 0 ? [content isEqualToString:@"EFI"] ? @"EFI" : identifier : name];
                                                
                                                // uuid not supported by script
                                                //NSString *uuid = [partitionInfo objectForKey:@"VolumeUUID"];
                                                
                                                //AddMenuItemToSourceList(list, name, (uuid != nil ? uuid : identifier));
                                                AddMenuItemToSourceList(list, name, identifier);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // Whole disk is Apple_HFS
                    //                else if ([content isEqualToString:@"Apple_HFS"]) {
                    //                }
                }
            }
        }
        
        _nvramPartitions = [NSArray arrayWithArray:list];
    }
    
    return _nvramPartitions;
}

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
        
        // Reset current themes db forsing it to reload from new path
        self.cloverThemesCollection = nil;
        self.cloverOemCollection = nil;
    }
}

-(NSArray *)cloverOemCollection
{
    if (!_cloverOemCollection) {
        _cloverOemCollection = [self getCloverOemcollectionFromPath:self.cloverPath];
    }
    
    return _cloverOemCollection;
}

-(void)setCloverOemCollection:(NSArray *)cloverOemProductsCollection
{
    if (!cloverOemProductsCollection) {
        _cloverOemCollection = [self getCloverOemcollectionFromPath:self.cloverPath];
    }
    else {
        _cloverOemCollection = cloverOemProductsCollection;
    }
    
    self.cloverOemPath = nil;
}

-(NSString *)cloverOemPath
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"lastOemProductSelected"];
}

-(void)setCloverOemPath:(NSString *)cloverOemProduct
{
    if (![self.cloverOemPath isEqualToString:cloverOemProduct]) {
        [[NSUserDefaults standardUserDefaults] setObject:cloverOemProduct forKey:@"lastOemProductSelected"];
        self.cloverConfig = nil;
    }
}

-(NSDictionary *)cloverConfig
{
    if (!_cloverConfig) {
        NSString *configPath = [self.cloverOemPath stringByAppendingPathComponent:@"config.plist"];
        NSLog(@"loading config: %@", configPath);
        _cloverConfig = [NSDictionary dictionaryWithContentsOfFile:configPath];
    }
    
    return _cloverConfig;
}

-(void)setCloverConfig:(NSDictionary *)cloverConfig
{
    _cloverConfig = cloverConfig;
    
    if (cloverConfig) {
        [_cloverConfig writeToFile:[self.cloverOemPath stringByAppendingPathComponent:@"config.plist"] atomically:YES];
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
        _cloverTheme = [self getNvramKey:"Clover.Theme"];
        
        self.CloverThemeInfo = [self.cloverThemesCollection objectForKey:_cloverTheme];
    }
    
    return _cloverTheme;
}

- (void)setCloverTheme:(NSString *)cloverTheme
{
    if (![self.cloverTheme isEqualToString:cloverTheme]) {
        _cloverTheme = cloverTheme;
        [self setNvramKey:"Clover.Theme" value:[cloverTheme UTF8String]];
    }
    
    self.CloverThemeInfo = [self.cloverThemesCollection objectForKey:cloverTheme];
}

- (NSNumber*)cloverOldLogLineCount
{
    if (!_cloverOldLogLineCount) {
        _cloverOldLogLineCount = [NSNumber numberWithInteger:[[self getNvramKey:"Clover.LogLineCount"] integerValue]];
    }
    
    return _cloverOldLogLineCount;
}

-(void)setCloverOldLogLineCount:(NSNumber *)cloverOldLogLineCount
{
    if (![self.cloverOldLogLineCount isEqualToNumber:cloverOldLogLineCount]) {
        _cloverOldLogLineCount = cloverOldLogLineCount;
        
        [self setNvramKey:"Clover.LogLineCount" value:[[NSString stringWithFormat:@"%ld", (long)[cloverOldLogLineCount integerValue]] UTF8String]];
    }
}

-(NSString *)cloverLogEveryBoot
{
    if (!_cloverLogEveryBoot) {
        _cloverLogEveryBoot = [self getNvramKey:"Clover.LogEveryBoot"];
    }
    
    return _cloverLogEveryBoot;
}

-(void)setCloverLogEveryBoot:(NSString *)cloverLogEveryBoot
{
    if (![self.cloverLogEveryBoot isCaseInsensitiveLike:cloverLogEveryBoot]) {
        _cloverLogEveryBoot = cloverLogEveryBoot;
        
        [self setNvramKey:"Clover.LogEveryBoot" value:[cloverLogEveryBoot UTF8String]];
    }
}

- (NSNumber*)cloverLogEveryBootEnabled
{
    if ([self.cloverLogEveryBoot isCaseInsensitiveLike:@"No"]) {
        return [NSNumber numberWithBool:NO];
    }
    else if ([self.cloverLogEveryBoot isCaseInsensitiveLike:@"Yes"] || [_cloverLogEveryBoot integerValue] >= 0) {
        return [NSNumber numberWithBool:YES];
    }
    
    return [NSNumber numberWithBool:NO];
}

- (void)setCloverLogEveryBootEnabled:(NSNumber *)cloverTimestampLogsEnabled
{
    if (![self.cloverLogEveryBootEnabled isEqualToNumber:cloverTimestampLogsEnabled]) {
        self.cloverLogEveryBoot = [cloverTimestampLogsEnabled boolValue] ? @"Yes" : @"No";
    }
}

- (NSNumber*)cloverLogEveryBootLimit
{
    if ([self.cloverLogEveryBoot isCaseInsensitiveLike:@"No"] || [self.cloverLogEveryBoot isCaseInsensitiveLike:@"Yes"]) {
        return [NSNumber numberWithInteger:0];
    }

    return [NSNumber numberWithInteger:[self.cloverLogEveryBoot integerValue]];
}

- (void)setCloverLogEveryBootLimit:(NSNumber *)cloverLogEveryBootLimit
{
    if (![self.cloverLogEveryBootLimit isEqualToNumber:cloverLogEveryBootLimit]) {
        self.cloverLogEveryBoot = [NSString stringWithFormat:@"%ld", [cloverLogEveryBootLimit integerValue]];
    }
}

-(NSString *)cloverMountEfiPartition
{
    if (!_cloverMountEfiPartition) {
        _cloverMountEfiPartition = [self getNvramKey:"Clover.MountEFI"];
    }
    
    return _cloverMountEfiPartition;
}

-(void)setCloverMountEfiPartition:(NSString *)cloverMountEfiPartition
{
    if (![self.cloverMountEfiPartition isEqualToString:cloverMountEfiPartition]) {
        _cloverMountEfiPartition = cloverMountEfiPartition;
        
        [self setNvramKey:"Clover.MountEFI" value:[cloverMountEfiPartition UTF8String]];
    }
}

-(NSString *)cloverNvramPartition
{
    if (!_cloverNvramPartition) {
        _cloverNvramPartition = [self getNvramKey:"Clover.NVRamDisk"];
    }
    
    return _cloverNvramPartition;
}

-(void)setCloverNvramPartition:(NSString *)cloverNvramPartition
{
    if (![self.cloverNvramPartition isEqualToString:cloverNvramPartition]) {
        _cloverNvramPartition = cloverNvramPartition;
        
        [self setNvramKey:"Clover.NVRamDisk" value:[cloverNvramPartition UTF8String]];
    }
}

#pragma mark Methods

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
    
    for (NSString *volume in [self mountedVolumes]) {
        
        NSString *path = [NSString stringWithFormat:@"/Volumes/%@/EFI/Clover", volume];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            AddMenuItemToSourceList(list, ([NSString stringWithFormat:GetLocalizedString(@"Clover on %@"), volume]), path);
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
                                
                [themeInfo setObject:[[NSImage alloc] initWithContentsOfFile:imagePath] forKey:@"Preview"];
            }
        }
    }
    
    return [themes copy];
}

- (NSArray*)getCloverOemcollectionFromPath:(NSString*)path
{
    NSString *oemPath = [path stringByAppendingPathComponent:@"OEM"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:oemPath]) {
        return [NSArray array];
    }
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"config.plist"]]) {
        AddMenuItemToSourceList(list, @"Default", path);
    }
    
    NSDirectoryEnumerator *enumarator = [[NSFileManager defaultManager] enumeratorAtPath:oemPath];
    
    NSString *productSubPath = nil;
    
    while (productSubPath = [enumarator nextObject]) {
        
        NSString *productPath = [oemPath stringByAppendingPathComponent:productSubPath];

        if ([[NSFileManager defaultManager] fileExistsAtPath:[productPath stringByAppendingPathComponent:@"config.plist"]]) {
            AddMenuItemToSourceList(list, productSubPath, productPath);
        }
    }
    
    if ([list count]) {
        return [list copy];
    }
    
    return nil;
}

#pragma mark Events


- (void)mainViewDidLoad
{
    // Setup security.
	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &items};
    
  	_authorizationView.delegate = self;
	[_authorizationView setAuthorizationRights:&rights];
	[_authorizationView updateStatus:nil];
    
    // Updater
    BOOL plistExists;
    
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *agentsFolder = [[searchPaths objectAtIndex:0] stringByAppendingPathComponent:@"LaunchAgents"];
    [[NSFileManager defaultManager] createDirectoryAtPath:agentsFolder withIntermediateDirectories:YES attributes:nil error:nil];
    _updaterPlistPath = [[agentsFolder stringByAppendingPathComponent:@kCloverUpdaterIdentifier] stringByAppendingPathExtension:@"plist"];
    
    // Initialize revision fields
    searchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
    NSString *preferenceFolder = [[searchPaths objectAtIndex:0] stringByAppendingPathComponent:@"Preferences"];
    NSString *cloverInstallerPlist = [[preferenceFolder stringByAppendingPathComponent:(NSString *)CFSTR("com.projectosx.clover.installer")] stringByAppendingPathExtension:@"plist"];
    plistExists = [[NSFileManager defaultManager] fileExistsAtPath:cloverInstallerPlist];
    NSString* installedRevision = @"-";
    if (plistExists) {
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:cloverInstallerPlist];
        NSNumber* revision = [dict objectForKey:@"CloverRevision"];
        if (revision) {
            installedRevision = [revision stringValue];
        }
    }
    [_lastInstalledTextField setStringValue:installedRevision];
    
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
                if (typeID == CFDataGetTypeID())
                    bootedRevision = [NSString stringWithFormat:@"%u",*((uint32_t*)CFDataGetBytePtr(valueRef))];
                CFRelease(valueRef);
            }
        }
        IOObjectRelease(ioRegistryEFI);
    }
    [_lastBootedTextField setStringValue:bootedRevision];
    
    // Initialize popUpCheckInterval
    unsigned int checkInterval = [self getUIntPreferenceKey:CFSTR("ScheduledCheckInterval") forAppID:CFSTR(kCloverUpdaterIdentifier) withDefault:0];
    [_updatesIntervalPopup selectItemWithTag:checkInterval];
    
    // Init last updates check date
    unsigned int lastCheckTimestamp = [self getUIntPreferenceKey:CFSTR("LastCheckTimestamp") forAppID:CFSTR(kCloverUpdaterIdentifier) withDefault:0];
    if (lastCheckTimestamp == 0) {
        [_lastUpdateTextField setStringValue:@"-"];
    } else {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:lastCheckTimestamp];
        [_lastUpdateTextField setStringValue:[_lastUpdateTextField.formatter stringFromDate:date]];
    }
    
    // Disable the checkNowButton if executable is not present
    [_checkNowButton setEnabled:[[NSFileManager defaultManager] fileExistsAtPath:@kCloverUpdaterExecutable]];
    
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector: @selector(volumesChanged:) name:NSWorkspaceDidMountNotification object: nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector: @selector(volumesChanged:) name:NSWorkspaceDidUnmountNotification object:nil];
}

- (void)volumesChanged:(id)sender
{
    // Force update booter paths
    NSLog(@"volumes did changed");

    _diskutilList = nil;
    _mountedVolumes = nil;
}

- (void)updatesIntervalChanged:(id)sender
{
    CFDictionaryRef launchInfo = SMJobCopyDictionary(kSMDomainUserLaunchd, CFSTR(kCloverUpdaterIdentifier));
    if (launchInfo != NULL) {
        CFRelease(launchInfo);
        CFErrorRef error = NULL;
        if (!SMJobRemove(kSMDomainUserLaunchd, CFSTR(kCloverUpdaterIdentifier), NULL, YES, &error))
            NSLog(@"Error in SMJobRemove: %@", error);
        if (error)
            CFRelease(error);
    }
	
    NSInteger checkInterval = [sender tag];
    
	[self setPreferenceKey:CFSTR("ScheduledCheckInterval") forAppID:CFSTR(kCloverUpdaterIdentifier) fromInt:(int)checkInterval];
    
    if (checkInterval > 0 && [[NSFileManager defaultManager] fileExistsAtPath:@kCloverUpdaterExecutable]) {
        // Create a new plist
        NSArray* call = [NSArray arrayWithObjects:
                         @kCloverUpdaterExecutable,
                         @"startup",
                         nil];
        
        NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      @kCloverUpdaterIdentifier, @"Label",
                                      [NSNumber numberWithInteger:checkInterval], @"StartInterval",
                                      [NSNumber numberWithBool:YES], @"RunAtLoad",
                                      @kCloverUpdaterExecutable, @"Program",
                                      call, @"ProgramArguments",
                                      nil];
        
        [plist writeToFile:_updaterPlistPath atomically:YES];
        
		CFErrorRef error = NULL;
		if (!SMJobSubmit(kSMDomainUserLaunchd, (__bridge CFDictionaryRef)plist, NULL, &error)) {
			if (error) {
				NSLog(@"Error in SMJobSubmit: %@", error);
			} else
				NSLog(@"Error in SMJobSubmit without details. Check /var/db/launchd.db/com.apple.launchd.peruser.NNN/overrides.plist for %@ set to disabled.", @kCloverUpdaterIdentifier);
		}
		if (error)
			CFRelease(error);
    } else {
        // Remove the plist
        [[NSFileManager defaultManager] removeItemAtPath:_updaterPlistPath error:nil];
    }
    
    CFPreferencesAppSynchronize(CFSTR(kCloverUpdaterIdentifier)); // Force the preferences to be save to disk
}

- (void)checkForUpdatePressed:(id)sender
{
    [_lastUpdateTextField setStringValue:[_lastUpdateTextField.formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]]];
    
    [[NSWorkspace sharedWorkspace] launchApplication:@kCloverUpdaterExecutable];
}

- (void)saveSettingsPressed:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"plist", nil]];
    [panel setAllowsOtherFileTypes:NO];
    [panel setCanCreateDirectories:YES];
    [panel setCanSelectHiddenExtension:NO];
    
    [panel setTitle:GetLocalizedString(@"Save Clover setting")];
    [panel setNameFieldStringValue:@"settings.plist"];
    
    [panel beginSheetModalForWindow:[self.mainView window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSString *command = [NSString stringWithFormat:@"%@ >%@", [self.bundle pathForResource:@"getconfig" ofType:@""], [[panel URL] path]];
            
            NSLog(@"command: %@", command);
            
            system([command UTF8String]);
        }
    }];
}

- (void)editCurrentConfigPressed:(id)sender
{
//    NSString *command = [NSString stringWithFormat:@"%@ >%@", [self.bundle pathForResource:@"Property List Editor" ofType:@"app"], [self.cloverOemPath stringByAppendingPathComponent:@"config.plist"]];
//    
//    NSLog(@"command: %@", command);
//    
//    system([command UTF8String]);
    [[NSWorkspace sharedWorkspace] openFile:[self.cloverOemPath stringByAppendingPathComponent:@"config.plist"]];
}

#pragma mark NVRAM methods

- (void)setupIoRegistryOptionsConnection
{
    // Allow readwrite for accessing IORegistry
    mach_port_t   masterPort;
    
    kern_return_t result = IOMasterPort(bootstrap_port, &masterPort);
    if (result != KERN_SUCCESS) {
        NSLog(@"Error getting the IOMaster port: %s", mach_error_string(result));
        exit(1);
    }
    
    _ioRegistryOptions = IORegistryEntryFromPath(masterPort, "IODeviceTree:/options");
    
    if (_ioRegistryOptions == 0) {
        NSLog(@"NVRAM is not supported on this system");
        exit(1);
    }
}

- (void)setupIoRegistryPlatformConnection
{
    // Allow readwrite for accessing IORegistry
    mach_port_t   masterPort;
    
    kern_return_t result = IOMasterPort(bootstrap_port, &masterPort);
    if (result != KERN_SUCCESS) {
        NSLog(@"Error getting the IOMaster port: %s", mach_error_string(result));
        return;
    }
    
    _ioRegistryEfiPlatform = IORegistryEntryFromPath(masterPort, "IODeviceTree:/efi/platform");
    
    if (_ioRegistryEfiPlatform == 0) {
        NSLog(@"EFI is not supported on this system");
        return;
    }
}

- (NSString*)getNvramKey:(const char *)key
{
    if (!_ioRegistryOptions) {
        [self setupIoRegistryOptionsConnection];
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
        [self setupIoRegistryOptionsConnection];
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

#pragma mark get and set preference keys functions 
// idea taken from:
// http://svn.perian.org/branches/perian-1.1/CPFPerianPrefPaneController.m
- (unsigned int)getUIntPreferenceKey:(CFStringRef)key forAppID:(CFStringRef)appID withDefault:(unsigned int)defaultValue
{
	CFPropertyListRef value;
	unsigned int ret = defaultValue;
	
	value = CFPreferencesCopyAppValue(key, appID);
	if (value && CFGetTypeID(value) == CFNumberGetTypeID())
		CFNumberGetValue(value, kCFNumberIntType, &ret);
	
	if (value)
		CFRelease(value);
	
	return ret;
}

- (void)setPreferenceKey:(CFStringRef)key forAppID:(CFStringRef)appID fromInt:(int)value
{
	CFNumberRef numRef = CFNumberCreate(NULL, kCFNumberIntType, &value);
	CFPreferencesSetAppValue(key, numRef, appID);
	CFRelease(numRef);
}

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
