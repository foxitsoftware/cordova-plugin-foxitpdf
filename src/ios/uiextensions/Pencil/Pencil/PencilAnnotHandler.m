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
#import "PencilAnnotHandler.h"
#import "ShapeUtil.h"
#import "ReplyUtil.h"
#import "ReplyTableViewController.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "PropertyBar.h"
#import "ColorUtility.h"

@interface PencilAnnotHandler ()

@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;

@property (nonatomic, retain) FSAnnot *editAnnot;
@property (nonatomic, retain) UIImage *annotImage;

@end

@implementation PencilAnnotHandler {
    FSPDFViewCtrl* _pdfViewCtrl;
    TaskServer* _taskServer;
    UIExtensionsManager* _extensionsManager;
    float _annotMargin;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        [_pdfViewCtrl registerScrollViewEventListener:self];
        [_extensionsManager registerAnnotHandler:self];
        [_extensionsManager registerRotateChangedListener:self];
        [_extensionsManager registerGestureEventListener:self];
        [_extensionsManager.propertyBar registerPropertyBarListener:self];
        [_extensionsManager registerPropertyBarListener:self];
        
        self.isShowStyle = NO;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        self.editAnnot = nil;
        _annotMargin = 20 + [UIImage imageNamed:@"annotation_drag.png"].size.width;
    }
    return self;
}

-(enum FS_ANNOTTYPE)getType
{
    return e_annotInk;
}

- (void)dealloc
{
    [_annotImage release];
    [_editAnnot release];
    [_replyVC release];
    [super dealloc];
}

-(BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF*)point
{
    int pageIndex = annot.pageIndex;
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:pageIndex];
    return CGRectContainsPoint(CGRectInset(pvRect, -20, -20), pvPoint);
}

-(void)onAnnotSelected:(FSAnnot*)annot
{
    if ([[[_extensionsManager getCurrentToolHandler] getName] isEqualToString:Tool_Eraser]) {
        //noop, todo, add to undo/redo
        return;
    }
    self.editAnnot = annot;
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex ];
    
    _maxWidth = [_pdfViewCtrl getPageViewWidth:pageIndex];
    _minWidth = 10;
    _maxHeight = [_pdfViewCtrl getPageViewHeight:pageIndex];
    _minHeight = 10;
    
    NSMutableArray *array = [NSMutableArray array];
    
    MenuItem *commentItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *openItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *replyItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kReply", nil) object:self action:@selector(reply)] autorelease];
    MenuItem *styleItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kStyle", nil) object:self action:@selector(showStyle)] autorelease];
    MenuItem *deleteItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kDelete", nil) object:self action:@selector(delete:)] autorelease];
    if (annot.canModify) {
        [array addObject:styleItem];
        if (annot.contents == nil || [annot.contents isEqualToString:@""]) {
            [array addObject:commentItem];
        }
        else
        {
            [array addObject:openItem];
        }
        [array addObject:replyItem];
        [array addObject:deleteItem];
    }
    else
    {
        [array addObject:commentItem];
        [array addObject:replyItem];
    }
    
    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
    _extensionsManager.menuControl.menuItems = array;
    [_extensionsManager.menuControl setRect:dvRect margin:20];
    [_extensionsManager.menuControl showMenu];
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;
    
    self.annotImage = [Utility getAnnotImage:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
    
    rect = CGRectInset(rect, -_annotMargin, -_annotMargin);
    [_pdfViewCtrl refresh:rect pageIndex:pageIndex needRender:YES];
}

-(void)comment
{
    NSMutableArray *replyAnnots = [[[NSMutableArray alloc] init] autorelease];
    FSAnnot* annot = _extensionsManager.currentAnnot;
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:annot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
    self.replyVC = replyCtr;
    replyCtr.isNeedReply = NO;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:annot];
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

-(void)reply
{
    NSMutableArray *replyAnnots = [[[NSMutableArray alloc] init] autorelease];
    FSAnnot* annot = _extensionsManager.currentAnnot;
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:annot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
    self.replyVC = replyCtr;
    replyCtr.isNeedReply = YES;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:annot];
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
-(void)delete:(id)sender
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
    [_extensionsManager.propertyBar setColors:@[@0xFF9F40,@0x8080FF,@0xBAE94C,@0xFFF160,@0xC3C3C3,@0xFF4C4C,@0x669999,@0xC72DA1,@0x996666,@0x000000]];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_LINEWIDTH];
    FSAnnot* annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity*100.0];
    [_extensionsManager.propertyBar setProperty:PROPERTY_LINEWIDTH intValue:annot.lineWidth];
    [_extensionsManager.propertyBar addListener:_extensionsManager];
    
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
    NSArray *array = [NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]];
    [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:array];
    self.isShowStyle = YES;
    self.shouldShowMenu = NO;
    self.shouldShowPropety = YES;
}

-(void)onAnnotDeselected:(FSAnnot*)annot
{
    if (_extensionsManager.menuControl.isMenuVisible) {
        [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
    }
    if (_extensionsManager.propertyBar.isShowing) {
        [_extensionsManager.propertyBar dismissPropertyBar];
        self.isShowStyle = NO;
        
    }
    self.shouldShowMenu = NO;
    self.shouldShowPropety = NO;
    
    self.annotImage = nil;
    
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    newRect = CGRectInset(newRect, -_annotMargin, -_annotMargin);
    [_pdfViewCtrl refresh:newRect pageIndex:annot.pageIndex needRender:YES];
}

-(void)addAnnot:(FSAnnot*)annot
{
    [_extensionsManager onAnnotAdded:[annot getPage] annot:annot];
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    rect = CGRectInset(rect, -20, -20);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

-(void)modifyAnnot:(FSAnnot*)annot
{
    if ([annot canModify]) {
        annot.modifiedDate = [NSDate date];
    }
    [_extensionsManager onAnnotModified:[annot getPage] annot:annot];
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect =CGRectInset(rect, -_annotMargin, -_annotMargin);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:annot.pageIndex];
    });
}

-(void)removeAnnot:(FSAnnot*)annot
{
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect = CGRectInset(rect, -_annotMargin, -_annotMargin);
    
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    [_extensionsManager onAnnotDeleted:page annot:annot];
    [page removeAnnot:annot];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex needRender:YES];
    });
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
    BOOL canAddAnnot = (allPermission & e_permAnnotForm);
    if (!canAddAnnot) {
        return NO;
        
    }
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    if (_extensionsManager.currentAnnot == annot)
    {
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint])
        {
            return YES;
        }
        else
        {
            [_extensionsManager setCurrentAnnot:nil];
            return YES;
        }
    }
    else
    {
        [_extensionsManager setCurrentAnnot:annot];
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    FSInk *pencilAnnot = (FSInk*)annot;
    if (_extensionsManager.currentAnnot != annot || pageIndex != annot.pageIndex)
    {
        return NO;
    }
    
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        if ([_extensionsManager.menuControl isMenuVisible])
        {
            [_extensionsManager.menuControl hideMenu];
        }
        if (_extensionsManager.propertyBar.isShowing && self.isShowStyle) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
        _editType = [ShapeUtil getEditTypeWithPoint:point rect:CGRectInset([_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex], -10, -10) defaultEditType:EDIT_ANNOT_RECT_TYPE_FULL];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translationPoint = [recognizer translationInView:pageView];
        float tw = translationPoint.x;
        float th = translationPoint.y;
        CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:pencilAnnot.fsrect pageIndex:pageIndex];
        FSRectF* rect = [Utility CGRect2FSRectF:pvRect];
        FSRectF* oldRect = [[[FSRectF alloc] init] autorelease];
        [oldRect set:rect.left bottom:rect.bottom right:rect.right top:rect.top];
        
        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_LEFTMIDDLE ||
            _editType == EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL)
        {
            if (!annot.canModify) {
                return YES;
            }
            rect.left += tw;
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL)
            {
                // Not left over right
                if ((rect.left + _minWidth) > rect.right)
                {
                    rect.right = rect.left + _minWidth;
                }
                else if (ABS(rect.right - rect.left) > _maxWidth)
                {
                    rect.left -= tw;
                }
            }
        }
        if (_editType == EDIT_ANNOT_RECT_TYPE_RIGHTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTMIDDLE ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL)
        {
            if (!annot.canModify) {
                return YES;
            }
            rect.right +=tw;
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL)
            {
                if ((rect.left + _minWidth) > rect.right)
                {
                    rect.left = rect.right - _minWidth;
                }
                else if (ABS(rect.right - rect.left) > _maxWidth)
                {
                    rect.right -= tw;
                }
            }
        }
        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_MIDDLETOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL)
        {
            if (!annot.canModify) {
                return YES;
            }
            rect.top += th;
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL)
            {
                if ((rect.top + _minHeight) > rect.bottom)
                {
                    rect.bottom = rect.top + _minHeight;
                }
                else if (ABS(rect.bottom - rect.top) > _maxHeight)
                {
                    rect.top -= th;
                }
            }
        }
        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_MIDDLEBOTTOM||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL)
        {
            if (!annot.canModify) {
                return YES;
            }
            rect.bottom += th;
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL)
            {
                if ((rect.top + _minHeight) > rect.bottom)
                {
                    rect.top = rect.bottom - _minHeight;
                }
                else if (ABS(rect.bottom - rect.top) > _maxHeight)
                {
                    rect.bottom -= th;
                }
            }
        }
        if ((rect.left < _minWidth && rect.left < oldRect.left) ||
            (rect.right > _maxWidth - _minWidth && rect.right > oldRect.right) ||
            (rect.bottom > _maxHeight - _minHeight && rect.bottom > oldRect.bottom) ||
            (rect.top < _minHeight && rect.top < oldRect.top)) {
            return NO;
        }
        
        CGRect newRect = [Utility FSRectF2CGRect:rect];
        rect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:pageIndex];
        annot.fsrect = rect;
        
        self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
        [_pdfViewCtrl refresh:CGRectInset(CGRectUnion(newRect, pvRect), -_annotMargin, -_annotMargin) pageIndex:pageIndex needRender:NO];
        
        [recognizer setTranslation:CGPointZero inView:pageView];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        _editType = EDIT_ANNOT_RECT_TYPE_UNKNOWN;
        if (annot.canModify) {
            [self modifyAnnot:pencilAnnot];
        }
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:pencilAnnot.fsrect pageIndex:pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:newRect pageIndex:annot.pageIndex];
        if (self.isShowStyle && !DEVICE_iPHONE)
        {
            self.shouldShowMenu = NO;
            self.shouldShowPropety = YES;
            NSArray *array = [NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]];
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:array];
        }
        else
        {
            self.shouldShowMenu = YES;
            self.shouldShowPropety = NO;
            [_extensionsManager.menuControl setRect:showRect margin:20];
            [_extensionsManager.menuControl showMenu];
        }
    }
    
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot*)annot
{
    if (annot.type == e_annotInk)
    {
        unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
        BOOL canAddAnnot = (allPermission & e_permAnnotForm);
        if (!canAddAnnot) {
            return NO;
        }
        UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
        CGPoint point = [gestureRecognizer locationInView:pageView];
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
    if (_extensionsManager.currentAnnot == annot && pageIndex == annot.pageIndex)
    {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        if (self.annotImage) {
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
            CGContextTranslateCTM(context, 0, rect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
            CGContextDrawImage(context, rect, [self.annotImage CGImage]);
            CGContextRestoreGState(context);
        }
        
		
        rect = CGRectInset(rect, -10,-10);
        
        CGContextSetLineWidth(context, 2.0);
        CGFloat dashArray[] = {3,3,3,3};
        CGContextSetLineDash(context, 3, dashArray, 4);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
        CGContextStrokeRect(context, rect);
        
        UIImage *dragDot = [UIImage imageNamed:@"annotation_drag.png"];
        NSArray *movePointArray = [ShapeUtil getMovePointInRect:rect];
        [movePointArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect dotRect = [obj CGRectValue];
            CGPoint point = CGPointMake(dotRect.origin.x, dotRect.origin.y);
            [dragDot drawAtPoint:point];
        }];
    }
}

- (void)onRotateChangedBefore:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self dismissAnnotMenu];
}

-(void)onRotateChangedAfter:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self showAnnotMenu];
}

#pragma mark IPropertyBarListener

- (void)onPropertyBarDismiss
{
    if (DEVICE_iPHONE && _extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotInk) {
        self.isShowStyle = NO;
        self.shouldShowPropety = NO;
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDragging:(UIScrollView *)dviewer
{
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)dviewer willDecelerate:(BOOL)decelerate
{
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)dviewer
{
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)dviewer
{
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)dviewer
{
    [self dismissAnnotMenu];
    
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)dviewer
{
    [self showAnnotMenu];
}

- (void)showAnnotMenu
{
    if (_extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotInk) {
        int pageIndex = self.editAnnot.pageIndex;
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
        
        if (self.shouldShowPropety)
        {
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        }
        else if (self.shouldShowMenu)
        {
            [_extensionsManager.menuControl setRect:showRect margin:20];
            [_extensionsManager.menuControl showMenu];
        }
    }
}

- (void)dismissAnnotMenu
{
    if (_extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotInk) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
        if (_extensionsManager.propertyBar.isShowing) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
    }
}

#pragma IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotInk) {
        [self annotPropertyChanged];
    }
}
- (void)onAnnotOpacityChanged:(unsigned int)opacity annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotInk) {
        [self annotPropertyChanged];
    }
}

- (void)onAnnotLineWidthChanged:(unsigned int)lineWidth annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotInk) {
        [self annotPropertyChanged];
    }
}

- (void)annotPropertyChanged
{
    if (self.editAnnot && self.annotImage) {
        self.annotImage = [Utility getAnnotImage:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        int pageIndex = self.editAnnot.pageIndex;
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:pageIndex];
        [_pdfViewCtrl refresh:CGRectInset(newRect, -20, -20) pageIndex:pageIndex needRender:NO];
    }
}

@end
