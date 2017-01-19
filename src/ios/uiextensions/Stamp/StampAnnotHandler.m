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
#import "StampAnnotHandler.h"
#import "ShapeUtil.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "UIExtensionsManager.h"
#import "PropertyBar.h"
#import "Utility.h"
#import "ColorUtility.h"

@interface StampAnnotHandler ()

@property (nonatomic, retain) FSAnnot *editAnnot;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, retain) FSRectF *currentRect;

@end

@implementation StampAnnotHandler {
    FSPDFViewCtrl* _pdfViewCtrl;
    TaskServer* _taskServer;
    UIExtensionsManager* _extensionsManager;
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
        
        self.editAnnot = nil;
        _currentRect = nil;
        self.shouldShowMenu = NO;
    }
    return self;
}

-(void)dealloc
{
    [_editAnnot release];
    [_replyVC release];
    [_annotImage release];
    [_currentRect release];
    [super dealloc];
}

-(enum FS_ANNOTTYPE)getType
{
    return e_annotStamp;
}

-(BOOL)isHitAnnot:(FSAnnot*)annot point:(FSPointF*)point
{
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    pvRect = CGRectInset(pvRect, -30, -30);
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
    self.currentRect = annot.fsrect;
    int pageIndex = annot.pageIndex;
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    
    _maxWidth = pageView.bounds.size.width;
    _minWidth = 10;
    _maxHeight = pageView.bounds.size.height;
    _minHeight = 10;
    
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    
    NSMutableArray *array = [NSMutableArray array];
    
    MenuItem *commentItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *openItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *replyItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kReply", nil) object:self action:@selector(reply)] autorelease];
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
        [array addObject:deleteItem];
    }
    else
    {
        [array addObject:commentItem];
        [array addObject:replyItem];
    }
    
    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
    MenuControl* annotMenu = _extensionsManager.menuControl;
    annotMenu.menuItems = array;
    [annotMenu setRect:dvRect];
    [annotMenu showMenu];
    self.shouldShowMenu = YES;
    
    self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
    rect = CGRectInset(rect, -30, -30);
    [_pdfViewCtrl refresh:rect pageIndex:pageIndex needRender:YES];
}

-(void)comment
{
    NSMutableArray *replyAnnots = [[[NSMutableArray alloc] init] autorelease];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
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
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
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
        [self removeAnnot:annot];
    };
    [_taskServer executeSync:task];
    [_extensionsManager setCurrentAnnot:nil];
}

-(void)onAnnotDeselected:(FSAnnot*)annot
{
    if (_extensionsManager.menuControl.isMenuVisible) {
        [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
    }
    self.shouldShowMenu = NO;
    self.editAnnot = nil;
    self.annotImage = nil;
    
    int pageIndex = annot.pageIndex;
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    newRect = CGRectInset(newRect, -30, -30);
    [_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:YES];
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
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
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
    if (_extensionsManager.currentAnnot != annot || pageIndex != annot.pageIndex)
    {
        return NO;
    }
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        self.shouldShowMenu = NO;
        if ([_extensionsManager.menuControl isMenuVisible])
        {
            [_extensionsManager.menuControl hideMenu];
        }
        _editType = [ShapeUtil getEditTypeWithPoint:point rect:CGRectInset(pvRect, -10, -10) defaultEditType:EDIT_ANNOT_RECT_TYPE_FULL];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translationPoint = [recognizer translationInView:pageView];
        float tw = translationPoint.x;
        float th = translationPoint.y;
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
        self.currentRect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:pageIndex];
        annot.fsrect = self.currentRect;
        [_pdfViewCtrl refresh:CGRectInset(CGRectUnion(newRect, pvRect), -30, -30) pageIndex:pageIndex needRender:NO];
        [recognizer setTranslation:CGPointZero inView:pageView];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        _editType = EDIT_ANNOT_RECT_TYPE_UNKNOWN;
        if (annot.canModify) {
            [self modifyAnnot:annot];
        }
        
        self.shouldShowMenu = YES;
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:pageIndex];
        [_extensionsManager.menuControl setRect:showRect];
        [_extensionsManager.menuControl showMenu];
    }
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot*)annot
{
    if (annot.type == e_annotStamp)
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
    if (pageIndex == annot.pageIndex && _extensionsManager.currentAnnot == annot && annot.type == e_annotStamp) {
        CGRect rect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        
        CGContextSaveGState(context);
        
        if (self.annotImage) {
            CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
            CGContextTranslateCTM(context, 0, rect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
            CGContextDrawImage(context, rect, [self.annotImage CGImage]);
        }
        
        CGContextRestoreGState(context);
        
        rect = CGRectInset(rect, -10,-10);
        CGContextSetLineWidth(context, 2.0);
        CGFloat dashArray[] = {3,3,3,3};
        CGContextSetLineDash(context, 3, dashArray, 4);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:0x179cd8] CGColor]);
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
    if (DEVICE_iPHONE && _extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotStamp) {
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView
{
    [self dismissAnnotMenu];
    
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView
{
    [self showAnnotMenu];
}

- (void)showAnnotMenu
{
    if (_extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotStamp) {
        if (self.shouldShowMenu)
        {
            int pageIndex = self.editAnnot.pageIndex;
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:pageIndex];
            CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
            [_extensionsManager.menuControl setRect:showRect];
            [_extensionsManager.menuControl showMenu];
        }
    }
}

- (void)dismissAnnotMenu
{
    if (_extensionsManager.currentAnnot == self.editAnnot && _extensionsManager.currentAnnot.type == e_annotStamp) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
    }
}

@end
