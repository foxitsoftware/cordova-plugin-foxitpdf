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
#import "FreetextModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "UIExtensionsSharedHeader.h"
#import "Utility+Demo.h"
#import "Defines.h"

@interface FreetextModule ()

@property (nonatomic, retain) TbBaseItem *propertyItem;

@end

@implementation FreetextModule {
    UIExtensionsManager* _extensionsManager;
    ReadFrame* _readFrame;
}

-(void)dealloc
{
    [_propertyItem release];
    [super dealloc];
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager readFrame:(ReadFrame*)readFrame
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _readFrame = readFrame;
        [_extensionsManager registerPropertyBarListener:self];
        
        [self loadModule];
    }
    return self;
}

-(void)loadModule
{
    TbBaseItem *tyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_typewriter"] imageSelected:[UIImage imageNamed:@"annot_typewriter"] imageDisable:[UIImage imageNamed:@"annot_typewriter"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    tyItem.tag = DEVICE_iPHONE?EDIT_ITEM_FREETEXT:-EDIT_ITEM_FREETEXT;
    tyItem.onTapClick = ^(TbBaseItem* item)
    {
        [self annotItemClicked];
    };
    
    [_readFrame.editBar addItem:tyItem displayPosition:DEVICE_iPHONE?Position_RB:Position_CENTER];
    
    _readFrame.moreToolsBar.typerwriterClicked = ^(){
        [self annotItemClicked];
    };
}

-(void)annotItemClicked
{
    [_readFrame changeState:STATE_ANNOTTOOL];
    [_extensionsManager setCurrentToolHandler:[_extensionsManager getToolHandlerByName:Tool_Freetext]];
    [_readFrame.toolSetBar removeAllItems];
    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_done"] imageSelected:[UIImage imageNamed:@"annot_done"] imageDisable:[UIImage imageNamed:@"annot_done"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    doneItem.tag = 0;
    [_readFrame.toolSetBar addItem:doneItem displayPosition:Position_CENTER];
    doneItem.onTapClick = ^(TbBaseItem*item){
        [_extensionsManager setCurrentToolHandler:nil];
        [_readFrame changeState:STATE_EDIT];
    };
    
    self.propertyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annotation_toolitembg"] imageSelected:[UIImage imageNamed:@"annotation_toolitembg"] imageDisable:[UIImage imageNamed:@"annotation_toolitembg"]];
    _propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:e_annotFreeText]];
    [_readFrame.toolSetBar addItem:_propertyItem displayPosition:Position_CENTER];
    _propertyItem.onTapClick = ^(TbBaseItem* item)
    {
        CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_extensionsManager.pdfViewCtrl];
        
        if (DEVICE_iPHONE) {
            [_extensionsManager showProperty:e_annotFreeText rect:rect inView:_extensionsManager.pdfViewCtrl];
        }
        else
        {
            [_extensionsManager showProperty:e_annotFreeText rect:item.contentView.bounds inView:item.contentView];
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
        for (UIView *view in _extensionsManager.pdfViewCtrl.subviews) {
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
        
        [Utility showAnnotationContinue:_readFrame.continueAddAnnot pdfViewCtrl:_extensionsManager.pdfViewCtrl siblingSubview:_readFrame.toolSetBar.contentView];
        [self performSelector:@selector(dismissAnnotationContinue) withObject:nil afterDelay:1];
    };
    
    TbBaseItem *iconItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"common_read_more"] imageSelected:[UIImage imageNamed:@"common_read_more"] imageDisable:[UIImage imageNamed:@"common_read_more"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    iconItem.tag = 4;
    [_readFrame.toolSetBar addItem:iconItem displayPosition:Position_CENTER];
    iconItem.onTapClick = ^(TbBaseItem* item)
    {
        _readFrame.hiddenMoreToolsBar = NO;
    };
    [Utility showAnnotationType:NSLocalizedString(@"kTypewriter", nil) type:e_annotFreeText pdfViewCtrl:_extensionsManager.pdfViewCtrl belowSubview:_readFrame.toolSetBar.contentView];
    
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

-(void)dismissAnnotationContinue
{
    [Utility dismissAnnotationContinue:_readFrame.pdfViewCtrl];
}

#pragma mark - IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotFreeText) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

@end
