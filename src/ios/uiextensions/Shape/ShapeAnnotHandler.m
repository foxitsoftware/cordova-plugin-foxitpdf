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

#import "ShapeAnnotHandler.h"
#import "ColorUtility.h"
#import "FSAnnotAttributes.h"
#import "FSAnnotExtent.h"
#import "FSUndo.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "ShapeUtil.h"

@interface ShapeAnnotHandler () <IDocEventListener>

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, strong) FSAnnot *editAnnot;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;
@property (nonatomic, assign) CGRect currentAnnotRect;
@property (nonatomic, strong) UIImage *annotImage;
@property (nonatomic, strong) FSAnnotAttributes *attributesBeforeModify;
@end

@implementation ShapeAnnotHandler {
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
    }
    return self;
}

- (FSAnnotType)getType {
    return e_annotCircle;
}

- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point {
    int pageIndex = annot.pageIndex;
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:pageIndex];
    return CGRectContainsPoint(CGRectInset(pvRect, -20, -20), pvPoint);
}

- (void)onAnnotSelected:(FSAnnot *)annot {
    self.editAnnot = annot;
    self.currentAnnotRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
    self.attributesBeforeModify = [FSAnnotAttributes attributesWithAnnot:annot];

    _minWidth = 10;
    _minHeight = 10;

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

    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:self.currentAnnotRect pageIndex:annot.pageIndex];

    _extensionsManager.menuControl.menuItems = array;
    [_extensionsManager.menuControl setRect:dvRect margin:20];
    [_extensionsManager.menuControl showMenu];
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;

    self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
    [_pdfViewCtrl refresh:CGRectInset(self.currentAnnotRect, -30, -30) pageIndex:annot.pageIndex needRender:YES];
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
        ;
    };
    replyCtr.editingCancelHandler = ^() {
        [_extensionsManager setCurrentAnnot:nil];
        ;
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
        ;
    };
    replyCtr.editingCancelHandler = ^() {
        [_extensionsManager setCurrentAnnot:nil];
        ;
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
    [_extensionsManager onAnnotDeleted:page annot:annot];

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

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    if (_extensionsManager.currentAnnot != annot) {
        return NO;
    }

    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        if ([_extensionsManager.menuControl isMenuVisible]) {
            [_extensionsManager.menuControl hideMenu];
        }
        if (_extensionsManager.propertyBar.isShowing && self.isShowStyle) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
        _editType = [ShapeUtil getEditTypeWithPoint:point rect:CGRectInset([_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex], -10, -10) defaultEditType:EDIT_ANNOT_RECT_TYPE_FULL];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGRect oldRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];

        CGPoint translationPoint = [recognizer translationInView:[_pdfViewCtrl getPageView:pageIndex]];
        float tw = translationPoint.x;
        float th = translationPoint.y;
        CGRect realRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
        FSRectF *rect = [Utility CGRect2FSRectF:realRect];

        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_LEFTMIDDLE ||
            _editType == EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            if (!annot.canModify) {
                return YES;
            }
            rect.left += tw;
            if (rect.left < _minWidth) {
                return NO;
            }
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL) {
                // Not left over right
                if ((rect.left + _minWidth) > rect.right) {
                    rect.right = rect.left + _minWidth;
                    if (rect.right > [_pdfViewCtrl getPageViewWidth:pageIndex] - _minWidth) {
                        return NO;
                    }
                } else if (ABS(rect.right - rect.left) > [_pdfViewCtrl getPageViewWidth:pageIndex]) {
                    rect.left -= tw;
                }
            }
        }
        if (_editType == EDIT_ANNOT_RECT_TYPE_RIGHTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTMIDDLE ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            if (!annot.canModify) {
                return YES;
            }
            rect.right += tw;
            if (rect.right > [_pdfViewCtrl getPageViewWidth:pageIndex] - _minWidth) {
                return NO;
            }
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL) {
                if ((rect.left + _minWidth) > rect.right) {
                    rect.left = rect.right - _minWidth;
                    if (rect.left < _minWidth) {
                        return NO;
                    }
                } else if (ABS(rect.right - rect.left) > [_pdfViewCtrl getPageViewWidth:pageIndex]) {
                    rect.right -= tw;
                }
            }
        }
        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_MIDDLETOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            if (!annot.canModify) {
                return YES;
            }
            rect.top += th;
            if (rect.top < _minHeight) {
                return NO;
            }
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL) {
                if ((rect.top + _minHeight) > rect.bottom) {
                    rect.bottom = rect.top + _minHeight;
                    if (rect.bottom > [_pdfViewCtrl getPageViewHeight:pageIndex] - _minHeight) {
                        return NO;
                    }
                } else if (ABS(rect.bottom - rect.top) > [_pdfViewCtrl getPageViewHeight:pageIndex]) {
                    rect.top -= th;
                }
            }
        }
        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_MIDDLEBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            if (!annot.canModify) {
                return YES;
            }
            rect.bottom += th;
            if (rect.bottom > [_pdfViewCtrl getPageViewHeight:pageIndex] - _minHeight) {
                return NO;
            }
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL) {
                if ((rect.top + _minHeight) > rect.bottom) {
                    rect.top = rect.bottom - _minHeight;
                    if (rect.top < _minHeight) {
                        return NO;
                    }
                } else if (ABS(rect.bottom - rect.top) > [_pdfViewCtrl getPageViewHeight:pageIndex]) {
                    rect.bottom -= th;
                }
            }
        }

        [recognizer setTranslation:CGPointZero inView:[_pdfViewCtrl getPageView:pageIndex]];
        CGRect newRect = [Utility FSRectF2CGRect:rect];
        rect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:pageIndex];
        annot.fsrect = rect;
        self.currentAnnotRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
        newRect = CGRectUnion(newRect, oldRect);
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:NO];
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        _editType = EDIT_ANNOT_RECT_TYPE_UNKNOWN;
        if (annot.canModify) {
            annot.modifiedDate = [NSDate date];
            [self modifyAnnot:annot addUndo:NO];
        }

        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:self.currentAnnotRect pageIndex:annot.pageIndex];
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
        (annot.type == e_annotCircle || annot.type == e_annotSquare)) {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];

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
        NSArray *movePointArray = [ShapeUtil getMovePointInRect:rect];
        [movePointArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect dotRect = [obj CGRectValue];
            CGPoint point = CGPointMake(dotRect.origin.x, dotRect.origin.y);
            [dragDot drawAtPoint:point];
        }];
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
    self.currentAnnotRect = CGRectZero; // saved rect is invalid if zoomed
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
        [_pdfViewCtrl refresh:CGRectInset(newRect, -20, -20) pageIndex:pageIndex needRender:NO];
    }
}

@end
