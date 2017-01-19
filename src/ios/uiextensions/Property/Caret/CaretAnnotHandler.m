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

#import "CaretAnnotHandler.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "UIExtensionsManager.h"
#import "PropertyBar.h"
#import "ColorUtility.h"

#define FSPDF_ANNOT_INTENTNAME_CARET_REPLACE		"Replace"
#define FSPDF_ANNOT_INTENTNAME_CARET_INSERTTEXT		"Insert Text"


@interface CaretAnnotHandler ()
@property (nonatomic, strong) FSAnnot *editAnnot;
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;
@property (nonatomic, assign) UIUserInterfaceSizeClass currentSizeclass;
@end

@implementation CaretAnnotHandler {
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
        
        self.colors = @[@0xFF9F40,@0x8080FF,@0xBAE94C,@0xFFF160,@0x996666,@0xFF4C4C,@0x669999,@0xFFFFFF,@0xC3C3C3,@0x000000];
        self.isShowStyle = NO;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        self.editAnnot = nil;
        
    }
    return self;
}

- (void)dealloc
{
    [_editAnnot release];
    [_colors release];
    [_annotImage release];
    [_currentVC release];
    [super dealloc];
}

-(enum FS_ANNOTTYPE)getType
{
    return e_annotCaret;
}

-(BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF*)point
{
    FSCaret* caret = (FSCaret*)annot;
    int pageIndex = annot.pageIndex;
    CGPoint pt = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:pageIndex];
    if ([caret isGrouped]) {
        for (int i = 0; i < [caret getGroupElementCount]; i ++) {
            FSAnnot* groupAnnot = [caret getGroupElement:i];
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:groupAnnot.fsrect pageIndex:pageIndex];
            rect = CGRectInset(rect, -10, -10);
            if (CGRectContainsPoint(rect, pt)) {
                return YES;
            }
        }
        return NO;
    } else {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:caret.fsrect pageIndex:pageIndex];
        rect = CGRectMake(rect.origin.x, rect.origin.y, 32, 32);
        rect = CGRectInset(rect, -10, -10);
        return CGRectContainsPoint(rect, pt);
    }
}

-(void)onAnnotSelected:(FSAnnot*)annot
{
    self.editAnnot = annot;
    int pageIndex = annot.pageIndex;
    NSMutableArray *array = [NSMutableArray array];
    MenuItem *commentItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *replyItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kReply", nil) object:self action:@selector(reply)] autorelease];
    if ([annot.intent isEqualToString:@"Replace"]) {
        if (annot.canModify) {
            MenuItem *styleReplaceItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kStyle", nil) object:self action:@selector(showReplaceStyle)] autorelease];
            [array addObject:styleReplaceItem];
            _isInsert = NO;
        }
    }else{
        if (annot.canModify) {
            MenuItem *styleInsertItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kStyle", nil) object:self action:@selector(showInsertStyle)] autorelease];
            [array addObject:styleInsertItem];
            _isInsert = YES;
        }
    }
    
    MenuItem *deleteItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kDelete", nil) object:self action:@selector(deleteAnnot)] autorelease];
    
    if (annot.canModify) {
        [array addObject:commentItem];
        [array addObject:replyItem];
        [array addObject:deleteItem];
    }
    else
    {
        [array addObject:commentItem];
        if (annot.canReply) {
            [array addObject:replyItem];
        }
    }
    CGRect caretRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:caretRect pageIndex:pageIndex];
    _extensionsManager.menuControl.menuItems = array;
    [_extensionsManager.menuControl setRect:dvRect];
    [_extensionsManager.menuControl showMenu];
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;

    CGRect pvRect = [self getPageViewRectForCaret:(FSMarkup*)annot pageIndex:pageIndex];
    [_pdfViewCtrl refresh:CGRectInset(pvRect, -30, -30) pageIndex:pageIndex needRender:NO];

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
    NSMutableArray *replyAnnots = [[NSMutableArray alloc] init];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
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
        [_extensionsManager setCurrentAnnot:nil];
    };
    replyCtr.editingCancelHandler = ^()
    {
        [_extensionsManager setCurrentAnnot:nil];
    };
}

-(void)reply
{
    NSMutableArray *replyAnnots = [[NSMutableArray alloc] init];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
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
        [_extensionsManager setCurrentAnnot:nil];
    };
    replyCtr.editingCancelHandler = ^()
    {
        [_extensionsManager setCurrentAnnot:nil];
    };
}

-(void)deleteAnnot
{
    FSAnnot *annot = _extensionsManager.currentAnnot;
    Task *task = [[Task alloc] init];
    task.run = ^(){
        [self removeAnnot:annot];
    };
    [_taskServer executeSync:task];
    [_extensionsManager setCurrentAnnot:nil];
}

-(void)showReplaceStyle
{
    BOOL isContain = NO;
    UInt32 firstColor = [_extensionsManager getAnnotColor:e_annotCaret];
    for (NSNumber *value in self.colors) {
        if (firstColor == value.intValue) {
            isContain = YES;
            break;
        }
    }
    
    if (!isContain) {
        self.colors = @[[NSNumber numberWithInt:firstColor],@0x8080FF,@0xBAE94C,@0xFFF160,@0x996666,@0xFF4C4C,@0x669999,@0xFFFFFF,@0xC3C3C3,@0x000000];
    }
    [_extensionsManager.propertyBar setColors:self.colors];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity*100.0];
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

-(void)showInsertStyle
{
    BOOL isContain = NO;
    UInt32 firstColor = [_extensionsManager getAnnotColor:e_annotCaret];
    for (NSNumber *value in self.colors) {
        if (firstColor == value.intValue) {
            isContain = YES;
            break;
        }
    }
    
    if (!isContain) {
        self.colors = @[[NSNumber numberWithInt:firstColor],@0x8080FF,@0xBAE94C,@0xFFF160,@0x996666,@0xFF4C4C,@0x669999,@0xFFFFFF,@0xC3C3C3,@0x000000];
    }
    [_extensionsManager.propertyBar setColors:self.colors];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity*100.0];
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


- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
}

- (CGRect)getPageViewRectForCaret:(FSMarkup*)caret pageIndex:(int)pageIndex
{
    if ([caret isGrouped]) { //replace
        CGRect unionRect = CGRectZero;
        for (int i = 0; i < [caret getGroupElementCount]; i ++) {
            FSAnnot* annot = [caret getGroupElement:i];
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            if (CGRectIsEmpty(unionRect))
                unionRect = rect;
            else
                unionRect = CGRectUnion(unionRect, rect);
        }
        return unionRect;
    } else {
        return [_pdfViewCtrl convertPdfRectToPageViewRect:caret.fsrect pageIndex:pageIndex];
    }

}

-(void)onAnnotDeselected:(FSAnnot*)annot
{
    self.editAnnot = nil;
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
    
    int pageIndex = annot.pageIndex;
    CGRect unionRect = [self getPageViewRectForCaret:(FSMarkup*)annot pageIndex:pageIndex];
    
    unionRect = CGRectInset(unionRect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:unionRect pageIndex:pageIndex needRender:NO];
    });
}

-(void)addAnnot:(FSAnnot *)annot
{
    Task *task = [[Task alloc] init];
    task.run = ^()
    {
        [_extensionsManager onAnnotAdded:[annot getPage] annot:annot];
        int pageIndex = annot.pageIndex;
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        rect =CGRectInset(rect, -30, -30);
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    };
    [_taskServer executeSync:task];
    [task release];
}

-(void)modifyAnnot:(FSAnnot *)annot
{
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    rect =CGRectInset(rect, -30, -30);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

-(void)removeAnnot:(FSAnnot *)annot
{
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    rect = CGRectInset(rect, -30, -30);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_extensionsManager onAnnotDeleted:[annot getPage] annot:annot];
       
        assert([annot isMarkup]);
        if ([(FSMarkup*)annot isGrouped]) {
            for (int i = 0; i < [(FSMarkup*)annot getGroupElementCount]; i ++) {
                FSAnnot* groupAnnot = [(FSMarkup*)annot getGroupElement:i];
                if (groupAnnot && ![groupAnnot.NM isEqualToString:annot.NM]) {
                    [[_extensionsManager getAnnotHandlerByType:groupAnnot.type] removeAnnot:groupAnnot];
                }
            }
        }
        
        [[_pdfViewCtrl.currentDoc getPage:pageIndex] removeAnnot:annot];
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
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

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
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
        [self comment];
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
   return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot*)annot
{
    if (annot.type == e_annotCaret)
    {
        unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
        BOOL canAddAnnot = (allPermission & e_permAnnotForm);
        if (!canAddAnnot) {
            return NO;
        }
        CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
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
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    FSAnnot* mkFsAnnot = nil;
    CGRect mkRect = CGRectZero;
    
    if ([(FSMarkup*)annot isGrouped]) {
        for (int i = 0; i < [(FSMarkup*)annot getGroupElementCount]; i ++) {
            FSAnnot* groupAnnot = [(FSMarkup*)annot getGroupElement:i];
            if (groupAnnot.type == e_annotStrikeOut) {
                mkFsAnnot = groupAnnot;
                break;
            }
        }
        if (mkFsAnnot) {
            mkRect = [_pdfViewCtrl convertPdfRectToPageViewRect:mkFsAnnot.fsrect pageIndex:pageIndex];
        }
    } else {
        mkRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    }
    if (pageIndex == annot.pageIndex && _extensionsManager.currentAnnot == annot) {
        CGRect annotRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        annotRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:annotRect pageIndex:pageIndex];
        CGRect drawRect = CGRectMake(ceilf(rect.origin.x), ceilf(rect.origin.y), ceilf(annotRect.size.width), ceilf(annotRect.size.height));
        if (self.annotImage) {
            CGContextSaveGState(context);
            
            CGContextTranslateCTM(context, drawRect.origin.x, drawRect.origin.y);
            CGContextTranslateCTM(context, 0, drawRect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, -drawRect.origin.x, -drawRect.origin.y);
            CGContextDrawImage(context, drawRect, [self.annotImage CGImage]);
            
            CGContextRestoreGState(context);
        }
        drawRect = CGRectInset(drawRect, -2, -2);
        CGContextSetLineWidth(context, 2.0);
        CGFloat dashArray[] = {3,3,3,3};
        CGContextSetLineDash(context, 3, dashArray, 4);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
        CGContextStrokeRect(context, drawRect);
        
        if (mkFsAnnot) {
            mkRect = CGRectInset(mkRect, -5, -5);
            CGContextSetLineWidth(context, 2.0);
            CGContextSetLineDash(context, 3, dashArray, 4);
            CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
            CGContextStrokeRect(context, mkRect);
        }
    }
}


#pragma mark IPropertyBarStateListener

- (void)onPropertyBarDismiss
{
    if (DEVICE_iPHONE && _extensionsManager.currentAnnot == self.editAnnot
        && _extensionsManager.currentAnnot.type == e_annotCaret) {
        self.isShowStyle = NO;
        self.shouldShowPropety = NO;
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

#pragma mark IRotateChangedListener

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

- (void)onScrollViewWillBeginDragging:(UIScrollView*)dviewer
{
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView*)dviewer willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView*)dviewer
{
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView*)dviewer
{
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView*)dviewer
{
    [self dismissAnnotMenu];
    
}

- (void)onScrollViewDidEndZooming:(UIScrollView*)dviewer
{
    double delayInSeconds = .2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self showAnnotMenu];
    });
}

- (void)showAnnotMenu
{
    if (_extensionsManager.currentAnnot == self.editAnnot
        && _extensionsManager.currentAnnot.type == e_annotCaret) {
        int pageIndex = self.editAnnot.pageIndex;
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
        if (!DEVICE_iPHONE && self.shouldShowPropety)
        {
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        }
        else if (self.shouldShowMenu && !_extensionsManager.menuControl.isMenuVisible)
        {
            [_extensionsManager.menuControl setRect:showRect];
            [_extensionsManager.menuControl showMenu];
        }
    }
}

- (void)dismissAnnotMenu
{
    if (_extensionsManager.currentAnnot == self.editAnnot
        && _extensionsManager.currentAnnot.type == e_annotCaret) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
        if (!DEVICE_iPHONE) {
            if (_extensionsManager.propertyBar.isShowing) {
                [_extensionsManager.propertyBar dismissPropertyBar];
            }
        }
    }
}

@end
