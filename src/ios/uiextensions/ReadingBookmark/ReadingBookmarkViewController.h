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
#import <FoxitRDK/FSPDFViewControl.h>
#import "../Panel/PanelController.h"
#import "ReadingBookmarkListCell.h"
@class FileDetailViewController;

typedef void (^ReadingBookmarkGotoPageHandler)(int page);
typedef void (^ReadingBookmarkSelectionHandler)();
typedef void (^ReadingBookmarkDeleteHandler)();



@interface ReadingBookmarkViewController : UITableViewController<IPanelChangedListener>
{
    FSReadingBookmark *selectBookmark;
    FSPDFViewCtrl* _pdfViewCtrl;
}

@property (nonatomic, copy) ReadingBookmarkGotoPageHandler bookmarkGotoPageHandler;
@property (nonatomic, copy) ReadingBookmarkSelectionHandler bookmarkSelectionHandler;
@property (nonatomic, copy) ReadingBookmarkDeleteHandler bookmarkDeleteHandler;

//a common way to do for bookmark and annotation

@property (nonatomic, retain) NSMutableArray *arrayBookmarks;
@property (nonatomic, assign) BOOL isContentEditing;
@property (nonatomic, assign) BOOL isShowMore;
@property (nonatomic, retain) NSIndexPath *moreIndexPath;
@property (nonatomic, retain) NSObject *currentVC;
@property (nonatomic, retain) PanelController* panelController;

- (void)loadData;
- (void)clearData:(BOOL)fromPDF;
- (NSUInteger)getBookmarkCount;

- (void)addBookmark:(FSReadingBookmark *)newBookmark;
- (void)renameBookmark:(FSReadingBookmark *)renameBookmark;

- (void)renameBookmarkWithIndex:(NSInteger)index;
- (void)deleteBookmarkWithIndex:(NSInteger)index;


@end
