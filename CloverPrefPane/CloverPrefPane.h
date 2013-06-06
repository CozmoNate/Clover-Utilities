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
    io_registry_entry_t _ioRegistryOptions;
    io_registry_entry_t _ioAcpiPlatformExpert;
    
    NSString *_updaterPlistPath;
    
    NSDictionary *_diskutilList;
    NSArray *_mountedVolumes;
    NSDictionary *_themesInfo;
    NSArray *_efiPartitions;
    NSArray *_nvramPartitions;
    NSArray *_cloverPathsCollection;
    NSArray *_cloverOemCollection;
    NSDictionary *_cloverConfig;
    NSString *_cloverTheme;
    NSNumber *_cloverOldLogLineCount;
    NSString *_cloverLogEveryBoot;
    NSString *_cloverMountEfiPartition;
    NSString *_cloverNvramPartition;

    
    IBOutlet SFAuthorizationView *_authorizationView;
    
    IBOutlet NSTextField *_lastBootedTextField;
    IBOutlet NSTextField *_latestAvailableTextField;
    IBOutlet NSPopUpButton *_updatesIntervalPopup;
    IBOutlet NSTextField *_lastUpdateTextField;
    IBOutlet NSButton *_checkNowButton;
}

@property (readonly) IBOutlet NSDictionary* diskutilList;
@property (readonly) IBOutlet NSArray* allDisks;
@property (readonly) IBOutlet NSArray* wholeDisks;
@property (readonly) IBOutlet NSArray* mountedVolumes;
@property (readonly) IBOutlet NSArray* efiPartitions;
@property (readonly) IBOutlet NSArray* nvramPartitions;

@property (nonatomic, strong) IBOutlet NSNumber* isUnlocked;

@property (nonatomic, strong) IBOutlet NSString* kernelBootArgs;

@property (nonatomic, strong) IBOutlet NSArray* cloverPathsCollection;
@property (nonatomic, strong) IBOutlet NSString* cloverPath;
@property (nonatomic, strong) IBOutlet NSArray* cloverOemCollection;
@property (nonatomic, strong) IBOutlet NSString* cloverOemPath;
@property (nonatomic, strong) IBOutlet NSDictionary* cloverThemesCollection;
@property (nonatomic, strong) IBOutlet NSDictionary* cloverConfig;
@property (nonatomic, strong) IBOutlet NSString* cloverTheme;
@property (nonatomic, strong) IBOutlet NSDictionary* cloverThemeInfo;

@property (nonatomic, strong) IBOutlet NSNumber* cloverOldLogLineCount;
@property (nonatomic, strong) IBOutlet NSString* cloverLogEveryBoot;
@property (nonatomic, strong) IBOutlet NSNumber* cloverLogEveryBootEnabled;
@property (nonatomic, strong) IBOutlet NSNumber* cloverLogEveryBootLimit;

@property (nonatomic, strong) IBOutlet NSString* cloverMountEfiPartition;
@property (nonatomic, strong) IBOutlet NSString* cloverNvramPartition;

- (IBAction)updatesIntervalChanged:(id)sender;
- (IBAction)checkForUpdatePressed:(id)sender;
- (IBAction)saveSettingsPressed:(id)sender;
- (IBAction)setCurrentCloverPathPressed:(id)sender;
- (IBAction)editCurrentConfigPressed:(id)sender;

@end
