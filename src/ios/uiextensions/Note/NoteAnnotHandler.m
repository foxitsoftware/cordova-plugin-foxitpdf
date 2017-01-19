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
#import <FoxitRDK/FSPDFViewControl.h>
#import "UIExtensionsManager+Private.h"
#import "NoteAnnotHandler.h"
#import "NoteDialog.h"
#import "ReplyTableViewController.h"
#import "MenuControl.h"
#import "ReplyUtil.h"
#import "MenuItem.h"
#import "ColorUtility.h"

@interface NoteAnnotHandler () <IDocEventListener>

@property (nonatomic, retain) FSAnnot *editAnnot;
@property (nonatomic, retain) NSArray *colors;
@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;

@property (nonatomic, retain) UIImage* annotImage;

@end

@implementation NoteAnnotHandler {
    FSPDFViewCtrl* _pdfViewCtrl;
    TaskServer* _taskServer;
    UIExtensionsManager* _extensionsManager;
    
    CGRect _lastPanRect;
    
    BOOL _isZooming;
}

-(void)dealloc
{
    [_editAnnot release];
    [_colors release];
    [_currentVC release];
    [_annotImage release];
    [super dealloc];
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        [_pdfViewCtrl registerDocEventListener:self];
        [_extensionsManager registerAnnotHandler:self];
        [_extensionsManager registerRotateChangedListener:self];
        [_extensionsManager registerGestureEventListener:self];
        [_pdfViewCtrl registerScrollViewEventListener:self];
        [_extensionsManager.propertyBar registerPropertyBarListener:self];
        [_extensionsManager registerPropertyBarListener:self];

        _taskServer = _extensionsManager.taskServer;
        self.colors = @[@0xFF9F40,@0x8080FF,@0xBAE94C,@0xFFF160,@0xC3C3C3,@0xFF4C4C,@0x669999,@0xC72DA1,@0x996666,@0x000000];
        self.isShowStyle = NO;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        self.editAnnot = nil;

        _lastPanRect = CGRectZero;
        _isZooming = NO;
    }
    return self;
}

- (UIImage*)getAnnotImage:(FSAnnot*)annot context:(CGContextRef)context dibWidth:(int)dibWidth dibHeight:(int)dibHeight pdfX:(int)pdfX pdfY:(int)pdfY pdfWidth:(int)pdfWidth pdfHeight:(int)pdfHeight
{
    if (context)
    {
        CGRect rect = CGContextGetClipBoundingBox(context);
        if (rect.size.width == 0 || rect.size.height == 0)
        {
            return nil;
        }
    }
    else
    {
        if (dibWidth == 0 || dibHeight == 0)
        {
            return nil;
        }
    }
    
    __block UIImage *img = nil;
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        CGFloat scale = [[UIScreen mainScreen] scale];
        if(context)
        {
            scale = 1;
        }
        else
        {
#ifdef CONTEXT_DRAW
            scale = 1;
#endif
        }
        int newDibWidth = dibWidth * scale;
        int newDibHeight = dibHeight * scale;
        CGContextRef realContext = context;
        void *pBuf = NULL;
        int size = newDibWidth*newDibHeight*4;
        FSBitmap* fsbitmap = nil;
        FSRenderer* fsrenderer = nil;
        if (!context)
        {
#ifdef CONTEXT_DRAW
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(newDibWidth, newDibHeight), NO, [[UIScreen mainScreen] scale]);
            realContext = UIGraphicsGetCurrentContext();
#else
            //create a 32bits bitmap
            pBuf = malloc(size);
            memset(pBuf, 0x00, size);
            fsbitmap = [FSBitmap create:newDibWidth height:newDibHeight format:e_dibArgb buffer:(unsigned char*)pBuf pitch:newDibWidth*4];
#endif
        }
        
        if (!context)
        {
#ifdef CONTEXT_DRAW
            fsrenderer = [FSRenderer createFromContext:realContext deviceType:e_deviceTypeDisplay];
#else
            fsrenderer = [FSRenderer create:fsbitmap rgbOrder:NO];
#endif
        }
        else
        {
            fsrenderer = [FSRenderer createFromContext:realContext deviceType:e_deviceTypeDisplay];
        }
        FSMatrix* fsmatrix = [_pdfViewCtrl getDisplayMatrix:[[annot getPage] getIndex]];
        
        void(^releaseRender)(BOOL freepBuf) = ^(BOOL freepBuf)
        {
            if (!context)
            {
#ifdef CONTEXT_DRAW
                UIGraphicsEndImageContext();
#else
                if (freepBuf)
                {
                    free(pBuf);
                }
#endif
            }
        };
        
        [fsrenderer setTransformAnnotIcon:NO];
        if ([_pdfViewCtrl isNightMode])
        {
            [fsrenderer setColorMode:e_colorModeMapping];
            [fsrenderer setMappingModeColors:0xFF00001b foreColor:0xFF5d5b71];
        }

        [fsrenderer renderAnnot:annot matrix:fsmatrix];

        if (!context)
        {
#ifdef CONTEXT_DRAW
            img = UIGraphicsGetImageFromCurrentImageContext();
#else
            img = [Utility dib2img:pBuf size:size dibWidth:newDibWidth dibHeight:newDibHeight withAlpha:YES];
#endif
        }
        releaseRender(img == nil);
        
    };
    [_taskServer executeSync:task];
    
    return img;
}

-(enum FS_ANNOTTYPE)getType
{
    return e_annotNote;
}

-(BOOL)isHitAnnot:(FSAnnot*)annot point:(FSPointF*)point
{
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    pvRect = CGRectMake(pvRect.origin.x, pvRect.origin.y, 32, 32);
    pvRect = CGRectInset(pvRect, -20, -20);
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:annot.pageIndex];
    if(CGRectContainsPoint(pvRect, pvPoint))
    {
        return YES;
    }
    return NO;
}

-(void)onAnnotSelected:(FSAnnot*)annot
{
    self.editAnnot = annot;
    
    CGRect pvRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
    
    NSMutableArray *array = [NSMutableArray array];
    
    MenuItem *commentItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *replyItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kReply", nil) object:self action:@selector(reply)] autorelease];
    MenuItem *styleItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kStyle", nil) object:self action:@selector(showStyle)] autorelease];
    MenuItem *deleteItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kDelete", nil) object:self action:@selector(deleteAnnot)] autorelease];
    
    if (annot.canModify) {
        [array addObject:styleItem];
        [array addObject:commentItem];
        [array addObject:replyItem];
        [array addObject:deleteItem];
    }
    else
    {
        [array addObject:commentItem];
        [array addObject:replyItem];
    }
    
    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:annot.pageIndex];
    MenuControl* annotMenu = _extensionsManager.menuControl;
    annotMenu.menuItems = array;
    [annotMenu setRect:dvRect];
    [annotMenu showMenu];
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;
    
    self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
    [_pdfViewCtrl refresh:CGRectInset(pvRect, -30, -30) pageIndex:annot.pageIndex needRender:YES];
}

-(void)copyText
{
    FSAnnot *annot = _extensionsManager.currentAnnot;
    NSString *str = annot.contents;
    if (str && ![str isEqualToString:@""]) {
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        board.string = str;
    }
    [_extensionsManager setCurrentAnnot:nil];
}

-(void)comment
{
    NSMutableArray *replyAnnots = [[[NSMutableArray alloc] init] autorelease];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager] autorelease];
    self.currentVC = replyCtr;
    replyCtr.isNeedReply = NO;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:_extensionsManager.currentAnnot];
    [replyCtr setTableViewAnnotations:array];
    UINavigationController *navCtr= [[UINavigationController alloc] initWithRootViewController:replyCtr];
    navCtr.delegate = replyCtr;
    navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:navCtr animated:YES completion:nil];
    replyCtr.editingDoneHandler = ^()
    {
        [navCtr release];
        [replyCtr release];
        [_extensionsManager setCurrentAnnot:nil];
    };
    replyCtr.editingCancelHandler = ^()
    {
        [navCtr release];
        
        [replyCtr release];
        [_extensionsManager setCurrentAnnot:nil];
    };
}

-(void)reply
{
    NSMutableArray *replyAnnots = [[[NSMutableArray alloc] init] autorelease];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager] autorelease];
    self.currentVC = replyCtr;
    replyCtr.isNeedReply = YES;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:_extensionsManager.currentAnnot];
    [replyCtr setTableViewAnnotations:array];
    UINavigationController *navCtr= [[UINavigationController alloc] initWithRootViewController:replyCtr];
    
    navCtr.delegate = replyCtr;
    navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:navCtr animated:YES completion:nil];
    replyCtr.editingDoneHandler = ^()
    {
        [navCtr release];
        
        [replyCtr release];
        [_extensionsManager setCurrentAnnot:nil];;
    };
    replyCtr.editingCancelHandler = ^()
    {
        [navCtr release];
        
        [replyCtr release];
        [_extensionsManager setCurrentAnnot:nil];;
    };
}

-(void)deleteAnnot
{
    FSAnnot *annot = _extensionsManager.currentAnnot;
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        [self removeAnnot:annot];
    };
    [_taskServer executeSync:task];
    [_extensionsManager setCurrentAnnot:nil];
}

-(void)showStyle
{
    UIExtensionsManager* extensionsManager = _extensionsManager;
    [extensionsManager.propertyBar setColors:self.colors];
    [extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_ICONTYPE];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity*100.0];
    [extensionsManager.propertyBar setProperty:PROPERTY_ICONTYPE intValue:annot.icon];
    [extensionsManager.propertyBar addListener:_extensionsManager];
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:annot.pageIndex];
    [extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
    self.isShowStyle = YES;
    self.shouldShowMenu = NO;
    self.shouldShowPropety = YES;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
}

-(void)onAnnotDeselected:(FSAnnot*)annot
{
    self.editAnnot = nil;
    MenuControl* annotMenu = _extensionsManager.menuControl;
    if (annotMenu.isMenuVisible) {
        [annotMenu setMenuVisible:NO animated:YES];
    }
    UIExtensionsManager* extensionsManager = _extensionsManager;
    if (extensionsManager.propertyBar.isShowing) {
        [extensionsManager.propertyBar dismissPropertyBar];
        self.isShowStyle = NO;
    }
    self.shouldShowMenu = NO;
    self.shouldShowPropety = NO;

    self.annotImage = nil;
    
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    newRect = CGRectInset(newRect, -30, -30);
    [_pdfViewCtrl refresh:newRect pageIndex:annot.pageIndex needRender:YES];
}

-(void)addAnnot:(FSAnnot*)annot
{
    [annot retain];
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^()
    {
       [self _addAnnot:(FSNote*)annot];

        CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        rect =CGRectInset(rect, -30, -30);
        int pageIndex = annot.pageIndex;
        dispatch_async(dispatch_get_main_queue(), ^{
            double delayInSeconds = .3;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
            });
        });
        [annot release];
    };
    [_taskServer executeSync:task];
}

-(void)modifyAnnot:(FSAnnot*)annot
{
    if ([annot canModify]) {
        annot.modifiedDate = [NSDate date];
    }
    [_extensionsManager onAnnotModified:[annot getPage] annot:annot];
    int pageIndex = annot.pageIndex;
    CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
    rect =CGRectInset(rect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        double delayInSeconds = .05;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
        });
    });
}

-(void)removeAnnot:(FSAnnot*)annot
{
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:annot.pageIndex];
    if (!page)
        return;

    CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
    int pageIndex = annot.pageIndex;

    [_extensionsManager onAnnotDeleted:page annot:annot];
    [page removeAnnot:annot];
    
    rect = CGRectInset(rect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        double delayInSeconds = .05;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
        });

    });
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
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

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    if (_extensionsManager.currentAnnot == annot) {
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
            return YES;
        } else {
            [_extensionsManager setCurrentAnnot:nil];
            return YES;
        }
    } else {
        [_extensionsManager setCurrentAnnot:annot];
        [self comment];
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    if (_extensionsManager.currentAnnot != annot) {
        return NO;
    }
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        MenuControl* annotMenu = _extensionsManager.menuControl;
        if ([annotMenu isMenuVisible])
        {
            [annotMenu hideMenu];
        }
        UIExtensionsManager* extensionsManager = _extensionsManager;
        if (extensionsManager.propertyBar.isShowing && self.isShowStyle) {
            [extensionsManager.propertyBar dismissPropertyBar];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
        
        CGPoint translationPoint = [recognizer translationInView:pageView];
        float tw = translationPoint.x;
        float th = translationPoint.y;
        if (!annot.canModify) {
            return YES;
        }
        CGRect realRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        FSRectF *rect = [Utility CGRect2FSRectF:realRect];
        
        rect.left += tw;
        rect.right +=tw;
        rect.top += th;
        rect.bottom += th;
        CGRect newRect = [Utility FSRectF2CGRect:rect];
        if (!(newRect.origin.x <=0
              || newRect.origin.x + newRect.size.width >= [_pdfViewCtrl getPageViewWidth:pageIndex]-20
              || newRect.origin.y <= 0
              || newRect.origin.y + newRect.size.height >= [_pdfViewCtrl getPageViewHeight:pageIndex]-20)) {
            rect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:pageIndex];
            annot.fsrect = rect;
            [_pdfViewCtrl refresh:CGRectInset(CGRectUnion(newRect, _lastPanRect), -30, -30) pageIndex:pageIndex needRender:NO];
            _lastPanRect = newRect;
            [recognizer setTranslation:CGPointZero inView:pageView];
        } else {
            return NO;
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        if (annot.canModify) {
            [self modifyAnnot:annot];
        }
        CGRect newRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:newRect pageIndex:annot.pageIndex];
        if (self.isShowStyle)
        {
            self.shouldShowMenu = NO;
            self.shouldShowPropety = YES;
            UIExtensionsManager* extensionsManager = _extensionsManager;
            [extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        }
        else
        {
            self.shouldShowMenu = YES;
            self.shouldShowPropety = NO;
            MenuControl* annotMenu = _extensionsManager.menuControl;
            [annotMenu setRect:showRect];
            [annotMenu showMenu];
        }
        _lastPanRect = newRect;
    }
    
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot*)annot
{
    if ([_extensionsManager getAnnotHandlerByType:annot.type] == self)
    {
        unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
        BOOL canAddAnnot = (allPermission & e_permAnnotForm);
        if (!canAddAnnot) {
            return NO;
        }
        CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint])
        {
            return YES;
        }
        return NO;
    }
    return NO;
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
    if (pageIndex == annot.pageIndex) {
        if (_extensionsManager.currentAnnot == annot) {
            CGRect annotRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            annotRect.origin.x = rect.origin.x;
            annotRect.origin.y = rect.origin.y;
            if (self.annotImage) {
                CGContextSaveGState(context);
                CGContextTranslateCTM(context, annotRect.origin.x, annotRect.origin.y);
                CGContextTranslateCTM(context, 0, annotRect.size.height);
                CGContextScaleCTM(context, 1.0, -1.0);
                CGContextTranslateCTM(context, -annotRect.origin.x, -annotRect.origin.y);
                CGContextDrawImage(context, annotRect, [self.annotImage CGImage]);
                CGContextRestoreGState(context);
            }
            CGRect drawRect = CGRectMake(ceilf(rect.origin.x), ceilf(rect.origin.y), ceilf(annotRect.size.width), ceilf(annotRect.size.height));
            drawRect = CGRectInset(drawRect, -2, -2);
            CGContextSetLineWidth(context, 2.0);
            CGFloat dashArray[] = {3,3,3,3};
            CGContextSetLineDash(context, 3, dashArray, 4);
            CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
            CGContextStrokeRect(context, drawRect);
        }
    }
}


#pragma mark IPropertyBarListener

- (void)onPropertyBarDismiss
{
    FSAnnot* curAnnot = _extensionsManager.currentAnnot;
    if (DEVICE_iPHONE && curAnnot == self.editAnnot && curAnnot.type == e_annotNote) {
        self.isShowStyle = NO;
        self.shouldShowPropety = NO;
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

#pragma mark IRotationEventListener

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self dismissAnnotMenu];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self showAnnotMenu];
}

#pragma mark IGestureEventListener

- (BOOL)onTap:(UITapGestureRecognizer *)recognizer
{
    return NO;
}

- (BOOL)onLongPress:(UILongPressGestureRecognizer *)recognizer
{
    return NO;
}

- (void)onScrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
{
    if (!_isZooming) { // if drag and zoom in the meantime, will show menu/property after the zooming
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView
{
    [self dismissAnnotMenu];
    _isZooming = YES;

}

- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView
{
    [self showAnnotMenu];
    _isZooming = NO;
}

- (void)showAnnotMenu
{
    FSAnnot* curAnnot = _extensionsManager.currentAnnot;
    if (curAnnot == self.editAnnot
        && [_extensionsManager getAnnotHandlerByType:curAnnot.type] == self) {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:_extensionsManager.currentAnnot.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.editAnnot.pageIndex];
        
        CGRect rectDisplayView = [[_pdfViewCtrl getDisplayView] bounds];
        if(CGRectIsEmpty(showRect) || CGRectIsNull(CGRectIntersection(showRect, rectDisplayView)))
            return;
        
        if (self.shouldShowPropety)
        {
            UIExtensionsManager* extensionsManager = _extensionsManager;
            [extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        }
        else if (self.shouldShowMenu)
        {
            MenuControl* annotMenu = _extensionsManager.menuControl;
            [annotMenu setRect:showRect];
            [annotMenu showMenu];
        }
    }
}


- (void)dismissAnnotMenu
{
    FSAnnot* curAnnot = _extensionsManager.currentAnnot;
    if (curAnnot == self.editAnnot && curAnnot.type == e_annotNote) {
        MenuControl* annotMenu = _extensionsManager.menuControl;
        if (annotMenu.isMenuVisible) {
            [annotMenu setMenuVisible:NO animated:YES];
        }
        UIExtensionsManager* extensionsManager = _extensionsManager;
        if (extensionsManager.propertyBar.isShowing) {
            [extensionsManager.propertyBar dismissPropertyBar];
        }
    }
}


-(void)_addAnnot:(FSNote*)annot
{
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:annot.pageIndex];
    if (!page)
        return;
    
    if (annot.replyTo.length > 0) {
        return;
    } else {
        BOOL rectChanged = NO;
        FSRectF *rect = annot.fsrect;
        if (rect.left != 0 && rect.left == rect.right)
        {
            rect.right++;
            rectChanged = YES;
        }
        if (rect.bottom != 0 && rect.bottom == rect.top)
        {
            rect.top++;
            rectChanged = YES;
        }
        if (rectChanged) {
            FSRectF *fsRect = [[FSRectF alloc] init];
            [fsRect set:rect.left bottom:rect.bottom right:rect.right top:rect.top];
            [annot setFsrect:fsRect];
            [fsRect release];
        }
        
        NSDate *now = [NSDate date];
        FSDateTime *time = [Utility convert2FSDateTime:now];
        [annot setCreationDateTime:time];
        [annot setModifiedDateTime:time];

        unsigned int flags = e_annotFlagPrint|e_annotFlagNoZoom|e_annotFlagNoRotate;
        [annot setFlags:flags];
        [_extensionsManager onAnnotAdded:page annot:annot];
    }
}

#pragma mark IDocEventListener

- (void)onDocWillClose:(FSPDFDoc* )document
{
    if (self.currentVC) {
        [self.currentVC dismissViewControllerAnimated:NO completion:nil];
    }
}

#pragma IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotNote) {
        [self annotPropertyChanged];
    }
}

- (void)onAnnotOpacityChanged:(unsigned int)opacity annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotNote) {
        [self annotPropertyChanged];
    }
}

- (void)onAnnotIconChanged:(int)icon annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotNote) {
        [self annotPropertyChanged];
    }
}

- (void)annotPropertyChanged
{
    if (self.editAnnot && self.annotImage) {
        self.annotImage = [Utility getAnnotImage:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        int pageIndex = self.editAnnot.pageIndex;
        CGRect rect = [Utility getAnnotRect:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        [_pdfViewCtrl refresh:CGRectInset(rect, -30, -30) pageIndex:pageIndex needRender:NO];
    }
}

@end
