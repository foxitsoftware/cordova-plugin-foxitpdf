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
#import "PropertyMainView.h"
#import "PropertyBar.h"
#import "ColorUtility.h"

@interface PropertyMainView ()

@property (nonatomic, retain) ColorLayout *currentColorLayout;
@property (nonatomic, retain) OpacityLayout *currentOpacityLayout;
@property (nonatomic, retain) LineWidthLayout *currentLineWidthLayout;
@property (nonatomic, retain) FontLayout *currentFontLayout;
@property (nonatomic, retain) IconLayout *currentIconLayout;

@end

@implementation PropertyMainView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.segmentItems = [NSMutableArray array];
    }
    return self;
}

- (void)showTab:(Property_TabType)type
{
    if (self.currentColorLayout) {
        self.currentColorLayout.hidden = YES;
    }
    if (self.currentOpacityLayout) {
        self.currentOpacityLayout.hidden = YES;
    }
    if (self.currentLineWidthLayout) {
        self.currentLineWidthLayout.hidden = YES;
    }
    if (self.currentFontLayout) {
        self.currentFontLayout.hidden = YES;
    }
    if (self.currentIconLayout) {
        self.currentIconLayout.hidden = YES;
    }
    switch (type) {
        case TAB_FILL:
            if (self.currentColorLayout) {
                self.currentColorLayout.hidden = NO;
            }
            if (self.currentOpacityLayout) {
                self.currentOpacityLayout.hidden = NO;
            }
            break;
        case TAB_BORDER:
            if (self.currentLineWidthLayout) {
                self.currentLineWidthLayout.hidden = NO;
            }
            break;
        case TAB_FONT:
            if (self.currentFontLayout) {
                self.currentFontLayout.hidden = NO;
            }
            break;
        case TAB_TYPE:
            if (self.currentIconLayout) {
                self.currentIconLayout.hidden = NO;
            }
            break;
            
        default:
            break;
    }
}

- (void)addLayoutAtTab:(UIView*)layout tab:(Property_TabType)tab
{
    switch (tab) {
        case TAB_FILL:
        {
            if ([layout respondsToSelector:@selector(supportProperty)]) {
                if ([(id)layout supportProperty] & PROPERTY_COLOR) {
                    self.currentColorLayout = (ColorLayout*)layout;
                    CGRect colorFrame = layout.frame;
                    colorFrame.origin.y = TABHEIGHT;
                    colorFrame.size.height = [(ColorLayout*)layout layoutHeight];
                    layout.frame = colorFrame;
                    [self addSubview:layout];
                }
            }
            
            if ([layout respondsToSelector:@selector(supportProperty)]) {
                if ([(id)layout supportProperty] & PROPERTY_OPACITY) {
                    self.currentOpacityLayout = (OpacityLayout*)layout;
                    CGRect opacityFrame = layout.frame;
                    opacityFrame.origin.y = TABHEIGHT + self.currentColorLayout.layoutHeight;
                    opacityFrame.size.height = [(OpacityLayout*)layout layoutHeight];
                    layout.frame = opacityFrame;
                    [self addSubview:layout];
                }
            }
        }
            break;
        case TAB_BORDER:
        {
            if ([layout respondsToSelector:@selector(supportProperty)]) {
                if ([(id)layout supportProperty] & PROPERTY_LINEWIDTH) {
                    self.currentLineWidthLayout = (LineWidthLayout*)layout;
                    CGRect lineWidthFrame = layout.frame;
                    lineWidthFrame.origin.y = TABHEIGHT;
                    lineWidthFrame.size.height = [(LineWidthLayout*)layout layoutHeight];
                    layout.frame = lineWidthFrame;
                    [self addSubview:layout];
                }
            }
        }
            break;
        case TAB_FONT:
        {
            if ([layout respondsToSelector:@selector(supportProperty)]) {
                if ([(id)layout supportProperty] & PROPERTY_FONTNAME) {
                    self.currentFontLayout = (FontLayout*)layout;
                    CGRect fontFrame = layout.frame;
                    fontFrame.origin.y = TABHEIGHT;
                    fontFrame.size.height = [(FontLayout*)layout layoutHeight];
                    layout.frame = fontFrame;
                    [self addSubview:layout];
                }
            }
        }
            break;
        case TAB_TYPE:
        {
            if ([layout respondsToSelector:@selector(supportProperty)]) {
                if ([(id)layout supportProperty] & PROPERTY_ICONTYPE) {
                    self.currentIconLayout = (IconLayout*)layout;
                    CGRect typeFrame = layout.frame;
                    typeFrame.origin.y = TABHEIGHT;
                    typeFrame.size.height = [(IconLayout*)layout layoutHeight];
                    layout.frame = typeFrame;
                    [self addSubview:layout];
                }
                
            }
            
            BOOL isTyped = NO;
            for (SegmentItem *item in self.segmentItems) {
                if (item.tag == TAB_BORDER) {
                    isTyped = YES;
                    break;
                }
            }
            if (!isTyped) {
                SegmentItem *typeItem = [[SegmentItem alloc] init];
                typeItem.title = NSLocalizedString(@"kIcon", nil);
                typeItem.image = nil;
                typeItem.tag = TAB_TYPE;
                typeItem.titleNormalColor = [UIColor colorWithRGBHex:0x179cd8];
                typeItem.titleSelectedColor = [UIColor whiteColor];
                [self.segmentItems addObject:typeItem];
            }
            
            BOOL isFilled = NO;
            for (SegmentItem *item in self.segmentItems) {
                if (item.tag == TAB_FILL) {
                    isFilled = YES;
                    break;
                }
            }
            if (!isFilled) {
                SegmentItem *fillItem = [[SegmentItem alloc] init];
                fillItem.title = NSLocalizedString(@"kPropertyFill", nil);
                fillItem.image = nil;
                fillItem.tag = TAB_FILL;
                fillItem.titleNormalColor = [UIColor colorWithRGBHex:0x179cd8];
                fillItem.titleSelectedColor = [UIColor whiteColor];
                [self.segmentItems addObject:fillItem];
            }
        }
            break;
        default:
            break;
    }
    int mainHeight = 0;
    int fillHeight = 0;
    int typeHeight = TABHEIGHT;
    if (self.currentColorLayout) {
        fillHeight += self.currentColorLayout.layoutHeight;
    }
    if (self.currentOpacityLayout) {
        fillHeight += self.currentOpacityLayout.layoutHeight;
    }
    if (self.currentLineWidthLayout) {
        fillHeight += self.currentLineWidthLayout.layoutHeight;
    }
    if (self.currentFontLayout) {
        fillHeight += self.currentFontLayout.layoutHeight;
    }
    if (self.currentIconLayout) {
        typeHeight += self.currentIconLayout.layoutHeight;
        fillHeight += TABHEIGHT;
    }
    mainHeight = MAX(fillHeight, typeHeight);
    CGRect mainRect = self.frame;
    mainRect.size.height = mainHeight;
    self.frame = mainRect;
    
    if (self.currentIconLayout) {
        CGRect typeFrame = self.currentIconLayout.frame;
        typeFrame.origin.y = TABHEIGHT;
        typeFrame.size.height = mainHeight - TABHEIGHT;
        self.currentIconLayout.frame = typeFrame;
        typeFrame.origin.y = 0;
        typeFrame.size.height = mainHeight - TABHEIGHT;
        self.currentIconLayout.tableView.frame = typeFrame;
        
        CGRect colorFrame = self.currentColorLayout.frame;
        colorFrame.origin.y = TABHEIGHT;
        self.currentColorLayout.frame = colorFrame;
        [self.currentColorLayout addDivideView];
        
        CGRect opacityFrame = self.currentOpacityLayout.frame;
        opacityFrame.origin.y = TABHEIGHT + colorFrame.size.height;
        self.currentOpacityLayout.frame = opacityFrame;
    }
    else
    {
        [self resetAllLayout];
        if (self.currentFontLayout) {
            self.currentFontLayout.mainLayoutHeight = mainHeight;
        }
    }
}

- (void)resetAllLayout
{
    if (self.currentColorLayout
        && self.currentOpacityLayout
        && !self.currentLineWidthLayout
        && !self.currentFontLayout) //markup
    {
        CGRect colorFrame = self.currentColorLayout.frame;
        colorFrame.origin.y = 0;
        self.currentColorLayout.frame = colorFrame;
        [self.currentColorLayout addDivideView];
        
        CGRect opacityFrame = self.currentOpacityLayout.frame;
        opacityFrame.origin.y = colorFrame.size.height;
        self.currentOpacityLayout.frame = opacityFrame;
    }
    else if (self.currentColorLayout
             && self.currentOpacityLayout
             && self.currentLineWidthLayout
             && !self.currentFontLayout) //line shape pencil
    {
        CGRect colorFrame = self.currentColorLayout.frame;
        colorFrame.origin.y = 0;
        self.currentColorLayout.frame = colorFrame;
        [self.currentColorLayout addDivideView];
        
        CGRect linewidthFrame = self.currentLineWidthLayout.frame;
        linewidthFrame.origin.y = colorFrame.size.height;
        self.currentLineWidthLayout.frame = linewidthFrame;
        [self.currentLineWidthLayout addDivideView];
        
        CGRect opacityFrame = self.currentOpacityLayout.frame;
        opacityFrame.origin.y = colorFrame.size.height + linewidthFrame.size.height;
        self.currentOpacityLayout.frame = opacityFrame;
    }
    else if (self.currentColorLayout
             && self.currentOpacityLayout
             && !self.currentLineWidthLayout
             && self.currentFontLayout) //freetext
    {
        CGRect fontFrame = self.currentFontLayout.frame;
        fontFrame.origin.y = 0;
        self.currentFontLayout.frame = fontFrame;
        [self.currentFontLayout addDivideView];
        
        CGRect colorFrame = self.currentColorLayout.frame;
        colorFrame.origin.y = fontFrame.size.height;
        self.currentColorLayout.frame = colorFrame;
        [self.currentColorLayout addDivideView];
        
        CGRect opacityFrame = self.currentOpacityLayout.frame;
        opacityFrame.origin.y = fontFrame.size.height + colorFrame.size.height;
        self.currentOpacityLayout.frame = opacityFrame;
    }
    else if (!self.currentColorLayout
             && !self.currentOpacityLayout
             && !self.currentFontLayout
             && self.currentLineWidthLayout)//erase
    {
        CGRect linewidthFrame = self.currentLineWidthLayout.frame;
        linewidthFrame.origin.y = 0;
        self.currentLineWidthLayout.frame = linewidthFrame;
    }
    else if (self.currentColorLayout
             && !self.currentOpacityLayout
             && self.currentLineWidthLayout
             && !self.currentFontLayout)//sigature
    {
        CGRect colorFrame = self.currentColorLayout.frame;
        colorFrame.origin.y = 0;
        self.currentColorLayout.frame = colorFrame;
        [self.currentColorLayout addDivideView];
        
        CGRect linewidthFrame = self.currentLineWidthLayout.frame;
        linewidthFrame.origin.y = colorFrame.size.height;
        self.currentLineWidthLayout.frame = linewidthFrame;
    }
    else if (self.currentColorLayout
             && !self.currentOpacityLayout
             && !self.currentLineWidthLayout
             && !self.currentFontLayout)
    {
        CGRect colorFrame = self.currentColorLayout.frame;
        colorFrame.origin.y = 0;
        self.currentColorLayout.frame = colorFrame;
    }
}

#pragma mark SegmentDeletate
-(void)itemClickWithItem:(SegmentItem *)item
{
    if ([item.title isEqualToString:NSLocalizedString(@"kPropertyFill", nil)]) {
        [self showTab:TAB_FILL];
    }
    if ([item.title isEqualToString:@"Border"]) {
        [self showTab:TAB_BORDER];
    }
    if ([item.title isEqualToString:@"Font"]) {
        [self showTab:TAB_FONT];
    }
    if ([item.title isEqualToString:NSLocalizedString(@"kIcon", nil)]) {
        [self showTab:TAB_TYPE];
    }
}

@end
