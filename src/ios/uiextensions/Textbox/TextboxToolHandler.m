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

#import "TextboxToolHandler.h"
#import "ColorUtility.h"
#import "Masonry.h"
#import "StringDrawUtil.h"
#import "UIExtensionsManager+Private.h"
#import "Utility.h"

@interface TextboxToolHandler () <UITextViewDelegate>

@property (nonatomic, assign) int pageIndex;
@property (nonatomic, assign) CGPoint tapPoint;
@property (nonatomic, assign) BOOL pageIsAlreadyExist;
@property (nonatomic, assign) int pageindex;
@property (nonatomic, strong) FSPointF *startPoint;
@property (nonatomic, strong) FSPointF *endPoint;
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) FSRectF *dibRect;

@property (nonatomic, assign) int startPosIndex;
@property (nonatomic, assign) int endPosIndex;
@property (nonatomic, strong) NSArray *arraySelectedRect;
@property (nonatomic, assign) CGRect currentEditRect;
@property (nonatomic, assign) BOOL isPanCreate;
@end

@implementation TextboxToolHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
    CGFloat minAnnotPageInset;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanges:) name:UIDeviceOrientationDidChangeNotification object:nil];
        //        self.fontName = @"Times-Roman";
        //        self.fontSize = 12;
        _pageIsAlreadyExist = NO;
        _type = e_annotFreeText;
        minAnnotPageInset = 5;
    }
    return self;
}

- (NSString *)getName {
    return Tool_Textbox;
}

- (BOOL)isEnabled {
    return YES;
}

- (void)onActivate {
}

- (void)onDeactivate {
    [self save];
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer {
    if (!self.pageIsAlreadyExist) {
        self.pageIndex = pageIndex;
        self.pageIsAlreadyExist = YES;
    }
    [self save];
    _isSaved = NO;

    if (_extensionsManager.currentToolHandler == self) {
        CGPoint point = CGPointZero;
        UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
        if (recognizer) {
            point = [recognizer locationInView:pageView];
            //self.tapPoint = [recognizer locationInView:];

        } else {
            point = _freeTextStartPoint;
        }
        float fontSize = [_extensionsManager getAnnotFontSize:e_annotFreeText];
        fontSize = [Utility convertWidth:fontSize fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];
        NSString *fontName = [_extensionsManager getAnnotFontName:e_annotFreeText];
        UIFont *font = [self getSysFont:fontName size:fontSize];
        if (!font) {
            font = [UIFont boldSystemFontOfSize:fontSize];
        }
        CGSize testSize = [Utility getTestSize:font];
        _originalDibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];

        CGFloat pageViewWidth = [_pdfViewCtrl getPageView:pageIndex].frame.size.width;
        if(DEVICE_iPAD)
            _textView = [[UITextView alloc] initWithFrame:CGRectMake(point.x, point.y, pageViewWidth - point.x >= 300 ? 300 : pageViewWidth - point.x, testSize.height)];
        else
           _textView = [[UITextView alloc] initWithFrame:CGRectMake(point.x, point.y, pageViewWidth - point.x >= 100 ? 100 : pageViewWidth - point.x, testSize.height)];
        _textView.delegate = self;
        [self adjustTextViewFrame:_textView inPageView:pageView forMinPageInset:minAnnotPageInset];

        if ((DEVICE_iPHONE && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)) || (DEVICE_iPHONE && ((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) < (375 * 667)) && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight))) {
            UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
            doneView.backgroundColor = [UIColor clearColor];
            // doneView.backgroundColor = [UIColor colorWithRGBHex:0xfffbdb];
            UIButton *doneBT = [UIButton buttonWithType:UIButtonTypeCustom];
            [doneBT setBackgroundImage:[UIImage imageNamed:@"common_keyboard_done"] forState:UIControlStateNormal];
            [doneBT addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
            [doneView addSubview:doneBT];
            [doneBT mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(doneView.mas_right).offset(0);
                make.top.equalTo(doneView.mas_top).offset(0);
                make.size.mas_equalTo(CGSizeMake(40, 40));
            }];
            _textView.inputAccessoryView = doneView;
        }
        if (OS_ISVERSION7) {
            _textView.textContainerInset = UIEdgeInsetsMake(2, -4, 2, -4);
        } else {
            _textView.contentInset = UIEdgeInsetsMake(-8, -8, -8, -8);
        }
        _textView.layer.borderColor = [UIColor redColor].CGColor;
        _textView.layer.borderWidth = 1;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textColor = ({
            UInt32 color = [_extensionsManager getAnnotColor:e_annotFreeText];
            float opacity = [_extensionsManager getAnnotOpacity:e_annotFreeText];
            BOOL isMappingColorMode = (_pdfViewCtrl.colorMode == e_colorModeMapping);
            if (isMappingColorMode && color == 0) {
                color = 16775930;
            }
            if (!isMappingColorMode && color == 16775930) {
                color = 0;
            }
            [UIColor colorWithRGBHex:color alpha:opacity];
        });
        _textView.font = font;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        _textView.scrollEnabled = NO;
        _textView.clipsToBounds = NO;
        [pageView addSubview:_textView];

        UIMenuController *menu = [UIMenuController sharedMenuController];
        menu.menuItems = nil;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasHidden:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];

        [_textView becomeFirstResponder];
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    return [self onPageViewLongAndPan:pageIndex recognizer:recognizer];
}

- (BOOL)onPageViewLongAndPan:(int)pageIndex recognizer:(UIGestureRecognizer *)recognizer {
    id<IAnnotHandler> annotHandler = nil;
    FSAnnot *annot = _extensionsManager.currentAnnot;
    if (annot != nil) {
        annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            if ([annotHandler onPageViewShouldBegin:pageIndex recognizer:recognizer annot:annot]) {
                [annotHandler onPageViewPan:pageIndex recognizer:(UIPanGestureRecognizer*)recognizer annot:annot];
                return YES;
            } else {
                _extensionsManager.currentAnnot = nil;
            }
        } else {
            [annotHandler onPageViewPan:pageIndex recognizer:(UIPanGestureRecognizer*)recognizer annot:annot];
            return YES;
        }
    }
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    //    FSPointF *dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    //    FS_POINTF dibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self save];
        self.pageIndex = pageIndex;
        self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (pageIndex != self.pageIndex) {
            return NO;
        }

        self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        self.dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.dibRect pageIndex:pageIndex];
        rect = CGRectIntersection(rect, pageView.bounds);
        [_pdfViewCtrl refresh:CGRectUnion(rect, self.rect) pageIndex:pageIndex needRender:NO];
        self.rect = rect;
        //        [pageView invalidate:rect];
        //        [pageView invalidateForModify:CGRectZero];

    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (pageIndex != self.pageIndex) {
            pageIndex = self.pageIndex;
            pageView = [_pdfViewCtrl getPageView:pageIndex];
            point = [recognizer locationInView:pageView];
        }
        //save current annotation and transfor to none

        //        if (pageIndex != self.pageIndex ) {
        //            id<IDvPageView> realPageView = [[APPDELEGATE.app.read getDocViewer] getPageView:self.pageIndex];
        //            pageView = realPageView;
        //        }

        //        FSPDFTextSelect *textPage = [Utility getTextSelect:_pdfViewCtrl.currentDoc pageIndex:pageIndex];

        //        NSArray *array = [self _getTextRects:textPage start:self.startPosIndex end:self.endPosIndex];
        NSMutableArray *arrayQuads = [NSMutableArray array];
        for (int i = 0; i < 1; i++) {
            CGPoint point1;
            CGPoint point2;
            CGPoint point3;
            CGPoint point4;
            point1.x = self.dibRect.left;
            point1.y = self.dibRect.top;
            point2.x = self.dibRect.right;
            point2.y = self.dibRect.top;
            point3.x = self.dibRect.left;
            point3.y = self.dibRect.bottom;
            point4.x = self.dibRect.right;
            point4.y = self.dibRect.bottom;

            NSValue *value1 = [NSValue valueWithCGPoint:point1];
            NSValue *value2 = [NSValue valueWithCGPoint:point2];
            NSValue *value3 = [NSValue valueWithCGPoint:point3];
            NSValue *value4 = [NSValue valueWithCGPoint:point4];
            NSArray *arrayQuad = [NSArray arrayWithObjects:value1, value2, value3, value4, nil];
            [arrayQuads addObject:arrayQuad];
        }
        //        FSCRT_RECTF rect = [_pdfViewCtrl convertPageViewRectToPdfRect:self.currentEditRect];
        //        rect = [_pdfViewCtrl convertPageViewRectToPdfRect:self.rect];
        //        FSRectF *rect = [_pdfViewCtrl convertPageViewRectToPdfRect:self.rect pageIndex:pageIndex]; // or self.self.currentEditRect ?

        if (!self.pageIsAlreadyExist) {
            self.pageIndex = pageIndex;
            self.pageIsAlreadyExist = YES;
        }

        CGRect rect = self.rect;
        [self save];
        _isSaved = NO;
        self.rect = rect;

        if (_extensionsManager.currentToolHandler == self) {
            float fontSize = [_extensionsManager getAnnotFontSize:e_annotFreeText];
            fontSize = [Utility convertWidth:fontSize fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];
            //            float fontSize = self.fontSize;
            //            fontSize = [pageView docToPageViewLineWidth:fontSize];
            NSString *fontName = [_extensionsManager getAnnotFontName:e_annotFreeText];
            UIFont *font = [self getSysFont:fontName size:fontSize];
            if (!font) {
                font = [UIFont boldSystemFontOfSize:fontSize];
            }
            _originalDibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
            _textView = [[UITextView alloc] initWithFrame:CGRectMake(self.rect.origin.x, self.rect.origin.y, self.rect.size.width, self.rect.size.height)];

            if ((DEVICE_iPHONE && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)) || (DEVICE_iPHONE && ((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) < (375 * 667)) && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight))) {
                UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
                doneView.backgroundColor = [UIColor clearColor];
                // doneView.backgroundColor = [UIColor colorWithRGBHex:0xfffbdb];
                UIButton *doneBT = [UIButton buttonWithType:UIButtonTypeCustom];
                [doneBT setBackgroundImage:[UIImage imageNamed:@"common_keyboard_done"] forState:UIControlStateNormal];
                [doneBT addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
                [doneView addSubview:doneBT];
                [doneBT mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(doneView.mas_right).offset(0);
                    make.top.equalTo(doneView.mas_top).offset(0);
                    make.size.mas_equalTo(CGSizeMake(40, 40));
                }];
                _textView.inputAccessoryView = doneView;
            }
            _textView.delegate = self;
            if (OS_ISVERSION7) {
                _textView.textContainerInset = UIEdgeInsetsMake(2, -4, 2, -4);
            } else {
                _textView.contentInset = UIEdgeInsetsMake(-8, -8, -8, -8);
            }
            _textView.layer.borderColor = [UIColor redColor].CGColor;
            _textView.layer.borderWidth = 1;
            _textView.backgroundColor = [UIColor clearColor];
            //            _textView.textColor = [UIColor colorWithRGBHex:self.color alpha:self.opacity];
            _textView.textColor = ({
                UInt32 color = [_extensionsManager getAnnotColor:e_annotFreeText];
                float opacity = [_extensionsManager getAnnotOpacity:e_annotFreeText];
                BOOL isMappingColorMode = (_pdfViewCtrl.colorMode == e_colorModeMapping);
                if (isMappingColorMode && color == 0) {
                    color = 16775930;
                }
                if (!isMappingColorMode && color == 16775930) {
                    color = 0;
                }
                [UIColor colorWithRGBHex:color alpha:opacity];
            });
            _textView.font = font;
            _textView.showsVerticalScrollIndicator = NO;
            _textView.showsHorizontalScrollIndicator = NO;
            _textView.scrollEnabled = NO;
            _textView.clipsToBounds = NO;
            [_pdfViewCtrl refresh:_textView.frame pageIndex:pageIndex needRender:NO];
            //            [pageView invalidateForModify:_textView.frame];

            [pageView addSubview:_textView];
            self.isPanCreate = YES;
            UIMenuController *menu = [UIMenuController sharedMenuController];
            menu.menuItems = nil;

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(keyboardWasShown:)
                                                         name:UIKeyboardDidShowNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(keyboardWasHidden:)
                                                         name:UIKeyboardWillHideNotification
                                                       object:nil];

            [_textView becomeFirstResponder];
            return YES;
        }
        return NO;
    }
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (_extensionsManager.currentToolHandler == self) {
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            if (_textView) {
                UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
                CGPoint point = [gestureRecognizer locationInView:pageView];
                if (_textView == [pageView hitTest:point withEvent:nil]) {
                    return NO;
                }
            }

            return YES; //Tap gesture to add free text by simple click
        }
    }
    return NO;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
    if (_extensionsManager.currentToolHandler != self) {
        return;
    }
    if (_textView) {
    } else {
        CGRect selfRect = self.rect;
        CGContextSetRGBFillColor(context, 0, 0, 1, 0.3);
        CGContextFillRect(context, selfRect);
    }
}

- (UIFont *)getSysFont:(NSString *)name size:(float)size {
    UIFont *font = [UIFont fontWithName:[Utility convert2SysFontString:name] size:size];
    if (!font) {
        font = [UIFont systemFontOfSize:size];
    }
    return font;
}

//- (NSArray *)_getTextRects:(FSPDFTextSelect *)fstextPage start:(int)start end:(int)end {
//    __block NSArray *ret = nil;
//    Task *task = [[Task alloc] init];
//    task.run = ^() {
//        ret = [Utility getTextRects:fstextPage startCharIndex:start endCharIndex:end];
//    };
//    [_taskServer executeSync:task];
//    return ret;
//}

#pragma mark IDvTouchEventListener
- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView {
    [self save];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    UIView *pageView = [_pdfViewCtrl getPageView:self.pageIndex];
    if (pageView) {
        CGRect frame = textView.frame;
        CGSize constraintSize = CGSizeMake(frame.size.width, MAXFLOAT);
        CGSize size = [textView sizeThatFits:constraintSize];
        if (self.isPanCreate) {
            if (size.height < frame.size.height) {
                size.height = frame.size.height;
            }
        }

        textView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, size.height);
        //        if (textView.frame.size.height + textView.frame.origin.y > CGRectGetHeight(pageView.frame)) {
        //            textView.frame = CGRectMake(textView.frame.origin.x, CGRectGetHeight(pageView.frame) - textView.frame.size.height - 5, textView.frame.size.width, size.height);
        //            [textView endEditing:YES];
        //        }
        if (textView.frame.size.height >= (CGRectGetHeight(pageView.frame) - 20)) {
            [textView endEditing:YES];
        }
        if (textView.frame.size.width >= (CGRectGetWidth(pageView.frame) - 20)) {
            [textView endEditing:YES];
        }
        [self adjustTextViewFrame:textView inPageView:pageView forMinPageInset:minAnnotPageInset];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self save];
}

- (void)adjustTextViewFrame:(UITextView *)textView inPageView:(UIView *)pageView forMinPageInset:(CGFloat)inset {
    CGRect bounds = CGRectInset(pageView.bounds, inset, inset);
    if (!CGRectIntersectsRect(textView.frame, bounds)) {
        return;
    }
    if (CGRectGetMinX(textView.frame) < CGRectGetMinX(bounds)) {
        CGPoint center = textView.center;
        center.x += CGRectGetMinX(bounds) - CGRectGetMinX(textView.frame);
        textView.center = center;
    }
    if (CGRectGetMaxX(textView.frame) > CGRectGetMaxX(bounds)) {
        CGPoint center = textView.center;
        center.x -= CGRectGetMaxX(textView.frame) - CGRectGetMaxX(bounds);
        textView.center = center;
    }
    if (CGRectGetMinY(textView.frame) < CGRectGetMinY(bounds)) {
        CGPoint center = textView.center;
        center.y += CGRectGetMinY(bounds) - CGRectGetMinY(textView.frame);
        textView.center = center;
    }
    if (CGRectGetMaxY(textView.frame) > CGRectGetMaxY(bounds)) {
        CGPoint center = textView.center;
        center.y -= CGRectGetMaxY(textView.frame) - CGRectGetMaxY(bounds);
        textView.center = center;
    }
}

#pragma mark - keyboard
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)keyboardWasShown:(NSNotification *)aNotification {
    if (_keyboardShown) {
        return;
    }
    _keyboardShown = YES;
    NSDictionary *info = [aNotification userInfo];
    NSValue *frame = nil;
    frame = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGRect keyboardFrame = [frame CGRectValue];
    CGRect textFrame = _textView.frame;

    //    UIView *pageView = [_pdfViewCtrl getPageView:self.pageIndex];
    //    if (pageView) {
    CGPoint oldPvPoint = [_pdfViewCtrl convertDisplayViewPtToPageViewPt:CGPointMake(0, 0) pageIndex:self.pageIndex];
    FSPointF *oldPdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:oldPvPoint pageIndex:self.pageIndex];

    CGRect dvAnnotRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:textFrame pageIndex:self.pageIndex];
    float positionY;
    if (DEVICE_iPHONE && !OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        positionY = SCREENWIDTH - dvAnnotRect.origin.y - dvAnnotRect.size.height;
    } else {
        positionY = SCREENHEIGHT - dvAnnotRect.origin.y - dvAnnotRect.size.height;
    }

    if (positionY < keyboardFrame.size.height) {
        float dvOffsetY = keyboardFrame.size.height - positionY + 40;
        CGRect offsetRect = CGRectMake(0, 0, 100, dvOffsetY);

        CGRect pvRect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:offsetRect pageIndex:self.pageIndex];
        FSRectF *pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:self.pageIndex];
        float pdfOffsetY = pdfRect.top - pdfRect.bottom;

        PDF_LAYOUT_MODE layoutMode = [_pdfViewCtrl getPageLayoutMode];
        if (layoutMode == PDF_LAYOUT_MODE_SINGLE ||
            layoutMode == PDF_LAYOUT_MODE_TWO ||
            layoutMode == PDF_LAYOUT_MODE_TWO_LEFT ||
            layoutMode == PDF_LAYOUT_MODE_TWO_RIGHT ||
            layoutMode == PDF_LAYOUT_MODE_TWO_MIDDLE) {
            //                float tmpPvOffset = [pageView docToPageViewLineWidth:pdfOffsetY];
            float tmpPvOffset = pvRect.size.height;
            CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
            CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:self.pageIndex];
            //                [[APPDELEGATE.app.read getDocViewer] setBottomOffset:tmpDvRect.size.height];
            [_pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
        } else if (layoutMode == PDF_LAYOUT_MODE_CONTINUOUS) {
            if ([_pdfViewCtrl getCurrentPage] == [_pdfViewCtrl getPageCount] - 1) {
                //                    float tmpPvOffset = [pageView docToPageViewLineWidth:pdfOffsetY];
                float tmpPvOffset = pvRect.size.height;
                CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
                CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:self.pageIndex];
                //                    [[APPDELEGATE.app.read getDocViewer] setBottomOffset:tmpDvRect.size.height];
                [_pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
            } else {
                //                    FS_POINTF jumpPdfPoint = {oldPdfPoint.x, oldPdfPoint.y - pdfOffsetY};
                //                    [[APPDELEGATE.app.read getDocViewer] jumpToPage:pageIndex withDocPoint:jumpPdfPoint animated:YES];
                FSPointF *jumpPdfPoint = [[FSPointF alloc] init];
                [jumpPdfPoint set:oldPdfPoint.x y:oldPdfPoint.y - pdfOffsetY];
                [_pdfViewCtrl gotoPage:self.pageIndex withDocPoint:jumpPdfPoint animated:YES];
            }
        }
    }
}

- (void)keyboardWasHidden:(NSNotification *)aNotification {
    _keyboardShown = NO;

    PDF_LAYOUT_MODE layoutMode = [_pdfViewCtrl getPageLayoutMode];
    if (layoutMode == PDF_LAYOUT_MODE_SINGLE ||
        layoutMode == PDF_LAYOUT_MODE_TWO ||
        layoutMode == PDF_LAYOUT_MODE_TWO_LEFT ||
        layoutMode == PDF_LAYOUT_MODE_TWO_RIGHT ||
        layoutMode == PDF_LAYOUT_MODE_TWO_MIDDLE ||
        self.pageIndex == [_pdfViewCtrl getPageCount] - 1) {
        [_pdfViewCtrl setBottomOffset:0];
    }
    //    id<IDvPageView> pageView = [[APPDELEGATE.app.read getDocViewer] getPageView:self.pageIndex];
    //    if (pageView) {
    //        _keyboardShown = NO;
    //
    //        if ([[APPDELEGATE.app.read getDocViewer] getDisplayMode] == PDF_DISPLAY_MODE_SINGLE || [[APPDELEGATE.app.read getDocViewer] getDisplayMode] == PDF_DISPLAY_MODE_TWO || pageIndex == [APPDELEGATE.app.read getDocMgr].currentDoc.pageCount - 1) {
    //            [[APPDELEGATE.app.read getDocViewer] setBottomOffset:0];
    //        }
    //    }
}

- (void)onPageChangedFrom:(int)oldIndex to:(int)newIndex {
    [self save];
}

- (void)save {
    if (_textView && !_isSaved) {
        _isSaved = YES;

        if (_textView.text.length > 0) {
            CGRect textFrame = _textView.frame;
            NSString *content = [StringDrawUtil getWrappedStringInTextView:_textView];

            //                FSCRT_RECTF rect = [_pdfViewCtrl convertPageViewRectToPdfRect:textFrame];
            FSRectF *rect = [_pdfViewCtrl convertPageViewRectToPdfRect:textFrame pageIndex:self.pageIndex];
            //                FtAnnot *annot = [FtAnnot createWithDefaultOptionForPageIndex:pageIndex rect:rect contents:content];
            FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:self.pageIndex];
            if (!page) {
                return;
            }
            FSFreeText *annot = (FSFreeText *) [page addAnnot:e_annotFreeText rect:rect];
            annot.NM = [Utility getUUID];
            annot.author = [SettingPreference getAnnotationAuthor];
            //            [annot setBorderInfo:({
            //                       FSBorderInfo *borderInfo = [[FSBorderInfo alloc] init];
            //                       [borderInfo setWidth:1];
            //                       [borderInfo setStyle:e_borderStyleSolid];
            //                       borderInfo;
            //                   })];

            [annot setDefaultAppearance:({
                       FSDefaultAppearance *appearance = [annot getDefaultAppearance];
                       appearance.flags = e_defaultAPFont | e_defaultAPTextColor | e_defaultAPFontSize;
                       NSString *fontName = [_extensionsManager getAnnotFontName:e_annotFreeText];
                       int fontID = [Utility toStandardFontID:fontName];
                       if (fontID == -1) {
                           appearance.font = [[FSFont alloc] initWithFontName:fontName fontStyles:0 weight:0 charset:e_fontCharsetDefault];
                       } else {
                           appearance.font = [[FSFont alloc] initWithStandardFontID:fontID];
                       }
                       appearance.fontSize = [_extensionsManager getAnnotFontSize:e_annotFreeText];
                       unsigned int color = [_extensionsManager getAnnotColor:e_annotFreeText];
                       appearance.textColor = color;
                       appearance;
                   })];
            //                annot.color = self.color;
            //                annot.fontName = self.fontName;
            //                annot.fontSize = self.fontSize;
            int opacity = [_extensionsManager getAnnotOpacity:e_annotFreeText];
            annot.opacity = opacity / 100.0f;
            annot.contents = content;
            annot.createDate = [NSDate date];
            annot.modifiedDate = [NSDate date];
            annot.subject = @"Textbox";
            annot.flags = e_annotFlagPrint;
            [annot resetAppearanceStream];
            // move annot if exceed page edge, as the annot size may be changed after reset ap (especially for Chinese char, the line interspace is changed)
            {
                FSRectF *rect = annot.fsrect;
                if (rect.bottom < 0) {
                    rect.top -= rect.bottom;
                    rect.bottom = 0;
                    annot.fsrect = rect;
                    [annot resetAppearanceStream];
                }
            }
            if (annot) {
                id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
                [annotHandler addAnnot:annot addUndo:YES];
            }
            //                annot.canReply = NO;
            //                Task *task = [[Task alloc] init];
            //                task.run = ^() {
            //                    [self addAnnot:annot addUndo:YES others:@{ IsFromServer : @0 }];
            //                    [_textView resignFirstResponder];
            //                    [_textView removeFromSuperview];
            //                    _textView = nil;
            //                    self.rect = CGRectZero;
            //                    self.isPanCreate = NO;
            //
            //                    [pageView invalidate:textFrame];
            //                    double delayInSeconds = .3;
            //                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            //                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            //                        [pageView invalidateForModify:textFrame];
            //                    });
            //                };
            //                [_taskServer executeSync:task];
            //            }
        }

        [_textView resignFirstResponder];
        [_textView removeFromSuperview];
        _textView = nil;
        self.rect = CGRectZero;
        self.isPanCreate = NO;
        self.pageIsAlreadyExist = NO;

        [[NSNotificationCenter defaultCenter] removeObserver:self];
        //        if (self.isSelectoolCreate) {
        //            self.isSelectoolCreate = NO;
        //            [_extensionsManager setCurrentToolHandler:nil];
        //        } else {
        //            if (_onlyAddOnce || !_extensionsManager.continueAddAnnot) {
        //                _onlyAddOnce = NO;
        //                [_extensionsManager setCurrentToolHandler:nil];
        //            }
        //        }
    }
}

//- (void)addAnnot:(FtAnnot *)dmAnnot addUndo:(BOOL)addUndo others:(NSDictionary *)others {
//    FtAddUndoItem *undoItem = [[FtAddUndoItem alloc] init];
//    undoItem.pageIndex = dmAnnot.pageIndex;
//    undoItem.NM = dmAnnot.NM;
//    undoItem.annot = dmAnnot.annot;
//    undoItem.author = dmAnnot.author;
//    undoItem.color = dmAnnot.color;
//    undoItem.opacity = dmAnnot.opacity;
//    undoItem.fontName = dmAnnot.fontName;
//    undoItem.fontSize = dmAnnot.fontSize;
//    undoItem.rect = dmAnnot.rect;
//    undoItem.contents = dmAnnot.contents;
//    undoItem.createDate = dmAnnot.createDate;
//    undoItem.modifiedDate = dmAnnot.modifiedDate;
//
//    DmPage *dmPage = [[APPDELEGATE.app.read getDocMgr].currentDoc getPage:dmAnnot.pageIndex];
//    FSCRT_PAGE page = dmPage.page;
//
//    FSPDF_TEXTPAGE textPage = NULL;
//
//    if (!page) {
//        return;
//    }
//
//    FSPDF_Page_LoadAnnots(page);
//
//    FSCRT_ANNOT annot = NULL;
//
//    if (dmAnnot.archive) {
//        FSCRT_ARCHIVE archive = NULL;
//        FSCRT_Archive_Create(&archive);
//        FSCRT_BSTR data;
//        [DmUtil convertNSData2BSTR:dmAnnot.archive bstr:&data];
//        FSCRT_Archive_LoadData(archive, &data);
//        FSPDF_Archive_DeserializeAnnot(archive, page, &annot);
//        FSCRT_Archive_Release(archive);
//    } else {
//        FSCRT_BSTR type;
//        [DmUtil convertNSString2BSTR:[DmAnnot convertAnnotTypeToSDKType:dmAnnot.annotType] bstr:&type];
//        FSCRT_RECTF rect = dmAnnot.rect;
//        //patch rect to avoid sdk parm check
//        if (rect.left != 0 && rect.left == rect.right) {
//            rect.right++;
//        }
//        if (rect.bottom != 0 && rect.bottom == rect.top) {
//            rect.top++;
//        }
//        FS_RESULT ret = FSPDF_Annot_Add(page, &rect, &type, NULL, INT32_MAX, &annot);
//        if (ret == FSCRT_ERRCODE_SUCCESS && annot) {
//            //Set name (uuid)
//            FSCRT_BSTR uuid;
//            [DmUtil convertNSString2BSTR:dmAnnot.NM bstr:&uuid];
//            FSPDF_Annot_SetName(annot, &uuid);
//            //Set author
//            FSCRT_BSTR author;
//            [DmUtil convertNSString2BSTR:dmAnnot.author bstr:&author];
//            FSPDF_Annot_SetTitle(annot, &author);
//            //Set add and modify time
//            NSDate *now = [NSDate date];
//            FSCRT_DATETIMEZONE time = [DmUtil convert2FSTime:now];
//            if (dmAnnot.createDate) {
//                FSCRT_DATETIMEZONE createTime = [DmUtil convert2FSTime:dmAnnot.createDate];
//                FSPDF_Annot_SetCreationDateTime(annot, &createTime);
//            } else {
//                FSPDF_Annot_SetCreationDateTime(annot, &time);
//                dmAnnot.createDate = now;
//            }
//            if (dmAnnot.modifiedDate) {
//                FSCRT_DATETIMEZONE modTime = [DmUtil convert2FSTime:dmAnnot.modifiedDate];
//                FSPDF_Annot_SetModifiedDateTime(annot, &modTime);
//            } else {
//                FSPDF_Annot_SetModifiedDateTime(annot, &time);
//                dmAnnot.modifiedDate = now;
//            }
//
//            FSPDF_Annot_SetOpacity(annot, dmAnnot.opacity / 100.0);
//
//            FSPDF_ANNOTBORDER border;
//            border.borderWidth = 1;
//            border.borderStyle = FSPDF_ANNOT_BORDERSTYLE_SOLID;
//            ret = FSPDF_Annot_SetBorder(annot, &border);
//
//            FSCRT_BSTR contents;
//            [DmUtil convertNSString2BSTR:dmAnnot.contents bstr:&contents];
//            FSPDF_Annot_SetContents(annot, &contents);
//            FSPDF_DEFAULTAPPEARANCE defAppearance;
//            defAppearance.flags = FSPDF_DEFAULTAPPEARANCE_FONT | FSPDF_DEFAULTAPPEARANCE_TEXTCOLOR;
//            defAppearance.fontSize = dmAnnot.fontSize;
//            FSCRT_FONT font;
//            FSCRT_Font_CreateStandard([DmUtil convertFontString2Id:dmAnnot.fontName], &font);
//            defAppearance.font = font;
//            defAppearance.textColor = dmAnnot.color;
//            FSPDF_Annot_SetDefaultAppearance(annot, &defAppearance);
//            FSCRT_Font_Release(font);
//
//            FS_DWORD flags = FSPDF_ANNOTFLAG_PRINT;
//
//            FSPDF_Annot_SetFlags(annot, flags);
//
//            FSPDF_Annot_ResetAppearance(annot);
//
//            dmAnnot.annot = annot;
//            undoItem.annot = annot;
//            [dmPage addAnnot:dmAnnot others:others];
//            [[APPDELEGATE.app.read getDocMgr].currentDoc setModified:YES];
//            if (addUndo) {
//                [[APPDELEGATE.app.read getDocMgr].currentDoc addUndoItem:undoItem];
//            }
//        }
//    }
//}

// useless ?
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event onView:(UIView *)view {
    if (_textView != nil) {
        CGPoint pt = [_textView convertPoint:point fromView:view];
        if (CGRectContainsPoint(_textView.bounds, pt)) {
            return _textView;
        }
    }
    return nil;
}

- (void)dismissKeyboard {
    [_textView resignFirstResponder];
}

- (void)orientationChanges:(NSNotification *)note {
    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
    if (DEVICE_iPHONE) {
        if (((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) >= (375 * 667)) && (o == UIDeviceOrientationLandscapeLeft || o == UIDeviceOrientationLandscapeRight)) {
            UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
            doneView.backgroundColor = [UIColor clearColor];
            _textView.inputAccessoryView = doneView;
        }
    } else if (((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) >= (375 * 667)) && (o == UIDeviceOrientationPortrait || o == UIDeviceOrientationPortraitUpsideDown)) {
        UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
        doneView.backgroundColor = [UIColor clearColor];
        // doneView.backgroundColor = [UIColor colorWithRGBHex:0xfffbdb];
        UIButton *doneBT = [UIButton buttonWithType:UIButtonTypeCustom];
        [doneBT setBackgroundImage:[UIImage imageNamed:@"common_keyboard_done"] forState:UIControlStateNormal];
        [doneBT addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
        [doneView addSubview:doneBT];
        [doneBT mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(doneView.mas_right).offset(0);
            make.top.equalTo(doneView.mas_top).offset(0);
            make.size.mas_equalTo(CGSizeMake(40, 40));
        }];
        _textView.inputAccessoryView = doneView;
    }
}

@end
