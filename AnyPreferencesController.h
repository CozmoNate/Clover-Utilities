//
//  AnyPreferencesController.h
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

@interface AnyPreferencesController : NSObject

+ (BOOL)getBoolFromKey:(CFStringRef)key forAppID:(CFStringRef)appID withDefault:(BOOL)defaultValue;
+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromBool:(BOOL)value;

+ (float)getFloatFromKey:(CFStringRef)key forAppID:(CFStringRef)appID withDefault:(float)defaultValue;
+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromFloat:(float)value;

+ (int)getIntFromKey:(CFStringRef)key forAppID:(CFStringRef)appID withDefault:(int)defaultValue;
+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromInt:(int)value;

+ (NSInteger)getIntegerFromKey:(CFStringRef)key forAppID:(CFStringRef)appID withDefault:(NSInteger)defaultValue;
+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromInteger:(NSInteger)value;

+ (NSString *)getStringFromKey:(CFStringRef)key forAppID:(CFStringRef)appID;
+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromString:(NSString *)value;

+ (NSDate *)getDateFromKey:(CFStringRef)key forAppID:(CFStringRef)appID;
+ (void)setKey:(CFStringRef)key forAppID:(CFStringRef)appID fromDate:(NSDate *)value;

+ (void)synchronizeforAppID:(CFStringRef)appID;

@end
