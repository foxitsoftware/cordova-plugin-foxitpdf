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

#import "LineModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "../Common/UIExtensionsSharedHeader.h"
#import "LineAnnotHandler.h"
#import "LineToolHandler.h"
#import "Utility.h"

@interface LineModule ()

@property (nonatomic, weak) TbBaseItem *propertyItem;

@end

@implementation LineModule {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
    FSAnnotType _annotType;
    BOOL _isArrLine;
}

- (NSString *)getName {
    return @"Line";
}

#pragma mark init
- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [_extensionsManager registerAnnotPropertyListener:self];

        [self loadModule];
        [[LineAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [[LineToolHandler alloc] initWithUIExtensionsManager:extensionsManager];
    }
    return self;
}

- (void)loadModule {
    _extensionsManager.moreToolsBar.arrowsClicked = ^() {
        _annotType = e_annotLine;
        _isArrLine = YES;
        [self annotItemClicked];
    };
    _extensionsManager.moreToolsBar.lineClicked = ^() {
        _annotType = e_annotLine;
        _isArrLine = NO;
        [self annotItemClicked];
    };
}

- (void)annotItemClicked {
    [_extensionsManager changeState:STATE_ANNOTTOOL];
    LineToolHandler *toolHandler = [_extensionsManager getToolHandlerByName:Tool_Line];
    toolHandler.type = _annotType;
    toolHandler.isArrowLine = _isArrLine;
    [_extensionsManager setCurrentToolHandler:toolHandler];
    [_extensionsManager.toolSetBar removeAllItems];

    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_done"] imageSelected:[UIImage imageNamed:@"annot_done"] imageDisable:[UIImage imageNamed:@"annot_done"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    doneItem.tag = 0;
    [_extensionsManager.toolSetBar addItem:doneItem displayPosition:Position_CENTER];

    doneItem.onTapClick = ^(TbBaseItem *item) {
        [_extensionsManager setCurrentToolHandler:nil];
        [_extensionsManager changeState:STATE_EDIT];
    };
    [_extensionsManager registerAnnotPropertyListener:self];
    TbBaseItem *propertyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annotation_toolitembg"] imageSelected:[UIImage imageNamed:@"annotation_toolitembg"] imageDisable:[UIImage imageNamed:@"annotation_toolitembg"]];
    self.propertyItem = propertyItem;
    self.propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:e_annotLine]];
    [_extensionsManager.toolSetBar addItem:_propertyItem displayPosition:Position_CENTER];
    self.propertyItem.onTapClick = ^(TbBaseItem *item) {
        CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_extensionsManager.pdfViewCtrl];
        if (DEVICE_iPHONE) {
            [_extensionsManager showProperty:_annotType rect:rect inView:_extensionsManager.pdfViewCtrl];
        } else {
            [_extensionsManager showProperty:_annotType rect:item.contentView.bounds inView:item.contentView];
        }
    };

    TbBaseItem *continueItem = nil;
    if (_extensionsManager.continueAddAnnot) {
        continueItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_continue"] imageSelected:[UIImage imageNamed:@"annot_continue"] imageDisable:[UIImage imageNamed:@"annot_continue"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    } else {
        continueItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_single"] imageSelected:[UIImage imageNamed:@"annot_single"] imageDisable:[UIImage imageNamed:@"annot_single"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    }
    continueItem.tag = 3;
    [_extensionsManager.toolSetBar addItem:continueItem displayPosition:Position_CENTER];
    continueItem.onTapClick = ^(TbBaseItem *item) {
        for (UIView *view in _extensionsManager.pdfViewCtrl.subviews) {
            if (view.tag == 2112) {
                return;
            }
        }
        _extensionsManager.continueAddAnnot = !_extensionsManager.continueAddAnnot;
        if (_extensionsManager.continueAddAnnot) {
            item.imageNormal = [UIImage imageNamed:@"annot_continue"];
            item.imageSelected = [UIImage imageNamed:@"annot_continue"];
        } else {
            item.imageNormal = [UIImage imageNamed:@"annot_single"];
            item.imageSelected = [UIImage imageNamed:@"annot_single"];
        }

        [Utility showAnnotationContinue:_extensionsManager.continueAddAnnot pdfViewCtrl:_extensionsManager.pdfViewCtrl siblingSubview:_extensionsManager.toolSetBar.contentView];
        [self performSelector:@selector(dismissAnnotationContinue) withObject:nil afterDelay:1];
    };

    TbBaseItem *iconItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"common_read_more"] imageSelected:[UIImage imageNamed:@"common_read_more"] imageDisable:[UIImage imageNamed:@"common_read_more"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    iconItem.tag = 4;
    [_extensionsManager.toolSetBar addItem:iconItem displayPosition:Position_CENTER];
    iconItem.onTapClick = ^(TbBaseItem *item) {
        _extensionsManager.hiddenMoreToolsBar = NO;
    };
    if (!_isArrLine) {
        [Utility showAnnotationType:FSLocalizedString(@"kLine") type:e_annotLine pdfViewCtrl:_extensionsManager.pdfViewCtrl belowSubview:_extensionsManager.toolSetBar.contentView];
    } else if (_isArrLine) {
        [Utility showAnnotationType:FSLocalizedString(@"kArrowLine") type:e_annotLine pdfViewCtrl:_extensionsManager.pdfViewCtrl belowSubview:_extensionsManager.toolSetBar.contentView];
    }

    [self.propertyItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.propertyItem.contentView.superview.mas_bottom).offset(-5);
        make.right.equalTo(self.propertyItem.contentView.superview.mas_centerX).offset(-15);
        make.width.mas_equalTo(self.propertyItem.contentView.bounds.size.width);
        make.height.mas_equalTo(self.propertyItem.contentView.bounds.size.height);
    }];

    [continueItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(continueItem.contentView.superview.mas_bottom).offset(-5);
        make.left.equalTo(self.propertyItem.contentView.superview.mas_centerX).offset(15);
        make.width.mas_equalTo(continueItem.contentView.bounds.size.width);
        make.height.mas_equalTo(continueItem.contentView.bounds.size.height);

    }];

    [doneItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(doneItem.contentView.superview.mas_bottom).offset(-5);
        make.right.equalTo(self.propertyItem.contentView.mas_left).offset(-30);
        make.width.mas_equalTo(doneItem.contentView.bounds.size.width);
        make.height.mas_equalTo(doneItem.contentView.bounds.size.height);

    }];

    [iconItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(iconItem.contentView.superview.mas_bottom).offset(-5);
        make.left.equalTo(continueItem.contentView.mas_right).offset(30);
        make.width.mas_equalTo(iconItem.contentView.bounds.size.width);
        make.height.mas_equalTo(iconItem.contentView.bounds.size.height);

    }];
}

- (void)dismissAnnotationContinue {
    [Utility dismissAnnotationContinue:_extensionsManager.pdfViewCtrl];
}

- (void)onAnnotColorChanged:(unsigned int)color annotType:(FSAnnotType)annotType {
    if (annotType == _annotType) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

@end
