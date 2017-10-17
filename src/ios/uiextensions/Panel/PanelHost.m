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
#import "IPanelSpec.h"
#import "Masonry.h"
#import "NSSet+containsAnyObjectInArray.h"
#import "UIExtensionsManager+Private.h"

@implementation PanelButton

@end

@implementation PanelHost

- (instancetype)initWithSize:(CGSize)size panelTypes:(NSArray<NSNumber *> *)panelTypes {
    self = [super init];
    if (self) {
        self.spaces = [[NSMutableArray alloc] init];
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        self.contentView.autoresizesSubviews = YES;
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self loadSegmentViewWithPanelTypes:panelTypes];
    }
    return self;
}

- (void)loadSegmentViewWithPanelTypes:(NSArray<NSNumber *> *)panelTypes {
    if (segmentView) {
        [segmentView removeFromSuperview];
    }
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    UIImage *normalImg = nil;
    UIImage *selImg = nil;
    
    if ([panelTypes containsObject:@(FSPanelTypeReadingBookmark)]) {
        SegmentItem *bookmark = [[SegmentItem alloc] init];
        bookmark.tag = FSPanelTagReadingBookmark;
        bookmark.image = [UIImage imageNamed:@"panel_top_bookmak_normal"];
        bookmark.selectImage = [UIImage imageNamed:@"panel_top_bookmak_selected"];
        [items addObject:bookmark];
    }
    if ([panelTypes containsObject:@(FSPanelTypeOutline)]) {
        SegmentItem *outline = [[SegmentItem alloc] init];
        outline.tag = FSPanelTagOutline;
        normalImg = [UIImage imageNamed:@"panel_top_outline_normal"];
        selImg = [UIImage imageNamed:@"panel_top_outline_selected"];
        outline.image = normalImg;
        outline.selectImage = selImg;
        [items addObject:outline];
    }
    if ([panelTypes containsObject:@(FSPanelTypeAnnotation)]) {
        SegmentItem *annotation = [[SegmentItem alloc] init];
        annotation.tag = FSPanelTagAnnotation;
        normalImg = [UIImage imageNamed:@"panel_top_annot_normal"];
        selImg = [UIImage imageNamed:@"panel_top_annot_selected"];
        annotation.image = normalImg;
        annotation.selectImage = selImg;
        [items addObject:annotation];
    }
    if ([panelTypes containsObject:@(FSPanelTypeAttachment)]) {
        SegmentItem *attachment = [[SegmentItem alloc] init];
        attachment.tag = FSPanelTagAttachment;
        attachment.image = [UIImage imageNamed:@"panel_top_attach_normal"];
        attachment.selectImage = [UIImage imageNamed:@"panel_top_attach_selected"];
        [items addObject:attachment];
    }
    
    NSInteger width = (self.contentView.bounds.size.width - 20) / items.count;
    segmentView = [[SegmentView alloc] initWithFrame:CGRectMake(10, 60, width * items.count, 40) segmentItems:items];
    segmentView.delegate = self;
    segmentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.contentView addSubview:segmentView];
    if (items.count > 0) {
        [segmentView setSelectItem:[items objectAtIndex:0]];
    }
}

#pragma mark <SegmentDelegate>

- (void)itemClickWithItem:(SegmentItem *)item;
{
    assert(item.tag != 0);
    for (id<IPanelSpec> spec in self.spaces) {
        if ([spec getTag] == item.tag) {
            [self setCurrentSpace:spec];
            break;
        }
    }
}

- (void)addSpec:(id<IPanelSpec>)spec {
    [self.spaces addObject:spec];

    [spec getTopToolbar].frame = CGRectMake([spec getTopToolbar].frame.origin.x, [spec getTopToolbar].frame.origin.y, DEVICE_iPHONE ? ([spec getContentView].bounds.size.width) : 300, [spec getTopToolbar].frame.size.height);
    [spec getContentView].frame = CGRectMake([spec getContentView].frame.origin.x, [spec getContentView].frame.origin.y, DEVICE_iPHONE ? ([spec getContentView].bounds.size.width) : 300, [spec getContentView].frame.size.height);

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

- (void)removeSpec:(id<IPanelSpec>)spec {
    if (spec == self.currentSpace) {
        self.currentSpace = ({
            id<IPanelSpec> firstOtherPanel = nil;
            for (id<IPanelSpec> panel in self.spaces) {
                if (panel != spec) {
                    firstOtherPanel = panel;
                    break;
                }
            }
            firstOtherPanel;
        });
    }
    [[spec getTopToolbar] removeFromSuperview];
    [[spec getContentView] removeFromSuperview];
    [self.spaces removeObject:spec];
}

- (void)reloadSegmentView {
    [self loadSegmentViewWithPanelTypes:({
        NSMutableArray<NSNumber *> *panelTypes = @[].mutableCopy;
        for (id<IPanelSpec> panel in self.spaces) {
            switch ([panel getTag]) {
                case FSPanelTagAnnotation:
                    [panelTypes addObject:@(FSPanelTypeAnnotation)];
                    break;
                case FSPanelTagAttachment:
                    [panelTypes addObject:@(FSPanelTypeAttachment)];
                    break;
                case FSPanelTagOutline:
                    [panelTypes addObject:@(FSPanelTypeOutline)];
                    break;
                case FSPanelTagReadingBookmark:
                    [panelTypes addObject:@(FSPanelTypeReadingBookmark)];
                    break;
                default:
                    break;
            }
        }
        panelTypes;
    })];
}

- (void)setCurrentSpace:(id<IPanelSpec>)currentSpace {
    if (currentSpace != self.currentSpace) {
        if (0 < self.spaces.count) {
            [[self.currentSpace getTopToolbar] setHidden:YES];
            [[self.currentSpace getContentView] setHidden:YES];
            [self.currentSpace onDeactivated];
        }
        _currentSpace = currentSpace;
        [[_currentSpace getTopToolbar] setHidden:NO];
        [[_currentSpace getContentView] setHidden:NO];
        [_currentSpace onActivated];
    }
}

- (UIView *)contentView {
    return _contentView;
}

@end
