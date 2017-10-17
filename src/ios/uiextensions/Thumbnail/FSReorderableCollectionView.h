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

@class FSReorderableCollectionView;

@protocol FSReorderableCollectionViewDataSource <UICollectionViewDataSource>

- (void)reorderableCollectionView:(FSReorderableCollectionView *_Nullable)collectionView moveItemAtIndexPaths:(NSArray<NSIndexPath *> *_Nonnull)sourceIndexPaths toIndex:(NSUInteger)destinationIndex;

@end

@protocol FSReorderableCollectionViewReorderDelegate <NSObject>

- (void)reorderableCollectionView:(FSReorderableCollectionView *_Nullable)collectionView willMoveItemsAtIndexPaths:(NSArray<NSIndexPath *> *_Nonnull)sourceIndexPaths toIndex:(NSUInteger)destinationIndex;
- (void)reorderableCollectionView:(FSReorderableCollectionView *_Nullable)collectionView didMoveItemsAtIndexPaths:(NSArray<NSIndexPath *> *_Nonnull)sourceIndexPaths toIndex:(NSUInteger)destinationIndex;

@end

// drag and drop cells in colleciont view, assumed only ONE secton
@interface FSReorderableCollectionView : UICollectionView

@property (nonatomic, weak, nullable) id<FSReorderableCollectionViewDataSource> dataSource;
@property (nonatomic, weak, nullable) id<FSReorderableCollectionViewReorderDelegate> reorderDelegate;
@property (nonatomic, readonly) BOOL isDraggingCell;
@property (nonatomic, strong, nullable) NSMutableIndexSet *indexSetForDraggingCells;
@property (nonatomic, strong, nullable) NSIndexPath *indexPathForPlaceholderCell; // a transparent cell showing insert position while dragging
@property (nonatomic, strong, nullable) NSIndexPath *originalIndexPathForPlaceholderCell;

- (NSIndexPath *)getOriginalIndexPathForIndexPath:(NSIndexPath *)indexPath;
- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout isModifiable:(BOOL)isModifiable;

@end
