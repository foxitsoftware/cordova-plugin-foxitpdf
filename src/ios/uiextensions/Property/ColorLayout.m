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
#import "PropertyBar.h"
#import "Const.h"
#import "Utility.h"
#import "ColorUtility.h"

@interface ColorLayout ()

@property (nonatomic, retain) UILabel *title;
@property (nonatomic, retain) NSArray *colors;
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, assign) int currentColor;
@property (nonatomic, retain) id<IPropertyValueChangedListener> currentListener;

@end

@implementation ColorLayout {
    PropertyBar* _propertyBar;
}

- (instancetype)initWithFrame:(CGRect)frame propertyBar:(PropertyBar*)propertyBar
{
    self = [super initWithFrame:frame];
    if (self) {
        _propertyBar = propertyBar;
        self.title = [[UILabel alloc] initWithFrame:CGRectMake(20, 3, frame.size.width, LAYOUTTITLEHEIGHT)];
        self.title.text = NSLocalizedString(@"kColor", nil);
        self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
        self.title.font = [UIFont systemFontOfSize:11.0f];
        self.items = [NSMutableArray array];
        [self addSubview:self.title];
    }
    return self;
}

-(long)supportProperty
{
    return PROPERTY_COLOR;
}

- (void)setColors:(NSArray*)array
{
    _colors = array;
    [self addColorItem];
}

- (void)setCurrentColor:(int)color
{
    _currentColor = color;
    if (_propertyBar.lineWidthLayout) {
        [_propertyBar.lineWidthLayout setCurrentColor:color];
    }
    for (ColorItem *item in self.items) {
        if (item.color == color) {
            [item setSelected:YES];
        }
        else
        {
            [item setSelected:NO];
        }
    }
}

-(void)setCurrentListener:(id<IPropertyValueChangedListener>)currentListener
{
    _currentListener = currentListener;
}

- (void)addColorItem
{
    CGRect layoutFrame = self.frame;
    if (([UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeLeft||[UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeRight) && DEVICE_iPHONE)
    {
        int itemWidth = (layoutFrame.size.width - 11*ITEMLRSPACE)/10;
        for (int i = 0; i < _colors.count; i++) {
            NSNumber *color = [_colors objectAtIndex:i];
            CGRect itemFrame = CGRectMake(ITEMLRSPACE*(i+1) + i*itemWidth, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, itemWidth);
            ColorItem *item = [[ColorItem alloc] initWithFrame:itemFrame];
            item.color = color.intValue;
            [item setSelected:NO];
            item.callback = ^(long property,int value){
                [_currentListener onIntValueChanged:property value:value];
                [self setCurrentColor:value];
            };
            [self addSubview:item];
            [self.items addObject:item];
        }
        self.layoutHeight = itemWidth + LAYOUTTITLEHEIGHT + LAYOUTTBSPACE*2;//30 top 10 bottom
    }
    else
    {
        int itemWidth = (layoutFrame.size.width - 6*ITEMLRSPACE)/5;
        for (int i = 0; i < _colors.count; i++) {
            NSNumber *color = [_colors objectAtIndex:i];
            CGRect itemFrame;
            if (i <= 4) {
                itemFrame = CGRectMake(ITEMLRSPACE*(i+1) + i*itemWidth, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, itemWidth);
            }
            else
            {
                itemFrame = CGRectMake(ITEMLRSPACE*(i-5+1) + (i - 5)*itemWidth, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE + itemWidth + LAYOUTTBSPACE, itemWidth, itemWidth);
            }
            ColorItem *item = [[ColorItem alloc] initWithFrame:itemFrame];
            item.color = color.intValue;
            [item setSelected:NO];
            item.callback = ^(long property,int value){
                [_currentListener onIntValueChanged:property value:value];
                [self setCurrentColor:value];
            };
            [self addSubview:item];
            [self.items addObject:item];
        }
        self.layoutHeight = itemWidth*2 + LAYOUTTITLEHEIGHT + LAYOUTTBSPACE*3;
    }
    
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
    
}

- (void)resetLayout
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    [self.items removeAllObjects];
    self.title = [[UILabel alloc] initWithFrame:CGRectMake(20, 3, self.frame.size.width, LAYOUTTITLEHEIGHT)];
    self.title.text = NSLocalizedString(@"kColor", nil);
    self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
    self.title.font = [UIFont systemFontOfSize:11.0f];
    [self addSubview:self.title];
    [self addColorItem];
    [self setCurrentColor:_currentColor];
}

@end
