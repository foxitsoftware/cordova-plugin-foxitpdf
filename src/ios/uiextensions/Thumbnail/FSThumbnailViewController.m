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

#import "UIExtensionsSharedHeader.h"

#import "AlertView.h"
#import "ColorUtility.h"
#import "FSThumbnailCell.h"
#import "FSThumbnailView.h"
#import "FSThumbnailViewController.h"

#import "FSFileAndImagePicker.h"
#import "FileSelectDestinationViewController.h"

#define DEVICE_iPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
static NSArray<NSNumber *> *arrayFromRange(NSRange range);
static NSArray<NSIndexPath *> *indexPathsFromRange(NSRange range);

@interface FSThumbnailViewController () <FSThumbnailCellDelegate, FSReorderableCollectionViewReorderDelegate, FSFileAndImagePickerDelegate>

@property (nonatomic) CGSize cellSize;
// buttom bar
@property (nonatomic, strong) TbBaseBar *bottomBar;
@property (nonatomic) BOOL isBottomBarHidden;
@property (nonatomic, strong) TbBaseItem *moreItem;
@property (nonatomic, strong) TbBaseItem *duplicateItem;
@property (nonatomic, strong) TbBaseItem *deleteItem;
@property (nonatomic, strong) TbBaseItem *rotateItem;
@property (nonatomic, strong) TbBaseItem *extractItem;

// top bar
@property (nonatomic, strong) TbBaseBar *topBar;
@property (nonatomic, strong) TbBaseItem *backItem;
@property (nonatomic, strong) TbBaseItem *titleItem;
@property (nonatomic, strong) TbBaseItem *editItem;
@property (nonatomic, strong) TbBaseItem *doneItem;
@property (nonatomic, strong) TbBaseItem *selectAllItem;
@property (nonatomic, strong) TbBaseItem *insertItem;

// thumbnail loading
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSBlockOperation *> *operations;

// misc
@property (nonatomic) NSInteger insertIndex;

@end

@implementation FSThumbnailViewController

static NSString *const reuseIDForThumbnailCell = @"thumbnailCell";
static NSString *const reuseIDForPlaceholderCell = @"placeholderCell";
static const NSUInteger bottomBarHeight = 49;
static const NSUInteger topBarHeight = 64;

- (instancetype)initWithDocument:(FSPDFDoc *_Nonnull)document {
    if (self = [super init]) {
        self.delegate = nil;
        self.document = document;
        self.isEditing = NO;
        self.operationQueue = ({
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            queue.name = @"load thumbnail queue";
            queue.maxConcurrentOperationCount = 1;
            queue;
        });
        self.operations = [NSMutableDictionary<NSIndexPath *, NSBlockOperation *> dictionary];
        self.cellSize = [self calculateCellSize];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self buildTopBar];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = self.cellSize;

    self.collectionView = [[FSReorderableCollectionView alloc] initWithFrame:CGRectMake(0, topBarHeight, self.view.bounds.size.width, self.view.bounds.size.height - topBarHeight) collectionViewLayout:layout isModifiable:[Utility canAssembleDocument:self.document] && ![self.document isXFA]];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.collectionView registerClass:[FSThumbnailCell class] forCellWithReuseIdentifier:reuseIDForThumbnailCell];
    [self.collectionView registerClass:[FSReorderableCollectionViewPlaceholderCell class] forCellWithReuseIdentifier:reuseIDForPlaceholderCell];
    self.collectionView.delegate = self;
    self.collectionView.reorderDelegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor grayColor];
    self.collectionView.allowsMultipleSelection = YES;
    [self.view addSubview:self.collectionView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.operationQueue cancelAllOperations];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self.operationQueue cancelAllOperations];
}

#pragma mark tool bars

- (void)setIsBottomBarHidden:(BOOL)isBottomBarHidden {
    if (!_bottomBar) {
        [self buildBottomBar];
    }
    if (_isBottomBarHidden == isBottomBarHidden) {
        return;
    }
    _isBottomBarHidden = isBottomBarHidden;
    if (isBottomBarHidden) {
        CGRect newFrame = self.bottomBar.contentView.frame;
        newFrame.origin.y = [UIScreen mainScreen].bounds.size.height;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.bottomBar.contentView.frame = newFrame;
                             [self.bottomBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.height.mas_equalTo(@49);
                                 make.left.equalTo(self.view.mas_left).offset(0);
                                 make.right.equalTo(self.view.mas_right).offset(0);
                                 make.top.equalTo(self.view.mas_bottom).offset(0);
                             }];
                         }];

    } else {
        CGRect newFrame = self.bottomBar.contentView.frame;
        newFrame.origin.y = [UIScreen mainScreen].bounds.size.height - self.bottomBar.contentView.frame.size.height;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.bottomBar.contentView.frame = newFrame;
                             [self.bottomBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.height.mas_equalTo(@49);
                                 make.left.equalTo(self.view.mas_left).offset(0);
                                 make.right.equalTo(self.view.mas_right).offset(0);
                                 make.bottom.equalTo(self.view.mas_bottom).offset(0);

                             }];
                         }];
    }
}

- (void)buildBottomBar {
    //    if (!_bottomBar) {
    _bottomBar = [[TbBaseBar alloc] init];
    _bottomBar.top = NO;
    _bottomBar.contentView.frame = CGRectMake(0, self.view.bounds.size.height - bottomBarHeight, self.view.bounds.size.width, bottomBarHeight);
    //        _bottomBar.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _bottomBar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    _bottomBar.intervalWidth = 100.f;
    if (DEVICE_iPHONE) {
        _bottomBar.intervalWidth = 40.f;
    }

    _rotateItem = [TbBaseItem createItemWithImageAndTitle:FSLocalizedString(@"kRotate") imageNormal:[UIImage imageNamed:@"thumb_rotate"] imageSelected:[UIImage imageNamed:@"thumb_rotate"] imageDisable:[UIImage imageNamed:@"thumb_rotate"] imageTextRelation:RELATION_BOTTOM];
    _rotateItem.textColor = [UIColor blackColor];
    _rotateItem.textFont = [UIFont systemFontOfSize:12.f];

    _extractItem = [TbBaseItem createItemWithImageAndTitle:FSLocalizedString(@"kExtract") imageNormal:[UIImage imageNamed:@"thumb_extract"] imageSelected:[UIImage imageNamed:@"thumb_extract"] imageDisable:[UIImage imageNamed:@"thumb_extract"] imageTextRelation:RELATION_BOTTOM];
    _extractItem.textColor = [UIColor blackColor];
    _extractItem.textFont = [UIFont systemFontOfSize:12.f];

    _deleteItem = [TbBaseItem createItemWithImageAndTitle:FSLocalizedString(@"kDelete") imageNormal:[UIImage imageNamed:@"thumb_delete_black"] imageSelected:[UIImage imageNamed:@"thumb_delete_black"] imageDisable:[UIImage imageNamed:@"thumb_delete_black"] imageTextRelation:RELATION_BOTTOM];
    _deleteItem.textColor = [UIColor blackColor];
    _deleteItem.textFont = [UIFont systemFontOfSize:12.f];

    _duplicateItem = [TbBaseItem createItemWithImageAndTitle:FSLocalizedString(@"kCopy") imageNormal:[UIImage imageNamed:@"thumb_copy"] imageSelected:[UIImage imageNamed:@"thumb_copy"] imageDisable:[UIImage imageNamed:@"thumb_copy"] imageTextRelation:RELATION_BOTTOM];
    _duplicateItem.textColor = [UIColor blackColor];
    _duplicateItem.textFont = [UIFont systemFontOfSize:12.f];

    typeof(self) __weak weakSelf = self;
    _rotateItem.onTapClick = ^(TbBaseItem *item) {
        weakSelf.rotateItem.enable = NO;
        [weakSelf rotateSelected];
        weakSelf.rotateItem.enable = self.collectionView.indexPathsForSelectedItems.count > 0;
    };

    _extractItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf extractSelected];
    };

    _deleteItem.onTapClick = ^(TbBaseItem *item) {
        weakSelf.deleteItem.enable = NO;
        [weakSelf deleteSelected];
    };

    _duplicateItem.onTapClick = ^(TbBaseItem *item) {
        weakSelf.duplicateItem.enable = NO;
        [weakSelf duplicatePages:^{
            weakSelf.duplicateItem.enable = YES;
            // reset selectall
            [weakSelf onCellSelectedOrDeselected];
        }];
    };

    [_bottomBar addItem:_rotateItem displayPosition:Position_CENTER];
    [_bottomBar addItem:_extractItem displayPosition:Position_CENTER];
    [_bottomBar addItem:_deleteItem displayPosition:Position_CENTER];
    [_bottomBar addItem:_duplicateItem displayPosition:Position_CENTER];
    //    }
    if (self.view != _bottomBar.contentView.superview) {
        [self.view addSubview:_bottomBar.contentView];
    }
    self.isBottomBarHidden = YES;
}

- (void)buildTopBar {
    _topBar = [[TbBaseBar alloc] init];
    _topBar.contentView.frame = CGRectMake(0, 0, self.view.bounds.size.width, topBarHeight);
    [self.view addSubview:_topBar.contentView];
    _topBar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    _topBar.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;

    _backItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"property_back"] imageSelected:[UIImage imageNamed:@"property_back"] imageDisable:[UIImage imageNamed:@"property_back"]];

    _titleItem = [TbBaseItem createItemWithTitle:FSLocalizedString(@"kViewModeThumbnail")];
    _titleItem.textColor = [UIColor colorWithRGBHex:0xff3f3f3f];
    _titleItem.enable = NO;
    [_topBar addItem:_titleItem displayPosition:Position_CENTER];

    _editItem = [TbBaseItem createItemWithTitle:FSLocalizedString(@"kEdit")];
    _editItem.textColor = [UIColor colorWithRGBHex:0x179cd8];

    _doneItem = [TbBaseItem createItemWithTitle:FSLocalizedString(@"kDone")];
    _doneItem.textColor = [UIColor colorWithRGBHex:0x179cd8];

    _selectAllItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"thumb_select_all"]
                                       imageSelected:[UIImage imageNamed:@"thumb_selected_all"]
                                        imageDisable:[UIImage imageNamed:@"thumb_select_all"]];

    _insertItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"thumb_insert"]
                                    imageSelected:[UIImage imageNamed:@"thumb_insert"]
                                     imageDisable:[UIImage imageNamed:@"thumb_insert"]];

    typeof(self) __weak weakSelf = self;
    _backItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf.delegate exitThumbnailViewController:weakSelf];
    };

    _editItem.onTapClick = ^(TbBaseItem *item) {
        weakSelf.isEditing = YES;
    };

    _doneItem.onTapClick = ^(TbBaseItem *item) {
        weakSelf.isEditing = NO;
    };

    _selectAllItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf selectOrDeselectAll];
    };

    _insertItem.onTapClick = ^(TbBaseItem *item) {
        __block NSInteger maxSelectedPageIndex = -1;
        [weakSelf.collectionView.indexPathsForSelectedItems enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            maxSelectedPageIndex = MAX(maxSelectedPageIndex, obj.item);
        }];
        weakSelf.insertIndex = maxSelectedPageIndex != -1 ? (int) (maxSelectedPageIndex + 1) : [weakSelf.document getPageCount];
        [weakSelf showInsertMenu:item.button insertBeforeOrAfter:NO];
    };
    [self resetTopBar];
}

- (void)resetTopBar {
    [_topBar removeItem:_backItem];
    [_topBar removeItem:_editItem];
    [_topBar removeItem:_doneItem];
    [_topBar removeItem:_insertItem];
    [_topBar removeItem:_selectAllItem];

    if (self.isEditing) {
        [_topBar addItem:_doneItem displayPosition:Position_RB];
        [_topBar addItem:_insertItem displayPosition:Position_RB];

        if (DEVICE_iPHONE) {
            [_topBar addItem:_selectAllItem displayPosition:Position_LT];
        } else {
            [_topBar addItem:_selectAllItem displayPosition:Position_RB];
        }
    } else {
        [_topBar addItem:_backItem displayPosition:Position_LT];
        if ([Utility canAssembleDocument:self.document] && ![self.document isXFA]) {
            [_topBar addItem:_editItem displayPosition:Position_RB];
        }
        self.titleItem.text = FSLocalizedString(@"kViewModeThumbnail");
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    FSReorderableCollectionView *reorderCollectionView = (FSReorderableCollectionView *) collectionView;
    return [self.document getPageCount] - reorderCollectionView.indexSetForDraggingCells.count + (reorderCollectionView.indexPathForPlaceholderCell ? 1 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FSReorderableCollectionView *reorderableCollectionView = (FSReorderableCollectionView *) collectionView;
    if ([indexPath isEqual:reorderableCollectionView.indexPathForPlaceholderCell]) {
        return [reorderableCollectionView dequeueReusableCellWithReuseIdentifier:reuseIDForPlaceholderCell forIndexPath:indexPath];
    }
    FSThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDForThumbnailCell forIndexPath:indexPath];
    cell.delegate = self;
    cell.isEditing = self.isEditing;
    // remove spinner
    for (UIView *subview in cell.contentView.subviews) {
        if ([subview isKindOfClass:[UIActivityIndicatorView class]]) {
            [subview removeFromSuperview];
            break;
        }
    }
    int pageIndex = (int) [reorderableCollectionView getOriginalIndexPathForIndexPath:indexPath].item;
    cell.labelNumber.text = [NSString stringWithFormat:@"%d", pageIndex + 1];
    // update button frames
    
    float width = 600;
    float height = 800;
    @try{
        FSPDFPage *page = [self.document getPage:pageIndex];
        width = [page getWidth];
        height = [page getHeight];
    }
   @catch(NSException* e)
    {
    }
    CGFloat realWidth = MIN(self.cellSize.width, self.cellSize.height * width / height);
    [cell updateButtonFramesWithThumbnailWidth:realWidth];

    BOOL selected = [[self.collectionView indexPathsForSelectedItems] containsObject:indexPath];
    cell.selected = selected;
    return cell;
}

#pragma mark <FSReorderableCollectionViewDataSource>

- (void)reorderableCollectionView:(FSReorderableCollectionView *)collectionView moveItemAtIndexPaths:(NSArray<NSIndexPath *> *)sourceIndexPaths toIndex:(NSUInteger)destinationIndex {
    NSArray *array = [sourceIndexPaths valueForKey:@"item"];
    BOOL isOK = [self.pageManipulationDelegate movePagesFromIndexes:array toIndex:destinationIndex];
    if (!isOK) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"Warning" message:@"Failed to move pages." buttonClickHandler:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (!self.isEditing) {
        int pageIndex = (int) indexPath.item;
        [self.delegate thumbnailViewController:self openPage:pageIndex];
        return NO;
    } else {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self onCellSelectedOrDeselected];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [self onCellSelectedOrDeselected];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (![cell isKindOfClass:[FSThumbnailCell class]]) {
        return;
    }
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(cell.contentView.bounds.size.width / 2, cell.contentView.bounds.size.height / 2);
    [cell.contentView addSubview:spinner];
    [spinner startAnimating];
    ((FSThumbnailCell *) cell).imageView.image = nil;

    FSReorderableCollectionView *reorderCollectionView = (FSReorderableCollectionView *) collectionView;
    NSUInteger pageIndex = [reorderCollectionView getOriginalIndexPathForIndexPath:indexPath].item;
    CGSize thumbnailSize = ({
        float width = 600;
        float height = 800;
        @try {
            FSPDFPage *page = [self.document getPage:(int) pageIndex];
            width = [page getWidth];
            height = [page getHeight];
        }
        @catch(NSException* e)
        {}
        CGFloat aspectRatio = width / height;
        CGFloat thumbnailWidth = MAX(self.cellSize.width, self.cellSize.height * aspectRatio);
        CGFloat thumbnailHeight = thumbnailWidth / aspectRatio;
        CGSizeMake(thumbnailWidth, thumbnailHeight);
    });

    NSBlockOperation *op;
    __weak __block NSBlockOperation *weakOp;
    __weak typeof(self) weakSelf = self;
    weakOp = op = [NSBlockOperation blockOperationWithBlock:^{
        if (weakOp.isCancelled) {
            return;
        }
        [weakSelf.delegate thumbnailViewController:weakSelf
            getThumbnailForPageAtIndex:pageIndex
            thumbnailSize:thumbnailSize
            needPause:^BOOL {
                return !weakOp || weakOp.isCancelled;
            }
            callback:^(UIImage *thumbnailImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!weakOp.isCancelled && [weakSelf.collectionView.visibleCells containsObject:cell]) {
                        ((FSThumbnailCell *) cell).imageView.image = thumbnailImage;
                        [spinner stopAnimating];
                        [spinner removeFromSuperview];
                    }
                });
            }];
    }];

    [self.operationQueue addOperation:op];
    if (self.operations[indexPath]) {
        [self.operations[indexPath] cancel];
    }
    self.operations[indexPath] = op;

    BOOL selected = [[self.collectionView indexPathsForSelectedItems] containsObject:indexPath];
    cell.selected = selected;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (![self.collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
        NSBlockOperation *operation = self.operations[indexPath];
        [operation cancel];
        self.operations[indexPath] = nil;
    }
}

#pragma mark <UICollectionViewDelegateFlowLayout>

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    UIEdgeInsets cellInsets = [self cellInsets];
    UIEdgeInsets sectionInset = [self sectionInsets];
    return UIEdgeInsetsMake(sectionInset.top, sectionInset.left + cellInsets.left, sectionInset.bottom, sectionInset.right + cellInsets.right);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    UIEdgeInsets cellInsets = [self cellInsets];
    return cellInsets.top + cellInsets.bottom;
    ;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    UIEdgeInsets cellInsets = [self cellInsets];
    return cellInsets.left + cellInsets.right;
    ;
}

#pragma mark <FSThumbnailCellDelegate>

- (void)cell:(FSThumbnailCell *)cell rotateClockwise:(BOOL)clockwise {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        [self cancelDrawingThumbnailsAtIndexPaths:@[ indexPath ]];
        if ([self.pageManipulationDelegate rotatePagesAtIndexes:@[ @(indexPath.item) ] clockwise:clockwise]) {
            BOOL selected = [self.collectionView.indexPathsForSelectedItems containsObject:indexPath];
            [self.collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
            if (selected) {
                [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            }
        } else {
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"Warning" message:@"Failed to rotate page." buttonClickHandler:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (void)deleteCell:(FSThumbnailCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        [self deletePagesAtIndexPaths:@[ indexPath ]];
    }
}

- (void)cell:(FSThumbnailCell *)cell insertBeforeOrAfter:(BOOL)beforeOrAfter {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        self.insertIndex = (beforeOrAfter ? indexPath.item : indexPath.item + 1);
        [self showInsertMenu:beforeOrAfter ? cell.insertPrevBtn : cell.insertNextBtn insertBeforeOrAfter:beforeOrAfter];
    }
}

- (void)didShowEditButtonsInCell:(FSThumbnailCell *)cell {
    for (FSThumbnailCell *visibleCell in self.collectionView.visibleCells) {
        if (visibleCell != cell) {
            [visibleCell dismissLeftBtns];
            [visibleCell dismissRightBtns];
        }
    }
}

#pragma mark <FSReorderableCollectionViewReorderDelegate>

- (void)reorderableCollectionView:(FSReorderableCollectionView *)collectionView willMoveItemsAtIndexPaths:(NSArray<NSIndexPath *> *)sourceIndexPaths toIndex:(NSUInteger)destinationIndex {
    [self cancelDrawingThumbnails];
}

- (void)reorderableCollectionView:(FSReorderableCollectionView *)collectionView didMoveItemsAtIndexPaths:(NSArray<NSIndexPath *> *)sourceIndexPaths toIndex:(NSUInteger)destinationIndex {
    __block NSUInteger maxIndex = destinationIndex;
    __block NSUInteger minIndex = destinationIndex;
    [sourceIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if (obj.item > maxIndex) {
            maxIndex = obj.item;
        }
        if (obj.item < minIndex) {
            minIndex = obj.item;
        }
    }];
    [self updatePageNumberLabelsInRange:NSMakeRange(minIndex, maxIndex - minIndex + 1)];
    [self onCellSelectedOrDeselected];
}

#pragma mark event handler

- (void)setIsEditing:(BOOL)isEditing {
    if (_isEditing != isEditing) {
        _isEditing = isEditing;
        //update tool bars
        [self resetTopBar];
        self.isBottomBarHidden = !isEditing;
        //update collection view
        [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof FSThumbnailCell *_Nonnull cell, NSUInteger idx, BOOL *_Nonnull stop) {
            cell.isEditing = isEditing;
        }];
        [self deselectAll];
    }
}

- (void)selectOrDeselectAll {
    int pageCount = [self.document getPageCount];
    BOOL isSelectAll = (self.collectionView.indexPathsForSelectedItems.count == pageCount);

    if (!isSelectAll) {
        [self selectAll];
    } else {
        [self deselectAll];
    }
}

- (void)rotateSelected {
    NSArray<NSIndexPath *> *selectedIndexPaths = self.collectionView.indexPathsForSelectedItems;
    if (selectedIndexPaths.count > 0) {
        [self cancelDrawingThumbnailsAtIndexPaths:selectedIndexPaths];
        if ([self.pageManipulationDelegate rotatePagesAtIndexes:[selectedIndexPaths valueForKey:@"item"] clockwise:YES]) {
            [self.collectionView reloadItemsAtIndexPaths:selectedIndexPaths];
            [self.collectionView performBatchUpdates:^{
                [selectedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    [self.collectionView selectItemAtIndexPath:obj animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                }];
            }
                                          completion:nil];
        } else {
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"Warning" message:[@"Failed to rotate " stringByAppendingString:selectedIndexPaths.count > 1 ? @"pages." : @"page."] buttonClickHandler:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (void)deleteSelected {
    [self deletePagesAtIndexPaths:self.collectionView.indexPathsForSelectedItems];
}

- (void)extractSelected {
    FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
    selectDestination.isRootFileDirectory = YES;
    selectDestination.fileOperatingMode = FileListMode_Select;
    [selectDestination loadFilesWithPath:DOCUMENT_PATH];
    selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder) {
        [controller dismissViewControllerAnimated:YES completion:nil];
        if (destinationFolder.count == 0)
            return;

        __block void (^inputFileName)(NSString *path) = ^(NSString *path) {
            BOOL isDir = NO;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
                return;
            }
            if (!isDir) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning"
                                                                    message:@"kFileAlreadyExists"
                                                         buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 inputFileName([path stringByDeletingLastPathComponent]);
                                                             });
                                                         }
                                                          cancelButtonTitle:@"kOK"
                                                          otherButtonTitles:nil];
                    [alertView show];
                });
                return;
            }
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kInputNewFileName"
                                                            message:nil
                                                              style:UIAlertViewStylePlainTextInput
                                                 buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                     if (buttonIndex == 0) {
                                                         return;
                                                     }
                                                     NSString *newName = [(AlertView *) alertView textFieldAtIndex:0].text;
                                                     if (newName.length < 1) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             inputFileName(path);
                                                         });
                                                     } else if ([fileManager fileExistsAtPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf", newName]]]) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning"
                                                                                                             message:@"kFileAlreadyExists"
                                                                                                  buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                          inputFileName(path);
                                                                                                      });
                                                                                                  }
                                                                                                   cancelButtonTitle:@"kOK"
                                                                                                   otherButtonTitles:nil];
                                                             [alertView show];
                                                         });
                                                     } else {
                                                         [self extractSelectedToPath:[path stringByAppendingString:[NSString stringWithFormat:@"/%@.pdf", newName]]];
                                                         inputFileName = nil;
                                                     }
                                                 }
                                                  cancelButtonTitle:@"kCancel"
                                                  otherButtonTitles:@"kOK", nil];
            [alertView show];
        };

        inputFileName(destinationFolder[0]);
    };
    selectDestination.cancelHandler = ^(FileSelectDestinationViewController *controller) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    };
    UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
    selectDestinationNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    selectDestinationNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:selectDestinationNavController animated:YES completion:nil];
}

- (void)extractSelectedToPath:(NSString *)destinationPath {
    NSArray<NSNumber *> *pages = [self.collectionView.indexPathsForSelectedItems valueForKey:@"item"];
    if (pages.count == 0) {
        return;
    }
    NSArray *sortPages = [pages sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 intValue] < [obj2 intValue] ? NSOrderedAscending : NSOrderedDescending;
    }];
    //create an empty doc
    FSPDFDoc *doc = [[FSPDFDoc alloc] init];
    //set pageRanges and count
    int count = 2 * (int) (pages.count);
    int a[count];
    for (NSUInteger i = 0; i < pages.count; i++) {
        a[2 * i] = [sortPages[i] intValue];
        a[2 * i + 1] = 1;
    }
    int *pageRanges = a;
    //import by srcDoc
    FSProgressState state = e_progressError;
    FSProgressive* progress = nil;
    @try {
        progress = [doc startImportPages:0 flags:0 layerName:nil srcDoc:self.document pageRanges:pageRanges count:count pause:nil];
        if(!progress)
            state = e_progressFinished;
        else
            state = e_progressToBeContinued;
            
    } @catch (NSException *exception) {
        NSLog(@"FSPDFDoc::startImportPages EXCEPTION NAME:%@", exception.name);
        if ([exception.name isEqualToString:@"e_errUnsupported"]) {
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kUnsupportedDocFormat" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
            [alertView show];
        }
        return;
    }

    while (state == e_progressToBeContinued) {
        state = [progress resume];
    }
    if (e_progressFinished != state) {
        [self convenientAlert:@"Failed to extract!"];
    } else {
        NSDate *date = [NSDate date];
        FSPDFMetadata* metadata = [[FSPDFMetadata alloc] initWithDocument:doc];
        [metadata setCreationDateTime:[Utility convert2FSDateTime:date]];
        if (![doc saveAs:destinationPath saveFlags:e_saveFlagNormal]) {
            [self convenientAlert:@"Failed to extract!"];
        } else {
            [self convenientAlert:@"Successful!"];
        }
    }
    [self onCellSelectedOrDeselected];
}

- (void)duplicatePages:(void (^)(void))completionBlock {
    NSArray<NSNumber *> *selectedPageIndexes = [self.collectionView.indexPathsForSelectedItems valueForKey:@"item"];
    if (selectedPageIndexes.count == 0) {
        return;
    }
    selectedPageIndexes = [selectedPageIndexes sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    NSUInteger maxSelectedPageIndex = selectedPageIndexes.lastObject.unsignedIntegerValue;
    if ([self.pageManipulationDelegate insertPagesFromDocument:self.document withSourceIndexes:selectedPageIndexes flags:e_importFlagNormal layerName:nil atIndex:maxSelectedPageIndex + 1]) {
        NSInteger cellCount = [self.document getPageCount] - self.collectionView.indexSetForDraggingCells.count;
        if (cellCount == 1 || [self.collectionView numberOfItemsInSection:0] == cellCount) {
            [self.collectionView reloadData];
            completionBlock ? completionBlock() : nil;
        } else {
            [self.collectionView performBatchUpdates:^{
                [self.collectionView insertItemsAtIndexPaths:indexPathsFromRange(NSMakeRange(maxSelectedPageIndex + 1, selectedPageIndexes.count))];
            }
                completion:^(BOOL finished) {
                    completionBlock ? completionBlock() : nil;
                }];
        }
        [self updatePageNumberLabelsInRange:NSMakeRange(maxSelectedPageIndex + 1, [self.document getPageCount] - maxSelectedPageIndex - 1)];
    } else {
        [self convenientAlert:@"Failed to copy!"];
        completionBlock ? completionBlock() : nil;
    }
}

#pragma mark insert pages and images

- (void)showInsertMenu:(UIButton *)button insertBeforeOrAfter:(BOOL)beforeOrAfter {
    FSFileAndImagePicker *picker = [[FSFileAndImagePicker alloc] init];
    picker.expectedFileTypes = @[ @"pdf", @"jbig2", @"jpx", @"tif", @"gif", @"png", @"jpg", @"bmp" ];
    picker.delegate = self;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [picker presentInRootViewController:rootViewController fromView:button];
}

//- (void)_showInsertMenu:(UIButton *)button {
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
//    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
//                                                           style:UIAlertActionStyleCancel
//                                                         handler:^(UIAlertAction *action){
//                                                         }];
//
//    UIAlertAction *fileAction = [UIAlertAction actionWithTitle:@"From Document"
//                                                         style:UIAlertActionStyleDefault
//                                                       handler:^(UIAlertAction *action) {
//                                                           [alert dismissViewControllerAnimated:NO completion:nil];
//
//                                                           FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
//                                                           selectDestination.isRootFileDirectory = YES;
//                                                           selectDestination.fileOperatingMode = FileListMode_Import;
//                                                           selectDestination.expectFileType = [[NSArray alloc] initWithObjects:@"pdf", @"jbig2", @"jpx", @"tif", @"gif", @"png", @"jpg", @"bmp", nil];
//                                                           [selectDestination loadFilesWithPath:DOCUMENT_PATH];
//                                                           selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder) {
//                                                               [controller dismissViewControllerAnimated:YES completion:nil];
//                                                               if (destinationFolder.count > 0) {
//                                                                   NSString *srcPath = destinationFolder[0];
//                                                                   if ([srcPath.pathExtension.lowercaseString isEqualToString:@"pdf"]) {
//                                                                       [self insertPages:srcPath atIndex:index];
//                                                                   } else {
//                                                                       UIImage *image = [UIImage imageWithContentsOfFile:srcPath];
//                                                                       [self insertPageFromImage:image atIndex:index];
//                                                                   }
//                                                               }
//                                                           };
//                                                           selectDestination.cancelHandler = ^(FileSelectDestinationViewController *controller) {
//                                                               [controller dismissViewControllerAnimated:YES completion:nil];
//                                                           };
//                                                           UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
//                                                           selectDestinationNavController.modalPresentationStyle = UIModalPresentationFormSheet;
//                                                           selectDestinationNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//                                                           [rootViewController presentViewController:selectDestinationNavController animated:YES completion:nil];
//                                                       }];
//
//    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"From Album"
//                                                          style:UIAlertActionStyleDefault
//                                                        handler:^(UIAlertAction *action) {
//                                                            [alert dismissViewControllerAnimated:NO completion:nil];
//                                                            PhotoToPDFViewController *photoController = [[PhotoToPDFViewController alloc] initWithButton:button];
//                                                            [rootViewController presentViewController:photoController animated:NO completion:nil];
//                                                            [photoController openAlbum];
//                                                            photoController.callback = ^(UIImage *image) {
//                                                                [self insertPageFromImage:image atIndex:index];
//                                                            };
//                                                        }];
//
//    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"From Camera"
//                                                           style:UIAlertActionStyleDefault
//                                                         handler:^(UIAlertAction *action) {
//                                                             [alert dismissViewControllerAnimated:NO completion:nil];
//                                                             PhotoToPDFViewController *photoController = [[PhotoToPDFViewController alloc] initWithButton:button];
//                                                             [rootViewController presentViewController:photoController animated:NO completion:nil];
//                                                             [photoController openCamera];
//                                                             photoController.callback = ^(UIImage *image) {
//                                                                 [self insertPageFromImage:image atIndex:index];
//                                                             };
//                                                         }];
//
//    [alert addAction:cancelAction];
//    [alert addAction:fileAction];
//    [alert addAction:photoAction];
//    [alert addAction:cameraAction];
//
//    alert.popoverPresentationController.sourceView = button.imageView;
//    alert.popoverPresentationController.sourceRect = button.imageView.bounds;
//    [rootViewController presentViewController:alert animated:YES completion:nil];
//}

- (void)insertPages:(NSString *)path atIndex:(int)index {
    void (^insertPagesFromLoadedDocument)(FSPDFDoc *document) = ^(FSPDFDoc *document) {
        NSArray<NSNumber *> *sourcePagesIndexes = arrayFromRange(NSMakeRange(0, [document getPageCount]));
        if ([self.pageManipulationDelegate insertPagesFromDocument:document withSourceIndexes:sourcePagesIndexes flags:e_importFlagNormal layerName:nil atIndex:index]) {
            NSMutableArray<NSIndexPath *> *indexPaths = [[NSMutableArray alloc] init];
            for (int i = index; i < index + [document getPageCount]; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                [indexPaths addObject:indexPath];
            }
            [self.collectionView insertItemsAtIndexPaths:indexPaths];
            [self updatePageNumberLabelsInRange:NSMakeRange(index, [self.document getPageCount])];
        } else {
            [self convenientAlert:@"Failed to insert!"];
        }
    };

    FSPDFDoc *srcDoc = [[FSPDFDoc alloc] initWithFilePath:path];
    [Utility tryLoadDocument:srcDoc
        withPassword:@""
        success:^(NSString *password) {
            insertPagesFromLoadedDocument(srcDoc);
        }
        error:^(NSString *description) {
            [self convenientAlert:description];
        }
        abort:nil];

    // reset selectall
    [self onCellSelectedOrDeselected];
}

- (void)insertPageFromImage:(UIImage *)image atIndex:(int)index {
    if ([self.pageManipulationDelegate insertPageFromImage:image atIndex:index]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        [self.collectionView insertItemsAtIndexPaths:@[ indexPath ]];
        [self updatePageNumberLabelsInRange:NSMakeRange(index, [self.document getPageCount] - index)];
    } else {
        [self convenientAlert:@"Failed to insert!"];
    }
    // reset selectall
    [self onCellSelectedOrDeselected];
}

- (void)convenientAlert:(NSString *)title {
    UIAlertView *alertFailed = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertFailed show];
}

#pragma mark - inner methods

- (void)onCellSelectedOrDeselected {
    int selectedCount = (int) self.collectionView.indexPathsForSelectedItems.count;
    BOOL isAllPagesSelected = (selectedCount == [self.document getPageCount]);
    self.selectAllItem.selected = isAllPagesSelected;

    if (self.isEditing) {
        self.titleItem.text = [NSString stringWithFormat:@"%d", selectedCount];
    }

    BOOL isAnyCellSelected = selectedCount > 0;
    self.deleteItem.enable = isAnyCellSelected;
    self.duplicateItem.enable = isAnyCellSelected;
    self.rotateItem.enable = isAnyCellSelected;
    self.extractItem.enable = isAnyCellSelected && [Utility canExtractContentsInDocument:self.document];
}

- (void)selectAll {
    int pageCount = [self.document getPageCount];
    for (int i = 0; i < pageCount; i++) {
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    assert(pageCount == self.collectionView.indexPathsForSelectedItems.count);
    [self onCellSelectedOrDeselected];
}

- (void)deselectAll {
    for (NSIndexPath *selectedIndexPath in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:selectedIndexPath animated:NO];
    }
    assert(0 == self.collectionView.indexPathsForSelectedItems.count);
    [self onCellSelectedOrDeselected];
}

- (void)deletePagesAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (indexPaths.count == 0) {
        [self onCellSelectedOrDeselected];
        return;
    } else if (indexPaths.count == [self.document getPageCount]) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kNotAllowDeleteAll" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
        [alertView show];
        [self onCellSelectedOrDeselected];
        return;
    }
    indexPaths = [indexPaths sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    AlertViewButtonClickedHandler buttonClickedHandler = ^(UIView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                [self.operations[obj] cancel];
            }];
            [self cancelDrawingThumbnails];
            if (![self.pageManipulationDelegate deletePagesAtIndexes:[indexPaths valueForKey:@"item"]]) {
                [self convenientAlert:@"Failed to delete!"];
                [self onCellSelectedOrDeselected];
                return;
            }
            [self.collectionView deleteItemsAtIndexPaths:indexPaths];
            [self updatePageNumberLabelsInRange:NSMakeRange(indexPaths[0].item, [self.document getPageCount] - indexPaths[0].item)];
        }

        [self onCellSelectedOrDeselected];
    };
    AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kSureToDeletePage" buttonClickHandler:buttonClickedHandler cancelButtonTitle:@"kCancel" otherButtonTitles:@"kOK", nil];
    [alertView show];
}

- (void)updatePageNumberLabelsInRange:(NSRange)range {
    if (range.location == NSNotFound || range.length == 0) {
        return;
    }
    for (NSUInteger i = range.location; i < range.location + range.length; i++) {
        FSThumbnailCell *cell = (FSThumbnailCell *) [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        if ([cell isKindOfClass:[FSThumbnailCell class]]) {
            cell.labelNumber.text = [NSString stringWithFormat:@"%d", (int) i + 1];
        }
    }
}

- (void)cancelDrawingThumbnails {
    [self.operationQueue cancelAllOperations];
    [self.operations removeAllObjects];
}

- (void)cancelDrawingThumbnailsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [self.operations[obj] cancel];
        self.operations[obj] = nil;
    }];
}

#pragma mark <FSFileAndImagePickerDelegate>

- (void)fileAndImagePicker:(FSFileAndImagePicker *)fileAndImagePicker didPickFileAtPath:(NSString *)filePath {
    [self insertPages:filePath atIndex:(int)self.insertIndex];
}

- (void)fileAndImagePicker:(FSFileAndImagePicker *)fileAndImagePicker didPickImage:(UIImage *)image {
    [self insertPageFromImage:image atIndex:(int)self.insertIndex];
}

- (void)fileAndImagePickerDidCancel:(FSFileAndImagePicker *)fileAndImagePicker {
}

#pragma mark <IRotationEventListener>

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark layout sizes

- (CGSize)calculateCellSize {
    CGSize cellSize;
#define OVERVIEW_IMAGE_WIDTH_IPHONE 142.0
#define OVERVIEW_IMAGE_HEIGHT_IPHONE 177.0
#define OVERVIEW_IMAGE_WIDTH 160.0
#define OVERVIEW_IMAGE_HEIGHT 200.0
    if (DEVICE_iPHONE) {
        cellSize = CGSizeMake(OVERVIEW_IMAGE_WIDTH_IPHONE, OVERVIEW_IMAGE_HEIGHT_IPHONE);
    } else {
        cellSize = CGSizeMake(OVERVIEW_IMAGE_WIDTH, OVERVIEW_IMAGE_HEIGHT);
    }

    return cellSize;
}

- (UIEdgeInsets)cellInsets {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    ScreenSizeMode sizeMode = [Utility getScreenSizeMode];
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        if (DEVICE_iPHONE) {
            if (sizeMode == ScreenSizeMode_47) {
                return UIEdgeInsetsMake(5, 12, 5, 12);
            } else if (sizeMode == ScreenSizeMode_55) {
                return UIEdgeInsetsMake(5, -2, 5, -2);
            } else {
                return UIEdgeInsetsMake(5, 6, 5, 6);
            }
        } else {
            return UIEdgeInsetsMake(10, 17, 10, 10);
        }
    } else {
        if (DEVICE_iPHONE) {
            if (sizeMode == ScreenSizeMode_40) {
                return UIEdgeInsetsMake(5, 0, 5, 0);
            } else if (sizeMode == ScreenSizeMode_47) {
                return UIEdgeInsetsMake(5, 9, 5, 8);
            } else if (sizeMode == ScreenSizeMode_55) {
                return UIEdgeInsetsMake(5, 2, 5, 1);
            } else {
                return UIEdgeInsetsMake(5, 7, 5, 7);
            }
        } else {
            return UIEdgeInsetsMake(10, 20, 10, 20);
        }
    }
}

- (UIEdgeInsets)sectionInsets {
    CGFloat topInset = DEVICE_iPHONE ? 10 : 20;

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        if (DEVICE_iPHONE) {
            ScreenSizeMode sizeMode = [Utility getScreenSizeMode];
            if (sizeMode == ScreenSizeMode_47) {
                return UIEdgeInsetsMake(topInset, 20, 44, 16);
            } else if (sizeMode == ScreenSizeMode_55) {
                return UIEdgeInsetsMake(topInset, 0, 44, 0);
            } else {
                return UIEdgeInsetsMake(topInset, 6, 44, 5);
            }
        } else {
            return UIEdgeInsetsMake(topInset, 6, 44, 5);
        }
    } else {
        if (DEVICE_iPHONE) {
            ScreenSizeMode sizeMode = [Utility getScreenSizeMode];
            if (sizeMode == ScreenSizeMode_40) {
                return UIEdgeInsetsMake(topInset, 0, 44, 0);
            } else if (sizeMode == ScreenSizeMode_47) {
                return UIEdgeInsetsMake(topInset, 15, 44, 15);
            } else if (sizeMode == ScreenSizeMode_55) {
                return UIEdgeInsetsMake(topInset, 4, 44, 4);
            } else {
                return UIEdgeInsetsMake(topInset, 5, 44, 5);
            }
        } else {
            return UIEdgeInsetsMake(topInset, 10, 44, 5);
        }
    }
}

@end

static NSArray<NSNumber *> *arrayFromRange(NSRange range) {
    if (range.location == NSNotFound || range.length == 0) {
        return nil;
    }
    NSMutableArray<NSNumber *> *array = [NSMutableArray<NSNumber *> arrayWithCapacity:range.length];
    for (NSUInteger i = range.location; i < range.location + range.length; i++) {
        [array addObject:@(i)];
    }
    return array;
}

static NSArray<NSIndexPath *> *indexPathsFromRange(NSRange range) {
    if (range.location == NSNotFound || range.length == 0) {
        return nil;
    }
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray<NSIndexPath *> arrayWithCapacity:range.length];
    for (NSUInteger i = range.location; i < range.location + range.length; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    return indexPaths;
}
