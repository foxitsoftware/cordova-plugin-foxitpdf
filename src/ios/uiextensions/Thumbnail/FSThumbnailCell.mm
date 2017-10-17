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

#import "FSThumbnailCell.h"

@implementation FSReorderableCollectionViewPlaceholderCell

@end

@interface FSThumbnailCell ()

@property (nonatomic, strong) UISwipeGestureRecognizer *swipeRightGesture;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeLeftGesture;

@end

@implementation FSThumbnailCell

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.isEditing = NO;
        self.alwaysHideCheckBox = NO;

        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [self addSubviews];
        [self addButtons];

        //swipe gestures
        self.swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRightGesture:)];
        self.swipeRightGesture.enabled = NO;
        [self addGestureRecognizer:self.swipeRightGesture];
        self.swipeRightGesture.delegate = self;

        self.swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeftGesture:)];
        self.swipeLeftGesture.enabled = NO;
        self.swipeLeftGesture.delegate = self;
        self.swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:self.swipeLeftGesture];
    }
    return self;
}

- (void)addSubviews {
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView = [[UIImageView alloc] init];
    self.imageView.frame = self.contentView.bounds;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.imageView];

    UIImageView *imagePageNmuberBackground = [[UIImageView alloc] init];
    imagePageNmuberBackground.frame = ({
        CGFloat width = 60;
        CGFloat height = 20;
        CGFloat x = (self.bounds.size.width - width) / 2;
        CGFloat bottomInset = 5;
        CGFloat y = self.frame.size.height - height - bottomInset;
        CGRectMake(x, y, width, height);
    });
    imagePageNmuberBackground.image = [[UIImage imageNamed:@"thumb_page_index_bg"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    imagePageNmuberBackground.alpha = 0.8;
    imagePageNmuberBackground.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.contentView addSubview:imagePageNmuberBackground];

    self.labelNumber = [[UILabel alloc] init];
    self.labelNumber.frame = CGRectMake(0, self.frame.size.height - 25, self.frame.size.width, 20);
    self.labelNumber.font = [UIFont systemFontOfSize:16];
    self.labelNumber.textColor = [UIColor whiteColor];
    self.labelNumber.backgroundColor = [UIColor clearColor];
    self.labelNumber.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.labelNumber.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.labelNumber];
}

- (void)addButtons {
    [self.contentView addSubview:self.checkBtn];
    [self.contentView addSubview:self.rotateLeftBtn];
    [self.contentView addSubview:self.rotateRightBtn];
    [self.contentView addSubview:self.deleteBtn];
    [self.contentView addSubview:self.insertPrevBtn];
    [self.contentView addSubview:self.insertNextBtn];

    [self.rotateRightBtn addTarget:self action:@selector(onRotateRightBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateLeftBtn addTarget:self action:@selector(onRotateLeftBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.deleteBtn addTarget:self action:@selector(onDeleteBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.insertPrevBtn addTarget:self action:@selector(onInsertPrevBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.insertNextBtn addTarget:self action:@selector(onInsertNextBtnClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)updateButtonFramesWithThumbnailWidth:(CGFloat)thumbnailWidth {
    CGRect frame = self.checkBtn.frame;
    frame.origin.x = floorf((float) (self.bounds.size.width - thumbnailWidth) / 2);
    self.checkBtn.frame = frame;

    frame.origin.x = self.checkBtn.frame.origin.x + thumbnailWidth / 2 - 30;
    frame.origin.y = self.bounds.size.height / 2 - 13;
    self.insertPrevBtn.frame = frame;

    frame.origin.x = self.checkBtn.frame.origin.x + thumbnailWidth / 2 + 4;
    self.insertNextBtn.frame = frame;

    frame.origin.x = self.checkBtn.frame.origin.x + thumbnailWidth / 2 - 46;
    self.rotateLeftBtn.frame = frame;

    frame.origin.x = self.checkBtn.frame.origin.x + thumbnailWidth / 2 - 13;
    self.rotateRightBtn.frame = frame;

    frame.origin.x = self.checkBtn.frame.origin.x + thumbnailWidth / 2 + 20;
    self.deleteBtn.frame = frame;
}

#pragma mark - Properties getter/setter

- (UIButton *)checkBtn {
    if (_checkBtn == nil) {
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(0, 0, 26, 26);
        button.alpha = 0.0;
        button.userInteractionEnabled = NO;
        [button setImage:[UIImage imageNamed:@"common_redio_blank"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"common_redio_selected"] forState:UIControlStateSelected];
        _checkBtn = button;
    }
    return _checkBtn;
}

- (UIButton *)rotateLeftBtn {
    if (_rotateLeftBtn == nil) {
        UIButton *button = [[UIButton alloc] init];
        [button setImage:[UIImage imageNamed:@"thumb_rotate_left"] forState:UIControlStateNormal];
        button.hidden = YES;
        _rotateLeftBtn = button;
    }
    return _rotateLeftBtn;
}

- (UIButton *)rotateRightBtn {
    if (_rotateRightBtn == nil) {
        UIButton *button = [[UIButton alloc] init];
        [button setImage:[UIImage imageNamed:@"thumb_rotate_right"] forState:UIControlStateNormal];
        button.hidden = YES;
        _rotateRightBtn = button;
    }
    return _rotateRightBtn;
}

- (UIButton *)deleteBtn {
    if (_deleteBtn == nil) {
        UIButton *button = [[UIButton alloc] init];
        [button setImage:[UIImage imageNamed:@"thumb_delete2"] forState:UIControlStateNormal];
        button.hidden = YES;
        _deleteBtn = button;
    }
    return _deleteBtn;
}

- (UIButton *)insertPrevBtn {
    if (_insertPrevBtn == nil) {
        UIButton *button = [[UIButton alloc] init];
        [button setImage:[UIImage imageNamed:@"thumb_insert_prev"] forState:UIControlStateNormal];
        button.hidden = YES;
        _insertPrevBtn = button;
    }
    return _insertPrevBtn;
}

- (UIButton *)insertNextBtn {
    if (_insertNextBtn == nil) {
        UIButton *button = [[UIButton alloc] init];
        [button setImage:[UIImage imageNamed:@"thumb_insert_next"] forState:UIControlStateNormal];
        button.hidden = YES;
        _insertNextBtn = button;
    }
    return _insertNextBtn;
}

- (void)showLeftBtns {
    self.rotateLeftBtn.hidden = NO;
    self.rotateRightBtn.hidden = NO;
    self.deleteBtn.hidden = NO;
    [self dismissRightBtns];
    [self.delegate didShowEditButtonsInCell:self];
}

- (void)showRightBtns {
    self.insertNextBtn.hidden = NO;
    self.insertPrevBtn.hidden = NO;
    [self dismissLeftBtns];
    [self.delegate didShowEditButtonsInCell:self];
}

- (void)dismissLeftBtns {
    self.rotateLeftBtn.hidden = YES;
    self.rotateRightBtn.hidden = YES;
    self.deleteBtn.hidden = YES;
}

- (void)dismissRightBtns {
    self.insertNextBtn.hidden = YES;
    self.insertPrevBtn.hidden = YES;
}

- (void)setIsEditing:(BOOL)isEditing {
    [self setIsEditing:isEditing animated:NO];
}

- (void)setIsEditing:(BOOL)isEditing animated:(BOOL)animated {
    if (_isEditing == isEditing) {
        return;
    }
    _isEditing = isEditing;
    if (animated) {
        [UIView animateWithDuration:0.3
            delay:0
            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
            animations:^{
                self.checkBtn.alpha = isEditing && (!self.alwaysHideCheckBox ? 1 : 0);
            }
            completion:^(BOOL finished) {
                self.checkBtn.alpha = isEditing && (!self.alwaysHideCheckBox ? 1 : 0);
                [self.checkBtn.superview bringSubviewToFront:self.checkBtn];
            }];
    } else {
        self.checkBtn.alpha = isEditing && (!self.alwaysHideCheckBox ? 1 : 0);
    }

    self.swipeLeftGesture.enabled = isEditing;
    self.swipeRightGesture.enabled = isEditing;

    if (!isEditing) {
        [self dismissLeftBtns];
        [self dismissRightBtns];
        self.checkBtn.selected = NO;
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];

    [self updateVisualAppearanceForSelected:selected];
}

#pragma mark - public methods

- (void)prepareForReuse {
    self.delegate = nil;
    self.tag = 0;
    self.isEditing = NO;
    self.alwaysHideCheckBox = NO;
    self.alpha = 1.0f;
    self.contentView.alpha = 1.0f;
    self.backgroundColor = [UIColor clearColor];
    self.imageView.image = nil;
    [self.contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj isKindOfClass:[UIActivityIndicatorView class]]) {
            [obj removeFromSuperview];
            *stop = YES;
        }
    }];
}

#pragma mark - button click events

- (void)onRotateRightBtnClicked {
    if (self.delegate) {
        [self.delegate cell:self rotateClockwise:YES];
    }
}

- (void)onRotateLeftBtnClicked {
    if (self.delegate) {
        [self.delegate cell:self rotateClockwise:NO];
    }
}

- (void)onDeleteBtnClicked {
    if (self.delegate) {
        [self.delegate deleteCell:self];
    }
}

- (void)onInsertPrevBtnClicked {
    if (self.delegate) {
        [self.delegate cell:self insertBeforeOrAfter:YES];
    }
}

- (void)onInsertNextBtnClicked {
    if (self.delegate) {
        [self.delegate cell:self insertBeforeOrAfter:NO];
    }
}

#pragma mark - private methods

- (void)updateVisualAppearanceForSelected:(BOOL)selected {
    if (self.checkBtn.selected != selected) {
        self.checkBtn.selected = selected;
    }
    [self dismissLeftBtns];
    [self dismissRightBtns];
}

#pragma mark - Swipe Gesture

- (void)handleSwipeRightGesture:(UISwipeGestureRecognizer *)swipeGesture {
    [self showLeftBtns];
}

- (void)handleSwipeLeftGesture:(UISwipeGestureRecognizer *)swipeGesture {
    [self showRightBtns];
}

@end
