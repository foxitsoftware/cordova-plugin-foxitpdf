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

#import "PageNavigationModule.h"
//#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@interface PageNavigationModule () {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
    int _oldReadFrameState;
}

@property (strong, nonatomic) UIToolbar *gotoPageToolbar;
@property (strong, nonatomic) UITextField *pageNumBar;
@property (strong, nonatomic) UIButton *goBtn;

@property (strong, nonatomic) UIView *pageNumView;
@property (strong, nonatomic) UILabel *totalNumLabel;
@property (strong, nonatomic) UIImageView *prevImage;
@property (strong, nonatomic) UIImageView *nextImage;
@property (assign, nonatomic) BOOL gotoToolbarShouldShow;

@property (nonatomic, assign) BOOL isFullScreen;

@end

@implementation PageNavigationModule

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    if (self = [super init]) {
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _extensionsManager = extensionsManager;
        [self initSubViews];
        self.gotoToolbarShouldShow = NO;
        [self loadModule];
        _oldReadFrameState = STATE_NORMAL;
    }
    return self;
}

- (NSString *)getName {
    return @"PageNavigation";
}

- (void)initSubViews {
    self.totalNumLabel = [[UILabel alloc] init];
    self.totalNumLabel.userInteractionEnabled = YES;
    [self.totalNumLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showGotoPageToolbar:)]];

    self.prevImage = [[UIImageView alloc] init];
    self.prevImage.image = [UIImage imageNamed:@"goto_page_jump_prev"];
    self.prevImage.userInteractionEnabled = YES;
    [self.prevImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGotoPrevView:)]];

    self.nextImage = [[UIImageView alloc] init];
    self.nextImage.image = [UIImage imageNamed:@"goto_page_jump_next"];
    self.nextImage.userInteractionEnabled = YES;
    [self.nextImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGotoNextView:)]];

    self.pageNumView = [[UIView alloc] init];
    [self.pageNumView addSubview:self.totalNumLabel];
    [self.pageNumView addSubview:self.prevImage];
    [self.pageNumView addSubview:self.nextImage];
}

- (void)addPageNumberView {
    CGRect frame = _pdfViewCtrl.bounds;

    self.prevImage.hidden = YES;
    self.nextImage.hidden = YES;

    if (DEVICE_iPHONE) {
        self.pageNumView.frame = CGRectMake(15, frame.size.height - 93, 50, 34);
        self.pageNumView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.425];
        self.pageNumView.layer.cornerRadius = 17.0;
    } else {
        self.pageNumView.frame = CGRectMake(20, frame.size.height - 94, 50, 30);
        _pageNumView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.425];
        _pageNumView.layer.cornerRadius = 15.0;
    }
    [_pdfViewCtrl insertSubview:_pageNumView aboveSubview:[_pdfViewCtrl getDisplayView]];
}

- (void)removePageNumberView {
    UIView *pageNumView = self.pageNumView;
    dispatch_async(dispatch_get_main_queue(), ^{
        [pageNumView removeFromSuperview];
    });
}

- (NSString *)getDisplayPageLabel:(int)pageIndex needTotal:(BOOL)needTotal {
    // copied from single container scroll view
    NSString *ret;
    int pageCount = [_pdfViewCtrl getPageCount];
    
    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_RIGHT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_MIDDLE) {
        if(pageIndex == 0 || pageIndex == 1) {
            ret = [NSString stringWithFormat:@"%d", pageIndex + 1];
        } else{
            if(pageCount % 2 == 1){
                pageIndex--;
                ret = [NSString stringWithFormat:@"%d,%d", pageIndex + 1, pageIndex + 2];
            }else{
                if(pageIndex == pageCount-1){
                    ret = [NSString stringWithFormat:@"%d", pageIndex + 1];
                }else{
                    pageIndex--;
                    ret = [NSString stringWithFormat:@"%d,%d", pageIndex + 1, pageIndex + 2];
                }
            }
        }
        
        if (needTotal) {
            ret = [NSString stringWithFormat:@"%@/%d", ret, pageCount];
        }
        return ret;
    }
    
    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO &&
        !(pageCount % 2 == 1 && (pageIndex == pageCount - 1))) {
        if (pageIndex % 2 == 1) {
            pageIndex--;
        }
        ret = [NSString stringWithFormat:@"%d,%d", pageIndex + 1, pageIndex + 2];
    } else {
        ret = [NSString stringWithFormat:@"%d", pageIndex + 1];
    }

    if (needTotal) {
        ret = [NSString stringWithFormat:@"%@/%d", ret, pageCount];
    }
    return ret;
}

- (UIToolbar *)gotoPageToolbar {
    if (!_gotoPageToolbar) {
        CGRect frame = _pdfViewCtrl.bounds;
        _gotoPageToolbar = [[UIToolbar alloc] init];
        _gotoPageToolbar.frame = CGRectMake(0, 20, frame.size.width, 44);
        _gotoPageToolbar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
        _gotoPageToolbar.hidden = YES;
        _gotoPageToolbar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;

        self.goBtn = [[UIButton alloc] init];
        self.goBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        self.goBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.goBtn setTitle:@"Go" forState:UIControlStateNormal];
        [self.goBtn setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateNormal];
        [self.goBtn setTitleColor:[UIColor colorWithRGBHex:0xF2FAFAFA] forState:UIControlStateHighlighted | UIControlStateDisabled | UIControlStateSelected | UIControlStateApplication | UIControlStateReserved];
        self.goBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        [self.goBtn addTarget:self action:@selector(goAction) forControlEvents:UIControlEventTouchUpInside];

        self.pageNumBar = [[UITextField alloc] initWithFrame:CGRectMake(10, 8, (int) self.goBtn.frame.origin.x - 20, 30)];
        self.pageNumBar.keyboardType = UIKeyboardTypeNumberPad;
        self.pageNumBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        self.pageNumBar.borderStyle = UITextBorderStyleRoundedRect;
        self.pageNumBar.layer.borderColor = [UIColor colorWithRGBHex:0x179cdb].CGColor;
        self.pageNumBar.layer.borderWidth = 1.0f;
        self.pageNumBar.layer.cornerRadius = 4.0f;

        if (IOS11_OR_LATER) {
            UIBarButtonItem *goBtnItem = [[UIBarButtonItem alloc] initWithCustomView:self.goBtn];
            UIBarButtonItem *leftPadding = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            leftPadding.width = -10.f;
            UIBarButtonItem *pageNumBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.pageNumBar];
            UIBarButtonItem *itemSeperator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            itemSeperator.width = 10;
            _gotoPageToolbar.items = @[leftPadding, pageNumBarItem, itemSeperator, goBtnItem];
        } else {
            [_gotoPageToolbar addSubview:self.goBtn];
            [_gotoPageToolbar addSubview:self.pageNumBar];
        }

        UIView *divideView = [[UIView alloc] init];
        divideView.backgroundColor = [UIColor colorWithRGBHex:0x949494];
        divideView.frame = CGRectMake(0, 44 - [Utility realPX:1.0f], CGRectGetWidth(_pdfViewCtrl.bounds), [Utility realPX:1.0f]);
        divideView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        [_gotoPageToolbar addSubview:divideView];
    }
    self.pageNumBar.placeholder = [self getDisplayPageLabel:[_pdfViewCtrl getCurrentPage] needTotal:YES];
    return _gotoPageToolbar;
}

- (void)gotoPageWithPageIndex:(int)pageIndex {
    if (pageIndex <= 0 || pageIndex > [_pdfViewCtrl getPageCount]) {
        self.pageNumBar.text = @"";
        self.pageNumBar.placeholder = [self getDisplayPageLabel:[_pdfViewCtrl getCurrentPage] needTotal:YES];
        AlertView *alertView = [[AlertView alloc]
                 initWithTitle:@"kWarning"
                       message:[NSString stringWithFormat:@"%@ %d - %d", FSLocalizedString(@"kWrongPageNumber"), 1, [_pdfViewCtrl getPageCount]]
            buttonClickHandler:^(UIView *alertView, NSInteger buttonIndex) {
                [self showGotoPageToolbar:nil];
            }
             cancelButtonTitle:nil
             otherButtonTitles:@"kOK", nil];
        [alertView show];
    } else {
        [self gotoPage:pageIndex - 1 animated:NO];
    }
}

- (BOOL)gotoPage:(int)index animated:(BOOL)animated {
    int pageCount = [_pdfViewCtrl getPageCount];
    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_RIGHT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_MIDDLE) {
        pageCount = pageCount +1;
    }
    
    NSAssert1(index >= -1 && index < pageCount, @"Attempt to go to page index out of range: %d", index);
    
    if (index >= 0 && index < pageCount) {
        if (YES) {
            [self.pageNumBar resignFirstResponder];
            self.gotoPageToolbar.hidden = YES;
            [_pdfViewCtrl gotoPage:index animated:animated];
        }
        return YES;
    }
    return NO;
}

- (void)quitGotoPage {
    [self.pageNumBar resignFirstResponder];
    self.gotoPageToolbar.hidden = YES;
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)goAction {
    NSString *stringPage = [_pageNumBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    int pageIndex = 0;
    if (stringPage != nil && stringPage.length != 0) {
        pageIndex = stringPage.intValue;
    }
    [self.pageNumBar resignFirstResponder];
    [self gotoPageWithPageIndex:pageIndex];
}

- (void)quitGotoMode {
    [self.pageNumBar resignFirstResponder];
    self.gotoPageToolbar.hidden = YES;
    if (!self.gotoToolbarShouldShow) {
        self.pageNumBar.text = nil;
    }
    [_extensionsManager changeState:_oldReadFrameState];
}

- (void)showGotoPageToolbar:(UITapGestureRecognizer *)recognizer {
    [_extensionsManager setCurrentAnnot:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [_pdfViewCtrl addSubview:self.gotoPageToolbar];
    [self.pageNumBar becomeFirstResponder];
    self.gotoPageToolbar.hidden = NO;
    if ([_extensionsManager getState] != STATE_PAGENAVIGATE)
        _oldReadFrameState = [_extensionsManager getState];
    [_extensionsManager changeState:STATE_PAGENAVIGATE];
}

- (void)handleGotoPrevView:(UITapGestureRecognizer *)recognizer {
    [_extensionsManager setCurrentAnnot:nil];

    if ([_pdfViewCtrl hasPrevView]) {
        [_pdfViewCtrl gotoPrevView:YES];
    }
}

- (void)handleGotoNextView:(UITapGestureRecognizer *)recognizer {
    [_extensionsManager setCurrentAnnot:nil];

    if ([_pdfViewCtrl hasNextView]) {
        [_pdfViewCtrl gotoNextView:YES];
    }
}

- (void)updatePageNumLabel {
    _totalNumLabel.text = [self getDisplayPageLabel:[_pdfViewCtrl getCurrentPage] needTotal:YES];
    _totalNumLabel.font = [UIFont systemFontOfSize:15];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize sizeName = [self.totalNumLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : self.totalNumLabel.font, NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    if (DEVICE_iPHONE) {
        self.totalNumLabel.frame = CGRectMake(0, (34 - sizeName.height) / 2, sizeName.width, sizeName.height);
    } else {
        self.totalNumLabel.frame = CGRectMake(0, (30 - sizeName.height) / 2, sizeName.width, sizeName.height);
    }
}

- (void)setPageCountLabel {
    int state = [_extensionsManager getState];
    if (state == STATE_THUMBNAIL || state == STATE_ANNOTTOOL || state == STATE_EDIT) {
        self.pageNumView.hidden = YES;
    } else {
        self.pageNumView.hidden = NO;
    }

    [self updatePageNumLabel];

    CGRect viewFrame = self.pageNumView.frame;
    if ([_pdfViewCtrl hasPrevView] && ![_pdfViewCtrl hasNextView]) {
        viewFrame.size.width = 46 + self.totalNumLabel.frame.size.width;
        self.pageNumView.frame = viewFrame;
        CGRect frame = self.totalNumLabel.frame;
        frame.origin.x = 36;
        self.totalNumLabel.frame = frame;
        self.prevImage.frame = CGRectMake(10, 9, 16, 16);
        self.prevImage.hidden = NO;
        self.nextImage.hidden = YES;
    } else if (![_pdfViewCtrl hasPrevView] && [_pdfViewCtrl hasNextView]) {
        viewFrame.size.width = 46 + self.totalNumLabel.frame.size.width;
        self.pageNumView.frame = viewFrame;
        CGRect frame = self.totalNumLabel.frame;
        frame.origin.x = 10;
        self.totalNumLabel.frame = frame;
        self.nextImage.frame = CGRectMake(20 + self.totalNumLabel.frame.size.width, 9, 16, 16);
        self.nextImage.hidden = NO;
        self.prevImage.hidden = YES;
    } else if ([_pdfViewCtrl hasPrevView] && [_pdfViewCtrl hasNextView]) {
        viewFrame.size.width = 72 + self.totalNumLabel.frame.size.width;
        self.pageNumView.frame = viewFrame;
        self.totalNumLabel.center = CGPointMake(viewFrame.size.width / 2, viewFrame.size.height / 2);
        self.prevImage.frame = CGRectMake(10, 9, 16, 16);
        self.nextImage.frame = CGRectMake(viewFrame.size.width - 26, 9, 16, 16);
        self.nextImage.hidden = NO;
        self.prevImage.hidden = NO;
    } else {
        viewFrame.size.width = 20 + self.totalNumLabel.frame.size.width;
        self.pageNumView.frame = viewFrame;
        self.totalNumLabel.center = CGPointMake(viewFrame.size.width / 2, viewFrame.size.height / 2);
        self.prevImage.hidden = YES;
        self.nextImage.hidden = YES;
    }
    self.totalNumLabel.textColor = [UIColor whiteColor];
}

- (void)loadModule {
    [_pdfViewCtrl registerScrollViewEventListener:self];
    [_pdfViewCtrl registerGestureEventListener:self];
    [_pdfViewCtrl registerPageEventListener:self];
    [_pdfViewCtrl registerDocEventListener:self];

    [_extensionsManager registerFullScreenListener:self];
    [_extensionsManager registerStateChangeListener:self];
    [_extensionsManager registerRotateChangedListener:self];
}

#pragma pageEventListener methods

- (void)onPageChanged:(int)oldIndex currentIndex:(int)currentIndex {
    [self setPageCountLabel];
}

- (void)onPageJumped {
    [self setPageCountLabel];
}

- (void)onPagesRemoved:(NSArray<NSNumber *> *)indexes {
    // If the document has only one page, there should not be a previous page and next page
    if ([_pdfViewCtrl getPageCount] == 1) {
        [_pdfViewCtrl clearPrevNextStack];
    }
    [self setPageCountLabel];
}

- (void)onPagesInsertedAtRange:(NSRange)range {
    // If insert a page, the data in the stack becomes invalid and needs to be empty
    [_pdfViewCtrl clearPrevNextStack];
    [self setPageCountLabel];
}

- (void)onPagesMoved:(NSArray<NSNumber *> *)indexes dstIndex:(int)dstIndex {
    // If insert a page, the data in the stack becomes invalid and needs to be empty
    [_pdfViewCtrl clearPrevNextStack];
    [self setPageCountLabel];
}

#pragma docEventlistener methods

- (void)onDocWillOpen {
}

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    CGRect frame = _pdfViewCtrl.bounds;
    if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.height, frame.size.width);
    }
    self.gotoPageToolbar.frame = CGRectMake(0, 20, frame.size.width, 44);
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize sizeName = [self.goBtn.titleLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : self.goBtn.titleLabel.font, NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    self.goBtn.frame = CGRectMake(frame.size.width - 10 - sizeName.width, (44 - sizeName.height) / 2, sizeName.width, sizeName.height);
    self.pageNumBar.frame = CGRectMake(10, 8, IOS11_OR_LATER ? (int) self.goBtn.frame.origin.x - 20 -20 : (int) self.goBtn.frame.origin.x - 20, 30);
    [self addPageNumberView];
    [self setPageCountLabel];
}

- (void)onDocWillClose:(FSPDFDoc *)document {
    [self removePageNumberView];
    [self.pageNumBar resignFirstResponder];
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
}

- (void)onDocWillSave:(FSPDFDoc *)document {
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (!self.gotoPageToolbar.hidden) {
        self.gotoToolbarShouldShow = YES;
    }
    self.pageNumView.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    CGRect frame = _pdfViewCtrl.bounds;
    if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.height, frame.size.width);
    }
    if (DEVICE_iPHONE) {
        self.pageNumView.frame = CGRectMake(15, frame.size.height - 93, 50, 34);
    } else {
        self.pageNumView.frame = CGRectMake(20, frame.size.height - 94, 50, 30);
    }
    self.gotoPageToolbar.frame = CGRectMake(0, 20, frame.size.width, 44);
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize sizeName = [self.goBtn.titleLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : self.goBtn.titleLabel.font, NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    self.goBtn.frame = CGRectMake(frame.size.width - 10 - sizeName.width, (44 - sizeName.height) / 2, sizeName.width, sizeName.height);
    self.pageNumBar.frame = CGRectMake(10, 8, IOS11_OR_LATER ? (int) self.goBtn.frame.origin.x - 20 -20 : (int) self.goBtn.frame.origin.x - 20, 30);
    [self setPageCountLabel];
    int state = [_extensionsManager getState];
    if (state == STATE_THUMBNAIL || state == STATE_ANNOTTOOL || state == STATE_EDIT || state == STATE_SIGNATURE || _extensionsManager.isFullScreen) {
        self.pageNumView.hidden = YES;
    } else {
        self.pageNumView.hidden = NO;
    }
    if (self.gotoToolbarShouldShow) {
        [self showGotoPageToolbar:nil];
        self.gotoToolbarShouldShow = NO;
    }
}

#pragma - IFullScreenListener

- (void)onFullScreen:(BOOL)isFullScreen {
    if (isFullScreen) {
        self.pageNumView.hidden = YES;
    } else {
        [self setPageCountLabel];
    }
}

#pragma mark IGestureEventListener

- (BOOL)onTap:(UITapGestureRecognizer *)recognizer {
    if ([_extensionsManager getState] != STATE_PAGENAVIGATE)
        return NO;
    [self quitGotoMode];
    return YES;
}

- (BOOL)onLongPress:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

#pragma - (void) onStateChanged : (int) state;

- (void)onStateChanged:(int)state {
    if (state == STATE_THUMBNAIL || state == STATE_ANNOTTOOL || state == STATE_EDIT || state == STATE_SIGNATURE) {
        self.pageNumView.hidden = YES;
    } else {
        if (state == STATE_NORMAL || state == STATE_REFLOW) {
            [self setPageCountLabel];
        }
        self.pageNumView.hidden = NO;
    }
}

@end
