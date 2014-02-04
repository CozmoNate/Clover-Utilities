//
//  NSString+CloverVersion.m
//  CloverPrefs
//
//  Created by Kozlek on 04.02.14.
//  Copyright (c) 2014 Kozlek. All rights reserved.
//

#import "NSString+CloverVersion.h"

@implementation NSString (CloverVersion)

-(NSUInteger)getCloverVersion
{
    if ([self hasPrefix:@"Clover_"]) {

        NSArray *components = [self componentsSeparatedByString:@"r"];

        NSString *revision = [components lastObject];

        return [revision intValue];
    }

    return 0;
}

@end
