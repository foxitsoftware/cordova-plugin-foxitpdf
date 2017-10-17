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
#import <UIKit/UIKit.h>

@class ReplyTableViewController;
@class PanelHost;
@class AnnotationListMore;

@protocol AnnotationListMoreDelegate <NSObject>

@optional
- (void)annotationListMoreReply:(AnnotationListMore *)annotationListMore;
- (void)annotationListMoreEdit:(AnnotationListMore *)annotationListMore;
- (void)annotationListMoreDescript:(AnnotationListMore *)annotationListMore;
- (void)annotationListMoreDelete:(AnnotationListMore *)annotationListMore;
- (void)annotationListMoreRename:(AnnotationListMore *)annotationListMore;
- (void)annotationListMoreSave:(AnnotationListMore *)annotationListMore;

@end

/** @brief The 'more' button view on the annotation list cell.*/
@interface AnnotationListMore : UIView

@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) UIButton *noteButton;
@property (nonatomic, strong) UIButton *descriptionButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *renameButton;
@property (nonatomic, strong) UIButton *saveButton;

@property (nonatomic, weak) id<AnnotationListMoreDelegate> delegate;

- (id)initWithOrigin:(CGPoint)origin height:(CGFloat)height canRename:(BOOL)canRename canEditContent:(BOOL)canEditContent canDescript:(BOOL)canDescript canDelete:(BOOL)canDelete canReply:(BOOL)canReply canSave:(BOOL)canSave;

@end
