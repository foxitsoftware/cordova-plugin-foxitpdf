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

#import "UndoModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface UndoModule ()

@property (nonatomic, strong) TbBaseItem *undoItem;
@property (nonatomic, strong) TbBaseItem *redoItem;

@end

@implementation UndoModule {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
}

- (id)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        [_extensionsManager registerUndoEventListener:self];
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [self loadModule];
    }
    return self;
}

- (void)loadModule {
    self.undoItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_undo"] imageSelected:[UIImage imageNamed:@"annot_undo"] imageDisable:[UIImage imageNamed:@"annot_undo"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    //    self.undoItem.tag = 3;
    __weak typeof(_extensionsManager) weakExtMgr = _extensionsManager;
    self.undoItem.onTapClick = ^(TbBaseItem *item) {
        item.enable = false;
        if ([weakExtMgr canUndo]) {
            [weakExtMgr undo];
        }
        item.enable = [weakExtMgr canUndo];
    };

    [_extensionsManager.editDoneBar addItem:self.undoItem displayPosition:Position_LT];

    self.redoItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annot_redo"] imageSelected:[UIImage imageNamed:@"annot_redo"] imageDisable:[UIImage imageNamed:@"annot_redo"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    //    self.redoItem.tag = 4;
    self.redoItem.onTapClick = ^(TbBaseItem *item) {
        item.enable = false;
        if ([weakExtMgr canRedo]) {
            [weakExtMgr redo];
        }
        item.enable = [weakExtMgr canRedo];
    };

    [_extensionsManager.editDoneBar addItem:self.redoItem displayPosition:Position_LT];

    CGRect undoFrame = self.undoItem.contentView.frame;
    CGRect redoFrame = self.redoItem.contentView.frame;

    undoFrame.origin.y -= 2;
    redoFrame.origin.y -= 2;

    self.undoItem.contentView.frame = undoFrame;
    self.redoItem.contentView.frame = redoFrame;

    self.undoItem.enable = NO;
    self.redoItem.enable = NO;
}

#pragma mark IFSUndoEventListener

- (void)onUndoChanged {
    if ([_extensionsManager canUndo]) {
        self.undoItem.enable = YES;
    } else {
        self.undoItem.enable = NO;
    }

    if ([_extensionsManager canRedo]) {
        self.redoItem.enable = YES;
    } else {
        self.redoItem.enable = NO;
    }
}

@end
