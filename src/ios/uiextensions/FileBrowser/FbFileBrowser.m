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

#import "FbFileBrowser.h"
#import "FileManageListViewController.h"
#import "FbFileEnum.h"
#import "FbFileItem.h"
#import "Utility.h"
#import "TbBaseBar.h"


@interface FbFileBrowser ()

@property (nonatomic,unsafe_unretained)BOOL isEditing;
@property (nonatomic,strong)FileManageListViewController *fileListView;
@property (nonatomic,strong) NSMutableArray *arrayFileLists;
@property (nonatomic,strong)NSMutableArray *arraySelectedItems;
@property (nonatomic,strong)UINavigationController *naviController;
@property (nonatomic,strong)TbBaseBar *topBar;
@property (nonatomic,assign)BOOL isShowFavorite;
@end


@implementation FbFileBrowser

- (void)initializeViewWithDelegate:(id<IFbFileDelegate>)delegate fileListType:(FileListType)type
{
    NSBundle *bundle = nil;
    NSString* nibName = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? @"FileManageViewController_iPhone" : @"FileManageListViewController_iPad";
    _fileListView = [[FileManageListViewController alloc] initWithNibName:nibName bundle:bundle];
    _fileListView.delegate = delegate;
    _fileListView.currentTypeIndex = type;
    _fileListView.sortType = self.sortType;
    _fileListView.sortMode = self.sortMode;
    _naviController = [[UINavigationController alloc] initWithRootViewController:_fileListView];
    _naviController.navigationBarHidden = YES;
}

- (void)changeThumbnailFrame:(BOOL)change
{
    for (UIViewController *viewCon in _fileListView.navigationController.viewControllers)
    {
        if (viewCon != _fileListView)
        {
             [(FileManageListViewController *)viewCon changeThumbnailFrame:change];
        }
    }
   
}

- (void)sortFileByType:(FileSortType)sortType andFileSortMode:(FileSortMode)sortMode
{
    FileManageListViewController *currentViewcon = ( FileManageListViewController *)_fileListView.navigationController.topViewController;
    [currentViewcon sortFileByType:sortType andFileSortMode:sortMode];
}

- (void)updateDataSource:(NSMutableArray *)dataSource
{
}

- (BOOL)isEditState
{
    return NO;
}

- (NSArray *)getCheckedItems
{
    return self.arraySelectedItems;
}

- (UIView *)getContentView
{
    return _naviController.view;
}

- (UINavigationController *)getNaviController
{
    return _naviController;
}

- (NSArray *)getDataSource:(NSString *)path
{
    return nil;
}

- (void)switchStyle
{
    FileManageListViewController *currentViewcon = ( FileManageListViewController *) _fileListView.navigationController.topViewController;
    [currentViewcon buttonChangeViewMode];
}

static NSArray* removeSystemFiles(NSArray* array, BOOL isRoot)
{
    return [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSString* path = evaluatedObject;
        return ![path.pathExtension.lowercaseString isEqualToString:@".plist"]
        && ![path.lowercaseString isEqualToString:@".plist"]
        && !(isRoot && [path isEqualToString:@"Inbox"])
        && ![path.lowercaseString isEqualToString:@".DS_Store".lowercaseString]
        && ![path isEqualToString:@".IntuneMAM".lowercaseString];
    }]];
}

- (void)getFileListForType:(FileListType)type withFolderPath:(NSString *)folder withSearchKeyword:(NSString *)searchKeyword withParentFileObject:(id)parentFileObject userData:(NSDictionary *)userData withHandler:(getFileListHandler)handler
{
    searchKeyword = [searchKeyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (self.arrayFileLists == nil)
        self.arrayFileLists = [[NSMutableArray alloc] init];
    
    //get list from local document
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *array = [fileManager contentsOfDirectoryAtPath:folder error:nil];//cannot use enumeratorAtPath: as it will list the subdirectories
    array = removeSystemFiles(array, YES);
    BOOL isFolder = NO;
    for(NSString * fileName in array)
    {
        NSString* path = [([folder isEqualToString:DOCUMENT_PATH])?DOCUMENT_PATH:folder stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:path isDirectory:&isFolder] && isFolder)  //If it is directory
        {
            //Removing the temporary directory of zip and zip
            if (!([folder isEqualToString:DOCUMENT_PATH] && ([path.lastPathComponent isEqualToString:@".unziptempfolder"] || [path.lastPathComponent isEqualToString:@".ziptempfolder"])))
            {
                //If you search for a keyword is empty you need to add Catalog
                if (searchKeyword == nil || [searchKeyword isEqualToString:@""])
                {
                    {
                        FbFileItem *fileObj = [[FbFileItem alloc] initWithPath:path modifiedDate:nil isFavorite:nil];
                        fileObj.isFolder = isFolder;
                        fileObj.path = path;
                        fileObj.fileName = 
                        [path lastPathComponent]; //if directory, set file name to directory name
                        fileObj.fileExt = nil;
                        NSDictionary *fileAttribute = [fileManager attributesOfItemAtPath:path error:nil];
                        if (fileAttribute != nil)
                        {
                            fileObj.modifiedDate = [fileAttribute fileModificationDate];
                        }
//                        // calculate directory size can be time-consuming
//                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//                            fileObj.directorySize = [FbFileItem folderSizeAtPath:path];
//                        });
                        NSArray *subFolderArray = [fileManager contentsOfDirectoryAtPath:path error:nil];
                        NSInteger subFolderCount = subFolderArray.count;
                        for (NSString *file in subFolderArray)
                        {
                            NSString *realPathFile = [path stringByAppendingPathComponent:file];
                            BOOL isFolder = NO;
                            if ([fileManager fileExistsAtPath:realPathFile isDirectory:&isFolder])
                            {
                                if (!isFolder)
                                {
                                    FbFileItem *fileObj = [[FbFileItem alloc] initWithPath:realPathFile modifiedDate:nil isFavorite:nil];
                                    fileObj.isFolder = NO;
                                    if (!fileObj.isValidPDF)
                                    {
                                        subFolderCount--;
                                    }
                                                                    }
                            }
                        }
                        fileObj.fileSize = subFolderCount; //if directory, filesize means the number of items in sub directory.
                        [self.arrayFileLists addObject:fileObj];
                                            }
                }
                else //otherwise no need to add directory, but need to search key word recursively in all related files
                {
                    [self getFileListForType:type
                              withFolderPath:path
                           withSearchKeyword:searchKeyword
                        withParentFileObject:nil
                                    userData:userData
                                 withHandler:^(NSMutableArray *fileListArray)
                     {
                         for (FbFileItem * objFbFileItem  in fileListArray)
                         {
                             if (![self.arrayFileLists containsObject:objFbFileItem])
                                 [self.arrayFileLists addObject:objFbFileItem];
                         }
                     }];
                }
            }
        }
        else
        {
            FbFileItem *fileObj = [[FbFileItem alloc] initWithPath:path modifiedDate:nil isFavorite:nil];
            if(searchKeyword != nil && searchKeyword.length > 0)
            {
                NSRange findRange = [fileObj.fileName rangeOfString:searchKeyword options:NSCaseInsensitiveSearch];
                if(findRange.length > 0)
                {
                    [self.arrayFileLists addObject:fileObj];
                }
            }
            else
            {
                [self.arrayFileLists addObject:fileObj];
            }
                    }
    }
        
    if(handler)
    {
        handler(self.arrayFileLists);
    }
}

+ (void)_getFileListForType:(FileListType)type withFolder:(NSString *)folder withSearchKeyword:(NSString *)searchKeyword withParentFileObject:(FbFileItem *)parentFileObject userData:(NSDictionary *)userData withHandler:(getFileListHandler)handler
{
	searchKeyword = [searchKeyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSMutableArray *arrayFileList = [[NSMutableArray alloc] init];
    
    //get list from local document
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *array = [fileManager contentsOfDirectoryAtPath:folder error:nil]; //cannot use enumeratorAtPath: as it will list the subdirectories
    array = removeSystemFiles(array, [folder isEqualToString:DOCUMENT_PATH]);
    //if parent folder is not Documents, it means a sub folder and need to add "..." as parent folder
    if (parentFileObject)
    {
        FbFileItem *fileObj = [[FbFileItem alloc] initWithPath:folder modifiedDate:nil isFavorite:nil];
        fileObj.isFolder = YES;
        fileObj.fileName = @"..";
        fileObj.fileExt = nil;
        fileObj.fileSize = parentFileObject.fileSize;
        [arrayFileList addObject:fileObj];
            }
    BOOL isFolder = NO; //Is directory
    for(NSString *fileName in array)
    {
        NSString *path = [folder stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:path isDirectory:&isFolder] && isFolder) //If it is directory
        {
            //Removing the temporary directory of zip and zip
            if (!([folder isEqualToString:DOCUMENT_PATH] && ([path.lastPathComponent isEqualToString:@".unziptempfolder"] || [path.lastPathComponent isEqualToString:@".ziptempfolder"])))
            {
                //If you search for a keyword is empty you need to add Catalog
                if (searchKeyword == nil || [searchKeyword isEqualToString:@""])
                {
                    
                    {
                        FbFileItem *fileObj = [[FbFileItem alloc] initWithPath:path modifiedDate:nil isFavorite:nil];
                        fileObj.isFolder = isFolder;
                        fileObj.path = path;
                        fileObj.fileName = [path lastPathComponent]; //if it is a folder, set file name to folder name
                        fileObj.fileExt = nil;
                        NSDictionary *fileAttribute = [fileManager attributesOfItemAtPath:path error:nil];
                        if (fileAttribute != nil)
                        {
                            fileObj.modifiedDate = [fileAttribute fileModificationDate];
                        }
//                        // calculate directory size can be time-consuming
//                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//                            fileObj.directorySize = [FbFileItem folderSizeAtPath:path];
//                        });
                        NSArray *subFolderArray = [fileManager contentsOfDirectoryAtPath:path error:nil];
                        NSInteger subFolderCount = subFolderArray.count;
                        for (NSString *file in subFolderArray)
                        {
                            NSString *realPathFile = [path stringByAppendingPathComponent:file];
                            BOOL isFolder = NO;
                            if ([fileManager fileExistsAtPath:realPathFile isDirectory:&isFolder])
                            {
                                if (!isFolder)
                                {
                                    FbFileItem *fileObj = [[FbFileItem alloc] initWithPath:realPathFile modifiedDate:nil isFavorite:nil];
                                    fileObj.isFolder = NO;
                                    if (!fileObj.isValidPDF)
                                    {
                                        subFolderCount--;
                                    }
                                                                    }
                            }
                        }
                        fileObj.fileSize = subFolderCount; //if folder, filesize means the number of items in sub directory
                        [arrayFileList addObject:fileObj];
                                            }
                }
                else //otherwise no need to add directory, but need to search key word recursively in all related files
                {
                    
                    [[FbFileBrowser alloc] getFileListForType:type
                                               withFolderPath:path
                                            withSearchKeyword:searchKeyword
                                         withParentFileObject:nil
                                                     userData:userData
                                                  withHandler:^(NSMutableArray *fileListArray)
                     {
                         for (FbFileItem * objFbFileItem  in fileListArray)
                         {
                             if (![arrayFileList containsObject:objFbFileItem])
                                 [arrayFileList addObject:objFbFileItem];
                         }
                     }];
                }
            }
        }
        else
        {
            if([Utility isPDFPath:path])
            {
                FbFileItem *fileObj = [[FbFileItem alloc] initWithPath:path modifiedDate:nil isFavorite:nil];
                fileObj.isFolder = NO;
                if(fileObj.isValidPDF)
                {
                    if(searchKeyword != nil && searchKeyword.length > 0)
                    {
                        NSRange findRange = [fileObj.fileName rangeOfString:searchKeyword options:NSCaseInsensitiveSearch];
                        if(findRange.length > 0)
                        {
                            [arrayFileList addObject:fileObj];
                        }
                    }
                    else
                    {
                        [arrayFileList addObject:fileObj];
                    }
                }
                            }
            else
            {
                //Ignore non PDF files.
            }
        }
    }
        
    if(handler)
	{
		handler(arrayFileList);
	}
    }

@end
