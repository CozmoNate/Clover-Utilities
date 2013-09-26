//
//  SilentUpdateDriver.m
//  Sparkle
//
//  Created by Kozlek on 26/09/13.
//
//

#import "SilentUpdateDriver.h"

@implementation SilentUpdateDriver

- (void)unarchiverDidFinish:(SUUnarchiver *)ua
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:SilentUpdateApplicationWillTerminate object:nil];
}

- (BOOL)shouldInstallSynchronously { return YES; }

-(void)applicationWillTerminate:(id)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self installWithToolAndRelaunch:NO];
}


@end
