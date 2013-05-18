//
//  AppDelegate.m
//  CloverUpdater
//
//  Created by Kozlek on 18/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

#import "AppDelegate.h"

#import "Arguments.h"

#define GetLocalizedString(key) \
[[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void) awakeFromNib {
    /*[OldRevision setStringValue: [NSString stringWithFormat: @"%s", arg1]];
    [NewRevision setStringValue: [NSString stringWithFormat: @"%s", arg2]];
    if ([OldRevision intValue] >= [NewRevision intValue]) {
        [updateButton setEnabled:FALSE];
    } else {
        [NewRevision setTextColor:[NSColor blueColor]];
    }*/
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    
    NSNumber *local = [formatter numberFromString:[NSString stringWithFormat: @"%s", arg1]];
    NSNumber *remote = [formatter numberFromString:[NSString stringWithFormat: @"%s", arg2]];
    
    if ([remote isGreaterThan:local]) {
        [_hasUpdateTextField setStringValue:[NSString stringWithFormat:GetLocalizedString([_hasUpdateTextField stringValue]), arg2, arg1]];
        
        [self performSelector:@selector(showHasUpdatesWindow) withObject:nil afterDelay:1.0];
    }
    else {
        [self performSelector:@selector(showNoUpdatesWindow) withObject:nil afterDelay:1.0];
    }
}

- (void)showHasUpdatesWindow
{
    [_hasUpdateWindow setLevel:NSModalPanelWindowLevel];
    [_hasUpdateWindow makeKeyAndOrderFront:self];
}

- (void)showNoUpdatesWindow
{
    [_noUpdatesWindow setLevel:NSModalPanelWindowLevel];
    [_noUpdatesWindow makeKeyAndOrderFront:self];
}

- (IBAction)skipUpdate:(id)sender
{
    printf("0");
    exit(0);
}

- (IBAction)doUpdate:(id)sender
{
    printf("1");
    exit(0);
}


@end
