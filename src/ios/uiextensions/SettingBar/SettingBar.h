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

/**
 * @file	SettingBar.h
 * @details	The setting bar consists controls to set page layout, screen brightness, reflow, crop and so on.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class UIExtensionsManager;
/**
 * @brief	Enumeration for item types in setting bar.
 *
 * @details	Values of this enumeration should be used alone.
 */
typedef NS_ENUM(NSUInteger, SettingItemType) {
    /** @brief	Single page layout button. */
    SINGLE,
    /** @brief	Continuous page layout button. */
    CONTINUOUS,
    /** @brief	Double page layout button. */
    DOUBLEPAGE,
    /** @brief	Cover page layout button. */
    COVERPAGE,
    /** @brief	Thumbnail button. */
    THUMBNAIL,
    /** @brief	Reflow button. */
    REFLOW,
    /** @brief	Crop page button. */
    CROPPAGE,
    /** @brief	Lock screen button. */
    LOCKSCREEN,
    /** @brief	Brightness slider view. */
    BRIGHTNESS,
    /** @brief	Night mode button. */
    NIGHTMODE,
    /** @brief  Pan&zoom button. */
    PANZOOM
};

@protocol IRotationEventListener;
@class FSPDFViewCtrl;

@protocol IAppLifecycleListener <NSObject>
@optional
- (void)applicationWillResignActive:(UIApplication *)application;
- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationWillEnterForeground:(UIApplication *)application;
- (void)applicationDidBecomeActive:(UIApplication *)application;
@end

@class SettingBar;

/** @brief	SettingBar delegate. */
@protocol SettingBarDelegate <NSObject>
@optional
// Methods for notification of selection/deselection events.
/**
 * @brief	Triggered when select single page layout.
 *
 * @param[in]	settingBar      The setting bar.
 */
- (void)settingBarSinglePageLayout:(SettingBar *)settingBar;
/**
 * @brief	Triggered when select continuous page layout.
 *
 * @param[in]	settingBar      The setting bar.
 */
- (void)settingBarContinuousLayout:(SettingBar *)settingBar;
/**
 * @brief	Triggered when select double page layout.
 *
 * @param[in]	settingBar      The setting bar.
 */
- (void)settingBarDoublePageLayout:(SettingBar *)settingBar;
/**
 * @brief	Triggered when select double page layout with cover.
 *
 * @param[in]	settingBar      The setting bar.
 */
- (void)settingBarCoverPageLayout:(SettingBar *)settingBar;
/**
 * @brief	Triggered when select thumbnail item.
 *
 * @param[in]	settingBar      The setting bar.
 */
- (void)settingBarThumbnail:(SettingBar *)settingBar;
/**
 * @brief	Triggered when select reflow item.
 *
 * @param[in]	settingBar      The setting bar.
 */
- (void)settingBarReflow:(SettingBar *)settingBar;
/**
 * @brief	Triggered when select crop page mode.
 *
 * @param[in]	settingBar      The setting bar.
 */
- (void)settingBarCrop:(SettingBar *)settingBar;
/**
 * @brief	Triggered when select pan&zoom mode.
 *
 * @param[in]	settingBar      The setting bar.
 */
- (void)settingBarPanAndZoom:(SettingBar *)settingBar;
/**
 * @brief	Triggered when select lock screen item.
 *
 * @param[in]	settingBar      The setting bar.
 * @param[in]	isLockScreen    Whether to lock screen rotation.
 */
- (void)settingBar:(SettingBar *)settingBar setLockScreen:(BOOL)isLockScreen;
/**
 * @brief	Triggered when select night mode item.
 *
 * @param[in]	settingBar      The setting bar.
 * @param[in]	isNightMode     Night mode or not.
 */
- (void)settingBar:(SettingBar *)settingBar setNightMode:(BOOL)isNightMode;

@end

@interface SettingBar : NSObject <IAppLifecycleListener>

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, weak) id<SettingBarDelegate> delegate;
/**
 * @brief	Initialize the setting bar.
 *
 * @param[in]	extensionsManager   The extensions manager.
 *
 * @return	The setting bar instance.
 */
- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager;

/**
 * @brief get setting bar items show/hide status.
 */
-(NSMutableDictionary *)getItemHiddenStatus;

/**
 * @brief	Hide or show item in setting bar.
 *
 * @param[in]	itemType     Item type. Please refer to {@link SettingItemType::SINGLE SettingItemType::XXX} values and this should be one of these values.
 */
- (void)setItem:(SettingItemType)itemType hidden:(BOOL)hidden;
/**
 * @brief	Update layout of items in setting bar.
 */
- (void)updateBtnLayout;
@end
