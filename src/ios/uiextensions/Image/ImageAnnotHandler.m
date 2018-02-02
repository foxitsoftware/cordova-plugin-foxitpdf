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

#import "ImageAnnotHandler.h"
#import "ColorUtility.h"
#import "FSAnnotAttributes.h"
#import "FSUndo.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "PropertyBar.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "ShapeUtil.h"
#import "UIExtensionsManager.h"
#import "Utility.h"

@interface ImageAnnotHandler ()

@property (nonatomic, strong) FSAnnot *editAnnot;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, strong) FSAnnotAttributes *attributesBeforeModify; // for undo
@property (nonatomic, strong) UIImage *annotImage;
@property (nonatomic, strong) UIViewController *replyVC;
@property (nonatomic) UIEdgeInsets pageInsets;

@end

@implementation ImageAnnotHandler {
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
    UIExtensionsManager *_extensionsManager;
    EDIT_ANNOT_RECT_TYPE _editType;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        self.editAnnot = nil;
        self.shouldShowMenu = NO;
        _minImageWidthInPage = 0.1;
        _maxImageWidthInPage = 0.5;
        _minImageHeightInPage = 0.1;
        _maxImageHeightInPage = 0.5;
        _pageInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    return self;
}

- (FSAnnotType)getType {
    return e_annotScreen;
}

- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point {
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    pvRect = CGRectInset(pvRect, -20, -20);
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:annot.pageIndex];
    if (CGRectContainsPoint(pvRect, pvPoint)) {
        return YES;
    }
    return NO;
}

- (void)onAnnotSelected:(FSAnnot *)annot {
    self.editAnnot = annot;
    self.attributesBeforeModify = [FSAnnotAttributes attributesWithAnnot:annot];

    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];

    NSMutableArray *array = [NSMutableArray array];

    MenuItem *styleItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kStyle") object:self action:@selector(showStyle)];
    MenuItem *commentItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kOpen") object:self action:@selector(comment)];
    //    MenuItem *openItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kOpen") object:self action:@selector(comment)];
    MenuItem *replyItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kReply") object:self action:@selector(reply)];
    MenuItem *deleteItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kDelete") object:self action:@selector(delete)];
    [array addObject:commentItem];
    if (annot.canModify) {
        [array insertObject:styleItem atIndex:0];
        [array addObject:replyItem];
        [array addObject:deleteItem];
    } else {
        if (annot.canReply) {
            [array addObject:replyItem];
        }
    }

    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
    MenuControl *annotMenu = _extensionsManager.menuControl;
    annotMenu.menuItems = array;
    [annotMenu setRect:dvRect];
    [annotMenu showMenu];
    self.shouldShowMenu = YES;

    self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
    rect = CGRectInset(rect, -20, -20);
    [_pdfViewCtrl refresh:rect pageIndex:pageIndex needRender:YES];
}

- (void)onAnnotDeselected:(FSAnnot *)annot {
    if (_extensionsManager.menuControl.isMenuVisible) {
        [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
    }
    self.editAnnot = nil;
    self.annotImage = nil;

    self.shouldShowMenu = NO;
    if (_extensionsManager.menuControl.isMenuVisible) {
        [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
    }
    if (![self.attributesBeforeModify isEqualToAttributes:[FSAnnotAttributes attributesWithAnnot:annot]]) {
        [self modifyAnnot:annot addUndo:YES];
    }
    self.attributesBeforeModify = nil;

    if (_extensionsManager.propertyBar.isShowing) {
        [_extensionsManager.propertyBar dismissPropertyBar];
    }

    int pageIndex = annot.pageIndex;
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    newRect = CGRectInset(newRect, -20, -20);
    [_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:YES];
}

- (void)onAnnotChanged:(FSAnnot *)annot property:(long)property from:(NSValue *)oldValue to:(NSValue *)newValue {
    if (annot == self.editAnnot && self.annotImage) {
        self.annotImage = [Utility getAnnotImage:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        int pageIndex = self.editAnnot.pageIndex;
        CGRect rect = [Utility getAnnotRect:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        [_pdfViewCtrl refresh:CGRectInset(rect, -30, -30) pageIndex:pageIndex needRender:NO];
    }
}

- (void)showStyle {
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_OPACITY | PROPERTY_ROTATION frame:CGRectZero];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity * 100.0];
    [_extensionsManager.propertyBar setProperty:PROPERTY_ROTATION intValue:[Utility valueForRotation:[(FSScreen *) annot getRotation]]];
    [_extensionsManager.propertyBar addListener:_extensionsManager];
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
    [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
    //    self.isShowStyle = YES;
    self.shouldShowMenu = NO;
    //    self.shouldShowPropety = YES;
}

- (void)comment {
    NSMutableArray *replyAnnots = [[NSMutableArray alloc] init];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
    self.replyVC = replyCtr;
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
    self.replyVC = replyCtr;
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

- (void) delete {
    FSAnnot *annot = _extensionsManager.currentAnnot;
    Task *task = [[Task alloc] init];
    task.run = ^() {
        [self removeAnnot:annot];
    };
    [_taskServer executeSync:task];
    [_extensionsManager setCurrentAnnot:nil];
}

- (void)addAnnot:(FSAnnot *)annot {
    [self addAnnot:annot addUndo:YES];
}

- (void)addAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    int pageIndex = annot.pageIndex;
    FSPDFPage *page = [annot getPage];
    if (addUndo) {
        FSAnnotAttributes *attributes = [FSAnnotAttributes attributesWithAnnot:annot];
        [_extensionsManager addUndoItem:[UndoItem itemForUndoAddAnnotWithAttributes:attributes page:page annotHandler:self]];
    }

    [_extensionsManager onAnnotAdded:page annot:annot];
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    rect = CGRectInset(rect, -20, -20);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
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
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    rect = CGRectInset(rect, -20, -20);
    rect = CGRectIntersection(rect, [_pdfViewCtrl getPageView:pageIndex].bounds);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:annot.pageIndex];
    });
}

- (void)removeAnnot:(FSAnnot *)annot {
    [self removeAnnot:annot addUndo:YES];
}

- (void)removeAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    int pageIndex = annot.pageIndex;
    FSPDFPage *page = [annot getPage];

    if (addUndo) {
        FSAnnotAttributes *attributes = self.attributesBeforeModify ?: [FSAnnotAttributes attributesWithAnnot:annot];
        [_extensionsManager addUndoItem:[UndoItem itemForUndoDeleteAnnotWithAttributes:attributes page:page annotHandler:self]];
    }
    self.attributesBeforeModify = nil;

    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect = CGRectInset(rect, -20, -20);

    [_extensionsManager onAnnotWillDelete:[_pdfViewCtrl.currentDoc getPage:pageIndex] annot:annot];
    [page removeAnnot:annot];
    [_extensionsManager onAnnotDeleted:page annot:annot];

    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:annot.pageIndex]];
    FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:annot.pageIndex];
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
    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    if (_extensionsManager.currentAnnot != annot) {
        return NO;
    }

    UIView *pageView = [_pdfViewCtrl getPageView:annot.pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.shouldShowMenu = NO;
        if ([_extensionsManager.menuControl isMenuVisible]) {
            [_extensionsManager.menuControl hideMenu];
        }
        _editType = [ShapeUtil getEditTypeWithPoint:point rect:CGRectInset(pvRect, -10, -10) defaultEditType:EDIT_ANNOT_RECT_TYPE_FULL];
        if (_editType == EDIT_ANNOT_RECT_TYPE_MIDDLETOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_MIDDLEBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_LEFTMIDDLE ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTMIDDLE) {
            _editType = EDIT_ANNOT_RECT_TYPE_FULL;
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGRect pageInsetRect = UIEdgeInsetsInsetRect(pageView.bounds, self.pageInsets);
        CGFloat pageWidth = CGRectGetWidth(pageView.bounds);
        CGFloat pageHeight = CGRectGetHeight(pageView.bounds);
        CGFloat minW = self.minImageWidthInPage * pageWidth;
        CGFloat maxW = self.maxImageWidthInPage * pageWidth;
        CGFloat minH = self.minImageHeightInPage * pageHeight;
        CGFloat maxH = self.maxImageHeightInPage * pageHeight;
        CGFloat dx = 0;
        CGFloat dy = 0;
        CGFloat dw = 0;
        CGFloat dh = 0;
        CGFloat w = CGRectGetWidth(pvRect);
        CGFloat h = CGRectGetHeight(pvRect);
        CGPoint translation = [recognizer translationInView:pageView];
        if (_editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            dx = translation.x;
            dy = translation.y;
            dx = MIN(dx, CGRectGetMaxX(pageInsetRect) - CGRectGetMaxX(pvRect));
            dx = MAX(dx, CGRectGetMinX(pageInsetRect) - CGRectGetMinX(pvRect));
            dy = MIN(dy, CGRectGetMaxY(pageInsetRect) - CGRectGetMaxY(pvRect));
            dy = MAX(dy, CGRectGetMinY(pageInsetRect) - CGRectGetMinY(pvRect));
        } else if (_editType == EDIT_ANNOT_RECT_TYPE_RIGHTBOTTOM) {
            CGFloat tmp = (w * translation.x + h * translation.y) / (w * w + h * h);
            dw = w * tmp;
            dh = h * tmp;
            maxW = MIN(maxW, CGRectGetMaxX(pageInsetRect) - CGRectGetMinX(pvRect));
            maxH = MIN(maxH, CGRectGetMaxY(pageInsetRect) - CGRectGetMinY(pvRect));
            dw = MIN(MAX(dw, minW - w), maxW - w);
            dh = h / w * dw;
            dh = MIN(MAX(dh, minH - h), maxH - h);
            dw = w / h * dh;
        } else if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTTOP) {
            CGFloat tmp = (w * translation.x + h * translation.y) / (w * w + h * h);
            dw = -w * tmp;
            dh = -h * tmp;
            maxW = MIN(maxW, CGRectGetMaxX(pvRect) - CGRectGetMinX(pageInsetRect));
            maxH = MIN(maxH, CGRectGetMaxY(pvRect) - CGRectGetMinY(pageInsetRect));
            dw = MIN(MAX(dw, minW - w), maxW - w);
            dh = h / w * dw;
            dh = MIN(MAX(dh, minH - h), maxH - h);
            dw = w / h * dh;
            dx = -dw;
            dy = -dh;
        } else if (_editType == EDIT_ANNOT_RECT_TYPE_RIGHTTOP) {
            CGFloat tmp = (w * translation.x - h * translation.y) / (w * w + h * h);
            dw = w * tmp;
            dh = h * tmp;
            maxW = MIN(maxW, CGRectGetMaxX(pageInsetRect) - CGRectGetMinX(pvRect));
            maxH = MIN(maxH, CGRectGetMaxY(pvRect) - CGRectGetMinY(pageInsetRect));
            dw = MIN(MAX(dw, minW - w), maxW - w);
            dh = h / w * dw;
            dh = MIN(MAX(dh, minH - h), maxH - h);
            dw = w / h * dh;
            dy = -dh;
        } else if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM) {
            CGFloat tmp = (w * translation.x - h * translation.y) / (w * w + h * h);
            dw = -w * tmp;
            dh = -h * tmp;
            maxW = MIN(maxW, CGRectGetMaxX(pvRect) - CGRectGetMinX(pageInsetRect));
            maxH = MIN(maxH, CGRectGetMaxY(pageInsetRect) - CGRectGetMinY(pvRect));
            dw = MIN(MAX(dw, minW - w), maxW - w);
            dh = h / w * dw;
            dh = MIN(MAX(dh, minH - h), maxH - h);
            dw = w / h * dh;
            dx = -dw;
        }
        CGRect newRect = pvRect;
        newRect.origin.x += dx;
        newRect.origin.y += dy;
        newRect.size.width += dw;
        newRect.size.height += dh;
        annot.fsrect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:pageIndex];
        if (_editType != EDIT_ANNOT_RECT_TYPE_FULL) {
            self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
        }
        CGRect refreshRect = CGRectUnion(newRect, pvRect);
        refreshRect = CGRectInset(refreshRect, -20, -20);
        [_pdfViewCtrl refresh:refreshRect pageIndex:annot.pageIndex needRender:NO];
        // update gesture translation
        if (_editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            translation.x -= dx;
            translation.y -= dy;
        } else if (_editType == EDIT_ANNOT_RECT_TYPE_RIGHTBOTTOM) {
            translation.x -= dw;
            translation.y -= dh;
        } else if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTTOP) {
            translation.x += dw;
            translation.y += dh;
        } else if (_editType == EDIT_ANNOT_RECT_TYPE_RIGHTTOP) {
            translation.x -= dw;
            translation.y += dh;
        } else if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM) {
            translation.x += dw;
            translation.y -= dh;
        }
        [recognizer setTranslation:translation inView:pageView];
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        _editType = EDIT_ANNOT_RECT_TYPE_UNKNOWN;
        if (annot.canModify) {
            [self modifyAnnot:annot addUndo:NO];
        }

        self.shouldShowMenu = YES;
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:annot.pageIndex];

        [_extensionsManager.menuControl setRect:showRect];
        [_extensionsManager.menuControl showMenu];
    }
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot *)annot {
    if (annot.type == e_annotScreen) {
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
    //    UITouch *touch = [touches anyObject];
    //    CGPoint point = [touch locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    //    FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    //    if (_extensionsManager.currentAnnot == annot) {
    //        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
    //            return YES;
    //        } else {
    //            [_extensionsManager setCurrentAnnot:nil];
    //            return YES;
    //        }
    //    } else {
    //        [_extensionsManager setCurrentAnnot:annot];
    //        return YES;
    //    }
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
    if (pageIndex == annot.pageIndex && _extensionsManager.currentAnnot == annot && annot.type == e_annotScreen) {
        CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];

        if (self.annotImage) {
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
            CGContextTranslateCTM(context, 0, rect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
            CGContextDrawImage(context, rect, [self.annotImage CGImage]);
            CGContextRestoreGState(context);
        }

        rect = CGRectInset(rect, -10, -10);
        CGContextSetLineWidth(context, 2.0);
        CGFloat dashArray[] = {3, 3, 3, 3};
        CGContextSetLineDash(context, 3, dashArray, 4);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:0x179cd8] CGColor]);
        CGContextStrokeRect(context, rect);

        UIImage *dragDot = [UIImage imageNamed:@"annotation_drag.png"];
        NSArray *movePointArray = [ShapeUtil getCornerMovePointInRect:rect];
        [movePointArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect dotRect = [obj CGRectValue];
            CGPoint point = CGPointMake(dotRect.origin.x, dotRect.origin.y);
            [dragDot drawAtPoint:point];
        }];
    }
}

- (void)onRotateChangedBefore:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissAnnotMenu];
}

- (void)onRotateChangedAfter:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self showAnnotMenu];
}

#pragma mark IPropertyBarListener

- (void)onPropertyBarDismiss {
    if (DEVICE_iPHONE && _extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotScreen) {
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView {
    [self showAnnotMenu];
}

- (void)showAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotScreen) {
        if (self.shouldShowMenu) {
            int pageIndex = self.editAnnot.pageIndex;
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:pageIndex];
            CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
            [_extensionsManager.menuControl setRect:showRect];
            [_extensionsManager.menuControl showMenu];
        }
    }
}

- (void)dismissAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotScreen) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
    }
}

#pragma mark IRotationEventListener

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissAnnotMenu];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self showAnnotMenu];
}

@end
