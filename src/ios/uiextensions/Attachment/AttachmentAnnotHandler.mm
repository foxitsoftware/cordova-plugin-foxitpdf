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

#import "AttachmentAnnotHandler.h"
#import "AttachmentController.h"
#import "ColorUtility.h"
#import "FSAnnotAttributes.h"
#import "FSUndo.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "PropertyBar.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "Utility.h"

#include <string>

@interface AttachmentAnnotHandler ()

@property (nonatomic, strong) FSAnnot *editAnnot;
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;

@property (nonatomic, strong) FSAnnotAttributes *attributesBeforeModify; // for undo

@property (nonatomic, strong) UIDocumentInteractionController *documentPopoverController;

@end

@implementation AttachmentAnnotHandler {
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
    UIExtensionsManager *_extensionsManager;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        [_extensionsManager registerAnnotHandler:self];
        [_extensionsManager registerRotateChangedListener:self];
        [_extensionsManager registerGestureEventListener:self];
        [_pdfViewCtrl registerScrollViewEventListener:self];
        [_extensionsManager.propertyBar registerPropertyBarListener:self];

        _taskServer = _extensionsManager.taskServer;
        self.colors = @[ @0xFF9F40, @0x8080FF, @0xBAE94C, @0xFFF160, @0x996666, @0xFF4C4C, @0x669999, @0xFFFFFF, @0xC3C3C3, @0x000000 ];
        self.isShowStyle = NO;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        self.editAnnot = nil;
    }
    return self;
}

- (FSAnnotType)getType {
    return e_annotFileAttachment;
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

    NSMutableArray<MenuItem *> *array = [NSMutableArray<MenuItem *> array];

    MenuItem *commentItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kOpen") object:self action:@selector(comment)];
    MenuItem *styleItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kStyle") object:self action:@selector(showStyle)];
    MenuItem *deleteItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kDelete") object:self action:@selector(deleteAnnot)];

    if (annot.canModify) {
        [array addObject:commentItem];
        [array addObject:styleItem];
        [array addObject:deleteItem];
    } else {
        [array addObject:commentItem];
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

- (void)comment {
    [self openAttachment:(FSFileAttachment *) _extensionsManager.currentAnnot];
    [_extensionsManager setCurrentAnnot:nil];
    return;
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
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setColors:self.colors];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_ATTACHMENT_ICONTYPE frame:CGRectZero];
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity * 100.0];
    [_extensionsManager.propertyBar setProperty:PROPERTY_ATTACHMENT_ICONTYPE intValue:annot.icon];
    [_extensionsManager.propertyBar addListener:_extensionsManager]; //todel
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

    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    newRect = CGRectInset(newRect, -30, -30);
    [_pdfViewCtrl refresh:newRect pageIndex:annot.pageIndex needRender:YES];
}

- (void)addAnnot:(FSAnnot *)annot {
    [self addAnnot:annot addUndo:YES];
}

- (void)addAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    int pageIndex = annot.pageIndex;
    FSPDFPage *page = [annot getPage];
    if (addUndo) {
        [_extensionsManager addUndoItem:[UndoAddAnnot createWithAttributes:[FSAnnotAttributes attributesWithAnnot:annot] page:page annotHandler:self]];
    }

    [_extensionsManager onAnnotAdded:page annot:annot];
    CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
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
    if ([annot canModify] && addUndo) {
        annot.modifiedDate = [NSDate date];
        [_extensionsManager addUndoItem:[UndoModifyAnnot createWithOldAttributes:self.attributesBeforeModify newAttributes:[FSAnnotAttributes attributesWithAnnot:annot] pdfViewCtrl:_pdfViewCtrl page:page annotHandler:self]];
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
        FSAnnotAttributes *attributes = self.attributesBeforeModify ?: [FSAnnotAttributes attributesWithAnnot:annot];
        [_extensionsManager addUndoItem:[UndoDeleteAnnot createWithAttributes:attributes page:page annotHandler:self]];
    }
    self.attributesBeforeModify = nil;

    [_extensionsManager onAnnotDeleted:page annot:annot];
    [page removeAnnot:annot];

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
        [self openAttachment:(FSFileAttachment *) annot];
        return YES;
    }
    return NO;
}

- (void)openAttachment:(FSFileAttachment *)annot {
    if (![annot getFileSpec]) {
        return;
    }
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSString *attachmentPath = [Utility getAttachmentTempFilePath:annot];
    if ([Utility isSupportFormat:attachmentPath]) {
        AttachmentController *attachmentCtr = [[AttachmentController alloc] init];

        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:attachmentCtr
                                         animated:YES
                                       completion:^{
                                           [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
                                           dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
                                           dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {

                                               if (![defaultManager fileExistsAtPath:attachmentPath]) {
                                                   [Utility loadAttachment:annot toPath:attachmentPath];
                                               }
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   AttachmentItem *attachmentItem = [AttachmentItem itemWithAttachmentAnnotation:annot];
                                                   attachmentItem.currentlevel = 1;
                                                   attachmentItem.isSecondLevel = YES;
                                                   
                                                   [attachmentCtr openDocument:attachmentItem];
                                               });
                                           });

                                       }];
    } else {
        if (![defaultManager fileExistsAtPath:attachmentPath]) {
            if (![Utility loadAttachment:annot toPath:attachmentPath]) {
                return;
            }
        }
        NSURL *urlFile = [NSURL fileURLWithPath:attachmentPath isDirectory:NO];
        self.documentPopoverController = [UIDocumentInteractionController interactionControllerWithURL:urlFile];
        self.documentPopoverController.delegate = self;
        BOOL isPresent = NO;
        if (DEVICE_iPHONE) {
            isPresent = [self.documentPopoverController presentOpenInMenuFromRect:_pdfViewCtrl.frame inView:_pdfViewCtrl animated:YES];
        } else {
            int pageIndex = annot.pageIndex;
            CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:pageIndex];
            isPresent = [self.documentPopoverController presentOpenInMenuFromRect:dvRect inView:_pdfViewCtrl animated:YES];
        }
        if (!isPresent) {
            NSString *fileName = [[annot getFileSpec] getFileName];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed to open attachment '%@'.", fileName] message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    if (_extensionsManager.currentAnnot != annot) {
        return NO;
    }

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        if ([_extensionsManager.menuControl isMenuVisible]) {
            [_extensionsManager.menuControl hideMenu];
        }
        if (_extensionsManager.propertyBar.isShowing && self.isShowStyle) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
        CGPoint translationPoint = [recognizer translationInView:pageView];
        [recognizer setTranslation:CGPointZero inView:pageView];
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
        if (!(newRect.origin.x <= 0 || newRect.origin.x + newRect.size.width >= pageView.bounds.size.width || newRect.origin.y <= 0 || newRect.origin.y + newRect.size.height >= pageView.bounds.size.height)) {
            rect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:pageIndex];
            annot.fsrect = rect;
            CGRect unionRect = CGRectUnion(newRect, realRect);
            [_pdfViewCtrl refresh:CGRectInset(unionRect, -30, -30) pageIndex:pageIndex needRender:NO];
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (annot.canModify) {
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
            [_extensionsManager.menuControl setRect:showRect];
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
        if (self.annotImage && _extensionsManager.currentAnnot == annot) {
            CGRect annotRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            annotRect.origin.x = rect.origin.x;
            annotRect.origin.y = rect.origin.y;

            CGRect drawRect = annotRect;
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, drawRect.origin.x, drawRect.origin.y);
            CGContextTranslateCTM(context, 0, drawRect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, -drawRect.origin.x, -drawRect.origin.y);
            CGContextDrawImage(context, drawRect, [self.annotImage CGImage]);

            CGContextRestoreGState(context);

            drawRect = CGRectMake(ceilf(drawRect.origin.x), ceilf(drawRect.origin.y), ceilf(drawRect.size.width), ceilf(drawRect.size.height));
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
    if (DEVICE_iPHONE && _extensionsManager.currentAnnot == self.editAnnot) {
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

- (BOOL)onTap:(UITapGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onLongPress:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

- (void)onScrollViewWillBeginDragging:(UIScrollView *)scrollView {
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
    [self showAnnotMenu];
}

- (void)showAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:_extensionsManager.currentAnnot.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.editAnnot.pageIndex];

        if (CGRectIsEmpty(showRect) || CGRectIsNull(CGRectIntersection(showRect, [[_pdfViewCtrl getDisplayView] bounds])))
            return;

        if (/*!DEVICE_iPHONE && */ self.shouldShowPropety) {
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        } else if (self.shouldShowMenu) {
            MenuControl *annotMenu = _extensionsManager.menuControl;
            [annotMenu setRect:showRect];
            [annotMenu showMenu];
        }
    }
}

- (void)dismissAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }

        {
            if (_extensionsManager.propertyBar.isShowing /* && !DEVICE_iPHONE*/) {
                [_extensionsManager.propertyBar dismissPropertyBar];
            }
        }
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
