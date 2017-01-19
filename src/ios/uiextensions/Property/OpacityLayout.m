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
#import "OpacityLayout.h"
#import <UIKit/UIKit.h>
#import "PropertyBar.h"
#import "Utility.h"
#import "Const.h"
#import "ColorUtility.h"

@interface OpacityLayout ()

@property (nonatomic, retain) NSArray *opacitys;
@property (nonatomic, retain) UILabel *title;
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, assign) int currentOpacity;
@property (nonatomic, retain) id<IPropertyValueChangedListener> currentListener;
@property (nonatomic, assign) CGFloat screenWidth;

@end

@implementation OpacityLayout


- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.title = [[[UILabel alloc] initWithFrame:CGRectMake(20, 3, frame.size.width, LAYOUTTITLEHEIGHT)] autorelease];
        self.title.text = NSLocalizedString(@"kOpacity", nil);
        self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
        self.title.font = [UIFont systemFontOfSize:11.0f];
        self.items = [NSMutableArray array];
        [self addSubview:self.title];
        [self addOpacityItem];
    }
    return self;
}

-(long)supportProperty
{
    return PROPERTY_OPACITY;
}

- (void)setCurrentOpacity:(int)opacity
{
    _currentOpacity = opacity;
    for (OpacityItem *item in self.items) {
        if (item.opacity == opacity) {
            [item setSelected:YES];
        }
        else
        {
            [item setSelected:NO];
        }
    }
}

- (void)setCurrentListener:(id<IPropertyValueChangedListener>)listener
{
    _currentListener = listener;
}

-(void)addOpacityItem
{
    int itemWidth = 32;
    if (DEVICE_iPHONE) {
        
         if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
         {
              self.screenWidth = [UIScreen mainScreen].bounds.size.height;
         }
         else
         {
             self.screenWidth = [UIScreen mainScreen].bounds.size.width;
         }
        int divideWidth = (_screenWidth - ITEMLRSPACE*2 - itemWidth*4)/3;
        for (int i = 0; i < 4; i++) {
            CGRect itemFrame = CGRectMake(ITEMLRSPACE + i*itemWidth + i*divideWidth, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, itemWidth + 15);
            OpacityItem *item = [[[OpacityItem alloc] initWithFrame:itemFrame] autorelease];
            [item setOpacity:25*(i+1)];
            item.callback = ^(long property,int value)
            {
                [_currentListener onIntValueChanged:property value:value];
                [self setCurrentOpacity:value];
            };
            [self addSubview:item];
            [self.items addObject:item];
        }
    }
    else
    {
        float screenWidth = self.frame.size.width;
        int divideWidth = (screenWidth - ITEMLRSPACE*2 - itemWidth*4)/3;
        for (int i = 0; i < 4; i++) {
            CGRect itemFrame = CGRectMake(ITEMLRSPACE + i*itemWidth + i*divideWidth, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, itemWidth + 15);
            OpacityItem *item = [[[OpacityItem alloc] initWithFrame:itemFrame] autorelease];
            [item setOpacity:25*(i+1)];
            item.callback = ^(long property,int value)
            {
                [_currentListener onIntValueChanged:property value:value];
                [self setCurrentOpacity:value];
            };
            [self addSubview:item];
            [self.items addObject:item];
        }
    }
    self.layoutHeight = itemWidth + 15 + LAYOUTTITLEHEIGHT + LAYOUTTBSPACE*2;
}

-(void)addDivideView
{
    for (UIView *view in self.subviews) {
        if (view.tag == 1000) {
            [view removeFromSuperview];
        }
    }
    UIView *divide = [[[UIView alloc] initWithFrame:CGRectMake(20, self.frame.size.height - 1, self.frame.size.width - 40, [Utility realPX:1.0f])] autorelease];
    divide.tag = 1000;
    divide.backgroundColor = [UIColor colorWithRGBHex:0x5c5c5c];
    divide.alpha = 0.2f;
    [self addSubview:divide];
    [divide release];
}

- (void)resetLayout
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    self.title = [[[UILabel alloc] initWithFrame:CGRectMake(20, 3, self.frame.size.width, LAYOUTTITLEHEIGHT)] autorelease];
    self.title.text = NSLocalizedString(@"kOpacity", nil);
    self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
    self.title.font = [UIFont systemFontOfSize:11.0f];
    [self addSubview:self.title];
    [self addOpacityItem];
    [self setCurrentOpacity:_currentOpacity];
}
@end
