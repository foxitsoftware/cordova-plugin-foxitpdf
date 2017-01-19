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
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "OutlineViewController.h"
#import "ColorUtility.h"
#import "MASConstraintMaker.h"
#import "View+MASAdditions.h"
#import "PanelController.h"
#import <QuartzCore/QuartzCore.h>


@implementation OutlineButton

@end

@interface OutlineViewController() {
    FSPDFViewCtrl* _pdfViewCtrl;
    PanelController* _panelController;
}

- (void)refreshInterface;

@end

@implementation OutlineViewController

@synthesize outlineGotoPageHandler = _outlineGotoPageHandler;
@synthesize hasParentOutline;

- (id)initWithStyle:(UITableViewStyle)style pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl panelController:(PanelController*)panelController
{
    self = [super initWithStyle:style];
    if (self) 
    {
        _pdfViewCtrl = pdfViewCtrl;
        _panelController = panelController;
        _arrayOutlines = [[NSMutableArray alloc] init];
        _outlineGotoPageHandler = nil;
        if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.tableView setSeparatorInset:UIEdgeInsetsMake(0,10,0,0)];
        }
        
    }
    return self;
}

- (void)dealloc
{
    [_arrayOutlines release];
    [_outlineGotoPageHandler release];
    [super dealloc];    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refreshInterface];
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0,10,0,0)];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsMake(0,10,0,0)];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsMake(0,10,0,0)];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsMake(0,10,0,0)];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.hasParentOutline ? (_arrayOutlines.count+1) : _arrayOutlines.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.hasParentOutline && indexPath.row == 0) {
        UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        UIImageView *backImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"panel_outline_comeback"]] autorelease];
        [cell.contentView addSubview:backImageView];
        UILabel *backLabel = [[[UILabel alloc] init] autorelease];
        backLabel.textColor = [UIColor grayColor];
        backLabel.text = @"...";
        [cell.contentView addSubview:backLabel];
        
        [backImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(cell.contentView.mas_centerY);
            make.left.mas_equalTo(15);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        [backLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(cell.contentView.mas_centerY);
            make.left.equalTo(backImageView.mas_right).offset(3);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    
    static NSString *cellIdentifier = @"outlineCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) 
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        cell.backgroundColor = [UIColor clearColor];
        OutlineButton *detailButton = [OutlineButton buttonWithType:UIButtonTypeCustom];
        detailButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        [detailButton addTarget:self action:@selector(detailOutline:) forControlEvents:UIControlEventTouchUpInside];
        detailButton.frame = CGRectMake(cell.frame.size.width-48, 0, 48, 40);
        detailButton.center = CGPointMake(detailButton.center.x, cell.frame.size.height/2);
        detailButton.tag = 30;
        [cell addSubview:detailButton];
    }
    OutlineButton *button = (OutlineButton *)[cell viewWithTag:30];
    button.indexPath = indexPath;
    int bookmarkIndex = (int)indexPath.row;
    if (self.hasParentOutline)
    {
        bookmarkIndex --;
    }
    FSBookmark *bookmarkItem = [_arrayOutlines objectAtIndex:bookmarkIndex];
    cell.textLabel.text = [bookmarkItem getTitle];
    [cell.textLabel setFont:[UIFont systemFontOfSize:17]];
    BOOL hasChild = [bookmarkItem getFirstChild] ? YES : NO;
    button.hidden = !hasChild;
    cell.accessoryType = hasChild ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.hasParentOutline && indexPath.row == 0)  //go to parent outline
    {
        [self.navigationController popViewControllerAnimated:YES];
        numberofPush-=1;
    }
    else 
    {
        _panelController.isHidden = YES;
        FSBookmark *bookmarkItem = [_arrayOutlines objectAtIndex:self.hasParentOutline?(indexPath.row-1):indexPath.row];
        FSDestination* dest = [bookmarkItem getDestination];
        if (nil == dest) return;
        FSPointF* point = [[FSPointF alloc] init];
        [point set:[dest getLeft] y:[dest getTop]];
        [_pdfViewCtrl gotoPage:[dest getPageIndex] withDocPoint:point animated:NO];
        [point release];
    }
}

- (void)detailOutline:(id)sender
{
    numberofPush+=1;
    OutlineButton *button = (OutlineButton *)sender;
    OutlineViewController *subOutlineViewCtrl = [[OutlineViewController alloc] initWithStyle:UITableViewStylePlain pdfViewCtrl:_pdfViewCtrl panelController:_panelController];
    subOutlineViewCtrl.hasParentOutline = YES;
    FSBookmark *bookmarkItem = [_arrayOutlines objectAtIndex:self.hasParentOutline?(button.indexPath.row-1):button.indexPath.row];
    [subOutlineViewCtrl loadData:bookmarkItem];
    subOutlineViewCtrl.outlineGotoPageHandler = self.outlineGotoPageHandler;
    [self.navigationController pushViewController:subOutlineViewCtrl animated:YES];
    [subOutlineViewCtrl release];
}

#pragma mark - methods

- (NSArray*)getBookmark:(FSBookmark*)parentBookmark
{
    NSMutableArray *array = [NSMutableArray array];
    FSBookmark* bmChild = [parentBookmark getFirstChild];
    if (bmChild)
    {
        [array addObject:bmChild];
        FSBookmark* bmNext = [bmChild getNextSibling];
        while (bmNext) {
            [array addObject:bmNext];
            bmNext = [bmNext getNextSibling];
        }
    }
    return [NSArray arrayWithArray:array];
}

/** @brief Receive all the children of specified bookmark. */
- (NSArray*)getOutline:(FSBookmark*)bookmark
{
    __block BOOL needRelease = NO;
    __block NSArray *ret = [NSArray array];
    
    if (bookmark == nil)
    {
        bookmark = [[_pdfViewCtrl getDoc] getFirstBookmark];
        needRelease = YES;
    }

    ret = [self getBookmark:bookmark];
    return ret;
}

- (void)getOutline:(FSBookmark *)bookmark getOutlineFinishHandler:(GetBookmarkFinishHandler)getOutlineFinishHandler
{
    getOutlineFinishHandler = [getOutlineFinishHandler copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *bookmarks = [self getOutline:bookmark];
        //here get the bookmark array with bookmarkName, pageIndex and nativeBookmark assigned, but bookmarkIndexes is not assigned yet
        NSMutableArray *fixedBookmarks = [NSMutableArray array];
        for (int i = 0; i < bookmarks.count; i++)
        {
            FSBookmark *bookmarkItem = [bookmarks objectAtIndex:i];
            [fixedBookmarks addObject:bookmarkItem];
        }
        if (getOutlineFinishHandler)
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                getOutlineFinishHandler(fixedBookmarks);
            });
        }
        
        [getOutlineFinishHandler release];
    });
}

- (void)loadData:(FSBookmark *)parentBookmark
{
    [self getOutline:parentBookmark getOutlineFinishHandler:^(NSMutableArray *bookmark) {
        [_arrayOutlines release];
        _arrayOutlines = [bookmark retain];
        [self.tableView reloadData];
    }];
}

- (void)clearData
{
    [_arrayOutlines removeAllObjects];
    for (NSInteger i = 0; i < numberofPush; i++) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    numberofPush = 0;
    [self.tableView reloadData];
}

#pragma mark - Private methods

- (void)refreshInterface
{
    UIView *view = [[UIView alloc]init];
    view.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:view];
    [view release];
}

@end
