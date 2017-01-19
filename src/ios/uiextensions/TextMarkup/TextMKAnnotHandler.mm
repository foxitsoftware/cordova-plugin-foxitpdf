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
#import "TextMKAnnotHandler.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "UIExtensionsManager.h"
#import "PropertyBar.h"
#import "ColorUtility.h"

@interface MKAnnotHandler () <IDocEventListener>

@property (nonatomic, retain) FSAnnot *markupAnnot;
@property (nonatomic, assign) int tmppageIndex;
@property (nonatomic, strong) FSRectF *tmprect;
@property (nonatomic, assign) unsigned int tmpcolor;
@property (nonatomic, assign) int tmpopacity;
@property (nonatomic, retain) NSArray *tmpQuauds;
@property (nonatomic, assign) int tmpflags;
@property (nonatomic, assign) int tmpsubject;
@property (nonatomic, retain) NSString *tmpauthor;
@property (nonatomic, retain) NSString *tmpcontents;
@property (nonatomic, strong) FSAnnot *tmpfsAnnot;
@property (nonatomic, assign) CGRect oldRect;


@property (nonatomic, retain) MenuControl *menuControl;
@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;

@end


@implementation MKAnnotHandler
{
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
        [_pdfViewCtrl registerDocEventListener:self];
        [_pdfViewCtrl registerScrollViewEventListener:self];
        [_extensionsManager registerAnnotHandler:self];
        [_extensionsManager registerRotateChangedListener:self];
        [_extensionsManager registerGestureEventListener:self];
        [_extensionsManager.propertyBar registerPropertyBarListener:self];

        self.isShowStyle = NO;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        self.markupAnnot = nil;
    }
    return self;
}

-(enum FS_ANNOTTYPE)getType
{
    return e_annotHighlight;
}

-(BOOL)isHitAnnot:(FSAnnot*)annot point:(FSPointF*)point
{
    if (annot.type == e_annotStrikeOut && [Utility isReplaceText:(FSStrikeOut*)annot]) {
        // this is a |replace| annot
        return NO;
    }
    CGRect rect = CGRectMake(annot.fsrect.left, annot.fsrect.bottom, annot.fsrect.right - annot.fsrect.left, annot.fsrect.top - annot.fsrect.bottom);
    return CGRectContainsPoint(rect, CGPointMake(point.x, point.y));
}

-(void)onAnnotSelected:(FSAnnot*)annot
{
    self.markupAnnot = annot;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    
    NSMutableArray *array = [NSMutableArray array];
    
    MenuItem *copyTextItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kCopyText", nil) object:self action:@selector(copyText)] autorelease];
    MenuItem *commentItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *openItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kOpen", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *replyItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kReply", nil) object:self action:@selector(reply)] autorelease];
    MenuItem *styleItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kStyle", nil) object:self action:@selector(showStyle)] autorelease];
    MenuItem *deleteItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kDelete", nil) object:self action:@selector(deleteAnnot)] autorelease];
    if (annot.canModify) {
        [array addObject:copyTextItem];
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
        [array addObject:copyTextItem];
        [array addObject:commentItem];
        [array addObject:replyItem];
    }
    
    
    CGRect dvRect = rect;
    dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:dvRect pageIndex:annot.pageIndex];
    MenuControl* annotMenu = _extensionsManager.menuControl;
    annotMenu.menuItems = array;
    [annotMenu setRect:dvRect];
    [annotMenu showMenu];
    
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;
    
    FSMarkup *mkAnnot = (FSMarkup*)annot;
    self.tmppageIndex = mkAnnot.pageIndex;
    self.tmpauthor = mkAnnot.author;
    self.tmpcolor = mkAnnot.color;
    self.tmpcontents = mkAnnot.contents;
    self.tmpflags = mkAnnot.flags;
    self.tmpQuauds = mkAnnot.quads;
    self.tmpopacity = mkAnnot.opacity*100.0;
    self.tmprect = mkAnnot.fsrect;
    self.tmpfsAnnot = mkAnnot;
    
    rect = CGRectInset(rect, -20, -20);
    [_pdfViewCtrl refresh:rect pageIndex:annot.pageIndex];
}

-(void)copyText
{
    FSMarkup *annot = (FSMarkup*)_extensionsManager.currentAnnot;
    NSMutableString *str = [NSMutableString stringWithFormat:@""];
    for (int i = 0; i < annot.quads.count; i++) {
        FSQuadPoints *arrayQuad = [annot.quads objectAtIndex:i];
        FSRectF *rect = [Utility convertToFSRect:arrayQuad.getFirst p2:arrayQuad.getFourth];
        NSString* tmp = [[Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:annot.pageIndex] getTextInRect:rect];
        if(tmp)
            [str appendString:tmp];
        
    }
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
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
    replyCtr.isNeedReply = NO;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:_extensionsManager.currentAnnot];
    [replyCtr setTableViewAnnotations:array];
    UINavigationController *navCtr= [[UINavigationController alloc] initWithRootViewController:replyCtr];
    self.currentVC = navCtr;
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
    replyCtr.isNeedReply = YES;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:_extensionsManager.currentAnnot];
    [replyCtr setTableViewAnnotations:array];
    UINavigationController *navCtr= [[UINavigationController alloc] initWithRootViewController:replyCtr];
    self.currentVC = navCtr;
    
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
    [_extensionsManager setCurrentAnnot:nil];
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        [self removeAnnot:annot];
    };
    [_taskServer executeSync:task];
}

-(void)showStyle
{
    FSAnnot *annot = _extensionsManager.currentAnnot;
    NSArray *colors = nil;
    if (annot.type == e_annotHighlight) {
        colors = @[@0xFFFF00,@0xCCFF66,@0x00FFFF,@0x99CCFF,@0x7480FC,@0xCC99FF,@0xFF99FF,@0xFF9999,@0x00CC66,@0x22F3B1];
    }
    else if (annot.type == e_annotUnderline || annot.type == e_annotSquiggly)
    {
        colors = @[@0x33CC00,@0xCCCC00,@0xFF9933,@0x0099CC,@0xBBBBBB,@0x3366FF,@0xCC33FF,@0xCC0099,@0xFF0000,@0x686767];
    }
    else if (annot.type == e_annotStrikeOut)
    {
        colors = @[@0xFF3333,@0xFF00FF,@0x9966FF,@0x66CC33,@0x996666,@0xCCCC00,@0xFF9900,@0x00CCFF,@0x00CCCC,@0x000000];
    }
    [_extensionsManager.propertyBar setColors:colors];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY];
   
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity*100.0];
    [_extensionsManager.propertyBar addListener:_extensionsManager];

    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:annot.pageIndex];
    NSArray *array = [NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]];
    [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:array];
    self.isShowStyle = YES;
    self.shouldShowMenu = NO;
    self.shouldShowPropety = YES;
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
}

-(void)onAnnotDeselected:(FSAnnot*)annot
{
    MenuControl* annotMenu = _extensionsManager.menuControl;
    if (annotMenu.isMenuVisible) {
        [annotMenu setMenuVisible:NO animated:YES];
    }
    if (_extensionsManager.propertyBar.isShowing) {
        [_extensionsManager.propertyBar dismissPropertyBar];
        self.isShowStyle = NO;
    }
    self.shouldShowMenu = NO;
    self.shouldShowPropety = NO;
    
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    newRect = CGRectInset(newRect, -20, -20);
    [_pdfViewCtrl refresh:newRect pageIndex:annot.pageIndex];

}

-(void)addAnnot:(FSAnnot*)annot
{
    [annot retain];
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^()
    {
        FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:annot.pageIndex];
        if (!page)
        {
            return;
        }
        
        {
            FSPDFTextSelect* textPage = [FSPDFTextSelect create:page];
            if (textPage)
            {
                NSString *tmp = @"";
                NSArray *array = [self getAnnotationQuad:(FSTextMarkup*)annot];
                for (int i = 0; i < array.count; i++)
                {
                    FSQuadPoints *arrayQuad = [array objectAtIndex:i];
                    FSRectF *rect = [Utility convertToFSRect:arrayQuad.getFirst p2:arrayQuad.getFourth];
                    tmp = [tmp stringByAppendingString:[textPage getTextInRect:rect]];
                }
                [annot setContents:tmp];
            }

            [annot resetAppearanceStream];
            [_extensionsManager onAnnotAdded:page annot:annot];

            int pageIndex = annot.pageIndex;
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            rect = CGRectInset(rect, -20, -20);
            dispatch_async(dispatch_get_main_queue(), ^{
                [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
            });
            [annot release];
        }
    };
    [_taskServer executeSync:task];
}

-(void)modifyAnnot:(FSAnnot*)annot
{
    if ([annot canModify]) {
        annot.modifiedDate = [NSDate date];
    }
    // [annot resetAppearanceStream]
    [_extensionsManager onAnnotModified:[annot getPage] annot:annot];
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect =CGRectInset(rect, -20, -20);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:annot.pageIndex];
    });
}

-(void)removeAnnot:(FSAnnot*)annot
{
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect = CGRectInset(rect, -20, -20);
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
//    Read *read = APPDELEGATE.app.read;
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
    return NO;
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

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot*)anno
{
    return NO;
}
- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot*)anno
{
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot*)annot
{
    return NO;
}

-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context annot:(FSAnnot*)annot
{
    if (_extensionsManager.currentAnnot == annot  && pageIndex == annot.pageIndex)
    {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
        rect = CGRectInset(rect, -5, -5);
        CGContextSetLineWidth(context, 2.0);
        CGFloat dashArray[] = {3,3,3,3};
        CGContextSetLineDash(context, 3, dashArray, 4);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
        CGContextStrokeRect(context, rect);
    }
}

- (NSArray*)getAnnotationQuad:(FSTextMarkup *)annot
{
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
    int quadCount = [annot getQuadPointsCount];
    if (quadCount <= 0)
    {
        return nil;
    }
    
    for (int i = 0; i < quadCount; i++) {
        FSQuadPoints *quadPoints = [annot getQuadPoints:i];
        if (!quadPoints)
        {
            goto END;
        }
        [array addObject:quadPoints];
    }
    
END:
    return array;
}
#pragma mark IPropertyBarListener

- (void)onPropertyBarDismiss
{
    FSAnnot* curAnnot = _extensionsManager.currentAnnot;
    if (DEVICE_iPHONE && curAnnot == self.markupAnnot && [_extensionsManager getAnnotHandlerByType:curAnnot.type] == self) {
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
    FSAnnot* curAnnot = _extensionsManager.currentAnnot;
    if (curAnnot == self.markupAnnot && [_extensionsManager getAnnotHandlerByType:curAnnot.type] == self) {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.markupAnnot.fsrect pageIndex:_extensionsManager.currentAnnot.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.markupAnnot.pageIndex];
        
        CGRect rectDisplayView = [[_pdfViewCtrl getDisplayView] bounds];
        if(CGRectIsEmpty(showRect) || CGRectIsNull(CGRectIntersection(showRect, rectDisplayView)))
            return;
        
        if (self.shouldShowPropety)
        {
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
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
    if (curAnnot == self.markupAnnot && [_extensionsManager getAnnotHandlerByType:curAnnot.type] == self) {
        MenuControl* annotMenu = _extensionsManager.menuControl;
        if (annotMenu.isMenuVisible) {
            [annotMenu setMenuVisible:NO animated:YES];
        }
        if (_extensionsManager.propertyBar.isShowing) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
    }
}
- (void)dealloc{
    [_currentVC release];
    [_tmprect release];
    [_tmpcontents release];
    [_tmpfsAnnot release];
    [_markupAnnot release];
    [_tmpauthor release];
    [_menuControl release];
    [_tmpQuauds release];
    [super dealloc];
}


#pragma mark IDocEventListener

- (void)onDocWillClose:(FSPDFDoc* )document
{
    if (self.currentVC) {
        [self.currentVC dismissViewControllerAnimated:NO completion:nil];
    }
}


@end
