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

#import "LineToolHandler.h"

#import "Utility.h"
#import "FSAnnotExtent.h"
#define DEFAULT_RECT_WIDTH 200

@interface LineToolHandler ()

@property (nonatomic, retain) FSPointF* startPoint;
@property (nonatomic, retain) FSPointF* endPoint;
@property (nonatomic, retain) FSLine *annot;

@end

@implementation LineToolHandler
{
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
        _type = e_annotLine;
        _isArrowLine = NO;
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

- (void)setStartPoint:(FSPointF*)startPoint
{
    [startPoint retain];
    [_startPoint release];
    _startPoint = startPoint;
}

-(NSString*)getName
{
    return Tool_Line;
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

#pragma mark PageView Gesture+Touch

- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer
{
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer
{
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page) {
        return NO;
    }
    
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    float defaultRectWidth = [Utility convertWidth:DEFAULT_RECT_WIDTH fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];
    CGPoint startPoint = CGPointMake(point.x - defaultRectWidth/2, point.y + defaultRectWidth/2);
    CGPoint endPoint = CGPointMake(point.x + defaultRectWidth/2, point.y - defaultRectWidth/2);
    
    float marginX = 5.0;
    float marginY = 5.0;
    float maxX = pageView.frame.size.width - marginX;
    float maxY = pageView.frame.size.height - marginY;
    
    if (point.x < marginX || point.x > maxX || point.y < marginY || point.y > maxY) {
        return YES;
    }
    
    float tempStart = 0.0;
    float tempEnd = 0.0;
    if (startPoint.x < marginX){
        tempStart = tempEnd = marginX - startPoint.x;
        if (endPoint.y - tempEnd < marginY) {
            tempEnd = endPoint.y - marginY;
        }
    }
    if (startPoint.y > maxY && point.x + point.y > maxY){
        tempStart = tempEnd = startPoint.y - maxY;
        if (endPoint.x + tempEnd > maxX) {
            tempEnd = maxX - endPoint.x;
        }
    }
    if (endPoint.x > maxX){
        tempStart = tempEnd = maxX - endPoint.x;
        if (startPoint.y - tempEnd > maxY) {
            tempStart = startPoint.y - maxY;
        }
    }
    if (endPoint.y < marginY && point.x + point.y < maxX){
        tempStart = tempEnd = endPoint.y - marginY;
        if (startPoint.x + tempEnd < marginX) {
            tempStart = marginX - startPoint.x;
        }
    }
    startPoint.x += tempStart;
    startPoint.y -= tempStart;
    endPoint.x += tempEnd;
    endPoint.y -= tempEnd;
    
    
    self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:startPoint pageIndex:pageIndex];
    self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:endPoint pageIndex:pageIndex];
    
    FSRectF* dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
    FSLine* annot = (FSLine*)[self addAnnotToPage:pageIndex withRect:dibRect];
    if (!annot) {
        return YES;
    }
    [annot setStartPoint:self.startPoint];
    [annot setEndPoint:self.endPoint];
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
    if (_extensionsManager.currentToolHandler != self) {
        return NO;
    }
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGRect rect = [pageView frame];
    CGSize size = rect.size;
    if(point.x > size.width || point.y > size.height ||point.x < 0 ||point.y < 0)
        return NO;
    FSPointF* dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSRectF* dibRect = [[[FSRectF alloc] init] autorelease];
    if (self.startPoint && self.endPoint) {
        dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
    } else {
        [dibRect set:dibPoint.x bottom:dibPoint.y right:dibPoint.x+0.1 top:dibPoint.y+0.1];
    }
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        FSAnnot* annot = [self addAnnotToPage:pageIndex withRect:dibRect];
        if (!annot) {
            return YES;
        }
        self.annot = (FSLine*)annot;
        if (_isArrowLine) {
           [annot setLineEndingStyle:@"OpenArrow"];
        }
        self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        FSLine* line = (FSLine*) self.annot;
        [line setStartPoint:self.startPoint];
        [line setEndPoint:self.endPoint];
        [annot resetAppearanceStream];
       
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if (pageIndex != self.annot.pageIndex) {
            return NO;
        }

        FSPointF* dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        float marginX = [Utility getAnnotMinXMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
        float marginY = [Utility getAnnotMinYMarginInPDF:_pdfViewCtrl pageIndex:pageIndex];
        FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
        
        if (dibPoint.x < marginX || dibPoint.y > [page getHeight] - marginY || dibPoint.y < marginY || dibPoint.x > [page getWidth] - marginX) {
            return NO;
        }
        self.endPoint = dibPoint;
        FSLine* line = (FSLine*) self.annot;
        [line setEndPoint:dibPoint];
        [self.annot resetAppearanceStream];
        FSRectF* dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
        self.annot.fsrect = dibRect;
        
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
        rect = CGRectInset(rect, -20, -20);
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];

    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        FSLine* annot1 = (FSLine*)self.annot;
        [annot1 setStartPoint:self.startPoint];
        [annot1 setEndPoint:self.endPoint];
        [annot1 setFsrect:[Utility convertToFSRect:self.startPoint p2:self.endPoint]];
        
        Task *task = [[[Task alloc] init] autorelease];
        task.run = ^(){
            [_extensionsManager onAnnotAdded:[self.annot getPage] annot:annot1];
            FSRectF* dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
            rect = CGRectInset(rect, -20, -20);
            self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:CGPointZero pageIndex:pageIndex];
            self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:CGPointZero pageIndex:pageIndex];
            
           [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
            double delayInSeconds = .1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
            });
       };
        [_extensionsManager.taskServer executeSync:task];
    }
}


- (FSAnnot*)addAnnotToPage:(int)pageIndex withRect:(FSRectF*)rect
{
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page) return nil;
    
    FSLine* annot = (FSLine*)[page addAnnot:self.type rect:rect];
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.color = [_extensionsManager getPropertyBarSettingColor:self.type];
    annot.opacity = [_extensionsManager getAnnotOpacity:self.type] / 100.0f;
    annot.lineWidth = [_extensionsManager getAnnotLineWidth:self.type];
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    if (!_isArrowLine)
    {
        annot.subject = @"Line";
    }
    else if (_isArrowLine)
    {
        [annot setIntent:@"LineArrow"];
        annot.subject = @"ArrowLine";
    }
    annot.flags = e_annotFlagPrint;
    return annot;
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
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return NO;
}

-(CGPoint)rotateVec:(float)px py:(float)py ang:(float)ang isChlen:(BOOL)isChlen newLine:(float)newLen
{
    CGPoint point = CGPointMake(0, 0);
    float vx = px * cosf(ang) - py * sinf(ang);
    float vy = px * sinf(ang) + py * cosf(ang);
    if (isChlen) {
        float d = sqrtf(vx * vx + vy * vy);
        vx = vx / d * newLen;
        vy = vy / d * newLen;
        point.x = vx;
        point.y = vy;
    }
    return point;
}
@end
