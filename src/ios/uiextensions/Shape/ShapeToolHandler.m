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

#import "ShapeToolHandler.h"
#import "Utility.h"
#import "FSAnnotExtent.h"

@interface ShapeToolHandler ()

@property (nonatomic, retain) FSPointF* startPoint;
@property (nonatomic, retain) FSPointF* endPoint;
@property (nonatomic, retain) FSAnnot *annot;

@end

@implementation ShapeToolHandler {
    UIExtensionsManager* _extensionsManager;
    FSPDFViewCtrl* _pdfViewCtrl;
    TaskServer* _taskServer;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [_extensionsManager registerToolHandler:self];
        _taskServer = _extensionsManager.taskServer;
        _type = e_annotCircle;
    }
    return self;
}

-(void)dealloc
{
    [_startPoint release];
    [_endPoint release];
    [_annot release];
    [super dealloc];
}

-(NSString*)getName
{
    return Tool_Shape;
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
    
}


// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer
{
    return NO;
}

#define DEFAULT_RECT_WIDTH 200

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    
    float defaultRectWidth = [Utility convertWidth:DEFAULT_RECT_WIDTH fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];
    CGPoint startPoint = CGPointMake(point.x - defaultRectWidth/2, point.y + defaultRectWidth/2);
    CGPoint endPoint = CGPointMake(point.x + defaultRectWidth/2, point.y - defaultRectWidth/2);

    
    self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:startPoint pageIndex:pageIndex];
    self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:endPoint pageIndex:pageIndex];
    FSRectF* dibRect = nil;
    
    dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
    float marginX = [Utility getAnnotMinXMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
    float marginY = [Utility getAnnotMinYMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    float pdfWidth = [page getWidth];
    float pdfHeight = [page getHeight];
    
    if (pdfHeight - dibRect.top < 0) {
        dibRect.bottom += pdfHeight - dibRect.top - marginY;
        dibRect.top = pdfHeight - marginY;
    }
    if (dibRect.bottom < 0) {
        dibRect.top += - dibRect.bottom + marginY;
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
    
    FSAnnot* annot = [self addAnnotToPage:pageIndex withRect:dibRect];
    if (!annot) {
        return YES;
    }
    [annot resetAppearanceStream];
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        [_extensionsManager onAnnotAdded:page annot:annot];
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
        rect = CGRectInset(rect, -20, -20);
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    };
    [_extensionsManager.taskServer executeSync:task];
    
    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGRect rect = [pageView frame];
    CGSize size = rect.size;
    if(point.x > size.width || point.y > size.height ||point.x < 0 ||point.y < 0)
        return NO;
    
    FSPointF* dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSRectF* dibRect = nil;
    if (self.startPoint && self.endPoint) {
        dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
    } else {
        dibRect = [[[FSRectF alloc] init] autorelease];
        [dibRect set:dibPoint.x bottom:dibPoint.y right:dibPoint.x+0.1 top:dibPoint.y+0.1];
    }
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        self.annot = [self addAnnotToPage:pageIndex withRect:dibRect];
        if (!self.annot) {
            return YES;
        }
        
        self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if (pageIndex != self.annot.pageIndex) {
            return NO;
        }
        FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
        float marginX = [Utility getAnnotMinXMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
        float marginY = [Utility getAnnotMinYMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
        
        if (dibPoint.x < marginX || dibPoint.y > [page getHeight] - marginY || dibPoint.y < marginY || dibPoint.x > [page getWidth] - marginX) {
            return NO;
        }
        self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        
        self.annot.fsrect = dibRect;
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
        rect = CGRectInset(rect, -10, -10);
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
        
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        if (self.annot) {
            [self.annot resetAppearanceStream];
            [_extensionsManager onAnnotAdded:[self.annot getPage] annot:self.annot];
        }
        return YES;
    }
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
    return YES;
}


- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet*)touches withEvent:(UIEvent*)event
{
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
}

- (FSAnnot*)addAnnotToPage:(int)pageIndex withRect:(FSRectF*)rect
{
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page) return nil;
    
    FSAnnot* annot = [page addAnnot:self.type rect:rect];
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.color = [_extensionsManager getPropertyBarSettingColor:self.type];
    annot.opacity = [_extensionsManager getAnnotOpacity:self.type] / 100.0f;
    annot.lineWidth = [_extensionsManager getAnnotLineWidth:self.type];
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    if (self.type == e_annotCircle)
    {
        annot.subject = @"Circle";
    }
    else if (self.type == e_annotSquare)
    {
        annot.subject = @"Rectangle";
    }
    annot.flags = e_annotFlagPrint;
    return annot;
}

@end
