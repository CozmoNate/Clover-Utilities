//
//  AppDelegate.m
//  CloverUpdater
//
//  Created by Kozlek on 18/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//
//  Initial code from Clover by JrCs, slice
//

#import "CloverUpdater.h"

#import "Definitions.h"
#import "Localizer.h"
#import "AnyDefaultsController.h"

#import "NSString+CloverVersion.h"

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
        [self showDockIcon];
        _installerPath = [args objectAtIndex:2];
        [self setRemoteRevision];
        _forcedUpdate = YES;
        [self doUpdate:self];
    }
    else {
        BOOL forced = args && [args count] && [[args objectAtIndex:1] isEqualToString:@"forced"];

        if (forced)
            [self showDockIcon];

        NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
        
        NSTimeInterval lastCheckTimestamp = [[AnyDefaultsController getDateFromKey:CFSTR(kCloverLastCheckTimestamp) forAppID:CFSTR(kCloverUpdaterIdentifier)] timeIntervalSince1970];
        NSInteger scheduledCheckInterval = [AnyDefaultsController getIntegerFromKey:CFSTR(kCloverScheduledCheckInterval) forAppID:CFSTR(kCloverUpdaterIdentifier) withDefault:0] * 0.9;
        NSTimeInterval intervalFromRef = [now timeIntervalSince1970];
        
        if ((scheduledCheckInterval && lastCheckTimestamp + scheduledCheckInterval < intervalFromRef - scheduledCheckInterval * 0.05) || forced) {
            NSLog(@"Starting updates check...");
            
            [AnyDefaultsController setKey:CFSTR(kCloverLastCheckTimestamp) forAppID:CFSTR(kCloverUpdaterIdentifier) fromDate:now];
            [AnyDefaultsController synchronizeforAppID:CFSTR(kCloverUpdaterIdentifier)];
            
            NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@kCloverLatestInstallerURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
            
            _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            
            if (!_connection) {
                [self terminate];
            }
        }
        else {
            NSLog(@"To early to run check. Terminating...");
            [self terminate];
        }
    }
    
    // Terminate app after 10 minutes
    [self performSelector:@selector(terminate) withObject:nil afterDelay:60 * 10];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed with error: %@", error.description);
    [self terminate];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // Stop downloading installer
    [connection cancel];

    _installerPath = response.suggestedFilename;

    [self setRemoteRevision];

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

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber *local = [formatter numberFromString:bootedRevision];
    NSNumber *downloaded = [NSNumber numberWithInt:[AnyDefaultsController getIntFromKey:CFSTR(kCloverLastVersionDownloaded) forAppID:CFSTR(kCloverUpdaterIdentifier) withDefault:0]];
    NSDate *downloadedDate = [AnyDefaultsController getDateFromKey:CFSTR(kCloverLastDownloadWarned) forAppID:CFSTR(kCloverUpdaterIdentifier)];

    if ([_remoteVersion isGreaterThan:local] && ([_remoteVersion isGreaterThan:downloaded] || (downloadedDate && [downloadedDate timeIntervalSinceDate:[NSDate date]] > 60 * 60 * 24)) ) {
        
        [_hasUpdateTextField setStringValue:[NSString stringWithFormat:GetLocalizedString([_hasUpdateTextField stringValue]), _remoteVersion.intValue, local.intValue]];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self showWindow:_hasUpdateWindow];
        }];
    }
    else if (_forcedUpdate) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self showWindow:_noUpdatesWindow];
        }];
    }
    else {
        [self terminate];
    }
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
    NSLog(@"Downloading to: %@", _installerPath);
    [download setDestination:_installerPath allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response;
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
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

- (void)download:(NSURLDownload *)aDownload didFailWithError:(NSError *)error
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert setIcon:[NSImage imageNamed:NSImageNameCaution]];
    [alert setMessageText:GetLocalizedString(@"An error occured while trying to download Clover installer!")];
    [alert setInformativeText:error.localizedDescription];
    [alert addButtonWithTitle:GetLocalizedString(@"Ok")];

    [alert beginSheetModalForWindow:_progressionWindow modalDelegate:self didEndSelector:@selector(terminate) contextInfo:NULL];
    
//    [self changeProgressionTitle:@"Download..." isInProgress:NO];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    [[NSWorkspace sharedWorkspace] openFile:_installerPath];

    [AnyDefaultsController setKey:CFSTR(kCloverLastVersionDownloaded) forAppID:CFSTR(kCloverUpdaterIdentifier) fromInteger:_remoteVersion.intValue];
    [AnyDefaultsController setKey:CFSTR(kCloverLastDownloadWarned) forAppID:CFSTR(kCloverUpdaterIdentifier) fromDate:[NSDate date]];

    [self terminate];
}

- (void)showWindow:(NSWindow*)window
{
    [NSApp activateIgnoringOtherApps:YES];
    [window setLevel:NSModalPanelWindowLevel];
    [window makeKeyAndOrderFront:self];
}

- (void)showDockIcon
{
	ProcessSerialNumber	psn = {0, kCurrentProcess};
	TransformProcessType(&psn, kProcessTransformToForegroundApplication);
}

- (void)setRemoteRevision
{
    NSString *remoteFilename = [[[_installerPath lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0];

    NSLog(@"Installer path: %@", _installerPath);

    _remoteVersion = [NSNumber numberWithInteger:[remoteFilename getCloverVersion]];
}

- (IBAction)doUpdate:(id)sender
{
//    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@kCloverLatestInstallerURL]];
//    [self terminate];

    [self showDockIcon];
    
    if (_forcedUpdate) {
        NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:@kCloverLatestInstallerURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
        
        _download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
        
        if (_download) {
            
            [self showWindow:_progressionWindow];
            
            [_progressionMessageTextField setStringValue:[NSString stringWithFormat:GetLocalizedString(@"Downloading %@"), [_installerPath lastPathComponent]]];
            [_progressionValueTextField setStringValue:@""];
        }
        else {
            [self terminate];
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
                
                _download = [[NSURLDownload alloc] initWithRequest:request delegate:self];

                if (_download) {
                    [_hasUpdateWindow orderOut:self];
                    
                    [self showWindow:_progressionWindow];
                    
                    [_progressionMessageTextField setStringValue:[NSString stringWithFormat:GetLocalizedString(@"Downloading %@"), [_installerPath lastPathComponent]]];
                    [_progressionValueTextField setStringValue:@""];
                }
                else {
                    [self terminate];
                }
            }
        }];
    }
}

- (void)terminate
{
    [NSApp terminate:self];
}

@end
