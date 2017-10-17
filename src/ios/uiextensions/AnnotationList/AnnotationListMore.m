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

#import "AnnotationListMore.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import <UIKit/UIKit.h>

#import "AnnotationListCell.h"
#import "AnnotationListViewController.h"
#import "AttachmentViewController.h"
#import "ColorUtility.h"
#import "MASConstraintMaker.h"
#import "ReadingBookmarkListCell.h"
#import "ReadingBookmarkViewController.h"
#import "ReplyTableViewController.h"
#import "View+MASAdditions.h"

@interface AnnotationListMore () <UIGestureRecognizerDelegate>
@property (nonatomic, assign) CGRect annotDetailBtRect;
@property (nonatomic, assign) CGRect replyBtRect;
@property (nonatomic, assign) CGRect bookmarkDetailBtRect;
@property (nonatomic, assign) CGRect bookmarkDetaileBtRect;

@end

@implementation AnnotationListMore {
}

- (id)initWithOrigin:(CGPoint)origin height:(CGFloat)height canRename:(BOOL)canRename canEditContent:(BOOL)canEditContent canDescript:(BOOL)canDescript canDelete:(BOOL)canDelete canReply:(BOOL)canReply canSave:(BOOL)canSave {
    // buttons
    self.renameButton = [AnnotationListMore createButtonWithImageAndTitle:NSLocalizedStringFromTable(@"kRename", @"FoxitLocalizable", nil)
                                                              imageNormal:[UIImage imageNamed:@"document_edit_small_rename"]
                                                            imageSelected:[UIImage imageNamed:@"document_edit_small_rename"]
                                                             imageDisable:[UIImage imageNamed:@"document_edit_small_rename"]];

    self.replyButton = [AnnotationListMore createButtonWithImageAndTitle:NSLocalizedStringFromTable(@"kReply", @"FoxitLocalizable", nil)
                                                             imageNormal:[UIImage imageNamed:@"panel_more_reply"]
                                                           imageSelected:[UIImage imageNamed:@"panel_more_reply"]
                                                            imageDisable:[UIImage imageNamed:@"panel_more_reply"]];

    self.noteButton = [AnnotationListMore createButtonWithImageAndTitle:NSLocalizedStringFromTable(@"kIconNote", @"FoxitLocalizable", nil)
                                                            imageNormal:[UIImage imageNamed:@"panel_more_note"]
                                                          imageSelected:[UIImage imageNamed:@"panel_more_note"]
                                                           imageDisable:[UIImage imageNamed:@"panel_more_note"]];

    self.descriptionButton = [AnnotationListMore createButtonWithImageAndTitle:NSLocalizedStringFromTable(@"kDescription", @"FoxitLocalizable", nil)
                                                                   imageNormal:[UIImage imageNamed:@"panel_more_note"]
                                                                 imageSelected:[UIImage imageNamed:@"panel_more_note"]
                                                                  imageDisable:[UIImage imageNamed:@"panel_more_note"]];

    self.saveButton = [AnnotationListMore createButtonWithImageAndTitle:NSLocalizedStringFromTable(@"kSave", @"FoxitLocalizable", nil)
                                                            imageNormal:[UIImage imageNamed:@"panel_more_save"]
                                                          imageSelected:[UIImage imageNamed:@"panel_more_save"]
                                                           imageDisable:[UIImage imageNamed:@"panel_more_save"]];

    self.deleteButton = [AnnotationListMore createButtonWithImageAndTitle:NSLocalizedStringFromTable(@"kDelete", @"FoxitLocalizable", nil)
                                                              imageNormal:[UIImage imageNamed:@"panel_more_delete"]
                                                            imageSelected:[UIImage imageNamed:@"panel_more_delete"]
                                                             imageDisable:[UIImage imageNamed:@"panel_more_delete"]];
    NSMutableArray<UIButton *> *buttons = [NSMutableArray<UIButton *> array];
    if (canSave) {
        [buttons addObject:self.saveButton];
    }
    if (canRename) {
        [buttons addObject:self.renameButton];
    }
    if (canReply) {
        [buttons addObject:self.replyButton];
    }
    if (canEditContent) {
        [buttons addObject:self.noteButton];
    }
    if (canDescript) {
        [buttons addObject:self.descriptionButton];
    }
    if (canDelete) {
        [buttons addObject:self.deleteButton];
    }
    const CGFloat minButtonWidth = 50.0f;
    __block CGFloat currrentX = 0;
    [buttons enumerateObjectsUsingBlock:^(UIButton *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CGFloat buttonWidth = MAX(minButtonWidth, obj.frame.size.width);
        CGRect buttonFrame = {currrentX, 0, buttonWidth, height};
        obj.frame = buttonFrame;
        obj.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [obj addTarget:self action:@selector(handleClick:) forControlEvents:UIControlEventTouchUpInside];
        currrentX += buttonWidth;
    }];

    CGRect frame = {origin, currrentX, height};
    if ([super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:231.f / 255.f green:231.f / 255.f blue:231.f / 255.f alpha:1];
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [buttons enumerateObjectsUsingBlock:^(UIButton *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            [self addSubview:obj];
        }];
    }
    return self;
}

- (void)handleClick:(UIButton *)button {
    if (button == self.renameButton) {
        if ([self.delegate respondsToSelector:@selector(annotationListMoreRename:)]) {
            [self.delegate annotationListMoreRename:self];
        }
    } else if (button == self.deleteButton) {
        if ([self.delegate respondsToSelector:@selector(annotationListMoreDelete:)]) {
            [self.delegate annotationListMoreDelete:self];
        }
    } else if (button == self.replyButton) {
        if ([self.delegate respondsToSelector:@selector(annotationListMoreReply:)]) {
            [self.delegate annotationListMoreReply:self];
        }
    } else if (button == self.saveButton) {
        if ([self.delegate respondsToSelector:@selector(annotationListMoreSave:)]) {
            [self.delegate annotationListMoreSave:self];
        }
    } else if (button == self.noteButton) {
        if ([self.delegate respondsToSelector:@selector(annotationListMoreEdit:)]) {
            [self.delegate annotationListMoreEdit:self];
        }
    } else if (button == self.descriptionButton) {
        if ([self.delegate respondsToSelector:@selector(annotationListMoreDescript:)]) {
            [self.delegate annotationListMoreDescript:self];
        }
    }
}

+ (UIButton *)createButtonWithImageAndTitle:(NSString *)title
                                imageNormal:(UIImage *)imageNormal
                              imageSelected:(UIImage *)imageSelected
                               imageDisable:(UIImage *)imageDisabled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    CGSize titleSize = [Utility getTextSize:title fontSize:9.0f maxSize:CGSizeMake(200, 100)];

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

    button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, -height * 1.5, 0);
    button.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width);
    button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width + 2 : width, titleSize.height + height);
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    return button;
}

@end
