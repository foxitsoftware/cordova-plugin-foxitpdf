/**
 * Copyright (C) 2003-2016, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to 
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement 
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.

 */
#import "SettingPreference.h"
#import "UIExtensionsManager+Private.h"

#define USER_DEFAULT [NSUserDefaults standardUserDefaults]

//Annotation
static NSString *Key_Annotation_Author                       = @"Annotation_Author";
//SETTING
static NSString *Key_Setting_PDF_HighlightLinks              = @"Setting_PDF_HighlightLinks";

@implementation SettingPreference

+ (NSString *)getAnnotationAuthor
{
    NSString* author = [USER_DEFAULT objectForKey:Key_Annotation_Author];
    if (!author.length) {
        author = [[UIDevice currentDevice].name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    [USER_DEFAULT setObject:author forKey:Key_Annotation_Author];
    return author;
}

+ (BOOL)getPDFHighlightLinks
{
    NSNumber *number = [USER_DEFAULT objectForKey:Key_Setting_PDF_HighlightLinks];
    if (number != nil)
    {
        return ([number intValue] == 1);
    }
    else
    {
        return YES;
    }
}

@end
