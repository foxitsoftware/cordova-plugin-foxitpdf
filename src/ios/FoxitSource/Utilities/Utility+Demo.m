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

#import <UIKit/UIKit.h>
#import "Utility+Demo.h"

#define DOCUMENT_PATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@implementation Utility(Demo)

+ (void)assignImage:(UIImageView *)imageView rawFrame:(CGRect)frame image:(UIImage *)image
{
    if(image.size.width/image.size.height == frame.size.width/frame.size.height)
    {
        imageView.frame = [Utility getStandardRect:frame];
    }
    else if(image.size.width/image.size.height < frame.size.width/frame.size.height)
    {
        float realHeight = frame.size.height;
        float realWidth = image.size.width/image.size.height*realHeight;
        imageView.frame = [Utility getStandardRect:CGRectMake(frame.origin.x+(frame.size.width-realWidth)/2, frame.origin.y, realWidth, realHeight)];
    }
    else
    {
        float realWidth = frame.size.width;
        float realHeight = image.size.height/image.size.width*realWidth;
        imageView.frame = [Utility getStandardRect:CGRectMake(frame.origin.x, frame.origin.y+(frame.size.height-realHeight)/2, realWidth, realHeight)];
    }
    imageView.image = image;
}

+ (ScreenSizeMode)getScreenSizeMode
{
    CGRect screenSize = [[UIScreen mainScreen] bounds];
    NSInteger screenWidth = screenSize.size.width;
    NSInteger screenHeight = screenSize.size.height;
    if (screenWidth == 480 || screenHeight == 480)
    {
        return ScreenSizeMode_35;
    }
    else if (screenWidth == 568 || screenHeight == 568)
    {
        return ScreenSizeMode_40;
    }
    else if (screenWidth == 667 || screenHeight == 667)
    {
        return ScreenSizeMode_47;
    }
    else if (screenWidth == 736 || screenHeight == 736)
    {
        return ScreenSizeMode_55;
    }
    else if (screenWidth == 1024 || screenHeight == 1024)
    {
        return ScreenSizeMode_97;
    }
    return ScreenSizeMode_35;
}

//Verify file type
+ (BOOL)isPDFPath:(NSString*)path
{
    if([path.pathExtension.lowercaseString isEqualToString:@"pdf"])
    {
        return YES;
    }
    else if([path.lowercaseString isEqualToString:@".pdf"])
    {
        return YES;
    }
    return NO;
}

+ (BOOL)isPDFExtension:(NSString*)extension
{
    return [extension.lowercaseString isEqualToString:@"pdf"];
}

//File/Folder existance
+ (BOOL) isFileOrFolderExistAtPath:(NSString *)path fileOrFolderName:(NSString *)fileOrFolderName
{
    BOOL isAlreadyFileOrFolderExist = NO;
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSArray * subFolder = [fileManager contentsOfDirectoryAtPath:path error:nil];
    [fileManager release];
    for (NSString *thisFolder in subFolder)
    {
        if( [thisFolder caseInsensitiveCompare:fileOrFolderName] == NSOrderedSame)
        {
            isAlreadyFileOrFolderExist = YES;
            break;
        }
    }
    return isAlreadyFileOrFolderExist;
}

//Get file type icon name
+ (NSString*)getIconName:(NSString*)path
{
    NSString *ret = @"list_none";
    if ([Utility isPDFPath:path])
    {
        ret = @"list_pdf";
    }
    return ret;
}

//Get file type thumbnail name
+ (NSString *)getThumbnailName:(NSString *)path
{
    NSString *ret = DEVICE_iPHONE ? @"thumbnail_none_iphone" : @"thumbnail_none_ipad";
    if ([self isPDFPath:path])
    {
        ret = DEVICE_iPHONE ? @"thumbnail_pdf_iphone" : @"thumbnail_pdf_ipad";
    }
    return ret;
}

//display the file size string
+ (NSString *)displayFileSize:(unsigned long long)byte
{
    if (byte < 1024)
    {
        return [NSString stringWithFormat:@"%lld B", byte];
    }
    else if(byte < 1024000)
    {
        return [NSString stringWithFormat:@"%.2f KB", byte/1024.0];
    }
    else if(byte < 1024000000)
    {
        return [NSString stringWithFormat:@"%.2f MB", byte/1024000.0];
    }
    else
    {
        return [NSString stringWithFormat:@"%.2f GB", byte/1024000000.0];
    }
}

+ (BOOL)showAnnotationContinue:(BOOL)isContinue pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl siblingSubview:(UIView*)siblingSubview
{
    [self dismissAnnotationContinue:pdfViewCtrl];
    NSString *textString = nil;
    if (isContinue) {
        textString = NSLocalizedString(@"kAnnotContinue", nil);
    }
    else
    {
        textString = NSLocalizedString(@"kAnnotSingle", nil);
    }
    
    CGSize titleSize = [Utility getTextSize:textString fontSize:15.0f maxSize:CGSizeMake(300, 100)];
    
    UIView *view  = [[[UIView alloc] initWithFrame:CGRectMake(SCREENWIDTH/2, SCREENHEIGHT - 120, titleSize.width + 10, 30)] autorelease];
    view.center = CGPointMake(SCREENWIDTH/2, SCREENHEIGHT - 105);
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0.8;
    view.layer.cornerRadius = 10.0f;
    view.tag = 2112;
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleSize.width, 30)] autorelease];
    label.center = CGPointMake(view.frame.size.width/2, view.frame.size.height/2);
    label.backgroundColor = [UIColor clearColor];
    label.text = textString;
    
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15];
    [view addSubview:label];
    [pdfViewCtrl insertSubview:view belowSubview:siblingSubview];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(view.superview.mas_centerX).offset(0);
        make.top.equalTo(view.superview.mas_bottom).offset(-120);
        make.width.mas_equalTo(titleSize.width+10);
        make.height.mas_equalTo(@30);
    }];
    return YES;
}

+(void)dismissAnnotationContinue:(UIView*)superView
{
    for (UIView *view in superView.subviews) {
        if (view.tag == 2112) {
            [view removeFromSuperview];
        }
    }
}

+ (BOOL)showAnnotationType:(NSString*)annotType type:(enum FS_ANNOTTYPE)type pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl belowSubview:(UIView*)siblingSubview
{
    for (UIView *view in pdfViewCtrl.subviews) {
        if (view.tag == 2113) {
            [view removeFromSuperview];
        }
    }
    
    CGSize titleSize = [Utility getTextSize:annotType fontSize:13.0f maxSize:CGSizeMake(100, 100)];
    
    UIView *view  = [[[UIView alloc] initWithFrame:CGRectMake(SCREENWIDTH/2, SCREENHEIGHT - 80, titleSize.width + 20 + 10, 20)] autorelease];
    view.center = CGPointMake(SCREENWIDTH/2, SCREENHEIGHT - 70);
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0.8;
    view.layer.cornerRadius = 5.0f;
    view.tag = 2113;
    
    UIImageView *imageView = [[[UIImageView alloc] init] autorelease];
    imageView.frame = CGRectMake(5, 2, 16, 16);
    switch (type) {
        case e_annotHighlight:
            imageView.image = [UIImage imageNamed:@"property_type_highlight"];
            break;
        case e_annotLink:
            break;
        case e_annotNote:
            imageView.image = [UIImage imageNamed:@"property_type_note"];
            break;
        case e_annotStrikeOut:
            imageView.image = [UIImage imageNamed:@"property_type_strikeout"];
            break;
        case e_annotUnderline:
            imageView.image = [UIImage imageNamed:@"property_type_underline"];
            break;
        case e_annotSquiggly:
            imageView.image = [UIImage imageNamed:@"property_type_squiggly"];
            break;
        case e_annotSquare:
            imageView.image = [UIImage imageNamed:@"property_type_rectangle"];
            break;
        case e_annotCircle:
            imageView.image = [UIImage imageNamed:@"property_type_circle"];
            break;
        case e_annotLine:
            if ([annotType isEqualToString:NSLocalizedString(@"kArrowLine", nil)]) {
                imageView.image = [UIImage imageNamed:@"property_type_arrowline"];
            }else {
                imageView.image = [UIImage imageNamed:@"property_type_line"];
            }
            break;
        case e_annotFreeText:
            imageView.image = [UIImage imageNamed:@"property_type_freetext"];
            break;
        case e_annotInk:
            if ([annotType isEqualToString:NSLocalizedString(@"kErase", nil)]) {
                imageView.image = [UIImage imageNamed:@"property_type_erase"];
            } else {
                imageView.image = [UIImage imageNamed:@"property_type_pencil"];
            }
            break;
        case e_annotStamp:
            imageView.image = [UIImage imageNamed:@"property_type_stamp"];
            break;
        case e_annotCaret:
            if ([annotType isEqualToString:NSLocalizedString(@"kReplaceText", nil)]) {
                imageView.image = [UIImage imageNamed:@"property_type_replace"];
            }
            else
                imageView.image = [UIImage imageNamed:@"property_type_caret"];
            break;
        default:
            break;
    }
    
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleSize.width, 20)] autorelease];
    label.center = CGPointMake(view.frame.size.width/2 + 10, view.frame.size.height/2);
    label.backgroundColor = [UIColor clearColor];
    label.text = annotType;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:12];
    [view addSubview:imageView];
    [view addSubview:label];
    [pdfViewCtrl insertSubview:view belowSubview:siblingSubview];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(view.superview.mas_centerX).offset(0);
        make.top.equalTo(view.superview.mas_bottom).offset(-80);
        make.width.mas_equalTo(titleSize.width+20+10);
        make.height.mas_equalTo(@20);
    }];
    
    return YES;
}


+ (NSArray *)searchFilesWithFolder:(NSString *)folder recursive:(BOOL)recursive;
{
    NSMutableArray *fileList= [NSMutableArray array];
    NSFileManager *fileManager= [[[NSFileManager alloc] init] autorelease];
    NSArray *fileAndFolderList= [fileManager contentsOfDirectoryAtPath:folder error:nil];
    for (NSString *file in fileAndFolderList)
    {
        BOOL isDir= NO;
        NSString *thisFile= [folder stringByAppendingPathComponent:file];
        if ([fileManager fileExistsAtPath:thisFile isDirectory:&isDir] && isDir)
        {
            if (recursive)
            {
                [fileList addObjectsFromArray:[[self class] searchFilesWithFolder:thisFile recursive:recursive]];
            }
        }
        else
        {
            [fileList addObject:thisFile];
        }
    }
    return (NSArray *)fileList;
}

@end
