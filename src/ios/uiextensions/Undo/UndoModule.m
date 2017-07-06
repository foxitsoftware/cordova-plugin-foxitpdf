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

#import "UndoModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface UndoModule ()

@property (nonatomic, strong) TbBaseItem *undoItem;
@property (nonatomic, strong) TbBaseItem *redoItem;

@end

@implementation UndoModule {
    FSPDFViewCtrl* __weak _pdfViewCtrl;
    UIExtensionsManager* __weak _extensionsManager;
    FSPDFReader* __weak _pdfReader;
}

- (id)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager pdfReader:(FSPDFReader*)pdfReader
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        [_extensionsManager registerUndoEventListener:self];
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _pdfReader = pdfReader;
        [self loadModule];
    }
    return self;
}

-(void)loadModule
{
    self.undoItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_undo"] imageSelected:[UIImage imageNamed:@"annot_undo"] imageDisable:[UIImage imageNamed:@"annot_undo"]background:[UIImage imageNamed:@"annotation_toolitembg"]];
    self.undoItem.tag = 3;
    self.undoItem.onTapClick = ^(TbBaseItem* item)
    {
        [self unDoRedoButtonClick:@"undo" afterDelay:0.2f];
    };
    
    [_pdfReader.editDoneBar addItem:self.undoItem displayPosition:Position_LT];
    
    self.redoItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_redo"] imageSelected:[UIImage imageNamed:@"annot_redo"] imageDisable:[UIImage imageNamed:@"annot_redo"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    self.redoItem.tag = 4;
    self.redoItem.onTapClick = ^(TbBaseItem* item)
    {
        [self unDoRedoButtonClick:@"redo" afterDelay:0.2f];
    };
    
    [_pdfReader.editDoneBar addItem:self.redoItem displayPosition:Position_LT];

    CGRect undoFrame = self.undoItem.contentView.frame;
    CGRect redoFrame = self.redoItem.contentView.frame;
    
    undoFrame.origin.y -= 2;
    redoFrame.origin.y -= 2;
    
    self.undoItem.contentView.frame = undoFrame;
    self.redoItem.contentView.frame = redoFrame;
    
    self.undoItem.enable = NO;
    self.redoItem.enable = NO;
}

#pragma mark Package button click event
-(void)unDoRedoButtonClick:(NSString *)type afterDelay:(float)delayTime
{
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(execUndoRedo:) object:type];
    
    [self performSelector:@selector(execUndoRedo:) withObject:type afterDelay:delayTime];
}

#pragma mark execute undo/redo
-(void)execUndoRedo:(NSString *)type{
    __weak typeof(_extensionsManager) weakExtMgr = _extensionsManager;
    
    if ([type isEqualToString:@"undo"]) {
        if ([weakExtMgr canUndo]) {
            [weakExtMgr undo];
        }
    } else {
        if ([weakExtMgr canRedo]) {
            [weakExtMgr redo];
        }
    }
}

#pragma mark IFSUndoEventListener

-(void)onUndoChanged
{
    if ([_extensionsManager canUndo])
    {
        self.undoItem.enable = YES;
    }
    else
    {
        self.undoItem.enable = NO;
    }
    
    if ([_extensionsManager canRedo])
    {
        self.redoItem.enable = YES;
    }
    else
    {
        self.redoItem.enable = NO;
    }
}

@end

