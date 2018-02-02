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

#import "ImageToolHandler.h"
#import "MenuControl.h"
#import "UIExtensionsManager+Private.h"

//#define STANDARD_STAMP_WIDTH 200
//#define STANDARD_STAMP_HEIGHT 60

static void swapValues(CGFloat *v1, CGFloat *v2) {
    CGFloat tmp = *v1;
    *v1 = *v2;
    *v2 = tmp;
}

@interface ImageToolHandler ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic) int pageIndex;

// 0.0~1.0
@property (nonatomic) CGFloat minImageWidthInPage;
@property (nonatomic) CGFloat maxImageWidthInPage;
@property (nonatomic) CGFloat minImageHeightInPage;
@property (nonatomic) CGFloat maxImageHeightInPage;

@end

@implementation ImageToolHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        _type = e_annotScreen;
        _minImageWidthInPage = 0.1;
        _maxImageWidthInPage = 0.3;
        _minImageHeightInPage = 0.1;
        _maxImageHeightInPage = 0.3;
        _image = nil;
        _imageView = nil;
        _pageIndex = -1;
    }
    return self;
}

- (NSString *)getName {
    return Tool_Image;
}

- (BOOL)isEnabled {
    return YES;
}

- (void)onActivate {
}

- (void)onDeactivate {
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer {
    return [self handleLongPressAndPan:pageIndex gestureRecognizer:recognizer];
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    return [self handleLongPressAndPan:pageIndex gestureRecognizer:recognizer];
}

- (BOOL)handleLongPressAndPan:(int)pageIndex gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [gestureRecognizer locationInView:pageView];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        MenuControl *annotMenu = _extensionsManager.menuControl;
        if ([annotMenu isMenuVisible]) {
            [annotMenu hideMenu];
        }
        if (self.image == nil) {
            return YES;
        }
        self.pageIndex = pageIndex;
        CGRect annotRect = [self annotRectWithCenter:point pageView:pageView];
        if (CGRectIsEmpty(annotRect)) {
            return YES;
        }
        UIImage *image = [UIImage imageWithCGImage:[self.image CGImage]
                                             scale:[self.image scale]
                                       orientation:[Utility imageOrientationForRotation:_extensionsManager.screenAnnotRotation]];
        self.imageView = [[UIImageView alloc] initWithImage:image];
        self.imageView.frame = ({
            CGRect frame = self.imageView.frame;
            frame.size = [self.class sizeAspectRatioFitSize:frame.size maxWidth:annotRect.size.width maxHeight:annotRect.size.height];
            frame;
        });
        self.imageView.center = [self.class centerOfRect:annotRect];
        [pageView addSubview:self.imageView];
        self.imageView.alpha = .5;
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if (pageIndex != self.pageIndex) {
            return YES;
        }
        self.imageView.frame = ({
            CGRect frame = self.imageView.frame;
            CGFloat w = CGRectGetWidth(frame);
            CGFloat h = CGRectGetHeight(frame);
            frame.origin.x = point.x - w / 2;
            frame.origin.y = point.y - h / 2;
            [Utility boundedRectForRect:frame containerRect:pageView.bounds];
        });
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        if (self.pageIndex == -1 || self.image == nil || self.imageView == nil) {
            return YES;
        }
        [self addAnnotWithRect:self.imageView.frame pageIndex:self.pageIndex];
        self.pageIndex = -1;
        self.image = nil;
        [UIView animateWithDuration:0.3
            animations:^{
                self.imageView.alpha = 0;
            }
            completion:^(BOOL finished) {
                [self.imageView removeFromSuperview];
                self.imageView = nil;
            }];
    }
    return YES;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer {
    if (self.image == nil) {
        return YES;
    }
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    CGRect frame = [self annotRectWithCenter:point pageView:pageView];
    if (CGRectIsEmpty(frame)) {
        return YES;
    }
    [self addAnnotWithRect:frame pageIndex:pageIndex];
    self.image = nil;
    return YES;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
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

- (CGRect)annotRectWithCenter:(CGPoint)center pageView:(UIView *)pageView {
    float pageWidth = CGRectGetWidth(pageView.frame);
    float pageHeight = CGRectGetHeight(pageView.frame);
    if (!CGRectContainsPoint(pageView.bounds, center)) {
        return CGRectZero;
    }
    CGFloat originWidth = self.image.size.width;
    CGFloat originHeight = self.image.size.height;
    if (_extensionsManager.screenAnnotRotation == e_rotation90 || _extensionsManager.screenAnnotRotation == e_rotation270) {
        swapValues(&originWidth, &originHeight);
    }

    CGFloat width = MIN(MAX(originWidth, self.minImageWidthInPage * pageWidth), self.maxImageWidthInPage * pageWidth);
    CGFloat height = originHeight / originWidth * width;
    height = MIN(MAX(height, self.minImageHeightInPage * pageHeight), self.maxImageHeightInPage * pageHeight);
    width = originWidth / originHeight * height;

    CGRect frame = CGRectMake(center.x - width / 2, center.y - height / 2, width, height);
    return [Utility boundedRectForRect:frame containerRect:pageView.bounds];
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
}

+ (CGSize)sizeAspectRatioFitSize:(CGSize)originSize maxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight {
    CGSize size = originSize;
    CGFloat aspectRatio = originSize.height / originSize.width;
    if (size.width > maxWidth) {
        size.width = maxWidth;
        size.height = size.width * aspectRatio;
    }
    if (size.height > maxHeight) {
        size.height = maxHeight;
        size.width = size.height / aspectRatio;
    }
    return size;
}

+ (CGPoint)centerOfRect:(CGRect)rect {
    return CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2);
}

- (void)addAnnotWithRect:(CGRect)rect pageIndex:(int)pageIndex {
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    FSRectF *fsrect = [_pdfViewCtrl convertPageViewRectToPdfRect:rect pageIndex:pageIndex];
    FSScreen *annot = (FSScreen *) [page addAnnot:e_annotScreen rect:fsrect];
    if (!annot) {
        return;
    }
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    annot.flags = e_annotFlagPrint;
    annot.intent = @"Img";
    annot.opacity = [_extensionsManager getAnnotOpacity:self.type] / 100.0f;
    [annot setRotation:_extensionsManager.screenAnnotRotation];
    FSImage *fsimage = [Utility createFSImageWithUIImage:self.image];
    if (fsimage) {
        [annot setImage:fsimage];
    }
    [annot resetAppearanceStream];
    [_pdfViewCtrl refresh:CGRectInset(rect, -5, -5) pageIndex:pageIndex needRender:YES];

    id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByType:self.type];
    [annotHandler addAnnot:annot addUndo:YES];
}

@end
