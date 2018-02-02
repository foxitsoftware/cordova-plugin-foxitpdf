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

#import "TextboxModule.h"
#import "FtAnnotHandler.h"
#import "SelectToolHandler.h"
#import "TextboxToolHandler.h"

@interface TextboxModule ()

@property (nonatomic, weak) UIExtensionsManager *extensionsManager;

@property (nonatomic, strong) PropertyBar *propertyMenu;
//@property (nonatomic, strong) TextboxToolHandler *toolHandler;
//@property (nonatomic, strong) FtAnnotHandler *annotHandler;

//@property (nonatomic, assign) unsigned int currentColor;
//@property (nonatomic, assign) int currentOpacity;
//@property (nonatomic, strong) NSString *currentFontName;
//@property (nonatomic, assign) float currentFontSize;

//@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, weak) TbBaseItem *propertyItem;
@property (nonatomic, assign) BOOL propertyIsShow;
@property (nonatomic, assign) BOOL shouldShowProperty;

@end

@implementation TextboxModule

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        self.extensionsManager = extensionsManager;
        //        self.colors = @[ @0x7480FC, @0xFFFF00, @0xCCFF66, @0x00FFFF, @0x99CCFF, @0xCC99FF, @0xFF9999, @0xFFFFFF, @0xC3C3C3, @0x000000 ];
        [_extensionsManager registerAnnotPropertyListener:self];
        [self loadModule];
    }
    return self;
}

- (NSString *)getName {
    return @"Textbox";
}

- (void)loadModule {
    TextboxToolHandler *toolHandler = [[TextboxToolHandler alloc] initWithUIExtensionsManager:_extensionsManager];
    [_extensionsManager registerToolHandler:toolHandler];

    FtAnnotHandler *annotHandler = [[FtAnnotHandler alloc] initWithUIExtensionsManager:_extensionsManager];
    [_extensionsManager registerAnnotHandler:annotHandler];
    [_extensionsManager registerRotateChangedListener:annotHandler];
    [_extensionsManager registerGestureEventListener:annotHandler];
    [_extensionsManager.propertyBar registerPropertyBarListener:annotHandler];

    //    [[APPDELEGATE.app.read getDocMgr] registerDocEventListener:self];
    //    [[APPDELEGATE.app.read getDocViewer] registerTouchEventListener:self.toolHandler];
    //    [APPDELEGATE.app.eventMgr registerReadEventListener:self.toolHandler];
    //    [[APPDELEGATE.app.read getReadFrame] registerSizeClassChangedListener:self];
    //    [self.propertyMenu registerPropertyBarListener:self];

    //    [[NSNotificationCenter defaultCenter] addObserver:self.toolHandler selector:@selector(orientationChanges:) name:UIDeviceOrientationDidChangeNotification object:nil];
    //    self.propertyMenu = [APPDELEGATE.app.read getReadFrame].propertyBarModule;

    //    self.currentColor = [AppPreference getIntValue:[self getName] type:@"Color" defaultValue:-1];
    //    self.currentOpacity = [AppPreference getIntValue:[self getName] type:@"Opacity" defaultValue:0];
    //    self.currentFontName = [AppPreference getStringValue:[self getName] type:@"FontName" defaultValue:@"Times-Roman"];
    //    self.currentFontSize = [AppPreference getFloatValue:[self getName] type:@"FontSize" defaultValue:0];
    //    if (self.currentColor == -1) {
    //        NSNumber *color = [self.colors objectAtIndex:0];
    //        self.currentColor = color.intValue;
    //        [AppPreference setIntValue:[self getName] type:@"Color" value:self.currentColor];
    //    }
    //    if (self.currentOpacity == 0) {
    //        self.currentOpacity = 100;
    //        [AppPreference setIntValue:[self getName] type:@"Opacity" value:self.currentOpacity];
    //    }
    //    if (self.currentFontName == nil) {
    //        self.currentFontName = @"Times-Roman";
    //        [AppPreference setStringValue:[self getName] type:@"FontName" value:@"Times-Roman"];
    //    }
    //
    //    if (self.currentFontSize == 0) {
    //        self.currentFontSize = 18;
    //        [AppPreference setFloatValue:[self getName] type:@"FontSize" value:18];
    //    }
    //
    //    self.toolHandler.color = self.currentColor;
    //    self.toolHandler.opacity = self.currentOpacity;
    //    self.toolHandler.fontName = self.currentFontName;
    //    self.toolHandler.fontSize = self.currentFontSize;

    _extensionsManager.moreToolsBar.textboxClicked = ^() {
        [self annotItemClicked];
    };
}

- (void)annotItemClicked {
    SelectToolHandler *select = (SelectToolHandler *) [_extensionsManager getToolHandlerByName:Tool_Select];
    [select clearSelection];
    [_extensionsManager changeState:STATE_ANNOTTOOL];
    id<IToolHandler> toolHandler = [_extensionsManager getToolHandlerByName:Tool_Textbox];
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
    //    self.currentColor = [AppPreference getIntValue:[self getName] type:@"Color" defaultValue:0];
    //    self.currentOpacity = [AppPreference getIntValue:[self getName] type:@"Opacity" defaultValue:100];
    //    self.currentFontName = [AppPreference getStringValue:[self getName] type:@"FontName" defaultValue:@"Times-Roman"];
    //    self.currentFontSize = [AppPreference getFloatValue:[self getName] type:@"FontSize" defaultValue:18];
    propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:e_annotFreeText]];
    [_extensionsManager.toolSetBar addItem:propertyItem displayPosition:Position_CENTER];
    propertyItem.onTapClick = ^(TbBaseItem *item) {
        if (DEVICE_iPHONE) {
            CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_extensionsManager.pdfViewCtrl];
            [_extensionsManager showProperty:e_annotFreeText rect:rect inView:_extensionsManager.pdfViewCtrl];
        } else {
            [_extensionsManager showProperty:e_annotFreeText rect:item.contentView.bounds inView:item.contentView];
        }

        //        BOOL isContain = NO;
        //        UInt32 firstColor = [AppPreference getIntValue:[self getName] type:@"Color" defaultValue:0];
        //        for (NSNumber *value in self.colors) {
        //            if (firstColor == value.intValue) {
        //                isContain = YES;
        //                break;
        //            }
        //        }
        //
        //        if (!isContain) {
        //            self.colors = @[ [NSNumber numberWithInt:firstColor], @0xFFFF00, @0xCCFF66, @0x00FFFF, @0x99CCFF, @0xCC99FF, @0xFF9999, @0xFFFFFF, @0xC3C3C3, @0x000000 ];
        //        }
        //        PropertyBar *property = [APPDELEGATE.app.read getReadFrame].propertyBarModule;
        //        [property setColors:self.colors];
        //        [property resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_FONTNAME | PROPERTY_FONTSIZE];
        //
        //        [property setProperty:PROPERTY_COLOR intValue:self.currentColor];
        //        [property setProperty:PROPERTY_OPACITY intValue:self.currentOpacity];
        //        [property setProperty:PROPERTY_FONTSIZE floatValue:self.currentFontSize];
        //        [property setProperty:PROPERTY_FONTNAME stringValue:self.currentFontName];
        //        [property addListener:self];
        //        self.propertyIsShow = YES;
        //        CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:[APPDELEGATE.app.read getReadFrame].viewController.view];
        //
        //        if (DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact) {
        //            [self.propertyMenu showPropertyBar:rect inView:[APPDELEGATE.app.read getReadFrame].viewController.view viewsCanMove:nil];
        //        } else {
        //            [self.propertyMenu showPropertyBar:item.contentView.bounds inView:item.contentView viewsCanMove:nil];
        //        }

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
        // todo wei bad practise
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
    [Utility showAnnotationType:FSLocalizedString(@"kTextbox") type:e_annotFreeText pdfViewCtrl:_extensionsManager.pdfViewCtrl belowSubview:_extensionsManager.toolSetBar.contentView];

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
    //    [Utility showBlindView:Annot_FreeText doneItem:doneItem propertyItem:_propertyItem continueItem:continueItem moreItem:iconItem signEidtItem:nil];
}

- (void)onPropertyBarDismiss {
    self.propertyIsShow = NO;
}

//- (void)onSizeClassWillChanged:(UIUserInterfaceSizeClass)sizeClass {
//    if (DEVICE_iPHONE || !self.propertyIsShow || ![self.propertyMenu isShowing]) {
//        return;
//    }
//    [self.propertyMenu dismissPropertyBarNOAnimated];
//    self.shouldShowProperty = YES;
//}

//- (void)onSizeClassChanged:(UIUserInterfaceSizeClass)sizeClass {
//    if (!self.shouldShowProperty) {
//        return;
//    }
//    self.shouldShowProperty = NO;
//
//    CGRect rect = [self.propertyItem.contentView convertRect:self.propertyItem.contentView.bounds toView:[APPDELEGATE.app.read getReadFrame].viewController.view];
//    [self.propertyMenu refreshPropertyLayout];
//    self.propertyIsShow = YES;
//    if (DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact) {
//        [self.propertyMenu showPropertyBar:rect inView:[APPDELEGATE.app.read getReadFrame].viewController.view viewsCanMove:nil];
//    } else {
//        [self.propertyMenu showPropertyBar:self.propertyItem.contentView.bounds inView:self.propertyItem.contentView viewsCanMove:nil];
//    }
//}

- (void)dismissAnnotationContinue {
    [Utility dismissAnnotationContinue:_extensionsManager.pdfViewCtrl];
}

//- (void)onDocumentWillOpen:(DmFileDescriptor *)descriptor {
//}
//
//- (void)onDocumentOpened:(DmDocument *)document error:(int)error {
//}
//
//- (void)onDocumentWillClose:(DmDocument *)document {
//    if (self.annotHandler.currentVC) {
//        if (DEVICE_iPHONE && [self.annotHandler.currentVC isKindOfClass:[UIActivityViewController class]]) {
//            [(UIActivityViewController *) self.annotHandler.currentVC dismissViewControllerAnimated:NO completion:nil];
//        } else if (!DEVICE_iPHONE && [self.annotHandler.currentVC isKindOfClass:[UIPopoverController class]]) {
//            [(UIPopoverController *) self.annotHandler.currentVC dismissPopoverAnimated:NO];
//        }
//    }
//}
//
//- (void)onDocumentClosed:(DmDocument *)document error:(int)error {
//}
//
//- (void)onDocumentWillSave:(DmDocument *)document {
//}
//

#pragma mark <IAnnotPropertyListener>

- (void)onAnnotColorChanged:(unsigned int)color annotType:(FSAnnotType)annotType {
    if (annotType == e_annotFreeText && [[_extensionsManager.currentToolHandler getName] isEqualToString:Tool_Textbox]) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

//- (void)onIntValueChanged:(long)property value:(int)value {
//    if (property == PROPERTY_COLOR) {
//        self.toolHandler.color = value;
//        self.annotHandler.color = value;
//        self.currentColor = value;
//        [AppPreference setIntValue:[self getName] type:@"Color" value:value];
//        [self.propertyItem setInsideCircleColor:value];
//
//    } else if (property == PROPERTY_OPACITY) {
//        self.toolHandler.opacity = value;
//        self.annotHandler.opacity = value;
//        self.currentOpacity = value;
//        [AppPreference setIntValue:[self getName] type:@"Opacity" value:value];
//    }
//}
//
//- (void)onFloatValueChanged:(long)property value:(float)value {
//    if (property == PROPERTY_FONTSIZE) {
//        self.toolHandler.fontSize = value;
//        self.annotHandler.fontSize = value;
//        self.currentFontSize = value;
//        [AppPreference setFloatValue:[self getName] type:@"FontSize" value:value];
//    }
//}
//
//- (void)onStringValueChanged:(long)property value:(NSString *)value {
//    if (property == PROPERTY_FONTNAME) {
//        self.toolHandler.fontName = value;
//        self.annotHandler.fontName = value;
//        self.currentFontName = value;
//        [AppPreference setStringValue:[self getName] type:@"FontName" value:value];
//    }
//}

@end
