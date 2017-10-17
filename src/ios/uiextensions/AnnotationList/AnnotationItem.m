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

#import "AnnotationItem.h"
#import "FSAnnotExtent.h"
#import "Utility.h"
#import <FoxitRDK/FSPDFObjC.h>
#import <UIKit/UIKit.h>

@implementation AnnotationItem

- (void)addCurrentlevel:(NSNumber *)object {
    _currentlevel = [object intValue];
}

- (void)setReplytoauthor:(NSString *)replytoauthor {
    if (_replytoauthor != replytoauthor) {
        _replytoauthor = [replytoauthor copy];
    }
}

- (void)setSecondLevel:(NSNumber *)object {
    _isSecondLevel = [object boolValue];
}

- (void)setcurrentlevelshow:(NSNumber *)object {
    _currentlevelshow = [object boolValue];
}

- (void)setAnnotationSection:(NSNumber *)object {
    _annosection = [object intValue];
}

@end

@implementation AnnotationButton

@end

@implementation AttachmentItem

@synthesize description;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isDocumentAttachment = NO;
        self.pageIndex = -1;
        self.filePath = nil;
        self.fileName = nil;
        self.fileSize = 0;
        self.description = nil;
        self.createDate = nil;
        self.modifyDate = nil;
        self.keyName = nil;
    }
    return self;
}

+ (instancetype)itemWithAttachmentAnnotation:(FSFileAttachment *)annot {
    AttachmentItem *attachmentItem = [[AttachmentItem alloc] init];
    attachmentItem.isDocumentAttachment = NO;
    attachmentItem.pageIndex = annot.pageIndex;
    attachmentItem.annot = annot;
    FSFileSpec *file = [annot getFileSpec];
    attachmentItem.fileSpec = file;
    attachmentItem.filePath = [Utility getAttachmentTempFilePath:annot];
    attachmentItem.fileName = [file getFileName];
    attachmentItem.fileSize = [file getFileSize];
    attachmentItem.description = annot.contents;
    attachmentItem.createDate = [Utility convertFSDateTime2NSDate:file.getCreationDateTime];
    attachmentItem.modifyDate = [Utility convertFSDateTime2NSDate:file.getModifiedDateTime];
    return attachmentItem;
}

+ (instancetype)itemWithDocumentAttachment:(NSString *)keyName file:(FSFileSpec *)attachmentFile PDFPath:(NSString *)PDFPath {
    AttachmentItem *attachmentItem = [[AttachmentItem alloc] init];
    attachmentItem.keyName = keyName;
    attachmentItem.isDocumentAttachment = YES;
    attachmentItem.fileSpec = attachmentFile;
    attachmentItem.filePath = [Utility getDocumentAttachmentTempFilePath:attachmentFile PDFPath:PDFPath];
    attachmentItem.fileName = attachmentFile.getFileName;
    attachmentItem.fileSize = attachmentFile.getFileSize;
    attachmentItem.description = attachmentFile.getDescription;
    attachmentItem.createDate = [Utility convertFSDateTime2NSDate:attachmentFile.getCreationDateTime];
    attachmentItem.modifyDate = [Utility convertFSDateTime2NSDate:attachmentFile.getModifiedDateTime];
    return attachmentItem;
}

@end
