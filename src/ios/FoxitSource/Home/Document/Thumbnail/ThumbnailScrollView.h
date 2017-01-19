/**
 * Copyright (C) 2003-2016, Foxit Software Inc..
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
@class ThumbnailScrollViewCell;
@protocol ThumbnailScrollViewSource;
@protocol ThumbnailScrollViewActionDelegate;
@protocol ThumbnailScrollViewSortDelegate;

typedef enum
{
    ThumbnailScrollViewCellAnimationNone = 0,
    ThumbnailScrollViewCellAnimationFade,
    ThumbnailScrollViewCellAnimationScroll = 1 << 7
} ThumbnailScrollViewCellAnimation;

typedef enum 
{
    ThumbnailScrollViewScrollPositionNone,
    ThumbnailScrollViewScrollPositionTop,
    ThumbnailScrollViewScrollPositionMiddle,
    ThumbnailScrollViewScrollPositionBottom
} ThumbnailScrollViewScrollPosition;

typedef enum
{
    ThumbnailScrollViewCellArrangementDown,
    ThumbnailScrollViewCellArrangementRight
} ThumbnailScrollViewCellArrangement;

@interface ThumbnailScrollView : UIScrollView<UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    NSMutableArray *_movingCells;
    NSMutableArray *_movingCellIndexes;
    NSMutableArray *_movingViews;
    BOOL _isEnableSort;
    NSInteger _sortFutureIndex;
    NSInteger _sortFutureIndexFirstTime;
    NSInteger _noNeedReload;
    
    NSMutableSet *_reusableCells;
    NSInteger _cellCount;
    CGSize _cellSize;
    BOOL _isRotationActive;
    BOOL _autoScrollActive;
    CGPoint _minPossibleContentOffset;
    CGPoint _maxPossibleContentOffset;
    
    BOOL _isNeedShake;
    BOOL _isSwapMode;
    BOOL _isCellEditing;
    
    
    // Sorting Gestures
    UIPanGestureRecognizer       *_sortingPanGesture;
    UILongPressGestureRecognizer *_longPressGesture;
    UITapGestureRecognizer       *_tapGesture;
    
    
}
@property (assign, nonatomic) IBOutlet id <ThumbnailScrollViewSource> dataSource;
@property (assign, nonatomic) IBOutlet id <ThumbnailScrollViewActionDelegate> actionDelegate;
@property (assign, nonatomic) IBOutlet id <ThumbnailScrollViewSortDelegate> sortDelegate;
@property (assign, nonatomic) IBOutlet UIView *mainSuperView;


@property (assign, nonatomic) UIEdgeInsets contentMargins;
@property (assign, nonatomic) UIEdgeInsets pageMargins;
@property (assign, nonatomic) int pagesOfOneRow;

@property (atomic) NSInteger firstIndexLoaded;
@property (atomic) NSInteger lastIndexLoaded;

@property (assign, nonatomic) BOOL editing;
@property (assign, nonatomic) BOOL isNeedShake;
@property (assign, nonatomic) BOOL isSwapMode;
@property (assign, nonatomic) ThumbnailScrollViewCellArrangement cellArrangement;
@property (nonatomic, readonly) BOOL cellsSubviewsCacheIsValid;
@property (nonatomic, retain) NSArray *cellSubviewsCache;
@property (nonatomic, assign) CGPoint lastTapPointInCell;
@property (nonatomic, assign) BOOL isMoving;


- (void)reloadData;
- (void)loadRequiredCells;
- (void)queueReusableCell:(ThumbnailScrollViewCell *)cell;

- (ThumbnailScrollViewCell *)dequeueReusableCell;
- (ThumbnailScrollViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

- (void)scrollToCellAtIndex:(NSInteger)index scrollPosition:(ThumbnailScrollViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (ThumbnailScrollViewCell *)cellOfIndex:(NSInteger)index;
- (NSInteger)cellIndexOfCenterPoint;

//
- (void)reloadCellAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)reloadCellAtIndex:(NSInteger)index withAnimation:(ThumbnailScrollViewCellAnimation)animation;
- (void)insertCellAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)insertCellAtIndex:(NSInteger)index withAnimation:(ThumbnailScrollViewCellAnimation)animation;
- (void)removeCellAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)removeCellAtIndex:(NSInteger)index withAnimation:(ThumbnailScrollViewCellAnimation)animation;
- (void)swapCellAtIndex:(NSInteger)index1 withCellAtIndex:(NSInteger)index2 animated:(BOOL)animated;
- (void)swapCellAtIndex:(NSInteger)index1 withCellAtIndex:(NSInteger)index2 withAnimation:(ThumbnailScrollViewCellAnimation)animation;

//
- (BOOL)checkTapPointInCellContent:(ThumbnailScrollViewCell *)cell subView:(UIView *)subView;
@end




//ThumbnailScrollView data source
@protocol ThumbnailScrollViewSource <NSObject>

@required
- (int)numberOfItemsInThumbnailScrollView:(ThumbnailScrollView *)scrollView;
- (CGSize)sizeForCellsInThumbnailScrollView:(ThumbnailScrollView *)scrollView;
- (ThumbnailScrollViewCell *)thumbnailScrollView:(ThumbnailScrollView *)scrollView cellAtIndex:(NSInteger)index;
- (int)thumbnailScrollView:(ThumbnailScrollView *)scrollView numberPagesOfOneRowInInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (UIEdgeInsets)thumbnailScrollView:(ThumbnailScrollView *)scrollView contentMarginsInInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (UIEdgeInsets)thumbnailScrollView:(ThumbnailScrollView *)scrollView pageMarginsInInterfaceOrientation:(UIInterfaceOrientation)orientation;

@optional
- (CGSize)thumbnailScrollView:(ThumbnailScrollView *)scrollView sizeForCellAtIndex:(NSInteger)index;
@end


@protocol ThumbnailScrollViewSortDelegate <NSObject>

@optional
- (BOOL)shouldSortInThumbnailScrollView:(ThumbnailScrollView *)scrollView cellIndex:(int)cellIndex;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView blankCellIndexChangedFrom:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView willSortCellIndexes:(NSArray *)cellIndexes blankCellIndex:(NSInteger)blankCellIndex;
- (BOOL)thumbnailScrollView:(ThumbnailScrollView *)scrollView shouldSortCellIndexes:(NSArray *)cellIndexes blankCellIndex:(NSInteger)blankCellIndex;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didCancelSortCellIndexes:(NSArray *)cellIndexes blankCellIndex:(NSInteger)blankCellIndex;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView willSortLayoutCellIndexes:(NSArray *)cellIndexes;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didSortLayoutCellIndexes:(NSArray *)cellIndexes;
- (UIImage *)thumbnailScrollView:(ThumbnailScrollView *)scrollView imageCopyCell:(ThumbnailScrollViewCell *)cell;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView willSortLayoutCell:(ThumbnailScrollViewCell *)cell cellIndex:(NSInteger)cellIndex;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didSortLayoutCell:(ThumbnailScrollViewCell *)cell cellIndex:(NSInteger)cellIndex;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView moreSelectedCellIndex:(NSInteger)cellIndex;

@end

//ThumbnailScrollView delegate
@protocol ThumbnailScrollViewActionDelegate <NSObject>

@optional
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didTapOnCellAtIndex:(NSInteger)index;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didDeleteCellAtIndex:(NSInteger)index;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView willQueueReusableCell:(ThumbnailScrollViewCell *)cell;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView startEditCell:(ThumbnailScrollViewCell *)cell isReloading:(BOOL)isReloading;
- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView stopEditCell:(ThumbnailScrollViewCell *)cell;

@end