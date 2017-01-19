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

#import "FormAnnotHandler.h"

static NSString *FORM_CHAR_BACK = @"BACK";


@implementation FormAnnotHandler {
    FSPDFViewCtrl* _pdfViewCtrl;
    TaskServer* _taskServer;
    UIExtensionsManager* _extensionsManager;
    FSFormFiller* _formFiller;
}

-(void)dealloc
{
    [super dealloc];
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        [_extensionsManager registerAnnotHandler:self];
        [_pdfViewCtrl registerDocEventListener:self];
        
        _formFiller = nil;
    }
    return self;
}

-(enum FS_ANNOTTYPE)getType
{
    return e_annotWidget;
}

-(BOOL)annotCanAnswer:(FSAnnot*)annot
{
    return YES;
}

-(FSRectF*)getAnnotBBox:(FSAnnot*)annot
{
    return annot.fsrect;
}

-(BOOL)isHitAnnot:(FSAnnot*)annot point:(FSPointF*)point
{
    FSAnnot* hitAnnot = [[annot getPage] getAnnotAtPos:point tolerance:5];
    if([[hitAnnot getUniqueID] isEqualToString:[annot getUniqueID]])
        return YES;
    return NO;
}

-(void)onAnnotSelected:(FSAnnot*)annot
{
    _isOver = NO;
}

-(void)onAnnotDeselected:(FSAnnot*)annot
{
    [self endForm:annot.pageIndex];
}

-(void)addAnnot:(int)pageIndex annot:(FSAnnot*)annot addUndo:(BOOL)addUndo
{
    
}

-(void)modifyAnnot:(FSAnnot*)annot addUndo:(BOOL)addUndo
{
    
}

-(void)removeAnnot:(FSAnnot*)annot addUndo:(BOOL)addUndo
{
    
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    return [self onPageViewTap:pageIndex recognizer:recognizer annot:annot];
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
    bool canFillForm = allPermission & e_permFillForm;
    if (![_pdfViewCtrl.currentDoc hasForm] || !canFillForm) {
        return NO;
    }
    
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    FSPointF* pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    if (_extensionsManager.currentAnnot == annot)
    {
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint])
        {
            _hasFormChanged = NO;
            _editFormControlNeedSetCursor = NO;
            BOOL bRet = [_formFiller tap:[_pdfViewCtrl.currentDoc getPage:pageIndex] point:pdfPoint];
            if (self.editFormControlNeedTextInput)
            {
                if (!self.hiddenTextField)
                {
                    self.currentEditRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:[_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex] pageIndex:pageIndex];
                    self.hiddenTextField = [[[UITextView alloc] init] autorelease];
                    self.hiddenTextField.hidden = YES;
                    self.hiddenTextField.delegate = self;
                    self.hiddenTextField.text = @"";
                    self.lastText = @"";
                    
                    [[_pdfViewCtrl getOverlayView:pageIndex] addSubview:self.hiddenTextField];
                    
                    [self.hiddenTextField becomeFirstResponder];
                    
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(keyboardWasShown:)
                                                                 name:UIKeyboardDidShowNotification object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(keyboardWasHidden:)
                                                                 name:UIKeyboardWillHideNotification object:nil];
                }
            }
            else
            {
                [self endTextInput];
            }
        }
        else
        {
            [_extensionsManager setCurrentAnnot:nil];
        }
        return YES;
    }
    else
    {
        [_extensionsManager setCurrentAnnot:annot];
        
        _hasFormChanged = NO;
        _editFormControlNeedSetCursor = NO;
        
        [_formFiller tap:[_pdfViewCtrl.currentDoc getPage:pageIndex] point:pdfPoint];
        
        
        BOOL needReturn = _isOver;
        if (needReturn)
        {
            return YES;
        }
        
        
        if (self.editFormControlNeedTextInput)
        {
            if (!self.hiddenTextField)
            {
                self.currentEditRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:[_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex] pageIndex:pageIndex];
                self.hiddenTextField = [[[UITextView alloc] init] autorelease];
                self.hiddenTextField.hidden = YES;
                self.hiddenTextField.delegate = self;
                self.hiddenTextField.text = @"";
                self.lastText = @"";
                
                [[_pdfViewCtrl getOverlayView:pageIndex] addSubview:self.hiddenTextField];
                
                [self.hiddenTextField becomeFirstResponder];
                
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(keyboardWasShown:)
                                                             name:UIKeyboardDidShowNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(keyboardWasHidden:)
                                                             name:UIKeyboardWillHideNotification object:nil];
            }
        }
        else
        {
            [self endTextInput];
        }
        
        if (self.editFormControlNeedTextInput || self.editFormControlNeedSetCursor) {
            
        }
        else
        {
            [self endOp:YES];
        }
        
        return _hasFormChanged;
    }
}

- (void)tap:(int)pageIndex point:(CGPoint)point
{
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    int pdfX,pdfY;
    pdfX = pdfY = 0;
    CGSize size = pageView.frame.size;
    int sizeX = size.width;
    int sizeY = size.height;
    [[pageView getPage] getFromCroppedRect:&pdfX pdfY:&pdfY pdfWidth:&sizeX pdfHeight:&sizeY];
    FSMatrix* matrix = [_pdfViewCtrl getDisplayMatrix:pageIndex];
    FSMatrix* matrixReverse = [matrix getReverse];
    FSPointF* fspoint = [[FSPointF alloc] init];
    [fspoint set:point.x y:point.y];
    FSPointF* pdfpoint = [matrixReverse transform:fspoint];
    _hasFormChanged = NO;
    _editFormControlNeedSetCursor = NO;
    
    [_formFiller tap:[_pdfViewCtrl.currentDoc getPage:pageIndex] point:pdfpoint];
    
    if (self.hiddenTextField) {
        self.hiddenTextField.text = @"";
        self.lastText = @"";
    }

}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot*)annot
{
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot*)annot
{
    unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
    bool canFillForm = allPermission & e_permFillForm;
    if (!canFillForm) {
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
    
}

- (void)endOp:(BOOL)needDelay
{
    if (!_isOver)
    {
        _isOver = YES;
        if (needDelay)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [_extensionsManager setCurrentAnnot:nil];
            });
        }
        else
        {
            [_extensionsManager setCurrentAnnot:nil];
        }
    }
    [_pdfViewCtrl refresh:CGRectZero pageIndex:[_pdfViewCtrl getCurrentPage]];
}
- (void)endTextInput
{
    if (self.hiddenTextField)
    {
        _isOver = YES;
        [self.hiddenTextField resignFirstResponder];
        _isOver = NO;
        self.lastText = @"";
        [self.hiddenTextField removeFromSuperview];
        self.hiddenTextField = nil;
        [_pdfViewCtrl refresh:CGRectZero pageIndex:[_pdfViewCtrl getCurrentPage]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)endForm:(int)pageIndex
{
    if (_extensionsManager.currentAnnot) {
        [self tap:pageIndex point:CGPointMake(-100, -100)];
        [self endTextInput];
    }
}

#pragma mark - UITextFieldDelegate


-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@""]) {
        text = FORM_CHAR_BACK;
        [self formInputText:text];
        if (!self.editFormControlNeedTextInput) {
            [self endOp:YES];
        }
    }
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text isEqualToString:self.lastText]) {
        return;
    }
    NSString *string = nil;
    int i = 0;
    while (i < self.lastText.length) {
        string = FORM_CHAR_BACK;
        [self formInputText:string];
        i++;
    }
    
    for (int i = 0; i < [textView.text length]; i++) {
        NSString *inputText = [textView.text substringWithRange:NSMakeRange(i, 1)];
        [self formInputText:inputText];
    }
    self.lastText = textView.text;
    if (!self.editFormControlNeedTextInput)
    {
        [self endOp:YES];
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
    
    
    FSAnnot *dmAnnot = _extensionsManager.currentAnnot;
    if (dmAnnot) {
        CGPoint oldPvPoint = [_pdfViewCtrl convertDisplayViewPtToPageViewPt:CGPointMake(0, 0) pageIndex:dmAnnot.pageIndex];
        FSPointF* oldPdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:oldPvPoint pageIndex:dmAnnot.pageIndex];
        
        CGRect pvAnnotRect = [_pdfViewCtrl convertPdfRectToPageViewRect:dmAnnot.fsrect pageIndex:dmAnnot.pageIndex];
        CGRect dvAnnotRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvAnnotRect pageIndex:dmAnnot.pageIndex];
        if (SCREENHEIGHT - dvAnnotRect.origin.y - dvAnnotRect.size.height < keyboardFrame.size.height) {
            float dvOffsetY = keyboardFrame.size.height - (SCREENHEIGHT - dvAnnotRect.origin.y - dvAnnotRect.size.height) + 20;
            CGRect offsetRect = CGRectMake(0, 0, 100, dvOffsetY);
            
            CGRect pvRect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:offsetRect pageIndex:dmAnnot.pageIndex];
            FSRectF* pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:dmAnnot.pageIndex];
            float pdfOffsetY = pdfRect.top - pdfRect.bottom;
            
            FSPointF* jumpPdfPoint = [[FSPointF alloc] init];
            [jumpPdfPoint set:oldPdfPoint.x y:oldPdfPoint.y - pdfOffsetY];
            if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_SINGLE
                || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO) {
                [_pdfViewCtrl setBottomOffset:dvOffsetY];
            }
            else if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_CONTINUOUS)
            {
                if ([_pdfViewCtrl getCurrentPage] == [_pdfViewCtrl.currentDoc getPageCount] - 1) {
                    FSRectF *fsRect = [[[FSRectF alloc] init] autorelease];
                    [fsRect set:0 bottom:pdfOffsetY right:pdfOffsetY top:0];
                    float tmpPvOffset = [_pdfViewCtrl convertPdfRectToPageViewRect:fsRect pageIndex:dmAnnot.pageIndex].size.width;
                    CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
                    CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:dmAnnot.pageIndex];
                    [_pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
                }
                else
                {
                    [_pdfViewCtrl gotoPage:dmAnnot.pageIndex withDocPoint:jumpPdfPoint animated:YES];
                }
            }
        }
        
    }
}


- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    _keyboardShown = NO;
    [self endOp:YES];
    FSAnnot *dmAnnot = _extensionsManager.currentAnnot;
    if (dmAnnot) {
        if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_SINGLE
            || dmAnnot.pageIndex == [_pdfViewCtrl.currentDoc getPageCount] - 1
            || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO) {
            [_pdfViewCtrl setBottomOffset:0];
        }
    }
    
}

- (void)formInputText:(NSString*)character
{
    @synchronized(self)
    {
        unsigned int code = 0;

        if (!character || character.length == 0)
        {
            return;
        }
        else if ([character isEqualToString:@"\n"])
        {
            code = 0x0D; //enter key
        }
        else if ([character isEqualToString:FORM_CHAR_BACK])
        {
            code = 0x08; //backspace key
        }
        else
        {
            NSData *myD = [character dataUsingEncoding:NSUTF16LittleEndianStringEncoding];
            Byte *bytes = (Byte *)[myD bytes];
            //byte to hex
            NSString *hexStr=@"";
            for(int i=0;i<[myD length];i++)
            {
                NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];//hex
                if([newHexStr length]==1)
                    hexStr = [NSString stringWithFormat:@"0%@%@",newHexStr,hexStr];
                else
                    hexStr = [NSString stringWithFormat:@"%@%@",newHexStr,hexStr];
            }
            code = strtoul([[hexStr substringWithRange:NSMakeRange(0, hexStr.length)] UTF8String], 0, 16);
        }
        
        [_formFiller input:code];
    }
}

- (void)setFormTimer:(int)uElapse lpTimerFunc:(FS_CALLBACK_TIMER)lpTimerFunc
{
    [self killFormTimer];
    _formTimer = [NSTimer scheduledTimerWithTimeInterval:(float)uElapse/(float)1000
                                                  target:self
                                                selector:@selector(handleFormTimer:)
                                                userInfo:nil
                                                 repeats:YES];
    _formTimerCallback = lpTimerFunc;
}

- (void)killFormTimer
{
    _formTimerCallback = nil;
    [_formTimer invalidate];
    _formTimer = nil;
}

- (void)handleFormTimer:(NSTimer *)timer
{
    if (_formTimerCallback)
    {
        _formTimerCallback(10);
    }
}

-(void)refresh: (FSPDFPage*)page pdfRect: (FSRectF*)pdfRect
{
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:pdfRect pageIndex:[page getIndex]];
    [_pdfViewCtrl refresh:rect pageIndex:[page getIndex]];
    
    _hasFormChanged = YES;
}

-(BOOL)setTimer: (int)elapse timerFunc: (FS_CALLBACK_TIMER)timerFunc timerID: (int *)timerID
{
    [self setFormTimer:elapse lpTimerFunc:timerFunc];
    *timerID = 10;
    return YES;
}

-(BOOL)killTimer: (int)timerID
{
    [self killFormTimer];
    return YES;
}

-(void)focusGotOnControl: (FSFormControl*)control fieldValue: (NSString *)fieldValue
{
    self.editFormControl = control;
    FSFormField* field = [control getField];
    enum FS_FORMFIELDTYPE type = [field getType];
    if(type != e_formFieldTextField)
        self.editFormControlNeedSetCursor = YES;
    if(type == e_formFieldTextField || (type == e_formFieldComboBox && ([field getFlags] & e_formFieldFlagComboEdit)))
        self.editFormControlNeedTextInput = YES;
}

-(void)focusLostFromControl: (FSFormControl*)control fieldValue: (NSString *)fieldValue
{
    self.editFormControl = nil;
    FSFormField* field = [control getField];
    enum FS_FORMFIELDTYPE type = [field getType];
    if(type != e_formFieldTextField)
        self.editFormControlNeedSetCursor = NO;
    if(type == e_formFieldTextField || (type == e_formFieldComboBox && ([field getFlags] & e_formFieldFlagComboEdit)))
        self.editFormControlNeedTextInput = NO;
}

#pragma mark IDocEventListener

- (void)onDocOpened:(FSPDFDoc* )document error:(int)error
{
    if (nil == _formFiller && [_pdfViewCtrl.currentDoc hasForm])
    {
        _formFiller = [FSFormFiller create:[_pdfViewCtrl.currentDoc getForm] assist:self];
        [_formFiller retain];
        [_formFiller highlightFormFields:YES];
    }
}

- (void)onDocWillClose:(FSPDFDoc* )document
{
    if (document)
        _formFiller = nil;
}

@end

