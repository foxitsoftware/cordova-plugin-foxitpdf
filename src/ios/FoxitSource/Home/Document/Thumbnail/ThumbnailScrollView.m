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

#import <QuartzCore/QuartzCore.h>
#import "ThumbnailScrollView.h"
#import "ThumbnailScrollViewCell.h"
#import "UIGestureRecognizerThumbnailScrollViewAdditions.h"
#import "FileManageListViewController.h"

#define THUMBNAILSCROLLVIEW_INVALID_INDEX -1

static const NSInteger INDEX_TAG_OFFSET = 50;
static const CGFloat DEFAULT_ANIMATION_DURATION = 0.3;
static const UIViewAnimationOptions DEFAULT_ANIMATION_OPTIONS = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction;

@interface ThumbnailScrollView ()

- (void)commonInit;
- (NSArray *)cellSubviews;
- (void)calculateContentSize:(BOOL)animated;
- (NSRange)rangeOfIndexesInBoundsFromOffset:(CGPoint)offset;
- (void)queueReusableForUnseeCells;
- (ThumbnailScrollViewCell *)newCellForIndex:(NSInteger)index;
- (NSInteger)indexOfCellFromLocation:(CGPoint)location;
- (CGRect)frameOfIndex:(NSInteger)index;
- (void)layoutSubviewsWithAnimation:(ThumbnailScrollViewCellAnimation)animation;
- (void)layoutCellsAnimation:(BOOL)animation;
- (void)setSubviewsCacheAsInvalid;
- (CGRect)actualCellFrame:(CGRect)frame;
- (void)applyWithoutAnimation:(void (^)(void))animations; 

// Gestures
- (void)sortingPanGestureUpdated:(UIPanGestureRecognizer *)panGesture;
- (void)sortingAutoScrollMovementCheck;

@end

@implementation ThumbnailScrollView
@synthesize dataSource = _dataSource;
@synthesize actionDelegate = _actionDelegate;
@synthesize sortDelegate = _sortDelegate;
@synthesize mainSuperView = _mainSuperView;

@synthesize contentMargins = _contentMargins;
@synthesize pageMargins = _pageMargins;
@synthesize pagesOfOneRow = _pagesOfOneRow;

@synthesize firstIndexLoaded = _firstIndexLoaded;
@synthesize lastIndexLoaded = _lastIndexLoaded;

@synthesize cellsSubviewsCacheIsValid = _cellsSubviewsCacheIsValid;
@synthesize cellSubviewsCache = _cellSubviewsCache;

@synthesize editing = _editing;
@synthesize isNeedShake = _isNeedShake;
@synthesize isSwapMode = _isSwapMode;
@synthesize cellArrangement = _cellArrangement;
@synthesize lastTapPointInCell = _lastTapPointInCell;
@synthesize isMoving = _isMoving;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit];
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) 
    {
        [self commonInit];
    }
    
    return self;
}

- (void)dealloc
{
    self.actionDelegate = nil;
    self.sortDelegate = nil;
    self.delegate = nil;
    self.dataSource = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];  
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    
    [_reusableCells release];
    [_movingCells release];
    [_movingCellIndexes release];
    [_movingViews release];
    [_cellSubviewsCache release];
    [_sortingPanGesture release];
    [_longPressGesture release];
    [_tapGesture release];
    [super dealloc];
}


#pragma mark - Private methods
- (void)commonInit
{
    _reusableCells = [[NSMutableSet alloc] init];
    _movingCells = [[NSMutableArray alloc] init];
    _movingCellIndexes = [[NSMutableArray alloc] init];
    _movingViews = [[NSMutableArray alloc] init];
    _contentMargins = UIEdgeInsetsMake(64, 0, 44, 0);
    _pageMargins = UIEdgeInsetsMake(5, 5, 5, 5);
    _pagesOfOneRow = 2;
    _isMoving = NO;
    self.scrollEnabled = YES;
    self.mainSuperView = self;
    _isNeedShake = YES;
    _isSwapMode = YES;
    self.contentSize = CGSizeMake(1.0f, 10000.0f);
    _cellArrangement = ThumbnailScrollViewCellArrangementDown;
    
    //Tap gestures 
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureUpdated:)];
    _tapGesture.delegate = self;
    _tapGesture.cancelsTouchesInView = NO;
    _tapGesture.numberOfTapsRequired = 1;
    _tapGesture.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:_tapGesture];
    
    //Sorting gestures
    _noNeedReload = THUMBNAILSCROLLVIEW_INVALID_INDEX;
    _sortingPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(sortingPanGestureUpdated:)];
    _sortingPanGesture.delegate = self;
    [self addGestureRecognizer:_sortingPanGesture];
    
    UIPanGestureRecognizer *panGestureRecognizer = nil;
    if ([self respondsToSelector:@selector(panGestureRecognizer)]) // iOS5 only
    { 
        panGestureRecognizer = self.panGestureRecognizer;
    }
    else 
    {
        for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) 
        { 
            if ([gestureRecognizer  isKindOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")]) 
            {
                panGestureRecognizer = (UIPanGestureRecognizer *) gestureRecognizer;
            }
        }
    }
    [panGestureRecognizer setMaximumNumberOfTouches:1];
    [panGestureRecognizer requireGestureRecognizerToFail:_sortingPanGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedWillRotateNotification:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (CGRect)actualCellFrame:(CGRect)frame
{
    frame.origin.x += _pageMargins.left;
    frame.origin.y += _pageMargins.top;
    frame.size.width -= (_pageMargins.left + _pageMargins.right);
    frame.size.height -= (_pageMargins.top + _pageMargins.bottom);
    return frame;
}

- (void)setSubviewsCacheAsInvalid
{
    _cellsSubviewsCacheIsValid = NO;
}

- (NSArray *)cellSubviews
{
    NSArray *subviews = nil;
    
    if (self.cellsSubviewsCacheIsValid) 
    {
        subviews = self.cellSubviewsCache;
    }
    else
    {
        @synchronized(self)
        {
            NSMutableArray *itemSubViews = [[NSMutableArray alloc] initWithCapacity:_cellCount];
            
            for (UIView * v in [self subviews]) 
            {
                if ([v isKindOfClass:[ThumbnailScrollViewCell class]]) 
                {
                    [itemSubViews addObject:v];
                }
            }
            
            subviews = itemSubViews;
            self.cellSubviewsCache = subviews;
            [itemSubViews release];
            _cellsSubviewsCacheIsValid = YES;
        }
    }
    
    return [[subviews retain] autorelease];
}

- (void)queueReusableForUnseeCells
{    
    NSRange rangeOfIndexes = [self rangeOfIndexesInBoundsFromOffset:self.contentOffset];
    ThumbnailScrollViewCell *cell;
    
    if ((NSInteger)rangeOfIndexes.location > self.firstIndexLoaded) 
    {
        for (NSInteger i = self.firstIndexLoaded; i < (NSInteger)rangeOfIndexes.location; i++) 
        {
            cell = [self cellOfIndex:i];
            if(cell)
            {
                [self queueReusableCell:cell];
                [cell removeFromSuperview];
            }
        }
        
        self.firstIndexLoaded = rangeOfIndexes.location;
        [self setSubviewsCacheAsInvalid];
    }
    
    if ((NSInteger)NSMaxRange(rangeOfIndexes) < self.lastIndexLoaded) 
    {
        for (NSInteger i = NSMaxRange(rangeOfIndexes); i <= self.lastIndexLoaded; i++)
        {
            cell = [self cellOfIndex:i];
            if(cell)
            {
                [self queueReusableCell:cell];
                [cell removeFromSuperview];
            }
        }
        
        self.lastIndexLoaded = NSMaxRange(rangeOfIndexes);
        [self setSubviewsCacheAsInvalid];
    }
}

- (void)calculateContentSize:(BOOL)animated
{
    NSInteger numberOfRows = ceil(_cellCount / (1.0 * _pagesOfOneRow));
    CGSize scrollViewContentSize = CGSizeMake(ceil((_cellSize.width + _pageMargins.left + _pageMargins.right) * _pagesOfOneRow), 
                                              ceil((_cellSize.height + _pageMargins.top + _pageMargins.bottom) * numberOfRows));
    scrollViewContentSize.width = ceil(scrollViewContentSize.width + _contentMargins.left + _contentMargins.right);
    scrollViewContentSize.height = ceil(scrollViewContentSize.height + _contentMargins.top + _contentMargins.bottom);
    _minPossibleContentOffset = CGPointMake(0, 0);
    _maxPossibleContentOffset = CGPointMake(scrollViewContentSize.width - self.bounds.size.width + self.contentInset.right, 
                                            scrollViewContentSize.height - self.bounds.size.height + self.contentInset.bottom);
    BOOL shouldUpdateScrollViewContentSize = !CGSizeEqualToSize(scrollViewContentSize, self.contentSize);
    if (shouldUpdateScrollViewContentSize)
    {
        if (scrollViewContentSize.height <= self.bounds.size.height || self.bounds.size.height == 0)
        {
            scrollViewContentSize =CGSizeMake(scrollViewContentSize.width, self.bounds.size.height + _contentMargins.top + (_contentMargins.top == 0.0f ? _contentMargins.bottom : 0.0f));
        }
        if (animated)
        {
            [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION
                                  delay:0 
                                options:DEFAULT_ANIMATION_OPTIONS 
                             animations:^{
                                 self.contentSize = scrollViewContentSize;
                             }
                             completion:nil];            
        }
        else
        {
            self.contentSize = scrollViewContentSize;
        }
    }
}

- (NSRange)rangeOfIndexesInBoundsFromOffset:(CGPoint)offset;
{
    CGPoint contentOffset = CGPointMake(MAX(0, offset.x), 
                                        MAX(0, offset.y - _contentMargins.top));
    
    CGFloat itemHeight = _cellSize.height + _pageMargins.top + _pageMargins.bottom;
    
    CGFloat firstRow = MAX(0, (int)(contentOffset.y / itemHeight) - 1);
    
    CGFloat lastRow = ceil((contentOffset.y + self.bounds.size.height) / itemHeight);
    
    NSInteger firstPosition = firstRow * _pagesOfOneRow;
    NSInteger lastPosition  = ((lastRow + 1) * _pagesOfOneRow);
    
    return NSMakeRange(firstPosition, (lastPosition - firstPosition));    
}

- (void)layoutSubviewsWithAnimation:(ThumbnailScrollViewCellAnimation)animation
{
    [self calculateContentSize:!(animation & ThumbnailScrollViewCellAnimationNone)];
    [self layoutCellsAnimation:animation & ThumbnailScrollViewCellAnimationFade];
    [self loadRequiredCells];
}

- (void)layoutCellsAnimation:(BOOL)animation
{
    void (^layoutBlock)(void) = ^{
        for (UIView *view in [self cellSubviews])
        {        
            if ([_movingCells indexOfObject:view] == NSNotFound) 
            {
                ThumbnailScrollViewCell *cell = (ThumbnailScrollViewCell *)view;
                NSInteger index = cell.tag - INDEX_TAG_OFFSET;
                if (index >= 0 && index < _cellCount)
                {
                    CGRect frame = [self frameOfIndex:index];
                    frame.origin.x += _pageMargins.left;
                    frame.origin.y += _pageMargins.top;
                    frame.size.width -= (_pageMargins.left + _pageMargins.right);
                    frame.size.height -= (_pageMargins.top + _pageMargins.bottom);
                    if (!CGRectEqualToRect(frame, view.frame))
                    {
                        cell.frame = frame;
                    }
                }
            }
        }
    };
    
    if (animation) 
    {
        [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION 
                              delay:0
                            options:DEFAULT_ANIMATION_OPTIONS
                         animations:^{
                             layoutBlock();
                         }
                         completion:nil
         ];
    }
    else 
    {
        layoutBlock();
    }    
}

- (void)applyWithoutAnimation:(void (^)(void))animations
{
    if (animations) 
    {
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        animations();
        [CATransaction commit];
    }    
}

#pragma mark - load cells methods

- (void)reloadData
{
    [_reusableCells release], _reusableCells = nil;
    [_movingCells release], _movingCells = nil;
    [_movingCellIndexes release], _movingCellIndexes = nil;
    [_movingViews release], _movingViews  = nil;
    [_cellSubviewsCache release], _cellSubviewsCache = nil;
    
    
    [[self cellSubviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop)
     {
         if ([obj isKindOfClass:[ThumbnailScrollViewCell class]]) 
         {
             [(UIView *)obj removeFromSuperview];
             [self queueReusableCell:(ThumbnailScrollViewCell *)obj];
         }
     }]; 
    self.firstIndexLoaded = THUMBNAILSCROLLVIEW_INVALID_INDEX;
    self.lastIndexLoaded = THUMBNAILSCROLLVIEW_INVALID_INDEX;
    [self setSubviewsCacheAsInvalid];
    _pagesOfOneRow = [self.dataSource thumbnailScrollView:self numberPagesOfOneRowInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    _contentMargins = [self.dataSource thumbnailScrollView:self contentMarginsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    _pageMargins = [self.dataSource thumbnailScrollView:self pageMarginsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    _cellCount = [self.dataSource numberOfItemsInThumbnailScrollView:self];
    if (_cellCount == 0)
    {
        return;
    }
    
    _cellSize = [self.dataSource sizeForCellsInThumbnailScrollView:self];
    [self calculateContentSize:NO];
    [self loadRequiredCells];
    [self setSubviewsCacheAsInvalid];
}

- (void)loadRequiredCells
{
    if (_cellCount == 0)
        return;

    NSRange rangeOfIndexes = [self rangeOfIndexesInBoundsFromOffset:self.contentOffset];
    NSRange rangeLoadedIndexes = NSMakeRange(self.firstIndexLoaded, self.lastIndexLoaded - self.firstIndexLoaded);
    self.firstIndexLoaded = self.firstIndexLoaded == THUMBNAILSCROLLVIEW_INVALID_INDEX ? rangeOfIndexes.location : MIN(self.firstIndexLoaded, (NSInteger)rangeOfIndexes.location);
    self.lastIndexLoaded  = self.lastIndexLoaded == THUMBNAILSCROLLVIEW_INVALID_INDEX ? NSMaxRange(rangeOfIndexes) : MAX(self.lastIndexLoaded, (NSInteger)(rangeOfIndexes.length + rangeOfIndexes.location));
    
    [self setSubviewsCacheAsInvalid];
    [self queueReusableForUnseeCells];
    
    BOOL forceLoad = self.firstIndexLoaded == THUMBNAILSCROLLVIEW_INVALID_INDEX || self.lastIndexLoaded == THUMBNAILSCROLLVIEW_INVALID_INDEX;
    NSInteger indexToLoad;
    for (NSUInteger i = 0; i < rangeOfIndexes.length; i++) 
    {
        indexToLoad = i + rangeOfIndexes.location;
        
        if ((forceLoad || !NSLocationInRange(indexToLoad, rangeLoadedIndexes)) && indexToLoad < _cellCount) 
        {
            if (![self cellOfIndex:indexToLoad] && indexToLoad != _noNeedReload) 
            {
                ThumbnailScrollViewCell *cell = [self newCellForIndex:indexToLoad];
                [self addSubview:cell];
            }
        }
    }
    [self setSubviewsCacheAsInvalid];
}

- (ThumbnailScrollViewCell *)newCellForIndex:(NSInteger)index
{
    NSAssert(index >= 0 && index < _cellCount, @"Invalid cell index at newCellForIndex");
    ThumbnailScrollViewCell *cell = [self.dataSource thumbnailScrollView:self cellAtIndex:index];
    cell.scrollView = self;
    CGRect frame = [self frameOfIndex:index];
    frame.origin.x = frame.origin.x + _pageMargins.left;
    frame.origin.y = frame.origin.y + _pageMargins.top;
    frame.size.width = frame.size.width - _pageMargins.left - _pageMargins.right;
    frame.size.height = frame.size.height - _pageMargins.top - _pageMargins.bottom;
    [self applyWithoutAnimation:^{
        cell.frame = frame;
        cell.containerView.frame = cell.bounds;
        cell.contentView.frame = cell.containerView.bounds;
    }];

    cell.tag = index + INDEX_TAG_OFFSET;
    return cell;
}

- (CGRect)frameOfIndex:(NSInteger)index
{
    NSAssert(index >=0 && index < _cellCount, @"Invalid cell index at frameOfIndex");
    NSUInteger col = index % _pagesOfOneRow;
    NSUInteger row = index / _pagesOfOneRow;
    CGPoint cellOffset = CGPointMake(col * (_cellSize.width + _pageMargins.left + _pageMargins.right), 
                                     row * (_cellSize.height + _pageMargins.top + _pageMargins.bottom));
    cellOffset.x += _contentMargins.left;
    cellOffset.y += _contentMargins.top;
    CGRect frame = CGRectMake(cellOffset.x, cellOffset.y, _cellSize.width + (_pageMargins.left + _pageMargins.right), _cellSize.height + (_pageMargins.top + _pageMargins.bottom));
    return frame;
}

- (ThumbnailScrollViewCell *)cellOfIndex:(NSInteger)index
{

    ThumbnailScrollViewCell *view = nil;
    for (ThumbnailScrollViewCell *v in [self cellSubviews]) 
    {
        if (v.tag == index + INDEX_TAG_OFFSET) 
        {
            view = v;
            break;
        }
    }
    
    return view;
}

- (NSInteger)indexOfCellFromLocation:(CGPoint)location
{
    CGPoint relativeLocation = CGPointMake(location.x - _contentMargins.left,
                                           location.y - _contentMargins.top);
    
    int col = (int) (relativeLocation.x / (_cellSize.width + _pageMargins.left + _pageMargins.right)); 
    int row = (int) (relativeLocation.y / (_cellSize.height + _pageMargins.top + _pageMargins.bottom));
    
    int position = col + row * _pagesOfOneRow;
    
    if (position >= _cellCount || position < 0) 
        position = THUMBNAILSCROLLVIEW_INVALID_INDEX;
    else
    {
        CGRect cellFrame = [self actualCellFrame:[self frameOfIndex:position]];
        
        if (!CGRectContainsPoint(cellFrame, location)) 
            position = THUMBNAILSCROLLVIEW_INVALID_INDEX;
    }
    
    return position;    
}

- (void)queueReusableCell:(ThumbnailScrollViewCell *)cell
{
    if (cell)
    {
        if (self.actionDelegate && [self.actionDelegate respondsToSelector:@selector(thumbnailScrollView:willQueueReusableCell:)])
            [self.actionDelegate thumbnailScrollView:self willQueueReusableCell:cell];

        [cell prepareForReuse];
        [_reusableCells addObject:cell];
        [cell removeFromSuperview];
    }
}

- (ThumbnailScrollViewCell *)dequeueReusableCell
{
    ThumbnailScrollViewCell *cell = [[[_reusableCells anyObject] retain] autorelease];
    
    if (cell) 
        [_reusableCells removeObject:cell];
    
    return cell;
}

- (ThumbnailScrollViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    ThumbnailScrollViewCell *cell = nil;
    
    for (ThumbnailScrollViewCell *reusableCell in [_reusableCells allObjects]) 
    {
        if ([reusableCell.reuseIdentifier isEqualToString:identifier]) 
        {
            cell = [[reusableCell retain] autorelease];
            break;
        }
    }
    
    if (cell) 
        [_reusableCells removeObject:cell];
    
    return cell;    
}

#pragma mark Public methods
- (NSInteger)cellIndexOfCenterPoint
{
    NSInteger index = THUMBNAILSCROLLVIEW_INVALID_INDEX;
    if (self.firstIndexLoaded != THUMBNAILSCROLLVIEW_INVALID_INDEX && self.lastIndexLoaded != THUMBNAILSCROLLVIEW_INVALID_INDEX)
        index = self.firstIndexLoaded + floorf((float)(self.lastIndexLoaded - self.firstIndexLoaded) / 2);

    return index;
}

- (void)scrollToCellAtIndex:(NSInteger)index scrollPosition:(ThumbnailScrollViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    NSAssert(index >= 0 && index < _cellCount, @"Invalid cell index at scrollToCellAtIndex");
    CGRect cellFrame = [self frameOfIndex:index];
    switch (scrollPosition)
    {
        case ThumbnailScrollViewScrollPositionNone:
        case ThumbnailScrollViewScrollPositionBottom:
        default:
            break;
        case ThumbnailScrollViewScrollPositionMiddle:
            cellFrame.origin.y = cellFrame.origin.y + floorf(((CGFloat)(self.bounds.size.height - cellFrame.size.height) / 2));
            break;
        case ThumbnailScrollViewScrollPositionTop:
            cellFrame.origin.y = cellFrame.origin.y + floorf((CGFloat)(self.bounds.size.height - cellFrame.size.height));
            break;
    }
    
    [UIView animateWithDuration:animated ? DEFAULT_ANIMATION_DURATION : 0
                          delay:0
                        options:DEFAULT_ANIMATION_OPTIONS
                     animations:^{
                         [self scrollRectToVisible:cellFrame animated:NO];
                         [self setSubviewsCacheAsInvalid];
                     } 
                     completion:^(BOOL finished){
                     }
     ];
}

- (void)reloadCellAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self reloadCellAtIndex:index withAnimation:animated ? ThumbnailScrollViewCellAnimationScroll : ThumbnailScrollViewCellAnimationNone];
}

- (void)reloadCellAtIndex:(NSInteger)index withAnimation:(ThumbnailScrollViewCellAnimation)animation
{
    NSAssert(index >= 0 && index < _cellCount, @"Invalid cell index at reloadCellAtIndex");
    UIView *currentView = [self cellOfIndex:index];
    ThumbnailScrollViewCell *cell = [self newCellForIndex:index];
    CGRect frame = [self frameOfIndex:index];
    frame = [self actualCellFrame:frame];
    cell.frame = frame;
    cell.alpha = 0;
    [self addSubview:cell];
  
    currentView.tag = INDEX_TAG_OFFSET - 1;
    BOOL shouldScroll = animation & ThumbnailScrollViewCellAnimationScroll;
    BOOL animate = animation & ThumbnailScrollViewCellAnimationFade;
    if (!animate)
    {
        if (shouldScroll)
            [self scrollToCellAtIndex:index scrollPosition:ThumbnailScrollViewScrollPositionNone animated:NO];

        cell.alpha = 1.0f;
        currentView.alpha = 0;
        [currentView removeFromSuperview];
    }
    else
    {
        [UIView animateWithDuration:animate ? DEFAULT_ANIMATION_DURATION : 0.f
                              delay:0.f
                            options:DEFAULT_ANIMATION_OPTIONS
                         animations:^{
                             if (shouldScroll) {
                                 [self scrollToCellAtIndex:index scrollPosition:ThumbnailScrollViewScrollPositionNone animated:NO];
                             }
                             currentView.alpha = 0;
                             cell.alpha = 1;
                         } 
                         completion:^(BOOL finished){
                             [currentView removeFromSuperview];
                         }
         ];
    }
    [self setSubviewsCacheAsInvalid];
}

- (void)insertCellAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self insertCellAtIndex:index withAnimation:animated ? ThumbnailScrollViewCellAnimationScroll : ThumbnailScrollViewCellAnimationNone];
}

- (void)insertCellAtIndex:(NSInteger)index withAnimation:(ThumbnailScrollViewCellAnimation)animation
{
    NSAssert((index >= 0 && index <= _cellCount), @"Invalid cell index at insertCellAtIndex");
    
    ThumbnailScrollViewCell *cell = nil;
    
    if (index >= self.firstIndexLoaded && index <= self.lastIndexLoaded) 
    {        
        cell = [self newCellForIndex:index];
        
        for (int i = (int)_cellCount - 1; i >= index; i--)
        {
            UIView *oldView = [self cellOfIndex:i];
            oldView.tag = oldView.tag + 1;
        }
        
        if (animation & ThumbnailScrollViewCellAnimationFade) {
            cell.alpha = 0;
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDelay:DEFAULT_ANIMATION_DURATION];
            [UIView setAnimationDuration:DEFAULT_ANIMATION_DURATION];
            cell.alpha = 1.0;
            [UIView commitAnimations];
        }
        [self addSubview:cell];
    }
    
    _cellCount++;
    [self calculateContentSize:!(animation & ThumbnailScrollViewCellAnimationNone)];
    
    BOOL shouldScroll = animation & ThumbnailScrollViewCellAnimationScroll;
    if (shouldScroll)
    {
        [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION 
                              delay:0
                            options:DEFAULT_ANIMATION_OPTIONS
                         animations:^{
                             [self scrollToCellAtIndex:index scrollPosition:ThumbnailScrollViewScrollPositionNone animated:NO];
                         } 
                         completion:^(BOOL finished){
                             [self layoutSubviewsWithAnimation:animation];
                         }
         ];
    }
    else 
        [self layoutSubviewsWithAnimation:animation];
    
    [self setSubviewsCacheAsInvalid];
}

- (void)removeCellAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self removeCellAtIndex:index withAnimation:animated ? ThumbnailScrollViewCellAnimationScroll : ThumbnailScrollViewCellAnimationNone];
}

- (void)removeCellAtIndex:(NSInteger)index withAnimation:(ThumbnailScrollViewCellAnimation)animation
{
    NSAssert((index >= 0 && index < _cellCount), @"Invalid cell index at removeCellAtIndex");
    
    ThumbnailScrollViewCell *cell = [self cellOfIndex:index];
    
    for (int i = (int)index + 1; i < _cellCount; i++)
    {
        ThumbnailScrollViewCell *oldView = [self cellOfIndex:i];
        oldView.tag = oldView.tag - 1;
    }
    
    cell.tag = INDEX_TAG_OFFSET - 1;
    _cellCount--;
    
    BOOL shouldScroll = animation & ThumbnailScrollViewCellAnimationScroll;
    BOOL animate = animation & ThumbnailScrollViewCellAnimationFade;
    [UIView animateWithDuration:animate ? DEFAULT_ANIMATION_DURATION : 0.f
                          delay:0.f
                        options:DEFAULT_ANIMATION_OPTIONS
                     animations:^{
                         cell.containerView.alpha = 0.3f;
                         cell.alpha = 0.f;
                         
                         if (shouldScroll) {
                             [self scrollToCellAtIndex:index scrollPosition:ThumbnailScrollViewScrollPositionNone animated:NO];
                         }
                         [self calculateContentSize:!(animation & ThumbnailScrollViewCellAnimationNone)];
                     } 
                     completion:^(BOOL finished) {
                         cell.containerView.alpha = 1.f;
                         [self queueReusableCell:cell];
                         [cell removeFromSuperview];
                         
                         self.firstIndexLoaded = self.lastIndexLoaded = THUMBNAILSCROLLVIEW_INVALID_INDEX;
                         [self loadRequiredCells];
                         [self layoutCellsAnimation:animate];
                         if (self.actionDelegate && [self.actionDelegate respondsToSelector:@selector(thumbnailScrollView:didDeleteCellAtIndex:)])
                         {
                             [self.actionDelegate thumbnailScrollView:self didDeleteCellAtIndex:index];
                         }
                     }
     ];
    [self setSubviewsCacheAsInvalid];    
}

- (void)swapCellAtIndex:(NSInteger)index1 withCellAtIndex:(NSInteger)index2 animated:(BOOL)animated
{
    [self swapCellAtIndex:index1 withCellAtIndex:index2 withAnimation:animated ? ThumbnailScrollViewCellAnimationScroll : ThumbnailScrollViewCellAnimationNone];
}

- (void)swapCellAtIndex:(NSInteger)index1 withCellAtIndex:(NSInteger)index2 withAnimation:(ThumbnailScrollViewCellAnimation)animation
{
    NSAssert((index1 >= 0 && index1 < _cellCount), @"Invalid cell index1 at swapCellAtIndex");
    NSAssert((index2 >= 0 && index2 < _cellCount), @"Invalid cell index2 at swapCellAtIndex");
    
    ThumbnailScrollViewCell *view1 = [self cellOfIndex:index1];
    ThumbnailScrollViewCell *view2 = [self cellOfIndex:index2];
    
    view1.tag = index2 + INDEX_TAG_OFFSET;
    view2.tag = index1 + INDEX_TAG_OFFSET;
    
    CGRect frame1 = [self frameOfIndex:index2];
    CGRect frame2 = [self frameOfIndex:index1];
    
    view1.frame = [self actualCellFrame:frame1];
    view2.frame = [self actualCellFrame:frame2];
    
    
    CGRect visibleRect = CGRectMake(self.contentOffset.x,
                                    self.contentOffset.y, 
                                    self.contentSize.width, 
                                    self.contentSize.height);
    
    // Better performance animating ourselves instead of using animated:YES in scrollRectToVisible
    BOOL shouldScroll = animation & ThumbnailScrollViewCellAnimationScroll;
    [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION 
                          delay:0
                        options:DEFAULT_ANIMATION_OPTIONS
                     animations:^{
                         if (shouldScroll) {
                             if (!CGRectIntersectsRect(view2.frame, visibleRect)) 
                             {
                                 [self scrollToCellAtIndex:index1 scrollPosition:ThumbnailScrollViewScrollPositionNone animated:NO];
                             }
                             else if (!CGRectIntersectsRect(view1.frame, visibleRect)) 
                             {
                                 [self scrollToCellAtIndex:index2 scrollPosition:ThumbnailScrollViewScrollPositionNone animated:NO];
                             }
                         }
                     } 
                     completion:^(BOOL finished) {
                         [self setNeedsLayout];
                     }];    
}


- (BOOL)checkTapPointInCellContent:(ThumbnailScrollViewCell *)cell subView:(UIView *)subView
{
    BOOL ret = NO;
    NSInteger index = [self indexOfCellFromLocation:self.lastTapPointInCell];
    if (index != THUMBNAILSCROLLVIEW_INVALID_INDEX)
    {
        ThumbnailScrollViewCell *cellAtPoint = [self cellOfIndex:index];
        if (cell != nil && cellAtPoint != nil && cell == cellAtPoint)
        {
            CGPoint pointInCell = [self convertPoint:self.lastTapPointInCell toView:cellAtPoint];
            if (subView != nil)
            {
                ret = CGRectContainsPoint(subView.frame, pointInCell);
            }
        }
    }
    return ret;
}

#pragma mark UIScrollView delegate

- (void)setContentOffset:(CGPoint)contentOffset
{
    BOOL valueChanged = !CGPointEqualToPoint(contentOffset, self.contentOffset);
    
    [super setContentOffset:contentOffset];
    
    if (valueChanged) 
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadRequiredCells];
        });
    }
}

#pragma mark Setter/Getter
- (void)setDataSource:(NSObject<ThumbnailScrollViewSource> *)dataSource
{
    _dataSource = dataSource;
    if (dataSource == nil)
    {
        return;
    }
    [self reloadData];
}

- (void)setPageMargins:(UIEdgeInsets)pageMargins
{
    if (!UIEdgeInsetsEqualToEdgeInsets(_pageMargins, pageMargins))
    {
        _pageMargins = pageMargins;
        [self layoutSubviewsWithAnimation:ThumbnailScrollViewCellAnimationNone];
    }
}

- (void)setContentMargins:(UIEdgeInsets)contentMargins
{
    if (!UIEdgeInsetsEqualToEdgeInsets(_contentMargins, contentMargins))
    {
        _contentMargins = contentMargins;
        [self layoutSubviewsWithAnimation:ThumbnailScrollViewCellAnimationNone];
    }
}

- (void)setPagesOfOneRow:(int)pagesOfOneRow
{
    if (_pagesOfOneRow != pagesOfOneRow)
    {
        _pagesOfOneRow = pagesOfOneRow;
        [self layoutSubviewsWithAnimation:ThumbnailScrollViewCellAnimationNone];
    }
}

- (void)setMainSuperView:(UIView *)mainSuperView
{
    _mainSuperView = mainSuperView != nil ? mainSuperView : self;
}

#pragma mark super methods
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (_isRotationActive)
    {
        _isRotationActive = NO;    
        int pages = [self.dataSource thumbnailScrollView:self numberPagesOfOneRowInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        UIEdgeInsets contentMargins = [self.dataSource thumbnailScrollView:self contentMarginsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        UIEdgeInsets pageMargins = [self.dataSource thumbnailScrollView:self pageMarginsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        if (pages != _pagesOfOneRow || !(UIEdgeInsetsEqualToEdgeInsets(contentMargins, _contentMargins)) || !(UIEdgeInsetsEqualToEdgeInsets(pageMargins, _pageMargins)))
        {
            _pagesOfOneRow = pages;
            _contentMargins = contentMargins;
            _pageMargins = pageMargins;
            CATransition *transition = [CATransition animation];
            transition.duration = 0.25f;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            [self.layer addAnimation:transition forKey:@"rotationAnimation"];
            [self setSubviewsCacheAsInvalid];
            [self applyWithoutAnimation:^{
                [self layoutSubviewsWithAnimation:ThumbnailScrollViewCellAnimationNone];
            }];            
        }
        else
        {
            [self layoutSubviewsWithAnimation:ThumbnailScrollViewCellAnimationNone];
        }
    }
    
}

#pragma mark - notifaction methods
- (void)receivedWillRotateNotification:(NSNotification *)notification
{
    _isRotationActive = YES;
}

- (void)receivedMemoryWarningNotification:(NSNotification *)notification
{
    [self queueReusableForUnseeCells];
    [_reusableCells removeAllObjects];
}

#pragma mark Tap gesture
//////////////////////////////////////////////////////////////

- (void)tapGestureUpdated:(UITapGestureRecognizer *)tapGesture
{
    CGPoint locationTouch = [_tapGesture locationInView:self];
    NSInteger index = [self indexOfCellFromLocation:locationTouch];
    if (index != THUMBNAILSCROLLVIEW_INVALID_INDEX)
    {
        if (self.actionDelegate && [self.actionDelegate respondsToSelector:@selector(thumbnailScrollView:didTapOnCellAtIndex:)])
        {
            ThumbnailScrollViewCell * cell = [self cellOfIndex:index];
            if (cell != nil)
            {
                self.lastTapPointInCell = locationTouch;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.actionDelegate thumbnailScrollView:self didTapOnCellAtIndex:index];
            });
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    FileManageListViewController *fileList = (FileManageListViewController *)self.dataSource;
    if (fileList.viewMode == 1 && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && fileList.isEditing)
    {
        return NO;
    }
    return YES;
}

#pragma mark - Sort Gestures
- (void)sortingPanGestureUpdated:(UIPanGestureRecognizer *)panGesture
{
    switch (panGesture.state) 
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            _autoScrollActive = NO;
            break;
        }
        case UIGestureRecognizerStateBegan:
        {            
            _autoScrollActive = YES;
            [self sortingAutoScrollMovementCheck];
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGesture translationInView:self];
            CGPoint offset = translation;
            CGPoint locationInScroll = [panGesture locationInView:self];
            if (!_isSwapMode)
            {
                for (UIImageView *imageView in _movingViews)
                {
                    CGAffineTransform transForm = CGAffineTransformMakeScale(imageView.transform.a, imageView.transform.d);
                    imageView.transform = CGAffineTransformTranslate(transForm, offset.x, offset.y);
                }
            }
            else
            {
                for (UIView *view in _movingCells)
                {
                        ThumbnailScrollViewCell *cell =(ThumbnailScrollViewCell *)view;
                        CGAffineTransform transForm = CGAffineTransformMakeScale(cell.transform.a, cell.transform.d);
                        cell.transform = CGAffineTransformTranslate(transForm, offset.x, offset.y);
                }
            }
            if (_isEnableSort)
            {
                [self sortingMoveDidContinueToPoint:locationInScroll];
            }
            
            break;
        }
        default:
            break;
    }    
}

#pragma mark GestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL valid = YES;
    BOOL isScrolling = self.isDragging || self.isDecelerating;
    if (gestureRecognizer == _tapGesture)
    {
        valid = !isScrolling && ![_longPressGesture hasRecognizedValidGesture];
    }
    else if (gestureRecognizer == _longPressGesture)
    {
        valid = self.sortDelegate && !isScrolling;
    }
    else if (gestureRecognizer == _sortingPanGesture) 
    {
        valid = (_movingCellIndexes.count != 0 && [_longPressGesture hasRecognizedValidGesture]);
    }
    return valid;
}

#pragma mark - Sorting movement control

- (void)sortingMoveDidContinueToPoint:(CGPoint)point
{
    NSInteger index = [self indexOfCellFromLocation:point];
    NSInteger tag = index + INDEX_TAG_OFFSET;
    if (!_isSwapMode)
    {
        if (self.sortDelegate && [self.sortDelegate respondsToSelector:@selector(thumbnailScrollView:blankCellIndexChangedFrom:toIndex:)] && (_sortFutureIndex != index))
        {
            [self.sortDelegate thumbnailScrollView:self blankCellIndexChangedFrom:_sortFutureIndex toIndex:index];
        }
        _sortFutureIndex = index;
        [self layoutCellsAnimation:YES];
        return;
    }
    ThumbnailScrollViewCell *cell = [_movingCells objectAtIndex:0];
    if (index != THUMBNAILSCROLLVIEW_INVALID_INDEX && index != _sortFutureIndex && index < _cellCount) 
    {
        BOOL positionTaken = NO;
        for (UIView *v in [self cellSubviews])
        {
            if (v != cell && v.tag == tag) 
            {
                positionTaken = YES;
                break;
            }
        }
        if (self.sortDelegate && [self.sortDelegate respondsToSelector:@selector(thumbnailScrollView:blankCellIndexChangedFrom:toIndex:)])
        {
            [self.sortDelegate thumbnailScrollView:self blankCellIndexChangedFrom:_sortFutureIndex toIndex:index];
        }
        if (positionTaken)
        {
            if (index > _sortFutureIndex) 
            {
                for (UIView *v in [self cellSubviews])
                {
                    if ((v.tag == tag || (v.tag < tag && v.tag >= _sortFutureIndex + INDEX_TAG_OFFSET)) && v != cell ) 
                    {
                        v.tag = v.tag - 1;
                        [self sendSubviewToBack:v];
                    }
                }
            }
            else
            {
                for (UIView *v in [self cellSubviews])
                {
                    if ((v.tag == tag || (v.tag > tag && v.tag <= _sortFutureIndex + INDEX_TAG_OFFSET)) && v != cell) 
                    {
                        v.tag = v.tag + 1;
                        [self sendSubviewToBack:v];
                    }
                }
            }            
            [self layoutCellsAnimation:YES];
        }
        else if (positionTaken)
        {
            [self layoutCellsAnimation:YES];
        }
        _sortFutureIndex = index;
    }
    
}

- (void)sortingAutoScrollMovementCheck
{
    if (_movingCellIndexes > 0 && _autoScrollActive && _isEnableSort)
    {
        CGPoint locationInMainView = [_sortingPanGesture locationInView:self];
        locationInMainView = CGPointMake(locationInMainView.x - self.contentOffset.x,
                                         locationInMainView.y -self.contentOffset.y
                                         );
        
        
        CGFloat threshhold = _cellSize.height;
        CGPoint offset = self.contentOffset;
        CGPoint locationInScroll = [_sortingPanGesture locationInView:self];
        
        // Going right
        if (locationInMainView.y + threshhold / 2 > self.bounds.size.height) 
        {            
            offset.y += _cellSize.height / 2;
            
            if (offset.y > _maxPossibleContentOffset.y) 
            {
                offset.y = _maxPossibleContentOffset.y;
            }
        }
        // Going left
        else if (locationInMainView.y - threshhold / 2 <= 0) 
        {            
            offset.y -= _cellSize.height / 2;
            
            if (offset.y < _minPossibleContentOffset.y) 
            {
                offset.y = _minPossibleContentOffset.y;
            }
        }
        
        if (offset.x != self.contentOffset.x || offset.y != self.contentOffset.y) 
        {
            //self.contentOffset = offset;
            [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION 
                                  delay:0
                                options:DEFAULT_ANIMATION_OPTIONS
                             animations:^{
                                    self.contentOffset = offset;
                             }
                             completion:^(BOOL finished){
                                 
                                 self.contentOffset = offset;
                                 
                                 if (_autoScrollActive) 
                                 {
                                     [self sortingMoveDidContinueToPoint:locationInScroll];
                                 }
                                 
                                 [self sortingAutoScrollMovementCheck];
                             }
             ];
        }
        else
        {
            [self performSelector:@selector(sortingAutoScrollMovementCheck) withObject:nil afterDelay:0.5];
        }
    }    
}

@end
