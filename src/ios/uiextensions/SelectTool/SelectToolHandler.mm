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
#import "SelectToolHandler.h"
#import "NoteDialog.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "Preference.h"
#import "UIExtensionsManager+Private.h"
#import "MagnifierView.h"
#import "FtToolHandler.h"

@interface SelectToolHandler () <IDocEventListener>

@property (nonatomic, assign) BOOL isTextSelect;
@property (nonatomic, assign) int currentPageIndex;
@property (nonatomic, strong) FSPointF* currentPoint;
@property (nonatomic, assign) int startPosIndex;
@property (nonatomic, assign) int endPosIndex;
@property (nonatomic, retain) NSArray *arraySelectedRect;
@property (nonatomic, strong) FSRectF *currentEditPdfRect;
@property (nonatomic, retain) NSArray *colors;
@end

@implementation SelectToolHandler {
    UIExtensionsManager* _extensionsManager;
    FSPDFViewCtrl* _pdfViewCtrl;
    TaskServer* _taskServer;
}

@synthesize type = _type;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [_extensionsManager registerToolHandler:self];
        [_pdfViewCtrl registerPageEventListener:self];
        [_extensionsManager registerRotateChangedListener:self];
        [_pdfViewCtrl registerScrollViewEventListener:self];
        [_extensionsManager registerGestureEventListener:self];
        [_pdfViewCtrl registerDocEventListener:self];
        _taskServer = _extensionsManager.taskServer;
    }
    return self;
}

- (NSArray*)_getTextRects:(FSPDFTextSelect*)fstextPage start:(int)start end:(int)end
{
    int count = ABS(end-start)+1;
    start = MIN(start, end);
    __block NSMutableArray *ret = [NSMutableArray array];
    
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        if (fstextPage != nil)
        {
            int rectCount = [fstextPage getTextRectCount:start count:count];
            for (int i = 0; i < rectCount; i++)
            {
                FSRectF* dibRect = [fstextPage getTextRect:i];
                if (dibRect.getLeft == dibRect.getRight || dibRect.getTop == dibRect.getBottom)
                {
                    continue;
                }
                
                enum FS_ROTATION direction = [fstextPage getBaselineRotation:i];
                NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGRect:[Utility FSRectF2CGRect:dibRect]],[NSNumber numberWithInt:direction],nil];
                
                [ret addObject:array];
            }
            
            //merge rects if possible
            if (ret.count > 1)
            {
                int i = 0;
                while (i < ret.count-1)
                {
                    int j = i + 1;
                    while (j < ret.count)
                    {
                        FSRectF* rect1 = [Utility CGRect2FSRectF:[[[ret objectAtIndex:i] objectAtIndex:0] CGRectValue]];
                        FSRectF* rect2 = [Utility CGRect2FSRectF:[[[ret objectAtIndex:j] objectAtIndex:0] CGRectValue]];
                        
                        int direction1 = [[[ret objectAtIndex:i] objectAtIndex:1] intValue];
                        int direction2 = [[[ret objectAtIndex:j] objectAtIndex:1] intValue];
                        BOOL adjcent = NO;
                        if (direction1 == direction2)
                        {
                            adjcent = NO;
                        }
                        if(adjcent)
                        {
                            FSRectF* rectResult = [[FSRectF alloc] init];
                            [rectResult set:MIN([rect1 getLeft], [rect2 getLeft]) bottom:MAX([rect1 getTop], [rect2 getTop]) right:MAX([rect1 getRight], [rect2 getRight]) top:MIN([rect1 getBottom], [rect2 getBottom])];
                            NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGRect:[Utility FSRectF2CGRect:rectResult]],[NSNumber numberWithInt:direction1],nil];
                            [ret replaceObjectAtIndex:i withObject:array];
                            [ret removeObjectAtIndex:j];
                            [rectResult release];
                        }
                        else
                        {
                            j++;
                        }
                    }
                    i++;
                }
            }
        }
        
    };
    [_taskServer executeSync:task];
    return ret;
}

//get word range of string, including space
- (NSArray*)getUnitWordBoundary:(NSString*)str
{
    NSMutableArray *array = [NSMutableArray array];
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault,
                                                             (CFStringRef)str,
                                                             CFRangeMake(0, [str length]),
                                                             kCFStringTokenizerUnitWordBoundary,
                                                             NULL);
    CFStringTokenizerTokenType tokenType = kCFStringTokenizerTokenNone;
    while ((tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)) != kCFStringTokenizerTokenNone)
    {
        CFRange tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
        NSRange range = NSMakeRange(tokenRange.location, tokenRange.length);
        [array addObject:[NSValue valueWithRange:range]];
    }
    if (tokenizer)
    {
        CFRelease(tokenizer);
    }
    return array;
}

- (NSRange)getWordByTextIndex:(int)index textPage:(FSPDFTextSelect*)fstextPage
{
    __block NSRange retRange = NSMakeRange(index, 1);
    
    int pageTotalCharCount = 0;
    
    if (fstextPage != nil) {
        pageTotalCharCount = [fstextPage getCharCount];
    }
    
    int startIndex = MAX(0, index - 25);
    int endIndex = MIN(pageTotalCharCount-1, index + 25);
    index -= startIndex;
    
    NSString *str = [fstextPage getChars:MIN(startIndex,endIndex) count:ABS(endIndex-startIndex)+1];
    NSArray *array = [self getUnitWordBoundary:str];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeValue];
        if (NSLocationInRange(index, range))
        {
            NSString *tmp = [str substringWithRange:range];
            if ([tmp isEqualToString:@" "])
            {
                NSUInteger nextIndex = idx + 1;
                if (nextIndex < array.count)
                {
                    range = [[array objectAtIndex:nextIndex] rangeValue];
                }
            }
            retRange = NSMakeRange(startIndex + range.location, range.length);
            *stop = YES;
        }
    }];

    return retRange;
    
}

- (int)getCharIndexAtPos:(int)pageIndex point:(CGPoint)point
{
    FSPointF* dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
    return (int)[textPage getIndexAtPos:dibPoint.x y:dibPoint.y tolerance:5];
}

- (NSArray*)getCurrentSelectRects:(int)pageIndex
{
    NSMutableArray *retArray = [NSMutableArray array];
    __block CGRect unionRect = CGRectZero;
    
    FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
    NSArray* array = [self _getTextRects:textPage start:self.startPosIndex end:self.endPosIndex];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGRect rect = [[obj objectAtIndex:0] CGRectValue];
        [retArray addObject:[NSValue valueWithCGRect:rect]];
        if (CGRectEqualToRect(unionRect, CGRectZero))
        {
            unionRect = rect;
        }
        else
        {
            unionRect = CGRectUnion(unionRect, rect);
        }
    }];
   
    self.currentEditPdfRect  = [Utility CGRect2FSRectF:unionRect];
    return retArray;
}

- (void)clearSelection
{
    self.startPosIndex = -1;
    self.endPosIndex = -1;
    self.arraySelectedRect = nil;
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
    if (self.isEdit && [_extensionsManager.menuControl isMenuVisible]) {
        [_extensionsManager.menuControl hideMenu];
    }
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer
{
    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
    
    if ([self handleLongPressAndPan:pageIndex gestureRecognizer:recognizer]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer
{
    id<IToolHandler> originToolHandler = _extensionsManager.currentToolHandler;
    if ([_extensionsManager getCurrentToolHandler] == self) {
        [_extensionsManager setCurrentToolHandler:nil];
    }
    if (!self.isEdit) {
        if (originToolHandler == self && [_extensionsManager.menuControl isMenuVisible]) {
            [_extensionsManager.menuControl hideMenu];
        }
        return NO;
    }
    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
    
    self.isEdit = NO;
    [self clearSelection];
    [_pdfViewCtrl refresh:CGRectZero pageIndex:pageIndex needRender:NO];
    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer
{
    if (!self.isEdit) {
        return NO;
    }
    if([self handleLongPressAndPan:pageIndex gestureRecognizer:recognizer])
    {
        return YES;
    }
    MenuControl* annotMenu = _extensionsManager.menuControl;
    if ([annotMenu isMenuVisible])
    {
        [annotMenu hideMenu];
    }
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([_extensionsManager getCurrentToolHandler] != self
        || _extensionsManager.currentAnnot) {
        return NO;
    }
    if (self.isEdit) {
        CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        int index = [self getCharIndexAtPos:pageIndex point:point];
        index = [self verifyIndexRange:index count:100];  //is it near start or end dot
        if (index > -1)
        {
            return YES;
        }
    }
    return NO;
}
#pragma mark - private methods

- (BOOL)handleLongPressAndPan:(int)pageIndex gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        MenuControl* annotMenu = _extensionsManager.menuControl;
        if ([annotMenu isMenuVisible])
        {
            [annotMenu hideMenu];
        }
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])  //only start when long press
        {
            
            self.currentPageIndex = pageIndex;
            //start a new range of select text
            int index = [self getCharIndexAtPos:pageIndex point:point];
            [self clearSelection];
            if (index > -1)  //has some selection, make first character selected
            {
                self.isEdit = YES;
                self.isTextSelect = YES;
                FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
                NSRange range = [self getWordByTextIndex:index textPage:textPage];
                self.startPosIndex = (int)range.location;
                self.endPosIndex = (int)(range.location + range.length - 1);
                [self showMagnifier:pageIndex index:index point:point];
                
                [_pdfViewCtrl refresh:pageIndex needRender:NO];
            }
            else
            {
                self.isTextSelect = NO;
                self.isEdit = YES;
                [self showBlankMenu:pageIndex point:point];
                [_pdfViewCtrl refresh:pageIndex needRender:NO];
            }
        }
        else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])  //pan start is used to drag the dot
        {
            int index = [self getCharIndexAtPos:pageIndex point:point];
            index = [self verifyIndexRange:index count:100];  //is it near start or end dot
            if (index > -1)
            {
                if (index == self.startPosIndex)
                {
                    //when drag dot always make drag end
                    int tmp = self.endPosIndex;
                    self.endPosIndex = self.startPosIndex;
                    self.startPosIndex = tmp;
                }
                [self showMagnifier:pageIndex index:index point:point];
                [_pdfViewCtrl refresh:pageIndex needRender:NO];
            }
        }
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        if (self.currentPageIndex != pageIndex) {
            return YES;
        }
        //position change, update the selected range
        if (self.startPosIndex == -1 || self.endPosIndex == -1)
        {
            return YES;  //not start successfully
        }
        int index = [self getCharIndexAtPos:pageIndex point:point];
        if (index > -1)
        {
            self.endPosIndex = index;
            [_pdfViewCtrl refresh:pageIndex needRender:NO];
            [self showMagnifier:pageIndex index:index point:point];
            [self moveMagnifier:pageIndex index:index point:point];
        }
        return YES;
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self closeMagnifier];
        if (self.currentPageIndex != pageIndex) {
            [self showTextMenu:self.currentPageIndex rect:[_pdfViewCtrl convertPdfRectToPageViewRect:self.currentEditPdfRect pageIndex:self.currentPageIndex]];
            return YES;
        }
        
        //getsture end. if have selection, pop up menu to let user choose; otherwise change to none op.
        if (self.startPosIndex == -1 || self.endPosIndex == -1)
        {
            return YES;
        }
        else
        {
            [self getCurrentSelectRects:pageIndex];
            [self showTextMenu:pageIndex rect:[_pdfViewCtrl convertPdfRectToPageViewRect:self.currentEditPdfRect pageIndex:self.currentPageIndex]];
            return YES;
        }
    }
    return YES;
}

- (int)verifyIndexRange:(int)index count:(int)count
{
    int ret = -1;
    if (index == -1)
    {
        ret = index;
    }
    else if (index >= self.startPosIndex - count && index <= self.startPosIndex + count)
    {
        ret = self.startPosIndex;
    }
    else if (index >= self.endPosIndex - count && index <= self.endPosIndex + count)
    {
        ret = self.endPosIndex;
    }
    return ret;
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

-(void)showTextMenu:(int)pageIndex rect:(CGRect)rect
{
    self.currentPageIndex = pageIndex;
    NSMutableArray *array = [NSMutableArray array];
    MenuItem *copyTextItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kCopyText", nil) object:self action:@selector(copyText)] autorelease];
    MenuItem *hightLightItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kHighlight", nil) object:self action:@selector(addHighlight)] autorelease];
    MenuItem *squigglyItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kSquiggly", nil) object:self action:@selector(addSquiggly)] autorelease];
    MenuItem *strikeOutItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kStrikeout", nil) object:self action:@selector(addStrikeout)] autorelease];
    MenuItem *underlineItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kUnderline", nil) object:self action:@selector(addUnderline)] autorelease];

    unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
    if ((allPermission & e_permExtract)) {
        [array addObject:copyTextItem];
    }
    
    if (YES  && (allPermission & e_permAnnotForm))
    {
        [array addObject:hightLightItem];
        [array addObject:underlineItem];
        [array addObject:strikeOutItem];
        [array addObject:squigglyItem];
    }

    if (array.count > 0) {
        CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.currentPageIndex];
        MenuControl* annotMenu = _extensionsManager.menuControl;
        annotMenu.menuItems = array;
        [annotMenu setRect:dvRect];
        [annotMenu showMenu];
    }
}

- (NSString*)copyText;
{
    self.isEdit = NO;
    NSMutableString *str = [NSMutableString stringWithFormat:@""];
    
    FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:self.currentPageIndex];
    [str appendString:[textPage getChars:MIN(self.startPosIndex, self.endPosIndex) count:ABS(self.endPosIndex-self.startPosIndex)+1]];
    if (str && ![str isEqualToString:@""]) {
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        board.string = str;
    }
    [_pdfViewCtrl refresh:self.currentPageIndex needRender:NO];
    [self clearSelection];
    return str;
}

-(void)addHighlight
{
    self.isEdit = NO;
    [self addMarkup:e_annotHighlight];
    [self clearSelection];
}

-(void)addSquiggly
{
    self.isEdit = NO;
    [self addMarkup:e_annotSquiggly];
    [self clearSelection];
}

-(void)addStrikeout
{
    self.isEdit = NO;
    [self addMarkup:e_annotStrikeOut];
    [self clearSelection];
}

-(void)addUnderline
{
    self.isEdit = NO;
    [self addMarkup:e_annotUnderline];
    [self clearSelection];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.isEdit = NO;
    [_pdfViewCtrl refresh:CGRectZero pageIndex:self.currentPageIndex needRender:NO];
}

-(void)addMarkup:(enum FS_ANNOTTYPE)type
{
    FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:self.currentPageIndex];
    NSArray* array = [self _getTextRects:textPage start:self.startPosIndex end:self.endPosIndex];
    NSMutableArray *arrayQuads = [NSMutableArray array];
    for (int i = 0; i < array.count; i++)
    {
        FSRectF *dibRect = [Utility CGRect2FSRectF:[[[array objectAtIndex:i] objectAtIndex:0] CGRectValue]];
        int direction = [[[array objectAtIndex:i] objectAtIndex:1] intValue];
        CGPoint point1;
        CGPoint point2;
        CGPoint point3;
        CGPoint point4;
        if (direction == 0 || direction == 4) //text is horizontal or unknown, left to right
        {
            point1.x = dibRect.left;
            point1.y = dibRect.top;
            point2.x = dibRect.right;
            point2.y = dibRect.top;
            point3.x = dibRect.left;
            point3.y = dibRect.bottom;
            point4.x = dibRect.right;
            point4.y = dibRect.bottom;
        }
        else if (direction == 1) // test is vertical, left to right
        {
            point4.x = dibRect.right;
            point4.y = dibRect.top;
            point3.x = dibRect.right;
            point3.y = dibRect.bottom;
            point2.x = dibRect.left;
            point2.y = dibRect.top;
            point1.x = dibRect.left;
            point1.y = dibRect.bottom;
        }
        else if (direction == 2) //text is horizontal, right to left
        {
            point4.x = dibRect.left;
            point4.y = dibRect.top;
            point3.x = dibRect.right;
            point3.y = dibRect.top;
            point2.x = dibRect.left;
            point2.y = dibRect.bottom;
            point1.x = dibRect.right;
            point1.y = dibRect.bottom;
        }
        else if (direction == 3) //text is vertical, right to left
        {
            point1.x = dibRect.right;
            point1.y = dibRect.top;
            point2.x = dibRect.right;
            point2.y = dibRect.bottom;
            point3.x = dibRect.left;
            point3.y = dibRect.top;
            point4.x = dibRect.left;
            point4.y = dibRect.bottom;
        }
        else
        {
            continue;
        }
        
        FSQuadPoints* fsqp = [[FSQuadPoints alloc] init];
        FSPointF* pt1 = [[FSPointF alloc] init];
        [pt1 set:point1.x y:point1.y];
        FSPointF* pt2 = [[FSPointF alloc] init];
        [pt2 set:point2.x y:point2.y];
        FSPointF* pt3 = [[FSPointF alloc] init];
        [pt3 set:point3.x y:point3.y];
        FSPointF* pt4 = [[FSPointF alloc] init];
        [pt4 set:point4.x y:point4.y];
        [fsqp setFirst:pt1];
        [fsqp setSecond:pt2];
        [fsqp setThird:pt3];
        [fsqp setFourth:pt4];
        [arrayQuads addObject:fsqp];
        
        [pt1 release];
        [pt2 release];
        [pt3 release];
        [pt4 release];
        [fsqp release];
    }
    if (0 == arrayQuads.count) return;
    CGRect insetRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.currentEditPdfRect pageIndex:self.currentPageIndex];
    FSRectF *rect = [_pdfViewCtrl convertPageViewRectToPdfRect:insetRect pageIndex:self.currentPageIndex];
    
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:self.currentPageIndex];
    if (!page) return;
    FSMarkup *annot = (FSMarkup*)[page addAnnot:type rect:rect];
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.quads = arrayQuads;
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    annot.flags = e_annotFlagPrint;
    
    unsigned int color = [_extensionsManager getPropertyBarSettingColor:type];
    int opacity = [_extensionsManager getPropertyBarSettingOpacity:type];
    if (type == e_annotHighlight)
    {
        annot.subject = @"Highlight";
        self.colors = @[@0xFFFF00,@0xCCFF66,@0x00FFFF,@0x99CCFF,@0x7480FC,@0xCC99FF,@0xFF99FF,@0xFF9999,@0x00CC66,@0x22F3B1];
        annot.color = [Preference getIntValue:@"Highlight" type:@"Color" defaultValue:0] != 0 ?[Preference getIntValue:@"Highlight" type:@"Color" defaultValue:0] : color;
        opacity = [Preference getIntValue:@"Highlight" type:@"Opacity" defaultValue:0] != 0 ? [Preference getIntValue:@"Highlight" type:@"Opacity" defaultValue:0] : opacity;
    }
    else if (type == e_annotSquiggly)
    {
        annot.subject = @"Squiggly";
        self.colors = @[@0x33CC00,@0xCCCC00,@0xFF9933,@0x0099CC,@0xBBBBBB,@0x3366FF,@0xCC33FF,@0xCC0099,@0xFF0000,@0x686767];
        annot.color = [Preference getIntValue:@"Squiggly" type:@"Color" defaultValue:0] != 0 ?[Preference getIntValue:@"Squiggly" type:@"Color" defaultValue:0] : color;
        opacity = [Preference getIntValue:@"Squiggly" type:@"Opacity" defaultValue:0] != 0 ? [Preference getIntValue:@"Squiggly"type:@"Opacity" defaultValue:0] : opacity;

    }
    else if (type == e_annotStrikeOut)
    {
        annot.subject = @"Strikeout";
        self.colors = @[@0xFF3333,@0xFF00FF,@0x9966FF,@0x66CC33,@0x996666,@0xCCCC00,@0xFF9900,@0x00CCFF,@0x00CCCC,@0x000000];
        annot.color = [Preference getIntValue:@"Strikeout" type:@"Color" defaultValue:0] != 0 ?[Preference getIntValue:@"Strikeout" type:@"Color" defaultValue:0] : color;
        opacity = [Preference getIntValue:@"Strikeout" type:@"Opacity" defaultValue:0] != 0 ? [Preference getIntValue:@"Strikeout"type:@"Opacity" defaultValue:0] : opacity;

    }
    else if (type == e_annotUnderline)
    {
        annot.subject = @"Underline";
        self.colors = @[@0x33CC00,@0xCCCC00,@0xFF9933,@0x0099CC,@0xBBBBBB,@0x3366FF,@0xCC33FF,@0xCC0099,@0xFF0000,@0x686767];
        annot.color = [Preference getIntValue:@"Underline" type:@"Color" defaultValue:0] != 0 ?[Preference getIntValue:@"Underline" type:@"Color" defaultValue:0] : color;
        opacity = [Preference getIntValue:@"Underline" type:@"Opacity" defaultValue:0] != 0 ? [Preference getIntValue:@"Underline" type:@"Opacity" defaultValue:0] : opacity;
    }
    annot.opacity = opacity/100.0f;
    
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByType:annot.type];
        [annotHandler addAnnot:annot];
        
        CGRect cgRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:self.currentPageIndex];
        cgRect = CGRectInset(cgRect, -20, -20);
        
        [_pdfViewCtrl refresh:cgRect pageIndex:self.currentPageIndex];
        [self clearSelection];
    };
    [_taskServer executeSync:task];
}

-(void)showBlankMenu:(int)pageIndex point:(CGPoint)point
{
    self.currentPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    self.currentPageIndex = pageIndex;
    NSMutableArray *array = [NSMutableArray array];
    MenuItem *commentItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kNote", nil) object:self action:@selector(comment)] autorelease];
    MenuItem *typeWriterItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kTypewriter", nil) object:self action:@selector(typeWriter)] autorelease];
    
    unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
    if ((allPermission & e_permAnnotForm)) {
        [array addObject:commentItem];
        [array addObject:typeWriterItem];

        CGRect dvRect = CGRectMake(point.x, point.y, 2, 2);
        dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:dvRect pageIndex:pageIndex];
        MenuControl* annotMenu = _extensionsManager.menuControl;
        annotMenu.menuItems = array;
        [annotMenu setRect:dvRect];
        [annotMenu showMenu];
    }
}

-(void)comment
{
    self.isEdit = NO;
    self.colors = @[@0xFF9F40,@0x8080FF,@0xBAE94C,@0xFFF160,@0xC3C3C3,@0xFF4C4C,@0x669999,@0xC72DA1,@0x996666,@0x000000];
    unsigned int color = [_extensionsManager getPropertyBarSettingColor:e_annotNote];

    float pageWidth = [_pdfViewCtrl getPageViewWidth:self.currentPageIndex];
    float pageHeight = [_pdfViewCtrl getPageViewHeight:self.currentPageIndex];

    float scale = pageWidth/1000.0;
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.currentPoint pageIndex:self.currentPageIndex];
    
    if(pvPoint.x > pageWidth-NOTE_ANNOTATION_WIDTH*scale*2) pvPoint.x = pageWidth-NOTE_ANNOTATION_WIDTH*scale*2;
    if(pvPoint.y > pageHeight-NOTE_ANNOTATION_WIDTH*scale*2) pvPoint.y = pageHeight-NOTE_ANNOTATION_WIDTH*scale*2;
    
    CGRect rect = CGRectMake(pvPoint.x - NOTE_ANNOTATION_WIDTH*scale/2, pvPoint.y - NOTE_ANNOTATION_WIDTH*scale/2, NOTE_ANNOTATION_WIDTH*scale, NOTE_ANNOTATION_WIDTH*scale);
    FSRectF *dibRect= [_pdfViewCtrl convertPageViewRectToPdfRect:rect pageIndex:self.currentPageIndex];
    
    [NoteDialog setViewCtrl: _pdfViewCtrl];
    [[NoteDialog defaultNoteDialog] show:nil replyAnnots:nil];
    
    [NoteDialog defaultNoteDialog].noteEditDone = ^()
    {
        FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:self.currentPageIndex];
        if (!page) return;
        
        FSNote* note = (FSNote*)[page addAnnot:e_annotNote rect:dibRect];
        note.color = color;
        int opacity = [_extensionsManager getPropertyBarSettingOpacity:e_annotNote];
        note.opacity = opacity/100.0f;
        note.icon = _extensionsManager.noteIcon;
        note.author = [SettingPreference getAnnotationAuthor];
        note.contents = [[NoteDialog defaultNoteDialog] getContent];
        note.NM = [Utility getUUID];
        note.lineWidth = 2;
        id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByType:note.type];
        [annotHandler addAnnot:note];
    };
    if (_extensionsManager.currentToolHandler == self) {
        [_extensionsManager setCurrentToolHandler:nil];
    }
}

-(void)typeWriter
{
    self.isEdit = NO;
    FtToolHandler *toolHandler = [_extensionsManager getToolHandlerByName:Tool_Freetext];
    [_extensionsManager setCurrentToolHandler:toolHandler];
    toolHandler.freeTextStartPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.currentPoint pageIndex:self.currentPageIndex];
    [toolHandler onPageViewTap:self.currentPageIndex recognizer:nil];
    toolHandler.isTypewriterToolbarActive = NO;
    if (_extensionsManager.currentToolHandler == self) {
        [_extensionsManager setCurrentToolHandler:nil];
    }
}

-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context
{
    if (pageIndex != self.currentPageIndex) {
        return;
    }
    
    if (self.isEdit && self.isTextSelect) {
        if (self.startPosIndex == -1 || self.endPosIndex == -1) {
            return;
        }
        
        self.arraySelectedRect = [self getCurrentSelectRects:pageIndex];
        [self.arraySelectedRect enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             CGRect selfRect = [obj CGRectValue];
             FSRectF *docRect = [Utility CGRect2FSRectF:selfRect];
             CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:docRect pageIndex:pageIndex];
             
             UIColor* highlightColor = _extensionsManager.selectionHighlightColor;
             CGFloat red, green, blue, alpha;
             [highlightColor getRed:&red green:&green blue:&blue alpha:&alpha];
             CGContextSetRGBFillColor(context, red, green, blue, alpha);
             CGContextFillRect(context, pvRect);
             
             //draw the drag dot
             if (idx == 0)
             {
                 UIImage *dragDot = [UIImage imageNamed:@"annotation_dragdot.png"];
                 CGRect leftCursor = CGRectMake((int)(pvRect.origin.x-7.5), (int)(pvRect.origin.y-12), 15, 17);
                 [dragDot drawAtPoint:leftCursor.origin];
             }
             if (idx+1 == self.arraySelectedRect.count)
             {
                 UIImage *dragDot = [UIImage imageNamed:@"annotation_dragdot.png"];
                 CGRect rightCursor = CGRectMake((int)(pvRect.origin.x+pvRect.size.width-7.5), (int)(pvRect.origin.y+pvRect.size.height-5), 15, 17);
                 [dragDot drawAtPoint:rightCursor.origin];
             }
         }];
    }
}

-(unsigned int)color
{
    return [_extensionsManager getPropertyBarSettingColor:self.type];
}

-(void)setColor:(unsigned int)color
{
    [_extensionsManager setAnnotColor:color annotType:self.type];
}

-(int)opacity
{
    return [_extensionsManager getAnnotOpacity:self.type];
}

-(void)setOpacity:(int)opacity
{
    return [_extensionsManager setAnnotOpacity:opacity annotType:self.type];
}

#pragma mark - IPageEventListener

- (void)onPageChanged:(int)oldIndex currentIndex:(int)currentIndex
{
    if (oldIndex != currentIndex) {
        if (!self.isEdit) {
            return;
        }
        if (_extensionsManager.currentAnnot) {
            [_extensionsManager setCurrentAnnot:nil];
        }
        
        MenuControl* annotMenu = _extensionsManager.menuControl;
        if ([annotMenu isMenuVisible])
        {
            [annotMenu hideMenu];
        }
        self.isEdit = NO;
        [self clearSelection];

        [_pdfViewCtrl refresh:CGRectZero pageIndex:oldIndex needRender:NO];
        [_pdfViewCtrl refresh:CGRectZero pageIndex:currentIndex needRender:NO];
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
    [self showAnnotMenu];
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
    
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView
{
    [self showAnnotMenu];
}

- (void)showAnnotMenu
{
    if (self.isEdit) {
        double delayInSeconds = .05;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            MenuControl* annotMenu = _extensionsManager.menuControl;
            if (self.isTextSelect) {
                CGRect dvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.currentEditPdfRect pageIndex:self.currentPageIndex];
                dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:dvRect pageIndex:self.currentPageIndex];
                
                CGRect rectDisplayView = [[_pdfViewCtrl getDisplayView] bounds];
                if(CGRectIsEmpty(dvRect) || CGRectIsNull(CGRectIntersection(dvRect, rectDisplayView)))
                    return;
                
                [annotMenu setRect:dvRect];
                [annotMenu showMenu];
            }
            else
            {
                CGPoint dvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.currentPoint pageIndex:self.currentPageIndex];
                CGRect dvRect = CGRectMake(dvPoint.x, dvPoint.y, 2, 2);
                
                CGRect rectDisplayView = [[_pdfViewCtrl getDisplayView] bounds];
                if(CGRectIsEmpty(dvRect) || CGRectIsNull(CGRectIntersection(dvRect, rectDisplayView)))
                    return;
                
                dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:dvRect pageIndex:self.currentPageIndex];
                [annotMenu setRect:dvRect];
                [annotMenu showMenu];
            }
        });
    }
}


- (void)dismissAnnotMenu
{
    if (self.isEdit) {
        MenuControl* annotMenu = _extensionsManager.menuControl;
        if ([annotMenu isMenuVisible])
        {
            [annotMenu hideMenu];
        }
    }
}

#pragma mark - Magnifier

- (void)showMagnifier:(int)pageIndex index:(int)index point:(CGPoint)point
{
    if(_magnifierView == nil)
    {
        FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
        NSArray* array = [self _getTextRects:textPage start:index end:index+1];
        if (array.count > 0)
        {
            FSRectF *dibRect = [Utility CGRect2FSRectF:[[[array objectAtIndex:0] objectAtIndex:0] CGRectValue]];
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
            point = CGPointMake(point.x, CGRectGetMidY(rect));
        }
        _magnifierView = [[MagnifierView alloc] init];
        _magnifierView.viewToMagnify = [_pdfViewCtrl getDisplayView];
        _magnifierView.touchPoint = point;
        _magnifierView.magnifyPoint = [[_pdfViewCtrl getPageView:pageIndex] convertPoint:point toView:[_pdfViewCtrl getDisplayView]];
        [[_pdfViewCtrl getPageView:pageIndex] addSubview:_magnifierView];
    }
}

- (void)moveMagnifier:(int)pageIndex index:(int)index point:(CGPoint)point
{
    FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
    NSArray* array = [self _getTextRects:textPage start:index end:index+1];
    if (array.count > 0)
    {
        FSRectF *dibRect = [Utility CGRect2FSRectF:[[[array objectAtIndex:0] objectAtIndex:0] CGRectValue]];
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
        point = CGPointMake(point.x, CGRectGetMidY(rect));
    }
    _magnifierView.touchPoint = point;
    _magnifierView.magnifyPoint = [[_pdfViewCtrl getPageView:pageIndex] convertPoint:point toView:[_pdfViewCtrl getDisplayView]];
    [_magnifierView setNeedsDisplay];
}

- (void)closeMagnifier
{
    [_magnifierView removeFromSuperview];
    [_magnifierView release];
    _magnifierView = nil;
}

-(NSString*)getName
{
    return Tool_Select;
}

#pragma mark IDocEventListener

- (void)onDocWillClose:(FSPDFDoc* )document
{
    self.isEdit = NO;
    [self clearSelection];
}

@end
