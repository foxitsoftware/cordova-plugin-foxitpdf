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

#import "LinkAnnotHandler.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import "AlertView.h"

@interface LinkAnnotHandler () <IDocEventListener, IPageEventListener>

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) NSDictionary *jumpDict;

- (void)reloadAnnotLink:(FSPDFPage *)dmpage;
- (void)loadAnnotLink:(FSPDFPage *)dmpage;

@end

@implementation LinkAnnotHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager

{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        _dictAnnotLink = [[NSMutableDictionary alloc] init];
        _selected = NO;
    }
    return self;
}

- (FSAnnotType)getType {
    return e_annotLink;
}

- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point {
    CGRect rect = CGRectMake(annot.fsrect.left, annot.fsrect.bottom, annot.fsrect.right - annot.fsrect.left, annot.fsrect.top - annot.fsrect.bottom);
    return CGRectContainsPoint(rect, CGPointMake(point.x, point.y));
}

- (void)onAnnotSelected:(FSAnnot *)annot {
}

- (void)onAnnotDeselected:(FSAnnot *)annot {
}

- (void)addAnnot:(FSAnnot *)annot {
}

- (void)addAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
}

- (void)modifyAnnot:(FSAnnot *)annot {
}

- (void)modifyAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
}

- (void)removeAnnot:(FSAnnot *)annot {
}

- (void)removeAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    if (annot) {
        _selected = YES;
    }
    if (!_selected || !_extensionsManager.enableLinks) {
        return NO;
    }
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    __block BOOL ret = NO;
    id linkArray = nil;
    @synchronized(_dictAnnotLink) {
        [self reloadAnnotLink:[_pdfViewCtrl.currentDoc getPage:pageIndex]];
        linkArray = [_dictAnnotLink objectForKey:@(pageIndex)];
    }
    if (linkArray && linkArray != [NSNull null]) {
        [linkArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *linkDict = obj;
            NSArray *desAreaArray = [linkDict objectForKey:LINK_DES_AREA];
            [desAreaArray enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx2, BOOL *stop2) {
                NSArray *pointsArray = obj2;
                FSPointF *dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
                CGPoint point = CGPointMake(dibPoint.x, dibPoint.y);
                if ([Utility isPointInPolygon:point polygonPoints:pointsArray]) {
                    [_pdfViewCtrl refresh:CGRectZero pageIndex:pageIndex];
                    
                    BOOL isCustomLink = [_extensionsManager onLinkOpen:linkDict LocationInfo:point];
                    if (!isCustomLink){
                        int type = [[linkDict objectForKey:LINK_DES_TYPE] intValue];
                        if (type == e_actionTypeGoto) {
                            [self jumpToPageWithDict:linkDict];
                        }
                        if (type == e_actionTypeURI) {
                            NSURL *URL = [NSURL URLWithString:[linkDict objectForKey:LINK_DES_URL]];
                            NSString *scheme = URL.scheme;
                            
                            BOOL isExit = [[UIApplication sharedApplication] canOpenURL:URL];
                            if (isExit) {
                                [[UIApplication sharedApplication] openURL:URL];
                            } else if (scheme && scheme.length > 0) {
                                AlertView *alert = [[AlertView alloc] initWithTitle:nil
                                                                                message:@"kNoAppropriateApplication"
                                                                               buttonClickHandler:nil
                                                                      cancelButtonTitle:@"kOK"
                                                                      otherButtonTitles:nil, nil];
                                [alert show];
                            } else {
                                AlertView *alert = [[AlertView alloc] initWithTitle:nil
                                                                                message:@"kInvalidUrl"
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"kOK"
                                                                      otherButtonTitles:nil, nil];
                                [alert show];
                            }
                        }
                        if (type == e_actionTypeLaunch) {
                            FSFileSpec *file = [linkDict objectForKey:LINK_DES_FILE];
                            NSString* fileName = [file getFileName];
                            NSString* path = [NSString stringWithFormat:@"%@%@%@",[_extensionsManager.pdfViewCtrl.filePath stringByDeletingLastPathComponent], @"/", fileName];
                            NSURL* URL = [[NSURL alloc] initFileURLWithPath:path];
//                            BOOL isExit = [[UIApplication sharedApplication] canOpenURL:URL];
//                            if (!isExit) {
                            
//                            }
                            NSString* ext = [path pathExtension];
                            if ([ext isEqualToString:@"pdf"]) {
                                [self setDocWithPath:path dict:linkDict];
                            } else {
                                BOOL success = [[UIApplication sharedApplication] openURL:URL];
                                if (!success) {
                                    AlertView *alert = [[AlertView alloc] initWithTitle:nil
                                                                            message:@"kNoAppropriateApplication"
                                                                 buttonClickHandler:nil
                                                                  cancelButtonTitle:@"kOK"
                                                                  otherButtonTitles:nil, nil];
                                    [alert show];
                                }
                            }
                        }
                        if (type == e_actionTypeGoToR) {
                            FSFileSpec *file = [linkDict objectForKey:LINK_DES_FILE];
                            NSString* fileName = [file getFileName];
                            fileName = [fileName stringByReplacingOccurrencesOfString:@":" withString:@"/"];
                            NSString* path = [NSString stringWithFormat:@"%@%@%@",[_extensionsManager.pdfViewCtrl.filePath stringByDeletingLastPathComponent], @"/", fileName];
                            NSFileManager *fileManager = [NSFileManager defaultManager];
                            if (!path || path == nil || ![fileManager fileExistsAtPath:path]) {
                                AlertView *alert = [[AlertView alloc] initWithTitle:nil
                                                                            message:@"kUnfoundOrCannotOpen"
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"kOK"
                                                                  otherButtonTitles:nil, nil];
                                [alert show];
                                ret = YES;
                                return;
                            }
                            
                            [self setJumpDocWithPath:path dict:linkDict];
                        }
                    }
                    ret = YES;
                    *stop2 = YES;
                    *stop = YES;
                }
            }];
        }];
    }
    return ret;
}

- (void)setJumpDocWithPath:(NSString*)path dict:(NSDictionary*)dict {
    FSPDFDoc* doc = [[FSPDFDoc alloc] initWithFilePath:path];
    __block FSErrorCode status = [doc load:nil];
    if (status == e_errPassword) {
        AlertView *alert = [[AlertView alloc] initWithTitle:nil
                                                    message:@"kDocNeedPassword"
                                         buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                             if (buttonIndex == 0) {
                                                 return;
                                             } else if (buttonIndex == 1) {
                                                 NSString *password = [alertView textFieldAtIndex:1].text;
                                                 status = [doc load:password];
                                                 if (status == e_errSuccess) {
                                                     [_extensionsManager.pdfViewCtrl openDoc:path password:password completion:nil];
                                                     _jumpDict = [[NSDictionary alloc] initWithDictionary:dict];
                                                 }
                                             }
                                         }
                                          cancelButtonTitle:@"kCancel"
                                          otherButtonTitles:@"kOK", nil];
        [alert show];
    } else if (status == e_errSuccess) {
        [_extensionsManager.pdfViewCtrl openDoc:path password:nil completion:nil];
        _jumpDict = [[NSDictionary alloc] initWithDictionary:dict];
    }
}

- (void)setDocWithPath:(NSString*)path dict:(NSDictionary*)dict {
    if (path == nil) {
        return;
    }
    if ([_extensionsManager.delegate respondsToSelector:@selector(uiextensionsManager:openNewDocAtPath:)]) {
        BOOL isOpen = [_extensionsManager.delegate uiextensionsManager:_extensionsManager openNewDocAtPath:path];
        if (isOpen) {
            [self jumpToPageWithDict:dict];
        }
    } else {
        __weak typeof(self) weakSelf = self;
        [_extensionsManager saveAndCloseCurrentDoc:^(BOOL success) {
            if (success) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf->_extensionsManager.pdfViewCtrl openDoc:path
                                                           password:nil
                                                         completion:^(FSErrorCode error) {
                                                             [weakSelf jumpToPageWithDict:dict];
                                                         }];
            }
        }];
    }
}

- (void)jumpToPageWithDict:(NSDictionary*)dict {
    int jumpIndex = [[dict objectForKey:LINK_DES_INDEX] intValue];
    if (jumpIndex >= 0 && jumpIndex < [_extensionsManager.pdfViewCtrl.currentDoc getPageCount]) {
        FSRectF *desDibRect = [Utility CGRect2FSRectF:[[dict objectForKey:LINK_DES_RECT] CGRectValue]];
        //prevent sometimes it's faster than return YES
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            FSPointF *point = [[FSPointF alloc] init];
            point.x = -1;
            point.y = desDibRect.top;
            [_pdfViewCtrl gotoPage:jumpIndex withDocPoint:point animated:YES];
        });
    }
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot *)annot {
    CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    __block BOOL ret = NO;
    id linkArray = nil;
    @synchronized(_dictAnnotLink) {
        [self reloadAnnotLink:[_pdfViewCtrl.currentDoc getPage:pageIndex]];
        linkArray = [_dictAnnotLink objectForKey:@(pageIndex)];
    }
    if (linkArray && linkArray != [NSNull null]) {
        [linkArray enumerateObjectsWithOptions:NSEnumerationReverse
                                    usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                        NSDictionary *linkDict = obj;
                                        NSArray *desAreaArray = [linkDict objectForKey:LINK_DES_AREA];
                                        [desAreaArray enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx2, BOOL *stop2) {
                                            NSArray *pointsArray = obj2;
                                            FSPointF *dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
                                            CGPoint point = CGPointMake(dibPoint.x, dibPoint.y);
                                            if ([Utility isPointInPolygon:point polygonPoints:pointsArray]) {
                                                [_pdfViewCtrl refresh:CGRectZero pageIndex:pageIndex];
                                                ret = YES;
                                                _selected = YES;
                                                *stop2 = YES;
                                                *stop = YES;
                                            }
                                        }];
                                    }];
    }
    return ret;
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
    [self onRealPageViewDraw:[_pdfViewCtrl.currentDoc getPage:pageIndex] inContext:context pageIndex:pageIndex];
}

#pragma mark IDvDrawEventListener

//draw link
- (void)onRealPageViewDraw:(FSPDFPage *)page inContext:(CGContextRef)context pageIndex:(int)pageIndex {
    if (!_extensionsManager.enableHighlightLinks)
        return;
    [self loadAnnotLink:page];

    NSArray *array = [_dictAnnotLink objectForKey:[NSNumber numberWithInt:[page getIndex]]];
    if (array && ((id) array != [NSNull null])) {
        if (![SettingPreference getPDFHighlightLinks]) {
            return;
        }

        CGFloat red, green, blue, alpha;
        [_extensionsManager.linksHighlightColor getRed:&red green:&green blue:&blue alpha:&alpha];
        CGContextSetRGBFillColor(context, red, green, blue, alpha);
        [array enumerateObjectsWithOptions:NSEnumerationReverse
                                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                    NSDictionary *linkDict = obj;
                                    NSArray *desAreaArray = [linkDict objectForKey:LINK_DES_AREA];
                                    [desAreaArray enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx2, BOOL *stop2) {
                                        NSArray *pointArray = obj2;
                                        CGContextBeginPath(context);
                                        [pointArray enumerateObjectsUsingBlock:^(id obj3, NSUInteger idx3, BOOL *stop3) {
                                            CGPoint p = [obj3 CGPointValue];
                                            FSPointF *p2 = [[FSPointF alloc] init];
                                            p2.x = p.x;
                                            p2.y = p.y;
                                            CGPoint pp = [_pdfViewCtrl convertPdfPtToPageViewPt:p2 pageIndex:[page getIndex]];
                                            p.x = pp.x;
                                            p.y = pp.y;
                                            if (idx3 == 0) {
                                                CGContextMoveToPoint(context, p.x, p.y);
                                            } else {
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

- (void)loadAnnotLink:(FSPDFPage *)dmpage {
    NSMutableArray *array = nil;
    @synchronized(_dictAnnotLink) {
        array = [_dictAnnotLink objectForKey:[NSNumber numberWithInt:[dmpage getIndex]]];
    }
    if (!array) {
        if (!dmpage) {
            return;
        }

        int linkCount = [dmpage getAnnotCount];
        if (linkCount > 0) {
            array = [NSMutableArray array];
        }

        for (int i = 0; i < linkCount; i++) {
            FSAnnot *annot = [dmpage getAnnot:i];
            if (!annot) {
                continue;
            }

            if (e_annotLink != [annot getType])
                continue;
            FSLink *link = (FSLink *) annot;
            FSAction *action = nil;
            @try {
                action = [link getAction];
            } @catch (NSException *exception) {
                NSLog(@"%@", exception.description);
            }
            while (action) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];

                BOOL support = NO;
                if ([action getType] == e_actionTypeGoto) {
                    FSGotoAction *gotoAction = (FSGotoAction *) action;
                    FSDestination *dest = [gotoAction getDestination];
                    if (dest) {
                        FSRectF *rect = [[FSRectF alloc] init];
                        rect.left = [dest getLeft];
                        rect.bottom = [dest getBottom];
                        rect.top = [dest getTop];
                        rect.right = [dest getRight];
                        int desIndex = [dest getPageIndex];

                        CGRect desRect = [Utility FSRectF2CGRect:rect];
                        [dict setValue:@(e_actionTypeGoto) forKey:LINK_DES_TYPE];
                        [dict setValue:@(desIndex) forKey:LINK_DES_INDEX];
                        [dict setValue:[NSValue valueWithCGRect:desRect] forKey:LINK_DES_RECT];

                        support = YES;
                    }
                }
                if ([action getType] == e_actionTypeGoToR) {
                    FSRemoteGotoAction *gotoRAction = (FSRemoteGotoAction *) action;
                    //fileSpec
                    FSFileSpec *file = [gotoRAction getFileSpec];
                    [dict setValue:file forKey:LINK_DES_FILE];
                    support = YES;
                    [dict setValue:@(e_actionTypeGoToR) forKey:LINK_DES_TYPE];
                    FSDestination *dest = [gotoRAction getDestination];
                    if (dest) {
                        FSRectF *rect = [[FSRectF alloc] init];
                        rect.left = [dest getLeft];
                        rect.bottom = [dest getBottom];
                        rect.top = [dest getTop];
                        rect.right = [dest getRight];
                        int desIndex = [dest getPageIndex];
                        
                        CGRect desRect = [Utility FSRectF2CGRect:rect];
                        [dict setValue:@(desIndex) forKey:LINK_DES_INDEX];
                        [dict setValue:[NSValue valueWithCGRect:desRect] forKey:LINK_DES_RECT];
                    } else {
                        [dict setValue:@0 forKey:LINK_DES_INDEX];
                    }
                }
                if ([action getType] == e_actionTypeLaunch) {
                    FSLaunchAction* launchAction = (FSLaunchAction *) action;
                    //fileSpec
                    FSFileSpec* file = [launchAction getFileSpec];
                    [dict setValue:file forKey:LINK_DES_FILE];
                    [dict setValue:@(e_actionTypeLaunch) forKey:LINK_DES_TYPE];
                    support = YES;
                }
                
                if ([action getType] == e_actionTypeURI) {
                    FSURIAction *uriAction = (FSURIAction *) action;
                    NSString *uri = [uriAction getURI];
                    [dict setValue:uri forKey:LINK_DES_URL];
                    [dict setValue:@(e_actionTypeURI) forKey:LINK_DES_TYPE];
                    support = YES;
                }
                if (support) {
                    NSArray *desArea = [self getAnnotationQuad:annot];
                    if (!desArea) {
                        FSRectF *rect = [annot getRect];
    
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

                    if (desArea) {
                        [dict setValue:desArea forKey:LINK_DES_AREA];
                    }
                }
                
                if (dict.count > 0) {
                    [array addObject:dict];
                }
                if ([action getSubActionCount] > 0)
                    action = [action getSubAction:0];
                else
                    action = nil;
            }
        }
        @synchronized(_dictAnnotLink) {
            [_dictAnnotLink setObject:array ? array : [NSNull null] forKey:[NSNumber numberWithInt:[dmpage getIndex]]];
        }
    }
}

- (void)reloadAnnotLink:(FSPDFPage *)dmpage {
    @synchronized(self) {
        @synchronized(_dictAnnotLink) {
            [_dictAnnotLink removeObjectForKey:[NSNumber numberWithInt:[dmpage getIndex]]];
        }
        [self loadAnnotLink:dmpage];
    }
}

- (NSArray *)getAnnotationQuad:(FSAnnot *)annot {
    if ([annot getType] != e_annotLink)
        return nil;
    int quadCount = [(FSLink *) annot getQuadPointsCount];
    if (quadCount <= 0) {
        return nil;
    }

    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < quadCount; i++) {
        FSQuadPoints *quadPoints = [(FSLink *) annot getQuadPoints:i];
        if (!quadPoints) {
            break;
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

    return array;
}

#pragma mark IDocEventListener

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    if(_jumpDict){
        [self jumpToPageWithDict:_jumpDict];
        _jumpDict = nil;
    }
}
- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    [self.dictAnnotLink removeAllObjects];
}

#pragma mark IPageEventListener
- (void)onPagesWillRemove:(NSArray<NSNumber *> *)indexes {
}

- (void)onPagesWillMove:(NSArray<NSNumber *> *)indexes dstIndex:(int)dstIndex {
}

- (void)onPagesWillRotate:(NSArray<NSNumber *> *)indexes rotation:(int)rotation {
}

- (void)onPagesRemoved:(NSArray<NSNumber *> *)indexes {
    [self.dictAnnotLink removeAllObjects];
}

- (void)onPagesMoved:(NSArray<NSNumber *> *)indexes dstIndex:(int)dstIndex {
    [self.dictAnnotLink removeAllObjects];
}

- (void)onPagesRotated:(NSArray<NSNumber *> *)indexes rotation:(int)rotation {
}

- (void)onPagesInsertedAtRange:(NSRange)range {
    [self.dictAnnotLink removeAllObjects];
}

@end
