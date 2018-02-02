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

#import "UIExtensionsManager.h"

@interface FSThumbnailCache : NSObject <IPageEventListener, IAnnotEventListener>

- (id _Nonnull)initWithUIExtenionsManager:(UIExtensionsManager *_Nonnull)extensionsManager;

- (void)getThumbnailForPageAtIndex:(NSUInteger)index withThumbnailSize:(CGSize)thumbnailSize needPause:(BOOL (^__nullable)(void))needPause callback:(void (^__nonnull)(UIImage *_Nullable))callback;
- (BOOL)removeThumbnailCacheOfPageAtIndex:(NSUInteger)pageIndex;
- (void)clearThumbnailCachesForPDFAtPath:(NSString *_Nonnull)path;

@end
