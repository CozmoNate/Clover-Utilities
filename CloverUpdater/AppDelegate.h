//
//  AppDelegate.h
//  CloverUpdater
//
//  Created by Kozlek on 18/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *hasUpdateWindow;
@property (assign) IBOutlet NSWindow *noUpdatesWindow;

@property (assign) IBOutlet NSTextField *hasUpdateTextField;

- (IBAction)skipUpdate:(id)sender;
- (IBAction)doUpdate:(id)sender;

@end
