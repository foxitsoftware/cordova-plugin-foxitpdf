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
#import "FtAnnotHandler.h"
#import "MenuControl.h"
#import "Utility.h"
#import "ColorUtility.h"
#import "MenuItem.h"
#import "StringDrawUtil.h"

@interface FtAnnotHandler () <UITextViewDelegate>

@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;
@property (nonatomic, retain) FSRectF* oldRect;
@property (nonatomic, retain) UIImage* annotImage;

@end

@implementation FtAnnotHandler {
    UIExtensionsManager* _extensionsManager;
    FSPDFViewCtrl* _pdfViewCtrl;
}

- (id)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        [_extensionsManager registerAnnotHandler:self];
        [_pdfViewCtrl registerScrollViewEventListener:self];
        [_extensionsManager registerRotateChangedListener:self];
        [_extensionsManager registerGestureEventListener:self];
        [_extensionsManager.propertyBar registerPropertyBarListener:self];
        [_extensionsManager registerPropertyBarListener:self];
        
        self.isShowStyle = NO;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        self.editAnnot = nil;
    }
    return self;
}

- (void)dealloc
{
    [_oldRect release];
    [_annotImage release];
    [_currentVC release];
    [_editAnnot release];
    [super dealloc];
}

-(enum FS_ANNOTTYPE)getType
{
    return e_annotFreeText;
}

-(BOOL)isHitAnnot:(FSAnnot*)annot point:(FSPointF*)point
{
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    pvRect = CGRectInset(pvRect, -10, -10);
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:annot.pageIndex];
    return CGRectContainsPoint(pvRect, pvPoint);
}

-(void)onAnnotSelected:(FSAnnot*)annot
{
    if(![annot isMarkup]) return;
    NSString* intent = [((FSMarkup*)annot) getIntent];
    if(!intent || [intent caseInsensitiveCompare:@"FreeTextTypewriter"] != NSOrderedSame)
        return;
    
    self.editAnnot = (FSFreeText*)annot;
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    
    NSMutableArray *array = [NSMutableArray array];
    
    MenuItem *copyItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kCopyText", nil) object:self action:@selector(copyText)] autorelease];
    MenuItem *editItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kEdit", nil) object:self action:@selector(edit)] autorelease];
    MenuItem *styleItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kStyle", nil) object:self action:@selector(showStyle)] autorelease];
    MenuItem *deleteItem = [[[MenuItem alloc] initWithTitle:NSLocalizedString(@"kDelete", nil) object:self action:@selector(deleteAnnot)] autorelease];
  
    if (annot.canModify) {
        [array addObject:editItem];
        [array addObject:copyItem];
        [array addObject:styleItem];
        [array addObject:deleteItem];
    }
    else
    {
        [array addObject:copyItem];
    }
    
    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:pageIndex];
    _extensionsManager.menuControl.menuItems = array;
    [_extensionsManager.menuControl setRect:dvRect];
    [_extensionsManager.menuControl showMenu];
    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;
    
    self.annotImage = [Utility getAnnotImage:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
    
    rect = CGRectInset(rect, -20, -20);
    [_pdfViewCtrl refresh:rect pageIndex:pageIndex needRender:YES];
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

-(UIFont*)getUIFontForFreeText:(FSFreeText*)freeText
{
    FSDefaultAppearance* appearance = [freeText getDefaultAppearance];
    float fontSize = appearance.fontSize ?: 10;
    fontSize = [Utility convertWidth:fontSize fromPageViewToPDF:_pdfViewCtrl pageIndex:freeText.pageIndex];
    NSString* fontName = [appearance.font getName] ?: @"Helvetica";
    UIFont *font = [self getSysFont:fontName size:fontSize];
    return font;
}

-(void)edit
{
    _isSaved = NO;
    FSFreeText *annot = (FSFreeText*)_extensionsManager.currentAnnot;
    
    int pageIndex = annot.pageIndex;
    {
        CGRect textFrame = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        _textView = [[UITextView alloc] initWithFrame:textFrame];
        _textView.delegate = self;
        if (OS_ISVERSION7)
        {
            _textView.textContainerInset = UIEdgeInsetsMake(2, -4, 2, -4);
        }
        else
        {
            _textView.contentInset = UIEdgeInsetsMake(-8,-8,-8,-8);
        }
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textColor = [UIColor colorWithRGBHex:annot.color alpha:annot.opacity];
        _textView.font = [self getUIFontForFreeText:annot];
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        _textView.scrollEnabled = NO;
        _textView.clipsToBounds = NO;
        [_textView becomeFirstResponder];
        _textView.text = annot.contents;
        [[_pdfViewCtrl getPageView:pageIndex] addSubview:_textView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];
        self.annotImage = nil;
        textFrame = CGRectInset(textFrame, -30, -30);
        [_pdfViewCtrl refresh:textFrame pageIndex:pageIndex needRender:NO];
    }
}

-(void)fixInvalidFontForFreeText:(FSFreeText*)annot
{
    FSDefaultAppearance* ap = [annot getDefaultAppearance];
    if (!ap.font || ap.fontSize == 0) {
        if (!ap.font) {
            ap.font = [FSFont createStandard:e_fontStandardIDHelvetica];
        }
        if (ap.fontSize == 0) {
            ap.fontSize = 10;
        }
        ap.flags = e_defaultAPFont | e_defaultAPTextColor | e_defaultAPFontSize;
        [annot setDefaultAppearance:ap];
    }
}

- (void)endEdit
{
    if (_textView && !_isSaved) {
        _isSaved = YES;
        if (_textView.text.length > 0) {
            StringDrawUtil *strDrawUtil = [[StringDrawUtil alloc] initWithFont:_textView.font];
            NSString *content = [strDrawUtil getReturnRefinedString:_textView.text forUITextViewWidth:_textView.bounds.size.width];
            [strDrawUtil release];
            FSFreeText* annot = (FSFreeText*)_extensionsManager.currentAnnot;
            [self fixInvalidFontForFreeText:annot];
            annot.contents = content;
            [annot resetAppearanceStream];
            
            [self modifyAnnot:_extensionsManager.currentAnnot];

        } else {
            [self removeAnnot:_extensionsManager.currentAnnot];
        }
        [_extensionsManager setCurrentAnnot:nil];
        [_textView resignFirstResponder];
        [_textView removeFromSuperview];
        [_textView release];
        _textView = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

-(void)deleteAnnot
{
    FSAnnot *annot = _extensionsManager.currentAnnot;
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        [self removeAnnot:annot];
    };
    [_extensionsManager.taskServer executeSync:task];
    [_extensionsManager setCurrentAnnot:nil];
}

-(void)showStyle
{
    [_extensionsManager.propertyBar setColors:@[@0x3366CC,@0x669933,@0xCC6600,@0xCC9900,@0xA3A305,@0xCC0000,@0x336666,@0x660066,@0x000000,@0x8F8E8E]];
    [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_FONTNAME | PROPERTY_FONTSIZE];
    FSAnnot *annot = _extensionsManager.currentAnnot;
    
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity*100.0];
    
    [self fixInvalidFontForFreeText:(FSFreeText*)annot];
    FSDefaultAppearance* appearance = [(FSFreeText*)annot getDefaultAppearance];
    float fontSize = appearance.fontSize;
    NSString* fontName = [appearance.font getName];
    [_extensionsManager.propertyBar setProperty:PROPERTY_FONTNAME stringValue:fontName];
    [_extensionsManager.propertyBar setProperty:PROPERTY_FONTSIZE floatValue:fontSize];
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
    
    [self endEdit];
    self.annotImage = nil;
    
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    newRect = CGRectInset(newRect, -20, -20);
    [_pdfViewCtrl refresh:newRect pageIndex:annot.pageIndex needRender:YES];
}

-(void)addAnnot:(FSAnnot*)annot
{
    [_extensionsManager onAnnotAdded:[annot getPage] annot:annot];
    int pageIndex = annot.pageIndex;
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
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
    return [self onPageViewTap:pageIndex recognizer:recognizer annot:annot];
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
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    if (_extensionsManager.currentAnnot != annot || pageIndex != annot.pageIndex)
    {
        return NO;
    }
    
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
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        self.oldRect = annot.fsrect;
        CGPoint translationPoint = [recognizer translationInView:[_pdfViewCtrl getPageView:pageIndex]];
        [recognizer setTranslation:CGPointZero inView:[_pdfViewCtrl getPageView:pageIndex]];
        if (!annot.canModify) {
            return YES;
        }
        float tw = translationPoint.x;
        float th = translationPoint.y;
        
        
        CGRect realPageRect = [_pdfViewCtrl getPageView:pageIndex].bounds;
        FSRectF* pageViewRect = [Utility CGRect2FSRectF: realPageRect];
        CGRect realRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
        realRect.origin.x += tw;
        realRect.origin.y += th;
        FSRectF* rect = [Utility CGRect2FSRectF:realRect];
        
        if(realRect.size.width <= realPageRect.size.width &&
           realRect.size.height <= realPageRect.size.height)
        {

            if (rect.left < pageViewRect.left) {
                float diferrence = pageViewRect.left - rect.left + 5;
                rect.left += diferrence;
                rect.right += diferrence;
            }
            if (rect.top < pageViewRect.top) {
                float diferrence = pageViewRect.top - rect.top + 5;
                rect.top += diferrence;
                rect.bottom += diferrence;
            }
            if (rect.right > pageViewRect.right) {
                float diferrence = rect.right - pageViewRect.right + 5;
                rect.right -= diferrence;
                rect.left -= diferrence;
            }
            if (rect.bottom > pageViewRect.bottom) {
                float diferrence = rect.bottom - pageViewRect.bottom + 5;
                rect.top -= diferrence;
                rect.bottom -= diferrence;
            }
        }
        CGRect newRect = [Utility FSRectF2CGRect:rect];
        CGRect oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.oldRect pageIndex:pageIndex];
        annot.fsrect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:pageIndex];
        // annot's appearance may be changed
        if(fabs(fabs(annot.fsrect.right - annot.fsrect.left) - fabs(self.oldRect.right - self.oldRect.left)) > .5f) {
            self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
        }
        CGRect  allRect = CGRectUnion(newRect, oldRect);
        allRect = CGRectInset(allRect, -30, -30);
        [_pdfViewCtrl refresh:allRect pageIndex:pageIndex needRender:NO];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        if (annot.canModify) {
            [self modifyAnnot:annot];
        }
        
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
        CGRect oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.oldRect pageIndex:annot.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:newRect pageIndex:annot.pageIndex];
        if (self.isShowStyle)
        {
            self.shouldShowMenu = NO;
            self.shouldShowPropety = YES;
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        }
        else
        {
            self.shouldShowMenu = YES;
            self.shouldShowPropety = NO;
            [_extensionsManager.menuControl setRect:showRect];
            [_extensionsManager.menuControl showMenu];
        }
        
        
        newRect = CGRectUnion(newRect, oldRect);
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:NO];
    }
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot*)annot
{
    if (annot.type == e_annotFreeText)
    {
        NSString* intent = [((FSMarkup*)annot) getIntent];
        if(!intent || [intent caseInsensitiveCompare:@"FreeTextTypewriter"] != NSOrderedSame)
            return NO;
        
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

- (UIFont*)getSysFont:(NSString*)name size:(float)size
{
    UIFont *font = [UIFont fontWithName:[Utility convert2SysFontString:name] size:size];
    if (!font)
    {
        font = [UIFont systemFontOfSize:size];
    }
    return font;
}

-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context annot:(FSAnnot*)annot
{
    if(![annot isMarkup]) return;
    NSString* intent = [((FSMarkup*)annot) getIntent];
    if(!intent || [intent caseInsensitiveCompare:@"FreeTextTypewriter"] != NSOrderedSame)
        return;
    if (pageIndex == annot.pageIndex) {
        if (_textView)
        {
            [self textViewDidChange:_textView];
        }
        else
        {
            CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
            self.oldRect = annot.fsrect;
            
            if (self.annotImage) {
                CGContextSaveGState(context);
                CGRect rect = CGRectMake(ceilf(pvRect.origin.x), ceilf(pvRect.origin.y), ceilf(pvRect.size.width), ceilf(pvRect.size.height));
                CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
                CGContextTranslateCTM(context, 0, rect.size.height);
                CGContextScaleCTM(context, 1.0, -1.0);
                CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
                CGContextDrawImage(context, rect, [self.annotImage CGImage]);
                CGContextRestoreGState(context);
            }
            
            if (_extensionsManager.currentAnnot == annot)
            {
                CGRect rect = CGRectInset(pvRect, -2,-2);
                CGContextSetLineWidth(context, 2.0);
                CGFloat dashArray[] = {3,3,3,3};
                CGContextSetLineDash(context, 3, dashArray, 4);
                CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:annot.color] CGColor]);
                CGContextStrokeRect(context, rect);
            }
        }
    }
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    CGSize oneSize = [Utility getTestSize:textView.font];
    CGPoint point = textView.frame.origin;
    
    FSAnnot *annot = _extensionsManager.currentAnnot;
    
    int pageIndex = annot.pageIndex;
    CGSize size = [textView.text sizeWithFont:textView.font constrainedToSize:CGSizeMake([_pdfViewCtrl getPageViewWidth:pageIndex] - point.x - oneSize.width, 99999) lineBreakMode:UILineBreakModeWordWrap];
    size.width += oneSize.width;
    size.height += oneSize.height;
    CGRect frame = textView.frame;
    frame.size = size;
    textView.frame = frame;
    float textViewHeight = textView.frame.origin.y + textView.frame.size.height;
    if (textViewHeight >= ([_pdfViewCtrl getPageViewHeight:pageIndex] - 20)) {
        CGRect textViewFrame = textView.frame;
        textViewFrame.origin.y -= (textViewHeight - [_pdfViewCtrl getPageViewHeight:pageIndex]);
        textView.frame = textViewFrame;
    }
    annot.fsrect = [_pdfViewCtrl convertPageViewRectToPdfRect:textView.frame pageIndex:pageIndex];
    if (textView.frame.size.height >= ([_pdfViewCtrl getPageViewHeight:pageIndex] - 20)) {
        [textView endEditing:YES];
    }
}

#pragma mark -
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    if (_keyboardShown)
        return;
    _keyboardShown = YES;
    NSDictionary* info = [aNotification userInfo];
    // Get the frame of the keyboard.
    NSValue *frame = nil;
    frame = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGRect keyboardFrame = [frame CGRectValue];
    
    
    FSAnnot *annot = _extensionsManager.currentAnnot;
    if (annot) {
        int pageIndex = annot.pageIndex;
        CGPoint oldPvPoint = [_pdfViewCtrl convertDisplayViewPtToPageViewPt:CGPointMake(0, 0) pageIndex:pageIndex];
        FSPointF* oldPdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:oldPvPoint pageIndex:pageIndex];
        
        CGRect pvAnnotRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        CGRect dvAnnotRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvAnnotRect pageIndex:annot.pageIndex];
        if (SCREENHEIGHT - dvAnnotRect.origin.y - dvAnnotRect.size.height < keyboardFrame.size.height) {
            float dvOffsetY = keyboardFrame.size.height - (SCREENHEIGHT - dvAnnotRect.origin.y - dvAnnotRect.size.height) + 60;
            CGRect offsetRect = CGRectMake(0, 0, 100, dvOffsetY);
            
            CGRect pvRect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:offsetRect pageIndex:pageIndex];
            FSRectF* pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:pageIndex];
            float pdfOffsetY = pdfRect.top - pdfRect.bottom;
            
            if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_SINGLE || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO) {
                float tmpPvOffset = pvRect.size.height;
                CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
                CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:pageIndex];
                [_extensionsManager.pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
            }
            else if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_CONTINUOUS)
            {
                if ([_pdfViewCtrl getCurrentPage] == [_pdfViewCtrl getPageCount] - 1) {
                    float tmpPvOffset = pvRect.size.height;
                    CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
                    CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:pageIndex];
                    [_extensionsManager.pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
                }
                else
                {
                    FSPointF* jumpPdfPoint = [[FSPointF alloc] init];
                    [jumpPdfPoint setX:oldPdfPoint.x];
                    [jumpPdfPoint setY:oldPdfPoint.y - pdfOffsetY];
                    [_pdfViewCtrl gotoPage:pageIndex withDocPoint:jumpPdfPoint animated:YES];
                    [jumpPdfPoint release];
                }
            }
        }
    }
}

- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    FSAnnot *annot = _extensionsManager.currentAnnot;
    
    [_pdfViewCtrl refresh:annot.pageIndex];
    _keyboardShown = NO;
    PDF_LAYOUT_MODE layoutMode = [_pdfViewCtrl getPageLayoutMode];
    if (layoutMode == PDF_LAYOUT_MODE_SINGLE || layoutMode == PDF_LAYOUT_MODE_TWO || annot.pageIndex == [_pdfViewCtrl getPageCount] - 1) {
        [_pdfViewCtrl setBottomOffset:0];
    }
}

- (void)keyboardDidHidden:(NSNotification*)aNotification
{
    [_extensionsManager setCurrentAnnot:nil];
}

#pragma mark IPropertyBarListener

- (void)onPropertyBarDismiss
{
    if (DEVICE_iPHONE && self.editAnnot &&  _extensionsManager.currentAnnot == self.editAnnot) {
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

#pragma mark IScrollViewEventListener

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

- (void)dismissAnnotMenu
{
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
        if (!DEVICE_iPHONE && _extensionsManager.propertyBar.isShowing) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
    }
}
- (void)showAnnotMenu
{
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:self.editAnnot.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.editAnnot.pageIndex];
        if (!DEVICE_iPHONE && self.shouldShowPropety)
        {
            [_extensionsManager.propertyBar refreshPropertyLayout];
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        }
        else if (self.shouldShowMenu)
        {
            [_extensionsManager.menuControl setRect:showRect];
            [_extensionsManager.menuControl showMenu];
        }
    }
}

#pragma IAnnotPropertyListener

- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotFreeText) {
        [self annotPropertyChanged];
    }
}
- (void)onAnnotOpacityChanged:(unsigned int)opacity annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotFreeText) {
        [self annotPropertyChanged];
    }
}
-(void)onAnnotFontNameChanged:(NSString *)fontName annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotFreeText) {
        [self annotPropertyChanged];
    }
}
-(void)onAnnotFontSizeChanged:(unsigned int)fontSize annotType:(enum FS_ANNOTTYPE)annotType
{
    if (annotType == e_annotFreeText) {
        [self annotPropertyChanged];
        
        if (self.shouldShowPropety) {
            [self dismissAnnotMenu];
            double delayInSeconds = .5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self showAnnotMenu];
            });
        }
    }
}

- (void)annotPropertyChanged
{
    if (self.editAnnot && self.annotImage) {
        self.annotImage = [Utility getAnnotImage:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        int pageIndex = self.editAnnot.pageIndex;
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:pageIndex];
        CGRect oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.oldRect pageIndex:pageIndex];
        [_pdfViewCtrl refresh:CGRectInset(CGRectUnion(newRect, oldRect), -10, -10) pageIndex:pageIndex needRender:NO];
    }
}

@end
