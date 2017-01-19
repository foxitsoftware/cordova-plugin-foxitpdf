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

/** @brief The custom UI, which has a similar UI like a button. */
@interface SegmentItem : NSObject
@property(nonatomic,retain)NSString *title;
@property(nonatomic,retain)UIImage *image;
@property(nonatomic,retain)UIImage *selectImage;
@property(nonatomic,assign)NSUInteger tag;
@property(nonatomic,retain)UIColor *titleNormalColor;
@property(nonatomic,retain)UIColor *titleSelectedColor;
@end

/** @brief Delegate for item clicking. */
@protocol SegmentDelegate <NSObject>
- (void)itemClickWithItem:(SegmentItem *)item;
@end

/** @brief The custom UI, which is as the container of SegmentItem. */
@interface SegmentView : UIView
{
    NSMutableArray *itemsArray;
}
@property(nonatomic,assign)id<SegmentDelegate> delegate;
- (id)initWithFrame:(CGRect)frame segmentItems:(NSArray *)items;
- (void)setSelectItem:(SegmentItem *)item;
- (NSArray *)getItems;
@end
