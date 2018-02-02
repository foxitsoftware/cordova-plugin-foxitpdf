/**
 * Copyright (C) 2003-2018, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "PolygonModule.h"
#import "PolygonAnnotHandler.h"
#import "PolygonToolHandler.h"
#import "Utility.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface PolygonModule ()

@property (nonatomic, weak) TbBaseItem *propertyItem;
@property (nonatomic) BOOL isPolygon;

@end

@implementation PolygonModule {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
}

- (NSString *)getName {
    return @"Shape";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _isPolygon = YES;
        [self loadModule];
        PolygonAnnotHandler *annotHandler = [[PolygonAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_pdfViewCtrl registerDocEventListener:annotHandler];
        [_pdfViewCtrl registerScrollViewEventListener:annotHandler];
        [_extensionsManager registerAnnotHandler:annotHandler];
        [_extensionsManager registerRotateChangedListener:annotHandler];
        [_extensionsManager registerGestureEventListener:annotHandler];
        [_extensionsManager.propertyBar registerPropertyBarListener:annotHandler];

        PolygonToolHandler *toolHandler = [[PolygonToolHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_extensionsManager registerToolHandler:toolHandler];

        annotHandler.minVertexDistance = 5;
        toolHandler.minVertexDistance = 5;
    }
    return self;
}

- (void)loadModule {
    [_extensionsManager registerAnnotPropertyListener:self];

    _extensionsManager.moreToolsBar.polygonClicked = ^() {
        self.isPolygon = YES;
        [self annotItemClicked];

    };
    _extensionsManager.moreToolsBar.cloudClicked = ^() {
        self.isPolygon = NO;
        [self annotItemClicked];

    };
}

- (void)annotItemClicked {
    [_extensionsManager changeState:STATE_ANNOTTOOL];
    PolygonToolHandler *toolHandler = (PolygonToolHandler *) [_extensionsManager getToolHandlerByName:Tool_Polygon];
    toolHandler.isPolygon = self.isPolygon;
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
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:e_annotPolygon]];
    [_extensionsManager.toolSetBar addItem:self.propertyItem displayPosition:Position_CENTER];

    self.propertyItem.onTapClick = ^(TbBaseItem *item) {
        CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_extensionsManager.pdfViewCtrl];
        if (DEVICE_iPHONE) {
            [_extensionsManager showProperty:e_annotPolygon rect:rect inView:_extensionsManager.pdfViewCtrl];
        } else {
            [_extensionsManager showProperty:e_annotPolygon rect:item.contentView.bounds inView:item.contentView];
        }
    };

    TbBaseItem *iconItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"common_read_more"] imageSelected:[UIImage imageNamed:@"common_read_more"] imageDisable:[UIImage imageNamed:@"common_read_more"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    iconItem.tag = 4;
    [_extensionsManager.toolSetBar addItem:iconItem displayPosition:Position_CENTER];
    iconItem.onTapClick = ^(TbBaseItem *item) {
        _extensionsManager.hiddenMoreToolsBar = NO;
    };
    [Utility showAnnotationType:self.isPolygon ? FSLocalizedString(@"kPolygon") : FSLocalizedString(@"kCloud") type:e_annotPolygon pdfViewCtrl:_extensionsManager.pdfViewCtrl belowSubview:_extensionsManager.toolSetBar.contentView];

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

- (void)dismissAnnotationContinue {
    [Utility dismissAnnotationContinue:_extensionsManager.pdfViewCtrl];
}

#pragma mark - IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(FSAnnotType)annotType {
    if (annotType == e_annotPolygon) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

@end
