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
#import "FileItem.h"
#import "FileManageListViewController.h"
#import "TbBaseBar.h"
#import "Utility.h"

@interface FileBrowser ()

@property (nonatomic, unsafe_unretained) BOOL isEditing;
@property (nonatomic, strong) FileManageListViewController *fileListView;
@property (nonatomic, strong) NSMutableArray *arraySelectedItems;
@property (nonatomic, strong) UINavigationController *naviController;
@property (nonatomic, strong) TbBaseBar *topBar;
@property (nonatomic, assign) BOOL isShowFavorite;
@end

@implementation FileBrowser

- (void)initializeViewWithDelegate:(id<FileDelegate>)delegate {
    NSBundle *bundle = nil;
    NSString *nibName = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? @"FileManageViewController_iPhone" : @"FileManageListViewController_iPad";
    _fileListView = [[FileManageListViewController alloc] initWithNibName:nibName bundle:bundle];
    _fileListView.delegate = delegate;
    _fileListView.sortType = self.sortType;
    _fileListView.sortMode = self.sortMode;
    _naviController = [[UINavigationController alloc] initWithRootViewController:_fileListView];
    _naviController.navigationBarHidden = YES;
}

- (void)changeThumbnailFrame:(BOOL)change {
    for (UIViewController *viewCon in _fileListView.navigationController.viewControllers) {
        if (viewCon != _fileListView) {
            [(FileManageListViewController *) viewCon changeThumbnailFrame:change];
        }
    }
}

- (void)sortFileByType:(FileSortType)sortType fileSortMode:(FileSortMode)sortMode {
    FileManageListViewController *currentViewcon = (FileManageListViewController *) _fileListView.navigationController.topViewController;
    [currentViewcon sortFileByType:sortType fileSortMode:sortMode];
}

- (UIView *)getContentView {
    return _naviController.view;
}

- (UINavigationController *)getNaviController {
    return _naviController;
}

- (void)switchStyle {
    FileManageListViewController *currentViewcon = (FileManageListViewController *) _fileListView.navigationController.topViewController;
    [currentViewcon buttonChangeViewMode];
}

static NSArray *removeSystemFiles(NSArray *array, BOOL isRoot) {
    return [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nonnull evaluatedObject, NSDictionary<NSString *, id> *_Nullable bindings) {
                      NSString *path = evaluatedObject;
                      return ![path.pathExtension.lowercaseString isEqualToString:@".plist"] && ![path.lowercaseString isEqualToString:@".plist"] && !(isRoot && [path isEqualToString:@"Inbox"]) && ![path.lowercaseString isEqualToString:@".DS_Store".lowercaseString] && ![path isEqualToString:@".IntuneMAM".lowercaseString];
                  }]];
}

+ (void)getFileListWithFolderPath:(NSString *)folder withSearchKeyword:(NSString *)searchKeyword userData:(NSDictionary *)userData withHandler:(getFileListHandler)handler {
    searchKeyword = [searchKeyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray *arrayFileList = [[NSMutableArray alloc] init];

    //get list from local document
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *array = [fileManager contentsOfDirectoryAtPath:folder error:nil]; //cannot use enumeratorAtPath: as it will list the subdirectories
    array = removeSystemFiles(array, YES);
    BOOL isFolder = NO;
    for (NSString *fileName in array) {
        NSString *path = [([folder isEqualToString:DOCUMENT_PATH]) ? DOCUMENT_PATH : folder stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:path isDirectory:&isFolder] && isFolder) //If it is directory
        {
            //Removing the temporary directory of zip and zip
            if (!([folder isEqualToString:DOCUMENT_PATH] && ([path.lastPathComponent isEqualToString:@".unziptempfolder"] || [path.lastPathComponent isEqualToString:@".ziptempfolder"]))) {
                //If you search for a keyword is empty you need to add Catalog
                if (searchKeyword == nil || [searchKeyword isEqualToString:@""]) {
                    {
                        FileItem *fileObj = [[FileItem alloc] initWithPath:path modifiedDate:nil isFavorite:nil];
                        fileObj.isFolder = isFolder;
                        fileObj.path = path;
                        fileObj.fileName =
                            [path lastPathComponent]; //if directory, set file name to directory name
                        fileObj.fileExt = nil;
                        NSDictionary *fileAttribute = [fileManager attributesOfItemAtPath:path error:nil];
                        if (fileAttribute != nil) {
                            fileObj.modifiedDate = [fileAttribute fileModificationDate];
                        }
                        //                        // calculate directory size can be time-consuming
                        //                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                        //                            fileObj.directorySize = [FileItem folderSizeAtPath:path];
                        //                        });
                        NSArray *subFolderArray = [fileManager contentsOfDirectoryAtPath:path error:nil];
                        NSInteger subFolderCount = subFolderArray.count;
                        for (NSString *file in subFolderArray) {
                            NSString *realPathFile = [path stringByAppendingPathComponent:file];
                            BOOL isFolder = NO;
                            if ([fileManager fileExistsAtPath:realPathFile isDirectory:&isFolder]) {
                                if (!isFolder) {
                                    FileItem *fileObj = [[FileItem alloc] initWithPath:realPathFile modifiedDate:nil isFavorite:nil];
                                    fileObj.isFolder = NO;
                                    if (!fileObj.isValidPDF) {
                                        subFolderCount--;
                                    }
                                }
                            }
                        }
                        fileObj.fileSize = subFolderCount; //if directory, filesize means the number of items in sub directory.
                        [arrayFileList addObject:fileObj];
                    }
                } else //otherwise no need to add directory, but need to search key word recursively in all related files
                {
                    [FileBrowser getFileListWithFolderPath:path
                                         withSearchKeyword:searchKeyword
                                                  userData:userData
                                               withHandler:^(NSMutableArray *fileListArray) {
                                                   for (FileItem *objFileItem in fileListArray) {
                                                       if (![arrayFileList containsObject:objFileItem])
                                                           [arrayFileList addObject:objFileItem];
                                                   }
                                               }];
                }
            }
        } else {
            FileItem *fileObj = [[FileItem alloc] initWithPath:path modifiedDate:nil isFavorite:nil];
            if (searchKeyword != nil && searchKeyword.length > 0) {
                NSRange findRange = [fileObj.fileName rangeOfString:searchKeyword options:NSCaseInsensitiveSearch];
                if (findRange.length > 0) {
                    [arrayFileList addObject:fileObj];
                }
            } else {
                [arrayFileList addObject:fileObj];
            }
        }
    }

    if (handler) {
        handler(arrayFileList);
    }
}

@end
