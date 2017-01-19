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

#import "FileManageBaseViewController.h"
#import "IFbFileDelegate.h"
#import "UIExtensionsSharedHeader.h"

@interface FileManageListViewController : FileManageBaseViewController <UIGestureRecognizerDelegate ,UITableViewDelegate,UITableViewDataSource>
{
    BOOL _orientationChanged;
    UITableView *moreTableView;
    NSMutableArray * selectedFileObjectsForFileCompare;

}

@property (retain, nonatomic) IBOutlet UIView *viewHeader;
@property (retain, nonatomic) UIButton *buttonBackiPhone;
@property (assign, nonatomic) BOOL isEditing;  //Note: make this a property so that FileManagebaseViewController openOutsideFileUI can force it NO when open outside file
@property (retain, nonatomic) IBOutlet UIButton *buttonViewMode;
@property (retain, nonatomic) UIView *messageView;
@property (retain, nonatomic) UIView *grayView;
@property (assign, nonatomic) BOOL isReadingFileAction;

- (void)sortFileByType:(FileSortType)sortType andFileSortMode:(FileSortMode)sortMode;

- (void)changeThumbnailFrame:(BOOL)change;

- (void)buttonChangeViewMode;
@end
