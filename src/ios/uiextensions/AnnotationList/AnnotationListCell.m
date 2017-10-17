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

#import "AnnotationListCell.h"
#import "AnnotationListMore.h"
#import "AnnotationListViewController.h"
#import "AttachmentViewController.h"
#import "ColorUtility.h"
#import "MASConstraintMaker.h"
#import "ReplyTableViewController.h"
#import "View+MASAdditions.h"
#import <UIKit/UIKit.h>

@interface AnnotationListCell () <AnnotationListMoreDelegate>

@property (nonatomic, assign) BOOL isMenu;

@end

@implementation AnnotationListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier isMenu:(BOOL)isMenu {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.isInputText = NO;
        self.currentlevel = 1;
        self.item = nil;
        self.cellDelegate = nil;
        self.isMenu = isMenu;
        AnnotationButton *buttonViewLevel = [AnnotationButton buttonWithType:UIButtonTypeCustom];
        buttonViewLevel.frame = CELL_ANNOTATIONBUTTON;
        buttonViewLevel.tag = 100;
        [buttonViewLevel setImage:[UIImage imageNamed:@"panel_annotation_close"] forState:UIControlStateSelected];
        [buttonViewLevel setImage:[UIImage imageNamed:@"panel_annotation_open"] forState:UIControlStateNormal];
        [self.contentView addSubview:buttonViewLevel];

        UIImageView *imageViewAnnotation = [[UIImageView alloc] initWithFrame:CELL_ANNOTATIONIMAGEVIEW];
        imageViewAnnotation.tag = 99;
        [self.contentView addSubview:imageViewAnnotation];

        UIImageView *annoupdatetip = [[UIImageView alloc] initWithFrame:CELL_ANNOTATIONUPDATEVIEW];
        annoupdatetip.tag = 108;
        annoupdatetip.image = [UIImage imageNamed:@"annoupdatetip"];
        [self.contentView addSubview:annoupdatetip];

        UIImageView *annouprepltip = [[UIImageView alloc] initWithFrame:CELL_ANNOTATIONREPLYTIP];
        annouprepltip.tag = 109;
        annouprepltip.image = [UIImage imageNamed:@"panel_annotation_reply"];
        [self.contentView addSubview:annouprepltip];

        UILabel *labelAuthor = [[UILabel alloc] init];
        labelAuthor.tag = 102;
        [labelAuthor setTextColor:[UIColor blackColor]];
        [labelAuthor setFont:[UIFont systemFontOfSize:13]];
        [labelAuthor setTextAlignment:NSTextAlignmentLeft];
        labelAuthor.lineBreakMode = NSLineBreakByTruncatingTail;
        labelAuthor.frame = CELL_ANNOTATIONAUTHOR;
        labelAuthor.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:labelAuthor];

        UILabel *labelDate = [[UILabel alloc] init];
        labelDate.tag = 103;
        [labelDate setTextColor:[UIColor darkGrayColor]];
        [labelDate setFont:[UIFont systemFontOfSize:8]];
        labelDate.textAlignment = NSTextAlignmentLeft;
        labelDate.frame = CELL_ANNOTATIONDATE;
        labelDate.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:labelDate];

        UILabel *labelSize = [[UILabel alloc] init];
        labelSize.tag = 110;
        [labelSize setTextColor:[UIColor darkGrayColor]];
        [labelSize setFont:[UIFont systemFontOfSize:8]];
        labelSize.textAlignment = NSTextAlignmentLeft;
        labelSize.frame = CELL_ATTACHMENTSIZE;
        labelSize.backgroundColor = [UIColor clearColor];
        labelSize.hidden = YES;
        [self.contentView addSubview:labelSize];

        UILabel *labelContents = [[UILabel alloc] init];
        labelContents.lineBreakMode = NSLineBreakByWordWrapping;
        labelContents.textAlignment = NSTextAlignmentLeft;
        labelContents.tag = 104;
        if (isMenu) {
            labelContents.frame = CELL_REPLYCONTENTS;
        } else {
            labelContents.frame = CELL_ANNOTATIONCONTENTS;
        }

        labelContents.backgroundColor = [UIColor clearColor];
        [labelContents setTextColor:[UIColor darkGrayColor]];
        [labelContents setFont:[UIFont systemFontOfSize:13]];
        [self.contentView addSubview:labelContents];

        UITextView *edititextview = [[UITextView alloc] init];
        edititextview.autoresizingMask = UIViewAutoresizingNone;
        edititextview.hidden = YES;
        edititextview.backgroundColor = [UIColor clearColor];
        if (OS_ISVERSION7) {
            edititextview.textContainerInset = UIEdgeInsetsMake(0, 10, 0, 0);
        } else {
            edititextview.contentInset = UIEdgeInsetsMake(-5, 0, 0, 0);
        }

        edititextview.returnKeyType = UIReturnKeyDefault;
        edititextview.font = [UIFont systemFontOfSize:13];
        edititextview.textColor = [UIColor darkGrayColor];
        [edititextview setTextAlignment:NSTextAlignmentLeft];
        edititextview.tag = 107;
        if (isMenu) {
            edititextview.frame = CGRectMake(5, 69, DEVICE_iPHONE ? self.contentView.bounds.size.width - 20 : 520, 20);
        } else {
            edititextview.frame = CELL_ANNOTATIONEDITVIEW;
        }
        [self.contentView addSubview:edititextview];

        self.detailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _detailButton.tag = 200;
        [_detailButton setImage:[UIImage imageNamed:@"document_cellmore_more"] forState:UIControlStateNormal];
        [_detailButton addTarget:self action:@selector(handleClickDetailButton) forControlEvents:UIControlEventTouchUpInside];
        _detailButton.frame = CGRectMake(self.bounds.size.width - 50, 0, 50, 50);
        _detailButton.center = CGPointMake(_detailButton.center.x, 34);
        _detailButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        [self.contentView addSubview:_detailButton];
        if (isMenu) {
            if ((DEVICE_iPHONE && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)) || (DEVICE_iPHONE && ((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) < (375 * 667)) && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight))) {
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
        }
    }
    return self;
}

- (void)setCellDelegate:(id<AnnotationListCellDelegate>)cellDelegate {
    if (_cellDelegate != cellDelegate) {
        _cellDelegate = cellDelegate;
        [self setupEditView];
    }
}

- (void)setItem:(AnnotationItem *)item {
    if (_item != item) {
        _item = item;
        [self setupEditView];
    }
}

- (void)setupEditView {
    if (!self.item || !self.cellDelegate) {
        return;
    }
    BOOL canEdit = [self.cellDelegate respondsToSelector:@selector(annotationListCellCanEdit:)] ? [self.cellDelegate annotationListCellCanEdit:self] : NO;
    BOOL canDescript = [self.cellDelegate respondsToSelector:@selector(annotationListCellCanDescript:)] ? [self.cellDelegate annotationListCellCanDescript:self] : NO;
    BOOL canDelete = [self.cellDelegate respondsToSelector:@selector(annotationListCellCanDelete:)] ? [self.cellDelegate annotationListCellCanDelete:self] : NO;
    BOOL canReply = [self.cellDelegate respondsToSelector:@selector(annotationListCellCanReply:)] ? [self.cellDelegate annotationListCellCanReply:self] : NO;
    BOOL canSave = [self.cellDelegate respondsToSelector:@selector(annotationListCellCanSave:)] ? [self.cellDelegate annotationListCellCanSave:self] : NO;
    if (canEdit || canDelete || canReply || canSave) {
        self.editView = [[AnnotationListMore alloc] initWithOrigin:CGPointMake(self.contentView.bounds.size.width, 0) height:68.0f canRename:NO canEditContent:canEdit canDescript:canDescript canDelete:canDelete canReply:canReply canSave:canSave];
        self.editView.delegate = self;
        [self.contentView addSubview:self.editView];
    }
    self.detailButton.enabled = (self.editView != nil);
}

#pragma mark <AnnotationListMoreDelegate>

- (void)annotationListMoreReply:(AnnotationListMore *)annotationListMore {
    if ([self.cellDelegate respondsToSelector:@selector(annotationListCellReply:)]) {
        [self.cellDelegate annotationListCellReply:self];
    }
}

- (void)annotationListMoreEdit:(AnnotationListMore *)annotationListMore {
    if ([self.cellDelegate respondsToSelector:@selector(annotationListCellEdit:)]) {
        [self.cellDelegate annotationListCellEdit:self];
    }
}

- (void)annotationListMoreDescript:(AnnotationListMore *)annotationListMore {
    if ([self.cellDelegate respondsToSelector:@selector(annotationListCellDescript:)]) {
        [self.cellDelegate annotationListCellDescript:self];
    }
}

- (void)annotationListMoreDelete:(AnnotationListMore *)annotationListMore {
    if ([self.cellDelegate respondsToSelector:@selector(annotationListCellDelete:)]) {
        [self.cellDelegate annotationListCellDelete:self];
    }
}

- (void)annotationListMoreSave:(AnnotationListMore *)annotationListMore {
    if ([self.cellDelegate respondsToSelector:@selector(annotationListCellSave:)]) {
        [self.cellDelegate annotationListCellSave:self];
    }
}

#pragma mark

- (void)dismissKeyboard {
    if (self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(dismissKeyboard)]) {
        [self.cellDelegate dismissKeyboard];
    }
}

- (void)prepareForReuse {
    if (_editView) {
        [_editView removeFromSuperview];
        _editView = nil;
    }
    self.item = nil;
}

- (void)handleClickDetailButton {
    if ([self.cellDelegate respondsToSelector:@selector(annotationListCellWillShowEditView:)]) {
        [self.cellDelegate annotationListCellWillShowEditView:self];
    }
    [self setEditViewHidden:NO];
    if ([self.cellDelegate respondsToSelector:@selector(annotationListCellDidShowEditView:)]) {
        [self.cellDelegate annotationListCellDidShowEditView:self];
    }
}

- (void)setEditViewHidden:(BOOL)isHidden {
    [self setEditViewHidden:isHidden animated:YES];
}

- (void)setEditViewHidden:(BOOL)isHidden animated:(BOOL)animated {
    if (isHidden) {
        [self hideEditViewAnimated:animated];
    } else {
        [self showEditViewAnimated:animated];
    }
}

- (void)showEditViewAnimated:(BOOL)animated {
    void (^showEditView)() = ^{
        self.editView.frame = ({
            CGRect frame = self.editView.frame;
            frame.origin.x = self.editView.superview.bounds.size.width - frame.size.width;
            frame;
        });
    };
    if (animated) {
        [UIView animateWithDuration:0.3 animations:showEditView];
    } else {
        showEditView();
    }
}

- (void)hideEditViewAnimated:(BOOL)animated {
    if (!_editView) {
        return;
    }
    void (^hideEditView)() = ^{
        self.editView.frame = ({
            CGRect frame = self.editView.frame;
            frame.origin.x = self.editView.superview.bounds.size.width;
            frame;
        });
    };
    if (animated) {
        [UIView animateWithDuration:0.3 animations:hideEditView];
    } else {
        hideEditView();
    }
}

@end
