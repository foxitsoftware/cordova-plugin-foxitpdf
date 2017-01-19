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
#import "TbBaseItem.h"
#import "ColorUtility.h"
#import "Utility.h"
#import "UIView+EnlargeEdge.h"
#import "UIButton+EnlargeEdge.h"

@interface TbBaseItem ()

@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, assign) TB_ItemDisplayStyle currentStyle;
@property (nonatomic, assign) TB_ImageTextRelation currentRelation;

@end

@implementation TbBaseItem

+ (TbBaseItem*)createItemWithTitle:(NSString*)title
{
    TbBaseItem *barItem = [[[TbBaseItem alloc] init] autorelease];
    if (barItem) {
        barItem.currentStyle = Item_Title;
        barItem.button = [UIButton buttonWithType:UIButtonTypeCustom];
        barItem.button.titleLabel.textAlignment = NSTextAlignmentCenter;

        barItem.text = title;
        barItem.textFont = [UIFont systemFontOfSize:18.0f];
        
        CGSize titleSize = [Utility getTextSize:title fontSize:18.0f maxSize:CGSizeMake(400, 100)];
        CGRect buttonFrame = CGRectMake(0, 0, titleSize.width, titleSize.height);
        
        barItem.contentView = [[UIView alloc] initWithFrame:buttonFrame];
        barItem.button.frame = buttonFrame;
        
        barItem.button.contentMode = UIViewContentModeScaleToFill;
        barItem.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        barItem.button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        barItem.button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [barItem.button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [barItem.button addTarget:barItem action:@selector(onTapClicked) forControlEvents:UIControlEventTouchUpInside];
        
        UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:barItem action:@selector(onLongPressClicked:)] autorelease];
        longPress.minimumPressDuration = 0.8; //press time
        [barItem.button addGestureRecognizer:longPress];
        [barItem.contentView addSubview:barItem.button];
        barItem.button.center = CGPointMake(barItem.contentView.bounds.size.width/2, barItem.contentView.bounds.size.height/2);
        [barItem.contentView setEnlargedEdge:ENLARGE_EDGE];
        [barItem.button setEnlargedEdge:ENLARGE_EDGE];
    }
    return barItem;
}

+ (TbBaseItem*)createItemWithImage:(UIImage*)imageNormal
                    imageSelected:(UIImage*)imageSelected
                     imageDisable:(UIImage*)imageDisabled
{
    TbBaseItem *barItem = [[[TbBaseItem alloc] init] autorelease];
    if (barItem) {
        barItem.currentStyle = Item_Image;
        float width = imageNormal.size.width;
        float height = imageNormal.size.height;
        CGRect buttonFrame = CGRectMake(0, 0, width, height);
        barItem.button = [[[UIButton alloc] initWithFrame:buttonFrame] autorelease];
        barItem.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        barItem.button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        barItem.button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        barItem.button.titleLabel.textAlignment = NSTextAlignmentCenter;
        barItem.imageNormal = imageNormal;
        barItem.imageSelected = imageSelected;
        barItem.imageDisabled = imageDisabled;
        barItem.contentView = [[[UIView alloc] initWithFrame:buttonFrame] autorelease];
        [barItem.button addTarget:barItem action:@selector(onTapClicked) forControlEvents:UIControlEventTouchUpInside];
        
        UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:barItem action:@selector(onLongPressClicked:)] autorelease];
        longPress.minimumPressDuration = 0.8; //press time
        [barItem.button addGestureRecognizer:longPress];
        [barItem.contentView addSubview:barItem.button];
        barItem.button.center = CGPointMake(barItem.contentView.bounds.size.width/2, barItem.contentView.bounds.size.height/2);
        [barItem.contentView setEnlargedEdge:ENLARGE_EDGE];
        [barItem.button setEnlargedEdge:ENLARGE_EDGE];
    }
    return barItem;
}

+ (TbBaseItem*)createItemWithImageAndTitle:(NSString*)title
                              imageNormal:(UIImage*)imageNormal
                            imageSelected:(UIImage*)imageSelected
                             imageDisable:(UIImage*)imageDisabled
                                 imageTextRelation:(TB_ImageTextRelation)imageTextRelation
{
    TbBaseItem *barItem = [[[TbBaseItem alloc] init] autorelease];
    if (barItem) {
        barItem.currentStyle = Item_Title_Image;
        barItem.currentRelation = imageTextRelation;
        
        barItem.button = [[[UIButton alloc] init] autorelease];
        barItem.button.titleLabel.textAlignment = NSTextAlignmentCenter;
        barItem.text = title;
        barItem.textFont = [UIFont systemFontOfSize:15];
        barItem.imageNormal = imageNormal;
        barItem.imageSelected = imageSelected;
        barItem.imageDisabled = imageDisabled;
        
        CGSize titleSize  = [Utility getTextSize:title fontSize:15.0f maxSize:CGSizeMake(400, 100)];
        
        float width = imageNormal.size.width;
        float height = imageNormal.size.height;
        CGRect frame = CGRectMake(0, 0, width, height);
        barItem.contentView = [[[UIView alloc] initWithFrame:frame] autorelease];
        barItem.button.frame = frame;
        barItem.button.contentMode = UIViewContentModeScaleToFill;
        
        [barItem.button setTitle:title forState:UIControlStateNormal];
        [barItem.button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [barItem.button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        barItem.button.titleLabel.font = [UIFont systemFontOfSize:15];
        barItem.button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        switch (imageTextRelation) {
            case RELATION_LEFT:
            {
                barItem.button.titleEdgeInsets = UIEdgeInsetsMake(0, -width - titleSize.width, 0, 0);
                barItem.button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -titleSize.width - width);
                barItem.button.frame = CGRectMake(0, 0, titleSize.width + width, titleSize.height > height ? titleSize.height : height);
                barItem.contentView.frame = barItem.button.frame;
                barItem.button.contentHorizontalAlignment = UIControlContentVerticalAlignmentCenter;
               break;
            }
               
            case RELATION_TOP:
            {
                barItem.button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, height, 0);
                barItem.button.imageEdgeInsets = UIEdgeInsetsMake(titleSize.height, 0, 0, -titleSize.width);

                barItem.button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width : width,  titleSize.height + height);
                barItem.contentView.frame = barItem.button.frame;
                barItem.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                break;
            }
            case RELATION_RIGHT:
            {
                barItem.button.frame = CGRectMake(0, 0, titleSize.width + width, titleSize.height > height ? titleSize.height : height);
                [barItem.button setImageEdgeInsets:UIEdgeInsetsMake(0.0, -12.0, 0.0, 0.0)];
                barItem.button.titleEdgeInsets = UIEdgeInsetsMake(0.0, -2.0, 0.0, 0.0);
                barItem.contentView.frame = barItem.button.frame;
                break;
            }
    
            case RELATION_BOTTOM:
            {
                
                barItem.button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, -height, 0);
                barItem.button.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width);
                barItem.button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width : width,  titleSize.height + height);
                barItem.contentView.frame = barItem.button.frame;
                barItem.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                
                break;
            }
            default:
                break;
        }
        [barItem.button addTarget:barItem action:@selector(onTapClicked) forControlEvents:UIControlEventTouchUpInside];
        
        UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:barItem action:@selector(onLongPressClicked:)] autorelease];
        longPress.minimumPressDuration = 0.8; //press time
        [barItem.button addGestureRecognizer:longPress];
        [barItem.contentView addSubview:barItem.button];
    }
    return barItem;
}

+ (TbBaseItem*)createItemWithTitle:(NSString*)title
                         background:(UIImage*)background
{
    TbBaseItem *barItem = [[[TbBaseItem alloc] init] autorelease];
    if (barItem) {
        barItem.currentStyle = Item_Title;
        
        CGSize titleSize  = [Utility getTextSize:title fontSize:15.0f maxSize:CGSizeMake(400, 100)];
        UIImage *backgroundSelected = [self imageByApplyingAlpha:background alpha:0.5];
        if (background) {
            titleSize = background.size;
        }
        
        CGRect buttonFrame = CGRectMake(0, 0, titleSize.width, titleSize.height);
        
        barItem.button = [[[UIButton alloc] initWithFrame:buttonFrame] autorelease];
        barItem.text = title;
        barItem.textFont = [UIFont systemFontOfSize:15];
        barItem.button.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        barItem.contentView = [[[UIView alloc] initWithFrame:buttonFrame] autorelease];
        
        barItem.button.contentMode = UIViewContentModeScaleToFill;
        barItem.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        barItem.button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        barItem.button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [barItem.button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        if (background) {
            [barItem.button setBackgroundImage:background forState:UIControlStateNormal];
            [barItem.button setBackgroundImage:backgroundSelected forState:UIControlStateHighlighted];
        }
        barItem.button.titleLabel.font = [UIFont systemFontOfSize:15];
        [barItem.button addTarget:barItem action:@selector(onTapClicked) forControlEvents:UIControlEventTouchUpInside];
        
        UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:barItem action:@selector(onLongPressClicked:)] autorelease];
        longPress.minimumPressDuration = 0.8; //press time
        [barItem.button addGestureRecognizer:longPress];
        [barItem.contentView addSubview:barItem.button];
        barItem.button.center = CGPointMake(barItem.contentView.bounds.size.width/2, barItem.contentView.bounds.size.height/2);
        [barItem.contentView setEnlargedEdge:ENLARGE_EDGE];
        [barItem.button setEnlargedEdge:ENLARGE_EDGE];
    }
    return barItem;
}

+ (TbBaseItem*)createItemWithImage:(UIImage*)imageNormal
                      imageSelected:(UIImage*)imageSelected
                       imageDisable:(UIImage*)imageDisabled
                         background:(UIImage*)background
{
    TbBaseItem *barItem = [[[TbBaseItem alloc] init] autorelease];
    if (barItem) {
        barItem.currentStyle = Item_Image;
        
        float width = imageNormal.size.width;
        float height = imageNormal.size.height;
        UIImage *backgroundSelected = [self imageByApplyingAlpha:background alpha:0.5];
        if (background) {
            width = background.size.width;
            height = background.size.height;
        }
        barItem.button.titleLabel.textAlignment = NSTextAlignmentCenter;
        CGRect buttonFrame = CGRectMake(0, 0, width, height);
        barItem.button = [[[UIButton alloc] initWithFrame:buttonFrame] autorelease];
        
        barItem.imageNormal = imageNormal;
        barItem.imageSelected = imageSelected;
        barItem.imageDisabled = imageDisabled;
        
        barItem.contentView = [[[UIView alloc] initWithFrame:buttonFrame] autorelease];
        barItem.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        barItem.button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        barItem.button.autoresizingMask =  UIViewAutoresizingFlexibleHeight;
        barItem.button.imageEdgeInsets = UIEdgeInsetsMake(-3, 0, 0, 0);
        if (background) {
            [barItem.button setBackgroundImage:background forState:UIControlStateNormal];
            [barItem.button setBackgroundImage:backgroundSelected forState:UIControlStateHighlighted];
        }
        [barItem.button addTarget:barItem action:@selector(onTapClicked) forControlEvents:UIControlEventTouchUpInside];
        
        UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:barItem action:@selector(onLongPressClicked:)] autorelease];
        longPress.minimumPressDuration = 0.8; //press time
        [barItem.button addGestureRecognizer:longPress];
        [barItem.contentView addSubview:barItem.button];
        barItem.button.center = CGPointMake(barItem.contentView.bounds.size.width/2, barItem.contentView.bounds.size.height/2);
        [barItem.contentView setEnlargedEdge:ENLARGE_EDGE];
        [barItem.button setEnlargedEdge:ENLARGE_EDGE];
    }
    return barItem;
}

+ (TbBaseItem*)createItemWithImageAndTitle:(NSString*)title
                                imageNormal:(UIImage*)imageNormal
                              imageSelected:(UIImage*)imageSelected
                               imageDisable:(UIImage*)imageDisabled
                                 background:(UIImage*)background
                          imageTextRelation:(TB_ImageTextRelation)imageTextRelation
{
    TbBaseItem *barItem = [[[TbBaseItem alloc] init] autorelease];
    if (barItem) {
        barItem.currentStyle = Item_Title_Image;
        barItem.currentRelation = imageTextRelation;
        
        float width = imageNormal.size.width;
        float height = imageNormal.size.height;
        UIImage *backgroundSelected = [self imageByApplyingAlpha:background alpha:0.5];
        if (background) {
            width = background.size.width;
            height = background.size.height;
        }
        CGRect frame = CGRectMake(0, 0, width, height);
        barItem.contentView = [[[UIView alloc] initWithFrame:frame] autorelease];
        barItem.button = [[[UIButton alloc] initWithFrame:frame] autorelease];
        barItem.text = title;
        barItem.textFont = [UIFont systemFontOfSize:15];
        barItem.imageNormal = imageNormal;
        barItem.imageSelected = imageSelected;
        barItem.imageDisabled = imageDisabled;
        
        CGSize titleSize  = [Utility getTextSize:title fontSize:15.0f maxSize:CGSizeMake(400, 100)];
        
        barItem.button.contentMode = UIViewContentModeScaleToFill;
        if (background) {
            [barItem.button setBackgroundImage:background forState:UIControlStateNormal];
            [barItem.button setBackgroundImage:backgroundSelected forState:UIControlStateHighlighted];
        }
        [barItem.button setTitle:title forState:UIControlStateNormal];
        barItem.button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [barItem.button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [barItem.button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        barItem.button.titleLabel.font = [UIFont systemFontOfSize:15];
        barItem.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        barItem.button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        barItem.button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        switch (imageTextRelation) {
            case RELATION_LEFT:
            {
                barItem.button.titleEdgeInsets = UIEdgeInsetsMake(0, -width - titleSize.width, 0, 0);
                barItem.button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -titleSize.width - width);
                barItem.button.frame = CGRectMake(0, 0, titleSize.width + width, titleSize.height > height ? titleSize.height : height);
                barItem.contentView.frame = barItem.button.frame;
                break;
            }
                
            case RELATION_TOP:
            {
                barItem.button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, height, 0);
                barItem.button.imageEdgeInsets = UIEdgeInsetsMake(titleSize.height, 0, 0, -titleSize.width);
                
                barItem.button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width : width,  titleSize.height + height);
                barItem.contentView.frame = barItem.button.frame;
                break;
            }
            case RELATION_RIGHT:
            {
                barItem.button.frame = CGRectMake(0, 0, titleSize.width + width, titleSize.height > height ? titleSize.height : height);
                [barItem.button setImageEdgeInsets:UIEdgeInsetsMake(0.0, -20, 0.0, 0.0)];
                barItem.contentView.frame = barItem.button.frame;
                break;
            }
                
            case RELATION_BOTTOM:
            {
                barItem.button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, -height, 0);
                barItem.button.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width + 3);
                barItem.button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width : width,  titleSize.height + height);
                barItem.contentView.frame = barItem.button.frame;
                break;
            }
            default:
                break;
        }
        [barItem.button addTarget:barItem action:@selector(onTapClicked) forControlEvents:UIControlEventTouchUpInside];
        
        UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:barItem action:@selector(onLongPressClicked:)] autorelease];
        longPress.minimumPressDuration = 0.8; //press time
        [barItem.button addGestureRecognizer:longPress];
        [barItem.contentView addSubview:barItem.button];
    }
    return barItem;
}

-(void)setText:(NSString *)text
{
    _text = text;
    if (self.button) {
        [self.button setTitle:text forState:UIControlStateNormal];
        [self refreshInterface];
    }
}

-(void)setAttributedText:(NSAttributedString *)string
{
    _attributedText = string;
    if (self.button)
    {
        [self.button setAttributedTitle:string forState:UIControlStateNormal];
        [self refreshInterface];
    }
}

-(void)setTextFont:(UIFont *)textFont
{
    _textFont = textFont;
    if (self.button) {
        self.button.titleLabel.font = textFont;
        [self refreshInterface];
    }
}

-(void)setImageNormal:(UIImage *)imageNormal
{
    _imageNormal = imageNormal;
    if (self.button) {
        [self.button setImage:imageNormal forState:UIControlStateNormal];
        [self.button setImage:[Utility imageByApplyingAlpha:imageNormal alpha:0.5] forState:UIControlStateHighlighted];
        [self.button setImage:[Utility imageByApplyingAlpha:imageNormal alpha:0.5] forState:UIControlStateDisabled];
    }
}

-(void)setImageDisabled:(UIImage *)imageDisabled
{
    _imageDisabled = imageDisabled;
    if (self.button) {
        
    }
}

-(void)setImageSelected:(UIImage *)imageSelected
{
    _imageSelected = imageSelected;
    if (self.button) {
        [self.button setImage:imageSelected forState:UIControlStateSelected];
    }
}

-(void)refreshInterface
{
    if (self.currentStyle == Item_Title)
    {
        if (!_textFont || !_text)
        {
            return;
        }
        
        CGSize titleSize;
        if (_attributedText)
            titleSize = [Utility getAttributedTextSize:_attributedText maxSize:CGSizeMake(400, 100)];
        else
            titleSize = [Utility getTextSize:self.text fontSize:_textFont.pointSize maxSize:CGSizeMake(400, 100)];
        
        CGRect contentViewFrame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, titleSize.width + 2, titleSize.height);
        self.contentView.frame = contentViewFrame;
        
        CGRect buttonFrame = CGRectMake(0, 0, titleSize.width + 2, titleSize.height);
        
        self.button.frame = buttonFrame;
        self.button.titleLabel.font = _textFont;
        self.button.center =CGPointMake(self.contentView.bounds.size.width/2, self.contentView.bounds.size.height/2);
        [self.contentView setEnlargedEdge:ENLARGE_EDGE];
        [self.button setEnlargedEdge:ENLARGE_EDGE];
    }
    else if(self.currentStyle == Item_Title_Image)
    {
        if (!_textFont || !_text) {
            return;
        }
        
        CGSize titleSize  = [Utility getTextSize:self.text fontSize:_textFont.pointSize maxSize:CGSizeMake(400, 100)];
        
        float width = self.imageNormal.size.width;
        float height = self.imageNormal.size.height;
        switch (self.currentRelation) {
            case RELATION_LEFT:
            {
                self.button.titleEdgeInsets = UIEdgeInsetsMake(0, -width - titleSize.width, 0, 0);
                self.button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -titleSize.width - width);
                self.button.frame = CGRectMake(0, 0, titleSize.width + width, titleSize.height > height ? titleSize.height : height);
                break;
            }
                
            case RELATION_TOP:
            {
                self.button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, height, 0);
                self.button.imageEdgeInsets = UIEdgeInsetsMake(titleSize.height, 0, 0, -titleSize.width);
                
                self.button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width : width,  titleSize.height + height);
                break;
            }
            case RELATION_RIGHT:
            {
                self.button.frame = CGRectMake(0, 0, titleSize.width + width + 2, titleSize.height > height ? titleSize.height : height);
                break;
            }
                
            case RELATION_BOTTOM:
            {
                self.button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, -height, 0);
                self.button.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width);
                self.button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width : width,  titleSize.height + height);
                self.button.center = self.contentView.center;
                break;
            }
            default:
                break;
        }
    }
}

-(void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    if (self.button) {
        [self.button setTitleColor:textColor forState:UIControlStateNormal];
    }
}

-(void)setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    if (self.button) {
        self.button.backgroundColor = backgroundColor;
    }
}

-(void)setEnable:(BOOL)enable
{
    _enable = enable;
    if (self.button) {
        self.button.enabled = enable;
    }
}

-(void)setSelected:(BOOL)selected
{
    _selected = selected;
    if (self.button) {
        self.button.selected = selected;
    }
}

-(void)setRect:(CGRect)rect
{
    _rect = rect;
    if (self.currentStyle == Item_Title) {
        self.button.frame = CGRectMake(30,0,rect.size.width,rect.size.height);
        self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    }
}

-(void)onTapClicked
{
    if (self.onTapClick) {
        self.onTapClick(self);
    }
}

-(void)onLongPressClicked:(UILongPressGestureRecognizer *)gestureRecognizer{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        if (self.onLongPress) {
            self.onLongPress(self);
        }
    }
}

+ (UIImage *)imageByApplyingAlpha:(UIImage*)image alpha:(CGFloat) alpha {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if(!ctx) return nil;
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    
    CGContextSetAlpha(ctx, alpha);
    
    CGContextDrawImage(ctx, area, image.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void) setInsideCircleColor:(int)color
{
    for (UIView *view in self.button.subviews) {
        if (view.tag == 100) {
            [view removeFromSuperview];
        }
    }
    UIView *circleView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)] autorelease];
    circleView.tag = 100;
    circleView.center = CGPointMake(self.button.bounds.size.width/2, self.button.bounds.size.height/2 - 1.5);
    circleView.layer.cornerRadius = 11.f;
    circleView.layer.backgroundColor = [[UIColor colorWithRGBHex:color] CGColor];
    [self.button addSubview:circleView];
}

@end
