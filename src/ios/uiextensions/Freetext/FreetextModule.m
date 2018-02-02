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

#import "FreetextModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "../Common/UIExtensionsSharedHeader.h"
#import "FtAnnotHandler.h"
#import "FtToolHandler.h"
#import "Utility.h"

@interface FreetextModule ()

@property (nonatomic, weak) TbBaseItem *propertyItem;

@end

@implementation FreetextModule {
    UIExtensionsManager *__weak _extensionsManager;
}

- (NSString *)getName {
    return @"Freetext";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        [_extensionsManager registerAnnotPropertyListener:self];
        [self loadModule];
        FtAnnotHandler* annotHandler = [[FtAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_extensionsManager registerAnnotHandler:annotHandler];
        [_extensionsManager registerRotateChangedListener:annotHandler];
        [_extensionsManager registerGestureEventListener:annotHandler];
        [_extensionsManager.propertyBar registerPropertyBarListener:annotHandler];
        [_extensionsManager.pdfViewCtrl registerScrollViewEventListener:annotHandler];
        
        FtToolHandler* toolHandler = [[FtToolHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_extensionsManager registerToolHandler:toolHandler];
        [_extensionsManager registerRotateChangedListener:toolHandler];
        [_extensionsManager.pdfViewCtrl registerScrollViewEventListener:toolHandler];
    }
    return self;
}

- (void)loadModule {
    TbBaseItem *tyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_typewriter"] imageSelected:[UIImage imageNamed:@"annot_typewriter"] imageDisable:[UIImage imageNamed:@"annot_typewriter"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    tyItem.tag = DEVICE_iPHONE ? EDIT_ITEM_FREETEXT : -EDIT_ITEM_FREETEXT;
    tyItem.onTapClick = ^(TbBaseItem *item) {
        [self annotItemClicked];
    };

    [_extensionsManager.editBar addItem:tyItem displayPosition:DEVICE_iPHONE ? Position_RB : Position_CENTER];

    _extensionsManager.moreToolsBar.typerwriterClicked = ^() {
        [self annotItemClicked];
    };
}

- (void)annotItemClicked {
    [_extensionsManager changeState:STATE_ANNOTTOOL];
    [_extensionsManager setCurrentToolHandler:[_extensionsManager getToolHandlerByName:Tool_Freetext]];
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
    _propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:e_annotFreeText]];
    [_extensionsManager.toolSetBar addItem:_propertyItem displayPosition:Position_CENTER];
    _propertyItem.onTapClick = ^(TbBaseItem *item) {
        CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_extensionsManager.pdfViewCtrl];

        if (DEVICE_iPHONE) {
            [_extensionsManager showProperty:e_annotFreeText rect:rect inView:_extensionsManager.pdfViewCtrl];
        } else {
            [_extensionsManager showProperty:e_annotFreeText rect:item.contentView.bounds inView:item.contentView];
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
    [Utility showAnnotationType:FSLocalizedString(@"kTypewriter") type:e_annotFreeText pdfViewCtrl:_extensionsManager.pdfViewCtrl belowSubview:_extensionsManager.toolSetBar.contentView];

    [_propertyItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(_propertyItem.contentView.superview.mas_bottom).offset(-5);
        make.right.equalTo(_propertyItem.contentView.superview.mas_centerX).offset(-15);
        make.width.mas_equalTo(_propertyItem.contentView.bounds.size.width);
        make.height.mas_equalTo(_propertyItem.contentView.bounds.size.height);
    }];

    [continueItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(continueItem.contentView.superview.mas_bottom).offset(-5);
        make.left.equalTo(_propertyItem.contentView.superview.mas_centerX).offset(15);
        make.width.mas_equalTo(continueItem.contentView.bounds.size.width);
        make.height.mas_equalTo(continueItem.contentView.bounds.size.height);

    }];

    [doneItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(doneItem.contentView.superview.mas_bottom).offset(-5);
        make.right.equalTo(_propertyItem.contentView.mas_left).offset(-30);
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

#pragma mark - IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(FSAnnotType)annotType {
    if (annotType == e_annotFreeText && [[_extensionsManager.currentToolHandler getName] isEqualToString:Tool_Freetext]) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

@end
