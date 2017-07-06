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

#import <UIKit/UIKit.h>

#import "IFbFileDelegate.h"
#import "FbFileBrowser.h"
#import "ThumbnailScrollView.h"

@class FbFileItem;


@interface FileManageBaseViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIActionSheetDelegate,ThumbnailScrollViewActionDelegate, ThumbnailScrollViewSortDelegate, ThumbnailScrollViewSource>
{
    NSMutableArray *arrayFile;
    NSMutableArray *arraySelectedFilepaths;
    
    int selectedTypeIndex; 
    int selectedRowIndex;  //to pass selected row when renaming/deleting, otherwise it cannot get selected row after alert view show. this is used in not editing mode.
    NSString *searchKeyword;
    
    //for generate and display the thumbnail
    dispatch_queue_t queue;

    BOOL _reloading;
    BOOL _alertViewFinished;
    
    NSString *_unZipFolder;
    __block BOOL isUnzipOk;
    BOOL isCheckedUnzipError;
    BOOL _isEnableThumbnail;
    BOOL _isTouchModeFileOperation;
    BOOL _needReloadData;
}

@property (nonatomic, assign) FileSortType sortType;
@property (nonatomic, assign) FileSortMode sortMode;

@property (strong, nonatomic) IBOutlet UITableView *tableFileList;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (copy,   nonatomic) NSString *currentFolder;
@property (assign, nonatomic) FileListType currentTypeIndex;
@property (strong, nonatomic) IBOutlet ThumbnailScrollView *thumbnailFileList;
@property (assign, nonatomic) BOOL isEnableThumbnail;
@property (assign, nonatomic) int viewMode;
@property (nonatomic,unsafe_unretained)id<IFbFileDelegate> delegate;

@property (nonatomic, strong) UIView *searchBackground;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIButton *searchDone;
@property (nonatomic, assign) BOOL searchModel;

@property (nonatomic, assign) NSInteger selectedItemIndexForRename;

@property (nonatomic, strong) FbFileItem *fileItem;


#pragma mark - Public API

- (IBAction)buttonNavigationBackClick:(id)sender;

//clear the file list data and UI
- (void)clearData;
//load the file list for current type and search keyword
- (void)loadData;

//when file change, load data after a delay, otherwise the file size is not correct
- (void)loadDataForFileChange:(NSNotification *)notification;

#pragma mark - sort methods for this class and subclass

- (void)refreshSort;

#pragma mark - Check and need start or stop file monitor

- (void)needStartFileMonitor;
- (void)needStopFileMonitor;
#pragma mark - Protected override methods

- (void)setUIAccordingToData;
- (void)refreshInterface;

@end
