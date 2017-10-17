/**
 * Copyright (C) 2003-2017, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "Preference.h"
#import "UIExtensionsManager+Private.h"

#define USER_DEFAULT [NSUserDefaults standardUserDefaults]

@implementation Preference

+ (int)getIntValue:(NSString *)module type:(NSString *)type defaultValue:(int)defVal {
    NSString *key = [module copy];
    key = [key stringByAppendingString:type];
    NSNumber *value = [USER_DEFAULT objectForKey:key];
    if (value != nil) {
        return [value intValue];
    } else {
        return defVal;
    }
}

+ (void)setIntValue:(NSString *)module type:(NSString *)type value:(int)value {
    NSString *key = [module copy];
    key = [key stringByAppendingString:type];
    [USER_DEFAULT setObject:[NSNumber numberWithInt:value] forKey:key];
    [USER_DEFAULT synchronize];
}

+ (float)getFloatValue:(NSString *)module type:(NSString *)type defaultValue:(float)defVal {
    NSString *key = [module copy];
    key = [key stringByAppendingString:type];
    NSNumber *value = [USER_DEFAULT objectForKey:key];
    if (value != nil) {
        return [value floatValue];
    } else {
        return defVal;
    }
}

+ (void)setFloatValue:(NSString *)module type:(NSString *)type value:(float)value {
    NSString *key = [module copy];
    key = [key stringByAppendingString:type];
    [USER_DEFAULT setObject:[NSNumber numberWithFloat:value] forKey:key];
    [USER_DEFAULT synchronize];
}

+ (BOOL)getBoolValue:(NSString *)module type:(NSString *)type delaultValue:(BOOL)defVal {
    NSString *key = [module copy];
    key = [key stringByAppendingString:type];
    BOOL value = [USER_DEFAULT boolForKey:key];
    return value;
}

+ (void)setBoolValue:(NSString *)module type:(NSString *)type value:(BOOL)value {
    NSString *key = [module copy];
    key = [key stringByAppendingString:type];
    [USER_DEFAULT setBool:value forKey:key];
    [USER_DEFAULT synchronize];
}

@end
