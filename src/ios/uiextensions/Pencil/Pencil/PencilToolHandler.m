/**
 * Copyright (C) 2003-2016, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 
 */
#import "PencilToolHandler.h"
#import "PencilAnnotHandler.h"
#import "UIExtensionsManager+Private.h"
#import "FSAnnotExtent.h"

@interface PencilToolHandler ()

@property (nonatomic, retain) FSInk *annot;
@property (nonatomic, assign) BOOL isMoving;
@property (nonatomic, assign) BOOL isZooming;
@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) CGRect lastRect;
@property (nonatomic, assign) BOOL isBegin;

@end

@implementation PencilToolHandler {
    UIExtensionsManager* _extensionsManager;
    FSPDFViewCtrl*  _pdfViewCtrl;
    TaskServer* _taskServer;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        [_extensionsManager registerToolHandler:self];
        [_extensionsManager registerPropertyBarListener:self];
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        _type = e_annotInk;
    }
    return self;
}

-(NSString*)getName
{
    return Tool_Pencil;
}

-(BOOL)isEnabled
{
    return YES;
}

-(void)onActivate
{
}

-(void)onDeactivate
{
    self.annot = nil;
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer
{
    return YES;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer
{
    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer
{
    return YES;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (FSInk*)createInkAnnotationInPage:(int)pageIndex atPos:(FSPointF*)pos
{
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page) return;
    
    CGRect rect = CGRectMake(pos.x - 20, pos.y - 20, 40, 40);
    FSInk* annot = (FSInk*)[page addAnnot:e_annotInk rect:[Utility CGRect2FSRectF:rect]];
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.color = [_extensionsManager getPropertyBarSettingColor:self.type];
    annot.opacity = [_extensionsManager getAnnotOpacity:self.type]/100.0;
    annot.lineWidth = [_extensionsManager getAnnotLineWidth:self.type];
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    annot.flags = e_annotFlagPrint;
    
    FSPDFPath* path = [FSPDFPath create];
    [path moveTo:pos];
    [annot setInkList:path];
    [annot resetAppearanceStream];
    return annot;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet*)touches withEvent:(UIEvent*)event
{
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [[touches anyObject] locationInView:pageView];
    if (point.x < 10 || point.x > pageView.bounds.size.width - 10 ||
        point.y < 10 || point.y > pageView.bounds.size.height - 10) {
        return NO;
    }
    
    _isBegin = YES;
    _isMoving = YES;
    
    FSPointF* dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    
    if (self.annot == nil)  //this is the first line
    {
        self.annot = [self createInkAnnotationInPage:pageIndex atPos:dibPoint];
        [_extensionsManager onAnnotAdded:[_pdfViewCtrl.currentDoc getPage:self.annot.pageIndex] annot:self.annot];
    }
    else
    {
        if (pageIndex != self.annot.pageIndex) {
            return NO;
        }
        
        FSPDFPath* path = [self.annot getInkList];
        [path moveTo:dibPoint];
        [self.annot setInkList:path];
        [self.annot resetAppearanceStream];
    }
    
    CGRect cgRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.annot.fsrect pageIndex:pageIndex];
    [_pdfViewCtrl refresh:cgRect pageIndex:pageIndex];
    _lastPoint = point;
    return YES;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_isMoving && !_isZooming)
    {
        UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
        CGPoint point = [[touches anyObject] locationInView:pageView];
        if (point.x < 10 || point.x > pageView.bounds.size.width - 10 ||
            point.y < 10 || point.y > pageView.bounds.size.height - 10) {
            return NO;
        }

        if (self.annot == nil)  //this is the first line
        {
            //annotation cannot cross page
            FSPointF* dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
            self.annot = [self createInkAnnotationInPage:pageIndex atPos:dibPoint];
            [_extensionsManager onAnnotAdded:[_pdfViewCtrl.currentDoc getPage:pageIndex] annot:self.annot];
            CGRect cgRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.annot.fsrect pageIndex:pageIndex];
            [_pdfViewCtrl refresh:cgRect pageIndex:pageIndex];
            _lastPoint = point;
            return YES;
        } else {
            if (pageIndex != self.annot.pageIndex) {
                return NO;
            } else {
                FSPointF* dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
                
                FSPDFPath* path = [self.annot getInkList];
                if ([path getPointCount] == 0) {
                    FSPDFPath* path = [FSPDFPath create];
                    [path moveTo:dibPoint];
                    [self.annot setInkList:path];
                    return YES;
                }
                [path lineTo:dibPoint];
                [self.annot setInkList:path];
                [self.annot resetAppearanceStream];
                
                CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.annot.fsrect pageIndex:pageIndex];
                if (CGRectEqualToRect(_lastRect, CGRectZero))
                {
                    _lastRect = pvRect;
                }
                CGRect unionRect = CGRectUnion(_lastRect, pvRect);
                float scale = [_pdfViewCtrl getPageViewWidth:pageIndex] / 1000;
                float margin = self.annot.lineWidth * 3 * scale;
                unionRect = CGRectInset(unionRect, -margin, -margin);
                unionRect = [Utility getStandardRect:unionRect];
                [_pdfViewCtrl refresh:unionRect pageIndex:pageIndex];
                
                _lastRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.annot.fsrect pageIndex:pageIndex];
                _lastPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:dibPoint pageIndex:pageIndex];
                
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_isMoving && self.annot) {
        [_extensionsManager onAnnotModified:[_pdfViewCtrl.currentDoc getPage:pageIndex] annot:self.annot];
    }
    _isBegin = NO;
    _isMoving = NO;
    return YES;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return NO;
}

-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context
{
}

# pragma IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotInk) {
        self.annot = nil;
    }
}

- (void)onAnnotLineWidthChanged:(unsigned int)lineWidth annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotInk) {
        self.annot = nil;
    }
}

- (void)onAnnotOpacityChanged:(unsigned int)opacity annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotInk) {
        self.annot = nil;
    }
}

@end
