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

#import "NoteModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "UIExtensionsSharedHeader.h"
#import "NoteToolHandler.h"
#import "NoteAnnotHandler.h"
#import "Utility+Demo.h"

@interface NoteModule () {
    FSPDFViewCtrl* __weak _pdfViewCtrl;
    UIExtensionsManager* __weak _extensionsManager;
    FSPDFReader* __weak _pdfReader;
}

@property (nonatomic, weak) TbBaseItem *propertyItem;

@end

@implementation NoteModule

-(NSString*)getName
{
    return @"Note";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager pdfReader:(FSPDFReader*)pdfReader
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _pdfReader = pdfReader;
        [self loadModule];
        [[NoteToolHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [[NoteAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
    }
    return self;
}

-(void)loadModule
{
    TbBaseItem *noteItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_note"] imageSelected:[UIImage imageNamed:@"annot_note"] imageDisable:[UIImage imageNamed:@"annot_note"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    noteItem.tag = DEVICE_iPHONE? EDIT_ITEM_NOTE :-EDIT_ITEM_NOTE;
    noteItem.onTapClick = ^(TbBaseItem* item)
    {
        if (_extensionsManager.currentAnnot) {
            [_extensionsManager setCurrentAnnot:nil];
        }
        [self annotItemClicked];
    };
    
    [_pdfReader.editBar addItem:noteItem displayPosition:DEVICE_iPHONE? Position_RB:Position_CENTER];
    
    _pdfReader.moreToolsBar.noteClicked = ^(){
        [self annotItemClicked];
    };
}

-(void)annotItemClicked
{
    [_extensionsManager setCurrentToolHandler: [_extensionsManager getToolHandlerByName:Tool_Note]];
    [_pdfReader changeState:STATE_ANNOTTOOL];
    
    [_pdfReader.toolSetBar removeAllItems];
    
    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_done"] imageSelected:[UIImage imageNamed:@"annot_done"] imageDisable:[UIImage imageNamed:@"annot_done"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    doneItem.tag = 0;
    [_pdfReader.toolSetBar addItem:doneItem displayPosition:Position_CENTER];
    doneItem.onTapClick = ^(TbBaseItem*item){
        [_extensionsManager setCurrentToolHandler:nil];
        [_pdfReader changeState:STATE_EDIT];
    };

    [_extensionsManager registerAnnotPropertyListener:self];
    TbBaseItem *propertyItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annotation_toolitembg"] imageSelected:[UIImage imageNamed:@"annotation_toolitembg"] imageDisable:[UIImage imageNamed:@"annotation_toolitembg"]];
    self.propertyItem = propertyItem;
    self.propertyItem.tag = 1;
    [self.propertyItem setInsideCircleColor:[_extensionsManager getPropertyBarSettingColor:e_annotNote]];
    [_pdfReader.toolSetBar addItem:self.propertyItem displayPosition:Position_CENTER];
    self.propertyItem.onTapClick = ^(TbBaseItem* item)
    {
        CGRect rect = [item.contentView convertRect:item.contentView.bounds toView:_pdfReader.pdfViewCtrl];
        if (DEVICE_iPHONE) {
            [_extensionsManager showProperty:e_annotNote rect:rect inView:_pdfReader.pdfViewCtrl];
        }
        else
        {
            [_extensionsManager showProperty:e_annotNote rect:item.contentView.bounds inView:item.contentView];
        }
        
    };
    
    TbBaseItem *continueItem = nil;
    if (_pdfReader.continueAddAnnot) {
        continueItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_continue"] imageSelected:[UIImage imageNamed:@"annot_continue"] imageDisable:[UIImage imageNamed:@"annot_continue"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    }
    else
    {
        continueItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_single"] imageSelected:[UIImage imageNamed:@"annot_single"] imageDisable:[UIImage imageNamed:@"annot_single"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
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
            item.imageNormal = [UIImage imageNamed:@"annot_continue"];
            item.imageSelected = [UIImage imageNamed:@"annot_continue"];
        }
        else
        {
            item.imageNormal = [UIImage imageNamed:@"annot_single"];
            item.imageSelected = [UIImage imageNamed:@"annot_single"];
        }
        
        [Utility showAnnotationContinue:_pdfReader.continueAddAnnot pdfViewCtrl:_pdfViewCtrl siblingSubview:_pdfReader.toolSetBar.contentView];
        [self performSelector:@selector(dismissAnnotationContinue) withObject:nil afterDelay:1];
    };
    
    TbBaseItem *iconItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"common_read_more"] imageSelected:[UIImage imageNamed:@"common_read_more"] imageDisable:[UIImage imageNamed:@"common_read_more"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    iconItem.tag = 6;
    [_pdfReader.toolSetBar addItem:iconItem displayPosition:Position_CENTER];
    iconItem.onTapClick = ^(TbBaseItem* item)
    {
        _pdfReader.hiddenMoreToolsBar = NO;
    };
    [Utility showAnnotationType:NSLocalizedStringFromTable(@"kNote", @"FoxitLocalizable", nil) type:e_annotNote pdfViewCtrl:_pdfViewCtrl belowSubview:_pdfReader.toolSetBar.contentView];
    
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
    [Utility dismissAnnotationContinue:_pdfReader.pdfViewCtrl];
}

#pragma mark - IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotNote) {
        [self.propertyItem setInsideCircleColor:color];
    }
}

@end
