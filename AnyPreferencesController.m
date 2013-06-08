//
//  AnyPreferencesController.m
//  CloverPrefs
//
//  Created by Kozlek on 08/06/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//
//  Code taken from
//  http://svn.perian.org/branches/perian-1.1/CPFPerianPrefPaneController.m
//

/*
 * CPFPerianPrefPaneController.m
 *
 * This file is part of Perian.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#import "AnyPreferencesController.h"

@implementation AnyPreferencesController

+ (BOOL)getBoolFromKey:(CFStringRef)key forAppID:(CFStringRef)appID withDefault:(BOOL)defaultValue
{
	CFPropertyListRef value;
	BOOL ret = defaultValue;
	
	value = CFPreferencesCopyAppValue(key, appID);
	if(value && CFGetTypeID(value) == CFBooleanGetTypeID())
		ret = CFBooleanGetValue(value);
	
	if(value)
		CFRelease(value);
	
	return ret;
}

+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromBool:(BOOL)value
{
	CFPreferencesSetAppValue(key, value ? kCFBooleanTrue : kCFBooleanFalse, appID);
}

+ (float)getFloatFromKey:(CFStringRef)key forAppID:(CFStringRef)appID withDefault:(float)defaultValue
{
	CFPropertyListRef value;
	float ret = defaultValue;
	
	value = CFPreferencesCopyAppValue(key, appID);
	if(value && CFGetTypeID(value) == CFNumberGetTypeID())
		CFNumberGetValue(value, kCFNumberFloatType, &ret);
	
	if(value)
		CFRelease(value);
	
	return ret;
}

+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromFloat:(float)value
{
	CFNumberRef numRef = CFNumberCreate(NULL, kCFNumberFloatType, &value);
	CFPreferencesSetAppValue(key, numRef, appID);
	CFRelease(numRef);
}

+ (int)getIntFromKey:(CFStringRef)key forAppID:(CFStringRef)appID withDefault:(int)defaultValue
{
	CFPropertyListRef value;
	int ret = defaultValue;
	
	value = CFPreferencesCopyAppValue(key, appID);
	if(value && CFGetTypeID(value) == CFNumberGetTypeID())
		CFNumberGetValue(value, kCFNumberIntType, &ret);
	
	if(value)
		CFRelease(value);
	
	return ret;
}

+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromInt:(int)value
{
	CFNumberRef numRef = CFNumberCreate(NULL, kCFNumberIntType, &value);
	CFPreferencesSetAppValue(key, numRef, appID);
	CFRelease(numRef);
}

+ (NSInteger)getIntegerFromKey:(CFStringRef)key forAppID:(CFStringRef)appID withDefault:(NSInteger)defaultValue
{
	CFPropertyListRef value;
	NSInteger ret = defaultValue;
	
	value = CFPreferencesCopyAppValue(key, appID);
	if(value && CFGetTypeID(value) == CFNumberGetTypeID())
		CFNumberGetValue(value, kCFNumberIntType, &ret);
	
	if(value)
		CFRelease(value);
	
	return ret;
}

+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromInteger:(NSInteger)value
{
	CFNumberRef numRef = CFNumberCreate(NULL, kCFNumberIntType, &value);
	CFPreferencesSetAppValue(key, numRef, appID);
	CFRelease(numRef);
}

+ (NSString *)getStringFromKey:(CFStringRef)key forAppID:(CFStringRef)appID
{
	CFPropertyListRef value;
	NSString *ret = nil;
	
	value = CFPreferencesCopyAppValue(key, appID);
	if(value && CFGetTypeID(value) == CFStringGetTypeID())
		ret = [NSString stringWithString:(NSString *)value];
	
	if(value)
		CFRelease(value);
	
	return ret;
}

+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromString:(NSString *)value
{
	CFPreferencesSetAppValue(key, (CFPropertyListRef)(value), appID);
}

+ (NSDate *)getDateFromKey:(CFStringRef)key forAppID:(CFStringRef)appID
{
	CFPropertyListRef value;
	NSDate *ret = nil;
	
	value = CFPreferencesCopyAppValue(key, appID);
	if(value && CFGetTypeID(value) == CFDateGetTypeID())
		ret = [[(NSDate *)value retain] autorelease];
	
	if(value)
		CFRelease(value);
	
	return ret;
}

+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromDate:(NSDate *)value
{
	CFPreferencesSetAppValue(key, (CFPropertyListRef)(value), appID);
}

+ (void)synchronizeforAppID:(CFStringRef)appID
{
    CFPreferencesAppSynchronize(appID);
}

@end
