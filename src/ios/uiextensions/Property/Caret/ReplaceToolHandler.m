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
#import "ReplaceToolHandler.h"
#import "UIExtensionsManager+Private.h"
#import "NoteDialog.h"

@interface ReplaceToolHandler ()
@property (nonatomic, assign) int pageindex;
@property (nonatomic, strong) NSMutableArray *colors;
@end

@implementation ReplaceToolHandler {
    UIExtensionsManager* _extensionsManager;
    FSPDFViewCtrl*  _pdfViewCtrl;
    TaskServer* _taskServer;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        [_extensionsManager registerToolHandler:self];
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        _type = e_annotCaret;
    }
    return self;
}

- (int)getCharIndexAtPos:(int)pageIndex point:(CGPoint)point
{
    FSPointF *dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
    return [textPage getIndexAtPos:dibPoint.x y:dibPoint.y tolerance:0];
}

- (NSArray*)getCurrentSelectRects:(int)pageIndex
{
    UIView* view = [_pdfViewCtrl getPageView:pageIndex];
    CGSize size = view.frame.size;
    int offsetY = 0;
    int offsetX = 0;
    __block CGRect unionRect = CGRectZero;
    NSMutableArray *ret = [NSMutableArray array];
    
    FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
    NSArray *array = [Utility getTextRects:textPage start:MIN(_startPosIndex,_endPosIndex) count:ABS(_endPosIndex-_startPosIndex)+1];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGRect rect = [[obj objectAtIndex:0] CGRectValue];
        FSRectF *dibRect = [Utility CGRect2FSRectF:rect];
        CGRect selfRect = [self getRealRectWithOptions:pageIndex dibRect:dibRect size:size offsetY:offsetY offsetX:offsetX];
        [ret addObject:[NSValue valueWithCGRect:selfRect]];
        if (CGRectEqualToRect(unionRect, CGRectZero))
        {
            unionRect = selfRect;
        }
        else
        {
            unionRect = CGRectUnion(unionRect, selfRect);
        }
    }];
    self.currentEditRect = [Utility normalizeCGRect:unionRect];
    return ret;
}

- (void)getTheCurrentRowPdfRectWithCurrentSelectedIndex:(int)index pageIndex:(int)pageIndex
{
    FSRectF*  selectCharpdfRect = self.currentEditPdfRect;
    int firstIndex = index;
    FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
    for (int i = index; i > -1; i--) {
        NSArray *array = [Utility getTextRects:textPage start:i count:1];
        __block CGRect unionRect = CGRectZero;
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect rect = [[obj objectAtIndex:0] CGRectValue];
            if (CGRectEqualToRect(unionRect, CGRectZero))
            {
                unionRect = rect;
            }
            else
            {
                unionRect = CGRectUnion(unionRect, rect);
            }
        }];
        self.currentEditPdfRect = [Utility normalizeFSRect:[Utility CGRect2FSRectF:unionRect]];
        if (selectCharpdfRect.top < self.currentEditPdfRect.bottom) {
            firstIndex = i;
            break;
        }
        if (i == 0) {
            firstIndex = i;
            break;
        }
    }
    
    int lastIndex = index;
    for (int i = index; i > 0; i++) {
        NSArray *array = [Utility getTextRects:textPage start:i count:1];
        if (array.count == 0 || !array) {
            break;
        }
        __block CGRect unionRect = CGRectZero;
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect rect = [[obj objectAtIndex:0] CGRectValue];
            if (CGRectEqualToRect(unionRect, CGRectZero))
            {
                unionRect = rect;
            }
            else
            {
                unionRect = CGRectUnion(unionRect, rect);
            }
        }];
        self.currentEditPdfRect = [Utility normalizeFSRect:[Utility CGRect2FSRectF:unionRect]];
        if (selectCharpdfRect.bottom > self.currentEditPdfRect.top) {
            lastIndex = i;
            break;
        }
        if (i == 1000) {
            break;
        }
    }
    
    __block CGRect unionRect = CGRectZero;
    
    int startIndex = firstIndex == index ? index : firstIndex+1;
    int endIndex = lastIndex == index ? index : lastIndex-1;
    NSArray *array = [Utility getTextRects:textPage start:MIN(startIndex,endIndex) count:ABS(endIndex - startIndex) + 1];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGRect rect = [[obj objectAtIndex:0] CGRectValue];
        unionRect = CGRectZero;
        if (CGRectEqualToRect(unionRect, CGRectZero))
        {
            unionRect = rect;
        }
        else
        {
            unionRect = CGRectUnion(unionRect, rect);
        }
    }];
    self.currentEditPdfRect = [Utility normalizeFSRect:[Utility CGRect2FSRectF:unionRect]];
}

- (CGRect)getRealRectWithOptions:(int)pageIndex dibRect:(FSRectF*)dibRect size:(CGSize)size offsetY:(int)offsetY offsetX:(int)offsetX
{
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
    return rect;
}

- (void)clearSelection
{
    _startPosIndex = -1;
    _endPosIndex = -1;
    self.arraySelectedRect = nil;
    [_pdfViewCtrl refresh:self.pageindex needRender:NO];
}

#pragma mark - Magnifier

- (void)showMagnifier:(int)pageIndex index:(int)index point:(CGPoint)point
{
    if(_magnifierView == nil)
    {
        FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
        NSArray* array = [Utility getTextRects:textPage start:index count:2];
        if (array.count > 0)
        {
            FSRectF* dibRect = [Utility CGRect2FSRectF:[[[array objectAtIndex:0] objectAtIndex:0] CGRectValue]];
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
    NSArray* array = [Utility getTextRects:textPage start:index count:2];
    if (array.count > 0)
    {
        FSRectF* dibRect = [Utility CGRect2FSRectF:[[[array objectAtIndex:0] objectAtIndex:0] CGRectValue]];
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
        point = CGPointMake(point.x, CGRectGetMidY(rect));
    }
    _magnifierView.touchPoint = point;
    _magnifierView.magnifyPoint = [_pdfViewCtrl convertPageViewPtToDisplayViewPt:point pageIndex:pageIndex];
    [_magnifierView setNeedsDisplay];
}

- (void)closeMagnifier
{
    [_magnifierView removeFromSuperview];
    _magnifierView = nil;
}

-(NSString*)getName
{
    return Tool_Replace;
}

-(BOOL)isEnabled
{
    return YES;
}

-(void)onActivate
{
    self.startPosIndex = -1;
    self.endPosIndex = -1;
}

-(void)onDeactivate
{
    
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer
{
    return [self onPageViewLongAndPan:pageIndex recognizer:recognizer];
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer
{
    if ([_extensionsManager getCurrentToolHandler] != self) {
        return NO;
    }
    FSAnnot *annot = _extensionsManager.currentAnnot;
    id<IAnnotHandler> annotHandler = annot ? [_extensionsManager getAnnotHandlerByType:annot.type] : nil;
    if (annot != nil) {
        if ([annotHandler onPageViewTap:pageIndex recognizer:recognizer annot:annot]) {
            return YES;
        }
    }
    
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    annot = [page getAnnotAtPos:pdfPoint tolerance:5];
    
    if (annot != nil) {
        if (annotHandler != nil /*&& [annotHandler annotCanAnswer:annot] */) {
            if([annotHandler onPageViewTap:pageIndex recognizer:recognizer annot:annot])
                return YES;
        }
    }
    return NO;
    
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer
{
    return [self onPageViewLongAndPan:pageIndex recognizer:recognizer];
}

- (BOOL)onPageViewLongAndPan:(int)pageIndex recognizer:(UIGestureRecognizer *)recognizer
{
    if ([_extensionsManager getCurrentToolHandler] != self) {
        return NO;
    }
    FSAnnot *annot = _extensionsManager.currentAnnot;
    id<IAnnotHandler> annotHandler = annot ? [_extensionsManager getAnnotHandlerByType:annot.type] : nil;
    if (annot != nil) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            self.pageindex = pageIndex;

            if ([annotHandler onPageViewShouldBegin:pageIndex recognizer:recognizer annot:annot]) {
                [annotHandler onPageViewPan:pageIndex recognizer:recognizer annot:annot];
                return YES;
            }
            else
            {
                [_extensionsManager setCurrentAnnot:nil];
            }
        }
        else
        {
            [annotHandler onPageViewPan:pageIndex recognizer:recognizer annot:annot];
            return YES;
        }
    }
    FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        self.pageindex = pageIndex;
        [self clearSelection];
        int index = [self getCharIndexAtPos:pageIndex point:point];
        if (index > -1)
        {
            if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]])
            {
                FSPDFTextSelect* textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];
                NSRange range = [Utility getWordByTextIndex:index textPage:textPage];
                self.startPosIndex = range.location;
                self.endPosIndex = range.location + range.length - 1;
            }
            else
            {
                self.startPosIndex = index;
            }
            [self getCurrentSelectRects:pageIndex];
            [self showMagnifier:pageIndex index:index point:point];
        }
        
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if (pageIndex != self.pageindex) {
            return NO;
        }
        CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        int index = [self getCharIndexAtPos:pageIndex point:point];
        if (index > -1)
        {
            if (self.startPosIndex == -1)
            {
                self.startPosIndex = index;
            }
            else
            {
                self.endPosIndex = index;
            }
            [self getCurrentSelectRects:pageIndex];
            [_pdfViewCtrl refresh:pageIndex needRender:NO];
            [self moveMagnifier:pageIndex index:index point:point];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self closeMagnifier];
        });
        if (self.startPosIndex == -1 || self.endPosIndex == -1)
        {
            return YES;
        }
        
        BOOL isHorizontal = YES;
        BOOL isLeftToRight = YES;
        BOOL isTopToBottom = YES;
        enum FS_ROTATION textRotation = e_rotationUnknown;
        for (int i = 0; i < [textPage getTextRectCount:self.endPosIndex count:1]; i ++) {
            textRotation = [textPage getBaselineRotation:i];
            if (textRotation == e_rotationUnknown)
                continue;
            isLeftToRight = (textRotation == e_rotation0 || textRotation == e_rotation270);
            isTopToBottom = (textRotation == e_rotation0 || textRotation == e_rotation90);
            isHorizontal = (textRotation == e_rotation0 || textRotation == e_rotation180);
            break;
        }
        
        __block CGRect unionRect = CGRectZero;
        for (int i = 0; i < 10; i++) {
            int startIndex = self.endPosIndex > self.startPosIndex ? self.endPosIndex - i : self.startPosIndex - i;
            int endIndex = self.endPosIndex > self.startPosIndex ? self.endPosIndex - i : self.startPosIndex - i;
            NSArray *array = [Utility getTextRects:textPage start:MIN(startIndex,endIndex) count:ABS(endIndex - startIndex) + 1];
            [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CGRect rect = [[obj objectAtIndex:0] CGRectValue];
                if (CGRectEqualToRect(unionRect, CGRectZero))
                {
                    unionRect = rect;
                }
                else
                {
                    unionRect = CGRectUnion(unionRect, rect);
                }
            }];
            self.currentEditPdfRect = [Utility normalizeFSRect:[Utility CGRect2FSRectF:unionRect]];
            if (unionRect.origin.x != 0 && unionRect.origin.y != 0) {
                break;
            }
        }
      
        FSRectF* rect = self.currentEditPdfRect;
        FSRectF* rectChar = self.currentEditPdfRect;
        if (ABS(rectChar.left - rectChar.right) < 1E-5 || ABS(rectChar.top - rectChar.bottom) < 1E-5) {
            return YES;
        }
        
        int index = self.endPosIndex > self.startPosIndex ? self.endPosIndex : self.startPosIndex;
        
        [self getTheCurrentRowPdfRectWithCurrentSelectedIndex:index pageIndex:pageIndex];
        FSRectF* rectWord = self.currentEditPdfRect;
        if (ABS(rectWord.left - rectWord.right) < 1E-5 || ABS(rectWord.top - rectWord.bottom) < 1E-5) {
            return YES;
        }

        float width, height, left, top;
        if (isHorizontal) {
            height = (rectWord.top - rectWord.bottom) * (8.5/10.0);
            width = height * (2.0/3.0);
            if (isLeftToRight) {
                left = rectChar.right - (width/2.0) ;
            } else {
                left = rectChar.left - (width/2.0);
            }
            if (isTopToBottom) {
                top = rectWord.top - (height * (7.5 /10.0));
            } else {
                top = rectWord.bottom + (height * (7.5 /10.0)) + height;
            }
        } else {
            width = (rectWord.right - rectWord.left) * (8.5/10.0);
            height = width * (2.0/3.0);
            if (isTopToBottom) {
                top = rectChar.bottom + (height/2.0);
            } else {
                top = rectChar.top + (height/2.0);
            }
            if (isLeftToRight) {
                left = rectWord.left + width * (7.5 /10.0);
            } else {
                left = rectWord.right - width * (7.5 /10.0) - width;
            }
        }
        [NoteDialog setViewCtrl:_pdfViewCtrl];
        [NoteDialog defaultNoteDialog].title = NSLocalizedString(@"kReplaceText", nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NoteDialog defaultNoteDialog] show:nil replyAnnots:nil];
        });
        self.currentVC = [NoteDialog defaultNoteDialog];
        [NoteDialog defaultNoteDialog].noteEditDone = ^()
        {
            FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
            if (!page) return;
            FSRectF* dibRect = [Utility makeFSRectWithLeft:left top:top right:(left + width) bottom:(top - height)];
            FSCaret* replaceAnnot = (FSCaret*)[page addAnnot:e_annotCaret rect:dibRect];
            replaceAnnot.NM = [Utility getUUID];
            replaceAnnot.author = [SettingPreference getAnnotationAuthor];
            replaceAnnot.createDate = [NSDate date];
            replaceAnnot.modifiedDate = [NSDate date];
            replaceAnnot.color = [_extensionsManager getPropertyBarSettingColor:self.type];
            replaceAnnot.opacity = [_extensionsManager getAnnotOpacity:self.type] / 100.0f;
            replaceAnnot.subject = @"Replace";
            replaceAnnot.contents = [[NoteDialog defaultNoteDialog] getContent];
            replaceAnnot.intent = @"Replace";
            replaceAnnot.flags = e_annotFlagPrint;
            
            {
                FSPDFDictionary* dict = [replaceAnnot getDict];
                int iRotation = 360 - textRotation * 90;
                [dict setAt:@"Rotate" object:[FSPDFObject createFromInteger:iRotation]];
                [replaceAnnot resetAppearanceStream];
            }
            
            NSArray *array = [Utility getTextRects:textPage start:MIN(self.startPosIndex,self.endPosIndex) count:ABS(self.endPosIndex - self.startPosIndex) + 1];
            NSMutableArray *arrayQuads = [NSMutableArray array];
            for (int i = 0; i < array.count; i++)
            {
                FSRectF *dibRect = [Utility CGRect2FSRectF:[[[array objectAtIndex:i] objectAtIndex:0] CGRectValue]];
                int direction = [[[array objectAtIndex:i] objectAtIndex:1] intValue];
                FSQuadPoints* fsqps = [[[FSQuadPoints alloc] init] autorelease];
                if (direction == 0 || direction == 4) //text is horizontal or unknown, left to right
                {
                    FSPointF* first = [[[FSPointF alloc] init] autorelease];
                    [first set:dibRect.left y:dibRect.top];
                    FSPointF* second = [[[FSPointF alloc] init] autorelease];
                    [second set:dibRect.right y:dibRect.top];
                    FSPointF* third = [[[FSPointF alloc] init] autorelease];
                    [third set:dibRect.left y:dibRect.bottom];
                    FSPointF* fourth = [[[FSPointF alloc] init] autorelease];
                    [fourth set:dibRect.right y:dibRect.bottom];
                    [fsqps set:first second:second third:third fourth:fourth];
                }
                else if (direction == 1) // test is vertical, left to right
                {
                    FSPointF* first = [[[FSPointF alloc] init] autorelease];
                    [first set:dibRect.left y:dibRect.bottom];
                    FSPointF* second = [[[FSPointF alloc] init] autorelease];
                    [second set:dibRect.left y:dibRect.top];
                    FSPointF* third = [[[FSPointF alloc] init] autorelease];
                    [third set:dibRect.right y:dibRect.bottom];
                    FSPointF* fourth = [[[FSPointF alloc] init] autorelease];
                    [fourth set:dibRect.right y:dibRect.top];
                    [fsqps set:first second:second third:third fourth:fourth];
                }
                else if (direction == 2) //text is horizontal, right to left
                {
                    FSPointF* first = [[[FSPointF alloc] init] autorelease];
                    [first set:dibRect.right y:dibRect.bottom];
                    FSPointF* second = [[[FSPointF alloc] init] autorelease];
                    [second set:dibRect.left y:dibRect.bottom];
                    FSPointF* third = [[[FSPointF alloc] init] autorelease];
                    [third set:dibRect.right y:dibRect.top];
                    FSPointF* fourth = [[[FSPointF alloc] init] autorelease];
                    [fourth set:dibRect.left y:dibRect.top];
                    [fsqps set:first second:second third:third fourth:fourth];
                }
                else if (direction == 3) //text is vertical, right to left
                {
                    FSPointF* first = [[[FSPointF alloc] init] autorelease];
                    [first set:dibRect.right y:dibRect.top];
                    FSPointF* second = [[[FSPointF alloc] init] autorelease];
                    [second set:dibRect.right y:dibRect.bottom];
                    FSPointF* third = [[[FSPointF alloc] init] autorelease];
                    [third set:dibRect.left y:dibRect.top];
                    FSPointF* fourth = [[[FSPointF alloc] init] autorelease];
                    [fourth set:dibRect.left y:dibRect.bottom];
                    [fsqps set:first second:second third:third fourth:fourth];
                }
                [arrayQuads addObject:fsqps];
            }
            FSMarkup *mkAnnot = (FSMarkup*)[page addAnnot:e_annotStrikeOut rect:rect];
            mkAnnot.NM = [Utility getUUID];
            mkAnnot.author = [SettingPreference getAnnotationAuthor];
            mkAnnot.createDate = replaceAnnot.createDate;
            mkAnnot.modifiedDate = replaceAnnot.modifiedDate;
            mkAnnot.flags = e_annotFlagPrint;
            mkAnnot.subject = @"Replace";
            mkAnnot.color = replaceAnnot.color;
            mkAnnot.opacity = replaceAnnot.opacity;
            mkAnnot.intent = @"StrikeOutTextEdit";
            mkAnnot.quads = arrayQuads;
            [page setAnnotGroup:[NSArray arrayWithObjects:replaceAnnot, mkAnnot, nil] headerIndex:0];
            Task *task = [[Task alloc] init];
            task.run = ^(){
                [[_extensionsManager getAnnotHandlerByType:e_annotCaret]  addAnnot:replaceAnnot];
                [[_extensionsManager getAnnotHandlerByType:e_annotStrikeOut] addAnnot:mkAnnot];
                
                CGRect cgRect = [_pdfViewCtrl convertPdfRectToPageViewRect:replaceAnnot.fsrect pageIndex:pageIndex];
                cgRect = CGRectInset(cgRect, -20, -20);
                
                [_pdfViewCtrl refresh:cgRect pageIndex:pageIndex];
                [self clearSelection];
            };
            [_taskServer executeSync:task];
            [task release];
        };

        [NoteDialog defaultNoteDialog].noteEditCancel = ^()
        {
            [self clearSelection];
        };
    }
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([_extensionsManager getCurrentToolHandler] != self) {
        return NO;
    }
    
    FSAnnot *annot = nil;
    annot = _extensionsManager.currentAnnot;
    id<IAnnotHandler> annotHandler = nil;
    if (annot != nil) {
        annotHandler = [_extensionsManager getAnnotHandlerByType:annot.type];
        if ([annotHandler onPageViewShouldBegin:pageIndex recognizer:gestureRecognizer annot:annot]) {
            return YES;
        }
    }
    
    CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    annot = [page getAnnotAtPos:pdfPoint tolerance:5.0f];
    
    if (annot != nil) {
        annotHandler = [_extensionsManager getAnnotHandlerByType:annot.type];
        if (annotHandler != nil) {
            if([annotHandler onPageViewShouldBegin:pageIndex recognizer:gestureRecognizer annot:annot])
                return YES;
        }
    }
    
    return YES;
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

-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context
{
    if ([_extensionsManager getCurrentToolHandler] != self) {
        return;
    }
    if (self.startPosIndex == -1 || self.endPosIndex == -1) {
        return;
    }
    if (self.pageindex != pageIndex) {
        return;
    }
    if (self.pageindex != pageIndex) {
        return;
    }
    
    self.arraySelectedRect = [self getCurrentSelectRects:pageIndex];
    [self.arraySelectedRect enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CGRect selfRect = [obj CGRectValue];
         CGContextSetRGBFillColor(context, 0, 0, 1, 0.3);
         CGContextFillRect(context, selfRect);
     }];
}

@end
