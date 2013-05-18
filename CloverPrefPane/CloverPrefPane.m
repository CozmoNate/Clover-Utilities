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
        
        _diskutilList = (__bridge NSDictionary *)(CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)data,
                                                                                  kCFPropertyListImmutable,
                                                                                  NULL));
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

- (NSArray*)volumes
{
    return [[self diskutilList] objectForKey:@"VolumesFromDisks"];
}

- (NSDictionary*)themesInfo
{
    if (nil == _themesInfo) {
        _themesInfo = [NSDictionary dictionaryWithContentsOfFile:[self.bundle pathForResource:@"themes" ofType:@"plist"]];
    }
    
    return _themesInfo;
}

-(void)setCloverTheme:(NSString *)cloverTheme
{
    if (![_cloverTheme isEqualToString:cloverTheme]) {
        _cloverTheme = cloverTheme;
        
        NSDictionary *themeInfo = [[self themesInfo] objectForKey:[self cloverTheme]];
        NSString *path = [self.bundle pathForResource:self.cloverTheme ofType:@"png"];
        
        [self setCloverThemeImage:[[NSImage alloc] initWithContentsOfFile:path ? path : [self.bundle pathForResource:@"NoPreview" ofType:@"png"]]];
        [self setCloverThemeInfo:themeInfo];
    }
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
                            for (NSDictionary *partitionEntry in partitions) {
                                
                                NSString *content = [partitionEntry objectForKey:@"Content"];
                                
                                if (content != nil && [content isEqualToString:@"EFI"]) {
                                    
                                    NSString *identifier = [partitionEntry objectForKey:@"DeviceIdentifier"];
                                    
                                    if (identifier != nil) {
                                        NSDictionary *partitionInfo = [self getPartitionInfo:identifier];
                                        
                                        if (partitionInfo != nil) {
                                            
                                            NSString *name = [NSString stringWithFormat:GetLocalizedString(@"EFI on %@"), diskIdentifier];
                                            NSString *uuid = [partitionInfo objectForKey:@"VolumeUUID"];
                                            
                                            AddMenuItemToSourceList(list, name, (uuid != nil ? uuid : identifier));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
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
                                                
                                                NSString *uuid = [partitionInfo objectForKey:@"VolumeUUID"];
                                                
                                                AddMenuItemToSourceList(list, name, (uuid != nil ? uuid : identifier));
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
        
        for (NSString *volume in [self volumes]) {
            [list addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                             volume, @"Title",
                             volume, @"Value",
                             nil]];
        }

        _nvramPartitions = [NSArray arrayWithArray:list];
    }
    
    return _nvramPartitions;
}

- (void)mainViewDidLoad
{
    // Allow readwrite for accessing IORegistry
    mach_port_t   masterPort;
    
    kern_return_t result = IOMasterPort(bootstrap_port, &masterPort);
    if (result != KERN_SUCCESS) {
        NSLog(@"Error getting the IOMaster port: %s", mach_error_string(result));
        exit(1);
    }
    
    _gOptionsRef = IORegistryEntryFromPath(masterPort, "IODeviceTree:/options");
    if (_gOptionsRef == 0) {
        NSLog(@"NVRAM is not supported on this system");
        exit(1);
    }
    
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
    
    [self setKernelBootArgs:[self getNvramKey:"boot-args"]];
    
    [self setCloverTheme:[self getNvramKey:"Clover.Theme"]];
    
    [self setCloverOldLogLineCount:[NSNumber numberWithInteger:[[self getNvramKey:"Clover.LogLineCount"] integerValue]]];

    NSString *logEveryBoot = [self getNvramKey:"Clover.LogEveryBoot"];
    if ([logEveryBoot isCaseInsensitiveLike:@"No"]) {
        [self setCloverTimestampLogsEnabled:[NSNumber numberWithBool:NO]];
        [self setCloverTimestampLogsLimit:[NSNumber numberWithInteger:0]];
    }
    else if ([logEveryBoot isCaseInsensitiveLike:@"Yes"]) {
        [self setCloverTimestampLogsEnabled:[NSNumber numberWithBool:YES]];
        [self setCloverTimestampLogsLimit:[NSNumber numberWithInteger:0]];
    }
    else {
        [self setCloverTimestampLogsEnabled:[NSNumber numberWithBool:YES]];
        [self setCloverTimestampLogsLimit:[NSNumber numberWithInteger:[logEveryBoot integerValue]]];
    }

    [self setCloverMountEfiPartition:[self getNvramKey:"Clover.MountEFI"]];
    [self setCloverNvramPartition:[self getNvramKey:"Clover.NVRamDisk"]];
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

#pragma mark Events

- (IBAction)updatesIntervalChanged:(id)sender
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

- (IBAction)checkForUpdatePressed:(id)sender
{
    [_lastUpdateTextField setStringValue:[_lastUpdateTextField.formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]]];
    
    [[NSWorkspace sharedWorkspace] launchApplication:@kCloverUpdaterExecutable];
}

- (void)kernelBootArgsChanged:(id)sender
{
    [self setNvramKey:"boot-args" value:[self.kernelBootArgs UTF8String]];
}

- (void)cloverThemeVariableChanged:(id)sender
{
    [self setNvramKey:"Clover.Theme" value:[self.cloverTheme UTF8String]];
}

- (void)cloverOldLogLinesVariableChanged:(id)sender
{
    [self setNvramKey:"Clover.LogLineCount" value:[[NSString stringWithFormat:@"%ld", (long)[sender integerValue]] UTF8String]];
}

- (void)cloverTimestampLogVariableChanged:(id)sender
{
    if (![[self cloverTimestampLogsEnabled] integerValue]) {
        [self setNvramKey:"Clover.LogEveryBoot" value:"No"];
    }
    else if (![[self cloverTimestampLogsLimit] integerValue]) {
        [self setNvramKey:"Clover.LogEveryBoot" value:"Yes"];
    }
    else {
        [self setNvramKey:"Clover.LogEveryBoot" value:[[NSString stringWithFormat:@"%ld", (long)[self.cloverTimestampLogsLimit integerValue]] UTF8String]];   
    }
}

- (IBAction)cloverMountEfiVariableChanged:(id)sender
{
    [self setNvramKey:"Clover.MountEFI" value:[self.cloverMountEfiPartition UTF8String]];
}

- (IBAction)cloverNvramDiskVariableChanged:(id)sender
{
    [self setNvramKey:"Clover.NVRamDisk" value:[self.cloverNvramPartition UTF8String]];
}

#pragma mark NVRAM methods

- (NSString*)getNvramKey:(const char *)key
{
    NSString* result = @"-";
    
    CFStringRef nameRef = CFStringCreateWithCString(kCFAllocatorDefault, key, kCFStringEncodingUTF8);
    if (nameRef == 0) {
        NSLog(@"Error creating CFString for key %s", key);
        return result;
    }
    
    CFTypeRef valueRef = IORegistryEntryCreateCFProperty(_gOptionsRef, nameRef, 0, 0);
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
