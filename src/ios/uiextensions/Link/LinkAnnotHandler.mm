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
#import "LinkAnnotHandler.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface LinkAnnotHandler () <IDocEventListener>

@property (nonatomic, assign) BOOL isSelected;

- (void)reloadAnnotLink:(FSPDFPage*)dmpage;
- (void)loadAnnotLink:(FSPDFPage*)dmpage;

@end

@implementation LinkAnnotHandler
{
    UIExtensionsManager* _extensionsManager;
    FSPDFViewCtrl* _pdfViewCtrl;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager

{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        [_extensionsManager registerAnnotHandler:self];
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        [_pdfViewCtrl registerDocEventListener:self];
        _dictAnnotLink = [[NSMutableDictionary alloc] init];
        _isSelected = NO;
    }
    return self;
}

-(enum FS_ANNOTTYPE)getType
{
    return e_annotLink;
}

-(BOOL)isHitAnnot:(FSAnnot*)annot point:(FSPointF*)point
{
    CGRect rect = CGRectMake(annot.fsrect.left, annot.fsrect.bottom, annot.fsrect.right - annot.fsrect.left, annot.fsrect.top - annot.fsrect.bottom);
    return CGRectContainsPoint(rect, CGPointMake(point.x, point.y));
}

-(void)onAnnotSelected:(FSAnnot*)annot
{
    
}

-(void)onAnnotDeselected:(FSAnnot*)annot
{
    
}

-(void)addAnnot:(FSAnnot*)annot
{
    
}

-(void)modifyAnnot:(FSAnnot*)annot
{
    
}

-(void)removeAnnot:(FSAnnot*)annot
{
    
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    if (annot) {
        _isSelected = YES;
    }
    if (!_isSelected || !_extensionsManager.enablelinks) {
        return NO;
    }
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    __block BOOL ret = NO;
    id linkArray = nil;
    @synchronized(_dictAnnotLink)
    {
        [self reloadAnnotLink:[_pdfViewCtrl.currentDoc getPage:pageIndex]];
        linkArray = [[_dictAnnotLink objectForKey:[NSNumber numberWithInt:pageIndex]] retain];
    }
    if (linkArray && linkArray != [NSNull null])
    {
        [linkArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             NSDictionary *linkDict = obj;
             NSArray *desAreaArray = [linkDict objectForKey:LINK_DES_AREA];
             [desAreaArray enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx2, BOOL *stop2)
              {
                  NSArray *pointsArray = obj2;
                  FSPointF* dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
                  CGPoint point = CGPointMake(dibPoint.x, dibPoint.y);
                  if ([Utility isPointInPolygon:point polygonPoints:pointsArray])
                  {
                      _annotLinkPointArray = desAreaArray;
                      [_pdfViewCtrl refresh:CGRectZero pageIndex:pageIndex];
                      int type = [[linkDict objectForKey:LINK_DES_TYPE] intValue];
                      if (type == e_actionTypeGoto)
                      {
                          int jumpIndex = [[linkDict objectForKey:LINK_DES_INDEX] intValue];
                          if (jumpIndex >= 0 && jumpIndex < [_extensionsManager.pdfViewCtrl.currentDoc getPageCount]) {
                              FSRectF* desDibRect = [Utility CGRect2FSRectF:[[linkDict objectForKey:LINK_DES_RECT] CGRectValue]];
                              //prevent sometimes it's faster than return YES
                              double delayInSeconds = 0.1;
                              dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                              dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                  FSPointF* point = [[FSPointF alloc] init];
                                  point.x = -1;
                                  point.y = desDibRect.top;
                                  [_pdfViewCtrl gotoPage:jumpIndex withDocPoint:point animated:YES];
                                  [point release];
                              });
                          }
                      }
                      if (type == e_actionTypeURI) {
                          NSString* uri = [linkDict objectForKey:LINK_DES_URL];
                          NSURL *newUri = [NSURL URLWithString:uri];
                          NSString * scheme = newUri.scheme;
                          
                          BOOL isexit = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:uri]];
                          if (isexit) {
                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:uri]];
                          }
                          else if(scheme && scheme.length >0){
                              UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:nil
                                                                               message:NSLocalizedString(@"kNoAppropriateApplication", nil)
                                                                              delegate:nil
                                                                     cancelButtonTitle:NSLocalizedString(@"kOK", nil) otherButtonTitles:nil, nil] autorelease];
                              [alert show];
                              
                          }
                          else
                          {
                              UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:nil
                                                                               message:NSLocalizedString(@"kInvalidUrl", nil)
                                                                              delegate:nil
                                                                     cancelButtonTitle:NSLocalizedString(@"kOK", nil) otherButtonTitles:nil, nil] autorelease];
                              [alert show];
                          }
                          
                      }
                      ret = YES;
                      *stop2 = YES;
                      *stop = YES;
                  }
              }];
         }];
    }
    [linkArray release];
    return ret;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot*)annot
{
    CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    __block BOOL ret = NO;
    id linkArray = nil;
    @synchronized(_dictAnnotLink)
    {
        [self reloadAnnotLink:[_pdfViewCtrl.currentDoc getPage:pageIndex]];
        linkArray = [[_dictAnnotLink objectForKey:[NSNumber numberWithInt:pageIndex]] retain];
    }
    if (linkArray && linkArray != [NSNull null])
    {
        [linkArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             NSDictionary *linkDict = obj;
             NSArray *desAreaArray = [linkDict objectForKey:LINK_DES_AREA];
             [desAreaArray enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx2, BOOL *stop2)
              {
                  NSArray *pointsArray = obj2;
                  FSPointF* dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
                  CGPoint point = CGPointMake(dibPoint.x, dibPoint.y);
                  if ([Utility isPointInPolygon:point polygonPoints:pointsArray])
                  {
                      _annotLinkPointArray = desAreaArray;
                      [_pdfViewCtrl refresh:CGRectZero pageIndex:pageIndex];
                      ret = YES;
                      _isSelected = YES;
                      *stop2 = YES;
                      *stop = YES;
                  }
              }];
         }];
    }
    [linkArray release];
    return ret;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet*)touches withEvent:(UIEvent*)event annot:(FSAnnot*)annot
{
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot*)annot
{
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot*)annot
{
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot*)annot
{
    return NO;
}

-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context annot:(FSAnnot*)annot
{
    [self onRealPageViewDraw:[_pdfViewCtrl.currentDoc getPage:pageIndex] inContext:context pageIndex:pageIndex];
}

#pragma mark IDvDrawEventListener

//draw link
- (void)onRealPageViewDraw:(FSPDFPage*)page inContext:(CGContextRef)context pageIndex:(int)pageIndex
{
    [self loadAnnotLink:page];
    
    NSArray *array = [_dictAnnotLink objectForKey:[NSNumber numberWithInt:[page getIndex]]];
    if (array && ((id)array != [NSNull null]))
    {
        if (![SettingPreference getPDFHighlightLinks]) {
            return;
        }
        
        CGContextSetRGBFillColor(context, 1.0, 1.0, 0, .3);
        [array enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             NSDictionary *linkDict = obj;
             NSArray *desAreaArray = [linkDict objectForKey:LINK_DES_AREA];
             [desAreaArray enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx2, BOOL *stop2)
              {
                  NSArray *pointArray = obj2;
                  CGContextBeginPath(context);
                  [pointArray enumerateObjectsUsingBlock:^(id obj3, NSUInteger idx3, BOOL *stop3)
                   {
                       CGPoint p = [obj3 CGPointValue];
                       FSPointF* p2 = [[FSPointF alloc] init];
                       p2.x = p.x;
                       p2.y = p.y;
                       CGPoint pp = [_pdfViewCtrl convertPdfPtToPageViewPt:p2 pageIndex:[page getIndex]];
                       [p2 release];
                       p.x = pp.x;
                       p.y = pp.y;
                       if (idx3 == 0)
                       {
                           CGContextMoveToPoint(context, p.x, p.y);
                       }
                       else
                       {
                           CGContextAddLineToPoint(context, p.x, p.y);
                       }
                   }];
                  CGContextClosePath(context);
                  CGContextFillPath(context);
              }];
         }];
    }
}

#pragma mark link

- (void)loadAnnotLink:(FSPDFPage*)dmpage
{
    NSMutableArray *array = nil;
    @synchronized(_dictAnnotLink)
    {
        array = [_dictAnnotLink objectForKey:[NSNumber numberWithInt:[dmpage getIndex]]];
    }
    if (!array)
    {
        if (!dmpage)
        {
            return;
        }
        
        
        int linkCount = [dmpage getAnnotCount];
        if (linkCount > 0)
        {
            array = [NSMutableArray array];
        }
        
        for (int i = 0; i < linkCount; i++)
        {
            FSAnnot* annot = [dmpage getAnnot:i];
            if (!annot)
            {
                continue;
            }
            
            if(e_annotLink != [annot getType])
                continue;
            FSLink* link = (FSLink*)annot;
            FSAction* action = [link getAction];
            while (action)
            {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                
                int ret = 0;
                if (!ret)
                {
                    BOOL support = NO;
                    if([action getType] == e_actionTypeGoto)
                    {
                        FSGotoAction* gotoAction = (FSGotoAction*)action;
                        FSDestination* dest = [gotoAction getDestination];
                        if(dest)
                        {
                            FSRectF* rect = [[FSRectF alloc] init];
                            rect.left = [dest getLeft];
                            rect.bottom = [dest getBottom];
                            rect.top = [dest getTop];
                            rect.right = [dest getRight];
                            int desIndex = [dest getPageIndex];
                            
                            CGRect desRect = [Utility FSRectF2CGRect:rect];
                            [dict setValue:[NSNumber numberWithInt:e_actionTypeGoto] forKey:LINK_DES_TYPE];
                            [dict setValue:[NSNumber numberWithInt:desIndex] forKey:LINK_DES_INDEX];
                            [dict setValue:[NSValue valueWithCGRect:desRect] forKey:LINK_DES_RECT];
                            
                            [rect release];
                            support = YES;
                        }
                    }
                    if ([action getType] == e_actionTypeURI)
                    {
                        FSURIAction* uriAction = (FSURIAction*)action;
                        NSString* uri = [uriAction getURI];
                        [dict setValue:uri forKey:LINK_DES_URL];
                        [dict setValue:[NSNumber numberWithInt:e_actionTypeURI] forKey:LINK_DES_TYPE];
                        support = YES;
                    }
                    if (support)
                    {
                        NSArray *desArea = [self getAnnotationQuad:annot];
                        if (!desArea)
                        {
                            FSRectF* rect = [annot getRect];
                            ret = 0;
                            if (!ret)
                            {
                                CGPoint point1;
                                point1.x = rect.left;
                                point1.y = rect.bottom;
                                NSValue *value1 = [NSValue valueWithCGPoint:point1];
                                CGPoint point2;
                                point2.x = rect.right;
                                point2.y = rect.bottom;
                                NSValue *value2 = [NSValue valueWithCGPoint:point2];
                                CGPoint point3;
                                point3.x = rect.right;
                                point3.y = rect.top;
                                NSValue *value3 = [NSValue valueWithCGPoint:point3];
                                CGPoint point4;
                                point4.x = rect.left;
                                point4.y = rect.top;
                                NSValue *value4 = [NSValue valueWithCGPoint:point4];
                                NSArray *arrayQuad = [NSArray arrayWithObjects:value1, value2, value3, value4, nil];
                                desArea = [NSArray arrayWithObject:arrayQuad];
                            }
                        }
                        
                        if (desArea)
                        {
                            [dict setValue:desArea forKey:LINK_DES_AREA];
                        }
                    }
                }
                
                if (dict.count > 0)
                {
                    [array addObject:dict];
                }
                if ([action getSubActionCount] > 0)
                    action = [action getSubAction:0];
                else
                    action = nil;
            }
        }
        @synchronized(_dictAnnotLink)
        {
            [_dictAnnotLink setObject:array?array:[NSNull null] forKey:[NSNumber numberWithInt:[dmpage getIndex]]];
        }
    }
}

- (void)reloadAnnotLink:(FSPDFPage*)dmpage
{
    @synchronized(self)
    {
        @synchronized(_dictAnnotLink)
        {
            [_dictAnnotLink removeObjectForKey:[NSNumber numberWithInt:[dmpage getIndex]]];
        }
        [self loadAnnotLink:dmpage];
    }
}

- (NSArray*)getAnnotationQuad:(FSAnnot*)annot
{
    if([annot getType] != e_annotLink)
        return nil;
    NSMutableArray *array = [NSMutableArray array];
    int quadCount = [(FSLink*)annot getQuadPointsCount];
    if (quadCount <= 0)
    {
        return nil;
    }
    
    for (int i = 0; i < quadCount; i++) {
        FSQuadPoints *quadPoints = [(FSLink*)annot getQuadPoints:i];
        if (!quadPoints)
        {
            goto END;
        }
        
        CGPoint point1;
        point1.x = [[quadPoints getFirst] getX];
        point1.y = [[quadPoints getFirst] getY];
        NSValue *value1 = [NSValue valueWithCGPoint:point1];
        CGPoint point2;
        point2.x = [[quadPoints getSecond] getX];
        point2.y = [[quadPoints getSecond] getY];
        NSValue *value2 = [NSValue valueWithCGPoint:point2];
        CGPoint point3;
        point3.x = [[quadPoints getThird] getX];
        point3.y = [[quadPoints getThird] getY];
        NSValue *value3 = [NSValue valueWithCGPoint:point3];
        CGPoint point4;
        point4.x = [[quadPoints getFourth] getX];
        point4.y = [[quadPoints getFourth] getY];
        NSValue *value4 = [NSValue valueWithCGPoint:point4];
        NSArray *arrayQuad = [NSArray arrayWithObjects:value1, value2, value3, value4, nil];
        [array addObject:arrayQuad];
    }
END:
    return array;
}

#pragma mark IDocEventListener

- (void)onDocClosed:(FSPDFDoc* )document error:(int)error
{
    [self.dictAnnotLink removeAllObjects];
}

@end
