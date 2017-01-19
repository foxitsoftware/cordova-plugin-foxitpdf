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
#import "FoxitRDK/FSPDFObjC.h"
#import "../Panel/PanelController.h"

typedef void (^GetBookmarkFinishHandler)(NSMutableArray* bookmark);

@interface OutlineButton : UIButton

@property(nonatomic,retain)NSIndexPath *indexPath;

@end


typedef void (^OutlineGotoPageHandler)(int page);

static NSInteger numberofPush = 0;

/** @brief The view controller for bookmarks. */
@interface OutlineViewController : UITableViewController

@property (nonatomic, retain) NSMutableArray *arrayOutlines;
@property (copy, nonatomic) OutlineGotoPageHandler outlineGotoPageHandler;
@property (assign, nonatomic) BOOL hasParentOutline;

- (id)initWithStyle:(UITableViewStyle)style pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl panelController:(PanelController*)panelController;
- (NSArray*)getBookmark:(FSBookmark*)parentBookmark;
- (NSArray*)getOutline:(FSBookmark*)bookmark;
- (void)getOutline:(FSBookmark *)bookmark getOutlineFinishHandler:(GetBookmarkFinishHandler)getOutlineFinishHandler;
- (void)loadData:(FSBookmark *)parentBookmark;
- (void)clearData;

@end
