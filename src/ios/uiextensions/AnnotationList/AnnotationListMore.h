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

#import <Foundation/Foundation.h>


@class ReplyTableViewController;
@class PanelHost;

/** @brief The 'more' button view on the annotation list cell.*/
@interface AnnotationListMore : UIView

@property(nonatomic,strong)NSIndexPath *indexPath;
@property(nonatomic,strong)UIButton *replyButton;
@property(nonatomic,strong)UIButton *noteButton;
@property(nonatomic,strong)UIButton *deleteButton;
@property(nonatomic,strong)UIButton *renameButton;
@property(nonatomic,strong)UIButton *saveButton;
@property(nonatomic,strong)UIView *bottomView;
@property(nonatomic,strong)UIView *gestureView;

@property (nonatomic, strong)AnnotationListMore* delegate;
- (id)initWithFrame:(CGRect)frame superView:(UIView*)superView delegate:(id)delegate isBookMark:(BOOL)enable isMenu:(BOOL)isMenu;
- (id)initWithFrame:(CGRect)frame superView:(UIView*)superView delegate:(id)delegate isBookMark:(BOOL)enable isMenu:(BOOL)isMenu isAttachment:(BOOL)isAttachment;
- (void)setCellViewHidden:(BOOL)hidden isMenu:(BOOL)menu;
- (void)tapGuest:(UIGestureRecognizer *)guest;
@end
