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

@class ThumbnailScrollView;
@interface ThumbnailScrollViewCell : UIView<UIGestureRecognizerDelegate>
{
    UIView *_badgeView;
    UISwipeGestureRecognizer *_swipeGestureRecognizer;
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@property (copy, nonatomic) NSString *reuseIdentifier; 
@property (retain, nonatomic) UIView *contentView;
@property (retain, nonatomic) UIView *containerView;
@property (retain, nonatomic) UIImageView *backgroundBadge;
@property (retain, nonatomic) UILabel *labelBadge;
@property (retain, nonatomic) NSString *badgeValue;
@property (assign, nonatomic) BOOL editing;
@property (assign, nonatomic) ThumbnailScrollView *scrollView;
@property (assign, nonatomic) BOOL aloneEditing;
@property (retain, nonatomic) id reserveObj;
@property (assign, nonatomic) BOOL alwaysHideCheckBox;

- (void)prepareForReuse;
- (UIImage *)cloneCellImage;
@end
