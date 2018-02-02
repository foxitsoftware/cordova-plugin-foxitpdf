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

#import "ShapeToolHandler.h"
#import "FSAnnotExtent.h"
#import "Utility.h"

@interface ShapeToolHandler ()

@property (nonatomic, strong) FSPointF *startPoint;
@property (nonatomic, strong) FSPointF *endPoint;
@property (nonatomic, strong) FSAnnot *annot;

@end

@implementation ShapeToolHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        _type = e_annotCircle;
    }
    return self;
}

- (NSString *)getName {
    return Tool_Shape;
}

- (BOOL)isEnabled {
    return YES;
}

- (void)onActivate {
}

- (void)onDeactivate {
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

#define DEFAULT_RECT_WIDTH 200

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];

    float defaultRectWidth = [Utility convertWidth:DEFAULT_RECT_WIDTH fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];
    CGPoint startPoint = CGPointMake(point.x - defaultRectWidth / 2, point.y + defaultRectWidth / 2);
    CGPoint endPoint = CGPointMake(point.x + defaultRectWidth / 2, point.y - defaultRectWidth / 2);

    self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:startPoint pageIndex:pageIndex];
    self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:endPoint pageIndex:pageIndex];
    FSRectF *dibRect = nil;

    dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
    float marginX = [Utility getAnnotMinXMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
    float marginY = [Utility getAnnotMinYMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    float pdfWidth = [page getWidth];
    float pdfHeight = [page getHeight];

    if (pdfHeight - dibRect.top < 0) {
        dibRect.bottom += pdfHeight - dibRect.top - marginY;
        dibRect.top = pdfHeight - marginY;
    }
    if (dibRect.bottom < 0) {
        dibRect.top += -dibRect.bottom + marginY;
        dibRect.bottom = marginY;
    }
    if (pdfWidth - dibRect.right < 0) {
        dibRect.left += pdfWidth - dibRect.right - marginX;
        dibRect.right = pdfWidth - marginX;
    }
    if (dibRect.left < 0) {
        dibRect.right += -dibRect.left + marginX;
        dibRect.left = marginX;
    }

    FSAnnot *annot = [self addAnnotToPage:pageIndex withRect:dibRect];
    if (!annot) {
        return YES;
    }
    [annot resetAppearanceStream];

    id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByType:self.type];
    @try {
        [annotHandler addAnnot:annot addUndo:YES];
    } @catch (NSException *exception) {
    } @finally {
    }

    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGRect rect = [pageView frame];
    CGSize size = rect.size;
    if (point.x > size.width || point.y > size.height || point.x < 0 || point.y < 0)
        return NO;

    FSPointF *dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSRectF *dibRect = nil;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        dibRect = [[FSRectF alloc] init];
        [dibRect set:dibPoint.x bottom:dibPoint.y right:dibPoint.x + 0.1 top:dibPoint.y + 0.1];
        
        self.annot = [self addAnnotToPage:pageIndex withRect:dibRect];
        if (!self.annot) {
            return YES;
        }
        
        self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        self.endPoint   = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (pageIndex != self.annot.pageIndex) {
            return NO;
        }
        FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
        float marginX = [Utility getAnnotMinXMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
        float marginY = [Utility getAnnotMinYMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
        FSRotation rotation = [page getRotation];
        CGFloat pdfPageWidth = (rotation == e_rotation0 || rotation == e_rotation180 || rotation == e_rotationUnknown) ? [page getWidth] : [page getHeight];
        CGFloat pdfPageHeight = (rotation == e_rotation0 || rotation == e_rotation180 || rotation == e_rotationUnknown) ? [page getHeight] : [page getWidth];
        if (dibPoint.x < marginX || dibPoint.y > pdfPageHeight - marginY || dibPoint.y < marginY || dibPoint.x > pdfPageWidth - marginX) {
            return NO;
        }
        self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        
        dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
        
        self.annot.fsrect = dibRect;
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
        rect = CGRectInset(rect, -10, -10);
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];

    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (self.annot) {
            [self.annot resetAppearanceStream];
            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByType:self.type];
            @try {
                [annotHandler addAnnot:self.annot addUndo:YES];
            } @catch (NSException *exception) {
            } @finally {
            }
        }
        return YES;
    }
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
    return YES;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
}

- (FSAnnot *)addAnnotToPage:(int)pageIndex withRect:(FSRectF *)rect {
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page)
        return nil;

    FSAnnot *annot = nil;
    @try {
        annot = [page addAnnot:self.type rect:rect];
    } @catch (NSException *exception) {
    } @finally {
    }
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.color = [_extensionsManager getPropertyBarSettingColor:self.type];
    annot.opacity = [_extensionsManager getAnnotOpacity:self.type] / 100.0f;
    annot.lineWidth = [_extensionsManager getAnnotLineWidth:self.type];
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    if (self.type == e_annotCircle) {
        annot.subject = @"Circle";
    } else if (self.type == e_annotSquare) {
        annot.subject = @"Rectangle";
    }
    annot.flags = e_annotFlagPrint;
    return annot;
}

@end
