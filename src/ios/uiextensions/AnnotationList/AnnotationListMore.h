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
#import <Foundation/Foundation.h>


@class ReplyTableViewController;
@class PanelHost;

/** @brief The 'more' button view on the annotation list cell.*/
@interface AnnotationListMore : UIView

@property(nonatomic,retain)NSIndexPath *indexPath;
@property(nonatomic,retain)UIButton *replyButton;
@property(nonatomic,retain)UIButton *noteButton;
@property(nonatomic,retain)UIButton *deleteButton;
@property(nonatomic,retain)UIButton *renameButton;
@property(nonatomic,retain)UIView *bottomView;
@property(nonatomic,retain)UIView *gestureView;

@property (nonatomic, retain)AnnotationListMore* delegate;
- (id)initWithFrame:(CGRect)frame superView:(UIView*)superView delegate:(id)delegate isBookMark:(BOOL)enable isMenu:(BOOL)isMenu;
- (void)setCellViewHidden:(BOOL)hidden isMenu:(BOOL)menu;
- (void)tapGuest:(UIGestureRecognizer *)guest;
@end
