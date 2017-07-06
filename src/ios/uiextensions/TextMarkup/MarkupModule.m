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

#import "MarkupModule.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import "UIExtensionsSharedHeader.h"
#import "Utility+Demo.h"
#import "TextMKToolHandler.h"
#import "TextMKAnnotHandler.h"

@interface MarkupModule () {
    FSPDFViewCtrl* __weak _pdfViewCtrl;
    UIExtensionsManager* __weak _extensionsManager;
    FSPDFReader* __weak _pdfReader;
    enum FS_ANNOTTYPE _annotType;
}

@property (nonatomic, weak) TbBaseItem *propertyItem;
@end

@implementation MarkupModule


-(NSString*)getName
{
    return @"Markup";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager pdfReader:(FSPDFReader*)pdfReader
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _pdfReader = pdfReader;
        [self loadModule];
        [[MKToolHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [[MKAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
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
    
    [_pdfReader.editBar addItem:hightItem displayPosition:DEVICE_iPHONE?Position_RB:Position_CENTER];
 
    itemImg = [UIImage imageNamed:@"annot_underline"];
    TbBaseItem *underlineItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    underlineItem.tag = DEVICE_iPHONE ? EDIT_ITEM_UNDERLINE:-EDIT_ITEM_UNDERLINE;
    underlineItem.onTapClick = ^(TbBaseItem* item)
    {
        _annotType = e_annotUnderline;
        [self annotItemClicked];
    };
    
    if (!DEVICE_iPHONE) {
        [_pdfReader.editBar addItem:underlineItem displayPosition:Position_CENTER];
    }
    
    itemImg = [UIImage imageNamed:@"annot_strokeout"];
    TbBaseItem *stItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    stItem.tag = DEVICE_iPHONE?EDIT_ITEM_STROKEOUT:-EDIT_ITEM_STROKEOUT;
    stItem.onTapClick = ^(TbBaseItem* item)
    {
        _annotType = e_annotStrikeOut;
        [self annotItemClicked];
    };
    
    [_pdfReader.editBar addItem:stItem displayPosition:DEVICE_iPHONE?Position_RB:Position_CENTER];
    
    _pdfReader.moreToolsBar.highLightClicked = ^(){
        _annotType = e_annotHighlight;
        [self annotItemClicked];
    };
    _pdfReader.moreToolsBar.strikeOutClicked = ^(){
        _annotType = e_annotStrikeOut;
        [self annotItemClicked];
    };
    
    _pdfReader.moreToolsBar.underLineClicked = ^(){
        _annotType = e_annotUnderline;
        [self annotItemClicked];
    };
    
    _pdfReader.moreToolsBar.breakLineClicked = ^(){
        _annotType = e_annotSquiggly;
        [self annotItemClicked];
    };
}

-(void)annotItemClicked
{
    [_pdfReader changeState:STATE_ANNOTTOOL];
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
    
    [_pdfReader.toolSetBar removeAllItems];
    
    UIImage *itemImg = [UIImage imageNamed:@"annot_done"];
    UIImage *backgrdImg = [UIImage imageNamed:@"annotation_toolitembg"];
    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    doneItem.tag = 0;
    [_pdfReader.toolSetBar addItem:doneItem displayPosition:Position_CENTER];
    doneItem.onTapClick = ^(TbBaseItem*item){
        [_extensionsManager setCurrentToolHandler:nil];
        [_pdfReader changeState:STATE_EDIT];
    };

    [_extensionsManager registerAnnotPropertyListener:self];
    TbBaseItem *propertyItem = [TbBaseItem createItemWithImage:backgrdImg imageSelected:backgrdImg imageDisable:backgrdImg];
    self.propertyItem = propertyItem;
    self.propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:_annotType]];
    [_pdfReader.toolSetBar addItem:self.propertyItem displayPosition:Position_CENTER];
    self.propertyItem.onTapClick = ^(TbBaseItem* item)
    {
        if (DEVICE_iPHONE) {
            CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_pdfReader.pdfViewCtrl];
            [_extensionsManager showProperty:_annotType rect:rect inView:_pdfReader.pdfViewCtrl];
        }
        else
        {
            [_extensionsManager showProperty:_annotType rect:item.contentView.bounds inView:item.contentView];
        }
    };
    
    TbBaseItem *continueItem = nil;
    if (_pdfReader.continueAddAnnot) {
        itemImg = [UIImage imageNamed:@"annot_continue"];
        continueItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    }
    else
    {
        itemImg = [UIImage imageNamed:@"annot_single"];
        continueItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    }
    continueItem.tag = 3;
    [_pdfReader.toolSetBar addItem:continueItem displayPosition:Position_CENTER];
    continueItem.onTapClick = ^(TbBaseItem* item)
    {
        for (UIView *view in _pdfReader.pdfViewCtrl.subviews) {
            if (view.tag == 2112) {
                return;
            }
        }
        _pdfReader.continueAddAnnot = !_pdfReader.continueAddAnnot;
        if (_pdfReader.continueAddAnnot) {
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
        
        [Utility showAnnotationContinue:_pdfReader.continueAddAnnot pdfViewCtrl:_pdfViewCtrl siblingSubview:_pdfReader.toolSetBar.contentView];
        [self performSelector:@selector(dismissAnnotationContinue) withObject:nil afterDelay:1];
    };

    itemImg = [UIImage imageNamed:@"common_read_more"];
    TbBaseItem *iconItem = [TbBaseItem createItemWithImage:itemImg imageSelected:itemImg imageDisable:itemImg background:backgrdImg];
    iconItem.tag = 4;
    [_pdfReader.toolSetBar addItem:iconItem displayPosition:Position_CENTER];
    iconItem.onTapClick = ^(TbBaseItem* item)
    {
        _pdfReader.hiddenMoreToolsBar = NO;
    };
    
    if (_annotType == e_annotHighlight) {
        [Utility showAnnotationType:NSLocalizedStringFromTable(@"kHighlight", @"FoxitLocalizable", nil) type:e_annotHighlight pdfViewCtrl:_pdfViewCtrl  belowSubview:_pdfReader.toolSetBar.contentView];
    }
    else if (_annotType == e_annotSquiggly)
    {
        [Utility showAnnotationType:NSLocalizedStringFromTable(@"kSquiggly", @"FoxitLocalizable", nil) type:e_annotSquiggly pdfViewCtrl:_pdfViewCtrl  belowSubview:_pdfReader.toolSetBar.contentView];
    }
    else if (_annotType == e_annotStrikeOut)
    {
        [Utility showAnnotationType:NSLocalizedStringFromTable(@"kStrikeout", @"FoxitLocalizable", nil) type:e_annotStrikeOut pdfViewCtrl:_pdfViewCtrl  belowSubview:_pdfReader.toolSetBar.contentView];
    }
    else if (_annotType == e_annotUnderline)
    {
        [Utility showAnnotationType:NSLocalizedStringFromTable(@"kUnderline", @"FoxitLocalizable", nil) type:e_annotUnderline pdfViewCtrl:_pdfViewCtrl  belowSubview:_pdfReader.toolSetBar.contentView];
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
    [Utility dismissAnnotationContinue:_pdfViewCtrl];
}

#pragma mark - IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == _annotType) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

@end
