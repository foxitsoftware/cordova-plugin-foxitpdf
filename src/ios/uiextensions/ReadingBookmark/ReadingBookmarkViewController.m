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
#import "ReadingBookmarkViewController.h"
#import "Const.h"
#import "ColorUtility.h"
#import "NSMutableArray+Moving.h"
#import "AnnotationListCell.h"
#import "UniversalEditViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AnnotationListMore.h"
#import "AlertView.h"
#import "Masonry.h"


@interface ReadingBookmarkViewController()<ReadingBookmarkListCellDelegate>

- (void)refreshInterface;

@end

@implementation ReadingBookmarkViewController

@synthesize bookmarkGotoPageHandler = _bookmarkGotoPageHandler;
@synthesize bookmarkSelectionHandler = _bookmarkSelectionHandler;
@synthesize isContentEditing = _isContentEditing;
@synthesize arrayBookmarks = _arrayBookmarks;

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl panelController:(PanelController*)panelController
{
    self = [super initWithStyle:style];
    if (self) 
    {
        _pdfViewCtrl = pdfViewCtrl;
        _panelController = panelController;
        self.arrayBookmarks = [[[NSMutableArray alloc] init] autorelease];
        _bookmarkGotoPageHandler = nil;
        _bookmarkSelectionHandler = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChange) name:ORIENTATIONCHANGED object:nil];
        
        self.tableView.allowsSelectionDuringEditing = YES;
        self.moreIndexPath = nil;
        
        [panelController registerPanelChangedListener:self];
    }
    return self;
}

- (void)dealloc
{
    self.arrayBookmarks = nil;
    [_bookmarkGotoPageHandler release];
    [_bookmarkSelectionHandler release];
    [_currentVC release];
    [super dealloc];    
}

- (void)deviceOrientationChange
{
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[ReadingBookmarkListCell class] forCellReuseIdentifier:@"bookmarkcell"];
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
    // Return YES for supported orientations
    return YES;
}

-(void)onPanelChanged:(BOOL)isShow
{
    if (self.isShowMore && !isShow) {
        if (self.moreIndexPath) {
           UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.moreIndexPath];
            AnnotationListMore *listMore = (AnnotationListMore*)[cell viewWithTag:650];
            [listMore tapGuest:nil];
            self.moreIndexPath = nil;
        }
    }
}

#pragma mark - Table view data source and delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{

}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _arrayBookmarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ReadingBookmarkListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bookmarkcell"];
    cell.delegate = self;
    cell.editView.indexPath = indexPath;
    
    FSReadingBookmark *bookmarkItem = [_arrayBookmarks objectAtIndex:indexPath.row];
    cell.pageLabel.text = @"";
    cell.pageLabel.text = [bookmarkItem getTitle];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailButton.object = cell.editView;

    if(0 /*![[APPDELEGATE.app.read getDocMgr].currentDoc canAssemble] || [[APPDELEGATE.app.read getDocMgr].currentDoc isReviewDoc]*/)
    {
        cell.detailButton.enabled = NO;
    }else{
        cell.detailButton.enabled = YES;
    }
    [cell.editView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(cell.editView.superview.mas_right).offset(0);
        make.top.equalTo(cell.editView.superview.mas_top).offset(0);
        make.height.mas_equalTo(50);
        float width;
        
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            width = DEVICE_iPHONE ? SCREENHEIGHT : 300;
        }else{
            width = DEVICE_iPHONE ? SCREENWIDTH : 300;
            
        }
        make.width.mas_equalTo(width);
    }];
    [cell.editView.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
        [cell.editView.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(cell.editView.gestureView.superview.mas_right).offset(0);
            make.top.equalTo(cell.editView.gestureView.superview.mas_top).offset(0);
            make.bottom.equalTo(cell.editView.gestureView.superview.mas_bottom).offset(0);
            float width;
            
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                width = DEVICE_iPHONE ? SCREENHEIGHT : 300;
            }else{
                width = DEVICE_iPHONE ? SCREENWIDTH : 300;
                
            }
            make.width.mas_equalTo(width);
        }];

    }];
    
    
    return cell;
}


- (void)setViewHidden:(id)odject
{
    AnnotationListMore *itemView = (AnnotationListMore *)odject;
    if (self.isShowMore) {
        [UIView animateWithDuration:0.3 animations:^{
            [itemView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(itemView.superview.mas_left).offset(0);
                make.top.equalTo(itemView.superview.mas_top).offset(0);
                make.bottom.equalTo(itemView.superview.mas_bottom).offset(0);
                float width;
                
                if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                    width = DEVICE_iPHONE ? SCREENHEIGHT : 300;
                }else{
                    width = DEVICE_iPHONE ? SCREENWIDTH : 300;
                    
                }
                make.width.mas_equalTo(width);
            }];
            
            [itemView.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(itemView.gestureView.superview.mas_left).offset(0);
                make.top.equalTo(itemView.gestureView.superview.mas_top).offset(0);
                make.bottom.equalTo(itemView.gestureView.superview.mas_bottom).offset(0);
                float width;
                
                if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                    width = DEVICE_iPHONE ? SCREENHEIGHT : 300;
                }else{
                    width = DEVICE_iPHONE ? SCREENWIDTH : 300;
                    
                }
                make.width.mas_equalTo(width);
            }];
            
        }];
    }
    self.isShowMore = YES;
    self.moreIndexPath = itemView.indexPath;
    [itemView setCellViewHidden:NO isMenu:NO];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FSReadingBookmark *bookmarkItem = [_arrayBookmarks objectAtIndex:indexPath.row];
    if (self.isContentEditing)
    {
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        if(self.bookmarkSelectionHandler)
        {
            self.bookmarkSelectionHandler();
        }
    }
    else 
    {
        _panelController.isHidden = YES;
        [_pdfViewCtrl gotoPage:[bookmarkItem getPageIndex] animated:NO];
    }
}

- (void)renameBookmarkWithIndex:(NSInteger)index
{
    FSReadingBookmark *bookmark = [_arrayBookmarks objectAtIndex:index];
    if (!DEVICE_iPHONE)
    {
        selectBookmark = bookmark;
        TSAlertView* alertView = [[TSAlertView alloc] init];
        alertView.title = NSLocalizedString(@"kRenameBookmark", nil);
        alertView.message = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"kRenameBookmark", nil), [bookmark getTitle]];
        [alertView addButtonWithTitle:NSLocalizedString(@"kCancel", nil)];
        [alertView addButtonWithTitle:NSLocalizedString(@"kRename", nil)];
        alertView.style = TSAlertViewStyleInputText;
        alertView.buttonLayout = TSAlertViewButtonLayoutNormal;
        alertView.usesMessageTextView = NO;
        alertView.delegate = self;
        alertView.tag = 1;
        alertView.inputTextField.text = [bookmark getTitle];
        [alertView show];
        self.currentVC = alertView;
        [alertView release];
        
    } else
    {
        BOOL isFullScreen = APPLICATION_ISFULLSCREEN;
        __block UniversalEditViewController *editController = [[[UniversalEditViewController alloc] initWithNibName:[Utility getXibName:@"UniversalEditViewController"] bundle:nil] autorelease];
        UINavigationController *editNavController = [[[UINavigationController alloc] initWithRootViewController:editController] autorelease];
        editController.title = NSLocalizedString(@"kRenameBookmark", nil);
        editController.textContent = [bookmark getTitle];
        editController.autoIntoEditing = YES;
        self.currentVC = editNavController;
        self.currentVC = editController;
        editController.editingCancelHandler = ^
        {
            [editController dismissModalViewControllerAnimated:YES];
            [[UIApplication sharedApplication] setStatusBarHidden:isFullScreen withAnimation:UIStatusBarAnimationFade];
        };
        editController.editingDoneHandler = ^(NSString *text) {
            text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (text == nil || text.length == 0)
            {
                AlertView *alertView = [[[AlertView alloc] initWithTitle:@"kWarning" message:@"kInputBookmarkName" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil] autorelease];
                self.currentVC = alertView;
                [alertView show];
            }
            else
            {
                [bookmark setTitle:text];
                [self renameBookmark:bookmark];
                [editController dismissModalViewControllerAnimated:YES];
                [[UIApplication sharedApplication] setStatusBarHidden:isFullScreen withAnimation:UIStatusBarAnimationFade];
            }
        };
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:editNavController animated:YES completion:^{
            
        }];
    }
}

- (void)deleteBookmarkWithIndex:(NSInteger)index
{
    FSReadingBookmark *deletedBookmark = [_arrayBookmarks objectAtIndex:index];
    NSUInteger pageIndex = [deletedBookmark getPageIndex];
    [_pdfViewCtrl.currentDoc removeReadingBookmark:deletedBookmark];
   
    NSAssert(deletedBookmark != nil, @"Delete bookmark cannot find the position of page index: %d", pageIndex);
    NSUInteger deletePos = [_arrayBookmarks indexOfObject:deletedBookmark];
    [_arrayBookmarks removeObject:deletedBookmark];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:deletePos inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    if (self.bookmarkDeleteHandler) {
        self.bookmarkDeleteHandler();
        [self performSelector:@selector(reloadtableViewAfterDeleteBookmark) withObject:nil afterDelay:0.5];
    }
}

-(void)reloadtableViewAfterDeleteBookmark
{
    [self.tableView reloadData];
}

- (void)alertView:(TSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1)
    {
        if (buttonIndex == 1)
        {
            TSAlertView *tsAlertView = (TSAlertView *)alertView;
            NSString *newName = [tsAlertView.inputTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if(newName == nil || newName.length == 0)
            {
                AlertView *alertView = [[[AlertView alloc] initWithTitle:@"kWarning" message:@"kInputBookmarkName" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil] autorelease];
                self.currentVC = alertView;
                [alertView show];
                return;
            }
            
            if ([newName compare:[selectBookmark getTitle]] != NSOrderedSame)
            {
                [selectBookmark setTitle:newName];
                [self renameBookmark:selectBookmark];
            }
        }
    }
}

- (void)loadData
{
    NSMutableArray* bookmarks = [[[NSMutableArray alloc] init] autorelease];
    int count = [_pdfViewCtrl.currentDoc getReadingBookmarkCount];
    for(int i=0; i<count; i++)
    {
        [bookmarks addObject:[_pdfViewCtrl.currentDoc getReadingBookmark:i]];
    }
    self.arrayBookmarks = bookmarks;
    [self.tableView reloadData];
}


- (void)clearData:(BOOL)fromPDF;
{
    if (fromPDF) {
        for (FSReadingBookmark *item in _arrayBookmarks)
        {
            [_pdfViewCtrl.currentDoc removeReadingBookmark:item];
        }
    }
    
    if (self.isShowMore) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.moreIndexPath];
        AnnotationListMore *editView = (AnnotationListMore *)[cell.contentView viewWithTag:650];
        [editView tapGuest:nil];
    }
    [_arrayBookmarks removeAllObjects];
    [self.tableView reloadData];
}

- (NSUInteger)getBookmarkCount
{
    return [_arrayBookmarks count];
}

- (void)addBookmark:(FSReadingBookmark *)newBookmark
{
    [_arrayBookmarks addObject:newBookmark];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_arrayBookmarks.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)renameBookmark:(FSReadingBookmark *)renameBookmark
{
    NSUInteger rowIndex = [_arrayBookmarks indexOfObject:renameBookmark];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowIndex inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Private methods

- (void)refreshInterface
{
    UIView *view = [[[UIView alloc] init] autorelease];
    view.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:view];

}

@end
