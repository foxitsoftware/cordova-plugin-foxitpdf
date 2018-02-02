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

#import "ReadingBookmarkListCell.h"
#import "Masonry.h"
#import "PanelHost.h"
#import "ReadingBookmarkViewController.h"

@implementation ReadingBookmarkButton

@end

@interface ReadingBookmarkListCell () <AnnotationListMoreDelegate>

@end

@implementation ReadingBookmarkListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CGRect contentFrame = CGRectMake(self.frame.size.width - 54, (self.frame.size.height - 32) / 2, 32, 32);
        contentFrame = CGRectMake(10, (self.frame.size.height - 30) / 2, 300, 30);
        self.pageLabel = [[UILabel alloc] initWithFrame:contentFrame];
        _pageLabel.textAlignment = NSTextAlignmentLeft;
        _pageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _pageLabel.font = [UIFont systemFontOfSize:17];
        _pageLabel.textColor = [UIColor blackColor];
        [self.contentView addSubview:_pageLabel];

        self.detailButton = [ReadingBookmarkButton buttonWithType:UIButtonTypeCustom];
        [_detailButton setImage:[UIImage imageNamed:@"document_cellmore_more"] forState:UIControlStateNormal];
        [_detailButton addTarget:self action:@selector(handleClickDetailButton) forControlEvents:UIControlEventTouchUpInside];
        _detailButton.frame = CGRectMake(self.bounds.size.width - 50, 0, 50, 50);
        _detailButton.center = CGPointMake(_detailButton.center.x, self.bounds.size.height / 2);
        _detailButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [self.contentView addSubview:_detailButton];

        return self;
    }
}

- (void)handleClickDetailButton {
    if ([self.delegate respondsToSelector:@selector(readingBookmarkListCellWillShowEditView:)]) {
        [self.delegate readingBookmarkListCellWillShowEditView:self];
    }
    [self setEditViewHidden:NO];
    if ([self.delegate respondsToSelector:@selector(readingBookmarkListCellDidShowEditView:)]) {
        [self.delegate readingBookmarkListCellDidShowEditView:self];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
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
    void (^showEditView)(void) = ^{
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
    void (^hideEditView)(void) = ^{
        if (!_editView) {
            return;
        }
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

- (AnnotationListMore *)editView {
    if (!_editView) {
        _editView = [[AnnotationListMore alloc] initWithOrigin:CGPointMake(self.contentView.bounds.size.width, 0) height:50.0f canRename:YES canEditContent:NO canDescript:NO canDelete:YES canReply:NO canSave:NO];
        _editView.delegate = self;
        [self.contentView addSubview:_editView];
    }
    return _editView;
}

- (void)prepareForReuse {
    if (_editView) {
        [_editView removeFromSuperview];
        _editView = nil;
    }
    [super prepareForReuse];
}

#pragma mark <AnnotationListMoreDelegate>

- (void)annotationListMoreDelete:(AnnotationListMore *)annotationListMore {
    if ([self.delegate respondsToSelector:@selector(readingBookmarkListCellDelete:)]) {
        [self.delegate readingBookmarkListCellDelete:self];
    }
}
- (void)annotationListMoreRename:(AnnotationListMore *)annotationListMore {
    if ([self.delegate respondsToSelector:@selector(readingBookmarkListCellRename:)]) {
        [self.delegate readingBookmarkListCellRename:self];
    }
}

@end
