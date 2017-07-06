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
#import <FoxitRDK/FSPDFObjC.h>
#import "FSReorderableCollectionView.h"
#import "TbBaseBar.h"

@class FSThumbnailViewController;
@protocol FSPageOrganizerDelegate;
@protocol FSThumbnailViewControllerDelegate;
@protocol IRotationEventListener;

@interface FSThumbnailViewController : UIViewController <UICollectionViewDelegate, FSReorderableCollectionViewDataSource, IRotationEventListener>

@property (nonatomic, weak) id<FSThumbnailViewControllerDelegate> delegate;
@property (nonatomic, weak) id<FSPageOrganizerDelegate> pageManipulationDelegate;
@property (nonatomic, strong) FSReorderableCollectionView* collectionView;
@property (nonatomic, strong) FSPDFDoc* document;
@property (nonatomic) BOOL isEditing;

- (instancetype)initWithDocument:(FSPDFDoc*)document;

@end

@protocol FSThumbnailViewControllerDelegate

- (void)exitThumbnailViewController:(FSThumbnailViewController *)thumbnailViewController;
- (void)thumbnailViewController:(FSThumbnailViewController *)thumbnailViewController openPage:(int)page;
- (void)thumbnailViewController:(FSThumbnailViewController *)thumbnailViewController PagesInserted:(FSPDFDoc*)destDoc;
- (void)thumbnailViewController:(FSThumbnailViewController *)thumbnailViewController getThumbnailForPageAtIndex:(NSUInteger)index thumbnailSize:(CGSize)thumbnailSize callback:(void(^ __nonnull)(UIImage *thumbnailImage))callback;

@end
