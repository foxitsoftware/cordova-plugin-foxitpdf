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

#import <Foundation/Foundation.h>
#import "../FSPDFReader.h"
#import "SettingBar.h"
#import <FoxitRDK/FSPDFViewControl.h>

@class FSPDFReader;
@class SettingBar;

@interface SettingBarController : NSObject

@property (nonatomic, strong) SettingBar* settingBar;
@property (nonatomic, assign) BOOL hiddenSettingBar;
@property (nonatomic, strong) FSPDFReader *pdfReader;

-(instancetype)initWithPDFViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl pdfReader:(FSPDFReader*)pdfReader;
-(void)onLayoutModeChanged:(PDF_LAYOUT_MODE)oldLayoutMode newLayoutMode:(PDF_LAYOUT_MODE)newLayoutMode;
@end
