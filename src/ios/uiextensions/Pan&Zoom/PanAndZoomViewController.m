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

#import "PanAndZoomViewController.h"
#import "Utility.h"

@interface borderView : UIView
- (CGRect)receiveImageViewRect:(CGRect)rect;
@end

@implementation borderView
{
    CGRect _imageViewFrame;
    FSPDFViewCtrl*__weak _pdfViewCtrl;
}

- (instancetype)initWithFrame:(CGRect)frame pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl{
    self = [super initWithFrame:frame];
    _pdfViewCtrl = pdfViewCtrl;
    
    self.contentMode = UIViewContentModeRedraw;
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:panGesture];
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    //draw rect line
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect originRec = self.bounds;
    CGPathAddRect(path,NULL, originRec);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextAddPath(currentContext, path);
    
    [[UIColor redColor] setStroke];
    CGContextSetLineWidth(currentContext, 8.0f / (_imageViewFrame.size.width / self.bounds.size.width));
    
    CGContextDrawPath(currentContext, kCGPathStroke);
}

- (CGRect)receiveImageViewRect:(CGRect)rect {
    _imageViewFrame = rect;
}

- (void)handlePan:(UIPanGestureRecognizer*)recognizer
{
    CGPoint translation = [recognizer translationInView:self];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    //set contraint border
    if ( !CGRectContainsRect(_imageViewFrame, recognizer.view.frame) ) {
        recognizer.view.center = CGPointMake(recognizer.view.center.x - translation.x,
                                             recognizer.view.center.y - translation.y);
        
        [recognizer setTranslation:CGPointZero inView:self];
        return;
    }
    CGFloat scale = _pdfViewCtrl.bounds.size.width / recognizer.view.frame.size.width;
    [_pdfViewCtrl scrollDisplayView:translation.x * scale distanceY:translation.y * scale];
    
    [recognizer setTranslation:CGPointZero inView:self];
}
@end


@interface PanZoomView ()
{
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
    
    CGRect _tempSelfFrame;
    
    borderView * _borderView;
    CGRect _imageViewFrame;
    CGFloat _aspectRatio;
    int _pageIndex;
}
@end

@implementation PanZoomView

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)uiextensionManager {
    _extensionsManager = uiextensionManager;
    _pdfViewCtrl = uiextensionManager.pdfViewCtrl;
    _pageIndex = [_pdfViewCtrl getCurrentPage];
    
    [self correctPageIndexInCoverMode];
    
    [self correctPageIndexInFacingMode];
    
    //calculate origin frame
    float width = _pdfViewCtrl.frame.size.width;
    float height = _pdfViewCtrl.frame.size.height;
    float bottomMargin = 49.0;
    
    float subviewOriginY = height * 3.0 / 5.0;
    float subviewHeight = height * 2.0 / 5.0 - bottomMargin;
    float subviewWidth = subviewHeight;
    float subviewOriginX = width / 2.0 - subviewWidth / 2.0;
    
    CGRect frame = CGRectMake(subviewOriginX, subviewOriginY, subviewWidth, subviewHeight);
    self = [super initWithFrame:frame];
    
    //gesture
    [_extensionsManager registerAnnotEventListener:self];
    [_extensionsManager registerRotateChangedListener:self];
    [_pdfViewCtrl registerPageEventListener:self];
    [_pdfViewCtrl registerScrollViewEventListener:self];
    [_pdfViewCtrl registerLayoutEventListener:self];
    [_pdfViewCtrl registerDocEventListener:self];
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:panGesture];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor grayColor];
    self.opaque = YES;
    self.userInteractionEnabled = YES;
    self.layer.borderColor = [UIColor blackColor].CGColor;
    self.layer.borderWidth = 2;
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.imageView];
    [self bringSubviewToFront:self.imageView];
    
    _borderView = [[borderView alloc] initWithFrame:CGRectZero pdfViewCtrl:_pdfViewCtrl];
    _borderView.opaque = NO;
    _borderView.userInteractionEnabled = YES;
    [self addSubview:_borderView];
    [self bringSubviewToFront:_borderView];
    
    return self;
}

- (void)correctPageIndexInCoverMode{
    PDF_LAYOUT_MODE layoutMode = [_pdfViewCtrl getPageLayoutMode];
    if ( layoutMode == PDF_LAYOUT_MODE_TWO_RIGHT )
    {
        if (_pageIndex == 0) {
            _pageIndex = 0;
        }else{
            _pageIndex = _pageIndex -1;
        }
    }
}

- (BOOL)correctPageIndexInFacingMode
{
    PDF_LAYOUT_MODE layoutMode = [_pdfViewCtrl getPageLayoutMode];
    if ( layoutMode == PDF_LAYOUT_MODE_TWO ||
        layoutMode == PDF_LAYOUT_MODE_TWO_RIGHT )
    {
        BOOL isLeftPage = NO;
        
        if (layoutMode == PDF_LAYOUT_MODE_TWO) {
            isLeftPage = _pageIndex % 2 == 0;
        } else {
            if (_pageIndex == 0) {
                _pageIndex = 0 ;
                return YES;
            }
            isLeftPage = _pageIndex % 2 == 1;
        }
        
        if ( isLeftPage ) {
            CGRect rect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:_pdfViewCtrl.bounds pageIndex:(_pageIndex + 1)];
            if (rect.origin.x > 0) {
                _pageIndex += 1;
                return YES;
            }
        } else {
            CGRect rect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:_pdfViewCtrl.bounds pageIndex:_pageIndex];
            if (rect.origin.x < 0) {
                _pageIndex -= 1;
                return YES;
            }
        }
    }
    return NO;
}

- (void)drawRect:(CGRect)rect {
    FSPDFPage* currentPage = [_pdfViewCtrl.currentDoc getPage:_pageIndex];
    [self drawSubView:currentPage];
}

- (void)drawSubView:(FSPDFPage*)currentPage {
    float pageWidth = [currentPage getWidth];
    float pageHeight = [currentPage getHeight];

    _aspectRatio = pageWidth / pageHeight;
    //during rotation, self.frame will be set to CGRectZero.
    CGFloat thumbnailWidth = 0;
    if ( CGRectEqualToRect(self.frame, CGRectZero) ) {
        thumbnailWidth = MIN(_tempSelfFrame.size.width, _tempSelfFrame.size.height * _aspectRatio);
    } else {
        thumbnailWidth = MIN(self.frame.size.width, self.frame.size.height * _aspectRatio);
    }
    CGFloat thumbnailHeight = thumbnailWidth / _aspectRatio;
    CGSize thumbnailSize = CGSizeMake(thumbnailWidth, thumbnailHeight);
    
    UIImage *thumbnailImage = [Utility drawPage:currentPage targetSize:thumbnailSize shouldDrawAnnotation:YES needPause:nil];
    
    //calculate image view frame
    CGFloat originX, originY, width, height;
    if (_aspectRatio > 1) {
        width = self.bounds.size.width;
        height = self.bounds.size.height / _aspectRatio;
        originX = self.bounds.origin.x;
        originY = (self.bounds.size.height - height) / 2.0;
        
    } else {
        height = self.bounds.size.height;
        width = height * _aspectRatio;
        originY = self.bounds.origin.y;
        originX = (self.bounds.size.width - width) / 2.0;
    }
    self.imageView.frame = CGRectMake(originX, originY, width, height);
    _imageViewFrame = self.imageView.frame;
    [self.imageView setImage:thumbnailImage];
    
    [_borderView receiveImageViewRect:_imageViewFrame];
    _borderView.frame = [self calculatorCurrentBorderViewRect];
}

#pragma docEventListener methods

-(void)onDocModified:(FSPDFDoc *)document {
    FSPDFPage* currentPage = [_pdfViewCtrl.currentDoc getPage:_pageIndex];
    [self drawSubView:currentPage];
}

#pragma pageEventListener methods

- (void)onPageChanged:(int)oldIndex currentIndex:(int)currentIndex
{
    _pageIndex = currentIndex;
    [self correctPageIndexInCoverMode];
    
    FSPDFPage* currentPage = [_pdfViewCtrl.currentDoc getPage:_pageIndex];
    [self drawSubView:currentPage];
}

- (void)onLayoutFinished
{
    _borderView.frame = [self calculatorCurrentBorderViewRect];
}

#pragma rotate

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    _tempSelfFrame = self.frame;
    self.frame = CGRectZero;
    _borderView.frame = CGRectZero;
    _imageView.frame = CGRectZero;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    _borderView.frame = [self calculatorCurrentBorderViewRect];
    
    float width = _pdfViewCtrl.frame.size.width;
    float height = _pdfViewCtrl.frame.size.height;
    float bottomMargin = 49.0;
    
    float subviewOriginY = height * 3.0 / 5.0;
    float subviewHeight = height * 2.0 / 5.0 - bottomMargin;
    float subviewWidth = subviewHeight;
    float subviewOriginX = width / 2.0 - subviewWidth / 2.0;
        
    self.frame = CGRectMake(subviewOriginX, subviewOriginY, subviewWidth, subviewHeight);
    
    FSPDFPage* currentPage = [_pdfViewCtrl.currentDoc getPage:_pageIndex];
    [self drawSubView:currentPage];
}

#pragma annotEventListener methods

-(void)onAnnotDeleted:(FSPDFPage *)page annot:(FSAnnot *)annot
{
    [self drawSubView:page];
}

-(void)onAnnotAdded:(FSPDFPage *)page annot:(FSAnnot *)annot
{
    [self drawSubView:page];
}

-(void)onAnnotModified:(FSPDFPage *)page annot:(FSAnnot *)annot
{
    [self drawSubView:page];
}

#pragma scrollViewEventListener methods

-(void)onScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        return;
    }
    if ([self correctPageIndexInFacingMode]) {
        FSPDFPage* currentPage = [_pdfViewCtrl.currentDoc getPage:_pageIndex];
        [self drawSubView:currentPage];
    } else {
        _borderView.frame = [self calculatorCurrentBorderViewRect];
    }
}

-(void)onScrollViewDidScroll:(UIScrollView *)scrollView
{
    
}

-(void)onScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self correctPageIndexInFacingMode]) {
        FSPDFPage* currentPage = [_pdfViewCtrl.currentDoc getPage:_pageIndex];
        [self drawSubView:currentPage];
    } else {
        _borderView.frame = [self calculatorCurrentBorderViewRect];
    }
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView
{
    if ([self correctPageIndexInFacingMode]) {
        FSPDFPage* currentPage = [_pdfViewCtrl.currentDoc getPage:_pageIndex];
        [self drawSubView:currentPage];
    } else {
        _borderView.frame = [self calculatorCurrentBorderViewRect];
    }
}

- (CGRect)calculatorCurrentBorderViewRect
{
    float fullPageWidth = [[_pdfViewCtrl.currentDoc getPage:_pageIndex] getWidth];
    float fullPageHeight = [[_pdfViewCtrl.currentDoc getPage:_pageIndex] getHeight];
    
    CGRect rect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:_pdfViewCtrl.bounds pageIndex:_pageIndex];
    if (rect.origin.x < 0) {
        rect.size.width = rect.size.width + rect.origin.x;
        rect.origin.x = 0;
    }
    if (rect.origin.y < 0) {
        rect.size.height = rect.size.height + rect.origin.y;
        rect.origin.y = 0;
    }
    
    FSRectF* pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:rect pageIndex:_pageIndex];
    
    //rate
    CGFloat xRate = pdfRect.left / fullPageWidth;
    CGFloat widthRate = (pdfRect.right - pdfRect.left) / fullPageWidth;
    CGFloat yRate = 1.0 - pdfRect.top / fullPageHeight;
    CGFloat heightRate = (pdfRect.top - pdfRect.bottom) / fullPageHeight;
    
    //adjust rect rate for page rotation
    FSRotation rotation = [[_pdfViewCtrl.currentDoc getPage:_pageIndex] getRotation];
    if (rotation == e_rotation90) {
        xRate = pdfRect.bottom / fullPageWidth;
        widthRate = (pdfRect.top - pdfRect.bottom) / fullPageWidth;
        yRate = pdfRect.left / fullPageHeight;
        heightRate = (pdfRect.right - pdfRect.left) / fullPageHeight;
    } else if (rotation == e_rotation270) {
        xRate = 1.0 - pdfRect.top / fullPageWidth;
        widthRate = (pdfRect.top - pdfRect.bottom) / fullPageWidth;
        yRate = 1.0 - pdfRect.right / fullPageHeight;
        heightRate = (pdfRect.right - pdfRect.left) / fullPageHeight;
    } else if (rotation == e_rotation180) {
        xRate = 1.0 - pdfRect.right / fullPageWidth;
        widthRate = (pdfRect.right - pdfRect.left) / fullPageWidth;
        yRate = pdfRect.bottom / fullPageHeight;
        heightRate = (pdfRect.top - pdfRect.bottom) / fullPageHeight;
    }
    
    //new frame in imageView
    _imageViewFrame = self.imageView.frame;
    CGFloat newWidth = widthRate * _imageViewFrame.size.width;
    CGFloat newX = _imageViewFrame.origin.x + _imageViewFrame.size.width * xRate;
    CGFloat newHeight = heightRate * _imageViewFrame.size.height;
    CGFloat newY = _imageViewFrame.origin.y + _imageViewFrame.size.height * yRate;
    
    if (newY + newHeight > _imageViewFrame.origin.y + _imageViewFrame.size.height) {
        newHeight = _imageViewFrame.origin.y + _imageViewFrame.size.height - newY;
    }
    if (newX + newWidth > _imageViewFrame.origin.x + _imageViewFrame.size.width) {
        newWidth = _imageViewFrame.origin.x + _imageViewFrame.size.width - newX;
    }
    
    CGRect borderViewRect = CGRectMake(newX, newY, newWidth, newHeight);
    if ( !CGRectIntersectsRect(borderViewRect, _imageViewFrame) )
    {
        return CGRectZero;
    }
    
    return borderViewRect;
}

- (void)handlePan:(UIPanGestureRecognizer*)recognizer
{
    CGPoint translation = [recognizer translationInView:self];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    if ( !CGRectContainsPoint(_pdfViewCtrl.frame, recognizer.view.center) ) {
        recognizer.view.center = CGPointMake(recognizer.view.center.x - translation.x,
                                             recognizer.view.center.y - translation.y);
    }
    
    [recognizer setTranslation:CGPointZero inView:self];
}

@end
