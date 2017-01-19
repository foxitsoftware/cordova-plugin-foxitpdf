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
#import "AnnotationListCell.h"
#import "AnnotationListViewController.h"
#import "ReplyTableViewController.h"
#import "AnnotationListMore.h"
#import "MASConstraintMaker.h"
#import "View+MASAdditions.h"
#import "ColorUtility.h"

@implementation AnnotationListCell

// super view is for annotationListMore's guesture recognizer
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier isMenu:(BOOL)isMenu superView:superView typeOf:(int)annotType {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.isInputText = NO;
        self.currentlevel=1;
        AnnotationButton* buttonViewLevel = [AnnotationButton buttonWithType:UIButtonTypeCustom];
        buttonViewLevel.frame = CELL_ANNOTATIONBUTTON;
        buttonViewLevel.tag = 100;
        [buttonViewLevel setImage:[UIImage imageNamed:@"panel_annotation_close"] forState:UIControlStateSelected];
        [buttonViewLevel setImage:[UIImage imageNamed:@"panel_annotation_open"] forState:UIControlStateNormal];
        [self.contentView addSubview:buttonViewLevel];
        
        
        UIImageView* imageViewAnnotation = [[[UIImageView alloc] initWithFrame:CELL_ANNOTATIONIMAGEVIEW] autorelease];
        imageViewAnnotation.tag=99;
        [self.contentView addSubview:imageViewAnnotation];
        
        UIImageView* annoupdatetip=[[[UIImageView alloc]initWithFrame:CELL_ANNOTATIONUPDATEVIEW]autorelease];
        annoupdatetip.tag=108;
        annoupdatetip.image=[UIImage imageNamed:@"annoupdatetip"];
        [self.contentView addSubview:annoupdatetip];
        
        UIImageView* annouprepltip=[[[UIImageView alloc]initWithFrame:CELL_ANNOTATIONREPLYTIP]autorelease];
        annouprepltip.tag=109;
        annouprepltip.image=[UIImage imageNamed:@"panel_annotation_reply"];
        [self.contentView addSubview:annouprepltip];
        
        UILabel* labelAuthor = [[[UILabel alloc] init] autorelease];
        labelAuthor.tag=102;
        [labelAuthor setTextColor:[UIColor blackColor]];
        [labelAuthor setFont:[UIFont systemFontOfSize:13]];
        [labelAuthor setTextAlignment:NSTextAlignmentLeft];
        labelAuthor.lineBreakMode=NSLineBreakByTruncatingTail;
        labelAuthor.frame =CELL_ANNOTATIONAUTHOR;
        labelAuthor.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:labelAuthor];
        
        
        UILabel* labelDate = [[[UILabel alloc] init] autorelease];
        labelDate.tag=103;
        [labelDate setTextColor:[UIColor darkGrayColor]];
        [labelDate setFont:[UIFont systemFontOfSize:8]];
        labelDate.textAlignment = NSTextAlignmentLeft;
        labelDate.frame = CELL_ANNOTATIONDATE;
        labelDate.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:labelDate];
        
        
        UILabel* labelContents = [[[UILabel alloc] init] autorelease];
        labelContents.lineBreakMode=NSLineBreakByWordWrapping;
        labelContents.textAlignment=NSTextAlignmentLeft;
        labelContents.tag=104;
        if (isMenu) {
            labelContents.frame = CELL_REPLYCONTENTS ;
        }
        else
        {
            labelContents.frame = CELL_ANNOTATIONCONTENTS;
        }
        
        labelContents.backgroundColor = [UIColor clearColor];
        [labelContents setTextColor:[UIColor darkGrayColor]];
        [labelContents setFont:[UIFont systemFontOfSize:13]];
        [self.contentView addSubview:labelContents];
        
        UITextView* edititextview=[[[UITextView alloc]init] autorelease];
        edititextview.autoresizingMask = UIViewAutoresizingNone;
        edititextview.hidden=YES;
        edititextview.backgroundColor = [UIColor clearColor];
        if (OS_ISVERSION7) {
            edititextview.textContainerInset=UIEdgeInsetsMake(0, 10, 0, 0);
        }else{
            edititextview.contentInset=UIEdgeInsetsMake(-5, 0, 0, 0);
        }

        edititextview.returnKeyType=UIReturnKeyDefault;
        edititextview.font=[UIFont systemFontOfSize:13];
        edititextview.textColor=[UIColor darkGrayColor];
        [edititextview setTextAlignment:NSTextAlignmentLeft];
        edititextview.tag=107;
        if (isMenu) {
            edititextview.frame = CGRectMake(5, 69, DEVICE_iPHONE? SCREENWIDTH - 20 : 520, 20);
        }
        else
        {
            edititextview.frame=CELL_ANNOTATIONEDITVIEW;
        }
        [self.contentView addSubview:edititextview];
        
        self.detailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _detailButton.tag = 200;
        [_detailButton setImage:[UIImage imageNamed:@"document_cellmore_more"] forState:UIControlStateNormal];
        [_detailButton addTarget:self action:@selector(setEditViewHiden) forControlEvents:UIControlEventTouchUpInside];
        _detailButton.frame = CGRectMake(self.bounds.size.width - 50, 0, 50, 50);
        _detailButton.center = CGPointMake(_detailButton.center.x, 34);
        _detailButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        [self.contentView addSubview:_detailButton];
        UIView* superviewOfAnnotListMore = superView;
        if (isMenu) {
            if ((DEVICE_iPHONE && ([UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationPortraitUpsideDown||[UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationPortrait)) || (DEVICE_iPHONE && ((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) < (375 * 667)) && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)))
            {
                UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
                doneView.backgroundColor = [UIColor colorWithRGBHex:0xfffbdb];
                UIButton *doneBT = [UIButton buttonWithType:UIButtonTypeCustom];
                [doneBT setBackgroundImage:[UIImage imageNamed:@"common_keyboard_done"] forState:UIControlStateNormal];
                [doneBT addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
                [doneView addSubview:doneBT];
                [doneBT mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(doneView.mas_right).offset(0);
                    make.top.equalTo(doneView.mas_top).offset(0);
                    make.size.mas_equalTo(CGSizeMake(40, 40));
                }];
                edititextview.inputAccessoryView = doneView;
            }
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _belowView = [[AnnotationListMore alloc] initWithFrame:CGRectMake(DEVICE_iPHONE ? SCREENHEIGHT : 540, 0, DEVICE_iPHONE ? SCREENHEIGHT : 540, 68) superView:superviewOfAnnotListMore delegate:self isBookMark:NO isMenu:isMenu];
                
            }else{
                _belowView = [[AnnotationListMore alloc] initWithFrame:CGRectMake(DEVICE_iPHONE ? SCREENWIDTH : 540, 0, DEVICE_iPHONE ? SCREENWIDTH : 540, 68) superView:superviewOfAnnotListMore delegate:self isBookMark:NO isMenu:isMenu];
            }
            if (SCREENHEIGHT *SCREENWIDTH == 414 * 736) {
                 _belowView = [[AnnotationListMore alloc] initWithFrame:CGRectMake(414, 0, 414, 68) superView:superviewOfAnnotListMore delegate:self isBookMark:NO isMenu:isMenu];
            }
        }
        else
        {
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                 _belowView = [[AnnotationListMore alloc] initWithFrame:CGRectMake(DEVICE_iPHONE ? SCREENHEIGHT : 300, 0, DEVICE_iPHONE ? SCREENHEIGHT : 300, 68) superView:superviewOfAnnotListMore delegate:self isBookMark:NO isMenu:isMenu];
            }else{
                 _belowView = [[AnnotationListMore alloc] initWithFrame:CGRectMake(DEVICE_iPHONE ? SCREENWIDTH : 300, 0, DEVICE_iPHONE ? SCREENWIDTH : 300, 68) superView:superviewOfAnnotListMore delegate:self isBookMark:NO isMenu:isMenu];
            }
           
        }

        [self.contentView addSubview:_belowView];
    }
    
    return self;
}
- (void)dismissKeyboard{
    if (self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(dismissKeyboard)]) {
        [self.cellDelegate dismissKeyboard];
    }
}
- (void)setEditViewHiden
{
    if ([self.delegate isKindOfClass:[ReplyTableViewController class]]) {
        ReplyTableViewController *viewList = (ReplyTableViewController *)self.delegate;
        if (viewList.isShowMore) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect gestureRect = _belowView.frame;
                gestureRect.origin.x = gestureRect.origin.x + _belowView.gestureView.frame.size.width;
                _belowView.frame = gestureRect;
            }];
        }
        viewList.isShowMore = YES;
        [_belowView setCellViewHidden:NO  isMenu:YES];
        if (viewList.isShowMore) {
            viewList.moreIndexPath = self.indexPath;
        }
        else
        {
            viewList.moreIndexPath = nil;
        }
    }
    else if ([self.delegate isKindOfClass:[AnnotationListViewController class]])
    {
        AnnotationListViewController *viewList = (AnnotationListViewController *)self.delegate;
        if (viewList.isShowMore) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect gestureRect = _belowView.frame;
                gestureRect.origin.x = gestureRect.origin.x + _belowView.gestureView.frame.size.width;
                _belowView.frame = gestureRect;
            }];
            
        }
        
        viewList.isShowMore = YES;
        [_belowView setCellViewHidden:NO isMenu:NO];
        if (viewList.isShowMore) {
            viewList.moreIndexPath = self.indexPath;
        }
        else
        {
            viewList.moreIndexPath = nil;
        }
    }
}

- (void)deleteAnnotation
{
    if ([self.delegate isKindOfClass:[ReplyTableViewController class]]) {
        ReplyTableViewController *viewCon = (ReplyTableViewController *)self.delegate;
        [viewCon deleteAnnotation:self.item];
        [_belowView setCellViewHidden:YES isMenu:YES];
        viewCon.isShowMore = NO;
    }
    else if ([self.delegate isKindOfClass:[AnnotationListViewController class]])
    {
        AnnotationListViewController *viewCon = (AnnotationListViewController *)self.delegate;
        [viewCon deleteAnnotation:self.item];
        [_belowView setCellViewHidden:YES isMenu:NO];
        viewCon.isShowMore = NO;
    }         
}

- (void)replyToAnnotation
{
   if ([self.delegate isKindOfClass:[ReplyTableViewController class]]) {
        ReplyTableViewController *viewCon = (ReplyTableViewController *)self.delegate;
        [viewCon replyToAnnotation:self.item];
        [_belowView setCellViewHidden:YES isMenu:YES];
        viewCon.isShowMore = NO;
    }
    else if ([self.delegate isKindOfClass:[AnnotationListViewController class]])
    {
        AnnotationListViewController *viewCon = (AnnotationListViewController *)self.delegate;
        [viewCon replyToAnnotation:self.item];
        [_belowView setCellViewHidden:YES isMenu:NO];
        viewCon.isShowMore = NO;
    }
}

- (void)addNoteToAnnotation
{
    if ([self.delegate isKindOfClass:[AnnotationListViewController class]])
    {
        AnnotationListViewController *viewCon = (AnnotationListViewController *)self.delegate;
        [viewCon addNoteToAnnotation:self.item withIndexPath:self.indexPath];
        [_belowView setCellViewHidden:YES isMenu:NO];
        viewCon.isShowMore = NO;
    }
    
}

@end
