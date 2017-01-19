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
#import "MarkupModule.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import "UIExtensionsSharedHeader.h"
#import "Utility+Demo.h"
#import "Defines.h"

@interface MarkupModule () {
    FSPDFViewCtrl* _pdfViewCtrl;
    UIExtensionsManager* _extensionsManager;
    ReadFrame* _readFrame;
    enum FS_ANNOTTYPE _annotType;
}

@property (nonatomic, retain) TbBaseItem *propertyItem;
@end

@implementation MarkupModule

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
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _readFrame = readFrame;
        [self loadModule];
    }
    return self;
}

-(void)loadModule
{
    UIImage *itemImg = [UIImage imageNamed:@"annot_hight"];
    UIImage *backgrdImg = [UIImage imageNamed:@"annotation_toolitembg"];
    TbBaseItem *hightItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    hightItem.tag = DEVICE_iPHONE ? EDIT_ITEM_HIGHLIGHT:-EDIT_ITEM_HIGHLIGHT;
    hightItem.onTapClick = ^(TbBaseItem* item)
    {
        _annotType = e_annotHighlight;
        [self annotItemClicked];
    };
    
    [_readFrame.editBar addItem:hightItem displayPosition:DEVICE_iPHONE?Position_RB:Position_CENTER];
 
    itemImg = [UIImage imageNamed:@"annot_underline"];
    TbBaseItem *underlineItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    underlineItem.tag = DEVICE_iPHONE ? EDIT_ITEM_UNDERLINE:-EDIT_ITEM_UNDERLINE;
    underlineItem.onTapClick = ^(TbBaseItem* item)
    {
        _annotType = e_annotUnderline;
        [self annotItemClicked];
    };
    
    if (!DEVICE_iPHONE) {
        [_readFrame.editBar addItem:underlineItem displayPosition:Position_CENTER];
    }
    
    itemImg = [UIImage imageNamed:@"annot_strokeout"];
    TbBaseItem *stItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    stItem.tag = DEVICE_iPHONE?EDIT_ITEM_STROKEOUT:-EDIT_ITEM_STROKEOUT;
    stItem.onTapClick = ^(TbBaseItem* item)
    {
        _annotType = e_annotStrikeOut;
        [self annotItemClicked];
    };
    
    [_readFrame.editBar addItem:stItem displayPosition:DEVICE_iPHONE?Position_RB:Position_CENTER];
    
    _readFrame.moreToolsBar.highLightClicked = ^(){
        _annotType = e_annotHighlight;
        [self annotItemClicked];
    };
    _readFrame.moreToolsBar.strikeOutClicked = ^(){
        _annotType = e_annotStrikeOut;
        [self annotItemClicked];
    };
    
    _readFrame.moreToolsBar.underLineClicked = ^(){
        _annotType = e_annotUnderline;
        [self annotItemClicked];
    };
    
    _readFrame.moreToolsBar.breakLineClicked = ^(){
        _annotType = e_annotSquiggly;
        [self annotItemClicked];
    };
}

-(void)annotItemClicked
{
    [_readFrame changeState:STATE_ANNOTTOOL];
    id<IToolHandler> toolHandler = [_extensionsManager getToolHandlerByName:Tool_Markup];
    switch (_annotType) {
        case e_annotHighlight:
        case e_annotSquiggly:
        case e_annotStrikeOut:
        case e_annotUnderline:
            toolHandler.type = _annotType;
            [_extensionsManager setCurrentToolHandler:toolHandler];
            break;
        
        default:
            break;
    }
    
    [_readFrame.toolSetBar removeAllItems];
    
    UIImage *itemImg = [UIImage imageNamed:@"annot_done"];
    UIImage *backgrdImg = [UIImage imageNamed:@"annotation_toolitembg"];
    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    doneItem.tag = 0;
    [_readFrame.toolSetBar addItem:doneItem displayPosition:Position_CENTER];
    doneItem.onTapClick = ^(TbBaseItem*item){
        [_extensionsManager setCurrentToolHandler:nil];
        [_readFrame changeState:STATE_EDIT];
    };

    [_extensionsManager registerPropertyBarListener:self];
    self.propertyItem = [TbBaseItem createItemWithImage:backgrdImg imageSelected:backgrdImg imageDisable:backgrdImg];
    _propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:_annotType]];
    [_readFrame.toolSetBar addItem:_propertyItem displayPosition:Position_CENTER];
    _propertyItem.onTapClick = ^(TbBaseItem* item)
    {
        if (DEVICE_iPHONE) {
            CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_readFrame.pdfViewCtrl];
            [_extensionsManager showProperty:_annotType rect:rect inView:_readFrame.pdfViewCtrl];
        }
        else
        {
            [_extensionsManager showProperty:_annotType rect:item.contentView.bounds inView:item.contentView];
        }
    };
    
    TbBaseItem *continueItem = nil;
    if (_readFrame.continueAddAnnot) {
        itemImg = [UIImage imageNamed:@"annot_continue"];
        continueItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    }
    else
    {
        itemImg = [UIImage imageNamed:@"annot_single"];
        continueItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    }
    continueItem.tag = 3;
    [_readFrame.toolSetBar addItem:continueItem displayPosition:Position_CENTER];
    continueItem.onTapClick = ^(TbBaseItem* item)
    {
        for (UIView *view in _readFrame.pdfViewCtrl.subviews) {
            if (view.tag == 2112) {
                return;
            }
        }
        _readFrame.continueAddAnnot = !_readFrame.continueAddAnnot;
        if (_readFrame.continueAddAnnot) {
            UIImage* itemImg = [UIImage imageNamed:@"annot_continue"];
            item.imageNormal = itemImg;
            item.imageSelected = itemImg;
        }
        else
        {
            UIImage* itemImg = [UIImage imageNamed:@"annot_single"];
            item.imageNormal = itemImg;
            item.imageSelected = itemImg;
        }
        
        [Utility showAnnotationContinue:_readFrame.continueAddAnnot pdfViewCtrl:_pdfViewCtrl siblingSubview:_readFrame.toolSetBar.contentView];
        [self performSelector:@selector(dismissAnnotationContinue) withObject:nil afterDelay:1];
    };

    itemImg = [UIImage imageNamed:@"common_read_more"];
    TbBaseItem *iconItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    iconItem.tag = 4;
    [_readFrame.toolSetBar addItem:iconItem displayPosition:Position_CENTER];
    iconItem.onTapClick = ^(TbBaseItem* item)
    {
        _readFrame.hiddenMoreToolsBar = NO;
    };
    
    if (_annotType == e_annotHighlight) {
        [Utility showAnnotationType:NSLocalizedString(@"kHighlight", nil) type:e_annotHighlight pdfViewCtrl:_pdfViewCtrl  belowSubview:_readFrame.toolSetBar.contentView];
    }
    else if (_annotType == e_annotSquiggly)
    {
        [Utility showAnnotationType:NSLocalizedString(@"kSquiggly", nil) type:e_annotSquiggly pdfViewCtrl:_pdfViewCtrl  belowSubview:_readFrame.toolSetBar.contentView];
    }
    else if (_annotType == e_annotStrikeOut)
    {
        [Utility showAnnotationType:NSLocalizedString(@"kStrikeout", nil) type:e_annotStrikeOut pdfViewCtrl:_pdfViewCtrl  belowSubview:_readFrame.toolSetBar.contentView];
    }
    else if (_annotType == e_annotUnderline)
    {
        [Utility showAnnotationType:NSLocalizedString(@"kUnderline", nil) type:e_annotUnderline pdfViewCtrl:_pdfViewCtrl  belowSubview:_readFrame.toolSetBar.contentView];
    }
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
    if (_annotType == e_annotHighlight ||
        _annotType == e_annotSquiggly ||
        _annotType == e_annotStrikeOut ||
        _annotType == e_annotUnderline) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

@end
