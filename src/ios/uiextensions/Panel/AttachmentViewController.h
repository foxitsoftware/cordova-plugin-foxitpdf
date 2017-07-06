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
#import "FileManageBaseViewController.h"

enum MoveFileAlertCheckType
{
    MoveFileAlertCheckType_Ask = 0,
    MoveFileAlertCheckType_Replace = 1,
    MoveFileAlertCheckType_ReplaceAll = 2,
    MoveFileAlertCheckType_Skip = 3,
    MoveFileAlertCheckType_SkipAll = 4,
    MoveFileAlertCheckType_Cancel = 5
};
typedef enum MoveFileAlertCheckType MoveFileAlertCheckType;


@class AttachmentPanel;

@interface AttachmentViewController : UITableViewController<IAnnotEventListener,UIAlertViewDelegate,UITextViewDelegate,UITableViewDelegate,UIDocumentInteractionControllerDelegate, IDocEventListener, IPageEventListener>
{
    BOOL _alertViewFinished;
    MoveFileAlertCheckType _moveFileAlertCheckType;
}
@property (atomic, strong) NSMutableArray *allAttachmentsSections;
@property (nonatomic,strong)AttachmentItem *editAnnoItem;
@property (nonatomic,strong)NSIndexPath *indexPath;
@property (nonatomic,assign)BOOL isShowMore;
@property (nonatomic, strong) NSIndexPath *moreIndexPath;

- (id)initWithStyle:(UITableViewStyle)style extensionsManager:(UIExtensionsManager*)extensionsManager module:(AttachmentPanel*)attachmentPanel;
- (void)loadData;
- (void)clearData;
// attachment could be a attachment annotation or a document attachment
- (void)deleteAnnotation:(AnnotationItem *)item;
- (void)saveAttachment:(AnnotationItem*)item;
- (void)addNoteToAnnotation:(AnnotationItem *)item withIndexPath:(NSIndexPath *)indexPath;
- (void)updateAllAttachments:(AttachmentItem *)attachmentItem operation:(int)operation;

- (void)onDocumentAttachmentAdded:(AttachmentItem*)attachmentItem;
- (void)onDocumentAttachmentDeleted:(AttachmentItem*)attachmentItem;
- (void)onDocumentAttachmentModified:(AttachmentItem*)attachmentItem;

@end
