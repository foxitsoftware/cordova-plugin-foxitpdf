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


#import "FSReorderableCollectionView.h"
#import "UIView+shake.h"

static NSMutableIndexSet *indexSetFromIndexPaths(NSArray<NSIndexPath *> *indexPaths);
static NSMutableArray<NSIndexPath *> *indexPathsFromRange(NSRange range);
static NSMutableArray<NSIndexPath *> *indexPathsFromIndexSet(NSIndexSet *indexSet);

@interface WrapperDataSource : NSObject <FSReorderableCollectionViewDataSource>

@property (nonatomic, weak, nullable) id <FSReorderableCollectionViewDataSource> originalDataSource;

+ (WrapperDataSource *_Nonnull)dataSourceWithOriginalDataSource:(id<UICollectionViewDataSource> _Nullable)originalDataSource;

@end

@interface FSReorderableCollectionView ()

@property (nonatomic, strong) UIView *movingCellSnapshotView;

// auto scroll
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) CGFloat autoscrollSpeed;
@property (nonatomic) BOOL isAutoscrollDown;
@property (nonatomic) BOOL isModifiable;

@end

@implementation FSReorderableCollectionView

@dynamic dataSource;

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout isModifiable:(BOOL)isModifiable{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        longPress.delaysTouchesBegan = YES;
        longPress.minimumPressDuration = 0.3f;
        [self addGestureRecognizer:longPress];
        self.isModifiable = isModifiable;
        self.autoscrollSpeed = 200.0f;
        self.indexPathForPlaceholderCell = nil;
        self.originalIndexPathForPlaceholderCell = nil;
        self.indexSetForDraggingCells = nil;
    }
    return self;
}

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource {
    [super setDataSource:dataSource];
}

- (BOOL)isDraggingCell {
    return self.indexSetForDraggingCells.count > 0;
}

#pragma mark <UICollectionViewDataSource>

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gesutre {

    if (!self.isModifiable) {
        return;
    }
    switch (gesutre.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint pos = [gesutre locationInView:self];
            NSIndexPath* currentIndexPath = [self indexPathForItemAtPoint:pos];
            if (currentIndexPath) {
                UICollectionViewCell* cell = [self cellForItemAtIndexPath:currentIndexPath];
                [self setupSnapshotViewOfMovingCellAtIndexPath:currentIndexPath withGesturePosition:pos completion:nil];
                 {
                     self.originalIndexPathForPlaceholderCell = currentIndexPath;
                     
                     if (!cell.isSelected) {
                         [self selectItemAtIndexPath:currentIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                     }
                     NSArray<NSIndexPath *> *selectedIndexPaths = self.indexPathsForSelectedItems;
                     self.indexSetForDraggingCells = indexSetFromIndexPaths(selectedIndexPaths);
                     assert(!self.indexPathForPlaceholderCell);
                     [self deleteItemsAtIndexPaths:selectedIndexPaths];
                     
                     self.indexPathForPlaceholderCell = [self indexPathForItemAtPoint:pos] ?: ({
                         NSIndexPath *lastIndexPath = self.indexPathsForVisibleItems.lastObject;
                         lastIndexPath
                         ? [NSIndexPath indexPathForItem:lastIndexPath.item+1 inSection:0]
                         : [NSIndexPath indexPathForItem:0 inSection:0];
                     });
                     [self insertItemsAtIndexPaths:@[ self.indexPathForPlaceholderCell ]];
                 }
            }
        }
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGPoint pos = [gesutre locationInView:self];
            self.movingCellSnapshotView.center = pos;
            if(!self.indexPathForPlaceholderCell)
                break;
            assert(self.indexPathForPlaceholderCell);
            NSIndexPath* newIndexPath = [self indexPathForItemAtPoint:pos];
            if (newIndexPath && ![newIndexPath isEqual:self.indexPathForPlaceholderCell]) {
                [self moveItemAtIndexPath:self.indexPathForPlaceholderCell toIndexPath:newIndexPath];
                self.indexPathForPlaceholderCell = newIndexPath;
            }
            
            if(self.visibleCells.count == 0)
                break;
            //autoscroll
            CGFloat cellHeight = self.visibleCells[0].contentView.bounds.size.height;
            if (pos.y - self.contentOffset.y < cellHeight && self.contentOffset.y > 1e-3) {
                [self autoscrollUp];
            } else if (pos.y  - self.contentOffset.y > self.bounds.size.height - cellHeight) {
                [self autoscrollDown];
            } else {
                [self stopAutoscroll];
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if(!self.indexPathForPlaceholderCell)
                break;
            assert(self.indexPathForPlaceholderCell);
            CGPoint pos = [gesutre locationInView:self];
            self.movingCellSnapshotView.center = pos;
            NSIndexPath* newIndexPath = [self indexPathForItemAtPoint:pos];
            if (newIndexPath && ![newIndexPath isEqual:self.indexPathForPlaceholderCell]) {
                [self moveItemAtIndexPath:self.indexPathForPlaceholderCell toIndexPath:newIndexPath];
                self.indexPathForPlaceholderCell = newIndexPath;
            }
            
            NSUInteger originalDestinationIndex = self.indexPathForPlaceholderCell.item == 0 ? 0
            : [self getOriginalIndexPathForIndexPath:[NSIndexPath indexPathForItem:self.indexPathForPlaceholderCell.item-1 inSection:0]].item + 1;
            NSMutableArray<NSIndexPath *> *sourceIndexPaths = indexPathsFromIndexSet(self.indexSetForDraggingCells);
            [self.reorderDelegate reorderableCollectionView:self willMoveItemsAtIndexPaths:sourceIndexPaths toIndex:originalDestinationIndex];
            [self.dataSource reorderableCollectionView:self moveItemAtIndexPaths:sourceIndexPaths toIndex:originalDestinationIndex];
            
            NSIndexPath *indexPathForPlaceholderCell = self.indexPathForPlaceholderCell;
            self.indexPathForPlaceholderCell = nil;
            self.originalIndexPathForPlaceholderCell = nil;
            [self deleteItemsAtIndexPaths:@[ indexPathForPlaceholderCell ]];
            
            NSUInteger numDraggingCells = self.indexSetForDraggingCells.count;
            self.indexSetForDraggingCells = nil;
            
            [self insertItemsAtIndexPaths:indexPathsFromRange(NSMakeRange(indexPathForPlaceholderCell.item, numDraggingCells))];
            
            [self tearDownSnapshotViewOfMovingCellAtIndexPath:indexPathForPlaceholderCell completion:^{
                [self.reorderDelegate reorderableCollectionView:self didMoveItemsAtIndexPaths:sourceIndexPaths toIndex:originalDestinationIndex];
            }];
            
            [self stopAutoscroll];
        }
            break;
            
        default:
            break;
    }
}

- (void)setupSnapshotViewOfMovingCellAtIndexPath:(NSIndexPath *)indexPath withGesturePosition:(CGPoint)position completion:(void(^)())completion {
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
    assert(cell);
    UIView *snapshotView = [cell.contentView snapshotViewAfterScreenUpdates:YES];
    snapshotView.center = cell.center;
    snapshotView.tag = indexPath.item;
    int selectedCount = (int)self.indexPathsForSelectedItems.count;
    if (selectedCount > 1) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:15];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = [NSString stringWithFormat:@"%d", selectedCount];
        [label sizeToFit];
        label.center = CGPointMake(CGRectGetMaxX(snapshotView.bounds), 0);
        [snapshotView addSubview:label];
        [snapshotView sizeToFit];
    }
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         cell.contentView.alpha = 0.0;
                         snapshotView.alpha = 0.7;
                         snapshotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                         [snapshotView shakeStatus:YES];
                         snapshotView.layer.shadowOpacity = 0.7;
                         snapshotView.center = position;
                     }
                     completion:^(BOOL finished) {
                         if (completion) {
                             completion();
                         }
                     }];
    
    [self addSubview:snapshotView];
    [self bringSubviewToFront:snapshotView];
    self.movingCellSnapshotView = snapshotView;
}

- (void)tearDownSnapshotViewOfMovingCellAtIndexPath:(NSIndexPath *)indexPath completion:(void(^)())completion {
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
    if(!cell) return;
    cell.contentView.alpha = 0.0f;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:0
                     animations:^{
                         self.movingCellSnapshotView.transform = CGAffineTransformIdentity;
                         self.movingCellSnapshotView.frame = (CGRect) {cell.frame.origin, self.movingCellSnapshotView.frame.size};
                         cell.contentView.alpha = 0.5f;
                     }
                     completion:^(BOOL finished) {
                         [self.movingCellSnapshotView removeFromSuperview];
                         self.movingCellSnapshotView = nil;
                         cell.contentView.alpha = 1.0f;
                         if (completion) {
                             completion();
                         }
                     }
     ];
}

- (NSIndexPath *)getOriginalIndexPathForIndexPath:(NSIndexPath *)indexPath {
    if (!self.isDraggingCell) {
        return indexPath;
    }
    if ([indexPath isEqual:self.indexPathForPlaceholderCell]) {
        return self.originalIndexPathForPlaceholderCell;
    }
    NSUInteger originIndex = 0;
    NSUInteger index = NSNotFound;
    while (1) {
        if (![self.indexSetForDraggingCells containsIndex:originIndex]) {
            index = index == NSNotFound ? 0 : (index+1);
            // ignore placeholder cell
            if (self.indexPathForPlaceholderCell && index == self.indexPathForPlaceholderCell.item) {
                index ++;
            }
            if (index == indexPath.item) {
                return [NSIndexPath indexPathForItem:originIndex inSection:0];
            }
        }
        originIndex ++;
    }
}

#pragma mark autoscroll

- (void)autoscrollDown {
    [self autoscrollWithIsAutoscrollDown:YES];
}

- (void)autoscrollUp {
    [self autoscrollWithIsAutoscrollDown:NO];
}

- (void)autoscrollWithIsAutoscrollDown:(BOOL)isAutoscrollDown {
    if (self.displayLink && !self.displayLink.paused && isAutoscrollDown == self.isAutoscrollDown) {
        return;
    }
    [self stopAutoscroll];
//    NSLog(@"begin autoscrolling");
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleAutoscroll:)];
    self.isAutoscrollDown = isAutoscrollDown;
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopAutoscroll {
    if (self.displayLink) {
//        NSLog(@"end autoscrolling");
        if (!self.displayLink.paused) {
            [self.displayLink invalidate];
        }
        self.displayLink = nil;
    }
}

- (void)handleAutoscroll:(CADisplayLink *)displayLink {
    CGFloat translationY = (self.isAutoscrollDown ? 1.0f : -1.0f) * self.autoscrollSpeed * displayLink.duration;
    translationY = rint(translationY);
    if (translationY + self.contentOffset.y < 0) {
        translationY = -self.contentOffset.y;
    }
    CGFloat maxY = MAX(self.contentSize.height, self.bounds.size.height);
    if (translationY + self.contentOffset.y > maxY - self.bounds.size.height) {
        translationY = maxY - self.bounds.size.height - self.contentOffset.y;
    }

    self.movingCellSnapshotView.center = ({
        CGPoint center = self.movingCellSnapshotView.center;
        center.y += translationY;
        center;
    });
    self.contentOffset = ({
        CGPoint cntentOffset = self.contentOffset;
        cntentOffset.y += translationY;
        cntentOffset;
    });
}

@end

static NSMutableIndexSet *indexSetFromIndexPaths(NSArray<NSIndexPath *> *indexPaths) {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *indexPath in indexPaths) {
        [indexSet addIndex:indexPath.item];
    }
    return indexSet;
}

static NSMutableArray<NSIndexPath *> *indexPathsFromIndexSet(NSIndexSet *indexSet) {
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray<NSIndexPath *>  arrayWithCapacity:indexSet.count];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
    }];
    return indexPaths;
}

static NSMutableArray<NSIndexPath *> *indexPathsFromRange(NSRange range) {
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray<NSIndexPath *>  arrayWithCapacity:range.length];
    for (NSUInteger i = range.location; i < range.location + range.length; i ++) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    return indexPaths;
}
