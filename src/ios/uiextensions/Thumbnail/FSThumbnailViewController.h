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

#import "FSReorderableCollectionView.h"
#import "TbBaseBar.h"
#import <FoxitRDK/FSPDFObjC.h>
#import <UIKit/UIKit.h>

@class FSThumbnailViewController;
@protocol FSPageOrganizerDelegate;
@protocol FSThumbnailViewControllerDelegate;
@protocol IRotationEventListener;

NS_ASSUME_NONNULL_BEGIN

@interface FSThumbnailViewController : UIViewController <UICollectionViewDelegate, FSReorderableCollectionViewDataSource, IRotationEventListener>

@property (nonatomic, weak, nullable) id<FSThumbnailViewControllerDelegate> delegate;
@property (nonatomic, weak, nullable) id<FSPageOrganizerDelegate> pageManipulationDelegate;
@property (nonatomic, strong, nullable) FSReorderableCollectionView *collectionView;
@property (nonatomic, strong, nonnull) FSPDFDoc *document;
@property (nonatomic) BOOL isEditing;

- (instancetype)initWithDocument:(FSPDFDoc *)document;

@end

@protocol FSThumbnailViewControllerDelegate

- (void)exitThumbnailViewController:(FSThumbnailViewController *)thumbnailViewController;
- (void)thumbnailViewController:(FSThumbnailViewController *)thumbnailViewController openPage:(int)page;
- (void)thumbnailViewController:(FSThumbnailViewController *)thumbnailViewController getThumbnailForPageAtIndex:(NSUInteger)index thumbnailSize:(CGSize)thumbnailSize needPause:(BOOL (^__nullable)(void))needPause callback:(void (^)(UIImage *))callback;

@end

NS_ASSUME_NONNULL_END
