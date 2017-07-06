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

#import <UIKit/UIKit.h>
#import "AnnotationStruct.h"
#import "AnnotationListCell.h"

typedef void (^NoteEditingDone)(void);
typedef void (^NoteEditingDelete)(void);
typedef void (^NoteEditingCancel)(void);

/**@brief A table view controller to maneger replies of an annotation. */
@interface ReplyTableViewController : UITableViewController<UITableViewDelegate,UINavigationControllerDelegate,UITextViewDelegate,UITextFieldDelegate>

@property (nonatomic, assign) NSUInteger pageIndex;
@property (nonatomic, copy) NoteEditingCancel editingCancelHandler;
@property (nonatomic, copy) NoteEditingDone  editingDoneHandler;
@property (nonatomic, assign) BOOL isNeedReply;

@property (nonatomic, strong) AnnotationItem *editAnnoItem;
@property (nonatomic, strong) AnnotationItem* replyanno;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) BOOL isShowMore;
@property (nonatomic, strong) NSIndexPath *moreIndexPath;

@property (nonatomic, strong)UIButton* buttonLeft;

-(id)initWithStyle:(UITableViewStyle)style extensionsManager:(UIExtensionsManager*)extensionsManager;
- (void)initNavigationBar;
-(void)setTableViewAnnotations:(NSArray*)annotatios;
-(void)getDetailReply:(AnnotationButton*)button;
-(void)getAboutAnnotatios:(AnnotationItem*)searchanno Annoarray:(NSArray*)annoarray deleteArray:(NSMutableArray*)deletearray;
-(void)deletaAnnotatios:(NSArray*)annos;
-(void)showKeyBoard:(NSIndexPath*)indexpath;

- (void)deleteAnnotation:(AnnotationItem *)item;
- (void)replyToAnnotation:(AnnotationItem *)item;

-(void)clearData;
@end
