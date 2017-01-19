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
#import "ShapeAnnotHandler.h"
#import "ShapeUtil.h"
#import "ReplyTableViewController.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "FSAnnotExtent.h"
#import "ReplyUtil.h"
#import "ColorUtility.h"

@interface ShapeAnnotHandler () <IDocEventListener>

@property (nonatomic, retain) NSArray *colors;
@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, retain) FSAnnot *editAnnot;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;
@property (nonatomic, assign) CGRect currentAnnotRect;
@property (nonatomic, retain) UIImage *annotImage;

@end

@implementation ShapeAnnotHandler {
    UIExtensionsManager* _extensionsManager;
    FSPDFViewCtrl* _pdfViewCtrl;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [_pdfViewCtrl registerDocEventListener:self];
        [_extensionsManager registerAnnotHandler:self];
        [_pdfViewCtrl registerDocEventListener:self];
        [_pdfViewCtrl registerScrollViewEventListener:self];
        [_extensionsManager registerRotateChangedListener:self];
        [_extensionsManager registerGestureEventListener:self];
        [_extensionsManager.propertyBar registerPropertyBarListener:self];
        [_extensionsManager registerPropertyBarListener:self];
        self.colors = @[@0xFF9F40,@0x8080FF,@0xBAE94C,@0xFFF160,@0xC3C3C3,@0xFF4C4C,@0x669999,@0xC72DA1,@0x996666,@0x000000];
        self.isShowStyle = NO;
        self.editAnnot = nil;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
    }
    return self;
}

-(enum FS_ANNOTTYPE)getType
{
    return e_annotCircle;
}

-(void)dealloc
{
    [_replyVC release];
    [_colors release];
    [_editAnnot release];
    [_annotImage release];
    [super dealloc];
}

-(BOOL)isHitAnnot:(FSAnnot*)annot point:(FSPointF*)point
{
    int pageIndex = annot.pageIndex;
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:pageIndex];
    return CGRectContainsPoint(CGRectInset(pvRect, -20, -20), pvPoint);
}

-(void)onAnnotSelected:(FSAnnot*)annot
{
    self.editAnnot = annot;
    self.currentAnnotRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
    UIView* pageView = [_pdfViewCtrl getPageView:annot.pageIndex];
    
    _maxWidth = pageView.bounds.size.width;
    _minWidth = 10;
    _maxHeight = pageView.bounds.size.height;
    _minHeight = 10;
    
    
    NSMutableArray *array = [NSMutableArray array];
    
    MenuItem *commentItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *openItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *replyItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kReply", nil) object:self action:@selector(reply)] autorelease];
    MenuItem *styleItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kStyle", nil) object:self action:@selector(showStyle)] autorelease];
    MenuItem *deleteItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kDelete", nil) object:self action:@selector(delete:)] autorelease];
    if (annot.canModify) {
        if (annot.contents == nil || [annot.contents isEqualToString:@""]) {
            [array addObject:commentItem];
        }
        else
        {
            [array addObject:openItem];
        }
        [array addObject:replyItem];
        [array addObject:styleItem];
        [array addObject:deleteItem];
    }
    else
    {
        [array addObject:commentItem];
        [array addObject:replyItem];
    }
    
    
    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:self.currentAnnotRect pageIndex:annot.pageIndex];
    
    _extensionsManager.menuControl.menuItems = array;
    [_extensionsManager.menuControl setRect:dvRect margin:20];
    [_extensionsManager.menuControl showMenu];
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;

    self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
    [_pdfViewCtrl refresh:CGRectInset(self.currentAnnotRect, -30, -30) pageIndex:annot.pageIndex needRender:YES];
}

-(void)comment
{
    NSMutableArray *replyAnnots = [[[NSMutableArray alloc] init] autorelease];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager] autorelease];
    self.replyVC = replyCtr;
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
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager] autorelease];
    self.replyVC = replyCtr;
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

-(void)delete:(id)sender
{
    FSAnnot *annot = _extensionsManager.currentAnnot;
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        [self deleteAnnot:annot];
    };
    [_extensionsManager.taskServer executeSync:task];
    [_extensionsManager setCurrentAnnot:nil];
}

-(void)deleteAnnot:(FSAnnot*)annot
{
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    rect = CGRectInset(rect, -20, -20);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_extensionsManager onAnnotDeleted:[_pdfViewCtrl.currentDoc getPage:pageIndex] annot:annot];
        [[_pdfViewCtrl.currentDoc getPage:pageIndex] removeAnnot:annot];
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

-(void)showStyle
{
    [_extensionsManager.propertyBar setColors:self.colors];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_LINEWIDTH];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity*100.0];
    [_extensionsManager.propertyBar setProperty:PROPERTY_LINEWIDTH intValue:annot.lineWidth];
    [_extensionsManager.propertyBar addListener:_extensionsManager];
    
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:annot.pageIndex];
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
    self.editAnnot = nil;
    
    int pageIndex = annot.pageIndex;
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    newRect = CGRectInset(newRect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:YES];
    });

}

-(void)addAnnot:(FSAnnot*)annot
{
    [_extensionsManager onAnnotAdded:[annot getPage] annot:annot];
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect = CGRectInset(rect, -30, -30);
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
    rect =CGRectInset(rect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:annot.pageIndex];
    });
}

-(void)removeAnnot:(FSAnnot*)annot
{
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect = CGRectInset(rect, -30, -30);
    int pageIndex = annot.pageIndex;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_extensionsManager onAnnotDeleted:[_pdfViewCtrl.currentDoc getPage:pageIndex] annot:annot];
        [[_pdfViewCtrl.currentDoc getPage:pageIndex] removeAnnot:annot];
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
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
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:annot.pageIndex]];
    FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:annot.pageIndex];
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
        return  YES;
    }
    return NO;
}


- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    if (_extensionsManager.currentAnnot != annot || annot.pageIndex != pageIndex)
    {
        return NO;
    }
    
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    
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
        CGRect oldRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        
        CGPoint translationPoint = [recognizer translationInView:[_pdfViewCtrl getPageView:pageIndex]];
        float tw = translationPoint.x;
        float th = translationPoint.y;
        CGRect realRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
        FSRectF* rect = [Utility CGRect2FSRectF:realRect];
        
        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_LEFTMIDDLE ||
            _editType == EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL)
        {
            if (!annot.canModify) {
                return YES;
            }
            rect.left += tw;
            if (rect.left < _minWidth) {
                return NO;
            }
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL)
            {
                // Not left over right
                if ((rect.left + _minWidth) > rect.right)
                {
                    rect.right = rect.left + _minWidth;
                    if (rect.right > _maxWidth - _minWidth) {
                        return NO;
                    }
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
            if (rect.right > _maxWidth - _minWidth) {
                return NO;
            }
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL)
            {
                if ((rect.left + _minWidth) > rect.right)
                {
                    rect.left = rect.right - _minWidth;
                    if (rect.left < _minWidth) {
                        return NO;
                    }
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
            if (rect.top < _minHeight) {
                return NO;
            }
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL)
            {
                if ((rect.top + _minHeight) > rect.bottom)
                {
                    rect.bottom = rect.top + _minHeight;
                    if (rect.bottom > _maxHeight - _minHeight) {
                        return NO;
                    }
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
            if (rect.bottom > _maxHeight - _minHeight) {
                return NO;
            }
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL)
            {
                if ((rect.top + _minHeight) > rect.bottom)
                {
                    rect.top = rect.bottom - _minHeight;
                    if (rect.top < _minHeight) {
                        return NO;
                    }
                }
                else if (ABS(rect.bottom - rect.top) > _maxHeight)
                {
                    rect.bottom -= th;
                }
            }
        }
        
        [recognizer setTranslation:CGPointZero inView:[_pdfViewCtrl getPageView:pageIndex]];
        CGRect newRect = [Utility FSRectF2CGRect:rect];
        rect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:pageIndex];
        annot.fsrect = rect;
        self.currentAnnotRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
        newRect = CGRectUnion(newRect, oldRect);
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:NO];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        _editType = EDIT_ANNOT_RECT_TYPE_UNKNOWN;
        if (annot.canModify) {
            [self modifyAnnot:annot];
        }
        
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:self.currentAnnotRect pageIndex:pageIndex];
        if (self.isShowStyle && !DEVICE_iPHONE)
        {
            self.shouldShowMenu = NO;
            self.shouldShowPropety = YES;
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:[_pdfViewCtrl getDisplayView] viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
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
    if ([_extensionsManager getAnnotHandlerByType:annot.type] == self)
    {
        unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
        BOOL canAddAnnot = (allPermission & e_permAnnotForm);
        if (!canAddAnnot) {
            return NO;
        }
        CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:annot.pageIndex]];
        FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:annot.pageIndex];
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint])
        {
            return YES;
        }
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
    if (_extensionsManager.currentAnnot == annot && pageIndex == annot.pageIndex &&
        (annot.type == e_annotCircle || annot.type == e_annotSquare)) {
        CGRect rect = self.currentAnnotRect;
        if (CGRectEqualToRect(rect, CGRectZero))
        {
            rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];        }
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

#pragma mark IRotationEventListener

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self dismissAnnotMenu];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self showAnnotMenu];
    
}

#pragma mark IPropertyBarListener

- (void)onPropertyBarDismiss
{
    if (DEVICE_iPHONE && self.editAnnot && _extensionsManager.currentAnnot == self.editAnnot) {
        self.isShowStyle = NO;
        self.shouldShowPropety = NO;
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDragging:(UIScrollView*)dviewer
{
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView*)dviewer willDecelerate:(BOOL)decelerate
{
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView*)dviewer
{
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView*)dviewer
{
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView*)dviewer
{
    [self dismissAnnotMenu];
    self.currentAnnotRect = CGRectZero; // saved rect is invalid if zoomed
}

- (void)onScrollViewDidEndZooming:(UIScrollView*)dviewer
{
    [self showAnnotMenu];
}

- (void)showAnnotMenu
{
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:self.editAnnot.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.editAnnot.pageIndex];

        if (self.shouldShowPropety)
        {
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:[_pdfViewCtrl getDisplayView] viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
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
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
        if (_extensionsManager.propertyBar.isShowing) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
    }
}

#pragma mark IDocEventListener

- (void)onDocWillClose:(FSPDFDoc* )document
{
    if (self.replyVC) {
        [self.replyVC dismissViewControllerAnimated:NO completion:nil];
    }
}

#pragma IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotCircle || annotType == e_annotSquare) {
        [self annotPropertyChanged];
    }
}
- (void)onAnnotOpacityChanged:(unsigned int)opacity annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotCircle || annotType == e_annotSquare) {
        [self annotPropertyChanged];
    }
}

- (void)onAnnotLineWidthChanged:(unsigned int)lineWidth annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotCircle || annotType == e_annotSquare) {
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
