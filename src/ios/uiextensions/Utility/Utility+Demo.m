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

#import <UIKit/UIKit.h>
#import "Utility+Demo.h"

#define DOCUMENT_PATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@implementation Utility(Demo)

//File/Folder existance
+ (BOOL) isFileOrFolderExistAtPath:(NSString *)path fileOrFolderName:(NSString *)fileOrFolderName
{
    BOOL isAlreadyFileOrFolderExist = NO;
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSArray * subFolder = [fileManager contentsOfDirectoryAtPath:path error:nil];
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

+ (BOOL)showAnnotationContinue:(BOOL)isContinue pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl siblingSubview:(UIView*)siblingSubview
{
    [self dismissAnnotationContinue:pdfViewCtrl];
    NSString *textString = nil;
    if (isContinue) {
        textString = NSLocalizedStringFromTable(@"kAnnotContinue", @"FoxitLocalizable", nil);
    }
    else
    {
        textString = NSLocalizedStringFromTable(@"kAnnotSingle", @"FoxitLocalizable", nil);
    }
    
    CGSize titleSize = [Utility getTextSize:textString fontSize:15.0f maxSize:CGSizeMake(300, 100)];
    
    UIView *view  = [[UIView alloc] initWithFrame:CGRectMake(SCREENWIDTH/2, SCREENHEIGHT - 120, titleSize.width + 10, 30)];
    view.center = CGPointMake(SCREENWIDTH/2, SCREENHEIGHT - 105);
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0.8;
    view.layer.cornerRadius = 10.0f;
    view.tag = 2112;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleSize.width, 30)];
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
    
    UIView *view  = [[UIView alloc] initWithFrame:CGRectMake(SCREENWIDTH/2, SCREENHEIGHT - 80, titleSize.width + 20 + 10, 20)];
    view.center = CGPointMake(SCREENWIDTH/2, SCREENHEIGHT - 70);
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0.8;
    view.layer.cornerRadius = 5.0f;
    view.tag = 2113;
    
    UIImageView *imageView = [[UIImageView alloc] init];
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
            if ([annotType isEqualToString:NSLocalizedStringFromTable(@"kArrowLine", @"FoxitLocalizable", nil)]) {
                imageView.image = [UIImage imageNamed:@"property_type_arrowline"];
            }else {
                imageView.image = [UIImage imageNamed:@"property_type_line"];
            }
            break;
        case e_annotFreeText:
            imageView.image = [UIImage imageNamed:@"property_type_freetext"];
            break;
        case e_annotInk:
            if ([annotType isEqualToString:NSLocalizedStringFromTable(@"kErase", @"FoxitLocalizable", nil)]) {
                imageView.image = [UIImage imageNamed:@"property_type_erase"];
            } else {
                imageView.image = [UIImage imageNamed:@"property_type_pencil"];
            }
            break;
        case e_annotStamp:
            imageView.image = [UIImage imageNamed:@"property_type_stamp"];
            break;
        case e_annotCaret:
            if ([annotType isEqualToString:NSLocalizedStringFromTable(@"kReplaceText", @"FoxitLocalizable", nil)]) {
                imageView.image = [UIImage imageNamed:@"property_type_replace"];
            }
            else
                imageView.image = [UIImage imageNamed:@"property_type_caret"];
            break;
        case e_annotFileAttachment:
            imageView.image = [UIImage imageNamed:@"property_type_attachment"];
        default:
            break;
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleSize.width, 20)];
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
    [UIView animateWithDuration:3 animations:^{
        view.alpha = 0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
    return YES;
}

//Add animation
+ (void)addAnimation:(CALayer*)layer type:(NSString*)type subType:(NSString*)subType timeFunction:(NSString*)timeFunction duration:(float)duration
{
    CATransition *animation = [CATransition animation];
    [animation setType:type];
    [animation setSubtype:subType];
    [animation setDuration:duration];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:timeFunction]];
    [layer addAnimation:animation forKey:nil];
}

@end
