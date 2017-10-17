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

#import "../Panel/PanelController.h"
#import <FoxitRDK/FSPDFObjC.h>
#import <UIKit/UIKit.h>

typedef void (^GetBookmarkFinishHandler)(NSMutableArray *bookmark);

@interface OutlineButton : UIButton

@property (nonatomic, strong) NSIndexPath *indexPath;

@end

typedef void (^OutlineGotoPageHandler)(int page);

/** @brief The view controller for bookmarks. */
@interface OutlineViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *arrayOutlines;
@property (copy, nonatomic) OutlineGotoPageHandler outlineGotoPageHandler;
@property (assign, nonatomic) BOOL hasParentOutline;

- (id)initWithStyle:(UITableViewStyle)style pdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl panelController:(FSPanelController *)panelController;
- (NSArray *)getBookmark:(FSBookmark *)parentBookmark;
- (NSArray *)getOutline:(FSBookmark *)bookmark;
- (void)getOutline:(FSBookmark *)bookmark getOutlineFinishHandler:(GetBookmarkFinishHandler)getOutlineFinishHandler;
- (void)loadData:(FSBookmark *)parentBookmark;
- (void)clearData;

@end
