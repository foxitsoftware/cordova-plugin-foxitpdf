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
#import "AnnotationListMore.h"
#import "Const.h"
@interface ReadingBookmarkButton : UIButton
@property(nonatomic,assign)id object;
@end

@protocol ReadingBookmarkListCellDelegate <NSObject>

- (void)setEditViewHiden:(ReadingBookmarkButton *)button;

@end


@interface ReadingBookmarkListCell : UITableViewCell
@property (nonatomic, retain) ReadingBookmarkButton *detailButton;
@property (nonatomic, retain) UILabel *pageLabel;
@property (nonatomic, retain) AnnotationListMore *editView;
@property (nonatomic, retain)NSIndexPath *indexPath;
@property (nonatomic, assign)id<ReadingBookmarkListCellDelegate>delegate;
@end
