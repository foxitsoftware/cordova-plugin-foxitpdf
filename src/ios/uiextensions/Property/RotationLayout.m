/**
 * Copyright (C) 2003-2018, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "RotationLayout.h"
#import "ColorUtility.h"
#import "Const.h"
#import "PropertyBar.h"
#import "RotationItem.h"
#import "Utility.h"
#import <UIKit/UIKit.h>

@interface RotationLayout ()

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) int currentRotation;
@property (nonatomic, strong) id<IPropertyValueChangedListener> currentListener;
@property (nonatomic, assign) CGFloat screenWidth;

@end

@implementation RotationLayout

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.title = [[UILabel alloc] initWithFrame:CGRectMake(20, 3, frame.size.width, LAYOUTTITLEHEIGHT)];
        self.title.text = FSLocalizedString(@"kRotation");
        self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
        self.title.font = [UIFont systemFontOfSize:11.0f];
        self.items = [NSMutableArray array];
        [self addSubview:self.title];
        [self addRotationItem];
    }
    return self;
}

- (long)supportProperty {
    return PROPERTY_ROTATION;
}

- (void)setCurrentRotation:(int)rotation {
    _currentRotation = rotation;
    for (RotationItem *item in self.items) {
        if (item.rotation == rotation) {
            [item setSelected:YES];
        } else {
            [item setSelected:NO];
        }
    }
}

- (void)setCurrentListener:(id<IPropertyValueChangedListener>)listener {
    _currentListener = listener;
}

- (void)addRotationItem {
    CGSize itemSize = [UIImage imageNamed:@"property_rotation_background"].size;
    int itemWidth = itemSize.width;
    int itemHeight = itemSize.height;
    if (DEVICE_iPHONE) {
        self.screenWidth = CGRectGetWidth(self.frame);
        int divideWidth = (_screenWidth - ITEMLRSPACE * 2 - itemWidth * 4) / 3;
        for (int i = 0; i < 4; i++) {
            CGRect itemFrame = CGRectMake(ITEMLRSPACE + i * itemWidth + i * divideWidth, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, itemHeight);
            RotationItem *item = [[RotationItem alloc] initWithFrame:itemFrame];
            [item setRotation:90 * i];
            item.callback = ^(long property, int value) {
                [_currentListener onProperty:property changedFrom:@(_currentRotation) to:@(value)];
                [self setCurrentRotation:value];
            };
            [self addSubview:item];
            [self.items addObject:item];
        }
    } else {
        float screenWidth = self.frame.size.width;
        int divideWidth = (screenWidth - ITEMLRSPACE * 2 - itemWidth * 4) / 3;
        for (int i = 0; i < 4; i++) {
            CGRect itemFrame = CGRectMake(ITEMLRSPACE + i * itemWidth + i * divideWidth, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, itemHeight);
            RotationItem *item = [[RotationItem alloc] initWithFrame:itemFrame];
            [item setRotation:90 * i];
            item.callback = ^(long property, int value) {
                [_currentListener onProperty:property changedFrom:@(_currentRotation) to:@(value)];
                [self setCurrentRotation:value];
            };
            [self addSubview:item];
            [self.items addObject:item];
        }
    }
    self.layoutHeight = itemHeight + 15 + LAYOUTTITLEHEIGHT + LAYOUTTBSPACE * 2;
}

- (void)addDivideView {
    for (UIView *view in self.subviews) {
        if (view.tag == 1000) {
            [view removeFromSuperview];
        }
    }
    UIView *divide = [[UIView alloc] initWithFrame:CGRectMake(20, self.frame.size.height - 1, self.frame.size.width - 40, [Utility realPX:1.0f])];
    divide.tag = 1000;
    divide.backgroundColor = [UIColor colorWithRGBHex:0x5c5c5c];
    divide.alpha = 0.2f;
    [self addSubview:divide];
}

- (void)resetLayout {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }

    self.title = [[UILabel alloc] initWithFrame:CGRectMake(20, 3, self.frame.size.width, LAYOUTTITLEHEIGHT)];
    self.title.text = FSLocalizedString(@"kRotation");
    self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
    self.title.font = [UIFont systemFontOfSize:11.0f];
    [self addSubview:self.title];
    [self addRotationItem];
    [self setCurrentRotation:_currentRotation];
}
@end
