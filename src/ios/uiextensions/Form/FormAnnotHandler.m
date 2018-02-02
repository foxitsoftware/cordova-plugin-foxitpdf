/**
 * Copyright (C) 2003-2018, Foxit Software Inc..
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
#import "ColorUtility.h"
#import "../Thirdparties/Masonry/Masonry.h"

static NSString *FORM_CHAR_BACK = @"BACK";

@implementation FormAnnotHandler {
    TaskServer *_taskServer;
    int _focusedWidgetIndex;
    BOOL _lockKeyBoardPosition;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        self.extensionsManager = extensionsManager;
        self.pdfViewCtrl = self.extensionsManager.pdfViewCtrl;
        _taskServer = self.extensionsManager.taskServer;

        _keyboardHeight = 0;
        _formFiller = nil;
        _focusedWidgetIndex = -1;
        self.formNaviBar = [self buildFormNaviBar];
        [self.pdfViewCtrl addSubview:self.formNaviBar.contentView];
        [self.formNaviBar.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.right.mas_equalTo(self.pdfViewCtrl);
            make.height.mas_equalTo(49);
        }];
        [self.formNaviBar.contentView setHidden:YES];

        self.hiddenTextField = [[UITextView alloc] init];
        self.hiddenTextField.hidden = YES;
        self.hiddenTextField.delegate = self;
        self.hiddenTextField.text = @"";
        self.lastText = @"";
        self.textFormNaviBar = [self buildFormNaviBar];
        self.hiddenTextField.inputAccessoryView = self.textFormNaviBar.contentView;
        [self.pdfViewCtrl addSubview:self.hiddenTextField];
        _lockKeyBoardPosition = NO;
    }
    return self;
}

- (FSAnnotType)getType {
    return e_annotWidget;
}

- (BOOL)canFormFiledNavi:(FSFormControl *)control {
    unsigned int flags = [[control getWidget] getFlags];
    FSFormField *field = [control getField];
    unsigned int fflags = [field getFlags];
    FSFormFieldType fieldType = [[control getField] getType];
    BOOL bRet = flags & e_annotFlagReadOnly || flags & e_annotFlagHidden || flags & e_annotFlagInvisible || flags & e_annotFlagToggleNoView || fieldType == e_formFieldPushButton || fieldType == e_formFieldSignature || fflags & e_formFieldFlagReadonly;
    return !bRet;
}

- (BOOL)canShowKeybord:(FSFormField *)field {
    FSFormFieldType fieldType = [field getType];
    return e_formFieldTextField == fieldType || (e_formFieldComboBox == fieldType && ([field getFlags] & e_formFieldFlagComboEdit));
}

- (TbBaseBar *)buildFormNaviBar {
    CGRect screenFrame = _pdfViewCtrl.bounds;
    if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        screenFrame = CGRectMake(0, 0, screenFrame.size.height, screenFrame.size.width);
    }

    TbBaseBar *formNaviBar = [[TbBaseBar alloc] init];
    formNaviBar.top = NO;
    formNaviBar.contentView.frame = CGRectMake(0, screenFrame.size.height - 49, screenFrame.size.width, 49);
    formNaviBar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    formNaviBar.intervalWidth = 100.f;
    if (DEVICE_iPHONE) {
        formNaviBar.intervalWidth = 40.f;
    }

    UIImage *prevImg = [UIImage imageNamed:@"formfill_pre_normal"];
    TbBaseItem *prevItem = [TbBaseItem createItemWithImage:prevImg imageSelected:prevImg imageDisable:prevImg background:nil];
    prevItem.onTapClick = ^(TbBaseItem *item) {
        FSPDFDoc *doc = [self.pdfViewCtrl getDoc];
        int curPageIndex = -1;
        if (_extensionsManager.currentAnnot)
            curPageIndex = [_extensionsManager.currentAnnot pageIndex];
        else
            curPageIndex = [self.pdfViewCtrl getCurrentPage];
        FSPDFPage *page = [doc getPage:curPageIndex];
        int pageCount = [doc getPageCount];
        int annotCount = [page getAnnotCount];
        BOOL canShowKeybord = NO;
        int savedPos = _focusedWidgetIndex;
        int savedPageIndex = curPageIndex;
        int prePos = _focusedWidgetIndex < 0 ? 0 : _focusedWidgetIndex - 1;
        while (true) {
            if (prePos == -1) {
                if (curPageIndex == 0)
                    curPageIndex = pageCount - 1;
                else
                    curPageIndex--;

                page = [doc getPage:curPageIndex];
                annotCount = [page getAnnotCount];
                prePos = annotCount - 1;
                if (annotCount == 0)
                    continue;
            }
            if (savedPageIndex == curPageIndex && savedPos == prePos)
                break;

            FSAnnot *annot = [page getAnnot:prePos];
            if ([annot getType] == e_annotWidget) {
                FSWidget *widget = (FSWidget *) annot;
                if ([self canFormFiledNavi:[widget getControl]]) {
                    canShowKeybord = [self canShowKeybord:[widget getField]];
                    FSRectF *rect = [annot getRect];
                    [self setFocus:[widget getControl] isHidden:NO];

                    [self.extensionsManager setCurrentAnnot:widget];
                    if (canShowKeybord) {
                        [self gotoFormField];
                    } else {
                        CGRect pvRect = [self.pdfViewCtrl convertPdfRectToPageViewRect:rect pageIndex:curPageIndex];
                        CGPoint pvPt = CGPointZero;
                        pvPt.x = pvRect.origin.x - (self.pdfViewCtrl.frame.size.width - pvRect.size.width) / 2;
                        pvPt.y = pvRect.origin.y - (self.pdfViewCtrl.frame.size.height - pvRect.size.height) / 2;
                        FSPointF *pdfPt = [self.pdfViewCtrl convertPageViewPtToPdfPt:pvPt pageIndex:curPageIndex];
                        [self.pdfViewCtrl gotoPage:curPageIndex withDocPoint:pdfPt animated:YES];
                    }
                    _focusedWidgetIndex = prePos;
                    break;
                }
            }
            prePos--;
        }

        if (canShowKeybord) {
            [self.hiddenTextField becomeFirstResponder];
            self.hiddenTextField.text = @"";

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(keyboardWasShown:)
                                                         name:UIKeyboardDidShowNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(keyboardWasHidden:)
                                                         name:UIKeyboardWillHideNotification
                                                       object:nil];
        } else
            [self endTextInput];
    };
    [formNaviBar addItem:prevItem displayPosition:Position_CENTER];

    UIImage *nextImg = [UIImage imageNamed:@"formfill_next_normal"];
    TbBaseItem *nextItem = [TbBaseItem createItemWithImage:nextImg imageSelected:nextImg imageDisable:nextImg background:nil];
    nextItem.onTapClick = ^(TbBaseItem *item) {
        FSPDFDoc *doc = [self.pdfViewCtrl getDoc];
        int curPageIndex = -1;
        if (_extensionsManager.currentAnnot)
            curPageIndex = [_extensionsManager.currentAnnot pageIndex];
        else
            curPageIndex = [self.pdfViewCtrl getCurrentPage];
        FSPDFPage *page = [doc getPage:curPageIndex];
        int pageCount = [doc getPageCount];
        int annotCount = [page getAnnotCount];
        BOOL canShowKeybord = NO;
        int i = _focusedWidgetIndex;
        int savedPos = _focusedWidgetIndex;
        int savedPageIndex = curPageIndex;
        int next = i + 1;
        while (true) {
            if (next == annotCount) {
                if (curPageIndex == pageCount - 1)
                    curPageIndex = 0;
                else
                    curPageIndex++;

                page = [doc getPage:curPageIndex];
                annotCount = [page getAnnotCount];
                next = 0;
                if (annotCount == 0)
                    continue;
            }
            if (savedPageIndex == curPageIndex && next == savedPos)
                break;
            FSAnnot *annot = [page getAnnot:next];
            if ([annot getType] == e_annotWidget) {
                FSWidget *widget = (FSWidget *) annot;
                if ([self canFormFiledNavi:[widget getControl]]) {
                    canShowKeybord = [self canShowKeybord:[widget getField]];
                    FSRectF *rect = [annot getRect];
                    [self setFocus:[widget getControl] isHidden:NO];

                    [self.extensionsManager setCurrentAnnot:widget];
                    if (canShowKeybord) {
                        [self gotoFormField];
                    } else {
                        CGRect pvRect = [self.pdfViewCtrl convertPdfRectToPageViewRect:rect pageIndex:curPageIndex];
                        CGPoint pvPt = CGPointZero;
                        pvPt.x = pvRect.origin.x - (self.pdfViewCtrl.frame.size.width - pvRect.size.width) / 2;
                        pvPt.y = pvRect.origin.y - (self.pdfViewCtrl.frame.size.height - pvRect.size.height) / 2;
                        FSPointF *pdfPt = [self.pdfViewCtrl convertPageViewPtToPdfPt:pvPt pageIndex:curPageIndex];
                        [self.pdfViewCtrl gotoPage:curPageIndex withDocPoint:pdfPt animated:YES];
                    }
                    _focusedWidgetIndex = next;
                    break;
                }
            }
            next++;
        }

        if (canShowKeybord) {
            [self.hiddenTextField becomeFirstResponder];
            self.hiddenTextField.text = @"";

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(keyboardWasShown:)
                                                         name:UIKeyboardDidShowNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(keyboardWasHidden:)
                                                         name:UIKeyboardWillHideNotification
                                                       object:nil];
        } else
            [self endTextInput];
    };
    [formNaviBar addItem:nextItem displayPosition:Position_CENTER];

    TbBaseItem *resetItem = [TbBaseItem createItemWithImageAndTitle:FSLocalizedString(@"kReset") imageNormal:nil imageSelected:nil imageDisable:nil background:nil imageTextRelation:0];
    resetItem.textColor = [UIColor blackColor];
    resetItem.onTapClick = ^(TbBaseItem *item) {
        FSPDFDoc *doc = [self.pdfViewCtrl getDoc];
        int curPageIndex = [self.pdfViewCtrl getCurrentPage];
        FSPDFPage *page = [doc getPage:curPageIndex];
        FSAnnot *annot = [page getAnnot:_focusedWidgetIndex];
        if ([annot getType] == e_annotWidget) {
            FSWidget *widget = (FSWidget *) annot;
            FSFormField *field = [widget getField];

            [_formFiller setFocus:nil];
            [field reset];
            [_formFiller setFocus:[widget getControl]];
            self.hiddenTextField.text = @"";
            CGRect newRect = [self.pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
            newRect = CGRectInset(newRect, -30, -30);
            [self.pdfViewCtrl refresh:newRect pageIndex:annot.pageIndex needRender:NO];
        }
    };
    [formNaviBar addItem:resetItem displayPosition:Position_CENTER];

    TbBaseItem *doneItem = [TbBaseItem createItemWithImageAndTitle:FSLocalizedString(@"kDone") imageNormal:nil imageSelected:nil imageDisable:nil background:nil imageTextRelation:0];
    doneItem.textColor = [UIColor blackColor];
    doneItem.onTapClick = ^(TbBaseItem *item) {
        [self setFocus:nil isHidden:YES];
        [self endTextInput];
        _focusedWidgetIndex = -1;
    };
    [formNaviBar addItem:doneItem displayPosition:Position_CENTER];

    return formNaviBar;
}

- (BOOL)annotCanAnswer:(FSAnnot *)annot {
    return YES;
}

- (FSRectF *)getAnnotBBox:(FSAnnot *)annot {
    return annot.fsrect;
}

- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point {
    FSAnnot *hitAnnot = nil;
    @try {
        hitAnnot = [[annot getPage] getAnnotAtPos:point tolerance:5];
    } @catch (NSException *exception) {
    }
    if (hitAnnot && ([hitAnnot getCptr] == [annot getCptr])) {
        FSFormField *field = [((FSWidget *) hitAnnot) getField];
        if (field && ([field getFlags] & e_formFieldFlagReadonly))
            return NO;
        return YES;
    }
    return NO;
}

- (void)onAnnotSelected:(FSAnnot *)annot {
    _isOver = NO;
}

- (void)onAnnotDeselected:(FSAnnot *)annot {
    int pageIndex = annot.pageIndex;
    [self endForm:pageIndex];
    [_extensionsManager removeThumbnailCacheOfPageAtIndex:pageIndex];
}

- (void)addAnnot:(FSAnnot *)annot {
}

- (void)addAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
}

- (void)modifyAnnot:(FSAnnot *)annot {
}

- (void)modifyAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
}

- (void)removeAnnot:(FSAnnot *)annot {
}

- (void)removeAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return YES;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return YES;
}

- (void)touchesBegan:(FSPDFPage *)page point:(FSPointF *)point isHidden:(BOOL)hidden {
    [_formFiller touchesBegan:page point:point];
    if (!hidden) {
        FSWidget *widget = (FSWidget *) self.extensionsManager.currentAnnot;
        FSFormFieldType fieldType = [[widget getField] getType];
        if (e_formFieldPushButton == fieldType)
            hidden = YES;
    }
    [self.formNaviBar.contentView setHidden:hidden];
}

- (void)setFocus:(FSFormControl *)control isHidden:(BOOL)hidden {
    [_formFiller setFocus:control];
    [self.formNaviBar.contentView setHidden:hidden];
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot *)annot {
    BOOL canFillForm = [Utility canFillFormInDocument:self.pdfViewCtrl.currentDoc];
    if (!canFillForm) {
        return NO;
    }

    UIView *pageView = [self.pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [gestureRecognizer locationInView:pageView];
    FSPointF *pdfPoint = [self.pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    BOOL hasForm = NO;
    @try {
        hasForm = [self.pdfViewCtrl.currentDoc hasForm];
    } @catch (NSException *e) {
    }
    if (!hasForm) {
        return NO;
    }
    BOOL canFillForm = [Utility canFillFormInDocument:self.pdfViewCtrl.currentDoc];
    if (!canFillForm) {
        return NO;
    }
    UIView *pageView = [self.pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [[touches anyObject] locationInView:pageView];
    FSPointF *pdfPoint = [self.pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    if (self.extensionsManager.currentAnnot == annot) {
        FSAnnot *hitAnnot = nil;
        @try {
            hitAnnot = [[[self.pdfViewCtrl getDoc] getPage:pageIndex] getAnnotAtPos:pdfPoint tolerance:5];
        } @catch (NSException *exception) {
        }
        if (pageIndex == annot.pageIndex && hitAnnot && hitAnnot.type == e_annotWidget) {
            _focusedWidgetIndex = [hitAnnot getIndex];
            _hasFormChanged = NO;
            _editFormControlNeedSetCursor = NO;

            [_formFiller touchesBegan:[self.pdfViewCtrl.currentDoc getPage:pageIndex] point:pdfPoint];
            BOOL hidden = NO;
            FSWidget *widget = (FSWidget *) hitAnnot;
            FSFormFieldType fieldType = [[widget getField] getType];
            if (e_formFieldPushButton == fieldType)
                hidden = YES;
            [self.formNaviBar.contentView setHidden:hidden];

            if (self.editFormControlNeedTextInput) {
                {
                    _lockKeyBoardPosition = YES;
                    [self.extensionsManager setCurrentAnnot:hitAnnot];
                    _lockKeyBoardPosition = NO;
                    [self.hiddenTextField becomeFirstResponder];
                    self.hiddenTextField.text = @"";

                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(keyboardWasShown:)
                                                                 name:UIKeyboardDidShowNotification
                                                               object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(keyboardWasHidden:)
                                                                 name:UIKeyboardWillHideNotification
                                                               object:nil];
                }
            } else {
                [self.extensionsManager setCurrentAnnot:hitAnnot];
                [self endTextInput];
            }
        } else {
            [self touchesBegan:[self.pdfViewCtrl.currentDoc getPage:pageIndex] point:pdfPoint isHidden:YES];
            [self.extensionsManager setCurrentAnnot:nil];
        }
        return YES;
    } else {
        [self.extensionsManager setCurrentAnnot:annot];

        _hasFormChanged = NO;
        _editFormControlNeedSetCursor = NO;

        [self touchesBegan:[self.pdfViewCtrl.currentDoc getPage:pageIndex] point:pdfPoint isHidden:NO];
        _focusedWidgetIndex = [annot getIndex];

        BOOL needReturn = _isOver;
        if (needReturn) {
            return YES;
        }

        if (self.editFormControlNeedTextInput) {
            {
                [self.hiddenTextField becomeFirstResponder];
                self.hiddenTextField.text = @"";

                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(keyboardWasShown:)
                                                             name:UIKeyboardDidShowNotification
                                                           object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(keyboardWasHidden:)
                                                             name:UIKeyboardWillHideNotification
                                                           object:nil];
            }
        } else {
            [self endTextInput];
        }

        return _hasFormChanged;
    }
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    if (self.extensionsManager.currentAnnot != annot || pageIndex != annot.pageIndex) {
        return NO;
    }

    UIView *pageView = [self.pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [[touches anyObject] locationInView:pageView];
    FSPointF *pdfPoint = [self.pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    if (self.extensionsManager.currentAnnot == annot) {
        return [_formFiller touchesMoved:[annot getPage] point:pdfPoint];
    }
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    if (self.extensionsManager.currentAnnot != annot || pageIndex != annot.pageIndex) {
        return NO;
    }

    UIView *pageView = [self.pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [[touches anyObject] locationInView:pageView];
    FSPointF *pdfPoint = [self.pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    if (self.extensionsManager.currentAnnot == annot) {
        return [_formFiller touchesEnded:[annot getPage] point:pdfPoint];
    }
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context annot:(FSAnnot *)annot {
}

- (void)endOp:(BOOL)needDelay {
    if (!_isOver) {
        _isOver = YES;
    }
    [self.pdfViewCtrl refresh:CGRectZero pageIndex:[self.pdfViewCtrl getCurrentPage]];
}

- (void)endTextInput {
    if (self.hiddenTextField) {
        _isOver = YES;
        [self.hiddenTextField resignFirstResponder];
        _isOver = NO;
        self.lastText = @"";
        self.hiddenTextField.text = @"";
        [self.pdfViewCtrl refresh:CGRectZero pageIndex:[self.pdfViewCtrl getCurrentPage]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)endForm:(int)pageIndex {
    if (self.extensionsManager.currentAnnot) {
        [self endTextInput];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@""]) {
        text = FORM_CHAR_BACK;
        [self formInputText:text];
        if (!self.editFormControlNeedTextInput) {
            [self endOp:YES];
        }
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
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
    if (!self.editFormControlNeedTextInput) {
        [self endOp:YES];
    }
}

#pragma mark -
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

- (void)gotoFormField {
    FSAnnot *dmAnnot = self.extensionsManager.currentAnnot;
    if (dmAnnot) {
        CGPoint oldPvPoint = [self.pdfViewCtrl convertDisplayViewPtToPageViewPt:CGPointMake(0, 0) pageIndex:dmAnnot.pageIndex];
        FSPointF *oldPdfPoint = [self.pdfViewCtrl convertPageViewPtToPdfPt:oldPvPoint pageIndex:dmAnnot.pageIndex];

        CGRect pvAnnotRect = [self.pdfViewCtrl convertPdfRectToPageViewRect:dmAnnot.fsrect pageIndex:dmAnnot.pageIndex];
        CGRect dvAnnotRect = [self.pdfViewCtrl convertPageViewRectToDisplayViewRect:pvAnnotRect pageIndex:dmAnnot.pageIndex];
        if (CGRectGetHeight(_pdfViewCtrl.bounds) - dvAnnotRect.origin.y - dvAnnotRect.size.height < _keyboardHeight) {
            float dvOffsetY = _keyboardHeight - (CGRectGetHeight(_pdfViewCtrl.bounds) - dvAnnotRect.origin.y - dvAnnotRect.size.height) + 20;
            CGRect offsetRect = CGRectMake(0, 0, 100, dvOffsetY);

            CGRect pvRect = [self.pdfViewCtrl convertDisplayViewRectToPageViewRect:offsetRect pageIndex:dmAnnot.pageIndex];
            FSRectF *pdfRect = [self.pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:dmAnnot.pageIndex];
            float pdfOffsetY = pdfRect.top - pdfRect.bottom;

            FSPointF *jumpPdfPoint = [[FSPointF alloc] init];
            [jumpPdfPoint set:oldPdfPoint.x y:oldPdfPoint.y - pdfOffsetY];
            if ([self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_SINGLE || [self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO || [self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_RIGHT || [self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_MIDDLE) {
                [self.pdfViewCtrl setBottomOffset:dvOffsetY];
            } else if ([self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_CONTINUOUS) {
                if ([self.pdfViewCtrl getCurrentPage] == [self.pdfViewCtrl.currentDoc getPageCount] - 1) {
                    FSRectF *fsRect = [[FSRectF alloc] init];
                    [fsRect set:0 bottom:pdfOffsetY right:pdfOffsetY top:0];
                    float tmpPvOffset = [self.pdfViewCtrl convertPdfRectToPageViewRect:fsRect pageIndex:dmAnnot.pageIndex].size.width;
                    CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
                    CGRect tmpDvRect = [self.pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:dmAnnot.pageIndex];
                    [self.pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
                } else {
                    [self.pdfViewCtrl gotoPage:dmAnnot.pageIndex withDocPoint:jumpPdfPoint animated:YES];
                }
            }
        } else {
            CGPoint dvPt = CGPointZero;
            dvPt.x = dvAnnotRect.origin.x - (self.pdfViewCtrl.frame.size.width - dvAnnotRect.size.width) / 2;
            dvPt.y = dvAnnotRect.origin.y - (self.pdfViewCtrl.frame.size.height - dvAnnotRect.size.height) / 2;
            CGPoint pvPt = [self.pdfViewCtrl convertDisplayViewPtToPageViewPt:dvPt pageIndex:dmAnnot.pageIndex];
            FSPointF *pdfPt = [self.pdfViewCtrl convertPageViewPtToPdfPt:pvPt pageIndex:dmAnnot.pageIndex];
            [self.pdfViewCtrl gotoPage:dmAnnot.pageIndex withDocPoint:pdfPt animated:YES];
        }
    }
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
    if (_keyboardShown)
        return;
    _keyboardShown = YES;
    NSDictionary *info = [aNotification userInfo];
    // Get the frame of the keyboard.
    NSValue *frame = nil;
    frame = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGRect keyboardFrame = [frame CGRectValue];
    _keyboardHeight = keyboardFrame.size.height;
    [self gotoFormField];
}

- (void)keyboardWasHidden:(NSNotification *)aNotification {
    _keyboardShown = NO;
    [self endOp:YES];
    FSAnnot *dmAnnot = self.extensionsManager.currentAnnot;
    if (dmAnnot && !_lockKeyBoardPosition) {
        if ([self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_SINGLE || dmAnnot.pageIndex == [self.pdfViewCtrl.currentDoc getPageCount] - 1 || [self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO || [self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_RIGHT || [self.pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_MIDDLE) {
            [self.pdfViewCtrl setBottomOffset:0];
        }
    }
}

- (void)formInputText:(NSString *)character {
    @synchronized(self) {
        unsigned int code = 0;

        if (!character || character.length == 0) {
            return;
        } else if ([character isEqualToString:@"\n"]) {
            code = 0x0D; //enter key
        } else if ([character isEqualToString:FORM_CHAR_BACK]) {
            code = 0x08; //backspace key
        } else {
            NSData *myD = [character dataUsingEncoding:NSUTF16LittleEndianStringEncoding];
            Byte *bytes = (Byte *) [myD bytes];
            //byte to hex
            NSString *hexStr = @"";
            for (int i = 0; i < [myD length]; i++) {
                NSString *newHexStr = [NSString stringWithFormat:@"%x", bytes[i] & 0xff]; //hex
                if ([newHexStr length] == 1)
                    hexStr = [NSString stringWithFormat:@"0%@%@", newHexStr, hexStr];
                else
                    hexStr = [NSString stringWithFormat:@"%@%@", newHexStr, hexStr];
            }
            code = (unsigned int) strtoul([[hexStr substringWithRange:NSMakeRange(0, hexStr.length)] UTF8String], 0, 16);
        }

        [_formFiller input:code];
    }
}

- (void)setFormTimer:(int)uElapse lpTimerFunc:(FSTimer *)lpTimerFunc {
    [self killFormTimer];
    self.formTimer = [NSTimer scheduledTimerWithTimeInterval:(float) uElapse / (float) 1000
                                                      target:self
                                                    selector:@selector(handleFormTimer:)
                                                    userInfo:nil
                                                     repeats:YES];
    self.formTimerCallback = lpTimerFunc;
}

- (void)killFormTimer {
    self.formTimerCallback = nil;
    [self.formTimer invalidate];
    self.formTimer = nil;
}

- (void)handleFormTimer:(NSTimer *)timer {
    if (_formTimerCallback) {
        [_formTimerCallback onTimer:10];
    }
}

- (void)refresh:(FSPDFPage *)page pdfRect:(FSRectF *)pdfRect {
    CGRect rect = [self.pdfViewCtrl convertPdfRectToPageViewRect:pdfRect pageIndex:[page getIndex]];
    [self.pdfViewCtrl refresh:rect pageIndex:[page getIndex]];

    _hasFormChanged = YES;
}

- (BOOL)setTimer:(int)elapse timer:(FSTimer *)timerFunc timerID:(int *)timerID {
    [self setFormTimer:elapse lpTimerFunc:timerFunc];
    *timerID = 10;
    return YES;
}

- (BOOL)killTimer:(int)timerID {
    [self killFormTimer];
    return YES;
}

- (void)focusGotOnControl:(FSFormControl *)control fieldValue:(NSString *)fieldValue {
    FSFormField *field = [control getField];
    FSFormFieldType type = [field getType];
    if (type != e_formFieldTextField)
        self.editFormControlNeedSetCursor = YES;
    if (type == e_formFieldTextField || (type == e_formFieldComboBox && ([field getFlags] & e_formFieldFlagComboEdit)))
        self.editFormControlNeedTextInput = YES;
}

- (void)focusLostFromControl:(FSFormControl *)control fieldValue:(NSString *)fieldValue {
    FSFormField *field = [control getField];
    FSFormFieldType type = [field getType];
    if (type != e_formFieldTextField)
        self.editFormControlNeedSetCursor = NO;
    if (type == e_formFieldTextField || (type == e_formFieldComboBox && ([field getFlags] & e_formFieldFlagComboEdit)))
        self.editFormControlNeedTextInput = NO;
}

#pragma mark IDocEventListener

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    FSPDFDoc *doc = self.pdfViewCtrl.currentDoc;
    if (nil == _formFiller) {
        BOOL hasForm = NO;
        @try {
            hasForm = [doc hasForm];
        } @catch (NSException *e) {
        }
        if (hasForm && [Utility canFillFormInDocument:doc]) {
            // creating form filler may block current thread if -[ExActionHandler alert:title:type:icon:] called
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                _formFiller = [[FSFormFiller alloc] initWithForm:[doc getForm] assist:self];
                [_formFiller highlightFormFields:YES];
            });
        }
    }
}

- (void)onDocWillClose:(FSPDFDoc *)document {
    [self.formNaviBar.contentView setHidden:YES];
    if (document)
        _formFiller = nil;
}

#pragma mark IRotationEventListener

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
}

@end
