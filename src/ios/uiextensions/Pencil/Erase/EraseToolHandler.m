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
#import "EraseToolHandler.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "UIExtensionsManager.h"
#import "UIExtensionsManager+Private.h"
#import "PropertyBar.h"
#import "ColorUtility.h"
#import "FSAnnotExtent.h"

@interface EraseToolHandler ()

@property (nonatomic, retain) NSMutableArray *pencilAnnotationArray;
@property (nonatomic, retain) NSMutableArray *affectedPencilAnnotationArray;
@property (nonatomic, assign) int annotationEditPageIndex;
@property (nonatomic, assign) CGRect currentEditRect;

@end

@implementation EraseToolHandler {
    UIExtensionsManager* _extensionsManager;
    FSPDFViewCtrl*  _pdfViewCtrl;
    TaskServer* _taskServer;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        [_extensionsManager registerToolHandler:self];
        _type = e_annotUnknownType; // todo
        
        self.pencilAnnotationArray = nil;
        self.affectedPencilAnnotationArray = nil;
        _isMoving = NO;
        _isZooming = NO;
        _lastPoint = CGPointZero;
        _isBegin = NO;
        _radius = 0;
        _isChanged = NO;
        _changedPointCount = 0;
        _annotationEditPageIndex = -1;
    }
    return self;
}

-(NSString*)getName
{
    return Tool_Eraser;
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

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer
{
    [_pdfViewCtrl refresh:pageIndex needRender:NO];
    
    _isMoving = NO;
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer
{
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
    
}

- (CGRect)getRectFromPointArray:(NSMutableArray<FSPointF*>*)pointArray
{
    CGFloat greatestXValue = INT32_MIN;
    CGFloat greatestYValue = INT32_MIN;
    CGFloat smallestXValue = INT32_MIN;
    CGFloat smallestYValue = INT32_MIN;
    
    for (FSPointF *point in pointArray)
    {
        float x = point.x;
        float y = point.y;
        if (greatestXValue == INT32_MIN)
        {
            greatestXValue = x;
            greatestYValue = y;
            smallestXValue = x;
            smallestYValue = y;
        }
        else
        {
            greatestXValue = MAX(greatestXValue, x);
            greatestYValue = MAX(greatestYValue, y);
            smallestXValue = MIN(smallestXValue, x);
            smallestYValue = MIN(smallestYValue, y);
        }
    }
    
    CGRect rect;
    rect.origin = CGPointMake(smallestXValue, smallestYValue);
    rect.size.width = greatestXValue - smallestXValue;
    rect.size.height = greatestYValue - smallestYValue;
    
    return rect;
}

- (CGRect)getRectFromPencilAnnotation
{
    CGRect ret = CGRectZero;
    
    for (FSAnnot *annot in self.pencilAnnotationArray)
    {
        CGRect rect = [Utility FSRectF2CGRect:annot.fsrect];
        if (CGRectEqualToRect(ret, CGRectZero))
        {
            ret = rect;
        }
        else
        {
            ret = CGRectUnion(rect, ret);
        }
    }
    
    return ret;
}

- (double)distanceOfTwoPoints:(FSPointF*)point1 point2:(FSPointF*)point2
{
    double dx = point1.x-point2.x;
    double dy = point1.y-point2.y;
    return sqrt(dx*dx + dy*dy);
}

- (BOOL)isInsideCircle:(FSPointF*)point circleCenterPoint:(FSPointF*)circleCenterPoint
{
    double dist = [self distanceOfTwoPoints:point point2:circleCenterPoint];
    if (dist < _radius)
    {
        return YES;
    }
    return NO;
}

- (void)addCenterPoint:(FSPointF*)p1 p2:(FSPointF*)p2 array:(NSMutableArray<FSPointF*>*)array
{
    if ([self distanceOfTwoPoints:p1 point2:p2] > _radius)
    {
        FSPointF* centerPoint = [[FSPointF alloc] init];
        centerPoint.x = (p1.x + p2.x) / 2;
        centerPoint.y = (p1.y + p2.y) / 2;
        
        [array addObject:centerPoint];
        [centerPoint release];
        
        [self addCenterPoint:p1 p2:centerPoint array:array];
        [self addCenterPoint:p2 p2:centerPoint array:array];
    }
}

- (void)getU:(FSPointF*)point1 point2:(FSPointF*)point2 circleCenterPoint:(FSPointF*)point u1:(double*)u1 u2:(double*)u2
{
    double a = (point2.x - point1.x)*(point2.x - point1.x) + (point2.y - point1.y)*(point2.y - point1.y);
    double b = 2 * ((point2.x - point1.x) * (point1.x - point.x) + (point2.y - point1.y) * (point1.y - point.y));
    double c = point.x*point.x + point.y*point.y + point1.x*point1.x + point1.y*point1.y - 2*(point.x * point1.x + point.y * point1.y) - _radius*_radius;
    
    double d = sqrt(b*b - 4 * a *c);
    *u1 = (-b + d)/(2*a);
    *u2 = (-b - d)/(2*a);
}

-(NSMutableArray<NSMutableArray<FSPointF*>*> *)getPointLinesFromInkAnnot:(FSInk*)inkAnnot
{
    NSMutableArray<NSMutableArray<FSPointF*>*> *arrayLines = [NSMutableArray<NSMutableArray<FSPointF*>*> array];
    FSPDFPath* path = [inkAnnot getInkList];
    FSPointF* lastPt = nil;
    for (int i = 0; i < [path getPointCount]; i++)
    {
        FSPointF* pt = [path getPoint:i];
        enum FS_PATHPOINTTYPE type = [path getPointType:i];
        if (type == e_pointTypeMoveTo) {
            [arrayLines addObject:[NSMutableArray<FSPointF*> arrayWithObject:pt]];
        } else {
            if (fabs(lastPt.x - pt.x) > 1e-3 || fabs(lastPt.y - pt.y) > 1e-3) {
                [[arrayLines lastObject] addObject:pt];
            }
        }
        lastPt = pt;
    }
    return arrayLines;
}

static FSPointF* makePoint(float x, float y)
{
    FSPointF* pt = [[[FSPointF alloc] init] autorelease];
    [pt set:x y:y];
    return pt;
}

- (NSMutableArray<FSPointF*>*)updatePencil:(FSPointF*)point
{
    NSMutableArray<FSPointF*> *arrayAffectedPoints = [NSMutableArray<FSPointF*> array];
    const int reachPointCount = 3;
    
    for (FSInk *inkAnnot in self.pencilAnnotationArray)
    {
        if (![inkAnnot canModify]) {
            continue;
        }
        if (_isBegin) {
            [[_extensionsManager getAnnotHandlerByType:e_annotInk] onAnnotSelected:inkAnnot];
            _isBegin = NO;
        }
        
        BOOL isChanged = NO;
        NSMutableArray<NSMutableArray<FSPointF*>*> *arrayLines = [self getPointLinesFromInkAnnot:inkAnnot];
        for (int i = 0; i < arrayLines.count; i++)
        {
            BOOL isLineChanged = NO;
            NSMutableArray<FSPointF*> *pointArray = arrayLines[i];
            
            if (pointArray.count <= 1)
            {
                FSPointF* onePoint = pointArray[0];
                if ([self isInsideCircle:onePoint circleCenterPoint:point])
                {
                    isChanged = YES;
                    [arrayAffectedPoints addObject:pointArray[0]];
                    _changedPointCount++;
                    [arrayLines removeObjectAtIndex:i];
                    i--;
                }
            }
            else
            {
                NSMutableArray *arrayNewLines = [NSMutableArray array];
                for (int j = 0; j < pointArray.count - 1; j++)
                {
                    @autoreleasepool
                    {
                        FSPointF* point1 = pointArray[j];
                        FSPointF* point2 = pointArray[j + 1];
                        
                        double u1, u2;
                        [self getU:point1 point2:point2 circleCenterPoint:point u1:&u1 u2:&u2];
                        
                        if ((u1 < 0 && u2 < 0) || (u1 > 1 && u2 > 1)) //no cross point, outside the circle
                        {
                        }
                        else if ((u1 < 0 && u2 > 1) || (u2 < 0 && u1 > 1)) //no cross point, inside the circle
                        {
                            isLineChanged = YES;
                            [arrayAffectedPoints addObject:pointArray[j]];
                            _changedPointCount++;
                            [pointArray removeObjectAtIndex:j];
                            j--;
                        }
                        else if (((u1 > 0.01 && u1 < 0.99) && (u2 < 0.01 || u2 > 0.99)) || ((u2 > 0.01 && u2 < 0.99) && (u1 < 0.01 || u1 > 0.99))) //one cross point, not on circle
                        {
                            double u;
                            if (u1 > 0.01 && u1 < 0.99)
                            {
                                u = u1;
                            }
                            else
                            {
                                u = u2;
                            }
                            
                            FSPointF* pointCross = [[[FSPointF alloc] init] autorelease];
                            pointCross.x = point1.x + u * (point2.x - point1.x);
                            pointCross.y = point1.y + u * (point2.y - point1.y);
                            
                            if (![self isInsideCircle:point1 circleCenterPoint:point]) //enter circle, point1 is out of circle, point2 is in circle
                            {
                                isLineChanged = YES;
                                [arrayAffectedPoints addObjectsFromArray:[pointArray subarrayWithRange:NSMakeRange(MAX(0,j+1-reachPointCount), MIN(reachPointCount,j+1))]];
                                [arrayAffectedPoints addObject:pointCross];
                                _changedPointCount++;
                                NSMutableArray<FSPointF*> *arrayNewPoints = [NSMutableArray<FSPointF*> array];
                                [arrayNewPoints addObjectsFromArray:[pointArray subarrayWithRange:NSMakeRange(0, j+1)]];
                                [arrayNewPoints addObject:pointCross];
                                [arrayNewLines addObject:arrayNewPoints];
                                [pointArray removeObjectsInRange:NSMakeRange(0, j+1)];
                                j = -1;
                            }
                            else //leave circle
                            {
                                if (j==0)
                                {
                                    isLineChanged = YES;
                                    [arrayAffectedPoints addObject:pointArray[j]];
                                    [pointArray removeObjectAtIndex:j];
                                    [pointArray insertObject:pointCross atIndex:0];
                                    [arrayAffectedPoints addObjectsFromArray:[pointArray subarrayWithRange:NSMakeRange(0, MIN(reachPointCount,pointArray.count))]];
                                    _changedPointCount++;
                                }
                            }
                        }
                        else if ((u1 > 0.01 && u1 < 0.99) && (u2 > 0.01 && u2 < 0.99)) //two cross point
                        {
                            isLineChanged = YES;
                            
                            FSPointF* pointCross1 = [[[FSPointF alloc] init] autorelease];
                            pointCross1.x = point1.x + u1 * (point2.x - point1.x);
                            pointCross1.y = point1.y + u1 * (point2.y - point1.y);
                            FSPointF* pointCross2 = [[[FSPointF alloc] init] autorelease];
                            pointCross2.x = point1.x + u2 * (point2.x - point1.x);
                            pointCross2.y = point1.y + u2 * (point2.y - point1.y);
                            
                            double au1, au2;
                            [self getU:pointCross1 point2:point1 circleCenterPoint:point u1:&au1 u2:&au2];
                            
                            FSPointF *pointCrossStart;
                            FSPointF *pointCrossEnd;
                            
                            if ((au1 >=0 && au1 <= 1) && (au2 >=0 && au2 <= 1))
                            {
                                pointCrossStart = pointCross2;
                                pointCrossEnd = pointCross1;
                            }
                            else
                            {
                                pointCrossStart = pointCross1;
                                pointCrossEnd = pointCross2;
                            }
                            
                            [arrayAffectedPoints addObjectsFromArray:[pointArray subarrayWithRange:NSMakeRange(MAX(0,j+1-reachPointCount), MIN(reachPointCount,j+1))]];
                            [arrayAffectedPoints addObject:pointCrossStart];
                            NSMutableArray *arrayNewPoints = [NSMutableArray array];
                            [arrayNewPoints addObjectsFromArray:[pointArray subarrayWithRange:NSMakeRange(0, j+1)]];
                            [arrayNewPoints addObject:pointCrossStart];
                            [arrayNewLines addObject:arrayNewPoints];
                            [pointArray removeObjectsInRange:NSMakeRange(0, j+1)];
                            [pointArray insertObject:pointCrossEnd atIndex:0];
                            [arrayAffectedPoints addObjectsFromArray:[pointArray subarrayWithRange:NSMakeRange(0, MIN(reachPointCount,pointArray.count))]];
                            _changedPointCount++;
                            j = 1;
                        }
                        else //one cross point, line exactly on the circle
                        {
                        }
                    }
                }
                
                if (isLineChanged)
                {
                    isChanged = YES;
                    
                    if (pointArray.count > 1)
                    {
                        [arrayNewLines addObject:pointArray];
                    }
                    else
                    {
                        [arrayAffectedPoints addObjectsFromArray:pointArray];
                        _changedPointCount++;
                    }
                    
                    [arrayLines removeObjectAtIndex:i];
                    i--;
                    
                    if (arrayNewLines.count > 0)
                    {
                        [arrayLines addObjectsFromArray:arrayNewLines];
                    }
                }
            }
        }
        
        if (isChanged)
        {
            FSPDFPath* newPath = [FSPDFPath create];
            for (int i = 0; i < arrayLines.count; i ++)
            {
                NSArray<FSPointF*> *arrayPoints = [arrayLines objectAtIndex:i];
                
                [newPath moveTo:arrayPoints[0]];
                for (int j = 1; j < arrayPoints.count; j ++)
                {
                    [newPath lineTo:arrayPoints[j]];
                }
            }
            // let setInkList work
            if ([newPath getPointCount] == 0) {
                [newPath moveTo:makePoint(0, 0)];
            }
            [inkAnnot setInkList:newPath];
            [inkAnnot resetAppearanceStream];
            if (![self.affectedPencilAnnotationArray containsObject:inkAnnot]) {
                [self.affectedPencilAnnotationArray addObject:inkAnnot];
            }
        }
    }
    
    return arrayAffectedPoints;
}

- (NSMutableArray<FSInk*>*)getInksInPage:(int)pageIndex
{
    NSMutableArray<FSInk*>* inkAnnots = [NSMutableArray<FSInk*> array];
    FSPDFPage* page = [[_pdfViewCtrl getDoc] getPage:pageIndex];
    for (int i = 0; i < [page getAnnotCount]; i ++) {
        FSAnnot* annot = [page getAnnot:i];
        if (annot.type == e_annotInk) {
            [inkAnnots addObject:(FSInk*)annot];
        }
    }
    return inkAnnots;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet*)touches withEvent:(UIEvent*)event
{
    if ([_extensionsManager getCurrentToolHandler] != self) {
        return NO;
    }
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [[touches anyObject] locationInView:pageView];
    
    if (_isBegin) {
        self.lastBeginValue = [NSValue valueWithCGPoint:point];
        return NO;
    }
    _isBegin = YES;
    self.lastBeginValue = nil;
    
    _isChanged = NO;
    
    self.annotationEditPageIndex = pageIndex;
    
    self.pencilAnnotationArray = [self getInksInPage:pageIndex];
    
    if (self.pencilAnnotationArray.count == 0)
    {
        return NO;
    }
    _radius = _extensionsManager.eraserLineWidth;
    
    self.affectedPencilAnnotationArray = [NSMutableArray array];
    
    //make overylay always draw background with rect
    _allRect = [self getRectFromPencilAnnotation];
    _penclRect = [Utility CGRect2FSRectF:_allRect];
    _allRect = [_pdfViewCtrl convertPdfRectToPageViewRect:_penclRect pageIndex:pageIndex];
    _allRect = [Utility getStandardRect:_allRect];
    _changedPointCount = 0;
    
    float scale = pageView.bounds.size.width / 1000.0;
    CGRect rect = CGRectMake(point.x - _radius*scale, point.y - _radius*scale, _radius*scale*2, _radius*scale*2);
    _lastRect = rect;
    
    FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    NSMutableArray<FSPointF*> *affectedPointArray = [self updatePencil:pdfPoint];
    
    if (affectedPointArray.count > 0)
    {
        _isChanged = YES;
        CGRect affectedRect = [self getRectFromPointArray:affectedPointArray];
        affectedRect = [_pdfViewCtrl convertPdfRectToPageViewRect:[Utility CGRect2FSRectF:affectedRect] pageIndex:pageIndex];
        rect = CGRectUnion(rect, affectedRect);
        
        rect = [Utility getStandardRect:rect];
        rect = CGRectInset(rect, RECT_INSET, RECT_INSET);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
        });
    }
    
    _lastPoint = point;
    _isMoving = YES;
    return YES;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([_extensionsManager getCurrentToolHandler] != self) {
        return NO;
    }
    
    if (_isMoving && !_isZooming)
    {
        if (pageIndex != self.annotationEditPageIndex) {
            [self onPageViewTouchesEnded:self.annotationEditPageIndex touches:touches withEvent:event];
            return YES;
        }
        UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
        CGPoint point = [[touches anyObject] locationInView:pageView];
        FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        
        NSMutableArray<FSPointF*> *affectedPointArray = [NSMutableArray<FSPointF*> array];
        NSMutableArray<FSPointF*> *pointArray = [NSMutableArray<FSPointF*> array];
        [pointArray addObject:pdfPoint];
        FSPointF* lastPdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:_lastPoint pageIndex:pageIndex];
        [self addCenterPoint:pdfPoint p2:lastPdfPoint array:pointArray];
        [pointArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [affectedPointArray addObjectsFromArray:[self updatePencil:(FSPointF*)obj]];
        }];
        
        float scale = pageView.bounds.size.width / 1000.0;
        CGRect rect = [Utility convertToCGRect:point p2:_lastPoint];
        rect = CGRectInset(rect, -_radius*scale, -_radius*scale);
        CGRect unionRect = CGRectUnion(_lastRect, rect);
        
        if (affectedPointArray.count > 0)
        {
            _isChanged = YES;
            CGRect affectedRect = [self getRectFromPointArray:affectedPointArray];
            affectedRect = [_pdfViewCtrl convertPdfRectToPageViewRect:[Utility CGRect2FSRectF:affectedRect] pageIndex:pageIndex];
            unionRect = CGRectUnion(unionRect, affectedRect);
        }
        unionRect = [Utility getStandardRect:unionRect];
        unionRect = CGRectInset(unionRect, RECT_INSET, RECT_INSET);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_pdfViewCtrl refresh:unionRect pageIndex:pageIndex];
        });
        _lastRect = rect;
        
        if (CGRectEqualToRect(self.currentEditRect, CGRectZero)) {
            self.currentEditRect = rect;
        }
        else
        {
            self.currentEditRect = CGRectUnion(self.currentEditRect, rect);
        }
        _penclRect = [_pdfViewCtrl convertPageViewRectToPdfRect:self.currentEditRect pageIndex:pageIndex];
        
        _lastPoint = point;
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([_extensionsManager getCurrentToolHandler] != self) {
        return NO;
    }
    
    if (_isChanged)
    {
        for (int i = 0; i < self.affectedPencilAnnotationArray.count; i++)
        {
            FSInk *annot = self.affectedPencilAnnotationArray[i];
            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByType:e_annotInk];

            if ([[annot getInkList] getPointCount] == 1) // just 'moveTo'
            {
                FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
                [_extensionsManager onAnnotDeleted:page annot:annot];
                [page removeAnnot:annot];
            }
            else
            {
                if ([annot canModify]) {
                    [annotHandler modifyAnnot:annot];
                }
            }
        }
    }
    
    self.affectedPencilAnnotationArray = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:pageIndex needRender:NO];
    });
    
    _isBegin = NO;
    _isMoving = NO;
    _isChanged = NO;
    _changedPointCount = 0;
    
    return YES;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return NO;
}

-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context
{
    if (//pageIndex == self.annotationEditPageIndex && // WRONG pageIndex of overlay view for continuous page mode, todo
        _isMoving && !_isZooming)
    {
        float scale = [_pdfViewCtrl getPageViewWidth:pageIndex] / 1000.0;
        
        // draw gray circle
        CGContextSetLineWidth(context, 2); // set the line width
        CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2].CGColor);
        
        CGPoint center = _lastPoint; // get the circle centre
        CGFloat radius = _radius * scale; // little scaling needed
        CGFloat startAngle = -((float)M_PI / 2); // 90 degrees
        CGFloat endAngle = ((2 * (float)M_PI) + startAngle);
        CGContextAddArc(context, center.x, center.y, radius + 4, startAngle, endAngle, 0); // create an arc the +4 just adds some pixels because of the polygon line thickness
        CGContextFillPath(context);// draw
    }
    
}
@end
