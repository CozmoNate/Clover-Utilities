//
//  AppDelegate.h
//  CloverUpdater
//
//  Created by Kozlek on 18/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

@interface CloverUpdater : NSObject <NSApplicationDelegate, NSURLConnectionDelegate, NSURLDownloadDelegate>
{
    NSString *_installerPath;
    BOOL _forcedUpdate;
}

@property (assign) IBOutlet NSWindow *hasUpdateWindow;
@property (assign) IBOutlet NSWindow *noUpdatesWindow;
@property (assign) IBOutlet NSWindow *progressionWindow;

@property (assign) IBOutlet NSTextField *hasUpdateTextField;
@property (assign) IBOutlet NSTextField *progressionMessageTextField;
@property (assign) IBOutlet NSTextField *progressionValueTextField;
@property (assign) IBOutlet NSLevelIndicator *levelIndicator;
@property (assign) IBOutlet NSProgressIndicator *progressionIndicator;

- (IBAction)doUpdate:(id)sender;

@end
