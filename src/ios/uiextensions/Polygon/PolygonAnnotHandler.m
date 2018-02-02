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

#import "PolygonAnnotHandler.h"
#import "ColorUtility.h"
#import "FSAnnotAttributes.h"
#import "FSAnnotExtent.h"
#import "FSUndo.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "ShapeUtil.h"

@interface PolygonAnnotHandler () <IDocEventListener>

@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, strong) FSPolygon *editAnnot;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;
@property (nonatomic, strong) UIImage *annotImage;
@property (nonatomic, strong) FSAnnotAttributes *attributesBeforeModify;
@property (nonatomic, strong) UIViewController *replyVC;

@property (nonatomic) CGFloat maxFingerBias;
@property (nonatomic, strong) NSMutableArray<FSPointF *> *vertexes;

typedef NS_ENUM(NSUInteger, EditType) {
    e_editTypeWholeAnnot,
    e_editTypeSingleVertex
};
@property (nonatomic) EditType editType;
@property (nonatomic) NSUInteger movingVertexIndex;

@end

@implementation PolygonAnnotHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        self.colors = @[ @0xFF9F40, @0x8080FF, @0xBAE94C, @0xFFF160, @0xC3C3C3, @0xFF4C4C, @0x669999, @0xC72DA1, @0x996666, @0x000000 ];
        self.isShowStyle = NO;
        self.editAnnot = nil;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        self.minVertexDistance = 5;
        self.maxFingerBias = 25;
        self.vertexes = nil;
    }
    return self;
}

- (FSAnnotType)getType {
    return e_annotPolygon;
}

- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point {
    int pageIndex = annot.pageIndex;
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:pageIndex];
    return CGRectContainsPoint(CGRectInset(pvRect, -10, -10), pvPoint);
}

- (void)onAnnotSelected:(FSAnnot *)annot {
    self.editAnnot = (FSPolygon *) annot;
    self.attributesBeforeModify = [FSAnnotAttributes attributesWithAnnot:annot];

    NSMutableArray *array = [NSMutableArray array];

    MenuItem *commentItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kOpen") object:self action:@selector(comment)];
    MenuItem *openItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kOpen") object:self action:@selector(comment)];
    MenuItem *replyItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kReply") object:self action:@selector(reply)];
    MenuItem *styleItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kStyle") object:self action:@selector(showStyle)];
    MenuItem *deleteItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kDelete") object:self action:@selector(delete)];
    if (annot.canModify) {
        if (annot.contents == nil || [annot.contents isEqualToString:@""]) {
            [array addObject:commentItem];
        } else {
            [array addObject:openItem];
        }
        [array addObject:replyItem];
        [array addObject:styleItem];
        [array addObject:deleteItem];
    } else {
        [array addObject:commentItem];
        if (annot.canReply) {
            [array addObject:replyItem];
        }
    }

    CGRect pvRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:annot.pageIndex];

    _extensionsManager.menuControl.menuItems = array;
    [_extensionsManager.menuControl setRect:dvRect margin:20];
    [_extensionsManager.menuControl showMenu];
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;

    self.vertexes = [Utility getPolygonVertexes:(FSPolygon *) annot].mutableCopy;
    self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
    [_pdfViewCtrl refresh:CGRectInset(pvRect, -30, -30) pageIndex:annot.pageIndex needRender:YES];
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
        [self removeAnnot:annot addUndo:YES];
    };
    [_extensionsManager.taskServer executeSync:task];
    [_extensionsManager setCurrentAnnot:nil];
}

- (void)showStyle {
    [_extensionsManager.propertyBar setColors:self.colors];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_LINEWIDTH frame:CGRectZero];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity * 100.0];
    [_extensionsManager.propertyBar setProperty:PROPERTY_LINEWIDTH intValue:annot.lineWidth];
    [_extensionsManager.propertyBar addListener:_extensionsManager];

    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:annot.pageIndex];
    NSArray *array = [NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]];
    [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:array];
    self.isShowStyle = YES;
    self.shouldShowMenu = NO;
    self.shouldShowPropety = YES;
}

- (void)onAnnotDeselected:(FSAnnot *)annot {
    if (![self.attributesBeforeModify isEqualToAttributes:[FSAnnotAttributes attributesWithAnnot:annot]]) {
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
    self.editAnnot = nil;

    int pageIndex = annot.pageIndex;
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    newRect = CGRectInset(newRect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:YES];
    });
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
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect = CGRectInset(rect, -30, -30);
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
    int pageIndex = annot.pageIndex;

    if ([annot canModify] && addUndo) {
        annot.modifiedDate = [NSDate date];
        [_extensionsManager addUndoItem:[UndoItem itemForUndoModifyAnnotWithOldAttributes:self.attributesBeforeModify newAttributes:[FSAnnotAttributes attributesWithAnnot:annot] pdfViewCtrl:_pdfViewCtrl page:page annotHandler:self]];
    }

    [_extensionsManager onAnnotModified:[annot getPage] annot:annot];

    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
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

    if (addUndo) {
        FSAnnotAttributes *attributes = self.attributesBeforeModify ?: [FSAnnotAttributes attributesWithAnnot:annot];
        [_extensionsManager addUndoItem:[UndoItem itemForUndoDeleteAnnotWithAttributes:attributes page:page annotHandler:self]];
    }
    self.attributesBeforeModify = nil;

    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];

    [_extensionsManager onAnnotWillDelete:page annot:annot];
    [page removeAnnot:annot];

    rect = CGRectInset(rect, -30, -30);
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
    return NO;
}

- (BOOL)isFingerAtPos:(CGPoint)pos closeToVertex:(CGPoint)vertex {
    CGFloat dx = pos.x - vertex.x;
    CGFloat dy = pos.y - vertex.y;
    return dx * dx + dy * dy < self.maxFingerBias * self.maxFingerBias;
}

- (BOOL)isVertexValid:(CGPoint)vertex pageIndex:(int)pageIndex {
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGRect validRect = CGRectInset(pageView.bounds, 5, 5);
    if (!CGRectContainsPoint(validRect, vertex)) {
        return NO;
    }
    return YES;
}

- (BOOL)isVertexValid:(CGPoint)vertex vertexIndex:(NSUInteger)vertexIndex pageIndex:(int)pageIndex {
    if (![self isVertexValid:vertex pageIndex:pageIndex]) {
        return NO;
    }
    if (vertexIndex > 0) {
        CGPoint prevPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.vertexes[vertexIndex - 1] pageIndex:pageIndex];
        CGFloat dx = prevPoint.x - vertex.x;
        CGFloat dy = prevPoint.y - vertex.y;
        if (dx * dx + dy * dy < self.minVertexDistance * self.minVertexDistance) {
            return NO;
        }
    }
    if (vertexIndex < self.vertexes.count - 1) {
        CGPoint nextPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.vertexes[vertexIndex + 1] pageIndex:pageIndex];
        CGFloat dx = nextPoint.x - vertex.x;
        CGFloat dy = nextPoint.y - vertex.y;
        if (dx * dx + dy * dy < self.minVertexDistance * self.minVertexDistance) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    if (_extensionsManager.currentAnnot != annot) {
        return NO;
    }

    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        if ([_extensionsManager.menuControl isMenuVisible]) {
            [_extensionsManager.menuControl hideMenu];
        }
        if (_extensionsManager.propertyBar.isShowing && self.isShowStyle) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
        self.editType = e_editTypeWholeAnnot;
        [self.vertexes enumerateObjectsUsingBlock:^(FSPointF *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            CGPoint vertex = [_pdfViewCtrl convertPdfPtToPageViewPt:obj pageIndex:pageIndex];
            if ([self isFingerAtPos:point closeToVertex:vertex]) {
                self.editType = e_editTypeSingleVertex;
                self.movingVertexIndex = idx;
                *stop = YES;
            }
        }];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (!annot.canModify) {
            return YES;
        }
        BOOL shouldMove = YES;
        // update self.vertexes
        CGPoint translation = [recognizer translationInView:pageView];
        if (self.editType == e_editTypeWholeAnnot) {
            for (NSInteger i = 0; i < self.vertexes.count; i++) {
                FSPointF *vertex = self.vertexes[i];
                CGPoint pvVertex = [_pdfViewCtrl convertPdfPtToPageViewPt:vertex pageIndex:pageIndex];
                pvVertex.x += translation.x;
                pvVertex.y += translation.y;
                if ([self isVertexValid:pvVertex pageIndex:pageIndex]) {
                    FSPointF *translatedVertex = [_pdfViewCtrl convertPageViewPtToPdfPt:pvVertex pageIndex:pageIndex];
                    vertex.x = translatedVertex.x;
                    vertex.y = translatedVertex.y;
                } else {
                    shouldMove = NO;
                    // undo translation
                    for (NSInteger j = i - 1; j >= 0; j--) {
                        FSPointF *vertex = self.vertexes[j];
                        CGPoint pvVertex = [_pdfViewCtrl convertPdfPtToPageViewPt:vertex pageIndex:pageIndex];
                        pvVertex.x -= translation.x;
                        pvVertex.y -= translation.y;
                        FSPointF *translatedVertex = [_pdfViewCtrl convertPageViewPtToPdfPt:pvVertex pageIndex:pageIndex];
                        vertex.x = translatedVertex.x;
                        vertex.y = translatedVertex.y;
                    }
                    break;
                }
            }
        } else {
            FSPointF *movingVertex = self.vertexes[self.movingVertexIndex];
            CGPoint pvVertex = [_pdfViewCtrl convertPdfPtToPageViewPt:movingVertex pageIndex:pageIndex];
            pvVertex.x += translation.x;
            pvVertex.y += translation.y;
            if ([self isVertexValid:pvVertex vertexIndex:self.movingVertexIndex pageIndex:pageIndex]) {
                FSPointF *translatedVertex = [_pdfViewCtrl convertPageViewPtToPdfPt:pvVertex pageIndex:pageIndex];
                movingVertex.x = translatedVertex.x;
                movingVertex.y = translatedVertex.y;
            } else {
                shouldMove = NO;
            }
        }
        if (!shouldMove) {
            return YES;
        }
        [recognizer setTranslation:CGPointZero inView:[_pdfViewCtrl getPageView:pageIndex]];
        CGRect oldRect = [Utility getAnnotRect:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        [self.editAnnot setVertexes:self.vertexes];
        [self.editAnnot resetAppearanceStream];
        CGRect newRect = [Utility getAnnotRect:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        if (self.editType == e_editTypeSingleVertex) {
            self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
        }
        newRect = CGRectUnion(newRect, oldRect);
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:NO];
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        _editType = EDIT_ANNOT_RECT_TYPE_UNKNOWN;
        if (annot.canModify) {
            annot.modifiedDate = [NSDate date];
            [self modifyAnnot:annot addUndo:NO];
        }

        CGRect pvRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:annot.pageIndex];
        if (self.isShowStyle && !DEVICE_iPHONE) {
            self.shouldShowMenu = NO;
            self.shouldShowPropety = YES;
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:[_pdfViewCtrl getDisplayView] viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        } else {
            self.shouldShowMenu = YES;
            self.shouldShowPropety = NO;
            [_extensionsManager.menuControl setRect:showRect margin:20];
            [_extensionsManager.menuControl showMenu];
        }
    }
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot *)annot {
    if ([_extensionsManager getAnnotHandlerByAnnot:annot] == self) {
        BOOL canAddAnnot = [Utility canAddAnnotToDocument:_pdfViewCtrl.currentDoc];
        if (!canAddAnnot) {
            return NO;
        }
        CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:annot.pageIndex]];
        FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:annot.pageIndex];
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
            return YES;
        }
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
    if (_extensionsManager.currentAnnot == annot && pageIndex == annot.pageIndex &&
        annot.type == e_annotPolygon) {
        CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        CGRect _rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        rect.origin.x = _rect.origin.x;
        rect.origin.y = _rect.origin.y;

        if (self.annotImage) {
            CGContextSaveGState(context);

            CGContextTranslateCTM(context, (int) rect.origin.x, (int) rect.origin.y);
            CGContextTranslateCTM(context, 0, (int) rect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, -(int) rect.origin.x, -(int) rect.origin.y);
            CGContextDrawImage(context, rect, [self.annotImage CGImage]);

            CGContextRestoreGState(context);
        }

        rect = CGRectInset(rect, -10, -10);

        CGContextSetLineWidth(context, 2.0);
        CGFloat dashArray[] = {3, 3, 3, 3};
        CGContextSetLineDash(context, 3, dashArray, 4);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
        CGContextStrokeRect(context, rect);

        UIImage *dragDot = [UIImage imageNamed:@"annotation_drag.png"];
        CGSize dotSize = dragDot.size;
        for (FSPointF *vertex in self.vertexes) {
            CGPoint point = [_pdfViewCtrl convertPdfPtToPageViewPt:vertex pageIndex:pageIndex];
            point.x -= dotSize.width / 2;
            point.y -= dotSize.height / 2;
            [dragDot drawAtPoint:point];
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

#pragma mark IPropertyBarListener

- (void)onPropertyBarDismiss {
    if (DEVICE_iPHONE && self.editAnnot && _extensionsManager.currentAnnot == self.editAnnot) {
        self.isShowStyle = NO;
        self.shouldShowPropety = NO;
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDragging:(UIScrollView *)dviewer {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)dviewer willDecelerate:(BOOL)decelerate {
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)dviewer {
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)dviewer {
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)dviewer {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)dviewer {
    [self showAnnotMenu];
}

- (void)showAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:self.editAnnot.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.editAnnot.pageIndex];

        if (self.shouldShowPropety) {
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:[_pdfViewCtrl getDisplayView] viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        } else if (self.shouldShowMenu) {
            [_extensionsManager.menuControl setRect:showRect margin:20];
            [_extensionsManager.menuControl showMenu];
        }
    }
}

- (void)dismissAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
        if (_extensionsManager.propertyBar.isShowing) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
    }
}

#pragma mark IDocEventListener

- (void)onDocWillClose:(FSPDFDoc *)document {
    if (self.replyVC) {
        [self.replyVC dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)onAnnotChanged:(FSAnnot *)annot property:(long)property from:(NSValue *)oldValue to:(NSValue *)newValue {
    if (annot == self.editAnnot && self.annotImage) {
        self.annotImage = [Utility getAnnotImage:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        int pageIndex = self.editAnnot.pageIndex;
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:pageIndex];
        [_pdfViewCtrl refresh:CGRectInset(newRect, -30, -30) pageIndex:pageIndex needRender:NO];
    }
}

@end
