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
#import <UIKit/UIKit.h>
#import "FbBaseBrowser.h"
#import "DocumentModule.h"


@interface FbFileBrowser : FbBaseBrowser

@property (nonatomic, assign) FileSortType sortType;
@property (nonatomic, assign) FileSortMode sortMode;

- (void)initializeViewWithDelegate:(id<IFbFileDelegate>)delegate fileListType:(FileListType)type;
- (void)sortFileByType:(FileSortType)sortType andFileSortMode:(FileSortMode)sortMode;
- (void)changeThumbnailFrame:(BOOL)change;
- (UINavigationController *)getNaviController;
- (void)switchStyle;

- (void)getFileListForType:(FileListType)type withFolderPath:(NSString *)folder withSearchKeyword:(NSString *)searchKeyword withParentFileObject:(id)parentFileObject userData:(NSDictionary *)userData withHandler:(getFileListHandler)handler;

+ (void)_getFileListForType:(FileListType)type withFolder:(NSString *)folder withSearchKeyword:(NSString *)searchKeyword withParentFileObject:(FbFileItem *)parentFileObject userData:(NSDictionary *)userData withHandler:(getFileListHandler)handler;
@end
