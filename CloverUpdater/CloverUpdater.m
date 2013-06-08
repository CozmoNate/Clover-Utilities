//
//  AppDelegate.m
//  CloverUpdater
//
//  Created by Kozlek on 18/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

#import "CloverUpdater.h"

#import "Definitions.h"
#import "Localizer.h"
#import "AnyPreferencesController.h"

#define GetLocalizedString(key) \
[[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

@implementation CloverUpdater

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    BOOL forced = args && [args count] && [[args objectAtIndex:1] isEqualToString:@"forced"];

    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    
    NSTimeInterval lastCheckTimestamp = [[AnyPreferencesController getDateFromKey:CFSTR(kCloverLastCheckTimestamp) forAppID:CFSTR(kCloverUpdaterIdentifier)] timeIntervalSince1970];
    NSTimeInterval intervalFromRef = [now timeIntervalSince1970];
    
    if ((lastCheckTimestamp && lastCheckTimestamp > intervalFromRef) || forced) {
        [AnyPreferencesController setKey:CFSTR(kCloverLastCheckTimestamp) forAppID:CFSTR(kCloverUpdaterIdentifier) fromDate:now];
        [AnyPreferencesController synchronizeforAppID:CFSTR(kCloverUpdaterIdentifier)];
        
        NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@kCloverLatestInstallerURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        
        if (![[NSURLConnection alloc]initWithRequest:request delegate:self]) {
            [NSApp terminate:self];
        }
    }
    else {
        [NSApp terminate:self];
    }
    
    [Localizer localizeView:_hasUpdateWindow];
    [Localizer localizeView:_noUpdatesWindow];
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
