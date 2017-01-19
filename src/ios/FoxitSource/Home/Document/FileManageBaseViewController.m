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
#import "FileManageBaseViewController.h"
#import "FileManageListViewController.h"
#import "ThumbnailScrollViewCell.h"

#import "FbFileEnum.h"
#import "UIExtensionsSharedHeader.h"

#import "AppDelegate.h"
#import "Utility+Demo.h"

#import "Defines.h"

#define FILE_CHANGED                 @"FileChangedNotification"

@interface FileManageBaseViewController (PrivateAPI)

- (BOOL)checkDiskFile:(int)currentSelectRow;
- (void)setNavigationBarTitleForFolderName;
- (NSArray *)getFileObjectFromFileNames:(NSArray *)fileNames;

@end

@implementation FileManageBaseViewController

@synthesize tableFileList = _tableFileList;
@synthesize thumbnailFileList = _thumbnailFileList;
@synthesize activityIndicator = _activityIndicator;

@synthesize currentFolder= _currentFolder;
@synthesize currentTypeIndex= _currentTypeIndex;
@synthesize  isEnableThumbnail = _isEnableThumbnail;
@synthesize viewMode = _viewMode;
@synthesize selectedItemIndexForRename = _selectedItemIndexForRename;
@synthesize fileItem = _fileItem;


#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
        arrayFile = [[NSMutableArray alloc] init];
        arraySelectedFilepaths = [[NSMutableArray alloc] init];
        searchKeyword = nil;
        //monitor file change
        queue = dispatch_queue_create("FileManageQueue", NULL);
        _isTouchModeFileOperation = NO;
        _isEnableThumbnail = YES;
        // File view mode initialization
        _viewMode = -1;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (_isEnableThumbnail)
    {
        _tableFileList.hidden = YES;
        CGRect viewFrame = self.view.bounds;
        self.thumbnailFileList.frame = viewFrame;
        [self.thumbnailFileList setBackgroundColor:[UIColor whiteColor]];
        self.thumbnailFileList.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.thumbnailFileList.scrollEnabled = YES;
        self.thumbnailFileList.mainSuperView =  self.navigationController.view.superview.superview;
        self.thumbnailFileList.isSwapMode = NO;
        self.thumbnailFileList.isNeedShake = NO;
        self.thumbnailFileList.cellArrangement = ThumbnailScrollViewCellArrangementRight;
        [self.view addSubview:self.thumbnailFileList];
    }
    //pull to refresh
    if (_refreshHeaderView == nil) 
    {
        CGRect headerViewFrame = CGRectMake(0.0f, 0.0f - _tableFileList.bounds.size.height, self.view.frame.size.width, _tableFileList.bounds.size.height);
        if (_isEnableThumbnail)
        {
            headerViewFrame = CGRectMake(0.0f, 0.0f - _thumbnailFileList.bounds.size.height, self.view.frame.size.width, _thumbnailFileList.bounds.size.height);
        }
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:headerViewFrame];
		view.delegate = self;
		[_tableFileList addSubview:view];
        if (_isEnableThumbnail)
        {
            [view removeFromSuperview];
            [_thumbnailFileList addSubview:view];
        }
		_refreshHeaderView = view;
		[view release];
	}	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
    [self refreshInterface];
    [self setUIAccordingToData];
    _selectedItemIndexForRename = -1;
}

- (void)viewDidUnload
{
    [self setTableFileList:nil];
    [self setActivityIndicator:nil];
    [self setThumbnailFileList:nil];
    _refreshHeaderView = nil;  //_refreshHeaderView is retained by _tableFileList, so don't need to release it
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (ThumbnailScrollView *)thumbnailFileList
{
    if (!_thumbnailFileList)
    {
        ThumbnailScrollView *scrollView = [[ThumbnailScrollView alloc] init];
        _thumbnailFileList = [scrollView retain];
        _thumbnailFileList.delegate = self;
        _thumbnailFileList.actionDelegate = self;
        _thumbnailFileList.dataSource = self;
        _thumbnailFileList.sortDelegate = self;
        [scrollView release];
    }
    return _thumbnailFileList;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)dealloc 
{
    [arrayFile release];
    [arraySelectedFilepaths release];
    [searchKeyword release];
    //this fix the loadData crash problem. in navigation the viewController get released, so delay perform fail.
    _refreshHeaderView.delegate = nil; 
    _refreshHeaderView = nil;    //_refreshHeaderView is retained by _tableFileList, so don't need to release it, and it must be called before
    [_tableFileList release];
    [_activityIndicator release];
    [_currentFolder release];
    [_fileItem release];
    [_progressAlertView release];
    _thumbnailFileList.delegate = nil;
    _thumbnailFileList.dataSource = nil;
    _thumbnailFileList.sortDelegate = nil;
    _thumbnailFileList.actionDelegate = nil;
    [_thumbnailFileList release];
    dispatch_release(queue);
    
    [super dealloc];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.navigationController)
    {
        if (OS_ISVERSION7)
        {
            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        }
        if (!self.navigationItem.titleView)
        {
            if (DEVICE_iPHONE && !OS_ISVERSION6)
            {
                self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
                self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
            }
            
            UILabel *titleLabel= [[UILabel alloc] init];
            titleLabel.frame= CGRectMake(0.0f, 0.0f, self.navigationController.navigationBar.frame.size.width, 44.0f);
            titleLabel.text= self.title;
            titleLabel.textAlignment= NSTextAlignmentCenter;
            titleLabel.autoresizesSubviews= YES;
            titleLabel.backgroundColor= [UIColor clearColor];
            titleLabel.textColor= [UIColor whiteColor];
            titleLabel.shadowColor= [UIColor darkGrayColor];
            titleLabel.shadowOffset= CGSizeMake(0.0f, -1.0f);
            titleLabel.font= [UIFont boldSystemFontOfSize:18.0f];
            [titleLabel sizeToFit];
            self.navigationItem.titleView= titleLabel;
            [titleLabel release];
        }
    }
    
    if (_fileItem != nil && DEMO_APPDELEGATE.isFileEdited)
    {
        DEMO_APPDELEGATE.isFileEdited = NO;
    }
}

#pragma mark - Properties

- (NSString *)currentFolder
{
    if (!_currentFolder)
    {
        NSString *path = DOCUMENT_PATH;
        self.currentFolder = path;
    }

    return _currentFolder;
}

#pragma mark - UINavigationController delegate handler
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (![viewController.navigationItem respondsToSelector:@selector(setRightBarButtonItems:)]) //iOS 4
    {
        [viewController viewWillAppear:animated];
    }
    if (navigationController.navigationBar.tag != 1)
    {
        navigationController.navigationBar.tag = 1;
        //[navigationController.navigationBar refreshBackground];
    }
}

#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{	
    [_refreshHeaderView adjustImageFrame];
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{	
	[self loadData];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return _reloading; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
    return nil;
}

//#pragma mark -  table view delegate and datasource handler
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - sort methods for this class and subclass

- (void)refreshSort
{
    [arrayFile sortUsingComparator:^NSComparisonResult(id obj1, id obj2)
     {
         FbFileItem *fileObj1= (FbFileItem *)obj1;
         FbFileItem *fileObj2= (FbFileItem *)obj2;
         if (fileObj1.isFolder != fileObj2.isFolder)
         {
             return fileObj1.isFolder?NSOrderedAscending:NSOrderedDescending;
         }
         else
         {
             NSComparisonResult compareResult= NSOrderedSame;
             if (self.sortType == FileSortType_Name)
             {
                 if (([fileObj1.fileName rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) && ([fileObj2.fileName rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound))
                 {
                     compareResult= [fileObj1.fileName compare:fileObj2.fileName options:NSNumericSearch];
                 }
                 else
                 {
                     compareResult= [fileObj1.fileName compare:fileObj2.fileName options:NSCaseInsensitiveSearch];
                 }
             }
             else if (self.sortType == FileSortType_Date)
             {
                 compareResult= [fileObj1.modifiedDate compare:fileObj2.modifiedDate];
             }
             else if (self.sortType == FileSortType_Size)
             {
                 if (fileObj1.fileSize != fileObj2.fileSize)
                 {
                     compareResult= fileObj1.fileSize < fileObj2.fileSize?NSOrderedAscending:NSOrderedDescending;
                 }
             }
             else if (self.sortType == FileSortType_LastView)
             {
                 compareResult = [fileObj1.lastViewDate compare:fileObj2.lastViewDate];
             }
             if (compareResult != NSOrderedSame && self.sortMode == FileSortMode_Descending)
             {
                 compareResult = compareResult == NSOrderedAscending?NSOrderedDescending:NSOrderedAscending;
             }
             return compareResult;
         }
     }];
}

#pragma mark - Public API

- (void)clearData
{
    [arrayFile removeAllObjects];
    if (_isEnableThumbnail)
    {
        [_thumbnailFileList reloadData];
    }
    else
    {
        [_tableFileList reloadData];
    }
}

- (void)loadData
{
    _reloading = YES;
    //get data first
    [_activityIndicator startAnimating];
    NSString *path = self.currentFolder;
    NSMutableDictionary *dictUserData = nil;
    [FbFileBrowser _getFileListForType:self.currentTypeIndex
                        withFolder:path 
                 withSearchKeyword:searchKeyword 
              withParentFileObject:nil
                          userData:dictUserData
                       withHandler:^(NSMutableArray *fileListArray)
                         {
                             [_activityIndicator stopAnimating];
                             [arrayFile release];     
                             NSArray *fileList = [fileListArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) 
                                                 {
                                                     FbFileItem *fileObj1= (FbFileItem *)obj1;
                                                     FbFileItem *fileObj2= (FbFileItem *)obj2;
                                                     if (fileObj1.isFolder != fileObj2.isFolder)
                                                     {
                                                         return fileObj1.isFolder ? NSOrderedAscending:NSOrderedDescending;
                                                     }
                                                     else
                                                     {
                                                         NSComparisonResult compareResult = NSOrderedSame;
                                                         if (self.sortType == FileSortType_Name)
                                                         {
                                                             if (([fileObj1.fileName rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) && ([fileObj2.fileName rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound))
                                                             {
                                                                 compareResult= [fileObj1.fileName compare:fileObj2.fileName options:NSNumericSearch];
                                                             }
                                                             else
                                                             {
                                                                 compareResult= [fileObj1.fileName compare:fileObj2.fileName options:NSCaseInsensitiveSearch];
                                                             }
                                                         }
                                                         else if (self.sortType == FileSortType_Date)
                                                         {
                                                             compareResult= [fileObj1.modifiedDate compare:fileObj2.modifiedDate];
                                                         }
                                                         else if (self.sortType == FileSortType_Size)
                                                         {
                                                             if (fileObj1.fileSize != fileObj2.fileSize)
                                                             {
                                                                 compareResult= fileObj1.fileSize < fileObj2.fileSize?NSOrderedAscending:NSOrderedDescending;
                                                             }
                                                         }
                                                         else if (self.sortType == FileSortType_LastView)
                                                         {
                                                             compareResult = [fileObj2.lastViewDate compare:fileObj1.lastViewDate];
                                                         }
                                                         if (compareResult != NSOrderedSame && self.sortMode == FileSortMode_Descending)
                                                         {
                                                             compareResult= compareResult == NSOrderedAscending?NSOrderedDescending:NSOrderedAscending;
                                                         }
                                                         return compareResult;
                                                     }
                                                 }];
                             arrayFile= [[NSMutableArray alloc] initWithArray:fileList];
                            //refresh UI accordingly
                             if (!_isEnableThumbnail)
                             {
                                [_tableFileList reloadData];
                             }
                             else
                             {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [_thumbnailFileList reloadData];
                                 });
                             }
                            _reloading = NO; 

                             if (_isEnableThumbnail)
                             {
                                 [_refreshHeaderView performSelector:@selector(egoRefreshScrollViewDataSourceDidFinishedLoading:) withObject:_thumbnailFileList afterDelay:0.1];
                             }
                             else
                             {
                                 [_refreshHeaderView performSelector:@selector(egoRefreshScrollViewDataSourceDidFinishedLoading:) withObject:_tableFileList afterDelay:0.1];
                             }
                        }];
}

//when file change, load data after a delay, otherwise the file size is not correct
- (void)loadDataForFileChange:(NSNotification *)notification
{
    //only when changed folder is current folder's sub-folder, need to load data: 1. update current list; 2. update current folder's item number
    //if the change folder is above current folder, not need to refresh as it will do when navigate back
    NSString *directory = notification.object;
    if ([directory rangeOfString:self.currentFolder].location == 0)
    {
        //the local file change event can happen multiple times, so that multiple notification posted. 
        //but only the last one will be executed
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadData) object:nil];
        if (_thumbnailFileList.isMoving)
        {
            _needReloadData = YES;
        }
        else
        {
            [self performSelector:@selector(loadData) withObject:nil afterDelay:5.0];
        }
    }
}

- (BOOL)getValidFloderWithContentsOfDirectory:(NSString *)directoryPath
{
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:directoryPath];
    NSString *fileName = nil;
    BOOL isDir = YES;
    while ((fileName = [dirEnumerator nextObject])) {
        
        NSString *fullFilePath = [directoryPath stringByAppendingPathComponent:fileName];
        [fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir];
        if (!isDir)
        {
            return YES;
            
        } else
        {
            isDir = NO;
        }
        
    }
    BOOL isDirectory = YES;
    [[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDirectory];
    if (isDir)
    {
        return isDirectory ? NO : YES;
        
    } else
    {
        return NO;
    }
    
}


#pragma mark - Protected override methods

//FileManageViewController is especially driven by data, as it will open outside file and the UI must rest according to data.
- (void)setUIAccordingToData
{
    //nothing to do here. set UI in child class.
    [self setNavigationBarTitleForFolderName];
}

- (void)refreshInterface
{
    _searchBar.placeholder = NSLocalizedString(@"kSearchPlaceholder", nil);
}

#pragma mark - Private API

- (BOOL)checkDiskFile:(int)currentSelectRow
{
    FbFileItem *selectedFile = [arrayFile objectAtIndex:currentSelectRow]; 
    NSArray *selectedRows = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:currentSelectRow inSection:0]];
    //check the file exist and the modified date is same as selected one
    
    FbFileItem *diskFile = [[[FbFileItem alloc] initWithPath:selectedFile.path modifiedDate:nil isFavorite:nil] autorelease];
    if(!diskFile.isValidPDF)  //cannot find the file in this path
    {
        AlertView *alertView = [[[AlertView alloc] initWithTitle:@"kWarning" message:[NSString stringWithFormat:NSLocalizedString(@"kNoFileInDisk", nil), selectedFile.fileName] buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil] autorelease];
        [alertView show];
        [arrayFile removeObject:selectedFile];
        if (_isEnableThumbnail)
        {
            [_thumbnailFileList reloadData];
        }
        else
        {
            [_tableFileList deleteRowsAtIndexPaths:selectedRows withRowAnimation:UITableViewRowAnimationFade];
            [_tableFileList reloadData];
        }
        return NO;
    }
    if(![diskFile.modifiedDate isEqualToDate:selectedFile.modifiedDate])  //modified date is not the same, means it's not the same file. update list.
    {
        [arrayFile replaceObjectAtIndex:currentSelectRow withObject:diskFile];
        if (_isEnableThumbnail)
        {
            [_thumbnailFileList reloadCellAtIndex:currentSelectRow withAnimation:ThumbnailScrollViewCellAnimationFade];
        }
        else
        {
            [_tableFileList reloadRowsAtIndexPaths:selectedRows withRowAnimation:UITableViewRowAnimationFade];
        }
        return YES;
    }
    return YES;
}

- (void)setNavigationBarTitleForFolderName
{
    if ([[self.currentFolder lastPathComponent] isEqualToString:@"Documents"])
    {
        self.title = NSLocalizedString(@"kDocuments", nil);
    }
    else
    {
        {
            self.title = [self.currentFolder lastPathComponent];
        }
    }
}

- (NSArray *)getFileObjectFromFileNames:(NSArray *)fileNames
{
    NSMutableArray *fileObjects=[[NSMutableArray alloc] init];
    for (NSString *file in fileNames)
    {
        FbFileItem *fileObject= [[FbFileItem alloc] initWithPath:file modifiedDate:nil isFavorite:nil];
        [fileObjects addObject:fileObject];
        [fileObject release];
    }
    return (NSArray *)[fileObjects autorelease];
}

#pragma mark - Check button on alertView

- (void)addCheckButtonForAlertView:(UIAlertView *)alertView buttonTitle:(NSString *)buttonTitle
{
    UIImage *image= [UIImage imageNamed:@"common_redio_blank"];
    UIButton *buttonCheck= [[UIButton alloc] initWithFrame:CGRectMake(20.0f, 75.0f, 100.0, 30.0f)];
    [buttonCheck setTitle:buttonTitle forState:UIControlStateNormal];
    [buttonCheck setImage:image forState:UIControlStateNormal];
    image= [UIImage imageNamed:@"common_redio_selected"];
    [buttonCheck setImage:image forState:UIControlStateHighlighted];
    [buttonCheck setImage:image forState:UIControlStateSelected];
    buttonCheck.tag= 200;
    [buttonCheck addTarget:self action:@selector(buttonCheckOfAlertViewClick:) forControlEvents:UIControlEventTouchUpInside];
    [alertView addSubview:buttonCheck];
    [buttonCheck release];    
}

- (void)buttonCheckOfAlertViewClick:(UIButton *)sender
{
    sender.selected= !sender.selected;
}
#pragma mark - Check and need start or stop file monitor

- (void)needStartFileMonitor
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FILE_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDataForFileChange:) name:FILE_CHANGED object:nil];
}

- (void)needStopFileMonitor
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadData) object:nil];
}

#pragma mark - public event handler
- (IBAction)buttonNavigationBackClick:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - ThumbnailScrollView data source

- (int)numberOfItemsInThumbnailScrollView:(ThumbnailScrollView *)scrollView
{
    return (int)arrayFile.count;
}

- (CGSize)sizeForCellsInThumbnailScrollView:(ThumbnailScrollView *)scrollView
{
    if (_viewMode == 0) //listview mode
    {
        return CGSizeMake(scrollView.bounds.size.width, 68.0f);
    }
    return DEVICE_iPHONE ? CGSizeMake(87.0f, 135.0f) : CGSizeMake(134.f, 184.0f);
}


- (ThumbnailScrollViewCell *)thumbnailScrollView:(ThumbnailScrollView *)scrollView cellAtIndex:(NSInteger)index
{
	NSAssert(false, @"cellAtIndex in base class FileManageBaseViewController should not be called");
    return nil;
}

- (int)thumbnailScrollView:(ThumbnailScrollView *)scrollView numberPagesOfOneRowInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (_viewMode == 0)
    {
        return 1;
    }
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        if (DEVICE_iPHONE)
        {
            ScreenSizeMode sizeMode = [Utility getScreenSizeMode];
            if (sizeMode == ScreenSizeMode_55)
            {
                return 4;
            }
            else
            {
                return 3;
            }
        }
        else
        {
            return 5;
        }
    }
    else
    {
        if (DEVICE_iPHONE)
        {
            ScreenSizeMode sizeMode = [Utility getScreenSizeMode];
            if (sizeMode == ScreenSizeMode_40)
            {
                return 5;
            }
            else if (sizeMode == ScreenSizeMode_47 || sizeMode == ScreenSizeMode_55)
            {
                return 6;
            }
            else
            {
                return 4;
            }
        }
        else
        {
            return 6;
        }
    }
}

- (UIEdgeInsets)thumbnailScrollView:(ThumbnailScrollView *)scrollView contentMarginsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (_viewMode == 0)
    {
        return UIEdgeInsetsMake(0, 0.0f, 44.0f, 0.0f);
    }
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        return DEVICE_iPHONE ? UIEdgeInsetsMake(0, ([Utility getScreenSizeMode] == ScreenSizeMode_55 ? 16.0f : 16.0f), 44, 0.0) : UIEdgeInsetsMake(0, 15.0f, 44, 0.0);
    }
    else
    {
        return DEVICE_iPHONE ? UIEdgeInsetsMake(0, ([Utility getScreenSizeMode] == ScreenSizeMode_35 ? 12.0f : 35.0f), 44, ([Utility getScreenSizeMode] == ScreenSizeMode_35 ? 5 : 0)) : UIEdgeInsetsMake(0, 0.0f, 44.0f, 0.0f);
    }
}

- (UIEdgeInsets)thumbnailScrollView:(ThumbnailScrollView *)scrollView pageMarginsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (_viewMode == 0)
    {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        if (DEVICE_iPHONE)
        {
            ScreenSizeMode sizeMode = [Utility getScreenSizeMode];
            if (sizeMode == ScreenSizeMode_47)
            {
                return UIEdgeInsetsMake(5, 11, 5, 11);
            }
            else if (sizeMode == ScreenSizeMode_55)
            {
                return UIEdgeInsetsMake(5, 5, 5, 2);
            }
            else
            {
                return UIEdgeInsetsMake(5, 3, 5, 3);
            }
        }
        else
        {
            return UIEdgeInsetsMake(10.0f, 8.0f, 5.0f, 5.0f);
        }
    }
    else
    {
        if (DEVICE_iPHONE)
        {
            ScreenSizeMode sizeMode = [Utility getScreenSizeMode];
            if (sizeMode == ScreenSizeMode_40)
            {
                return UIEdgeInsetsMake(5, 10, 5, 3);
            }
            else if (sizeMode == ScreenSizeMode_47)
            {
                return UIEdgeInsetsMake(5, 7, 5, 5);
            }
            else if (sizeMode == ScreenSizeMode_55)
            {
                return UIEdgeInsetsMake(5, 12, 5, 12);
            }
            else
            {
                return UIEdgeInsetsMake(5, 7, 5, 12);
            }
        }
        else
        {
            return UIEdgeInsetsMake(10.0f, 18.0f, 5.0f, 18.0f);
        }
    }
}

#pragma mark - ThumbnailScrollView delegate

- (BOOL)shouldSortInThumbnailScrollView:(ThumbnailScrollView *)scrollView cellIndex:(int)cellIndex
{
    BOOL _needSort = YES;
    if (_needSort)
    {
        FoxitLog(@"stop file monitor");
        [self needStopFileMonitor];
    }
    return _needSort;
}

-(void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didCancelSortCellIndexes:(NSArray *)cellIndexes blankCellIndex:(NSInteger)blankCellIndex
{
    FoxitLog(@"start file monitor-didCancel");
    if (_needReloadData)
    {
        FoxitLog(@"need reload data");
        _needReloadData = NO;
        [self loadData];
    }
    [self needStartFileMonitor];
}

-(void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didTapOnCellAtIndex:(NSInteger)index
{
    [_fileItem release], _fileItem = nil;
    FbFileItem *openingFile = [arrayFile objectAtIndex:index];
    if (!openingFile.isFolder)
    {
        if(!_thumbnailFileList.editing && !openingFile.isOpen)  //open selected file if it's not opened yet
        {
            if([self checkDiskFile:(int)index])
            {
                FbFileItem *openingFile = [arrayFile objectAtIndex:index];
                //find if there is file ready open
                FbFileItem *openedFile = nil;
                for(FbFileItem *obj in arrayFile)
                {
                    if(obj.isOpen)
                    {
                        openedFile = obj;
                        break;
                    }
                }
                if(openedFile != nil)
                    openedFile.isOpen = NO;

                //refresh UI
                if (_isEnableThumbnail)
                    [_thumbnailFileList reloadData];
                else
                    [_tableFileList reloadData];

                if ([self.delegate conformsToProtocol:@protocol(IFbFileDelegate)] && [self.delegate respondsToSelector:@selector(onItemCliked:)])
                {
                    [self.delegate onItemCliked:openingFile];
                    _fileItem = [openingFile retain];
                }
            }
        }
    }
}

@end
