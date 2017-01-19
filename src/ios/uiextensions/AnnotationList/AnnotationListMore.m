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
#import "AnnotationListMore.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "AnnotationListCell.h"
#import "AnnotationListViewController.h"
#import "ReplyTableViewController.h"
#import "ReadingBookmarkViewController.h"
#import "ReadingBookmarkListCell.h"
#import "MASConstraintMaker.h"
#import "View+MASAdditions.h"
#import "ColorUtility.h"

@interface AnnotationListMore() <UIGestureRecognizerDelegate>
@property (nonatomic, assign)CGRect annotDetailBtRect;
@property (nonatomic, assign)CGRect replyBtRect;
@property (nonatomic, assign)CGRect bookmarkDetailBtRect;
@property (nonatomic, assign)CGRect bookmarkDetaileBtRect;

@end

@implementation AnnotationListMore {
    UIView* _superView;
}

- (UIView *)gestureView{
    if (!_gestureView) {
        self.gestureView = [[UIView alloc] init];
    }
    return _gestureView;
}

- (id)initWithFrame:(CGRect)frame superView:(UIView*)superView delegate:(id)delegate isBookMark:(BOOL)enable isMenu:(BOOL)isMenu
{
    if ([super initWithFrame:frame])
    {
        self.delegate = delegate;
        _superView = superView;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGuest:)];
        tapGesture.delegate = self;
        self.userInteractionEnabled = YES;
        if (isMenu) {
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
            {
                self.gestureView.frame = CGRectMake(frame.origin.x, 0, DEVICE_iPHONE ? SCREENHEIGHT : frame.size.height, SCREENWIDTH);
            }else{
                self.gestureView.frame = CGRectMake(frame.origin.x, 0, DEVICE_iPHONE ? SCREENWIDTH : frame.size.width, SCREENHEIGHT);
            }
        }
        else
        {
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                self.gestureView.frame = CGRectMake(frame.origin.x, 64, DEVICE_iPHONE ? SCREENHEIGHT : 300, SCREENWIDTH);
            }else{
                self.gestureView.frame = CGRectMake(frame.origin.x, 64, DEVICE_iPHONE ? SCREENWIDTH : 300, SCREENHEIGHT);
            }
        }
        [self.gestureView addGestureRecognizer:tapGesture];
        [_superView addSubview:self.gestureView];

        if (enable)
        {
            
            self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 100, 0, 100, 50)];
            self.bottomView.backgroundColor = [UIColor colorWithRed:231.f/255.f green:231.f/255.f blue:231.f/255.f alpha:1];
            self.renameButton = [AnnotationListMore createItemWithImageAndTitle:NSLocalizedString(@"kRename", NULL)
                                                                    imageNormal:[UIImage imageNamed:@"document_edit_small_rename"]
                                                                  imageSelected:[UIImage imageNamed:@"document_edit_small_rename"]                                                         imageDisable:[UIImage imageNamed:@"document_edit_small_rename"]];
            
            self.deleteButton = [AnnotationListMore createItemWithImageAndTitle:NSLocalizedString(@"kDelete", NULL)
                                                                    imageNormal:[UIImage imageNamed:@"panel_more_delete"]
                                                                  imageSelected:[UIImage imageNamed:@"panel_more_delete"]                                                         imageDisable:[UIImage imageNamed:@"panel_more_delete"]];
            
            self.renameButton.frame = CGRectMake(20, 10, self.renameButton.frame.size.width + 10, self.renameButton.frame.size.height );
            self.renameButton.center = CGPointMake(frame.size.width - 100 + 25, 25);
            self.deleteButton.frame = CGRectMake(90, 10, self.deleteButton.frame.size.width + 10, self.deleteButton.frame.size.height );
            self.deleteButton.center = CGPointMake(frame.size.width - 100 + 75, 25);
            
            self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            self.renameButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            self.deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            
            [self addSubview:self.bottomView];
            [self addSubview:self.renameButton];
            [self addSubview:self.deleteButton];
            
        }
        else if (isMenu)
        {
            
            self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 100, 0, 100, 68)];
            self.bottomView.backgroundColor = [UIColor colorWithRed:231.f/255.f green:231.f/255.f blue:231.f/255.f alpha:1];
            self.replyButton = [AnnotationListMore createItemWithImageAndTitle:NSLocalizedString(@"kReply", NULL)
                                                                   imageNormal:[UIImage imageNamed:@"panel_more_reply"]
                                                                 imageSelected:[UIImage imageNamed:@"panel_more_reply"]                                                         imageDisable:[UIImage imageNamed:@"panel_more_reply"]];
            
            self.deleteButton = [AnnotationListMore createItemWithImageAndTitle:NSLocalizedString(@"kDelete", NULL)
                                                                    imageNormal:[UIImage imageNamed:@"panel_more_delete"]
                                                                  imageSelected:[UIImage imageNamed:@"panel_more_delete"]                                                         imageDisable:[UIImage imageNamed:@"panel_more_delete"]];
            
            self.replyButton.frame = CGRectMake(20, 10, self.replyButton.frame.size.width + 20, self.replyButton.frame.size.height + 20);
            self.replyButton.center = CGPointMake(frame.size.width - 100 + 25, 34);
            self.deleteButton.frame = CGRectMake(90, 10, self.deleteButton.frame.size.width + 20, self.deleteButton.frame.size.height + 20);
            self.deleteButton.center = CGPointMake(frame.size.width - 100 + 75, 34);
            
            self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            self.replyButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            self.deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            
            [self addSubview:self.bottomView];
            [self addSubview:self.replyButton];
            [self addSubview:self.deleteButton];
            [self.deleteButton addTarget:self.delegate action:@selector(deleteAnnotation) forControlEvents:UIControlEventTouchUpInside];
            [self.replyButton addTarget:self.delegate action:@selector(replyToAnnotation) forControlEvents:UIControlEventTouchUpInside];
        }
        else
        {
            
            self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 150, 0, 150, 68)];
            self.bottomView.backgroundColor = [UIColor colorWithRed:231.f/255.f green:231.f/255.f blue:231.f/255.f alpha:1];
            self.replyButton = [AnnotationListMore createItemWithImageAndTitle:NSLocalizedString(@"kReply", NULL)
                                                                   imageNormal:[UIImage imageNamed:@"panel_more_reply"]
                                                                 imageSelected:[UIImage imageNamed:@"panel_more_reply"]                                                         imageDisable:[UIImage imageNamed:@"panel_more_reply"]];
            
            self.noteButton = [AnnotationListMore createItemWithImageAndTitle:NSLocalizedString(@"kIconNote", NULL)
                                                                  imageNormal:[UIImage imageNamed:@"panel_more_note"]
                                                                imageSelected:[UIImage imageNamed:@"panel_more_note"]                                                         imageDisable:[UIImage imageNamed:@"panel_more_note"]];
            
            self.deleteButton = [AnnotationListMore createItemWithImageAndTitle:NSLocalizedString(@"kDelete", NULL)
                                                                    imageNormal:[UIImage imageNamed:@"panel_more_delete"]
                                                                  imageSelected:[UIImage imageNamed:@"panel_more_delete"]                                                         imageDisable:[UIImage imageNamed:@"panel_more_delete"]];
            
            self.replyButton.frame = CGRectMake(20, 10, self.replyButton.frame.size.width + 20, self.replyButton.frame.size.height + 20);
            self.replyButton.center = CGPointMake(frame.size.width - 150 + 25, 34);
            self.noteButton.frame = CGRectMake(60, 10, self.noteButton.frame.size.width + 20, self.noteButton.frame.size.height + 20);
            self.noteButton.center = CGPointMake(frame.size.width - 150 + 75, 34);
            self.deleteButton.frame = CGRectMake(90, 10, self.deleteButton.frame.size.width + 20, self.deleteButton.frame.size.height + 20);
            self.deleteButton.center = CGPointMake(frame.size.width - 150 + 125, 34);
            
            self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            self.replyButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            self.noteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            self.deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            
            [self addSubview:self.bottomView];
            [self addSubview:self.replyButton];
            [self addSubview:self.noteButton];
            [self addSubview:self.deleteButton];
            [self.deleteButton addTarget:self.delegate action:@selector(deleteAnnotation) forControlEvents:UIControlEventTouchUpInside];
            [self.replyButton addTarget:self.delegate action:@selector(replyToAnnotation) forControlEvents:UIControlEventTouchUpInside];
            [self.noteButton addTarget:self.delegate action:@selector(addNoteToAnnotation) forControlEvents:UIControlEventTouchUpInside];
            
        }
    }
    return self;
}

+ (UIButton*)createItemWithImageAndTitle:(NSString*)title
                             imageNormal:(UIImage*)imageNormal
                           imageSelected:(UIImage*)imageSelected
                            imageDisable:(UIImage*)imageDisabled
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    CGSize titleSize  = [Utility getTextSize:title fontSize:9.0f maxSize:CGSizeMake(200, 100)];
    
    float width = imageNormal.size.width;
    float height = imageNormal.size.height;
    button.contentMode = UIViewContentModeScaleToFill;
    [button setImage:imageNormal forState:UIControlStateNormal];
    [button setImage:[Utility imageByApplyingAlpha:imageNormal alpha:0.5] forState:UIControlStateHighlighted];
    [button setImage:[Utility imageByApplyingAlpha:imageNormal alpha:0.5] forState:UIControlStateSelected];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRGBHex:0x5c5c5c] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor colorWithRGBHex:0x5c5c5c] forState:UIControlStateSelected];
    button.titleLabel.font = [UIFont systemFontOfSize:9];
    
    button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, -height*1.5, 0);
    button.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width);
    button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width + 2 : width  ,  titleSize.height + height);
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    return button;
}

- (void)renameBookmark
{
    [self tapGuest:nil];
    ReadingBookmarkListCell *viewList = (ReadingBookmarkListCell *)self.delegate;
    ReadingBookmarkViewController *bookmarkCtr = (ReadingBookmarkViewController *)viewList.delegate;
    [bookmarkCtr renameBookmarkWithIndex:self.indexPath.row];
}

- (void)deleteBookmark
{
    [self tapGuest:nil];
    ReadingBookmarkListCell *viewList = (ReadingBookmarkListCell *)self.delegate;
    ReadingBookmarkViewController *bookmarkCtr = (ReadingBookmarkViewController *)viewList.delegate;
    [bookmarkCtr deleteBookmarkWithIndex:self.indexPath.row];
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([AnnotationListCell class] && self.delegate && [self.delegate isKindOfClass:[AnnotationListCell class]])
    {
        AnnotationListCell *viewList = (AnnotationListCell *)self.delegate;
        if ([viewList.delegate isKindOfClass:[ReplyTableViewController class]]) {
            ReplyTableViewController *replyCtr = (ReplyTableViewController*)viewList.delegate;
            NSArray *cellArrs = replyCtr.tableView.visibleCells;
            CGPoint point = [touch locationInView:replyCtr.view];
            CGRect replyRect = [self.replyButton.superview convertRect:self.replyButton.frame toView:replyCtr.view];
           
            CGRect deleteRect = [self.replyButton.superview convertRect:self.deleteButton.frame toView:replyCtr.view];
            
            if (CGRectContainsPoint(replyRect, point) && !self.replyButton.hidden) {
                [viewList replyToAnnotation];
                return YES;
            } 
            else if (CGRectContainsPoint(deleteRect, point))
            {
                [viewList deleteAnnotation];
                return YES;
            }
            
            for (AnnotationListCell *replyCell in cellArrs) {
                self.replyBtRect = [replyCell convertRect:replyCell.detailButton.frame toView:replyCtr.view];
                if (CGRectContainsPoint(_replyBtRect,point)) {
                    replyCtr.isShowMore = NO;
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frame = CGRectMake(self.frame.origin.x + self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
                        
                        [self.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {

                            float width;
                            float height;
                            float x;
                            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                                x = DEVICE_iPHONE ? SCREENHEIGHT : 540;
                                width = DEVICE_iPHONE ? SCREENHEIGHT : 540;
                                height = DEVICE_iPHONE ? SCREENWIDTH : 540;
                                
                            }else{
                                x = DEVICE_iPHONE? SCREENWIDTH : 540;
                                width = DEVICE_iPHONE ? SCREENWIDTH : 540;
                                height = DEVICE_iPHONE ? SCREENHEIGHT : 540;
                            }
                            make.top.mas_equalTo(0);
                            make.left.mas_equalTo(x);
                            make.width.mas_equalTo(width);
                            make.height.mas_equalTo(height);
                        }];
                    }];
                    
                    [replyCell setEditViewHiden];
                    return NO;
                    
                }
            }
        }
        else
        {
            AnnotationListViewController *annotCtr = (AnnotationListViewController *)viewList.delegate;
            CGPoint annotCtrPoint = [touch locationInView:annotCtr.view];
            NSArray *cellArrs = annotCtr.tableView.visibleCells;
            CGPoint point = [touch locationInView:_superView];
            CGRect replyRect = [self.replyButton.superview convertRect:self.replyButton.frame toView:_superView];
            CGRect noteRect = [self.replyButton.superview convertRect:self.noteButton.frame toView:_superView];
            CGRect deleteRect = [self.replyButton.superview convertRect:self.deleteButton.frame toView:_superView];
            
            if (CGRectContainsPoint(replyRect, point) && !self.replyButton.hidden) {
                [viewList replyToAnnotation];
                return NO;
            } else if (CGRectContainsPoint(noteRect, point) && !self.noteButton.hidden)
            {
                [viewList addNoteToAnnotation];
                return NO;
            }
            else if (CGRectContainsPoint(deleteRect, point))
            {
                [viewList deleteAnnotation];
                return NO;
            }
            
            for (AnnotationListCell *annotCell in cellArrs) {
                self.annotDetailBtRect = [annotCell convertRect:annotCell.detailButton.frame toView:annotCtr.view];
                if (CGRectContainsPoint(_annotDetailBtRect, annotCtrPoint))
                {
                    
                    annotCtr.isShowMore = NO;
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frame = CGRectMake(self.frame.origin.x + self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
                        
                        [self.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
                            make.left.equalTo(self.gestureView.superview.mas_right).offset(0);
                            make.top.equalTo(self.gestureView.superview.mas_top).offset(0);
                            make.bottom.equalTo(self.gestureView.superview.mas_bottom).offset(0);
                            float width;
                            
                            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                                width = DEVICE_iPHONE ? SCREENHEIGHT : 300;
                            }else{
                                width = DEVICE_iPHONE ? SCREENWIDTH : 300;
                                
                            }
                            make.width.mas_equalTo(width);
                        }];
                    }];
                    
                    [annotCell setEditViewHiden];
                    return NO;
                }
            }
        }
    }
    else if ( self.delegate && [self.delegate isKindOfClass:[ReadingBookmarkListCell class]])
    {
        ReadingBookmarkListCell *viewList = (ReadingBookmarkListCell *)self.delegate;
        ReadingBookmarkViewController *bookmarkCtr = (ReadingBookmarkViewController *)viewList.delegate;
        CGPoint bookmarkCtrPoint = [touch locationInView:bookmarkCtr.view];
        NSMutableArray *cellArrs = bookmarkCtr.tableView.visibleCells;
        CGPoint point = [touch locationInView:_superView];
        CGRect renameRect = [self.renameButton.superview convertRect:self.renameButton.frame toView:_superView];
        CGRect deleteRect = [self.deleteButton.superview convertRect:self.deleteButton.frame toView:_superView];
        if (CGRectContainsPoint(renameRect, point)) {
            [self renameBookmark];
            return NO;
        }
        else if (CGRectContainsPoint(deleteRect, point))
        {
            [self deleteBookmark];
            return NO;
        }
        
        for (ReadingBookmarkListCell *bookmarkCell in cellArrs) {
            self.bookmarkDetaileBtRect = [bookmarkCell convertRect:bookmarkCell.detailButton.frame toView:bookmarkCtr.view];
            if (CGRectContainsPoint(_bookmarkDetaileBtRect, bookmarkCtrPoint))
            {
                
                bookmarkCtr.isShowMore = NO;
                [UIView animateWithDuration:0.3 animations:^{
                    self.frame = CGRectMake(self.frame.origin.x + self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
                    
                    [self.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.left.equalTo(self.gestureView.superview.mas_right).offset(0);
                        make.top.equalTo(self.gestureView.superview.mas_top).offset(0);
                        make.bottom.equalTo(self.gestureView.superview.mas_bottom).offset(0);
                        float width;
                        
                        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                            width = DEVICE_iPHONE ? SCREENHEIGHT : 300;
                        }else{
                            width = DEVICE_iPHONE ? SCREENWIDTH : 300;
                            
                        }
                        make.width.mas_equalTo(width);
                    }];
                }];
                
                [bookmarkCell setEditViewHiden:bookmarkCell.detailButton];
                return NO;
            }
            
        }
    }
    return YES;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

- (void)tapGuest:(UIGestureRecognizer *)guest
{
    AnnotationListCell *annotationCell = (AnnotationListCell *)self.delegate;
    if ([annotationCell.delegate isKindOfClass:[AnnotationListViewController class]])
    {
        AnnotationListViewController *viewList = (AnnotationListViewController *)annotationCell.delegate;
        if(!viewList.isShowMore)
            return;
        viewList.isShowMore = NO;
    }else if ([annotationCell.delegate isKindOfClass:[ReplyTableViewController class]])
    {
        ReplyTableViewController *replyCtr = (ReplyTableViewController *)annotationCell.delegate;
        if(!replyCtr.isShowMore)
            return;
        replyCtr.isShowMore = NO;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(self.frame.origin.x + self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
        
        [self.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.gestureView.superview.mas_right).offset(0);
            make.top.equalTo(self.gestureView.superview.mas_top).offset(0);
            make.bottom.equalTo(self.gestureView.superview.mas_bottom).offset(0);
            float width;
            
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                width = DEVICE_iPHONE ? SCREENHEIGHT : 300;
            }else{
                width = DEVICE_iPHONE ? SCREENWIDTH : 300;
                
            }
            make.width.mas_equalTo(width);
        }];
    }];
}

- (void)setCellViewHidden:(BOOL)hidden isMenu:(BOOL)menu
{
    if (hidden)
    {
        if (menu) {
            [UIView animateWithDuration:0.3 animations:^{
                self.frame = CGRectMake(self.frame.origin.x + self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
                if ([OS_VERSION substringToIndex:1].integerValue == 7) {
                    self.gestureView.frame = CGRectMake(0, DEVICE_iPHONE ? SCREENHEIGHT : 540, DEVICE_iPHONE ? SCREENWIDTH : 540, DEVICE_iPHONE ? SCREENHEIGHT : 540);
                } else {
                    [self.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
                        float width;
                        float height;
                        float x;
                        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                            x = DEVICE_iPHONE ? SCREENHEIGHT : 540;
                            width = DEVICE_iPHONE ? SCREENHEIGHT : 540;
                            height = DEVICE_iPHONE ? SCREENWIDTH : 540;
                            
                        }else{
                            x = DEVICE_iPHONE? SCREENWIDTH : 540;
                            width = DEVICE_iPHONE ? SCREENWIDTH : 540;
                            height = DEVICE_iPHONE ? SCREENHEIGHT : 540;
                        }
                        make.top.mas_equalTo(0);
                        make.left.mas_equalTo(x);
                        make.width.mas_equalTo(width);
                        make.height.mas_equalTo(height);
                    }];
                }
            }];
            
        }else{
        [UIView animateWithDuration:0.3 animations:^{
            self.frame = CGRectMake(self.frame.origin.x + self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
            
            [self.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.gestureView.superview.mas_right).offset(0);
                make.top.equalTo(self.gestureView.superview.mas_top).offset(64);
                make.bottom.equalTo(self.gestureView.superview.mas_bottom).offset(0);
                float width;
                
                if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                    width = DEVICE_iPHONE ? SCREENHEIGHT : 300;
                }else{
                    width = DEVICE_iPHONE ? SCREENWIDTH : 300;
                    
                }
                make.width.mas_equalTo(width);
            }];
        }];
        }
    } else
    {
        if (menu) {
            [UIView animateWithDuration:0.3 animations:^{
                self.frame = CGRectMake(self.frame.origin.x - self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
                if ([OS_VERSION substringToIndex:1].integerValue == 7) {
                    self.gestureView.frame = CGRectMake(0, 0, DEVICE_iPHONE ? SCREENWIDTH : 540, DEVICE_iPHONE ? SCREENHEIGHT : 540);
                } else {
                    [self.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
                        float width;
                        float height;
                        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                            width = DEVICE_iPHONE ? SCREENHEIGHT : 540;
                            height = DEVICE_iPHONE ? SCREENWIDTH : 540;
                            
                        }else{
                            width = DEVICE_iPHONE ? SCREENWIDTH : 540;
                            height = DEVICE_iPHONE ? SCREENHEIGHT : 540;
                        }
                        make.top.mas_equalTo(0);
                        make.left.mas_equalTo(0);
                        make.width.mas_equalTo(width);
                        make.height.mas_equalTo(height);
                    }];
                }
            }];
        }else{
        
        [UIView animateWithDuration:0.3 animations:^{
            self.frame = CGRectMake(self.frame.origin.x - self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
            
            [self.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.gestureView.superview.mas_left).offset(0);
                make.top.equalTo(self.gestureView.superview.mas_top).offset(64);
                make.bottom.equalTo(self.gestureView.superview.mas_bottom).offset(0);
                float width;
                
                if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                    width = DEVICE_iPHONE ? SCREENHEIGHT : 300;
                }else{
                    width = DEVICE_iPHONE ? SCREENWIDTH : 300;
                    
                }
                make.width.mas_equalTo(width);
            }];
        }];
        }
    }
}

@end
