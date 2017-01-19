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

#import <Foundation/Foundation.h>
#import "UIExtensionsSharedHeader.h"

@class FSPDFViewCtrl;

typedef enum
{
    ScreenSizeMode_35 = 0,    //3.5 inches
    ScreenSizeMode_40,        //4 inches
    ScreenSizeMode_47,        //4.7 inches
    ScreenSizeMode_55,        //5.5 inches
    ScreenSizeMode_97         //9.7 inches
} ScreenSizeMode;

@interface Utility(Demo)

+ (void)assignImage:(UIImageView *)imageView rawFrame:(CGRect)frame image:(UIImage *)image;

+ (ScreenSizeMode)getScreenSizeMode;

+ (BOOL)isPDFPath:(NSString*)path;
+ (BOOL)isPDFExtension:(NSString*)extension;

//File/Folder existance
+ (BOOL) isFileOrFolderExistAtPath:(NSString *)path fileOrFolderName:(NSString *)fileOrFolderName;

//Get file type icon name
+ (NSString*)getIconName:(NSString*)path;

//Get file type thumbnail name
+ (NSString *)getThumbnailName:(NSString *)path;

//display the file size string
+ (NSString *)displayFileSize:(unsigned long long)Byte;

//alert user whether tool will keep selected
+ (BOOL)showAnnotationContinue:(BOOL)isContinue pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl siblingSubview:(UIView*)siblingSubview;
+(void)dismissAnnotationContinue:(UIView*)superView;

//show user name and icon of current tool
+ (BOOL)showAnnotationType:(NSString*)annotType type:(enum FS_ANNOTTYPE)type pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl belowSubview:(UIView*)siblingSubview;

+ (NSArray *)searchFilesWithFolder:(NSString *)folder recursive:(BOOL)recursive;
@end
