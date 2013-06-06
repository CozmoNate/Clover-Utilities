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
#define kCloverUpdaterExecutable "CloverUpdater.app"

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
        
        NSArray *urls = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:[NSArray arrayWithObject:NSURLVolumeURLKey] options:0];
        
        for (NSURL *url in urls) {
            NSError *error;
            NSString *volumeName = nil;
            
            [url getResourceValue:&volumeName forKey:NSURLVolumeURLKey error:&error];
            
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
    
	[self setPreferenceKey:CFSTR("ScheduledCheckInterval") forAppID:CFSTR(kCloverUpdaterIdentifier) fromInt:(int)checkInterval];
    
    NSString *updaterPath = [[[self.bundle resourcePath] stringByAppendingPathComponent:@kCloverUpdaterExecutable] stringByAppendingPathComponent:@"Contents/MacOS/CloverUpdater"];
    NSLog(@"Clover Updater path: %@", updaterPath);
    
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
    
    CFPreferencesAppSynchronize(CFSTR(kCloverUpdaterIdentifier)); // Force the preferences to be save to disk
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
    
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *agentsFolder = [[searchPaths objectAtIndex:0] stringByAppendingPathComponent:@"LaunchAgents"];
    [[NSFileManager defaultManager] createDirectoryAtPath:agentsFolder withIntermediateDirectories:YES attributes:nil error:nil];
    _updaterPlistPath = [[agentsFolder stringByAppendingPathComponent:@kCloverUpdaterIdentifier] stringByAppendingPathExtension:@"plist"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_updaterPlistPath]) {
        NSLog(@"Setting default updates interval: Daily");
        [self setUpdatesInterval:86400];
    }
    
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
    //[_checkNowButton setEnabled:[[NSFileManager defaultManager] fileExistsAtPath:@kCloverUpdaterExecutable]];
    
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector: @selector(volumesChanged:) name:NSWorkspaceDidMountNotification object: nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector: @selector(volumesChanged:) name:NSWorkspaceDidUnmountNotification object:nil];
    
    // 
    NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@"http://sourceforge.net/projects/cloverefiboot/files/latest/download"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    if (![[NSURLConnection alloc]initWithRequest:request delegate:self]) {
        [NSApp terminate:self];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSString *remoteRevision = [[[[[response.suggestedFilename componentsSeparatedByString:@"."] objectAtIndex:0] componentsSeparatedByString:@"_"] objectAtIndex:2] substringFromIndex:1];
    
    [_latestAvailableTextField setStringValue:remoteRevision];
}

- (void)volumesChanged:(id)sender
{
    // Force update booter paths
    NSLog(@"volumes did changed");

    _diskutilList = nil;
    _mountedVolumes = nil;
    
    // force rfresh clover paths
    self.cloverPathsCollection = nil;
}

- (void)updatesIntervalChanged:(id)sender
{
    [self setUpdatesInterval:[sender tag]];
    CFPreferencesAppSynchronize(CFSTR(kCloverUpdaterIdentifier)); // Force the preferences to be save to disk
}

- (void)checkForUpdatePressed:(id)sender
{
    [_lastUpdateTextField setStringValue:[_lastUpdateTextField.formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]]];
    
    NSString *command = [NSString stringWithFormat:@"%@/Contents/MacOS/CloverUpdater forced", [[self.bundle resourcePath] stringByAppendingPathComponent:@kCloverUpdaterExecutable]];
    system(command.UTF8String);
    //[[NSWorkspace sharedWorkspace] launchApplication:[[self.bundle resourcePath] stringByAppendingPathComponent:@kCloverUpdaterExecutable]];
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
