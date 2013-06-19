//
//  Localizer.m
//  HWMonitor
//
//  Created by kozlek on 20.03.13.
//  Copyright (c) 2013 kozlek. All rights reserved.
//

#import "Localizer.h"

#define GetLocalizedString(key) \
[_bundle localizedStringForKey:(key) value:@"" table:nil]

@implementation Localizer

+ (Localizer *)localizerWithBundle:(NSBundle *)bundle
{
    Localizer *me = [[Localizer alloc] initWithBundle:bundle];
    
    return me;
}

+(void)localizeView:(id)view
{
    Localizer *localizer = [Localizer localizerWithBundle:[NSBundle mainBundle]];
    [localizer localizeView:view];
}

+(void)localizeView:(id)view withBunde:(NSBundle *)bundle
{
    Localizer *localizer = [Localizer localizerWithBundle:bundle];
    [localizer localizeView:view];
}

-(id)init
{
    self = [super init];
    
    if (self) {
        _bundle = [NSBundle mainBundle];
    }
    
    return self;
}

-(Localizer *)initWithBundle:(NSBundle *)bundle
{
    self = [super init];
    
    if (self) {
        _bundle = bundle;
    }
    
    return self;
}

- (void)localizeView:(id)view
{
    if (!view) {
        return;
    }
    
    if ([view isKindOfClass:[NSWindow class]]) {
        [self localizeView:[view contentView]];
    }
    else if ([view isKindOfClass:[NSTextField class]]) {
        NSTextField *textField = (NSTextField*)view;
        
        NSString *title = [textField stringValue];
        
        [textField setStringValue:GetLocalizedString(title)];
    }
    else if ([view isKindOfClass:[NSButton class]]) {
        NSButton *button = (NSButton*)view;
        
        NSString *title = [button title];
        
        [button setTitle:GetLocalizedString(title)];
        [button setAlternateTitle:GetLocalizedString([button alternateTitle])];
        
        [self localizeView:button.menu];
    }
    else if ([view isKindOfClass:[NSMatrix class]]) {
        NSMatrix *matrix = (NSMatrix*)view;
        
        NSUInteger row, column;
        
        for (row = 0 ; row < [matrix numberOfRows]; row++) {
            for (column = 0; column < [matrix numberOfColumns] ; column++) {
                NSButtonCell* cell = [matrix cellAtRow:row column:column];
                
                NSString *title = [cell title];
                
                [cell setTitle:GetLocalizedString(title)];
            }
        }
    }
    else if ([view isKindOfClass:[NSMenu class]]) {
        NSMenu *menu = (NSMenu*)view;
        
        [menu setTitle:GetLocalizedString([menu title])];
        
        for (id subItem in [menu itemArray]) {
            if ([subItem isKindOfClass:[NSMenuItem class]]) {
                NSMenuItem* menuItem = subItem;
                
                [menuItem setTitle:GetLocalizedString([menuItem title])];
                
                if ([menuItem hasSubmenu])
                    [self localizeView:[menuItem submenu]];
            }
        }
    }
    else if ([view isKindOfClass:[NSTabView class]]) {
        for (NSTabViewItem *item in [(NSTabView*)view tabViewItems]) {
            [item setLabel:GetLocalizedString([item label])];
            [self localizeView:[item view]];
        }
    }
    else if ([view isKindOfClass:[NSToolbar class]]) {
        for (NSToolbarItem *item in [(NSToolbar*)view items]) {
            [item setLabel:GetLocalizedString([item label])];
            [self localizeView:[item view]];
        }
    }
    
    // Must be at the end to allow other checks to pass because almost all controls are derived from NSView
    else if ([view isKindOfClass:[NSView class]] ) {
        for(NSView *subView in [view subviews]) {
            [self localizeView:subView];
        }
    }
    else {
        if ([view respondsToSelector:@selector(setTitle:)]) {
            NSString *title = [(id)view title];
            [view setTitle:GetLocalizedString(title)];
        }
        else if ([view respondsToSelector:@selector(setStringValue:)]) {
            NSString *title = [(id)view stringValue];
            [view setStringValue:GetLocalizedString(title)];
        }
        
        if ([view respondsToSelector:@selector(setAlternateTitle:)]) {
            NSString *title = [(id)view alternateTitle];
            [view setAlternateTitle:GetLocalizedString(title)];
        }
    }
    
    if ([view respondsToSelector:@selector(setToolTip:)]) {
        NSString *tooltip = [view toolTip];
        [view setToolTip:GetLocalizedString(tooltip)];
    }
}


@end
