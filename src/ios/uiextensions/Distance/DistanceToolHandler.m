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

#import "DistanceToolHandler.h"
#import "FSAnnotExtent.h"
#import "UIExtensionsManager+Private.h"
#import "Utility.h"
#define DEFAULT_RECT_WIDTH 200

@interface DistanceToolHandler ()

@property (nonatomic, strong) FSPointF *startPoint;
@property (nonatomic, strong) FSPointF *endPoint;
@property (nonatomic, strong) FSLine *annot;
@property (nonatomic, assign) int currentPageIndex;
@property (nonatomic, strong) NSString *currentUnit;

@end

@implementation DistanceToolHandler {
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
        _type = e_annotLine;
        
        [_extensionsManager registerAnnotEventListener:self];
    }
    return self;
}

- (void)setStartPoint:(FSPointF *)startPoint {
    _startPoint = startPoint;
}

- (NSString *)getName {
    return Tool_Distance;
}

- (BOOL)isEnabled {
    return YES;
}

- (void)onActivate {
}

- (void)onDeactivate {
    [self releaseData];
    if(self.annot)
    {
        FSAnnot* annot = self.annot;
        self.annot = nil;
        id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
        [annotHandler addAnnot:annot addUndo:YES];
    }
}

-(void)releaseData{
    if (self.currentPageIndex) {
        [_pdfViewCtrl refresh:self.currentPageIndex];
    }
    self.startPoint = nil;
    self.endPoint = nil;
    self.annot = nil;
    self.currentPageIndex = -1;
}
#pragma mark PageView Gesture+Touch

- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
    
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    if (point.x > pageView.frame.size.width || point.y > pageView.frame.size.height || point.x < 0 || point.y < 0)
        return NO;
    FSPointF *dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSRectF *dibRect = [[FSRectF alloc] init];
    
    if (self.startPoint && self.endPoint) {
        dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
    } else {
        [dibRect set:dibPoint.x bottom:dibPoint.y right:dibPoint.x + 0.1 top:dibPoint.y + 0.1];
    }
    
    void (^end)() = ^() {
        FSAnnot* annot = self.annot;
        self.annot = nil;
        id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
        [annotHandler addAnnot:annot addUndo:YES];
        [self updateDistanceDataFromStartPoint:self.startPoint toEndPoint:self.endPoint];
    };
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if(self.annot)
            end();
        
        self.currentPageIndex = pageIndex;
        FSLine *annot = [self addAnnotToPage:pageIndex withRect:dibRect];
        if (!annot) {
            return NO;
        }
        self.annot = (FSLine *) annot;
        [annot setLineStartingStyle:@"OpenArrow"];
        [annot setLineEndingStyle:@"OpenArrow"];
        self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        
        FSLine *line = (FSLine *) self.annot;
        [line setStartPoint:self.startPoint];
        [line setEndPoint:self.endPoint];
        [annot resetAppearanceStream];
        [_pdfViewCtrl refresh:pageIndex];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (pageIndex != self.annot.pageIndex) {
            end();
            return NO;
        }

        FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        float marginX = [Utility getAnnotMinXMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
        float marginY = [Utility getAnnotMinYMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
        FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
        FSRectF* pageBox = [Utility getPageBoundary:page];
        FSRectF* deflateRect = [Utility inflateFSRect:pageBox width:-marginX height:-marginY];
        if(![Utility isPointInFSRect:deflateRect point:pdfPoint])
        {
            end();
            return NO;
        }

        self.endPoint = dibPoint;
        [self.annot setEndPoint:dibPoint];
        [self.annot resetAppearanceStream];
        FSRectF *pdfRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
        //self.annot.fsrect = dibRect;
        
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:pdfRect pageIndex:pageIndex];
        rect = CGRectInset(rect, -100, -20);
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
        [self updateDistanceDataFromStartPoint:self.startPoint toEndPoint:self.endPoint];
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if ([Utility pointEqualToPoint:self.startPoint point:self.endPoint]) {
            FSAnnot* annot = self.annot;
            self.annot = nil;
            [self removeAnnot:annot];
            [_pdfViewCtrl refresh:self.currentPageIndex];
            return NO;
        }
        FSLine *annot1 = (FSLine *) self.annot;
        [annot1 setStartPoint:self.startPoint];
        [annot1 setEndPoint:self.endPoint];
        [annot1 resetAppearanceStream];
        end();
        return YES;
    }
    return NO;
}

- (void)removeAnnot:(FSAnnot *)annot {
    FSPDFPage *page = [annot getPage];
    [page removeAnnot:annot];
    
    self.annot = nil;
}

- (FSLine *)addAnnotToPage:(int)pageIndex withRect:(FSRectF *)rect {
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page)
        return nil;

    FSLine *annot = (FSLine *) [page addAnnot:self.type rect:rect];
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.color = [_extensionsManager getPropertyBarSettingColor:self.type];
    annot.opacity = [_extensionsManager getAnnotOpacity:self.type] / 100.0f;
    annot.lineWidth = [_extensionsManager getAnnotLineWidth:self.type];
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    [annot setIntent:@"LineDimension"];
    
    [annot setMeasureRatio:_extensionsManager.distanceUnit];
    
    NSArray *result = [Utility getDistanceUnitInfo:_extensionsManager.distanceUnit];
    _currentUnit = [result objectAtIndex:3];
    [annot setMeasureUnit:0 unit:[result objectAtIndex:3]];
    [annot setMeasureConversionFactor:0 factor:[[result objectAtIndex:2] floatValue]/[[result objectAtIndex:0] floatValue]];
    
    [annot setContent:@""];
    annot.flags = e_annotFlagPrint;
    return annot;
}

-(void)updateDistanceDataFromStartPoint:(FSPointF *)start toEndPoint:(FSPointF *)end {
    float distance = [Utility getDistanceFromX:start toY:end withUnit:_extensionsManager.distanceUnit];
    NSString *distanceContent = [NSString stringWithFormat:@"%.2f%@",distance,_currentUnit];
    [self.annot setContent:distanceContent];
    
    [_pdfViewCtrl refresh:self.currentPageIndex];
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
    return YES;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (void)onAnnotWillDelete:(FSPDFPage *)page annot:(FSAnnot *)annot {
    FSLine *lineAnnot = (FSLine *)annot;
    if (annot.type == e_annotLine && [[lineAnnot getIntent] isEqualToString:@"LineDimension"]) {
        [self releaseData];
    }
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
    if (self.annot != nil && self.startPoint && self.endPoint && self.currentPageIndex == pageIndex && ![Utility pointEqualToPoint:self.startPoint point:self.endPoint]) {
        CGPoint startPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.startPoint  pageIndex:pageIndex];
        
        UIFont* font = [UIFont fontWithName: @"Helvetica" size: 12];
        NSMutableParagraphStyle* textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
        textStyle.alignment = NSTextAlignmentLeft;
        NSDictionary* textFontAttributes = @{
                                             NSFontAttributeName: font,
                                             NSForegroundColorAttributeName: UIColor.redColor,
                                             NSParagraphStyleAttributeName: textStyle
                                             };
        float distance = [Utility getDistanceFromX:self.startPoint toY:self.endPoint withUnit:_extensionsManager.distanceUnit];
        NSString *distanceContent = [NSString stringWithFormat:@"%.2f%@",distance,_currentUnit];
        [distanceContent drawAtPoint:startPoint withAttributes:textFontAttributes];
    }
}

@end
