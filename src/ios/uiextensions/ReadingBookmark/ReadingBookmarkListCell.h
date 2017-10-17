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

#import "AnnotationListMore.h"
#import "Const.h"
#import <UIKit/UIKit.h>

@interface ReadingBookmarkButton : UIButton
@property (nonatomic, assign) id object;
@end

@class ReadingBookmarkListCell;

@protocol ReadingBookmarkListCellDelegate <NSObject>

- (void)readingBookmarkListCellWillShowEditView:(ReadingBookmarkListCell *)cell;
- (void)readingBookmarkListCellDidShowEditView:(ReadingBookmarkListCell *)cell;
- (void)readingBookmarkListCellDelete:(ReadingBookmarkListCell *)cell;
- (void)readingBookmarkListCellRename:(ReadingBookmarkListCell *)cell;

@end

@interface ReadingBookmarkListCell : UITableViewCell

@property (nonatomic, strong) ReadingBookmarkButton *detailButton;
@property (nonatomic, strong) UILabel *pageLabel;
@property (nonatomic, strong) AnnotationListMore *editView;
@property (nonatomic, assign) BOOL editViewHidden;
@property (nonatomic, assign) id<ReadingBookmarkListCellDelegate> delegate;

@end
