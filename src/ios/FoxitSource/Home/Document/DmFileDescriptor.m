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
 #import "DmFileDescriptor.h"

@implementation DmFileDescriptor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fileID = nil;
        self.filePath = nil;
        self.fileCanModify = YES;
        self.docOpenType = 0;
        self.docOpenPassword = nil;
        self.docOpenPermissions = 0;
        self.docSecurityName = nil;
        self.docIsModified = NO;
        self.docSaveType = 0;
        self.reviewType = 0;
        self.pdfdoc = nil;
    }
    return self;
}

-(void)dealloc
{
    self.fileID = nil;
    self.filePath = nil;
    self.fileCanModify = YES;
    self.docOpenType = 0;
    self.docOpenPassword = nil;
    self.docOpenPermissions = 0;
    self.docSecurityName = nil;
    self.docIsModified = NO;
    self.docSaveType = 0;
    self.reviewType = 0;
    self.pdfdoc = nil;
}

@end
