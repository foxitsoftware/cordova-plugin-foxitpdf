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
#import "LineWidthLayout.h"
#import "PropertyBar.h"
#import "Utility.h"
#import "ColorUtility.h"

@interface LineWidthLayout ()

@property (nonatomic, retain) UILabel *title;
@property (nonatomic, assign) int currentColor;
@property (nonatomic, assign) int currentLineWidth;
@property (nonatomic, retain) id<IPropertyValueChangedListener> currentListener;

@property (nonatomic, retain) UIImageView *circleView;
@property (nonatomic, retain) UILabel *numberView;
@property (nonatomic, retain) UISlider *silder;

@end

@implementation LineWidthLayout

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.title = [[[UILabel alloc] initWithFrame:CGRectMake(20, 3, frame.size.width, LAYOUTTITLEHEIGHT)] autorelease];
        self.title.text = NSLocalizedString(@"kThickness", nil);
        self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
        self.title.font = [UIFont systemFontOfSize:11.0f];
        [self addSubview:self.title];
        
        self.circleView = [[[UIImageView alloc] initWithFrame:CGRectMake(20, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, 32, 32)] autorelease];
        self.circleView.layer.cornerRadius = 16.f;
        [self addSubview:self.circleView];
        
        self.numberView = [[[UILabel alloc] initWithFrame:CGRectMake(70, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE + 6, 50, 20)] autorelease];
        self.numberView.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
        self.numberView.font = [UIFont systemFontOfSize:15];
        [self addSubview:self.numberView];
        
        self.silder = [[[UISlider alloc] initWithFrame:CGRectMake(120, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE + 6, frame.size.width - 140, 20)] autorelease];
        [self.silder setThumbImage:[UIImage imageNamed:@"property_linewidth_slider.png"] forState:UIControlStateNormal];
        [self.silder setThumbImage:[UIImage imageNamed:@"property_linewidth_slider.png"] forState:UIControlStateHighlighted];
        self.silder.minimumValue = 1.0f;
        self.silder.maximumValue = 12.0f;
        
        [self.silder addTarget:self action:@selector(sliderChangedValue) forControlEvents:UIControlEventValueChanged];
        self.layoutHeight = LAYOUTTITLEHEIGHT + LAYOUTTBSPACE*2 + 30;
        [self addSubview:self.silder];
    }
    return self;
}

-(long)supportProperty
{
    return PROPERTY_LINEWIDTH;
}

-(void)setCurrentColor:(int)color
{
    _currentColor = color;
    self.circleView.backgroundColor = [UIColor colorWithRGBHex:color];
}

-(void)setCurrentLineWidth:(int)lineWidth
{
    _currentLineWidth = lineWidth;
    [self.silder setValue:lineWidth animated:NO];
    self.numberView.text = [NSString stringWithFormat:@"%d %@",lineWidth,@"pt"];
    self.circleView.backgroundColor = [UIColor colorWithRGBHex:_currentColor];
    int circleWidth = self.silder.value * 16 / 12;
    self.circleView.layer.cornerRadius = circleWidth;
    self.circleView.frame = CGRectMake(20 + 16 - circleWidth, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE + 16 - circleWidth, circleWidth*2, circleWidth*2);
}

-(void)setCurrentListener:(id<IPropertyValueChangedListener>)currentListener
{
    _currentListener = currentListener;
}

-(void)sliderChangedValue
{
    self.numberView.text = [NSString stringWithFormat:@"%d %@",(int)self.silder.value,@"pt"];
    self.circleView.backgroundColor = [UIColor colorWithRGBHex:_currentColor];
    int circleWidth = self.silder.value * 16 / 12;
    self.circleView.layer.cornerRadius = circleWidth;
    self.circleView.frame = CGRectMake(20 + 16 - circleWidth, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE + 16 - circleWidth, circleWidth*2, circleWidth*2);
    [self.currentListener onIntValueChanged:PROPERTY_LINEWIDTH value:self.silder.value];
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

-(void)resetLayout
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    self.title = [[[UILabel alloc] initWithFrame:CGRectMake(20, 3, self.frame.size.width, LAYOUTTITLEHEIGHT)] autorelease];
    self.title.text = NSLocalizedString(@"kThickness", nil);
    self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
    self.title.font = [UIFont systemFontOfSize:11.0f];
    [self addSubview:self.title];
    
    self.circleView = [[[UIImageView alloc] initWithFrame:CGRectMake(20, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, 32, 32)] autorelease];
    self.circleView.layer.cornerRadius = 16.f;
    [self addSubview:self.circleView];
    
    self.numberView = [[[UILabel alloc] initWithFrame:CGRectMake(70, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE + 6, 50, 20)] autorelease];
    self.numberView.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
    self.numberView.font = [UIFont systemFontOfSize:15];
    [self addSubview:self.numberView];
    
    self.silder = [[[UISlider alloc] initWithFrame:CGRectMake(120, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE + 6, self.frame.size.width - 140, 20)] autorelease];
    [self.silder setThumbImage:[UIImage imageNamed:@"property_linewidth_slider.png"] forState:UIControlStateNormal];
    [self.silder setThumbImage:[UIImage imageNamed:@"property_linewidth_slider.png"] forState:UIControlStateHighlighted];
    self.silder.minimumValue = 1.0f;
    self.silder.maximumValue = 12.0f;
    
    [self.silder addTarget:self action:@selector(sliderChangedValue) forControlEvents:UIControlEventValueChanged];
    self.layoutHeight = LAYOUTTITLEHEIGHT + LAYOUTTBSPACE*2 + 30;
    [self addSubview:self.silder];
    [self setCurrentColor:_currentColor];
    [self setCurrentLineWidth:_currentLineWidth];
}

@end
