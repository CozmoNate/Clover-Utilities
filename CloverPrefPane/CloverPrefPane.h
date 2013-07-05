//
//  CloverPrefPane.h
//  CloverPrefPane
//
//  Created by Kozlek on 15/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//
//  Initial code from Clover by JrCs
//

#import <PreferencePanes/PreferencePanes.h>
#import <ServiceManagement/ServiceManagement.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface CloverPrefPane : NSPreferencePane <NSURLDownloadDelegate, NSConnectionDelegate>
{
    io_registry_entry_t _ioRegistryOptions;
    io_registry_entry_t _ioAcpiPlatformExpert;
    NSString *_installerFilename;
    NSString *_updaterPath;
    NSString *_updaterPlistPath;
    
    BOOL _hasForcedUpdateCheck;
//    NSMutableData *_remoteDocumentData;
    
    NSDictionary *_diskutilList;
    NSArray *_mountedVolumes;
    NSDictionary *_themesInfo;
    NSArray *_efiPartitions;
    NSArray *_cloverPathsCollection;
    NSArray *_cloverOemCollection;
    NSString *_cloverConfigPath;
    NSString *_cloverTheme;
    NSString *_cloverOldLogLineCount;
    NSString *_cloverLogEveryBoot;
    NSString *_cloverMountEfiPartition;
    NSString *_cloverNvramPartition;
    NSString *_cloverBackupsOnDestinationVolume;
    NSString *_cloverEfiFolderBackupsLimit;
    
    IBOutlet SFAuthorizationView *_authorizationView;
    IBOutlet NSTextField *_bootedRevisionTextField;
    IBOutlet NSTextField *_installedRevisionTextField;
    IBOutlet NSTextField *_availableRevisionTextField;
    IBOutlet NSPopUpButton *_updatesIntervalPopup;
    IBOutlet NSTextField *_lastUpdateTextField;
    IBOutlet NSButton *_checkNowButton;
    IBOutlet NSProgressIndicator *_updatesIndicator;
}

@property (readonly) IBOutlet NSDictionary* diskutilList;
@property (readonly) IBOutlet NSArray* allDisks;
@property (readonly) IBOutlet NSArray* wholeDisks;
@property (readonly) IBOutlet NSArray* mountedVolumes;
@property (readonly) IBOutlet NSArray* efiPartitions;
//@property (readonly) IBOutlet NSArray* nvramPartitions;

@property (nonatomic, strong) IBOutlet NSNumber* isUnlocked;

@property (nonatomic, strong) IBOutlet NSString* kernelBootArgs;

@property (nonatomic, strong) IBOutlet NSNumber* cloverRevision;
@property (nonatomic, strong) IBOutlet NSArray* cloverPathsCollection;
@property (nonatomic, strong) IBOutlet NSString* cloverPath;
@property (nonatomic, strong) IBOutlet NSArray* cloverOemCollection;
@property (nonatomic, strong) IBOutlet NSString* cloverOemPath;
@property (nonatomic, strong) IBOutlet NSDictionary* cloverThemesCollection;
@property (nonatomic, strong) IBOutlet NSString* cloverConfigPath;
@property (nonatomic, strong) IBOutlet NSString* cloverTheme;
@property (nonatomic, strong) IBOutlet NSDictionary* cloverThemeInfo;

@property (nonatomic, assign) NSInteger cloverPreviousLogLines;

@property (nonatomic, assign) BOOL cloverLogEveryBootEnabled;
@property (nonatomic, assign) NSInteger cloverLogEveryBootNumber;

@property (nonatomic, assign) IBOutlet NSString* cloverMountEfiPartition;
@property (nonatomic, assign) BOOL cloverEmulateNvram;

@property (nonatomic, assign) BOOL cloverBackupsOnDestinationVolumeEnabled;
@property (nonatomic, assign) NSInteger cloverBackupsLimit;

- (IBAction)updatesIntervalChanged:(id)sender;
- (IBAction)checkForUpdatePressed:(id)sender;
- (IBAction)saveSettingsPressed:(id)sender;
- (IBAction)setCurrentCloverPathPressed:(id)sender;
- (IBAction)revealCurrentConfigPressed:(id)sender;
- (IBAction)popupToolTip:(id)sender;

@end
