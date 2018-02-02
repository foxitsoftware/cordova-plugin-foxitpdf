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

#import <UIKit/UIKit.h>

@class FSThumbnailCell;

@protocol FSThumbnailCellDelegate <NSObject>

- (void)cell:(FSThumbnailCell *)cell rotateClockwise:(BOOL)clockwise;
- (void)deleteCell:(FSThumbnailCell *)cell;
- (void)cell:(FSThumbnailCell *)cell insertBeforeOrAfter:(BOOL)beforeOrAfter;
- (void)didShowEditButtonsInCell:(FSThumbnailCell *)cell;

@end

@interface FSThumbnailCell : UICollectionViewCell <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<FSThumbnailCellDelegate> delegate;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *labelNumber;
@property (nonatomic, strong) UIButton *checkBtn; // top left check box
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) BOOL alwaysHideCheckBox;

@property (nonatomic, strong) UIButton *deleteBtn;      //delete
@property (nonatomic, strong) UIButton *rotateLeftBtn;  //rotateLeft
@property (nonatomic, strong) UIButton *rotateRightBtn; //rotateRight
@property (nonatomic, strong) UIButton *insertPrevBtn;  //insertPrev
@property (nonatomic, strong) UIButton *insertNextBtn;  //insertNext

- (void)prepareForReuse;
- (void)updateButtonFramesWithThumbnailWidth:(CGFloat)thumbnailWidth;
- (void)showLeftBtns;
- (void)showRightBtns;
- (void)dismissLeftBtns;
- (void)dismissRightBtns;

@end

@interface FSReorderableCollectionViewPlaceholderCell : UICollectionViewCell

@end
