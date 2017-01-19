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

#define ReviewType_NetWork 1
#define ReviewType_Email 2
#define ReviewType_Email_Merge 3
#define ReviewType_FoxitCloud 4

#define DOC_TYPE_PDF		1
#define DOC_TYPE_PPDF		2

@class FSPDFDoc;
@interface DmFileDescriptor : NSObject

@property (nonatomic, retain) NSString *fileID;
@property (nonatomic, retain) NSString* filePath;
@property (nonatomic, assign) BOOL fileCanModify;
@property (nonatomic, assign) int docOpenType;
@property (nonatomic, retain) NSString *docOpenPath;
@property (nonatomic, retain) NSString *docOpenPassword;
@property (nonatomic, assign) int docOpenPermissions;
@property (nonatomic, retain) NSString *docSecurityName;
@property (nonatomic, assign) BOOL docIsModified;
@property (nonatomic, assign) int docSaveType;
@property (nonatomic, assign) int reviewType;
@property (nonatomic, retain) FSPDFDoc* pdfdoc;

@end
