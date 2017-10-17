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
#import <FoxitRDK/FSPDFViewControl.h>
#import <UIKit/UIKit.h>

@class UIExtensionsManager;
@protocol IAnnotEventListener;

@interface FSThumbnailCache : NSObject <IPageEventListener, IAnnotEventListener>

- (id)initWithUIExtenionsManager:(UIExtensionsManager *)extensionsManager;

- (void)getThumbnailForPageAtIndex:(NSUInteger)index withThumbnailSize:(CGSize)thumbnailSize needPause:(BOOL (^__nullable)())needPause callback:(void (^__nonnull)(UIImage *))callback;
- (BOOL)removeThumbnailCacheOfPageAtIndex:(NSUInteger)pageIndex;
- (void)clearThumbnailCachesForPDFAtPath:(NSString *)path;

@end
