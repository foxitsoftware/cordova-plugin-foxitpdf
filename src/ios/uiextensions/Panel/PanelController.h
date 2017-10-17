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

/**
 * @file	PanelController.h
 * @details	The panel controller consists panels of annotation, outline and so on.
 */

#import <Foundation/Foundation.h>

@class UIExtensionsManager;
@class FSPanelController;

/** @brief Panel hidden event listener. */
@protocol IPanelChangedListener <NSObject>
/**
 * @brief	Triggered when panel is hidden or shown.
 *
 * @param[in]	isHidden	Whether is hidden or not.
 */
- (void)onPanelChanged:(BOOL)isHidden;

@end

/** @brief Panel types. */
typedef NS_ENUM(NSUInteger, FSPanelType) {
    /** @breif Annotation panel type. */
    FSPanelTypeAnnotation = 0,
    /** @breif Attachment panel type. */
    FSPanelTypeAttachment,
    /** @breif Outline panel type. */
    FSPanelTypeOutline,
    /** @breif Reading bookmark panel type. */
    FSPanelTypeReadingBookmark
};

/** @brief Panel controller. */
@interface FSPanelController : NSObject

@property (nonatomic, assign) BOOL isHidden;
/**
 * @brief	Initialize the panel controller.
 *
 * @param[in]	extensionsManager	The extensions manager.
 *
 * @return	The panel controller instance.
 */
- (instancetype)initWithExtensionsManager:(UIExtensionsManager *)extensionsManager;

/**
 * @brief	Hide or show panel of a specific type.
 *
 * @param[in]	isHidden	Whether is hidden or not.
 * @param[in]	type        Panel type. Please refer to {@link FSPanelType::FSPanelTypeAnnotation FSPanelType::FSPanelTypeXXX} values and this can be one or combination of these values.
 */
- (void)setPanelHidden:(BOOL)isHidden type:(FSPanelType)type;
/**
 * @brief	Register a panel hidden event listener.
 *
 * @param[in]	listener	A panel hidden event listener.
 */
- (void)registerPanelChangedListener:(id<IPanelChangedListener>)listener;
/**
 * @brief	Unregister a panel hidden event listener.
 *
 * @param[in]	listener	A panel hidden event listener.
 */
- (void)unregisterPanelChangedListener:(id<IPanelChangedListener>)listener;

@end
