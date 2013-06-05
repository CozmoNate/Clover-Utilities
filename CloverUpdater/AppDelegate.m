//
//  AppDelegate.m
//  CloverUpdater
//
//  Created by Kozlek on 18/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

#import "AppDelegate.h"

#define GetLocalizedString(key) \
[[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

#define kCloverUpdaterIdentifier "com.projectosx.Clover.Updater"
#define kCloverLatestInstallerURL "http://sourceforge.net/projects/cloverefiboot/files/latest/download"

@implementation AppDelegate

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

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    BOOL forced = args && [args count] && [[args objectAtIndex:1] isEqualToString:@"forced"];
    
    NSUInteger lastCheckTimestamp = [self getUIntPreferenceKey:CFSTR("LastCheckTimestamp") forAppID:CFSTR(kCloverUpdaterIdentifier) withDefault:0];
    NSTimeInterval intervalFromRef = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970];
    
    if ((lastCheckTimestamp && lastCheckTimestamp > intervalFromRef) || forced) {
        [self setPreferenceKey:CFSTR("LastCheckTimestamp") forAppID:CFSTR(kCloverUpdaterIdentifier) fromInt:intervalFromRef];
        CFPreferencesAppSynchronize(CFSTR(kCloverUpdaterIdentifier)); // Force the preferences to be save to disk
        
        NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@kCloverLatestInstallerURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
        
        if (![[NSURLConnection alloc]initWithRequest:request delegate:self]) {
            [NSApp terminate:self];
        }
    }
    else {
        [NSApp terminate:self];
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    
    NSString *remoteString = [[[[[response.suggestedFilename componentsSeparatedByString:@"."] objectAtIndex:0] componentsSeparatedByString:@"_"] objectAtIndex:2] substringFromIndex:1];
    NSNumber *remote = [formatter numberFromString:remoteString];

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

    NSNumber *local = [formatter numberFromString:bootedRevision];
    
    if ([remote isGreaterThan:local]) {
        [_hasUpdateTextField setStringValue:[NSString stringWithFormat:GetLocalizedString([_hasUpdateTextField stringValue]), remote.intValue, local.intValue]];

        [self performSelector:@selector(showHasUpdatesWindow) withObject:nil afterDelay:1.0];
    }
    else {
        [self performSelector:@selector(showNoUpdatesWindow) withObject:nil afterDelay:1.0];
    }
}

- (void)showHasUpdatesWindow
{
    [NSApp activateIgnoringOtherApps:YES];
    [_hasUpdateWindow setLevel:NSModalPanelWindowLevel];
    [_hasUpdateWindow makeKeyAndOrderFront:self];
}

- (void)showNoUpdatesWindow
{
    [NSApp activateIgnoringOtherApps:YES];
    [_noUpdatesWindow setLevel:NSModalPanelWindowLevel];
    [_noUpdatesWindow makeKeyAndOrderFront:self];
}

- (IBAction)doUpdate:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@kCloverLatestInstallerURL]];
    [NSApp terminate:self];
}


@end
