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
#import "TbBaseBar.h"
#import "ColorUtility.h"
#import "Utility.h"
#import "Const.h"

@interface TbBaseBar ()

@property (nonatomic, strong) NSMutableArray *ltItems;
@property (nonatomic, strong) NSMutableArray *centerItems;
@property (nonatomic, strong) NSMutableArray *rbItems;
@property (nonatomic, assign) int topMargin;
@property (nonatomic, assign) int leftMargin;
@property (nonatomic, strong) UIView *divideView;

@end

@implementation TbBaseBar

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.contentView = [[UIView alloc] init];
        self.ltItems = [NSMutableArray array];
        self.centerItems = [NSMutableArray array];
        self.rbItems = [NSMutableArray array];
        self.top = YES;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.leftMargin = 3;
        self.intervalWidth = 0;
        self.hasDivide = YES;
        self.divideView = [[[UIView alloc] init] autorelease];
        self.divideView.backgroundColor = [UIColor colorWithRGBHex:0x949494];
        [self.contentView addSubview:self.divideView];
    }
    return self;
}

-(void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.contentView.backgroundColor = backgroundColor;
}

-(void)setHidden:(BOOL)hidden
{
    self.contentView.hidden = hidden;
}

-(BOOL)hidden
{
    return self.contentView.hidden;
}

-(void)setTop:(BOOL)top
{
    _top = top;
    if (top) {
        self.topMargin = 29;
    }
    else
    {
        self.topMargin = 8;
    }
}

-(void)setHasDivide:(BOOL)hasDivide
{
    _hasDivide = hasDivide;
    if (hasDivide) {
        self.divideView.backgroundColor = [UIColor colorWithRGBHex:0x949494];
    }
    else
    {
        self.divideView.backgroundColor = [UIColor clearColor];
    }
}

- (BOOL)addItem:(TbBaseItem*)item displayPosition:(TB_Position)position
{
    if (_top) {
        self.divideView.frame = CGRectMake(0, self.contentView.frame.size.height -  [Utility realPX:1.0f], self.contentView.frame.size.width, [Utility realPX:1.0f]);
    }
    else
    {
        self.divideView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, [Utility realPX:1.0f]);
    }
    
    if (!self.hasDivide) {
        self.divideView.backgroundColor = [UIColor clearColor];
    }
    else
    {
        self.divideView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    }
    if (self.interval)
    {
        [self.ltItems addObject:item];
        [self.ltItems sortUsingComparator:^NSComparisonResult(TbBaseItem *obj1, TbBaseItem *obj2) {
            
            NSComparisonResult result = [[NSNumber numberWithInt:obj2.tag] compare:[NSNumber numberWithInt:obj1.tag]];
            return result;
        }];
        
        for (TbBaseItem *item in self.ltItems) {
            [item.contentView removeFromSuperview];
        }
        
        CGSize screenSize = self.contentView.frame.size;

        float interWidth = 0;
        float insetWidth = 20;
        if (self.ltItems.count > 2)
        {
            TbBaseItem *lastItem = [self.ltItems objectAtIndex:(self.ltItems.count - 1)];
            if (self.direction == Orientation_HORIZONTAL)
            {
                interWidth = (screenSize.width - insetWidth * 2 - lastItem.contentView.frame.size.width) / (self.ltItems.count -1);
            }
            else
            {
                interWidth = (screenSize.height - insetWidth * 2 - lastItem.contentView.frame.size.height) / (self.ltItems.count - 1);
            }
        }
        else
        {
            if (self.direction == Orientation_HORIZONTAL)
            {
                interWidth = screenSize.width - insetWidth * 2;
            }
            else
            {
                interWidth = screenSize.height - insetWidth * 2;
            }
        }
        
        int tempWidth = insetWidth;
        for (int i = 0; i < self.ltItems.count; i++) {
            TbBaseItem *item = [self.ltItems objectAtIndex:i];
            if (self.direction == Orientation_HORIZONTAL)
            {
                if (i == 0) {
                    CGPoint centerPoint = CGPointMake(insetWidth + item.contentView.frame.size.width/2, self.top ? self.contentView.center.y + 10 - self.contentView.frame.origin.y : self.contentView.center.y - self.contentView.frame.origin.y);
                    item.contentView.center = centerPoint;
                }
                else if (i == self.ltItems.count - 1) {
                    CGPoint centerPoint = CGPointMake(screenSize.width - insetWidth - item.contentView.frame.size.width + item.contentView.frame.size.width/2, self.top ? self.contentView.center.y + 10 - self.contentView.frame.origin.y : self.contentView.center.y - self.contentView.frame.origin.y);
                    item.contentView.center = centerPoint;
                }
                else
                {
                    CGPoint centerPoint = CGPointMake(tempWidth + item.contentView.frame.size.width/2, self.top ? self.contentView.center.y + 10 - self.contentView.frame.origin.y : self.contentView.center.y - self.contentView.frame.origin.y);
                    item.contentView.center = centerPoint;
                }
                
                item.contentView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
            }
            else
            {
                CGRect frame;
                if (i == 0) {
                    frame = CGRectMake(self.leftMargin, insetWidth, item.contentView.frame.size.width, item.contentView.frame.size.height);
                }
                else if (i == self.ltItems.count - 1) {
                    frame = CGRectMake(self.leftMargin, screenSize.height - insetWidth - item.contentView.frame.size.height, item.contentView.frame.size.width, item.contentView.frame.size.height);
                }
                else
                {
                    frame = CGRectMake(self.leftMargin, insetWidth + tempWidth, item.contentView.frame.size.width, item.contentView.frame.size.height);
                }
                item.contentView.frame = frame;
                item.contentView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            }
            
            tempWidth += interWidth;
            [self.contentView addSubview:item.contentView];
        }
    }
    else
    {
        switch (position) {
            case Position_LT:
            {
                [self.ltItems addObject:item];
                [self.ltItems sortUsingComparator:^NSComparisonResult(TbBaseItem *obj1, TbBaseItem *obj2) {
                    
                    NSComparisonResult result = [[NSNumber numberWithInt:obj1.tag] compare:[NSNumber numberWithInt:obj2.tag]];
                    return result;
                }];
                
                for (TbBaseItem *item in self.ltItems) {
                    [item.contentView removeFromSuperview];
                }
                
                int tempWidth = 0;
                int padding = 0;
                if (DEVICE_iPHONE) {
                    padding = 10;
                }
                else
                {
                    padding = 10;
                }
                for (int i = 0; i < self.ltItems.count; i++) {
                    TbBaseItem *item = [self.ltItems objectAtIndex:i];
                    
                    if (self.direction == Orientation_HORIZONTAL)
                    {
                        if (self.top)
                        {
                            CGPoint centerPoint = CGPointMake(padding + tempWidth + item.contentView.frame.size.width/2, self.contentView.center.y + 10 - self.contentView.frame.origin.y);
                            item.contentView.center = centerPoint;

                        }
                        else
                        {
                            CGPoint centerPoint = CGPointMake(padding + tempWidth + item.contentView.frame.size.width/2, self.contentView.center.y - self.contentView.frame.origin.y);
                            item.contentView.center = centerPoint;
                        }
                        item.contentView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
                    }
                    else
                    {
                        CGPoint centerPoint = CGPointMake(self.contentView.center.x - self.contentView.frame.origin.x, padding + tempWidth);
                        item.contentView.center = centerPoint;
                        item.contentView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
                    }
                    tempWidth += item.contentView.frame.size.width + padding;
                    item.contentView.contentMode = UIViewContentModeCenter;
                    [self.contentView addSubview:item.contentView];
                }
                break;
            }
            case Position_CENTER:
            {
                [self.centerItems addObject:item];
                [self.centerItems sortUsingComparator:^NSComparisonResult(TbBaseItem *obj1, TbBaseItem *obj2) {
                    
                    NSComparisonResult result = [[NSNumber numberWithInt:obj1.tag] compare:[NSNumber numberWithInt:obj2.tag]];
                    return result;
                }];
                
                for (TbBaseItem *item in self.centerItems) {
                    [item.contentView removeFromSuperview];
                }
                
                int totalWidth = 0;
                int padding = 0;
                if (DEVICE_iPHONE) {
                    padding = 10;
                }
                else
                {
                    padding = 10;
                }
                
                for (int i = 0; i < self.centerItems.count; i++) {
                    TbBaseItem *item = [self.centerItems objectAtIndex:i];
                    totalWidth += item.contentView.frame.size.width;
                    if (i < self.centerItems.count - 1) {
                        if (self.intervalWidth > 0) {
                            totalWidth += self.intervalWidth;
                        }
                        else
                        {
                            totalWidth += padding;
                        }
                    }
                }
                
                int totalHeight = 0;
                for (int i = 0; i < self.centerItems.count; i++) {
                    TbBaseItem *item = [self.centerItems objectAtIndex:i];
                    totalHeight += item.contentView.frame.size.height;
                    if (i < self.centerItems.count - 1) {
                        if (self.intervalWidth > 0) {
                            totalHeight += self.intervalWidth;
                        }
                        else
                        {
                            totalHeight += padding;
                        }
                    }
                }
                
                int tempWidth = 0;
                
                for (int i = 0; i < self.centerItems.count; i++) {
                    TbBaseItem *item = [self.centerItems objectAtIndex:i];
                    CGRect screenFrame = self.contentView.frame;
                    if (self.direction == Orientation_HORIZONTAL)
                    {
                        if (self.top)
                        {
                            CGPoint centerPoint = CGPointMake(screenFrame.size.width/2 - totalWidth/2 + tempWidth + item.contentView.frame.size.width/2, self.contentView.center.y + 10 - self.contentView.frame.origin.y);
                            item.contentView.center = centerPoint;

                        }
                        else
                        {
                            CGPoint centerPoint = CGPointMake(screenFrame.size.width/2 - totalWidth/2 + tempWidth + item.contentView.frame.size.width/2, self.contentView.center.y - self.contentView.frame.origin.y);
                            item.contentView.center = centerPoint;
                        }
                    
                        item.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                    }
                    else
                    {
                        CGPoint centerPoint = CGPointMake(self.contentView.center.x - self.contentView.frame.origin.x, screenFrame.size.height/2 - totalHeight/2);
                        item.contentView.center = centerPoint;
                        item.contentView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
                    }
                    
                    if (self.intervalWidth > 0) {
                        tempWidth += item.contentView.frame.size.width + self.intervalWidth;
                    }
                    else
                    {
                        tempWidth += item.contentView.frame.size.width + padding;
                    }
                    item.contentView.contentMode = UIViewContentModeCenter;
                    [self.contentView addSubview:item.contentView];
                }
                break;
            }
            case Position_RB:
            {
                [self.rbItems addObject:item];
                [self.rbItems sortUsingComparator:^NSComparisonResult(TbBaseItem *obj1, TbBaseItem *obj2) {
                    
                    NSComparisonResult result = [[NSNumber numberWithInt:obj1.tag] compare:[NSNumber numberWithInt:obj2.tag]];
                    return result;
                }];
                
                for (TbBaseItem *item in self.rbItems) {
                    [item.contentView removeFromSuperview];
                }
                
                int tempWidth = 0;
                int padding = 12;
                
                for (int i = 0; i < self.rbItems.count; i++)
                {
                    TbBaseItem *item = [self.rbItems objectAtIndex:i];
                    CGRect screenFrame = self.contentView.bounds;
                    tempWidth += item.contentView.frame.size.width;

                    if (self.top)
                    {
                        CGPoint centerPoint = CGPointMake(screenFrame.size.width - padding -tempWidth + item.contentView.frame.size.width/2, self.contentView.center.y + 10 - self.contentView.frame.origin.y);
                        item.contentView.center = centerPoint;
                        
                    }
                    else
                    {
                        CGPoint centerPoint = CGPointMake(screenFrame.size.width - padding -tempWidth + item.contentView.frame.size.width/2, self.contentView.center.y - self.contentView.frame.origin.y);
                        item.contentView.center = centerPoint;
                    }
                    
                    item.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                    tempWidth += padding;
                    item.contentView.contentMode = UIViewContentModeCenter;
                    [self.contentView addSubview:item.contentView];
                }
                break;
            }
            default:
                break;
        }
    }
    return YES;
}


- (BOOL)removeItemByIndex:(int)tag displayPosition:(TB_Position)position
{
    switch (position) {
        case Position_LT:
        {
            for (TbBaseItem *item in self.ltItems) {
                if (item.tag == tag) {
                    [item.contentView removeFromSuperview];
                    [self.ltItems removeObject:item];
                    return YES;
                }
            }
            break;

        }
        case Position_CENTER:
        {
            for (TbBaseItem *item in self.centerItems) {
                if (item.tag == tag) {
                    [item.contentView removeFromSuperview];
                    [self.centerItems removeObject:item];
                    return YES;
                }
            }
            break;
        }
        case Position_RB:
        {
            for (TbBaseItem *item in self.rbItems) {
                if (item.tag == tag) {
                    [item.contentView removeFromSuperview];
                    [self.rbItems removeObject:item];
                    return YES;
                }
            }
            break;
        }
        default:
            break;
    }
    return NO;
}

- (BOOL)removeItem:(TbBaseItem*)item
{
    if ([self.ltItems containsObject:item]) {
        [item.contentView removeFromSuperview];
        [self.ltItems removeObject:item];
        return YES;
    }
    
    if ([self.centerItems containsObject:item]) {
        [item.contentView removeFromSuperview];
        [self.centerItems removeObject:item];
        return YES;
    }
    
    if ([self.rbItems containsObject:item]) {
        [item.contentView removeFromSuperview];
        [self.rbItems removeObject:item];
        return YES;
    }
    return NO;
}

- (BOOL)removeAllItems
{
    for (TbBaseItem *item in self.ltItems) {
        [item.contentView removeFromSuperview];
    }
    [self.ltItems removeAllObjects];
    
    for (TbBaseItem *item in self.centerItems) {
        [item.contentView removeFromSuperview];
    }
    [self.centerItems removeAllObjects];
    
    for (TbBaseItem *item in self.rbItems) {
        [item.contentView removeFromSuperview];
    }
    [self.rbItems removeAllObjects];
    return YES;
}

- (BOOL)removeLtItems
{
    for (TbBaseItem *item in self.ltItems) {
        [item.contentView removeFromSuperview];
    }
    [self.ltItems removeAllObjects];
    return YES;
}

- (BOOL)removeCenterItems
{
    for (TbBaseItem *item in self.centerItems) {
        [item.contentView removeFromSuperview];
    }
    [self.centerItems removeAllObjects];
    return YES;
}

- (BOOL)removeRbItems
{
    for (TbBaseItem *item in self.rbItems) {
        [item.contentView removeFromSuperview];
    }
    [self.rbItems removeAllObjects];
    return YES;
}
@end
