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

#import "PolygonToolHandler.h"
#import "FSAnnotExtent.h"
#import "Utility.h"

@interface PolygonToolHandler ()

@property (nonatomic, strong) NSMutableArray<FSPointF *> *vertexes;
@property (nonatomic, strong) UIImage *annotImage;

@end

@implementation PolygonToolHandler {
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
        _type = e_annotPolygon;
        _vertexes = @[].mutableCopy;
        _annot = nil;
        _annotImage = nil;
        _minVertexDistance = 5;
    }
    return self;
}

- (NSString *)getName {
    return Tool_Polygon;
}

- (BOOL)isEnabled {
    return YES;
}

- (void)onActivate {
}

- (void)onDeactivate {
    if (self.annot) {
        FSPolygon *annot = self.annot;
        self.annot = nil;
        self.annotImage = nil;
        [self.vertexes removeAllObjects];
        int pageIndex = annot.pageIndex;
        id<IAnnotHandler> annothandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
        [annothandler addAnnot:annot addUndo:YES];
        CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        [_pdfViewCtrl refresh:CGRectInset(pvRect, -30, -30) pageIndex:pageIndex needRender:YES];
    } else if (self.vertexes.count == 1) {
        int pageIndex = [_pdfViewCtrl getCurrentPage];
        CGPoint vertex = [_pdfViewCtrl convertPdfPtToPageViewPt:self.vertexes.firstObject pageIndex:pageIndex];
        [_pdfViewCtrl refresh:CGRectInset(CGRectMake(vertex.x, vertex.y, 0, 0), -30, -30) pageIndex:pageIndex needRender:NO];
        [self.vertexes removeAllObjects];
    }
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)isVertexValid:(CGPoint)vertex pageIndex:(int)pageIndex {
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGRect validRect = CGRectInset(pageView.bounds, 5, 5);
    if (!CGRectContainsPoint(validRect, vertex)) {
        return NO;
    }
    if (self.vertexes.count > 0) {
        CGPoint lastPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.vertexes.lastObject pageIndex:pageIndex];
        CGFloat dx = lastPoint.x - vertex.x;
        CGFloat dy = lastPoint.y - vertex.y;
        if (dx * dx + dy * dy < self.minVertexDistance * self.minVertexDistance) {
            return NO;
        }
    }
    return YES;
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
    if (self.annot && self.annot.pageIndex != pageIndex) {
        return;
    }
    if (self.annotImage) {
        CGRect annotRect = [Utility getAnnotRect:self.annot pdfViewCtrl:_pdfViewCtrl];
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.annot.fsrect pageIndex:pageIndex];
        annotRect.origin.x = rect.origin.x;
        annotRect.origin.y = rect.origin.y;
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, annotRect.origin.x, annotRect.origin.y);
        CGContextTranslateCTM(context, 0, annotRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, -annotRect.origin.x, -annotRect.origin.y);
        CGContextDrawImage(context, annotRect, [self.annotImage CGImage]);
        CGContextRestoreGState(context);
    }
    UIImage *dot = [UIImage imageNamed:@"annotation_drag.png"];
    UIImage *highlightDot = [UIImage imageNamed:@"annotation_drag_highlight.png"];
    CGSize dotSize = dot.size;
    [self.vertexes enumerateObjectsUsingBlock:^(FSPointF *_Nonnull vertex, NSUInteger idx, BOOL *_Nonnull stop) {
        CGPoint point = [_pdfViewCtrl convertPdfPtToPageViewPt:vertex pageIndex:pageIndex];
        if (idx == 0) {
            point.x -= highlightDot.size.width / 2;
            point.y -= highlightDot.size.height / 2;
            [highlightDot drawAtPoint:point];
        } else {
            point.x -= dotSize.width / 2;
            point.y -= dotSize.height / 2;
            [dot drawAtPoint:point];
        }
    }];
}

- (void)updateAnnotInPage:(int)pageIndex {
    if (self.annot == nil && self.vertexes.count > 1) {
        self.annot = [self addAnnotToPage:pageIndex];
    }
    if (self.annot) {
        [self.annot setVertexes:self.vertexes];
        [self.annot resetAppearanceStream];
        self.annotImage = [Utility getAnnotImage:self.annot pdfViewCtrl:_pdfViewCtrl];
        CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.annot.fsrect pageIndex:pageIndex];
        [_pdfViewCtrl refresh:CGRectInset(pvRect, -30, -30) pageIndex:pageIndex needRender:NO];
    } else if (self.vertexes.count == 1) {
        CGPoint vertex = [_pdfViewCtrl convertPdfPtToPageViewPt:self.vertexes.firstObject pageIndex:pageIndex];
        [_pdfViewCtrl refresh:CGRectInset(CGRectMake(vertex.x, vertex.y, 0, 0), -30, -30) pageIndex:pageIndex needRender:NO];
    }
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer {
    if (self.annot && self.annot.pageIndex != pageIndex) {
        return YES;
    }
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    if (![self isVertexValid:point pageIndex:pageIndex]) {
        return YES;
    }
    [self.vertexes addObject:[_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex]];
    [self updateAnnotInPage:pageIndex];
    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    return NO;
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

- (FSPolygon *)addAnnotToPage:(int)pageIndex {
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page)
        return nil;

    FSPolygon *annot = nil;
    FSRectF *rect = [[FSRectF alloc] init];
    [rect set:0 bottom:0 right:0 top:0];
    @try {
        annot = (FSPolygon *) [page addAnnot:self.type rect:rect];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
        return nil;
    }
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.color = [_extensionsManager getPropertyBarSettingColor:self.type];
    annot.opacity = [_extensionsManager getAnnotOpacity:self.type] / 100.0f;
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    annot.flags = e_annotFlagPrint;
    [annot setBorderInfo:({
               FSBorderInfo *borderInfo = [[FSBorderInfo alloc] init];
               [borderInfo setWidth:[_extensionsManager getAnnotLineWidth:self.type]];
               if (self.isPolygon) {
                   [borderInfo setStyle:e_borderStyleSolid];
               } else {
                   [borderInfo setStyle:e_borderStyleCloudy];
                   [borderInfo setCloudIntensity:2.0];
               }
               borderInfo;
           })];
    if (!self.isPolygon) {
        annot.intent = @"PolygonCloud";
    }
    return annot;
}

@end
