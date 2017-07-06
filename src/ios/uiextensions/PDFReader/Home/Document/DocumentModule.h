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

#import "../../Thirdparties/DXPopover/DXPopover.h"
#import "../../UIExtensionsSharedHeader.h"
#import "../../FSPDFReader.h"

@class FSPDFReader;
@class FbFileBrowser;

// Document module to manage the pdf file list in the home directory.
@interface DocumentModule : NSObject<IFbFileDelegate>
{
    FileSortType sortType;
    FileSortMode sortMode;
    int viewMode;
    
	TbBaseBar *topToolbar;
	UIView *contentView;
    FbFileBrowser * browser;
    DXPopover *popover;
    TbBaseBar *fileBrowser;
    UILabel *previousPath;
    UILabel *currentPath;
    NSMutableArray *pathItems;
    UIImageView *nextImage;
    UIImageView *dateimage;
    UIImageView *nameimage;
    UIImageView *sizeimage;
    TbBaseItem *thumbnailItem;
    
    BOOL isShowMorePopover;
    BOOL isShowSortPopover;
}
@property(nonatomic, weak) TbBaseItem *sortNameItem;
@property(nonatomic, strong) UIView *rootView;

- (instancetype)initWithReadFrame:(FSPDFReader*)pdfReader;
- (void) reframingSortContainerView;
-(UIView *)getTopToolbar;
-(UIView *)getContentView;
@end

