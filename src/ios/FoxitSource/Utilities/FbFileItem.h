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
#import <UIKit/UIKit.h>
#import "FbBaseBrowser.h"

@interface FbFileItem : NSObject


@property(nonatomic, strong) NSString *parentPath;
@property(nonatomic, strong) NSString *type;
@property(nonatomic, strong) NSString *fileName;
@property(nonatomic, strong) NSString *createTime;
@property(nonatomic, unsafe_unretained) NSUInteger fileSize;
@property(nonatomic, unsafe_unretained) NSUInteger directorySize;
@property(nonatomic, unsafe_unretained) BOOL isFolder;
@property(nonatomic, assign) BOOL isOpen;
@property(nonatomic, assign) BOOL isValidPDF;
@property(nonatomic, strong) NSString *path;
@property(nonatomic, strong) NSDate *modifiedDate;
@property(nonatomic, retain) NSDate *lastViewDate;
@property(nonatomic, assign) BOOL isTouchMoving;
@property(nonatomic, retain) NSString *fileExt;
@property(nonatomic, assign) unsigned int reserveData;

- (id)initWithPath:(NSString *)filePath modifiedDate:(NSDate *)lastModifiedDate isFavorite:(NSNumber *)isFavorite;
+ (float)folderSizeAtPath:(NSString *)folderPath;
- (void)getThumbnailForPageIndex:(int)pageIndex dispatchQueue:(dispatch_queue_t)queue WithHandler:(getThumbnailHandler)handler;

+ (NSString *)getCacheDirectoryPath:(NSString *)path;

@end


