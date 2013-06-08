//
//  Localizer.h
//  HWMonitor
//
//  Created by kozlek on 20.03.13.
//  Copyright (c) 2013 kozlek. All rights reserved.
//

@interface Localizer : NSObject
{
@private
    NSBundle *_bundle;
}

+ (Localizer*)localizerWithBundle:(NSBundle*)bundle;
+ (void)localizeView:(id)view;
+ (void)localizeView:(id)view withBunde:(NSBundle*)bundle;

- (Localizer*)initWithBundle:(NSBundle*)bundle;
- (void)localizeView:(id)view;

@end
