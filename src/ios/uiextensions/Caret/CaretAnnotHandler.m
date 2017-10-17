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

#import "CaretAnnotHandler.h"
#import "ColorUtility.h"
#import "FSAnnotAttributes.h"
#import "FSUndo.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "PropertyBar.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "UIExtensionsManager.h"

#define FSPDF_ANNOT_INTENTNAME_CARET_REPLACE "Replace"
#define FSPDF_ANNOT_INTENTNAME_CARET_INSERTTEXT "Insert Text"

@interface CaretAnnotHandler ()
@property (nonatomic, strong) FSAnnot *editAnnot;
@property (nonatomic, strong) NSArray<FSAnnotAttributes *> *attributesArrayBeforeModify; // for undo
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;
@end

@implementation CaretAnnotHandler {
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
    UIExtensionsManager *_extensionsManager;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        [_pdfViewCtrl registerScrollViewEventListener:self];
        [_extensionsManager registerAnnotHandler:self];
        [_extensionsManager registerRotateChangedListener:self];
        [_extensionsManager registerGestureEventListener:self];
        [_extensionsManager.propertyBar registerPropertyBarListener:self];

        self.colors = @[ @0xFF9F40, @0x8080FF, @0xBAE94C, @0xFFF160, @0x996666, @0xFF4C4C, @0x669999, @0xFFFFFF, @0xC3C3C3, @0x000000 ];
        self.isShowStyle = NO;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        self.editAnnot = nil;
    }
    return self;
}

- (FSAnnotType)getType {
    return e_annotCaret;
}

- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point {
    FSCaret *caret = (FSCaret *) annot;
    int pageIndex = annot.pageIndex;
    CGPoint pt = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:pageIndex];
    if ([caret isGrouped]) {
        for (int i = 0; i < [caret getGroupElementCount]; i++) {
            FSAnnot *groupAnnot = [caret getGroupElement:i];
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:groupAnnot.fsrect pageIndex:pageIndex];
            rect = CGRectInset(rect, -10, -10);
            if (CGRectContainsPoint(rect, pt)) {
                return YES;
            }
        }
        return NO;
    } else {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:caret.fsrect pageIndex:pageIndex];
        rect = CGRectMake(rect.origin.x, rect.origin.y, 32, 32);
        rect = CGRectInset(rect, -10, -10);
        return CGRectContainsPoint(rect, pt);
    }
}

- (void)onAnnotSelected:(FSAnnot *)annot {
    self.editAnnot = annot;
    assert(annot.type == e_annotCaret);
    self.attributesArrayBeforeModify = [self createAnnotAttributes:(FSCaret *) annot];

    int pageIndex = annot.pageIndex;
    NSMutableArray *array = [NSMutableArray array];
    MenuItem *commentItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kOpen") object:self action:@selector(comment)];
    MenuItem *replyItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kReply") object:self action:@selector(reply)];
    if ([annot.intent isEqualToString:@"Replace"]) {
        if (annot.canModify) {
            MenuItem *styleReplaceItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kStyle") object:self action:@selector(showReplaceStyle)];
            [array addObject:styleReplaceItem];
            _isInsert = NO;
        }
    } else {
        if (annot.canModify) {
            MenuItem *styleInsertItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kStyle") object:self action:@selector(showInsertStyle)];
            [array addObject:styleInsertItem];
            _isInsert = YES;
        }
    }

    MenuItem *deleteItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kDelete") object:self action:@selector(deleteAnnot)];

    if (annot.canModify) {
        [array addObject:commentItem];
        [array addObject:replyItem];
        [array addObject:deleteItem];
    } else {
        [array addObject:commentItem];
        if (annot.canReply) {
            [array addObject:replyItem];
        }
    }
    CGRect caretRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:caretRect pageIndex:pageIndex];
    _extensionsManager.menuControl.menuItems = array;
    [_extensionsManager.menuControl setRect:dvRect];
    [_extensionsManager.menuControl showMenu];
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;

    CGRect pvRect = [self getPageViewRectForCaret:(FSMarkup *) annot pageIndex:pageIndex];
    [_pdfViewCtrl refresh:CGRectInset(pvRect, -30, -30) pageIndex:pageIndex needRender:NO];
}

- (void)copyText {
    FSAnnot *annot = _extensionsManager.currentAnnot;
    NSString *str = annot.contents;
    if (str && ![str isEqualToString:@""]) {
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        board.string = str;
    }
    [_extensionsManager setCurrentAnnot:nil];
}

- (void)comment {
    NSMutableArray *replyAnnots = [[NSMutableArray alloc] init];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
    self.currentVC = replyCtr;
    replyCtr.isNeedReply = NO;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:_extensionsManager.currentAnnot];
    [replyCtr setTableViewAnnotations:array];
    UINavigationController *navCtr = [[UINavigationController alloc] initWithRootViewController:replyCtr];
    navCtr.delegate = replyCtr;
    navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:navCtr animated:YES completion:nil];
    replyCtr.editingDoneHandler = ^() {
        [_extensionsManager setCurrentAnnot:nil];
    };
    replyCtr.editingCancelHandler = ^() {
        [_extensionsManager setCurrentAnnot:nil];
    };
}

- (void)reply {
    NSMutableArray *replyAnnots = [[NSMutableArray alloc] init];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
    self.currentVC = replyCtr;
    replyCtr.isNeedReply = YES;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:_extensionsManager.currentAnnot];
    [replyCtr setTableViewAnnotations:array];
    UINavigationController *navCtr = [[UINavigationController alloc] initWithRootViewController:replyCtr];

    navCtr.delegate = replyCtr;
    navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:navCtr animated:YES completion:nil];
    replyCtr.editingDoneHandler = ^() {
        [_extensionsManager setCurrentAnnot:nil];
    };
    replyCtr.editingCancelHandler = ^() {
        [_extensionsManager setCurrentAnnot:nil];
    };
}

- (void)deleteAnnot {
    FSAnnot *annot = _extensionsManager.currentAnnot;
    Task *task = [[Task alloc] init];
    task.run = ^() {
        [self removeAnnot:annot];
    };
    [_taskServer executeSync:task];
    [_extensionsManager setCurrentAnnot:nil];
}

- (void)showReplaceStyle {
    BOOL isContain = NO;
    UInt32 firstColor = [_extensionsManager getAnnotColor:e_annotCaret];
    for (NSNumber *value in self.colors) {
        if (firstColor == value.intValue) {
            isContain = YES;
            break;
        }
    }

    if (!isContain) {
        self.colors = @[ [NSNumber numberWithInt:firstColor], @0x8080FF, @0xBAE94C, @0xFFF160, @0x996666, @0xFF4C4C, @0x669999, @0xFFFFFF, @0xC3C3C3, @0x000000 ];
    }
    [_extensionsManager.propertyBar setColors:self.colors];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY frame:CGRectZero];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity * 100.0];
    [_extensionsManager.propertyBar addListener:_extensionsManager];
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
    NSArray *array = [NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]];
    [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:array];
    self.isShowStyle = YES;
    self.shouldShowMenu = NO;
    self.shouldShowPropety = YES;
}

- (void)showInsertStyle {
    BOOL isContain = NO;
    UInt32 firstColor = [_extensionsManager getAnnotColor:e_annotCaret];
    for (NSNumber *value in self.colors) {
        if (firstColor == value.intValue) {
            isContain = YES;
            break;
        }
    }

    if (!isContain) {
        self.colors = @[ [NSNumber numberWithInt:firstColor], @0x8080FF, @0xBAE94C, @0xFFF160, @0x996666, @0xFF4C4C, @0x669999, @0xFFFFFF, @0xC3C3C3, @0x000000 ];
    }
    [_extensionsManager.propertyBar setColors:self.colors];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY frame:CGRectZero];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity * 100.0];
    [_extensionsManager.propertyBar addListener:_extensionsManager];
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
    NSArray *array = [NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]];
    [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:array];
    self.isShowStyle = YES;
    self.shouldShowMenu = NO;
    self.shouldShowPropety = YES;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
}

- (CGRect)getPageViewRectForCaret:(FSMarkup *)caret pageIndex:(int)pageIndex {
    if ([caret isGrouped]) { //replace
        CGRect unionRect = CGRectZero;
        for (int i = 0; i < [caret getGroupElementCount]; i++) {
            FSAnnot *annot = [caret getGroupElement:i];
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            if (CGRectIsEmpty(unionRect))
                unionRect = rect;
            else
                unionRect = CGRectUnion(unionRect, rect);
        }
        return unionRect;
    } else {
        return [_pdfViewCtrl convertPdfRectToPageViewRect:caret.fsrect pageIndex:pageIndex];
    }
}

- (void)onAnnotDeselected:(FSAnnot *)annot {
    self.editAnnot = nil;
    assert(annot.type == e_annotCaret);
    if (![self.attributesArrayBeforeModify[0] isEqualToAttributes:[FSAnnotAttributes attributesWithAnnot:annot]]) {
        [self modifyAnnot:annot addUndo:YES];
    }
    self.attributesArrayBeforeModify = nil;

    if (_extensionsManager.menuControl.isMenuVisible) {
        [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
    }
    if (_extensionsManager.propertyBar.isShowing) {
        [_extensionsManager.propertyBar dismissPropertyBar];
        self.isShowStyle = NO;
    }
    self.shouldShowMenu = NO;
    self.shouldShowPropety = NO;
    self.annotImage = nil;

    int pageIndex = annot.pageIndex;
    CGRect unionRect = [self getPageViewRectForCaret:(FSMarkup *) annot pageIndex:pageIndex];

    unionRect = CGRectInset(unionRect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:unionRect pageIndex:pageIndex needRender:NO];
    });
}

- (void)addAnnot:(FSAnnot *)annot {
    [self addAnnot:annot addUndo:YES];
}

- (void)addAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    Task *task = [[Task alloc] init];
    task.run = ^() {
        int pageIndex = annot.pageIndex;
        FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
        if (addUndo) {
            FSCaretAttributes *attributes = [[FSCaretAttributes alloc] initWithAnnot:annot];
            if (![(FSMarkup *) annot isGrouped]) {
                [_extensionsManager addUndoItem:[UndoAddAnnot createWithAttributes:attributes page:page annotHandler:self]];
            } else {
                int groupCount = [(FSMarkup *) annot getGroupElementCount];
                NSMutableArray<FSAnnotAttributes *> *attributesArray = [NSMutableArray<FSAnnotAttributes *> arrayWithCapacity:groupCount];
                [attributesArray addObject:attributes];
                for (int i = 0; i < groupCount; i++) {
                    FSAnnot *groupAnnot = [(FSMarkup *) annot getGroupElement:i];
                    if (![groupAnnot.NM isEqualToString:attributes.NM]) {
                        [attributesArray addObject:[FSAnnotAttributes attributesWithAnnot:groupAnnot]];
                    }
                }
                [_extensionsManager addUndoItem:[UndoItem itemWithUndo:^(UndoItem *item) {
                                        FSAnnot *annot = [Utility getAnnotByNM:attributes.NM inPage:page];
                                        if (annot) {
                                            [self removeAnnot:annot addUndo:NO];
                                        }
                                    }
                                                    redo:^(UndoItem *item) {
                                                        NSMutableArray<FSMarkup *> *annotArray = [NSMutableArray<FSMarkup *> arrayWithCapacity:[attributesArray count]];
                                                        for (FSAnnotAttributes *attributes in attributesArray) {
                                                            FSAnnot *annot = [page addAnnot:attributes.type rect:attributes.rect];
                                                            if (annot) {
                                                                [attributes resetAnnot:annot];
                                                                [annotArray addObject:(FSMarkup *) annot];
                                                            }
                                                        }
                                                        [page setAnnotGroup:annotArray headerIndex:0];
                                                        for (FSAnnot *annot in annotArray) {
                                                            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
                                                            [annotHandler addAnnot:annot addUndo:NO];
                                                        }
                                                    }
                                                    pageIndex:pageIndex]];
            }
        }
        [_extensionsManager onAnnotAdded:page annot:annot];
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        rect = CGRectInset(rect, -30, -30);
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    };
    [_taskServer executeSync:task];
}

- (void)modifyAnnot:(FSAnnot *)annot {
    [self modifyAnnot:annot addUndo:YES];
}

- (NSArray<FSAnnotAttributes *> *)createAnnotAttributes:(FSCaret *)annot {
    NSMutableArray<FSAnnotAttributes *> *attributesArray = [NSMutableArray<FSAnnotAttributes *> array];
    [attributesArray addObject:[FSAnnotAttributes attributesWithAnnot:annot]];
    NSString *NM = annot.NM;
    for (int i = 0; i < [annot getGroupElementCount]; i++) {
        FSAnnot *groupAnnot = [(FSMarkup *) annot getGroupElement:i];
        if (![groupAnnot.NM isEqualToString:NM]) {
            [attributesArray addObject:[FSAnnotAttributes attributesWithAnnot:groupAnnot]];
        }
    }
    return attributesArray;
}

- (void)modifyAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    FSPDFPage *page = [annot getPage];
    if (!page) {
        return;
    }
    int pageIndex = annot.pageIndex;

    if ([annot canModify] && addUndo) {
        annot.modifiedDate = [NSDate date];

        if ([annot canModify] && addUndo) {
            annot.modifiedDate = [NSDate date];

            NSMutableArray<UndoItem *> *undoItemArray = [NSMutableArray<UndoItem *> array];
            NSUInteger count = self.attributesArrayBeforeModify.count;
            NSArray<FSAnnotAttributes *> *attributesArray = [self createAnnotAttributes:(FSCaret *) annot];
            assert(count == attributesArray.count);
            for (int i = 0; i < count; i++) {
                [undoItemArray addObject:[UndoModifyAnnot createWithOldAttributes:self.attributesArrayBeforeModify[i] newAttributes:attributesArray[i] pdfViewCtrl:_pdfViewCtrl page:page annotHandler:[_extensionsManager getAnnotHandlerByType:attributesArray[i].type]]];
            }
            [_extensionsManager addUndoItem:[UndoItem itemByMergingUndoItemInArray:undoItemArray]];
        }
    }

    [_extensionsManager onAnnotModified:page annot:annot];

    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    rect = CGRectInset(rect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

- (void)removeAnnot:(FSAnnot *)annot {
    [self removeAnnot:annot addUndo:YES];
}

- (void)removeAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    int pageIndex = annot.pageIndex;
    FSPDFPage *page = [annot getPage];
    if (page) {
        if (addUndo) {
            NSMutableArray<FSAnnotAttributes *> *attributesArray = self.attributesArrayBeforeModify ?: [self createAnnotAttributes:(FSCaret *) annot];
            if (![(FSMarkup *) annot isGrouped]) {
                FSAnnotAttributes *attributes = attributesArray[0];
                [_extensionsManager addUndoItem:[UndoDeleteAnnot createWithAttributes:attributes page:page annotHandler:self]];
            } else {
                [_extensionsManager addUndoItem:[UndoItem itemWithUndo:^(UndoItem *item) {
                                        NSMutableArray<FSMarkup *> *annotArray = [NSMutableArray<FSMarkup *> arrayWithCapacity:[attributesArray count]];
                                        for (FSAnnotAttributes *attributes in attributesArray) {
                                            FSAnnot *annot = [page addAnnot:attributes.type rect:attributes.rect];
                                            if (annot) {
                                                [attributes resetAnnot:annot];
                                                [annotArray addObject:(FSMarkup *) annot];
                                            }
                                        }
                                        [page setAnnotGroup:annotArray headerIndex:0];
                                        for (FSAnnot *annot in annotArray) {
                                            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
                                            [annotHandler addAnnot:annot addUndo:NO];
                                        }
                                    }
                                                    redo:^(UndoItem *item) {
                                                        FSAnnot *annot = [Utility getAnnotByNM:attributesArray[0].NM inPage:page];
                                                        if (annot) {
                                                            [self removeAnnot:annot addUndo:NO];
                                                        }
                                                    }
                                                    pageIndex:pageIndex]];
            } // isGrouped
        }     // addUndo
        self.attributesArrayBeforeModify = nil;

        [_extensionsManager onAnnotDeleted:page annot:annot];
        assert([annot isMarkup]);
        if ([(FSMarkup *) annot isGrouped]) {
            for (int i = 0; i < [(FSMarkup *) annot getGroupElementCount]; i++) {
                FSAnnot *groupAnnot = [(FSMarkup *) annot getGroupElement:i];
                if (groupAnnot && ![groupAnnot.NM isEqualToString:annot.NM]) {
                    [[_extensionsManager getAnnotHandlerByAnnot:groupAnnot] removeAnnot:groupAnnot addUndo:NO];
                }
            }
        }
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        rect = CGRectInset(rect, -30, -30);
        [page removeAnnot:annot];
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    } // page
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    if (_extensionsManager.currentAnnot == annot) {
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
            return YES;
        } else {
            [_extensionsManager setCurrentAnnot:nil];
            return YES;
        }
    } else {
        [_extensionsManager setCurrentAnnot:annot];
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    if (_extensionsManager.currentAnnot == annot) {
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
            return YES;
        } else {
            [_extensionsManager setCurrentAnnot:nil];
            return YES;
        }
    } else {
        [_extensionsManager setCurrentAnnot:annot];
        [self comment];
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot *)annot {
    if (annot.type == e_annotCaret) {
        BOOL canAddAnnot = [Utility canAddAnnotToDocument:_pdfViewCtrl.currentDoc];
        if (!canAddAnnot) {
            return NO;
        }
        CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
            return YES;
        }
        return NO;
    }
    return NO;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context annot:(FSAnnot *)annot {
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    FSAnnot *mkFsAnnot = nil;
    CGRect mkRect = CGRectZero;

    if ([(FSMarkup *) annot isGrouped]) {
        for (int i = 0; i < [(FSMarkup *) annot getGroupElementCount]; i++) {
            FSAnnot *groupAnnot = [(FSMarkup *) annot getGroupElement:i];
            if (groupAnnot.type == e_annotStrikeOut) {
                mkFsAnnot = groupAnnot;
                break;
            }
        }
        if (mkFsAnnot) {
            mkRect = [_pdfViewCtrl convertPdfRectToPageViewRect:mkFsAnnot.fsrect pageIndex:pageIndex];
        }
    } else {
        mkRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    }
    if (pageIndex == annot.pageIndex && _extensionsManager.currentAnnot == annot) {
        CGRect annotRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        annotRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:annotRect pageIndex:pageIndex];
        CGRect drawRect = CGRectMake(ceilf(rect.origin.x), ceilf(rect.origin.y), ceilf(annotRect.size.width), ceilf(annotRect.size.height));
        if (self.annotImage) {
            CGContextSaveGState(context);

            CGContextTranslateCTM(context, drawRect.origin.x, drawRect.origin.y);
            CGContextTranslateCTM(context, 0, drawRect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, -drawRect.origin.x, -drawRect.origin.y);
            CGContextDrawImage(context, drawRect, [self.annotImage CGImage]);

            CGContextRestoreGState(context);
        }
        drawRect = CGRectInset(drawRect, -2, -2);
        CGContextSetLineWidth(context, 2.0);
        CGFloat dashArray[] = {3, 3, 3, 3};
        CGContextSetLineDash(context, 3, dashArray, 4);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
        CGContextStrokeRect(context, drawRect);

        if (mkFsAnnot) {
            mkRect = CGRectInset(mkRect, -5, -5);
            CGContextSetLineWidth(context, 2.0);
            CGContextSetLineDash(context, 3, dashArray, 4);
            CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
            CGContextStrokeRect(context, mkRect);
        }
    }
}

#pragma mark IPropertyBarStateListener

- (void)onPropertyBarDismiss {
    if (DEVICE_iPHONE && _extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotCaret) {
        self.isShowStyle = NO;
        self.shouldShowPropety = NO;
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

#pragma mark IRotateChangedListener

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissAnnotMenu];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self showAnnotMenu];
}

#pragma mark IGestureEventListener

- (BOOL)onTap:(UITapGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onLongPress:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

- (void)onScrollViewWillBeginDragging:(UIScrollView *)dviewer {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)dviewer willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)dviewer {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)dviewer {
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)dviewer {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)dviewer {
    double delayInSeconds = .2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self showAnnotMenu];
    });
}

- (void)showAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotCaret) {
        int pageIndex = self.editAnnot.pageIndex;
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
        if (!DEVICE_iPHONE && self.shouldShowPropety) {
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        } else if (self.shouldShowMenu && !_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setRect:showRect];
            [_extensionsManager.menuControl showMenu];
        }
    }
}

- (void)dismissAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotCaret) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
        if (!DEVICE_iPHONE) {
            if (_extensionsManager.propertyBar.isShowing) {
                [_extensionsManager.propertyBar dismissPropertyBar];
            }
        }
    }
}

@end
