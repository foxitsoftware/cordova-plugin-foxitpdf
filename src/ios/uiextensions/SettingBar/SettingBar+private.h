/**
 * Copyright (C) 2003-2018, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#ifndef SettingBar_private_h
#define SettingBar_private_h

#import <FoxitRDK/FSPDFViewControl.h>
#import <UIKit/UIKit.h>

@interface SettingBar ()

@property (nonatomic, strong, nonnull) UIButton *singleViewBtn;
@property (nonatomic, strong, nonnull) UIButton *continueViewBtn;
@property (nonatomic, strong, nonnull) UIButton *thumbnailViewBtn;
@property (nonatomic, strong, nonnull) UIButton *reflowBtn;
@property (nonatomic, strong, nonnull) UIButton *cropBtn;
@property (nonatomic, strong, nonnull) UIButton *screenLockBtn;
@property (nonatomic, strong, nonnull) UIButton *panAndZoomBtn;
@property (nonatomic, strong, nonnull) UIButton *nightViewBtn;
@property (nonatomic, strong, nonnull) UIButton *doubleViewBtn;
@property (nonatomic, strong, nonnull) UIButton *coverBtn;

- (UIView *_Nullable)getItemView:(SettingItemType)itemType;
- (void)updateLayoutButtonsWithLayout:(PDF_LAYOUT_MODE)layout;

@end

#endif /* SettingBar_private_h */
