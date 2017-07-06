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
@class FSAnnot;

/**@brief Annotation item to save the current state of annotation. */
@interface AnnotationItem : NSObject

@property (nonatomic,strong)FSAnnot *annot;
@property (nonatomic,assign)NSInteger currentlevel;
@property (nonatomic,strong)NSString*replytoauthor;
@property (nonatomic,assign)BOOL currentlevelshow;
@property (nonatomic,weak) AnnotationItem *rootannotation;
@property (nonatomic,weak) UIButton*currentlevelbutton;
@property (nonatomic,assign)BOOL isSecondLevel;
@property (nonatomic,assign)BOOL isEdited;
@property (nonatomic,assign)BOOL isUpdate;
@property (nonatomic,assign)BOOL isShowUpdateTip;
@property (nonatomic,assign)NSUInteger annosection;
@property (nonatomic,assign)NSUInteger annorow;
@property (nonatomic,strong)NSString* annoIdentifierTag;
@property (nonatomic,assign)BOOL isSelected;
@property (nonatomic,assign)BOOL isReply;
@property (nonatomic,assign)BOOL isMyAnnotation;
@property (nonatomic,assign)BOOL isDeleted;

-(void)addCurrentlevel:(NSNumber *)object;
-(void)setcurrentlevelshow:(NSNumber*)object;
-(void)setSecondLevel:(NSNumber*)object;
-(void)setAnnotationSection:(NSNumber*)object;
@end

/**@brief Annotation button. */
@interface AnnotationButton : UIButton

@property(nonatomic,assign)NSUInteger currentsection;
@property(nonatomic,assign)NSUInteger currentrow;
@property(nonatomic,assign)BOOL currentstate;
@property(nonatomic,weak) AnnotationItem *buttonannotag;
@end

@class FSFileSpec;
@class FSFileAttachment;

@interface AttachmentItem : AnnotationItem
@property (nonatomic, copy) NSString *keyName;//For document file attachment, nil for annotation.
@property (nonatomic, strong) FSFileSpec* fileSpec;
@property (nonatomic) BOOL isDocumentAttachment;
@property (nonatomic, assign) int pageIndex;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, assign) long long fileSize;
@property (nonatomic, strong) NSDate *createDate;
@property (nonatomic, strong) NSDate *modifyDate;


+ (instancetype)itemWithAttachmentAnnotation:(FSFileAttachment*)annot;
+ (instancetype)itemWithDocumentAttachment:(NSString*)keyName file:(FSFileSpec*)attachmentFile PDFPath:(NSString*)PDFPath;
@end
