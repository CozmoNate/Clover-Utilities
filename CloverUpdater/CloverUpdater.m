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
    [Localizer localizeView:_hasUpdateWindow];
    [Localizer localizeView:_noUpdatesWindow];
    [Localizer localizeView:_progressionWindow];
    
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    if (args && [args count] && [[args objectAtIndex:1] isEqualToString:@"update"]) {
        _installerPath = [args objectAtIndex:2];
        _forcedUpdate = YES;
        [self doUpdate:self];
    }
    else {
        BOOL forced = args && [args count] && [[args objectAtIndex:1] isEqualToString:@"forced"];
        
        NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
        
        NSTimeInterval lastCheckTimestamp = [[AnyPreferencesController getDateFromKey:CFSTR(kCloverLastCheckTimestamp) forAppID:CFSTR(kCloverUpdaterIdentifier)] timeIntervalSince1970];
        NSInteger scheduledCheckInterval = [AnyPreferencesController getIntegerFromKey:CFSTR(kCloverScheduledCheckInterval) forAppID:CFSTR(kCloverUpdaterIdentifier) withDefault:0];
        NSTimeInterval intervalFromRef = [now timeIntervalSince1970];
        
        
        if ((scheduledCheckInterval && lastCheckTimestamp && lastCheckTimestamp + scheduledCheckInterval < intervalFromRef) || forced) {
            NSLog(@"Starting updates check...");
            
            [AnyPreferencesController setKey:CFSTR(kCloverLastCheckTimestamp) forAppID:CFSTR(kCloverUpdaterIdentifier) fromDate:now];
            [AnyPreferencesController synchronizeforAppID:CFSTR(kCloverUpdaterIdentifier)];
            
            NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@kCloverLatestInstallerURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
            
            if (![[NSURLConnection alloc] initWithRequest:request delegate:self]) {
                [NSApp terminate:self];
            }
        }
        else {
            NSLog(@"To early to run check. Terminating...");
            
            [NSApp terminate:self];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed with error: %@", error.description);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // Stop downloading installer
    [connection cancel];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    
    _installerPath = response.suggestedFilename;
    
    NSString *remoteString = [[[[[_installerPath componentsSeparatedByString:@"."] objectAtIndex:0] componentsSeparatedByString:@"_"] objectAtIndex:2] substringFromIndex:1];
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

        [self performSelector:@selector(showWindow:) withObject:_hasUpdateWindow afterDelay:1.0];
    }
    else if (_forcedUpdate) {
        [self performSelector:@selector(showWindow:) withObject:_noUpdatesWindow afterDelay:1.0];
    }
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
    NSLog(@"Downloading to: %@", _installerPath);
    [download setDestination:_installerPath allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response;
{
    if ([response expectedContentLength]) {
        [_levelIndicator setHidden:NO];
        [_progressionIndicator setHidden:YES];
        [_levelIndicator setMinValue:0];
        [_levelIndicator setMaxValue:[response expectedContentLength]];
        [_levelIndicator setDoubleValue:0];
    }
    else {
        [_levelIndicator setHidden:YES];
        [_progressionIndicator setHidden:NO];
    }
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
    if (![_levelIndicator isHidden]) {
        [_levelIndicator setDoubleValue:_levelIndicator.doubleValue + length];
        [_progressionValueTextField setStringValue:[NSString stringWithFormat:GetLocalizedString(@"%1.1f Mbytes"), _levelIndicator.doubleValue / (1024 * 1024)]];
    }
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    [[NSWorkspace sharedWorkspace] openFile:_installerPath];
    [NSApp terminate:self];
}

- (void)download:(NSURLDownload *)aDownload didFailWithError:(NSError *)error
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert setIcon:[NSImage imageNamed:NSImageNameCaution]];
    [alert setMessageText:GetLocalizedString(@"An error occured while trying to download Clover installer!")];
    [alert setInformativeText:error.localizedDescription];
    [alert addButtonWithTitle:GetLocalizedString(@"Ok")];
    
    [alert beginSheetModalForWindow:_progressionWindow modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    
//    [self changeProgressionTitle:@"Download..." isInProgress:NO];
}

- (void)showWindow:(NSWindow*)window
{
    [NSApp activateIgnoringOtherApps:YES];
    [window setLevel:NSModalPanelWindowLevel];
    [window makeKeyAndOrderFront:self];
}

- (IBAction)doUpdate:(id)sender
{
//    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@kCloverLatestInstallerURL]];
//    [NSApp terminate:self];
    
    if (_forcedUpdate) {
        NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@kCloverLatestInstallerURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
        
        if ([[NSURLDownload alloc] initWithRequest:request delegate:self]) {
            
            [self showWindow:_progressionWindow];
            
            [_progressionMessageTextField setStringValue:[NSString stringWithFormat:GetLocalizedString(@"Downloading %@"), [_installerPath lastPathComponent]]];
            [_progressionValueTextField setStringValue:@""];
        }
    }
    else {
        NSSavePanel *panel = [NSSavePanel savePanel];
        
        [panel setNameFieldStringValue:[_installerPath lastPathComponent]];
        [panel setTitle:GetLocalizedString(@"Set Clover installer location")];

        [panel beginSheetModalForWindow:_hasUpdateWindow completionHandler:^(NSInteger result) {

            if (result == NSFileHandlingPanelOKButton) {

                _installerPath = panel.URL.path;

                NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@kCloverLatestInstallerURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];

                if ([[NSURLDownload alloc] initWithRequest:request delegate:self]) {
                    [_hasUpdateWindow orderOut:self];
                    
                    [self showWindow:_progressionWindow];
                    
                    [_progressionMessageTextField setStringValue:[NSString stringWithFormat:GetLocalizedString(@"Downloading %@"), [_installerPath lastPathComponent]]];
                    [_progressionValueTextField setStringValue:@""];
                }
            }
        }];
    }
}


@end
