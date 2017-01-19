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
#import "FileManageListViewController.h"
#import "AppDelegate.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "ThumbnailScrollViewCell.h"
#import "DocumentModule.h"
#import "UILabel.h"
#import "FbFileEnum.h"
#import "Utility+Demo.h"

#import <FoxitRDK/FSPDFObjC.h>
#import "Defines.h"
#import "AppDelegate.h"

@interface FileManageListViewController (PrivateAPI)

- (void)pushFileManageListViewWithFolder:(NSString *)folder;
- (void)changeViewMode:(int)viewMode;

@end

@implementation FileManageListViewController

@synthesize viewHeader;
@synthesize isEditing = _isEditing;
@synthesize buttonViewMode = _buttonViewMode;
@synthesize buttonBackiPhone = _buttonBackiPhone;


#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _isEditing = NO;
        _orientationChanged = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}


- (void)showMoreMenu:(BOOL)isZip
{
    self.grayView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT)] autorelease];
    [DEMO_APPDELEGATE.window addSubview:self.grayView];
    if (isZip) {
        self.grayView.tag = 100;
    } else {
        self.grayView.tag = 101;
    }
    self.grayView.backgroundColor = [UIColor blackColor];
    self.grayView.alpha = 0.4;
    self.grayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture)];
    [self.grayView addGestureRecognizer:tapGesture];
    
    moreTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, SCREENHEIGHT, SCREENWIDTH, 87) style:UITableViewStylePlain];
    if (OS_ISVERSION7) {
        moreTableView.separatorInset = UIEdgeInsetsMake(0, 5, 0, 16);
    }
    moreTableView.scrollEnabled = NO;
    moreTableView.delegate = self;
    moreTableView.dataSource = self;
    moreTableView.backgroundColor = [UIColor redColor];
    moreTableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [DEMO_APPDELEGATE.window addSubview:moreTableView];
    
    [UIView animateWithDuration:0.3 animations:^{
        moreTableView.frame = CGRectMake(0, SCREENHEIGHT - 87, SCREENWIDTH, 87);
    }];
}

- (void)tapGesture
{
    [UIView animateWithDuration:0.3 animations:^{
        moreTableView.frame = CGRectMake(0, SCREENHEIGHT, SCREENWIDTH, 87);
        
    } completion:^(BOOL finished) {
        [self.grayView removeFromSuperview];
        [moreTableView removeFromSuperview];
    }];
}

- (void)dealloc
{
    [viewHeader release];
    [_buttonBackiPhone release];
    [_buttonViewMode release];
    [_messageView release];
    [super dealloc];
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
    
    if (DEVICE_iPHONE)
    {
        [self refreshInterface];
    }
    if (_isEnableThumbnail)
    {
        [self changeViewMode:self.viewMode];
    }
    self.tabBarController.navigationController.navigationBarHidden = DEVICE_iPHONE;
    
    if([UIViewController instancesRespondToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    if([UINavigationController instancesRespondToSelector:@selector(interactivePopGestureRecognizer)])
    {
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    self.viewHeader.backgroundColor = [UIColor colorWithRed:239.f/256.f green:239.f/256.f blue:239.f/256.f alpha:1];
    
    [self setTableViewFrame];
    
    selectedFileObjectsForFileCompare = [[NSMutableArray alloc] initWithCapacity:0];
    
}

- (void)setTableViewFrame
{
    if (!DEVICE_iPHONE)
    {
        if (_isEnableThumbnail)
        {
            self.thumbnailFileList.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        }
        else
        {
            self.tableFileList.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        }
        
    }
    else
    {
        self.thumbnailFileList.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    }
}


- (void)sortFileByType:(FileSortType)sortType andFileSortMode:(FileSortMode)sortMode
{
    self.sortType = sortType;
    self.sortMode = sortMode;
    [self loadData];
    
    if (_isEnableThumbnail)
        [self.thumbnailFileList reloadData];
    else
        [self.tableFileList reloadData];
}

- (void)changeThumbnailFrame:(BOOL)change
{
    if (change)
    {
        self.thumbnailFileList.frame = CGRectMake(0, 50, self.view.bounds.size.width, self.view.bounds.size.height - 50);
        
    } else
    {
        self.thumbnailFileList.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    }
}


- (void)viewDidUnload
{
    [self setViewHeader:nil];
    [self setButtonViewMode:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation));
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self needStartFileMonitor];

    [self changeViewMode:self.viewMode];
    if (_orientationChanged)
    {
        _orientationChanged = NO;
        if (_isEnableThumbnail)
        {
            [self.thumbnailFileList reloadData];
        }
        else
        {
            [self.tableFileList reloadData];
        }
    }
    [self loadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self needStopFileMonitor];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)orientationChanged:(NSNotification*)object
{
    FoxitLog(@"orientation:%d", [UIDevice currentDevice].orientation);
    _orientationChanged = YES;
    
    [self performSelector:@selector(refreshUIOnOrientation) withObject:nil];//afterDelay:0.1f
}

- (void) refreshUIOnOrientation
{
    if (_isEnableThumbnail)
        [self.thumbnailFileList reloadData];
    else
        [self.tableFileList reloadData];
    
}

#pragma mark -  table view delegate and datasource handler

static const float STYLE_FRAME_INSET_IPHONE = 4;
static const CGRect STYLE_THUMBNAIL_NORMAL_FRAME = {15, 6, FILE_IMAGE_WIDTH, FILE_IMAGE_HEIGHT};
static const CGRect STYLE_THUMBNAIL_EDIT_FRAME = {43, 6, FILE_IMAGE_WIDTH, FILE_IMAGE_HEIGHT};
static const CGRect STYLE_THUMBNAIL_NORMAL_FRAME_EX = {6, 6, THUMBNAIL_IMAGE_WIDTH_EX, THUMBNAIL_IMAGE_HEIGHT_EX};
static const CGRect STYLE_THUMBNAIL_NORMAL_FRAME_LARGE_EX = {6, 5, THUMBNAIL_IMAGE_WIDTH_LARGE_EX, THUMBNAIL_IMAGE_HEIGHT_LARGE_EX};

static const CGRect STYLE_FILE_NAME_NORMAL_FRAME = {75, 12, 36.0/*use cell width*/, 20};
static const CGRect STYLE_FILE_NAME_EDIT_FRAME = {103, 12, 36.0/*use cell width*/, 20};
static const CGRect STYLE_MODIFIED_DATE_NORMAL_FRAME = {9, 40, 245, 15};
static const CGRect STYLE_MODIFIED_DATE_EDIT_FRAME = {39, 40, 245, 15};

#pragma mark - methods

//FileManageViewController is especially driven by data, as it will open outside file and the UI must rest according to data.
- (void)setUIAccordingToData
{
    [super setUIAccordingToData];
    self.searchBar.text = searchKeyword;
}

- (void)refreshInterface
{
    [super refreshInterface];
}

//Avi- Adding filename to display in navigation path
- (void)pushFileManageListViewWithFolder:(NSString *)folder displayName:(NSString *)displayname
{
    void(^block)() = ^(){
        [self needStopFileMonitor];
        NSBundle *bundle = nil;
        NSString* nibName = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? @"FileManageViewController_iPhone" : @"FileManageListViewController_iPad";
        FileManageListViewController *ctrl= [[FileManageListViewController alloc] initWithNibName:nibName bundle:bundle];
        ctrl.currentFolder = folder;
        ctrl.currentTypeIndex = FileListType_Local;
        ctrl.delegate = self.delegate;
        ctrl.sortType = self.sortType;
        ctrl.sortMode = self.sortMode;
        ctrl.viewMode = self.viewMode;
        [self.navigationController pushViewController:ctrl animated:YES];
        [ctrl release];
        
        if ([self.delegate conformsToProtocol:@protocol(IFbFileDelegate)] && [self.delegate respondsToSelector:@selector(onItemCliked:)])
        {
            FbFileItem *fileItem = [[[FbFileItem alloc] init] autorelease];
            fileItem.isFolder = YES;
            fileItem.path = folder;
            fileItem.fileName = displayname;
            [self.delegate onItemCliked:fileItem];//todo wyy
        }
    };
        block();
}

- (void)changeViewMode:(int)viewMode
{
    if (self.viewMode != viewMode)
    {
        self.viewMode = viewMode;
        [self.thumbnailFileList reloadData];
        self.thumbnailFileList.cellArrangement = self.viewMode == 0 ? ThumbnailScrollViewCellArrangementDown : ThumbnailScrollViewCellArrangementRight;
        
    }
}

#pragma mark - event handler

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = nil;
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        UIImageView *imageView  = [[[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 40, 0, 30, 30)] autorelease];
        imageView.center = CGPointMake(imageView.center.x, cell.frame.size.height/2);
        imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        imageView.contentMode = UIViewContentModeCenter;
        imageView.tag = 20;
        [cell.contentView addSubview:imageView];
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:15.f];
    
    UIImageView *imageView = (UIImageView*)[cell.contentView viewWithTag:20];
    
    if (self.grayView.tag == 100)
    {
        if (indexPath.row == 0)
        {
            imageView.image = [UIImage imageNamed:@"document_edit_zip.png"];
            cell.textLabel.text = NSLocalizedString(@"kZip", nil);
            
        }
        else if (indexPath.row == 1)
        {
            imageView.image = [UIImage imageNamed:@"document_edit_share.png"];
            cell.textLabel.text = NSLocalizedString(@"kShare", nil);
        }
    }
    else
    {
        {
            [self tapGesture];
            return cell;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    [self tapGesture];
    
}

- (void)buttonChangeViewMode
{
    [self changeViewMode:self.viewMode == 1 ? 0 : 1];
}


#pragma mark - ThumbnailScrollView data source

static const int TAG_LIST_CELL_FILETYPEIMAGE_BG     = 110;
static const int TAG_LIST_CELL_FILETYPEIMAGE        = 1101;
static const int TAG_LIST_CELL_FILENAME             = 1103;
static const int TAG_LIST_CELL_DATE                 = 1105;
static const int TAG_LIST_CELL_FILESIZE             = 1107;
static const int TAG_LIST_CELL_FILENUMBER           = 1109;
static const int TAG_LIST_CELL_FILECELLMORE         = 1111;

static const int TAG_LIST_CELL_SPLITELINE           = 1127;
static const int TAG_LIST_CELL_LEFTLINE             = 1129;
static const int TAG_LIST_CELL_TOPLINE              = 1131;
static const int TAG_LIST_CELL_RIGHTLINE            = 1133;


static NSString *LISTVIEW_IDENTIFIER = @"LISTVIEW_INDENTIFIER";
static NSString *THUMBNAILVIEW_IDENTIFIER = @"THUMBNAILVIEW_IDENTIFIER";

static NSString* getReadableFileSize(unsigned long long byte);

- (ThumbnailScrollViewCell *)thumbnailScrollView:(ThumbnailScrollView *)scrollView cellAtIndex:(NSInteger)index
{
    ThumbnailScrollViewCell *cell = (self.viewMode == 1) ? [scrollView dequeueReusableCellWithIdentifier:THUMBNAILVIEW_IDENTIFIER] : [scrollView dequeueReusableCellWithIdentifier:LISTVIEW_IDENTIFIER];
    if (self.viewMode == 0) //listview mode
    {
        if (cell == nil)
        {
            cell = [[[ThumbnailScrollViewCell alloc] init] autorelease];
            cell.reuseIdentifier = LISTVIEW_IDENTIFIER;
            CGRect frame = CGRectMake(0, 0, scrollView.bounds.size.width, 68.0f);
            cell.frame = frame;
            cell.contentView.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f];
            cell.containerView.frame = cell.bounds;
            cell.contentView.frame = frame;
            
            UIImageView *imageViewBg = [[UIImageView alloc] initWithFrame:STYLE_THUMBNAIL_NORMAL_FRAME];
            imageViewBg.tag = TAG_LIST_CELL_FILETYPEIMAGE_BG;
            [cell.contentView addSubview:imageViewBg];
            [imageViewBg release];
            
            //filetypeimage
            UIImageView *thumbnailImageView = [[UIImageView alloc] initWithFrame:STYLE_THUMBNAIL_NORMAL_FRAME];
            thumbnailImageView.tag = TAG_LIST_CELL_FILETYPEIMAGE;
            [cell.contentView addSubview:thumbnailImageView];
            [thumbnailImageView release];
            
            
            //filename
            frame = STYLE_FILE_NAME_NORMAL_FRAME;
            frame.size.width = cell.bounds.size.width - STYLE_FILE_NAME_NORMAL_FRAME.origin.x;
            UILabel *labelFileName = [[UILabel alloc] initWithFrame:frame];
            labelFileName.tag = TAG_LIST_CELL_FILENAME;
            labelFileName.font = [UIFont boldSystemFontOfSize:DEVICE_iPHONE ? 16 : 18];
            labelFileName.textColor = [UIColor blackColor];
            labelFileName.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:labelFileName];
            labelFileName.text = @"";
            labelFileName.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [labelFileName release];
            
            //file date
            frame = STYLE_MODIFIED_DATE_NORMAL_FRAME;
            UILabel *labelFileDateTime = [[UILabel alloc] init];
            labelFileDateTime.tag = TAG_LIST_CELL_DATE;
            labelFileDateTime.font = [UIFont systemFontOfSize:10];
            labelFileDateTime.textColor = [UIColor darkGrayColor];
            labelFileDateTime.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:labelFileDateTime];
            labelFileDateTime.frame = frame;
            [labelFileDateTime release];
            
            //file Size
            UILabel *labelFileSize = [[UILabel alloc] init];
            labelFileSize.tag = TAG_LIST_CELL_FILESIZE;
            labelFileSize.font = [UIFont systemFontOfSize:10];
            labelFileSize.textColor = [UIColor darkGrayColor];
            labelFileSize.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:labelFileSize];
            labelFileSize.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            [labelFileSize release];
            
            //folder file number
            frame = CGRectMake(cell.bounds.size.width - 60.0f, (int)(cell.bounds.size.height - 17.0f)/2, 22.0f, 17.0f);
            UILabel *labelNumber = [[UILabel alloc] initWithFrame:frame];
            labelNumber.tag = TAG_LIST_CELL_FILENUMBER;
            labelNumber.backgroundColor = [UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0f];
            labelNumber.layer.cornerRadius = 5.0f;
            labelNumber.layer.masksToBounds = YES;
            labelNumber.font = [UIFont systemFontOfSize:12.0f];
            labelNumber.textColor = [UIColor whiteColor];
            labelNumber.textAlignment = NSTextAlignmentCenter;
            labelNumber.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [cell.contentView addSubview:labelNumber];
            [labelNumber release];
            
            
            //splite line index = 11
            UIView *viewSpliteLine = [[UIView alloc] init];
            viewSpliteLine.tag = TAG_LIST_CELL_SPLITELINE;
            viewSpliteLine.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];

            frame = CGRectMake(CGRectGetMinX(labelFileName.frame), cell.bounds.size.height - 1, cell.bounds.size.width, [Utility realPX:1.0f]);
            viewSpliteLine.frame = frame;
            viewSpliteLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [cell.contentView addSubview:viewSpliteLine];
            [viewSpliteLine release];
            
        }
        
        UIImageView *imageViewBg = [cell.contentView viewWithTag:TAG_LIST_CELL_FILETYPEIMAGE_BG];
        UIImageView *thumbnailImageView = [cell.contentView viewWithTag:TAG_LIST_CELL_FILETYPEIMAGE];
        UILabel *labelFileName = [cell.contentView viewWithTag:TAG_LIST_CELL_FILENAME];
        UILabel *labelFileDateTime = [cell.contentView viewWithTag:TAG_LIST_CELL_DATE];
        UILabel *labelFileSize = [cell.contentView viewWithTag:TAG_LIST_CELL_FILESIZE];
        UILabel *labelNumber = [cell.contentView viewWithTag:TAG_LIST_CELL_FILENUMBER];
        UIView *viewSpliteLine = [cell.containerView viewWithTag:TAG_LIST_CELL_SPLITELINE];

        FbFileItem *fileObj = [arrayFile objectAtIndex:index];
        if ([fileObj.fileName rangeOfString:@"/"].location == NSNotFound)
        {
            if ([[fileObj.fileExt lowercaseString] isEqualToString:@"pdf"])
            {
                if ([fileObj.fileName rangeOfString:@".pdf"].location == NSNotFound)
                    labelFileName.text = [fileObj.fileName stringByAppendingString:@".pdf"];
                else
                    labelFileName.text = fileObj.fileName;

            }
            else if ([[fileObj.fileExt lowercaseString] isEqualToString:@"ppdf"])
            {
                if ([fileObj.fileName rangeOfString:@".ppdf"].location == NSNotFound)
                    labelFileName.text = [fileObj.fileName stringByAppendingString:@".ppdf"];
                else
                    labelFileName.text = fileObj.fileName;
            }
            else
                labelFileName.text = fileObj.fileName;
        }
        else
        {
            NSString *filename = [fileObj.fileName lastPathComponent];
            
            if ([[fileObj.fileExt lowercaseString] isEqualToString:@"pdf"])
            {
                if ([filename rangeOfString:@".ppdf"].location == NSNotFound)
                    labelFileName.text = [filename stringByAppendingString:@".pdf"];
                else
                    labelFileName.text = filename;

            }
            else if ([[fileObj.fileExt lowercaseString] isEqualToString:@"ppdf"])
            {
                if ([filename rangeOfString:@".ppdf"].location == NSNotFound)
                    labelFileName.text = [filename stringByAppendingString:@".ppdf"];
                else
                    labelFileName.text = filename;
            }
            else
                labelFileName.text = filename;
        }
        
        labelFileDateTime.text = [Utility displayDateInYMDHM:fileObj.modifiedDate];
        [labelFileName setTextColor:
         [UIColor darkGrayColor]];

        CGRect labelFrame = _isEditing ? STYLE_FILE_NAME_EDIT_FRAME : STYLE_FILE_NAME_NORMAL_FRAME;
        labelFrame.origin.x = DEVICE_iPHONE ? labelFrame.origin.x - STYLE_FRAME_INSET_IPHONE : labelFrame.origin.x;
        labelFrame.size.width = cell.bounds.size.width - labelFrame.origin.x - 36.0f;//36.0f is favorite icon left x point
        if (fileObj.isFolder)
            labelFrame.size.width = cell.bounds.size.width - labelFrame.origin.x - 60.0f;//36.0f is favorite icon left x point
        else
            labelFrame.size.width = cell.bounds.size.width - labelFrame.origin.x - 36.0f;//36.0f is favorite icon left x point

        labelFileName.frame = labelFrame;
        CGRect splitLineFrame = CGRectMake(CGRectGetMinX(labelFileName.frame), viewSpliteLine.frame.origin.y, viewSpliteLine.frame.size.width, [Utility realPX:1.0f]);
        viewSpliteLine.frame = splitLineFrame;
        labelFrame = _isEditing ? STYLE_MODIFIED_DATE_EDIT_FRAME : STYLE_MODIFIED_DATE_NORMAL_FRAME;
        labelFrame.origin.x = DEVICE_iPHONE ? labelFrame.origin.x - STYLE_FRAME_INSET_IPHONE : labelFrame.origin.x;
        labelFrame.size.width = cell.bounds.size.width - labelFrame.origin.x;
       
        CGRect thumbnailFrame = _isEditing ? STYLE_THUMBNAIL_EDIT_FRAME : STYLE_THUMBNAIL_NORMAL_FRAME;
        thumbnailImageView.frame = thumbnailFrame;
        
        {
            labelFileDateTime.frame = CGRectMake(labelFrame.origin.x + 80 - 13, labelFrame.origin.y + 2, 100, labelFrame.size.height);
            labelNumber.hidden = !fileObj.isFolder;
            labelNumber.text = [NSString stringWithFormat:@"%lu", (unsigned long)fileObj.fileSize];
            
            CGRect labelNumberFrame = labelNumber.frame;
            labelNumberFrame.origin.x = _isEditing ? cell.bounds.size.width - 35 : cell.bounds.size.width - 60;
            labelNumber.frame = labelNumberFrame;
            
            labelFrame = labelFileDateTime.frame;
            labelFrame = _isEditing ? STYLE_FILE_NAME_EDIT_FRAME : STYLE_FILE_NAME_NORMAL_FRAME;
            labelFrame.origin.x = DEVICE_iPHONE ? labelFrame.origin.x - STYLE_FRAME_INSET_IPHONE : labelFrame.origin.x;
            labelFrame.origin.y = labelFileDateTime.frame.origin.y - 3;
            labelFrame.size.width = cell.bounds.size.width - labelFrame.origin.x;
            labelFileSize.frame = CGRectMake(CGRectGetMaxX(labelFileDateTime.frame)+20  - 15, labelFrame.origin.y, 110, labelFrame.size.height);;
            labelFileSize.textAlignment = NSTextAlignmentLeft;
        }
        
        cell.alwaysHideCheckBox = NO;
        if (DEVICE_iPHONE)
        {
            thumbnailFrame.origin.x -= STYLE_FRAME_INSET_IPHONE;
        }
        if (fileObj.isFolder)
        {
            thumbnailImageView.layer.borderWidth  = 0.0;
            imageViewBg.hidden = YES;
            thumbnailImageView.frame = thumbnailFrame;
            thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
            thumbnailImageView.image = [UIImage imageNamed:@"list_newfolder"];
            labelFileSize.text = getReadableFileSize(fileObj.directorySize);
        }
        else
        {
            thumbnailImageView.image = nil;
            if ([[fileObj.fileExt lowercaseString] isEqualToString:@"pdf"])
            {
                thumbnailImageView.layer.borderWidth  = 1.0;
                thumbnailImageView.layer.borderColor  = [UIColor colorWithHexString:@"D8D8D8"].CGColor;
            }
            else
                thumbnailImageView.layer.borderWidth  = 0.0;
            
            //Avi - block added to fix the issue 0074139
            __block UIImageView *blockthumbnailImageView = [cell.contentView viewWithTag:TAG_LIST_CELL_FILETYPEIMAGE];

            [fileObj getThumbnailForPageIndex:-1 dispatchQueue:queue WithHandler:^(UIImage *image, int pageIndex, NSString *pdfPath)
             {
                 thumbnailImageView.contentMode = UIViewContentModeScaleToFill;
                 if (index >= 0 && index < arrayFile.count)  //Fix delete files crash, when files are deleted and callback occur.
                 {
                     FbFileItem *imageFileObj = [arrayFile objectAtIndex:index];
                     if ([imageFileObj.path isEqualToString:pdfPath])
                     {
                         [Utility assignImage:blockthumbnailImageView rawFrame:thumbnailFrame image:image];
                         CGRect bgFrame = thumbnailImageView.frame;
                         bgFrame = CGRectMake(bgFrame.origin.x, bgFrame.origin.y, bgFrame.size.width + 3, bgFrame.size.height + 3);
                         imageViewBg.frame = bgFrame;
                         if ([imageFileObj.fileExt.lowercaseString isEqualToString:@"pdf"] && image.scale == 1)
                         {
                            thumbnailImageView.layer.borderWidth  = 1.0;
                            thumbnailImageView.layer.borderColor  = [UIColor colorWithHexString:@"D8D8D8"].CGColor;
                         }
                     }
                     imageViewBg.hidden = YES;
                 }
             }];
             labelFileSize.text = getReadableFileSize(fileObj.fileSize);
        }
        
        if(fileObj.isFolder || ![[fileObj.fileExt lowercaseString] isEqualToString:@"pdf"])
            thumbnailImageView.layer.borderWidth  = 0.0;
        else if ([[fileObj.fileExt lowercaseString] isEqualToString:@"pdf"])
        {
            thumbnailImageView.layer.borderWidth  = 1.0;
            thumbnailImageView.layer.borderColor  = [UIColor colorWithHexString:@"D8D8D8"].CGColor;
        }
        
        labelFileSize.hidden = NO;

        cell.alpha = fileObj.isTouchMoving ? 0.3f : 1.0f;
        cell.reserveObj = fileObj;

        return cell;
    }
    
    //thumbnail mode
    if (cell == nil)
    {
        cell = [[[ThumbnailScrollViewCell alloc] init] autorelease];
        cell.reuseIdentifier = THUMBNAILVIEW_IDENTIFIER;
        CGRect frame = DEVICE_iPHONE ? CGRectMake(0, 0, 87.0f, 135.0f) : CGRectMake(0.0f, 0.0f, 130.0f, 184.0f);
        cell.frame = frame;
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:0.0];
        cell.containerView.frame = cell.bounds;
        cell.contentView.frame = cell.containerView.bounds;
        
        //index = 0
        UIImage *image = [UIImage imageNamed:DEVICE_iPHONE ? @"thumbnail_newfolder_iphone" : @"thumbnail_newfolder_ipad"];
        UIImageView *imageViewFolder = [[UIImageView alloc] initWithImage:image];
        imageViewFolder.frame = DEVICE_iPHONE ? CGRectMake(0, 0, 100.0f, 97.0f) : CGRectMake(0.0f, 0.0f, 130.0f, 146.0f);
        [cell.contentView addSubview:imageViewFolder];
        imageViewFolder.hidden = NO;
        imageViewFolder.alpha = 0.0f;
        imageViewFolder.contentMode = UIViewContentModeCenter;
        [imageViewFolder release];
        //index = 1
        frame = DEVICE_iPHONE ? CGRectMake(0, 0, 87.0f, 97.0f) : CGRectMake(0.0f, 0.0f, 130.0f, 146.0f);

        image = [UIImage imageNamed:DEVICE_iPHONE ? @"thumbnail_pdf_bg_iphone" : @"thumbnail_pdf_bg_ipad"];
        UIImageView *imageViewThumbnailBackground = [[UIImageView alloc] initWithImage:image];
        imageViewThumbnailBackground.frame = frame;
        imageViewThumbnailBackground.contentMode = UIViewContentModeScaleToFill;
        [cell.contentView addSubview:imageViewThumbnailBackground];
        [imageViewThumbnailBackground release];
        //index = 2
        UIImageView *imageViewThumbnail = [[UIImageView alloc] initWithFrame:frame];
        imageViewThumbnail.contentMode = UIViewContentModeScaleAspectFit;
        [cell.contentView addSubview:imageViewThumbnail];
        [imageViewThumbnail release];
        //index = 3
        frame = DEVICE_iPHONE ? CGRectMake(0, 98.0f, 87.0f, 19.0f) : CGRectMake(0.0f, 147.0f, 130.0f, 19.0f);
        UILabel *labelPageTitle = [[UILabel alloc] init];
        labelPageTitle.textAlignment = NSTextAlignmentCenter;
        labelPageTitle.numberOfLines = 2;
        [labelPageTitle alignTop];
        labelPageTitle.textColor = [UIColor blackColor];
        labelPageTitle.shadowColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        labelPageTitle.shadowOffset = CGSizeMake(0.0f, 1.0f);
        labelPageTitle.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:labelPageTitle];
        [labelPageTitle release];
        //index = 4
        frame = DEVICE_iPHONE ? CGRectMake(0, 117.0f, 87.0f, 18.0f) : CGRectMake(0.0f, 165.0f, 130.0f, 18.0f);
        UILabel *labelNumberTitle = [[UILabel alloc] init];
        labelNumberTitle.frame = frame;
        labelNumberTitle.font = [UIFont systemFontOfSize:DEVICE_iPHONE?11.f:13.f];
        labelNumberTitle.textColor = [UIColor darkGrayColor];
        labelNumberTitle.textAlignment = NSTextAlignmentCenter;
        labelNumberTitle.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:labelNumberTitle];
        [labelNumberTitle release];
        //index = 8 favorite Small icon

        cell.backgroundBadge.image = [[UIImage imageNamed:@"thumb_redio_red"] stretchableImageWithLeftCapWidth:16 topCapHeight:0];
    }
    UIImageView *imageViewFolder = [cell.contentView.subviews objectAtIndex:0];
    UIImageView *imageViewThumbnailBackground = [cell.contentView.subviews objectAtIndex:1];
    UIImageView *imageViewThumbnail = [cell.contentView.subviews objectAtIndex:2];
    UILabel *labelPageTitle = [cell.contentView.subviews objectAtIndex:3];
    UILabel *labelNumberTitle = [cell.contentView.subviews objectAtIndex:4];

    FbFileItem *fileObj = [arrayFile objectAtIndex:index];
    [labelPageTitle setTextColor:
     [UIColor darkGrayColor]];
    imageViewFolder.hidden = NO;
    imageViewFolder.alpha = fileObj.isFolder ? 1.0f : 0.0f;
    imageViewThumbnail.hidden = fileObj.isFolder;
    imageViewThumbnailBackground.hidden = fileObj.isFolder || ![fileObj.path.lowercaseString.pathExtension isEqualToString:@"pdf"];
    labelNumberTitle.hidden = !fileObj.isFolder;

    if (([fileObj.fileName rangeOfString:@"/"].location == NSNotFound))
    {
        if ([[fileObj.fileExt lowercaseString] isEqualToString:@"pdf"])
        {
            if ([fileObj.fileName rangeOfString:@".pdf"].location == NSNotFound)
                labelPageTitle.text = [fileObj.fileName stringByAppendingString:@".pdf"];
            else
                labelPageTitle.text = fileObj.fileName;
        }
        else if ([[fileObj.fileExt lowercaseString] isEqualToString:@"ppdf"])
        {
            if ([fileObj.fileName rangeOfString:@".ppdf"].location == NSNotFound)
                labelPageTitle.text = [fileObj.fileName stringByAppendingString:@".ppdf"];
            else
                labelPageTitle.text = fileObj.fileName;
        }
        else
            labelPageTitle.text = fileObj.fileName;
    }
    else
    {
        NSString *filename = [fileObj.fileName lastPathComponent];
        
        if ([[fileObj.fileExt lowercaseString] isEqualToString:@"pdf"])
        {
            if ([filename rangeOfString:@".ppdf"].location == NSNotFound)
                labelPageTitle.text = [filename stringByAppendingString:@".pdf"];
            else
                labelPageTitle.text = filename;
            
        }
        else if ([[fileObj.fileExt lowercaseString] isEqualToString:@"ppdf"])
        {
            if ([filename rangeOfString:@".ppdf"].location == NSNotFound)
                labelPageTitle.text = [filename stringByAppendingString:@".ppdf"];
            else
                labelPageTitle.text = filename;
        }
        else
            labelPageTitle.text = filename;


    }
    
    CGRect frame = DEVICE_iPHONE ? CGRectMake(0, 0, 87.0f, 97.0f) : CGRectMake(0.0f, 0.0f, 130.0f, 146.0f);
    imageViewThumbnail.frame = frame;
    CGRect frameTitle = DEVICE_iPHONE ?CGRectMake(0, 98.0f, 87.0f, 18.0f) : CGRectMake(0.0f, 150.0f, 130.0f, 18.0f);
    imageViewThumbnail.tag = index;
    cell.alwaysHideCheckBox = NO;
    if (!fileObj.isFolder)
    {
        frameTitle.size.height += 18.0f;
        labelPageTitle.font = [UIFont systemFontOfSize:DEVICE_iPHONE?12.f:14.f];
        labelNumberTitle.text = @"";
        if (![[fileObj.fileExt lowercaseString] isEqualToString:@"pdf"])
            imageViewThumbnail.layer.borderWidth  = 0.0;
        else
        {
            imageViewThumbnail.layer.borderWidth  = 1.0;
            imageViewThumbnail.layer.borderColor  = [UIColor colorWithHexString:@"D8D8D8"].CGColor;
        }
        
        [fileObj getThumbnailForPageIndex:-2 dispatchQueue:queue WithHandler:^(UIImage *image, int pageIndex, NSString *pdfPath)
         {
             imageViewThumbnail.contentMode = UIViewContentModeScaleToFill;
             //UITableViewCell is reused, when callback return, the cell content(image view) is not the one when send out request. To fix it the key is to make sure image only assigned when the cell content is same for the callback content.
             //a trick here is block has copy, and here it copies imageThubnail, so that each time imageThumbnail.tag = indexPath.row is called without delay, that is correct for all the time. And imageThumbnail is copied into block, not prevent imageThumbnail.tag is the right value (currently seen in UITableView).
             //the above reason makes the fix work.
             if (imageViewThumbnail.tag >= 0 && imageViewThumbnail.tag < arrayFile.count)  //Fix delete files crash, when files are deleted and callback occur.
             {
                 FbFileItem *imageFileObj = [arrayFile objectAtIndex:imageViewThumbnail.tag];
                 if ([imageFileObj.path isEqualToString:pdfPath])
                 {
                     [Utility assignImage:imageViewThumbnail rawFrame:(DEVICE_iPHONE ? STYLE_THUMBNAIL_NORMAL_FRAME_EX : STYLE_THUMBNAIL_NORMAL_FRAME_LARGE_EX) image:image];
                     CGRect infactRect = imageViewThumbnail.frame;
                     infactRect.origin = CGPointMake(infactRect.origin.x - 4.0f, infactRect.origin.y - 2.0f);
                     infactRect.size.width += 8.0f;
                     infactRect.size.height += 8.0f;
                     imageViewThumbnailBackground.frame = infactRect;
                     imageViewThumbnailBackground.hidden = !([imageFileObj.fileExt.lowercaseString isEqualToString:@"pdf"] && fileObj.reserveData != 1);
                     imageViewThumbnailBackground.hidden = YES;
                     if ([imageFileObj.fileExt.lowercaseString isEqualToString:@"pdf"] && image.scale == 1)
                     {
                         imageViewThumbnail.layer.borderWidth  = 1.0;
                         imageViewThumbnail.layer.borderColor  = [UIColor colorWithHexString:@"D8D8D8"].CGColor;
                     }

                     if (scrollView.editing)
                     {
                         infactRect = imageViewThumbnail.frame;
                         CGPoint buttonCheckPoint = DEVICE_iPHONE ? CGPointMake(infactRect.origin.x , infactRect.origin.y + 2.0f) : CGPointMake(infactRect.origin.x + 2.0f, infactRect.origin.y + 6.0f);
                         
                         
                         if ([imageFileObj.fileExt.lowercaseString isEqualToString:@"pdf"])
                         {
                             buttonCheckPoint = DEVICE_iPHONE ? CGPointMake(infactRect.origin.x , infactRect.origin.y) : CGPointMake(infactRect.origin.x + 2.0f, infactRect.origin.y + 2.0f);
                         }
                     }
                 }
             }
         }];
    }
    else
    {
        imageViewThumbnail.layer.borderWidth  = 0.0;
        labelNumberTitle.text = [NSString stringWithFormat:NSLocalizedString(@"kItems", nil), fileObj.fileSize];
        labelPageTitle.font = [UIFont boldSystemFontOfSize:DEVICE_iPHONE?12.f:14.f];
    }
    labelPageTitle.frame = frameTitle;
    
    frameTitle = DEVICE_iPHONE ? CGRectMake(0, 117.0f, 87.0f, 18.0f) : CGRectMake(0.0f, 165.0f, 130.0f, 18.0f);
    labelNumberTitle.frame = frameTitle;
    
    cell.reserveObj = fileObj;
    cell.alpha = fileObj.isTouchMoving ? 0.3f : 1.0f;
    return cell;
}


#pragma mark - ThumbnailScrollView delegate

- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView blankCellIndexChangedFrom:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    FoxitLog(@"index form:%d to:%d", fromIndex, toIndex);
    if (fromIndex != -1)
    {
        FbFileItem *fileObj = [arrayFile objectAtIndex:fromIndex];
        if (!fileObj.isTouchMoving)
        {
            ThumbnailScrollViewCell *cell = [scrollView cellOfIndex:fromIndex];
            [UIView animateWithDuration:.3
                                  delay:.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 if (!fileObj.isFolder && self.viewMode == 1)
                                 {
                                     UIImageView *imageThumbnail = (UIImageView *)[cell.contentView.subviews objectAtIndex:2];
                                     imageThumbnail.transform = CGAffineTransformIdentity;
                                     UIImageView *imageThumbnailBackground = (UIImageView *)[cell.contentView.subviews objectAtIndex:1];
                                     imageThumbnailBackground.transform = CGAffineTransformIdentity;
                                     UIImageView *imageFolder = (UIImageView *)[cell.contentView.subviews objectAtIndex:0];
                                     imageFolder.hidden = NO;
                                     imageFolder.alpha = 0.0f;
                                     UILabel *labelPageTitle = (UILabel *)[cell.contentView.subviews objectAtIndex:3];
                                     labelPageTitle.hidden = NO;
                                     UILabel *labelNumberTitle = (UILabel *)[cell.contentView.subviews objectAtIndex:4];
                                     labelNumberTitle.hidden = NO;
                                 }
                                 cell.backgroundColor = [UIColor clearColor];
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
    }
    if (toIndex != -1)
    {
        FbFileItem *fileObj = [arrayFile objectAtIndex:toIndex];
        if (!fileObj.isTouchMoving)
        {
            ThumbnailScrollViewCell *cell = [scrollView cellOfIndex:toIndex];
            [UIView animateWithDuration:.3
                                  delay:.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 if (!fileObj.isFolder && self.viewMode == 1)
                                 {
                                     UIImageView *imageThumbnail = (UIImageView *)[cell.contentView.subviews objectAtIndex:2];
                                     CGAffineTransform transform = imageThumbnail.transform;
                                     transform = CGAffineTransformScale(transform, 0.5f, 0.5f);
                                     imageThumbnail.transform = transform;
                                     UIImageView *imageThumbnailBackground = (UIImageView *)[cell.contentView.subviews objectAtIndex:1];
                                     transform = imageThumbnailBackground.transform;
                                     transform = CGAffineTransformScale(transform, 0.5f, 0.5f);
                                     imageThumbnailBackground.transform = transform;
                                     UIImageView *imageFolder = (UIImageView *)[cell.contentView.subviews objectAtIndex:0];
                                     imageFolder.hidden = NO;
                                     imageFolder.alpha = 1.0f;
                                     UILabel *labelPageTitle = (UILabel *)[cell.contentView.subviews objectAtIndex:3];
                                     labelPageTitle.hidden = YES;
                                     UILabel *labelNumberTitle = (UILabel *)[cell.contentView.subviews objectAtIndex:4];
                                     labelNumberTitle.hidden = YES;
                                 }
                                 cell.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f];
                                 cell.layer.cornerRadius = self.viewMode == 1 ? 5.0f : 0.0f;
                                 cell.layer.masksToBounds = YES;
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
    }
}

- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView willSortLayoutCellIndexes:(NSArray *)cellIndexes
{
    [UIView animateWithDuration:0.3 animations:^{
        for (NSNumber *index in cellIndexes)
        {
            ThumbnailScrollViewCell *cell = [scrollView cellOfIndex:index.intValue];
            if (cell != nil)
            {
                cell.alpha = 0.2;
            }
        }
    }];
}

- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didSortLayoutCellIndexes:(NSArray *)cellIndexes
{
    [UIView animateWithDuration:0.3 animations:^{
        for (NSNumber *index in cellIndexes)
        {
            ThumbnailScrollViewCell *cell = [scrollView cellOfIndex:index.intValue];
            if (cell != nil)
            {
                cell.alpha = 1.0;
            }
        }
    }];
}

- (UIImage *)thumbnailScrollView:(ThumbnailScrollView *)scrollView imageCopyCell:(ThumbnailScrollViewCell *)cell
{
    if (self.viewMode == 0)
    {
        CGRect tempRect = cell.frame;
        tempRect.size.width = 280;
        cell.frame = tempRect;
        UIView *viewLine = [cell.contentView viewWithTag:TAG_LIST_CELL_LEFTLINE];
        viewLine.hidden = NO;
        viewLine = [cell.contentView viewWithTag:TAG_LIST_CELL_TOPLINE];
        viewLine.hidden = NO;
        viewLine = [cell.contentView viewWithTag:TAG_LIST_CELL_RIGHTLINE];
        viewLine.hidden = NO;
        cell.backgroundColor = [UIColor whiteColor];
        UIImage *image = [cell cloneCellImage];
        cell.backgroundColor = [UIColor clearColor];
        viewLine = [cell.contentView viewWithTag:TAG_LIST_CELL_LEFTLINE];
        viewLine.hidden = YES;
        viewLine = [cell.contentView viewWithTag:TAG_LIST_CELL_TOPLINE];
        viewLine.hidden = YES;
        viewLine = [cell.contentView viewWithTag:TAG_LIST_CELL_RIGHTLINE];
        viewLine.hidden = YES;
        tempRect.size.width = scrollView.bounds.size.width;
        cell.frame = tempRect;
        return image;
    }
    [[cell.contentView.subviews objectAtIndex:3] setHidden:YES];
    [[cell.contentView.subviews objectAtIndex:4] setHidden:YES];

    UIImage *image = [cell cloneCellImage];
    [[cell.contentView.subviews objectAtIndex:3] setHidden:NO];
    [[cell.contentView.subviews objectAtIndex:4] setHidden:NO];
    cell.editing = scrollView.editing;
    return image;
}




- (BOOL)thumbnailScrollView:(ThumbnailScrollView *)scrollView shouldSortCellIndexes:(NSArray *)cellIndexes blankCellIndex:(NSInteger)blankCellIndex
{

    if ([cellIndexes indexOfObject:[NSNumber numberWithLong:blankCellIndex]] != NSNotFound)
    {
        return NO;
    }
    FoxitLog(@"should sort cell index:%d", blankCellIndex);
    return YES;
}

-(void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didTapOnCellAtIndex:(NSInteger)index
{
    if (self.viewMode == 0)
    {
        ThumbnailScrollViewCell *cell = [scrollView cellOfIndex:index];
        if (cell == nil)
        {
            return;
        }
        //click the favorite button
        if ([scrollView checkTapPointInCellContent:cell subView:[cell.contentView viewWithTag:TAG_LIST_CELL_FILECELLMORE]])
        {
            return;
        }
    }
    if (self.viewMode == 1) //click the file name will do rename action.
    {
        ThumbnailScrollViewCell *cell = [scrollView cellOfIndex:index];
        if (cell == nil)
        {
            return;
        }
        if ([scrollView checkTapPointInCellContent:cell subView:[cell.contentView.subviews objectAtIndex:3]] || [scrollView checkTapPointInCellContent:cell subView:[cell.contentView.subviews objectAtIndex:4]])
        {
            return;
        }
    }
    FbFileItem *openingFile = [arrayFile objectAtIndex:index];
    {
        if (!openingFile.isFolder)
        {
            if (
                [openingFile.path.lowercaseString hasSuffix:@".zip"]) //unzip
            {
                return;
            }
            ThumbnailScrollViewCell * cell = [scrollView cellOfIndex:index];
            if (cell != nil)
            {
                cell.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f];
                cell.layer.cornerRadius = (self.viewMode == 0 ? 0.0f : 5.0f);
                [UIView animateWithDuration:0.2
                                 animations:^{
                                     cell.backgroundColor = [UIColor clearColor];
                                 }
                                 completion:^(BOOL finished) {
                                     {
                                         //this will open file really
                                         openingFile.isOpen = NO;  //here must set the isOpen to NO because in FileList, all the document must be closed when navigation go back, however isOpen is not set because we want to keep the last visit highlight. However it causes a problem in base class if the file is already set isOpen=Yes. So here, make a fake trick to set isOpen=NO.
                                     }
                                     [super thumbnailScrollView:scrollView didTapOnCellAtIndex:index];
                                 }];
            }
        }
        else
        {
            ThumbnailScrollViewCell *cell = [scrollView cellOfIndex:index];
            cell.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f];
            cell.layer.cornerRadius = self.viewMode == 0 ? 0.0f : 5.0f;
            double delayInSeconds = .1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                cell.backgroundColor = [UIColor clearColor];
                if ([openingFile.fileName isEqualToString:@".."])
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self pushFileManageListViewWithFolder:openingFile.path displayName:openingFile.fileName];
                    });
                }
            });
        }
        
    }

}

- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView moreSelectedCellIndex:(NSInteger)cellIndex
{
    FbFileItem *fileObj = [arrayFile objectAtIndex:cellIndex];
    fileObj.isTouchMoving = YES;
    if (scrollView.editing)
    {
        [scrollView reloadCellAtIndex:cellIndex animated:YES];
    }
}

- (void)thumbnailScrollView:(ThumbnailScrollView *)scrollView didCancelSortCellIndexes:(NSArray *)cellIndexes blankCellIndex:(NSInteger)blankCellIndex
{
    
    if (blankCellIndex != -1)
    {
        ThumbnailScrollViewCell *cell = [scrollView cellOfIndex:blankCellIndex];
        if (cell != nil)
        {
            FbFileItem *fileObj = [arrayFile objectAtIndex:blankCellIndex];
            [UIView animateWithDuration:.3
                                  delay:.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 if (!fileObj.isFolder && self.viewMode == 1)
                                 {
                                     UIImageView *imageThumbnail = (UIImageView *)[cell.contentView.subviews objectAtIndex:2];
                                     imageThumbnail.transform = CGAffineTransformIdentity;
                                     UIImageView *imageThumbnailBackground = (UIImageView *)[cell.contentView.subviews objectAtIndex:1];
                                     imageThumbnailBackground.transform = CGAffineTransformIdentity;
                                     UIImageView *imageFolder = (UIImageView *)[cell.contentView.subviews objectAtIndex:0];
                                     imageFolder.hidden = YES;
                                     UILabel *labelPageTitle = (UILabel *)[cell.contentView.subviews objectAtIndex:3];
                                     labelPageTitle.hidden = NO;
                                     UILabel *labelNumberTitle = (UILabel *)[cell.contentView.subviews objectAtIndex:4];
                                     labelNumberTitle.hidden = NO;
                                 }
                                 cell.backgroundColor = [UIColor clearColor];
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
    }

    for (NSNumber *index in cellIndexes)
    {
        FbFileItem *fileObj = [arrayFile objectAtIndex:index.intValue];
        fileObj.isTouchMoving = NO;
    }
    [super thumbnailScrollView:scrollView didCancelSortCellIndexes:cellIndexes blankCellIndex:blankCellIndex];
}

@end

static NSString* getReadableFileSize(unsigned long long byte)
{
    if (byte < 1024)
    {
        return [NSString stringWithFormat:@"%lld B", byte];
    }
    else if(byte < 1024000)
    {
        return [NSString stringWithFormat:@"%.2f KB", byte/1024.0];
    }
    else if(byte < 1024000000)
    {
        return [NSString stringWithFormat:@"%.2f MB", byte/1024000.0];
    }
    else
    {
        return [NSString stringWithFormat:@"%.2f GB", byte/1024000000.0];
    }
}
