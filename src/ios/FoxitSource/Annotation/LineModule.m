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
#import "LineModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "UIExtensionsSharedHeader.h"
#import "../../uiextensions/Line/LineToolHandler.h"
#import "Utility+Demo.h"
#import "Defines.h"
@interface LineModule ()

@property (nonatomic, retain) TbBaseItem *propertyItem;

@end

@implementation LineModule
{
    FSPDFViewCtrl* _pdfViewCtrl;
    UIExtensionsManager* _extensionsManager;
    ReadFrame* _readFrame;
     enum FS_ANNOTTYPE _annotType;
    BOOL _isArrLine;
}

-(void)dealloc
{
    [_propertyItem release];
    [super dealloc];
}

#pragma mark init
- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager readFrame:(ReadFrame*)readFrame
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _readFrame = readFrame;
        [_extensionsManager registerPropertyBarListener:self];
        
        [self loadModule];
    }
    return self;
}

-(void)loadModule
{
    TbBaseItem *tyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_line"] imageSelected:[UIImage imageNamed:@"annot_line"] imageDisable:[UIImage imageNamed:@"annot_line"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    
        tyItem.onTapClick = ^(TbBaseItem* item)
    {
        _annotType = e_annotLine;
        [self annotItemClicked];
        _isArrLine = NO;
    };
    
    _readFrame.moreToolsBar.arrowsClicked = ^() {
        _annotType = e_annotLine;
       _isArrLine = YES;
        [self annotItemClicked];
    };
    _readFrame.moreToolsBar.lineClicked = ^(){
         _annotType = e_annotLine;
        _isArrLine = NO;
        [self annotItemClicked];
    };
}

-(void)annotItemClicked
{
    [_readFrame changeState:STATE_ANNOTTOOL];
     if (_isArrLine) {
        LineToolHandler* toolHandler = [_extensionsManager getToolHandlerByName:Tool_Line];
        toolHandler.isArrowLine = YES;
        toolHandler.type = _annotType;
         [_extensionsManager setCurrentToolHandler:toolHandler];
    }
    else
    {
        LineToolHandler* toolHandler = [_extensionsManager getToolHandlerByName:Tool_Line];
        toolHandler.type = _annotType;
        toolHandler.isArrowLine = NO;
        [_extensionsManager setCurrentToolHandler:toolHandler];
    }
    [_readFrame.toolSetBar removeAllItems];
    
    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_done"] imageSelected:[UIImage imageNamed:@"annot_done"] imageDisable:[UIImage imageNamed:@"annot_done"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    doneItem.tag = 0;
    [_readFrame.toolSetBar addItem:doneItem displayPosition:Position_CENTER];

    doneItem.onTapClick = ^(TbBaseItem*item){
        [_extensionsManager setCurrentToolHandler:nil];
        [_readFrame changeState:STATE_EDIT];
    };
    [_extensionsManager registerPropertyBarListener:self];
    self.propertyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annotation_toolitembg"] imageSelected:[UIImage imageNamed:@"annotation_toolitembg"] imageDisable:[UIImage imageNamed:@"annotation_toolitembg"]];
    self.propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:e_annotLine]];
    [_readFrame.toolSetBar addItem:_propertyItem displayPosition:Position_CENTER];
    self.propertyItem.onTapClick = ^(TbBaseItem* item)
    {
        CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_readFrame.pdfViewCtrl];
        if (DEVICE_iPHONE) {
            [_extensionsManager showProperty:_annotType rect:rect inView:_readFrame.pdfViewCtrl];
        }
        else
        {
            [_extensionsManager showProperty:_annotType rect:item.contentView.bounds inView:item.contentView];
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
    if (!_isArrLine) {
        [Utility showAnnotationType:NSLocalizedString(@"kLine", nil) type:e_annotLine pdfViewCtrl:_readFrame.pdfViewCtrl belowSubview:_readFrame.toolSetBar.contentView];
    }
    else if (_isArrLine)
    {
        [Utility showAnnotationType:NSLocalizedString(@"kArrowLine", nil) type:e_annotLine pdfViewCtrl:_readFrame.pdfViewCtrl belowSubview:_readFrame.toolSetBar.contentView];
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

-(void)dismissAnnotationContinue
{
    [Utility dismissAnnotationContinue:_readFrame.pdfViewCtrl];
}

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == _annotType) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

@end
