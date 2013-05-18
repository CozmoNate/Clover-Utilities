//
//  CloverPrefPane.h
//  CloverPrefPane
//
//  Created by Kozlek on 15/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <ServiceManagement/ServiceManagement.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface CloverPrefPane : NSPreferencePane
{
    io_registry_entry_t _gOptionsRef;
    NSString *_updaterPlistPath;
    NSDictionary *_diskutilList;
    NSDictionary *_themesInfo;
    NSArray *_efiPartitions;
    NSArray *_nvramPartitions;
    
    IBOutlet SFAuthorizationView *_authorizationView;
    
    IBOutlet NSTextField *_lastBootedTextField;
    IBOutlet NSTextField *_lastInstalledTextField;
    IBOutlet NSPopUpButton *_updatesIntervalPopup;
    IBOutlet NSTextField *_lastUpdateTextField;
    IBOutlet NSButton *_checkNowButton;
}

@property (readonly) IBOutlet NSDictionary* themesInfo;
@property (readonly) IBOutlet NSDictionary* diskutilList;
@property (readonly) IBOutlet NSArray* allDisks;
@property (readonly) IBOutlet NSArray* wholeDisks;
@property (readonly) IBOutlet NSArray* volumes;
@property (readonly) IBOutlet NSArray* efiPartitions;
@property (readonly) IBOutlet NSArray* nvramPartitions;

@property (nonatomic, strong) IBOutlet NSObject* isUnlocked;

@property (nonatomic, strong) IBOutlet NSString* kernelBootArgs;

@property (nonatomic, strong) IBOutlet NSString* cloverTheme;
@property (nonatomic, strong) IBOutlet NSImage* cloverThemeImage;
@property (nonatomic, strong) IBOutlet NSDictionary* cloverThemeInfo;

@property (nonatomic, strong) IBOutlet NSNumber* cloverOldLogLineCount;
@property (nonatomic, strong) IBOutlet NSNumber* cloverTimestampLogsEnabled;
@property (nonatomic, strong) IBOutlet NSNumber* cloverTimestampLogsLimit;

@property (nonatomic, strong) IBOutlet NSString* cloverMountEfiPartition;
@property (nonatomic, strong) IBOutlet NSString* cloverNvramPartition;

- (void)mainViewDidLoad;

- (IBAction)updatesIntervalChanged:(id)sender;
- (IBAction)checkForUpdatePressed:(id)sender;

- (IBAction)kernelBootArgsChanged:(id)sender;

- (IBAction)cloverThemeVariableChanged:(id)sender;
- (IBAction)cloverOldLogLinesVariableChanged:(id)sender;
- (IBAction)cloverTimestampLogVariableChanged:(id)sender;
- (IBAction)cloverMountEfiVariableChanged:(id)sender;
- (IBAction)cloverNvramDiskVariableChanged:(id)sender;

@end
