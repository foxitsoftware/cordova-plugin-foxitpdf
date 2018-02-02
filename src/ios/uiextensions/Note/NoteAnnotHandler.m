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

#import "NoteAnnotHandler.h"
#import "ColorUtility.h"
#import "FSAnnotAttributes.h"
#import "FSUndo.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "NoteDialog.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface NoteAnnotHandler () <IDocEventListener, IAnnotPropertyListener, UIPopoverControllerDelegate, IPropertyBarListener, IRotationEventListener, IScrollViewEventListener, IGestureEventListener>

@property (nonatomic, strong) FSAnnot *editAnnot;
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;
@property (nonatomic, strong) FSAnnotAttributes *attributesBeforeModify; // for undo
@property (nonatomic, strong) UIImage *annotImage;

@end

@implementation NoteAnnotHandler {
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
    UIExtensionsManager *_extensionsManager;

    CGRect _lastPanRect;

    BOOL _isZooming;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;

        _taskServer = _extensionsManager.taskServer;
        self.colors = @[ @0xFF9F40, @0x8080FF, @0xBAE94C, @0xFFF160, @0xC3C3C3, @0xFF4C4C, @0x669999, @0xC72DA1, @0x996666, @0x000000 ];
        self.isShowStyle = NO;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        self.editAnnot = nil;

        _lastPanRect = CGRectZero;
        _isZooming = NO;
    }
    return self;
}

- (FSAnnotType)getType {
    return e_annotNote;
}

- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point {
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    pvRect = CGRectMake(pvRect.origin.x, pvRect.origin.y, 32, 32);
    pvRect = CGRectInset(pvRect, -20, -20);
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:annot.pageIndex];
    return CGRectContainsPoint(pvRect, pvPoint);
}

- (void)onAnnotSelected:(FSAnnot *)annot {
    self.editAnnot = annot;
    self.attributesBeforeModify = [FSAnnotAttributes attributesWithAnnot:annot];

    CGRect pvRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];

    NSMutableArray *array = [NSMutableArray array];

    MenuItem *commentItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kOpen") object:self action:@selector(comment)];
    MenuItem *replyItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kReply") object:self action:@selector(reply)];
    MenuItem *styleItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kStyle") object:self action:@selector(showStyle)];
    MenuItem *deleteItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kDelete") object:self action:@selector(deleteAnnot)];

    if (annot.canModify) {
        [array addObject:styleItem];
        [array addObject:commentItem];
        [array addObject:replyItem];
        [array addObject:deleteItem];
    } else {
        [array addObject:commentItem];
        if (annot.canReply) {
            [array addObject:replyItem];
        }
    }

    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:annot.pageIndex];
    MenuControl *annotMenu = _extensionsManager.menuControl;
    annotMenu.menuItems = array;
    [annotMenu setRect:dvRect];
    [annotMenu showMenu];
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;

    self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
    [_pdfViewCtrl refresh:CGRectInset(pvRect, -30, -30) pageIndex:annot.pageIndex needRender:YES];
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
        ;
    };
    replyCtr.editingCancelHandler = ^() {
        [_extensionsManager setCurrentAnnot:nil];
        ;
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

- (void)showStyle {
    [_extensionsManager.propertyBar setColors:self.colors];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_ICONTYPE frame:CGRectZero];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity * 100.0];
    [_extensionsManager.propertyBar setProperty:PROPERTY_ICONTYPE intValue:annot.icon];
    [_extensionsManager.propertyBar addListener:_extensionsManager];
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:annot.pageIndex];
    [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
    self.isShowStyle = YES;
    self.shouldShowMenu = NO;
    self.shouldShowPropety = YES;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
}

- (void)onAnnotDeselected:(FSAnnot *)annot {
    self.editAnnot = nil;
    if (self.attributesBeforeModify && ![self.attributesBeforeModify isEqualToAttributes:[FSAnnotAttributes attributesWithAnnot:annot]]) {
        [self modifyAnnot:annot addUndo:YES];
    }
    self.attributesBeforeModify = nil;

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

    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    newRect = CGRectInset(newRect, -30, -30);
    [_pdfViewCtrl refresh:newRect pageIndex:annot.pageIndex needRender:YES];
}

- (void)addAnnot:(FSAnnot *)annot {
    [self addAnnot:annot addUndo:YES];
}

- (void)addAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    Task *task = [[Task alloc] init];
    task.run = ^() {
        [self _addAnnot:(FSNote *) annot addUndo:addUndo];

        CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        rect = CGRectInset(rect, -30, -30);
        int pageIndex = annot.pageIndex;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
        });
    };
    [_taskServer executeSync:task];
}

- (void)modifyAnnot:(FSAnnot *)annot {
    [self modifyAnnot:annot addUndo:YES];
}

- (void)modifyAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    FSPDFPage *page = [annot getPage];
    if (!page) {
        return;
    }

    if ([annot canModify] && addUndo) {
        annot.modifiedDate = [NSDate date];
        [_extensionsManager addUndoItem:[UndoItem itemForUndoModifyAnnotWithOldAttributes:self.attributesBeforeModify newAttributes:[FSAnnotAttributes attributesWithAnnot:annot] pdfViewCtrl:_pdfViewCtrl page:page annotHandler:self]];
    }

    [_extensionsManager onAnnotModified:page annot:annot];

    int pageIndex = annot.pageIndex;
    CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
    rect = CGRectInset(rect, -30, -30);

    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

- (void)removeAnnot:(FSAnnot *)annot {
    [self removeAnnot:annot addUndo:YES];
}

- (void)removeAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    FSPDFPage *page = [annot getPage];
    if (!page)
        return;

    CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
    int pageIndex = annot.pageIndex;

    if (addUndo) {
        FSNoteAttributes *attributes = (FSNoteAttributes *) ([self.attributesBeforeModify.NM isEqualToString:annot.NM] ? self.attributesBeforeModify : [FSAnnotAttributes attributesWithAnnot:annot]);
        [_extensionsManager addUndoItem:[UndoItem itemWithUndo:^(UndoItem *item) {
                                FSNote *note = nil;
                                if (attributes.replyTo.length == 0) {
                                    note = (FSNote *) [page addAnnot:e_annotNote rect:attributes.rect];
                                } else {
                                    FSMarkup *parent = (FSMarkup *) [Utility getAnnotByNM:attributes.replyTo inPage:page];
                                    note = [parent addReply];
                                }
                                if (note) {
                                    [attributes resetAnnot:note];
                                    [self addAnnot:note addUndo:NO];
                                }
                            }
                                            redo:^(UndoItem *item) {
                                                FSAnnot *annot = [Utility getAnnotByNM:attributes.NM inPage:page];
                                                if (annot) {
                                                    [self removeAnnot:annot addUndo:NO];
                                                }
                                            }
                                            pageIndex:pageIndex]];
    }
    self.attributesBeforeModify = nil;

    [_extensionsManager onAnnotWillDelete:page annot:annot];
    [page removeAnnot:annot];
    [_extensionsManager onAnnotDeleted:page annot:annot];

    rect = CGRectInset(rect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
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
    if (_extensionsManager.currentAnnot != annot) {
        return NO;
    }
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        MenuControl *annotMenu = _extensionsManager.menuControl;
        if ([annotMenu isMenuVisible]) {
            [annotMenu hideMenu];
        }
        if (_extensionsManager.propertyBar.isShowing && self.isShowStyle) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];

        CGPoint translationPoint = [recognizer translationInView:pageView];
        float tw = translationPoint.x;
        float th = translationPoint.y;
        if (!annot.canModify) {
            return YES;
        }
        CGRect realRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        FSRectF *rect = [Utility CGRect2FSRectF:realRect];

        rect.left += tw;
        rect.right += tw;
        rect.top += th;
        rect.bottom += th;
        CGRect newRect = [Utility FSRectF2CGRect:rect];
        if (!(newRect.origin.x <= 0 || newRect.origin.x + newRect.size.width >= [_pdfViewCtrl getPageViewWidth:pageIndex] - 20 || newRect.origin.y <= 0 || newRect.origin.y + newRect.size.height >= [_pdfViewCtrl getPageViewHeight:pageIndex] - 20)) {
            rect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:pageIndex];
            annot.fsrect = rect;
            CGRect unionRect = CGRectEqualToRect(_lastPanRect, CGRectZero) ? newRect : CGRectUnion(newRect, _lastPanRect);
            [_pdfViewCtrl refresh:CGRectInset(unionRect, -30, -30) pageIndex:pageIndex needRender:NO];
            _lastPanRect = newRect;
            [recognizer setTranslation:CGPointZero inView:pageView];
        } else {
            return NO;
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (annot.canModify) {
            annot.modifiedDate = [NSDate date];
            [self modifyAnnot:annot addUndo:NO];
        }
        CGRect newRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];

        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:newRect pageIndex:annot.pageIndex];
        if (self.isShowStyle) {
            self.shouldShowMenu = NO;
            self.shouldShowPropety = YES;
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        } else {
            self.shouldShowMenu = YES;
            self.shouldShowPropety = NO;
            MenuControl *annotMenu = _extensionsManager.menuControl;
            [annotMenu setRect:showRect];
            [annotMenu showMenu];
        }
        _lastPanRect = newRect;
    }
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot *)annot {
    if ([_extensionsManager getAnnotHandlerByAnnot:annot] == self) {
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
    if (pageIndex == annot.pageIndex) {
        if (_extensionsManager.currentAnnot == annot) {
            CGRect annotRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            annotRect.origin.x = rect.origin.x;
            annotRect.origin.y = rect.origin.y;
            if (self.annotImage) {
                CGContextSaveGState(context);
                CGContextTranslateCTM(context, annotRect.origin.x, annotRect.origin.y);
                CGContextTranslateCTM(context, 0, annotRect.size.height);
                CGContextScaleCTM(context, 1.0, -1.0);
                CGContextTranslateCTM(context, -annotRect.origin.x, -annotRect.origin.y);
                CGContextDrawImage(context, annotRect, [self.annotImage CGImage]);
                CGContextRestoreGState(context);
            }
            CGRect drawRect = CGRectMake(ceilf(rect.origin.x), ceilf(rect.origin.y), ceilf(annotRect.size.width), ceilf(annotRect.size.height));
            drawRect = CGRectInset(drawRect, -2, -2);
            CGContextSetLineWidth(context, 2.0);
            CGFloat dashArray[] = {3, 3, 3, 3};
            CGContextSetLineDash(context, 3, dashArray, 4);
            CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
            CGContextStrokeRect(context, drawRect);
        }
    }
}

#pragma mark IPropertyBarListener

- (void)onPropertyBarDismiss {
    FSAnnot *curAnnot = _extensionsManager.currentAnnot;
    if (DEVICE_iPHONE && curAnnot == self.editAnnot && curAnnot.type == e_annotNote) {
        self.isShowStyle = NO;
        self.shouldShowPropety = NO;
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

#pragma mark IRotationEventListener

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

- (void)onScrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
{
    if (!_isZooming) { // if drag and zoom in the meantime, will show menu/property after the zooming
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
    _isZooming = YES;
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView {
    [self showAnnotMenu];
    _isZooming = NO;
}

- (void)showAnnotMenu {
    FSAnnot *curAnnot = _extensionsManager.currentAnnot;
    if (curAnnot == self.editAnnot && [_extensionsManager getAnnotHandlerByAnnot:curAnnot] == self) {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:_extensionsManager.currentAnnot.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.editAnnot.pageIndex];

        CGRect rectDisplayView = [[_pdfViewCtrl getDisplayView] bounds];
        if (CGRectIsEmpty(showRect) || CGRectIsNull(CGRectIntersection(showRect, rectDisplayView)))
            return;

        if (self.shouldShowPropety) {
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        } else if (self.shouldShowMenu) {
            MenuControl *annotMenu = _extensionsManager.menuControl;
            [annotMenu setRect:showRect];
            [annotMenu showMenu];
        }
    }
}

- (void)dismissAnnotMenu {
    FSAnnot *curAnnot = _extensionsManager.currentAnnot;
    if (curAnnot == self.editAnnot && curAnnot.type == e_annotNote) {
        MenuControl *annotMenu = _extensionsManager.menuControl;
        if (annotMenu.isMenuVisible) {
            [annotMenu setMenuVisible:NO animated:YES];
        }
        if (_extensionsManager.propertyBar.isShowing) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
    }
}

- (void)_addAnnot:(FSNote *)annot addUndo:(BOOL)addUndo {
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:annot.pageIndex];
    if (!page)
        return;

    if (addUndo) {
        FSNoteAttributes *attributes = [[FSNoteAttributes alloc] initWithAnnot:annot];
        [_extensionsManager addUndoItem:[UndoItem itemWithUndo:^(UndoItem *item) {
            FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:item.pageIndex];
            FSAnnot *annot = [Utility getAnnotByNM:attributes.NM inPage:page];
            if (annot) {
                [self removeAnnot:annot addUndo:NO];
            }
        } redo:^(UndoItem *item) {
            FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:item.pageIndex];
            FSNote *note = nil;
            if (attributes.replyTo.length == 0) {
                note = (FSNote *) [page addAnnot:e_annotNote rect:attributes.rect];
            } else {
                FSMarkup *parent = (FSMarkup *) [Utility getAnnotByNM:attributes.replyTo inPage:page];
                note = [parent addReply];
            }
            if (note) {
                [attributes resetAnnot:note];
                [self addAnnot:note addUndo:NO];
            }
        } pageIndex:annot.pageIndex]];
    }

    if (annot.replyTo.length > 0) {
        [_extensionsManager onAnnotAdded:page annot:annot];
        return;
    } else {
        BOOL rectChanged = NO;
        FSRectF *rect = annot.fsrect;
        if (rect.left != 0 && rect.left == rect.right) {
            rect.right++;
            rectChanged = YES;
        }
        if (rect.bottom != 0 && rect.bottom == rect.top) {
            rect.top++;
            rectChanged = YES;
        }
        if (rectChanged) {
            FSRectF *fsRect = [[FSRectF alloc] init];
            [fsRect set:rect.left bottom:rect.bottom right:rect.right top:rect.top];
            [annot setFsrect:fsRect];
        }

        unsigned int flags = e_annotFlagPrint | e_annotFlagNoZoom | e_annotFlagNoRotate;
        [annot setFlags:flags];
        [_extensionsManager onAnnotAdded:page annot:annot];
    }
}

#pragma mark IDocEventListener

- (void)onDocWillClose:(FSPDFDoc *)document {
    if (self.currentVC) {
        [self.currentVC dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)onAnnotChanged:(FSAnnot *)annot property:(long)property from:(NSValue *)oldValue to:(NSValue *)newValue {
    if (annot == self.editAnnot && self.annotImage) {
        self.annotImage = [Utility getAnnotImage:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        int pageIndex = self.editAnnot.pageIndex;
        CGRect rect = [Utility getAnnotRect:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        [_pdfViewCtrl refresh:CGRectInset(rect, -30, -30) pageIndex:pageIndex needRender:NO];
    }
}

@end
