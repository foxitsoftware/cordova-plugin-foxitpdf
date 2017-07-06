/**
 * Copyright (C) 2003-2017, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "PanelHost.h"
#import "UIExtensionsManager+Private.h"
#import "IPanelSpec.h"
#import "Masonry.h"

@implementation PanelButton

@end

@implementation PanelHost

-(instancetype)init
{
    return [self initWithModuleConfig:nil];
}

-(instancetype)initWithModuleConfig:(UIExtensionsModulesConfig*)config
{
    self = [super init];
    if (self)
    {
        self.spaces = [[NSMutableArray alloc] init];
        if (DEVICE_iPHONE) {
            self.contentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        }
        else
        {
            self.contentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 300, [UIScreen mainScreen].bounds.size.height)];
        }
        
        UIImage *normalImg = nil;
        UIImage *selImg = nil;

        int itemCount = 0;
        NSMutableArray* array = [[NSMutableArray alloc] init];
        if(config.loadReadingBookmark)
        {
            SegmentItem *bookmark = [[SegmentItem alloc] init];
            bookmark.tag = 10;
            bookmark.image = [UIImage imageNamed:@"panel_top_bookmak_normal"];
            bookmark.selectImage = [UIImage imageNamed:@"panel_top_bookmak_selected"];
            itemCount++;
            [array addObject:bookmark];
        }
        if(config.loadOutline)
        {
            SegmentItem *outline = [[SegmentItem alloc] init];
            outline.tag = 20;
            normalImg = [UIImage imageNamed:@"panel_top_outline_normal"];
            selImg = [UIImage imageNamed:@"panel_top_outline_selected"];
            outline.image = normalImg;
            outline.selectImage = selImg;
            itemCount++;
            [array addObject:outline];
        }
        
        if(config.loadAnnotations) {
            SegmentItem *annotation = [[SegmentItem alloc] init];
            annotation.tag = 30;
            normalImg = [UIImage imageNamed:@"panel_top_annot_normal"];
            selImg = [UIImage imageNamed:@"panel_top_annot_selected"];
            annotation.image = normalImg;
            annotation.selectImage = selImg;
            itemCount++;
            [array addObject:annotation];
        }
        
        if(config.loadAttachment) {
            SegmentItem *attachment = [[SegmentItem alloc] init];
            attachment.tag = 40;
            attachment.image = [UIImage imageNamed:@"panel_top_attach_normal"];
            attachment.selectImage = [UIImage imageNamed:@"panel_top_attach_selected"];
            itemCount++;
            [array addObject:attachment];
        }
        
        NSInteger width = (self.contentView.bounds.size.width-20)/itemCount;
        segmentView = [[SegmentView alloc] initWithFrame:CGRectMake(10, 60, width*itemCount, 40) segmentItems:array];
        segmentView.delegate = self;
        segmentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.contentView addSubview:segmentView];
        self.contentView.autoresizesSubviews = YES;
        self.contentView.backgroundColor = [UIColor whiteColor];
        if(array.count > 0)
            [segmentView setSelectItem:[array objectAtIndex:0]];
    }
    return self;
}

- (void)itemClickWithItem:(SegmentItem *)item;
{
    
    if (item.tag == 10)
    {
        for (id<IPanelSpec>spec in self.spaces)
        {
            if ([spec getTag] == 1)
            {
                [self setCurrentSpace:spec];
                break;
            }
        }
        
    } else if (item.tag == 20)
    {
        for (id<IPanelSpec>spec in self.spaces)
        {
            if ([spec getTag] == 2)
            {
                [self setCurrentSpace:spec];
                break;
            }
        }
        
    } else if (item.tag == 30)
    {
        for (id<IPanelSpec>spec in self.spaces)
        {
            if ([spec getTag] == 3)
            {
                [self setCurrentSpace:spec];
                break;
            }
        }
    }
    else if (item.tag == 40)
    {
        for (id<IPanelSpec> spec in self.spaces) {
            if ([spec getTag] == 4) {
                [self setCurrentSpace:spec];
                break;
            }
        }
    }

}

-(void)addSpec:(id<IPanelSpec>)spec
{
    [self.spaces addObject:spec];
    
    [spec getTopToolbar].frame = CGRectMake([spec getTopToolbar].frame.origin.x, [spec getTopToolbar].frame.origin.y, DEVICE_iPHONE?([spec getContentView].bounds.size.width) :300,[spec getTopToolbar].frame.size.height);
    [spec getContentView].frame = CGRectMake([spec getContentView].frame.origin.x, [spec getContentView].frame.origin.y, DEVICE_iPHONE?([spec getContentView].bounds.size.width) :300,[spec getContentView].frame.size.height);
    
    [self.contentView insertSubview:[spec getTopToolbar] belowSubview:segmentView];
    [self.contentView insertSubview:[spec getContentView] belowSubview:segmentView];
    [[spec getTopToolbar] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(0);
        make.right.equalTo(self.contentView.mas_right).offset(0);
        make.top.equalTo(self.contentView.mas_top).offset(0);
        make.height.mas_equalTo(@107);
        
    }];
    
    [[spec getContentView] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(0);
        make.right.equalTo(self.contentView.mas_right).offset(0);
        make.top.equalTo(self.contentView.mas_top).offset(107);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(0);
    }];
    
    [[spec getTopToolbar] setHidden:YES];
    [[spec getContentView] setHidden:YES];
}

-(void)removeSpec:(id<IPanelSpec>)spec{

}

-(void)setCurrentSpace:(id<IPanelSpec>)currentSpace
{
    if (currentSpace != self.currentSpace)
    {
        if (0 < self.spaces.count)
        {
            [[self.currentSpace getTopToolbar] setHidden:YES];
            [[self.currentSpace getContentView] setHidden:YES];
        }
        _currentSpace = currentSpace;
        [[_currentSpace getTopToolbar] setHidden:NO];
        [[_currentSpace getContentView] setHidden:NO];
    }
}

-(UIView*)contentView
{
    return _contentView;
}

@end
