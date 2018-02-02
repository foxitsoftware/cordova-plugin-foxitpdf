/**
 * Copyright (C) 2003-2018, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "FileDelegate.h"
#import <UIKit/UIKit.h>

typedef enum {
    FileSortType_Name = 0,
    FileSortType_Date = 1,
    FileSortType_Size = 2,
    FileSortType_LastView = 3
} FileSortType;

typedef enum {
    FileSortMode_Ascending,
    FileSortMode_Descending
} FileSortMode;

typedef void (^getFileListHandler)(NSMutableArray *fileList);
typedef void (^getThumbnailHandler)(UIImage *imageThumbnail, int pageIndex, NSString *pdfPath);

@interface FileBrowser : NSObject

@property (nonatomic, assign) FileSortType sortType;
@property (nonatomic, assign) FileSortMode sortMode;

- (UIView *)getContentView;

- (void)initializeViewWithDelegate:(id<FileDelegate>)delegate;
- (void)sortFileByType:(FileSortType)sortType fileSortMode:(FileSortMode)sortMode;
- (void)changeThumbnailFrame:(BOOL)change;
- (UINavigationController *)getNaviController;
- (void)switchStyle;

+ (void)getFileListWithFolderPath:(NSString *)folder withSearchKeyword:(NSString *)searchKeyword userData:(NSDictionary *)userData withHandler:(getFileListHandler)handler;
@end
