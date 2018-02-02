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

#import "ImageModule.h"
#import "../Common/UIExtensionsSharedHeader.h"
#import "FSFileAndImagePicker.h"
#import "ImageAnnotHandler.h"
#import "ImageToolHandler.h"
#import "Utility.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface ImageModule () <FSFileAndImagePickerDelegate>

@property (nonatomic, weak) TbBaseItem *propertyItem;

@property (nonatomic, strong) NSArray *colors;

@end

@implementation ImageModule {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
}

- (NSString *)getName {
    return @"Image";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [self loadModule];
        ImageToolHandler *toolHandler = [[ImageToolHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_extensionsManager registerToolHandler:toolHandler];
        ImageAnnotHandler *annotHandler = [[ImageAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_extensionsManager registerAnnotHandler:annotHandler];
        [_extensionsManager registerRotateChangedListener:annotHandler];
        [_pdfViewCtrl registerScrollViewEventListener:annotHandler];
        [_extensionsManager registerRotateChangedListener:annotHandler];
        [_extensionsManager registerGestureEventListener:annotHandler];
        [_extensionsManager.propertyBar registerPropertyBarListener:annotHandler];

        annotHandler.minImageWidthInPage = annotHandler.minImageHeightInPage = 0.1;
        annotHandler.maxImageWidthInPage = annotHandler.maxImageHeightInPage = 0.7;
    }
    return self;
}

- (void)loadModule {
    _extensionsManager.moreToolsBar.imageClicked = ^() {
        [self annotItemClicked];
    };
}

- (void)annotItemClicked {
    ImageToolHandler *toolHanlder = (ImageToolHandler *) [_extensionsManager getToolHandlerByName:Tool_Image];
    [_extensionsManager setCurrentToolHandler:toolHanlder];

    if (!DEVICE_iPHONE) {
        [_extensionsManager setHiddenMoreToolsBar:YES]; // dismiss popover
    }
    FSFileAndImagePicker *picker = [[FSFileAndImagePicker alloc] init];
    picker.delegate = self;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [picker presentInRootViewController:rootViewController fromView:nil];

    [_extensionsManager.toolSetBar removeAllItems];

    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_done"] imageSelected:[UIImage imageNamed:@"annot_done"] imageDisable:[UIImage imageNamed:@"annot_done"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    doneItem.tag = 0;
    [_extensionsManager.toolSetBar addItem:doneItem displayPosition:Position_CENTER];
    doneItem.onTapClick = ^(TbBaseItem *item) {
        if (_extensionsManager.currentToolHandler) {
            [_extensionsManager setCurrentToolHandler:nil];
        }
        [_extensionsManager changeState:STATE_EDIT];
    };

    TbBaseItem *propertyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annotation_toolitembg"] imageSelected:[UIImage imageNamed:@"annotation_toolitembg"] imageDisable:[UIImage imageNamed:@"annotation_toolitembg"]];
    self.propertyItem = propertyItem;
    self.propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[UIColor grayColor].rgbHex];
    [_extensionsManager.toolSetBar addItem:self.propertyItem displayPosition:Position_CENTER];
    self.propertyItem.onTapClick = ^(TbBaseItem *item) {
        CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_pdfViewCtrl];
        if (DEVICE_iPHONE) {
            [_extensionsManager showProperty:e_annotScreen rect:rect inView:_pdfViewCtrl];
        } else {
            [_extensionsManager showProperty:e_annotScreen rect:item.contentView.bounds inView:item.contentView];
        }
    };

    //    TbBaseItem *continueItem = nil;
    //    if (_extensionsManager.continueAddAnnot) {
    //        continueItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_continue"] imageSelected:[UIImage imageNamed:@"annot_continue"] imageDisable:[UIImage imageNamed:@"annot_continue"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    //    } else {
    //        continueItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_single"] imageSelected:[UIImage imageNamed:@"annot_single"] imageDisable:[UIImage imageNamed:@"annot_single"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    //    }
    //    continueItem.tag = 3;
    //    [_extensionsManager.toolSetBar addItem:continueItem displayPosition:Position_CENTER];
    //    continueItem.onTapClick = ^(TbBaseItem *item) {
    //        for (UIView *view in _pdfViewCtrl.subviews) {
    //            if (view.tag == 2112) {
    //                return;
    //            }
    //        }
    //        _extensionsManager.continueAddAnnot = !_extensionsManager.continueAddAnnot;
    //        if (_extensionsManager.continueAddAnnot) {
    //            item.imageNormal = [UIImage imageNamed:@"annot_continue"];
    //            item.imageSelected = [UIImage imageNamed:@"annot_continue"];
    //        } else {
    //            item.imageNormal = [UIImage imageNamed:@"annot_single"];
    //            item.imageSelected = [UIImage imageNamed:@"annot_single"];
    //        }
    //
    //        [Utility showAnnotationContinue:_extensionsManager.continueAddAnnot pdfViewCtrl:_pdfViewCtrl siblingSubview:_extensionsManager.toolSetBar.contentView];
    //        [self performSelector:@selector(dismissAnnotationContinue) withObject:nil afterDelay:1];
    //    };

    TbBaseItem *iconItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"common_read_more"] imageSelected:[UIImage imageNamed:@"common_read_more"] imageDisable:[UIImage imageNamed:@"common_read_more"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    iconItem.tag = 4;
    [_extensionsManager.toolSetBar addItem:iconItem displayPosition:Position_CENTER];
    iconItem.onTapClick = ^(TbBaseItem *item) {
        _extensionsManager.hiddenMoreToolsBar = NO;
    };

    [self.propertyItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.propertyItem.contentView.superview.mas_bottom).offset(-5);
        make.centerX.equalTo(self.propertyItem.contentView.superview.mas_centerX);
        //        make.right.equalTo(self.propertyItem.contentView.superview.mas_centerX).offset(-15);
        make.width.mas_equalTo(self.propertyItem.contentView.bounds.size.width);
        make.height.mas_equalTo(self.propertyItem.contentView.bounds.size.height);
    }];

    //    [continueItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.bottom.mas_equalTo(continueItem.contentView.superview.mas_bottom).offset(-5);
    //        make.left.equalTo(self.propertyItem.contentView.superview.mas_centerX).offset(15);
    //        make.width.mas_equalTo(continueItem.contentView.bounds.size.width);
    //        make.height.mas_equalTo(continueItem.contentView.bounds.size.height);
    //    }];

    [doneItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(doneItem.contentView.superview.mas_bottom).offset(-5);
        make.right.equalTo(self.propertyItem.contentView.mas_left).offset(-30);
        make.width.mas_equalTo(doneItem.contentView.bounds.size.width);
        make.height.mas_equalTo(doneItem.contentView.bounds.size.height);

    }];

    [iconItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(iconItem.contentView.superview.mas_bottom).offset(-5);
        make.left.equalTo(/* continueItem */ self.propertyItem.contentView.mas_right).offset(30);
        make.width.mas_equalTo(iconItem.contentView.bounds.size.width);
        make.height.mas_equalTo(iconItem.contentView.bounds.size.height);

    }];
    //    self.propertyItem.onTapClick(self.propertyItem);
}

- (void)dismissAnnotationContinue {
    [Utility dismissAnnotationContinue:_pdfViewCtrl];
}

#pragma mark <FSFileAndImagePickerDelegate>

- (void)fileAndImagePicker:(FSFileAndImagePicker *)fileAndImagePicker didPickImage:(UIImage *)image {
    ImageToolHandler *toolHanlder = (ImageToolHandler *) [_extensionsManager getToolHandlerByName:Tool_Image];
    toolHanlder.image = image;
    [_extensionsManager changeState:STATE_ANNOTTOOL];
    [Utility showAnnotationType:FSLocalizedString(@"kImage") type:e_annotScreen pdfViewCtrl:_pdfViewCtrl belowSubview:_extensionsManager.toolSetBar.contentView];
}

- (void)fileAndImagePickerDidCancel:(FSFileAndImagePicker *)fileAndImagePicker {
    _extensionsManager.currentToolHandler = nil;
    //    [_extensionsManager changeState:STATE_EDIT];
}

@end
