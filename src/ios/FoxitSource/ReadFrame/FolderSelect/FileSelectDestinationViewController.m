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

#import "FileSelectDestinationViewController.h"
#import "FbFileItem.h"
#import "FbFileBrowser.h"

@implementation FileItem

-(void)dealloc
{
    [_title release];
    [_filekey release];
    
    [super dealloc];
}

@end


@implementation FileViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.fileTypeImage = [[UIImageView alloc] initWithFrame:CGRectMake(DEVICE_iPHONE?0:10, 0, 40, 40)];
        self.previousImage = [[UIImageView alloc] initWithFrame:CGRectMake(DEVICE_iPHONE?0:10, 0, 18, 18)];
        self.previousImage.image = [UIImage imageNamed:@"document_path_back"];
        self.previousImage.center = CGPointMake(DEVICE_iPHONE?14:24, self.bounds.size.height/2);
        
        self.backName = [[UILabel alloc] initWithFrame:CGRectMake(DEVICE_iPHONE?30:40, 0, 200, 40)];
        self.backName.textColor = [UIColor colorWithRed:23.f/255.f green:156.f/255.f blue:216.f/255.f alpha:1];
        self.backName.center = CGPointMake(self.backName.center.x, self.bounds.size.height/2);
        self.backName.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        self.folderName = [[UILabel alloc] initWithFrame:CGRectMake(DEVICE_iPHONE?50:60, 0, 200, 40)];
        self.fileSelectImage = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width-26, 0, 26, 26)];
        self.fileSelectImage.image = [UIImage imageNamed:@"document_cellfile_selected"];
        self.fileTypeImage.center = CGPointMake(DEVICE_iPHONE?25:35, self.bounds.size.height/2);
        self.fileSelectImage.center = CGPointMake(self.fileSelectImage.center.x, self.bounds.size.height/2);
        self.folderName.center = CGPointMake(self.folderName.center.x, self.bounds.size.height/2);
        self.fileTypeImage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.folderName.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.fileSelectImage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        self.previousImage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        self.separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.contentView.frame.size.height-1, self.contentView.frame.size.width, [Utility realPX:1.0f])];
        self.separatorLine.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
        self.separatorLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        
        [self.contentView addSubview:self.fileTypeImage];
        [self.contentView addSubview:self.folderName];
        [self.contentView addSubview:self.fileSelectImage];
        [self.contentView addSubview:self.previousImage];
        [self.contentView addSubview:self.backName];
        [self.contentView addSubview:self.separatorLine];
        
        self.fileSelectImage.hidden = YES;
        self.contentView.autoresizesSubviews = YES;
    }
    return self;
}

- (void)dealloc
{
    [_fileTypeImage release];
    [_previousImage release];
    [_folderName release];
    [_backName release];
    [_fileSelectImage release];
    [_separatorLine release];
    
    [super dealloc];
}

@end

@interface FileSelectDestinationViewController ()
{
    UILabel * lblInstructionMsg;
}
@property (nonatomic, retain)NSMutableArray *selectedArray;
@property (nonatomic,retain)NSString *currentDirectoryPath;
- (void)loadFilesWithPath:(NSString *)filePath;
@end

@implementation FileSelectDestinationViewController

#pragma mark - Initialization
- (instancetype)init
{
    if (self = [super init])
    {
        self.fileItemsArray = [NSMutableArray array];
        self.selectedArray = [NSMutableArray array];
    }
    return self;
}

#pragma mark - View lifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationHandleOpenURL:) name:NOTIFICATION_NAME_APP_HANDLE_OPEN_URL object:nil];

    self.tableViewFolders = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableViewFolders.delegate = self;
    self.tableViewFolders.dataSource = self;
    self.tableViewFolders.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableViewFolders];
    if (self.fileOperatingMode == FileListMode_Copy || self.fileOperatingMode == FileListMode_Move || self.fileOperatingMode == FileListMode_Select)
        [self configureInstructionMessage];
    [self initNavigationBar];
    [self refreshInterface];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (DEMO_APPDELEGATE.pdfViewCtrl.currentDoc) {
        [DEMO_APPDELEGATE.pdfViewCtrl registerDocEventListener:self];
    }
    if (self.fileItemsArray.count == 0)
        [lblInstructionMsg setHidden:NO];
    else if (!self.isRootFileDirectory && self.fileItemsArray.count == 1)
        [lblInstructionMsg setHidden:NO];
    else
        [lblInstructionMsg setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [DEMO_APPDELEGATE.pdfViewCtrl unregisterDocEventListener:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_APP_HANDLE_OPEN_URL object:nil];
}

#pragma mark - UI configuration
- (void) configureInstructionMessage
{
    NSString *msg = @"";
    switch (self.fileOperatingMode)
    {
        case FileListMode_Copy:
            msg = @"kCopyHelp";
            break;
            
        case FileListMode_Move:
            msg = @"kMoveHelp";
            break;
            
        case FileListMode_Select:
            msg = @"kOKHelp";
            break;
            
        default:
            break;
    }
    
    CGSize titleSize = [Utility getTextSize:NSLocalizedString(msg, nil) fontSize:20.0f maxSize:CGSizeMake(SCREENWIDTH - 60, 100)];
    
    if (lblInstructionMsg == nil)
    {
        lblInstructionMsg = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleSize.width+3, titleSize.height)];
        lblInstructionMsg.center = CGPointMake(SCREENWIDTH/2, SCREENHEIGHT/2);
        lblInstructionMsg.textAlignment = NSTextAlignmentCenter;
        lblInstructionMsg.numberOfLines = 0;
        lblInstructionMsg.text = NSLocalizedString(msg, nil);
        lblInstructionMsg.font = [UIFont systemFontOfSize:20.0f];
        lblInstructionMsg.textColor = [UIColor blackColor];
        [self.view addSubview:lblInstructionMsg];
    }
    else
    {
        lblInstructionMsg.frame = CGRectMake(0, 0, titleSize.width+3, titleSize.height);
        lblInstructionMsg.center = CGPointMake(SCREENWIDTH/2, SCREENHEIGHT/2);
    }
}
- (void)refreshInterface
{
    self.tableViewFolders.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableViewFolders.backgroundColor = [UIColor whiteColor];
    self.tableViewFolders.backgroundView = [[[UIView alloc] init] autorelease];

    UIView *view = [[[UIView alloc]init] autorelease];
    view.backgroundColor = [UIColor clearColor];
    [self.tableViewFolders setTableFooterView:view];
}

#pragma mark - Configure NavigationBar
- (void)initNavigationBar
{
    UIButton* buttonLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonLeft.frame = CGRectMake(0.0, 0.0, 65.0, 32);
    buttonLeft.titleLabel.font = [UIFont systemFontOfSize:DEVICE_iPHONE?15.0f:18.0f];
    [buttonLeft setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [buttonLeft setTitle:NSLocalizedString(@"kCancel", nil) forState:UIControlStateNormal];
    [buttonLeft addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.buttonDone = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    [self.buttonDone setTintColor:[UIColor whiteColor]];
    [self.buttonDone setEnabled:YES];

    [self.navigationItem addLeftBarButtonItem:buttonLeft?[[[UIBarButtonItem alloc] initWithCustomView:buttonLeft] autorelease]:nil];
    [self.navigationItem setRightBarButtonItem:self.buttonDone];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRGBHex:0x179cd8];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    if (self.fileOperatingMode == FileListMode_Copy)
    {
       [self.buttonDone setTitle:NSLocalizedString(@"kCopy", nil)];
       self.title = NSLocalizedString(@"kCopyToFolder", nil);
    }
    else if (self.fileOperatingMode == FileListMode_Move)
    {
       self.title = NSLocalizedString(@"kMoveToFolder", nil);
       [self.buttonDone setTitle:NSLocalizedString(@"kMove", nil)];
        
        NSString *firstNeedMoveFile = [(FbFileItem *)[self.operatingFiles objectAtIndex:0] path];
        if ([self.currentDirectoryPath isEqualToString:[firstNeedMoveFile stringByDeletingLastPathComponent]])
            [self.buttonDone setEnabled:NO];
        else
            [self.buttonDone setEnabled:YES];
    }
    else if (self.fileOperatingMode == FileListMode_Upload)
    {
       self.title = NSLocalizedString(@"kCloudUploadFile", nil);
       [self.buttonDone setTitle:NSLocalizedString(@"kCloudUploadFile", nil)];
    }
    else if (self.fileOperatingMode == FileListMode_Select)
    {
        [self.buttonDone setTitle:NSLocalizedString(@"kOK", nil)];
    }
    else if (self.fileOperatingMode == FileListMode_Import)
    {
        [self.buttonDone setTitle:NSLocalizedString(@"kSelectFile", nil)];
        [self.buttonDone setEnabled:NO];
    }
    
    NSDictionary * fontAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:DEVICE_iPHONE?15.0f:18.0f]};
    [self.buttonDone setTitleTextAttributes:fontAttributes forState:UIControlStateNormal];
    
    NSDictionary *titleFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:DEVICE_iPHONE?17.0:20.0], NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = titleFontAttributes;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    navigationController.navigationBar.tag = 1;
    if (viewController == self)
    {
        [self viewWillAppear:NO];
    }
}

- (void)setNavigationTitle:(NSString *)title
{
    self.title = title;
}

#pragma mark - Action methods
- (void)doneAction
{
    if (self.fileOperatingMode == FileListMode_Upload)
    {
        self.operatingHandler([self.navigationController.viewControllers objectAtIndex:0], self.selectedArray);
    }
    else
    {
        [self.buttonDone setEnabled:NO];
        self.operatingHandler(self, [NSArray arrayWithObject:self.currentDirectoryPath]);
    }
}

- (void)cancelAction
{
    if (self.cancelHandler) {
        self.cancelHandler();
    }
    [[self.navigationController.viewControllers objectAtIndex:0] dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - Other Methods
//Avi - new method addded to add the cloudname in copy page to fix the issue 0071868
-(void)_loadFilesWithPath:(NSString *)filePath
{
    __block NSMutableArray *folderList = [[NSMutableArray alloc] init];
    [FbFileBrowser _getFileListForType:FileListType_Local
                            withFolder:filePath
                     withSearchKeyword:nil
                  withParentFileObject:nil
                              userData:nil
                           withHandler:^(NSMutableArray *fileList)
     {
        NSArray *favFileListArr = [fileList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
                                    {
                                        FbFileItem *fileObj1= (FbFileItem *)obj1;
                                        FbFileItem *fileObj2= (FbFileItem *)obj2;
                                        if (fileObj1.isFolder != fileObj2.isFolder)  //一个是目录一个非目录,则目录优先
                                        {
                                            return fileObj1.isFolder ? NSOrderedAscending:NSOrderedDescending;
                                        }
                                        else
                                        {
                                            NSComparisonResult compareResult = NSOrderedSame;
                                            return compareResult;
                                        }
                                    }];
         
         [folderList addObjectsFromArray:[NSArray arrayWithArray:favFileListArr]];
     }];

    for (FbFileItem *fileitem in folderList)
    {
        if (fileitem.isFolder)
        {
            BOOL willAdd = YES;
            for (NSString *expFolder in self.exceptFolderList)
            {
                if ([[expFolder lastPathComponent] isEqualToString:[fileitem.path lastPathComponent]])
                {
                    willAdd = NO;
                    break;
                }
            }
            if (willAdd)
            {
                FileItem *item = [[FileItem alloc] init];
                item.filekey = fileitem.path;
                item.title = fileitem.fileName;
                item.isFolder = YES;
                [self.fileItemsArray addObject:item];
            }
        }
    }
}

- (void)loadFilesWithPath:(NSString *)filePath
{
    if (!self.isRootFileDirectory)
    {
        [self.fileItemsArray addObject:NSLocalizedString(@"kBack", nil)];
    }
    
    //Avi - added
    [self _loadFilesWithPath:filePath];

    //Avi - commenting
//    NSArray *subFolder = [Utility searchFoldersWithFolder:filePath recursive:NO];
//    for (NSString *thisFolder in subFolder)
//    {
//        BOOL willAdd = YES;
//        for (NSString *expFolder in self.exceptFolderList)
//        {
//            if ([[expFolder lastPathComponent] isEqualToString:[thisFolder lastPathComponent]]) {
//                
//                willAdd = NO;
//                break;
//            }
//        }
//        if (willAdd)
//        {
//            
//            NSString *fileDisplayName = [thisFolder lastPathComponent];
//            if (![fileDisplayName isEqualToString:@".IntuneMAM"])
//            {
//                FileItem *item= [[FileItem alloc] init];
//                item.filekey = thisFolder;
//                item.title = fileDisplayName;
//                item.isFolder = YES;
//                [self.fileItemsArray addObject:item];
//            }
//        }
//    }
    
    if (self.fileOperatingMode == FileListMode_Select || self.fileOperatingMode == FileListMode_Import || self.fileOperatingMode == FileListMode_Upload)
    {
        NSArray *files = [Utility searchFilesWithFolder:filePath recursive:NO];
        for (NSString *file in files)
        {
            NSString *fileDisplayName = [file lastPathComponent];
            BOOL willAdd = NO;
            NSString *extName = [fileDisplayName pathExtension];
            for (NSString* ext in _expectFileType)
            {
                if ([Utility isGivenExtension:extName type:ext])
                {
                    willAdd = YES;
                    break;
                }
            }
            if (self.fileOperatingMode == FileListMode_Upload && self.expectFileType == nil)
            {
                willAdd = YES;
            }
            if (willAdd)
            {
                FileItem *item= [[[FileItem alloc] init] autorelease];
                item.filekey = file;
                item.isFolder = NO;
                item.title = fileDisplayName;
                [self.fileItemsArray addObject:item];
            }
        }
    }

    self.currentDirectoryPath = filePath;
}

#pragma mark - Memory Management Methods
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [_selectedArray release];
    [_currentDirectoryPath release];
    
    [super dealloc];
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fileItemsArray count];
}

- (FileViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"cellIdentifier";
    FileViewCell* folderCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (folderCell == nil)
    {
        folderCell = [[[FileViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    if (!self.isRootFileDirectory && indexPath.row == 0)
    {
        folderCell.folderName.hidden = YES;
        folderCell.fileTypeImage.hidden = YES;
        folderCell.fileSelectImage.hidden = YES;
        folderCell.accessoryType = UITableViewCellAccessoryNone;
        folderCell.previousImage.hidden = NO;
        folderCell.backName.hidden = NO;
        folderCell.backName.text = [self.fileItemsArray objectAtIndex:0];
        folderCell.separatorLine.frame = CGRectMake(10, folderCell.contentView.frame.size.height-1, 2000, [Utility realPX:1.0f]);
    }
    else
    {
        FileItem *fileItem = [self.fileItemsArray objectAtIndex:indexPath.row];
        folderCell.folderName.text = fileItem.title;
        folderCell.separatorLine.frame = CGRectMake(0, folderCell.contentView.frame.size.height-1, 2000, [Utility realPX:1.0f]);
        if (fileItem.isFolder)
        {
            folderCell.fileSelectImage.hidden = YES;
            folderCell.fileTypeImage.image = [UIImage imageNamed:@"list_newfolder"];
            folderCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else
        {
            folderCell.accessoryType = UITableViewCellAccessoryNone;
            if (fileItem.selected)
            {
               folderCell.fileSelectImage.hidden = NO;
                folderCell.accessoryType = UITableViewCellAccessoryCheckmark;
                
            }
            else
            {
                folderCell.fileSelectImage.hidden = YES;
                folderCell.accessoryType = UITableViewCellAccessoryNone;
            }
            if ([Utility isPDFPath:fileItem.filekey])
            {
                folderCell.fileTypeImage.image = [Utility drawPageThumbnailWithPDFPath:fileItem.filekey pageIndex:0 pdfSize:CGSizeMake(41, 58)];
            }
            else
            {
                folderCell.fileTypeImage.image = [UIImage imageNamed:[Utility getIconName:fileItem.filekey]];
            }
        }
        
        folderCell.folderName.hidden = NO;
        folderCell.fileTypeImage.hidden = NO;
        folderCell.previousImage.hidden = YES;
        folderCell.backName.hidden = YES;
    }
    return folderCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (!self.isRootFileDirectory && indexPath.row == 0)
    {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    for (FileItem *fileItem in self.fileItemsArray)
    {
        if ([fileItem isKindOfClass:[FileItem class]])
        {
            if (self.fileOperatingMode != FileListMode_Upload) {
                fileItem.selected = NO;
            }
        }
    }
    FileItem *fileItem = [self.fileItemsArray objectAtIndex:indexPath.row];
    if (!fileItem.isFolder)
    {
        self.currentDirectoryPath = fileItem.filekey;
        
        if (self.fileOperatingMode == FileListMode_Upload) {
            fileItem.selected = !fileItem.selected;
            if (fileItem.selected) {
                [self.selectedArray addObject:fileItem.filekey];
            }
            else
            {
                if ([self.selectedArray containsObject:fileItem.filekey]) {
                    [self.selectedArray removeObject:fileItem.filekey];
                }
            }
            if (self.selectedArray.count == 0)
                self.title = NSLocalizedString(@"kCloudUploadFile", nil);
            else
            {
                self.title = [NSString stringWithFormat:@"%@(%lu)",NSLocalizedString(@"kCloudUploadFile", nil),(unsigned long)self.selectedArray.count];
            }
        }
        else
            fileItem.selected = YES;

        [tableView reloadData];
        if (self.fileOperatingMode == FileListMode_Import) {
            NSString *fileType = [self.expectFileType objectAtIndex:0];
            if ([Utility isGivenPath:fileItem.filekey type:fileType])
            {
                [self.buttonDone setEnabled:YES];
            }
            else
            {
                [self.buttonDone setEnabled:NO];
            }
        }
        
        return;
    }
    [self.selectedArray removeAllObjects];
    for (FileItem *fileItem in self.fileItemsArray)
    {
        if ([fileItem isKindOfClass:[FileItem class]])
        {
            fileItem.selected = NO;
        }
        [tableView reloadData];
    }
    
    FileSelectDestinationViewController *selectDestination = [[[FileSelectDestinationViewController alloc] init] autorelease];
    selectDestination.fileOperatingMode = self.fileOperatingMode;
    selectDestination.operatingHandler = self.operatingHandler;
    selectDestination.cancelHandler = self.cancelHandler;
    selectDestination.isRootFileDirectory = NO;
    selectDestination.exceptFolderList = self.exceptFolderList;
    selectDestination.expectFileType = self.expectFileType;
    selectDestination.operatingFiles = self.operatingFiles;
    [selectDestination loadFilesWithPath:fileItem.filekey];
    [self.navigationController pushViewController:selectDestination animated:YES];
}

#pragma mark - Orientation Method
- (void)orientationChanged:(NSNotification*)object
{
    [self configureInstructionMessage];
}

#pragma mark - NSNotification handler Method
- (void)applicationHandleOpenURL:(NSNotification *)object
{
    [self cancelAction];
}
@end
