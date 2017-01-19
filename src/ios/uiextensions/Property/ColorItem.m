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
#import "ColorItem.h"
#import "ColorUtility.h"

@interface ColorItem ()

@property (nonatomic, retain) UIButton *button;

@end

@implementation ColorItem

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        self.button.frame = CGRectMake(4, 4, frame.size.width - 8, frame.size.height - 8);
        self.button.layer.borderWidth = 1.0;
        self.button.layer.borderColor = [UIColor colorWithRGBHex:0xB2B2B2].CGColor;
        [self.button addTarget:self action:@selector(onClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.button];
    }
    return self;
}

-(void)setColor:(int)color
{
    _color = color;
    self.button.backgroundColor = [UIColor colorWithRGBHex:color];
}

-(void)onClick
{
    if (self.callback) {
        self.callback(PROPERTY_COLOR,_color);
    }
}

-(void)setSelected:(BOOL)selected
{
    if (selected) {
        self.layer.borderWidth = 2.0f;
        self.layer.borderColor = [[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] CGColor];
        self.layer.cornerRadius = 5.0f;
        self.backgroundColor = [UIColor clearColor];
    }
    else
    {
        self.layer.borderWidth = 0.0f;
    }
}

@end
