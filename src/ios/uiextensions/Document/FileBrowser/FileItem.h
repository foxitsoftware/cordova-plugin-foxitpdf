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

#import "FileBrowser.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FileItem : NSObject

@property (nonatomic, strong) NSString *parentPath;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *filekey;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *fileExt;

@property (nonatomic, assign) BOOL isFolder;
@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, assign) BOOL isValidPDF;
@property (nonatomic, assign) BOOL isTouchMoving;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, strong) NSDate *modifiedDate;
@property (nonatomic, strong) NSDate *lastViewDate;

@property (nonatomic, assign) unsigned long long fileSize;
@property (nonatomic, assign) unsigned int reserveData;

- (id)initWithPath:(NSString *)filePath modifiedDate:(NSDate *)lastModifiedDate isFavorite:(NSNumber *)isFavorite;
- (void)getThumbnailForPageIndex:(int)pageIndex dispatchQueue:(dispatch_queue_t)queue WithHandler:(getThumbnailHandler)handler;

+ (NSString *)getCacheDirectoryPath:(NSString *)path;

@end
