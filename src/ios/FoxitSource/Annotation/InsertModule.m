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
#import "InsertModule.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import "UIExtensionsSharedHeader.h"
#import "Utility+Demo.h"
#import "Defines.h"

#import "../../uiextensions/SelectTool/SelectToolHandler.h"

@interface InsertModule ()

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) TbBaseItem *propertyItem;
@property (nonatomic, assign) BOOL propertyIsShow;
@property (nonatomic, assign) BOOL shouldShowProperty;

@end

@implementation InsertModule {
    FSPDFViewCtrl* _pdfViewCtrl;
    UIExtensionsManager* _extensionsManager;
    ReadFrame* _readFrame;
    enum FS_ANNOTTYPE _annotType;
}

-(void)dealloc
{
    [_propertyItem release];
    [_colors release];
    [super dealloc];
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager readFrame:(ReadFrame*)readFrame
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _readFrame = readFrame;
        
        self.colors = @[@0x996666,@0xFF3333,@0xFF00FF,@0x9966FF,@0x66CC33,@0x00CCFF,@0xFF9900,@0xFFFFFF,@0xC3C3C3,@0x000000];
        [self loadModule];
    }
    return self;
}

-(void)loadModule
{
    _readFrame.moreToolsBar.insertClicked = ^(){
        _annotType = e_annotCaret;
        [self annotItemClicked];
    };
    
    [_extensionsManager registerPropertyBarListener:self];
    
}


-(void)annotItemClicked
{
    [(SelectToolHandler*)[_extensionsManager getToolHandlerByName:Tool_Select] clearSelection];
    
    id<IToolHandler> toolHandler = [_extensionsManager getToolHandlerByName:Tool_Insert];
    [_extensionsManager setCurrentToolHandler:toolHandler];
    
    [_readFrame changeState:STATE_ANNOTTOOL];
    [_readFrame.toolSetBar removeAllItems];
    
    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_done"] imageSelected:[UIImage imageNamed:@"annot_done"] imageDisable:[UIImage imageNamed:@"annot_done"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    doneItem.tag = 0;
    [_readFrame.toolSetBar addItem:doneItem displayPosition:Position_CENTER];
    doneItem.onTapClick = ^(TbBaseItem*item){
        [_extensionsManager setCurrentToolHandler:nil];
        [_readFrame changeState:STATE_EDIT];
    };
    

    self.propertyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annotation_toolitembg"] imageSelected:[UIImage imageNamed:@"annotation_toolitembg"] imageDisable:[UIImage imageNamed:@"annotation_toolitembg"]];
    self.propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:e_annotCaret]];
    [_readFrame.toolSetBar addItem:self.propertyItem displayPosition:Position_CENTER];
    self.propertyItem.onTapClick = ^(TbBaseItem* item)
    {
        self.propertyIsShow = YES;
        if (DEVICE_iPHONE) {
            CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_pdfViewCtrl];
            [_extensionsManager showProperty:e_annotCaret rect:rect inView:_pdfViewCtrl];
        }
        else
        {
            [_extensionsManager showProperty:e_annotCaret rect:item.contentView.bounds inView:item.contentView];
        }
        
    };
    
    TbBaseItem *continueItem = nil;
    if (_readFrame.continueAddAnnot) {
        continueItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_continue"] imageSelected:[UIImage imageNamed:@"annot_continue"] imageDisable:[UIImage imageNamed:@"annot_continue"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    }
    else
    {
        continueItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_single"] imageSelected:[UIImage imageNamed:@"annot_single"] imageDisable:[UIImage imageNamed:@"annot_single"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    }
    continueItem.tag = 3;
    [_readFrame.toolSetBar addItem:continueItem displayPosition:Position_CENTER];
    continueItem.onTapClick = ^(TbBaseItem* item)
    {
        for (UIView *view in _pdfViewCtrl.subviews) {
            if (view.tag == 2112) {
                return;
            }
        }
        _readFrame.continueAddAnnot = !_readFrame.continueAddAnnot;
        if (_readFrame.continueAddAnnot) {
            item.imageNormal = [UIImage imageNamed:@"annot_continue"];
            item.imageSelected = [UIImage imageNamed:@"annot_continue"];
        }
        else
        {
            item.imageNormal = [UIImage imageNamed:@"annot_single"];
            item.imageSelected = [UIImage imageNamed:@"annot_single"];
        }
        
        [Utility showAnnotationContinue:_readFrame.continueAddAnnot pdfViewCtrl:_pdfViewCtrl siblingSubview:_readFrame.toolSetBar.contentView];
        [self performSelector:@selector(dismissAnnotationContinue) withObject:nil afterDelay:1];
    };
    
    TbBaseItem *iconItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"common_read_more"] imageSelected:[UIImage imageNamed:@"common_read_more"] imageDisable:[UIImage imageNamed:@"common_read_more"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    iconItem.tag = 6;
    [_readFrame.toolSetBar addItem:iconItem displayPosition:Position_CENTER];
    iconItem.onTapClick = ^(TbBaseItem* item)
    {
        _readFrame.hiddenMoreToolsBar = NO;
    };
    [Utility showAnnotationType:NSLocalizedString(@"kInsertText", nil) type:e_annotCaret pdfViewCtrl:_pdfViewCtrl  belowSubview:_readFrame.toolSetBar.contentView];
    
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

- (void)onPropertyBarDismiss
{
    self.propertyIsShow = NO;
}

-(void)dismissAnnotationContinue
{
    [Utility dismissAnnotationContinue:_extensionsManager.pdfViewCtrl];
}


#pragma mark - IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotCaret) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

@end
