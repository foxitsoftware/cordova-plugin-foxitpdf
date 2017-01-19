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
#import "SegmentView.h"

@interface SegmentItem ()


@property(nonatomic,retain)UIImageView *belowImage;
@property(nonatomic,retain)UIButton *itemButton;
@property(nonatomic,assign)CGRect validRect;
@property(nonatomic,assign)SegmentView *parentView;
@end

@implementation SegmentItem

- (CGRect)getValidRect
{
    NSUInteger count = [[self.parentView getItems] count];
    NSUInteger viewWidth = self.parentView.frame.size.width;
    NSUInteger width = viewWidth/count;
    NSUInteger index = [[self.parentView getItems] indexOfObject:self];
    
    CGRect rect = CGRectMake(width*index, 0, width, self.parentView.frame.size.height);
    self.validRect = rect;
    return self.validRect;
}

- (void)dealloc
{
    [_title release];
    [super dealloc];
}

@end

@interface SegmentView ()


@property(nonatomic,retain)UIImageView *background;

@end


@implementation SegmentView

- (id)initWithFrame:(CGRect)frame segmentItems:(NSArray *)items
{
    if (self = [super initWithFrame:frame])
    {
        itemsArray = [[NSMutableArray alloc] init];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGuest:)];
        UIImage *image = [[UIImage imageNamed:@"segment_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        self.background = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
        self.background.userInteractionEnabled = YES;
        [self.background  addGestureRecognizer:tapGesture];
        self.background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.background.image = image;
        [self addSubview:self.background];
        for (int i = 0; i < [items count]; i++)
        {
            SegmentItem *item = [items objectAtIndex:i];
            item.parentView = self;
            UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, item.image.size.width, item.image.size.height)] autorelease];
            button.userInteractionEnabled = NO;
            button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
            item.validRect = CGRectMake(i*(self.bounds.size.width/[items count]), 0, self.bounds.size.width/[items count], self.bounds.size.height);
            
            if (item.image) {
                [button setImage:item.image forState:UIControlStateNormal];
                [button setImage:item.selectImage forState:UIControlStateSelected];
            }
            if (item.title) {
                button.frame = CGRectMake(0, 0, 100, 40);
                [button setTitle:item.title forState:UIControlStateNormal];
            }
            
            [button setTitleColor:item.titleNormalColor forState:UIControlStateNormal];
            [button setTitleColor:item.titleSelectedColor forState:UIControlStateSelected];
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            button.center = CGPointMake((i*2+1)*((self.bounds.size.width)/([items count]*2)), self.bounds.size.height/2);
            button.tag = i;
            UIView *separateLine = nil;
            UIImageView *itemBelowImage = [[[UIImageView alloc] initWithFrame:CGRectMake(i*(self.bounds.size.width/[items count])+0.5, 0, self.bounds.size.width/[items count], self.bounds.size.height)] autorelease];
            itemBelowImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            if (i == 0)
            {
                separateLine = [[[UIView alloc] init] autorelease];
                separateLine.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
                separateLine.backgroundColor = [UIColor colorWithRed:23.f/255.f green:156.f/255 blue:216.f/255.f alpha:1];
                separateLine.frame = CGRectMake(self.bounds.size.width/[items count], 0, 1, self.bounds.size.height);
                itemBelowImage.image = [[UIImage imageNamed:@"segment_left_bg.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
                
            } else if (i < ([items count] -1 ))
            {
                separateLine = [[[UIView alloc] init] autorelease];
                separateLine.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
                separateLine.backgroundColor = [UIColor colorWithRed:23.f/255.f green:156.f/255 blue:216.f/255.f alpha:1];
                separateLine.frame = CGRectMake(i*(self.bounds.size.width/[items count]) + self.bounds.size.width/[items count], 0, 1, self.bounds.size.height);
                itemBelowImage.image = [[UIImage imageNamed:@"segment_center_bg.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
                
            } else
            {
                itemBelowImage.image = [[UIImage imageNamed:@"segment_right_bg.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
            }
            itemBelowImage.hidden = YES;
            [self addSubview:itemBelowImage];
            [self addSubview:button];
            [self addSubview:separateLine];
            item.belowImage = itemBelowImage;
            item.itemButton = button;
            [itemsArray addObject:item];
        }
    }
    return self;
}

- (NSArray *)getItems
{
    return itemsArray;
}

- (void)setSelectItem:(SegmentItem *)item
{
    [self onClick:item];
    
}

- (void)tapGuest:(UITapGestureRecognizer *)recongnizer
{
    CGPoint point = [recongnizer locationInView:self.background];
    for (SegmentItem *item in itemsArray)
    {
        if (CGRectContainsPoint([item getValidRect], point))
        {
            [self onClick:item];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (void)onClick:(SegmentItem *)sender
{
    if ([self.delegate conformsToProtocol:@protocol(SegmentDelegate)] && [self.delegate respondsToSelector:@selector(itemClickWithItem:)])
    {
        [self.delegate itemClickWithItem:sender];
    }
    for (SegmentItem *item in itemsArray)
    {
        if (item.tag != sender.tag)
        {
            item.belowImage.hidden = YES;
            item.itemButton.selected = NO;
            
        } else
        {
            item.belowImage.hidden = NO;
            item.itemButton.selected = YES;
        }
    }
}


@end
