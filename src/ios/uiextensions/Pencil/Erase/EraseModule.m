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

#import "EraseModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "EraseToolHandler.h"
#import "Utility.h"

@interface EraseModule ()

@property (nonatomic, weak) TbBaseItem *propertyItem;
@end

@implementation EraseModule {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
}

- (NSString *)getName {
    return @"Eraser";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [self loadModule];
        [[EraseToolHandler alloc] initWithUIExtensionsManager:extensionsManager];
    }
    return self;
}

- (void)loadModule {
    _extensionsManager.moreToolsBar.eraserClicked = ^() {
        [self annotItemClicked];
    };
}

- (void)annotItemClicked {
    [_extensionsManager changeState:STATE_ANNOTTOOL];
    id<IToolHandler> toolHandler = [_extensionsManager getToolHandlerByName:Tool_Eraser];
    [_extensionsManager setCurrentToolHandler:toolHandler];

    [_extensionsManager.toolSetBar removeAllItems];

    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_done"] imageSelected:[UIImage imageNamed:@"annot_done"] imageDisable:[UIImage imageNamed:@"annot_done"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    doneItem.tag = 0;
    [_extensionsManager.toolSetBar addItem:doneItem displayPosition:Position_CENTER];
    doneItem.onTapClick = ^(TbBaseItem *item) {
        [_extensionsManager setCurrentToolHandler:nil];
        [_extensionsManager changeState:STATE_EDIT];
    };

    TbBaseItem *propertyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annotation_toolitembg"] imageSelected:[UIImage imageNamed:@"annotation_toolitembg"] imageDisable:[UIImage imageNamed:@"annotation_toolitembg"]];
    self.propertyItem = propertyItem;
    self.propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[UIColor grayColor].rgbHex];
    [_extensionsManager.toolSetBar addItem:self.propertyItem displayPosition:Position_CENTER];
    self.propertyItem.onTapClick = ^(TbBaseItem *item) {
        CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_pdfViewCtrl];
        [_extensionsManager showProperty:e_annotInk rect:rect inView:_pdfViewCtrl];
    };

    TbBaseItem *iconItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_more"] imageSelected:[UIImage imageNamed:@"annot_more"] imageDisable:[UIImage imageNamed:@"annot_more"]];
    iconItem.tag = 4;
    [_extensionsManager.toolSetBar addItem:iconItem displayPosition:Position_CENTER];
    iconItem.onTapClick = ^(TbBaseItem *item) {
        _extensionsManager.hiddenMoreToolsBar = NO;
    };
    [Utility showAnnotationType:FSLocalizedString(@"kErase") type:e_annotInk pdfViewCtrl:_pdfViewCtrl belowSubview:_extensionsManager.toolSetBar.contentView];

    [self.propertyItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.propertyItem.contentView.superview.mas_bottom).offset(-5);
        make.centerX.equalTo(self.propertyItem.contentView.superview.mas_centerX);
        make.width.mas_equalTo(self.propertyItem.contentView.bounds.size.width);
        make.height.mas_equalTo(self.propertyItem.contentView.bounds.size.height);
    }];

    [doneItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(doneItem.contentView.superview.mas_bottom).offset(-5);
        make.right.equalTo(self.propertyItem.contentView.mas_left).offset(-30);
        make.width.mas_equalTo(doneItem.contentView.bounds.size.width);
        make.height.mas_equalTo(doneItem.contentView.bounds.size.height);

    }];

    [iconItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(iconItem.contentView.superview.mas_bottom).offset(-5);
        make.left.equalTo(self.propertyItem.contentView.mas_right).offset(30);
        make.width.mas_equalTo(iconItem.contentView.bounds.size.width);
        make.height.mas_equalTo(iconItem.contentView.bounds.size.height);

    }];
}

@end
