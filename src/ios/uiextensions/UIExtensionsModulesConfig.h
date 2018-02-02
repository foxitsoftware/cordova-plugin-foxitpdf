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
 * @file	UIExtensionsModulesConfig.h
 * @details	UIExtensions modules config allows you to choose modules to load and designate annotation types.
 */

#import <Foundation/Foundation.h>

/** @brief Modules config for UIExtensionsManager. */
@interface UIExtensionsModulesConfig : NSObject
// whether to load module
@property (nonatomic, assign) BOOL loadThumbnail;
@property (nonatomic, assign) BOOL loadReadingBookmark;
@property (nonatomic, assign) BOOL loadOutline;
@property (nonatomic, assign) BOOL loadAttachment;
@property (nonatomic, assign) BOOL loadForm;
@property (nonatomic, assign) BOOL loadSignature;
@property (nonatomic, assign) BOOL loadSearch;
@property (nonatomic, assign) BOOL loadPageNavigation;
@property (nonatomic, assign) BOOL loadEncryption;
/** @brief Supported tools. For elements please refer to {@link Tool_Note Tool_XXX} values. Annotation of unsupported types are not interactable. */
@property (nonatomic, strong, nullable) NSMutableSet<NSString *> *tools;

- (id __nullable)initWithJSONData:(NSData *__nonnull)data;

@end
