/**
 * Copyright (C) 2003-2017, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "CropViewController.h"
#import "MBProgressHUD.h"
#import "Utility.h"
#import "SettingBar.h"

@class SettingBar;

@interface CropPDFView : UIView
@property (nonatomic, strong) FSPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, assign) int pageIndex;
- (id)initWithFrame:(CGRect)frame;
@end

@interface CropView : UIView

@property (nonatomic, assign) CGRect originalRect;
@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) CGRect currentRect;
@property (nonatomic, assign) CGRect currentRealRect;
@property (nonatomic, assign) int currentEditPointIndex;
@property (nonatomic, strong) NSMutableArray *arrayPageCropRects;
@property (nonatomic, strong) CropPDFView *pdfView;

- (instancetype)initWithCropPDFView:(CropPDFView*)pdfView;
- (void)resetDefaultCrop;
- (void)resetNoCrop;

@end

@interface CropViewController ()
{
    FSPDFViewCtrl* __weak _pdfViewCtrl;
    UIExtensionsManager* __weak _extensionsManager;
    FSPDFReader* __weak _pdfReader;
}

@property (nonatomic, strong) CropPDFView* pdfView;
@property (nonatomic, strong) CropView *cropView;
@property (assign, nonatomic) BOOL isApply2All;
@end

@implementation CropViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
        self.isApply2All = NO;
	}
	return self;
}

- (void)dealloc
{
	self.pdfView = nil;
	self.cropView = nil;
	self.cropViewClosedHandler = nil;
}

-(void)setExtension:(UIExtensionsManager*)extensionsManager pdfReader:(FSPDFReader*)pdfReader
{
    _extensionsManager = extensionsManager;
    _pdfViewCtrl = extensionsManager.pdfViewCtrl;
    _pdfReader = pdfReader;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view.
    self.extendedLayoutIncludesOpaqueBars = YES; //replace "self.wantsFullScreenLayout = YES;" by deprecation
    self.topToolbar.clipsToBounds = YES;
	self.viewStatusBar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
	self.topToolbar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
	self.bottomToolbar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
	
	[self.buttonCrop setTitle:NSLocalizedStringFromTable(@"kCropDone", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
	[self.buttonDetect setTitle:NSLocalizedStringFromTable(@"kCropDetect", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
	[self.buttonFull setTitle:NSLocalizedStringFromTable(@"kCropFull", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
	[self.buttonNoCrop setTitle:NSLocalizedStringFromTable(@"kCropNo", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
	[self.buttonSmartCrop setTitle:NSLocalizedStringFromTable(@"kCropSmart", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
	[self.buttonPageIndex setTitle:[NSString stringWithFormat:@"%d",self.pdfView.pageIndex+1] forState:UIControlStateNormal];
	[self.buttonApply2All setTitle:NSLocalizedStringFromTable(@"kApply2All", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
    if (self.pdfView.pageIndex & 1) {
        [self.buttonApply2OddEven setTitle:NSLocalizedStringFromTable(@"kApply2Even", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
    }
    else {
        [self.buttonApply2OddEven setTitle:NSLocalizedStringFromTable(@"kApply2Odd", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
    }
    
	[self.buttonCrop setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateNormal];
	[self.buttonDetect setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateNormal];
	[self.buttonFull setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateNormal];
	[self.buttonNoCrop setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateNormal];
	[self.buttonSmartCrop setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateNormal];
	[self.buttonPageIndex setTitleColor:[UIColor colorWithRGBHex:0xff3f3f3f] forState:UIControlStateNormal];
    [self.buttonApply2All setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateNormal];
    [self.buttonApply2OddEven setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateNormal];
    
    [self.buttonPrevPage setImage:[UIImage imageNamed:@"formfill_pre_normal.png"] forState:UIControlStateNormal];
    [self.buttonPrevPage setImage:[UIImage imageNamed:@"formfill_pre_pressed.png"] forState:UIControlStateDisabled];
    [self.buttonNextPage setImage:[UIImage imageNamed:@"formfill_next_normal.png"] forState:UIControlStateNormal];
    [self.buttonNextPage setImage:[UIImage imageNamed:@"formfill_next_pressed.png"] forState:UIControlStateDisabled];
    
	self.buttonPageIndex.enabled = NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.cropView.arrayPageCropRects removeAllObjects];
    [super viewWillDisappear:animated];
}

- (CGRect)getPageContentCGRect:(FSPDFPage*)page isWholePage:(BOOL)isWholePage
{
    CGRect rect = CGRectZero;
    
    FSRectF* rectBBox = nil;
    if (isWholePage) {
        rectBBox = [[FSRectF alloc] init];
        rectBBox.left = 0;
        rectBBox.bottom = 0;
        enum FS_ROTATION rotation = [page getRotation];
        if (rotation == e_rotation0 || rotation == e_rotation180) {
            rectBBox.right = [page getWidth];
            rectBBox.top = [page getHeight];
        }
        else
        {
            rectBBox.right = [page getHeight];
            rectBBox.top = [page getWidth];
        }
    }
    else{
        if ([page isParsed] == NO) {
            BOOL parseSuccess = YES;
            enum FS_PROGRESSSTATE state = [page startParse:e_parsePageNormal pause:nil isReparse:NO];
            if (e_progressError == state)
            {
                parseSuccess = NO;
            }
            else if (e_progressToBeContinued == state)
            {
                while (e_progressToBeContinued == state)
                {
                    state = [page continueParse];
                }
                if (e_progressFinished != state)
                {
                    parseSuccess = NO;
                }
            }
            if (!parseSuccess)
            {
                return rect;
            }
        }
        
        rectBBox = [page calcContentBBox:e_calcContentsBox];
    }
    
    
    if (rectBBox.left != 0 || rectBBox.right != 0 || rectBBox.top != 0 || rectBBox.bottom != 0)
    {
        FSRectF* newRectBBox = [[FSRectF alloc] init];
        newRectBBox.left = rectBBox.left;
        newRectBBox.right = rectBBox.right;
        newRectBBox.top = rectBBox.top;
        newRectBBox.bottom = rectBBox.bottom;
    
        CGRect newRect;
        enum FS_ROTATION rotation = [page getRotation];
        switch (rotation) {
            case e_rotation0:
                newRect = CGRectMake(MIN(newRectBBox.left, newRectBBox.right),
                                            [page getHeight] - MAX(newRectBBox.top, newRectBBox.bottom),
                                            ABS(newRectBBox.right - newRectBBox.left),
                                            ABS(newRectBBox.top - newRectBBox.bottom));
                break;
            case e_rotation90:
                newRect = CGRectMake( newRectBBox.bottom,
                                      newRectBBox.left,
                                     ABS(newRectBBox.top - newRectBBox.bottom),
                                     ABS(newRectBBox.right - newRectBBox.left));
                break;
            case e_rotation180:
                newRect = CGRectMake( [page getWidth] - newRectBBox.right,
                                     newRectBBox.bottom,
                                     ABS(newRectBBox.right - newRectBBox.left),
                                     ABS(newRectBBox.top - newRectBBox.bottom));
                break;
            case e_rotation270:
                newRect = CGRectMake(
                                     [page getWidth] -newRectBBox.top,
                                     [page getHeight]-newRectBBox.right,
                                     ABS(newRectBBox.top - newRectBBox.bottom),
                                     ABS(newRectBBox.right - newRectBBox.left));
                break;
            default:
                break;
        }
        
        rect = newRect;
    }
    
    return rect;
}

- (FSRectF*)convertCGRect2PDFRect:(CGRect)cgrect
{
    FSRectF* pdfrect = [[FSRectF alloc] init];
    [pdfrect set:0 bottom:0 right:0 top:0];
    CGRect temp = cgrect;
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:self.pdfView.pageIndex];
    enum FS_ROTATION rotation = [page getRotation];
    if (rotation == e_rotation90 || rotation == e_rotation270)
    {
        //to do
    }
    
    pdfrect.left = temp.origin.x;
    pdfrect.right = temp.origin.x + temp.size.width;
    pdfrect.top = [page getHeight] - temp.origin.y;
    pdfrect.bottom = pdfrect.top - temp.size.height;
    return pdfrect;
}

- (void)calcCurrentPreviewedCropRects
{
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:self.pdfView.pageIndex];
    float pageWidth = [page getWidth];
    float pageHeight = [page getHeight];
    float bgWidth = self.viewBackground.bounds.size.width;
    float bgHeight = self.viewBackground.bounds.size.height;
    
    float scale = bgWidth / pageWidth;
    if (pageWidth / pageHeight - bgWidth / bgHeight < 0.000001) {
        scale = bgHeight / pageHeight;
    }
    CGRect frame = CGRectMake((bgWidth - pageWidth * scale) / 2, (bgHeight - pageHeight * scale) / 2, pageWidth * scale, pageHeight * scale);
    self.pdfView.frame = frame;
    self.cropView.frame = self.pdfView.bounds;
    
    self.cropView.originalSize = CGSizeMake(pageWidth, pageHeight);
    self.cropView.originalRect = [self getPageContentCGRect:[_pdfViewCtrl.currentDoc getPage:self.pdfView.pageIndex] isWholePage:NO];
    int margin = 15;
    self.cropView.originalRect = [Utility convertCGRectWithMargin:self.cropView.originalRect size:self.cropView.originalSize margin:margin];
    self.cropView.currentRect = [self.cropView.arrayPageCropRects[self.pdfView.pageIndex] CGRectValue];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
	if (!self.pdfView) {
        self.pdfView = [[CropPDFView alloc] init];
        self.pdfView.pdfViewCtrl = _pdfViewCtrl;
        self.pdfView.pageIndex = [_pdfViewCtrl getCurrentPage];
        
        self.cropView = [[CropView alloc] initWithCropPDFView:self.pdfView];
		self.cropView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.cropView.opaque = NO;
		self.cropView.userInteractionEnabled = YES;
        
        for (int i = 0; i < [_pdfViewCtrl getPageCount]; i++) {
            FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:i];
            float pageWidth = [page getWidth];
            float pageHeight = [page getHeight];
            CGSize pageSize = CGSizeMake(pageWidth, pageHeight);
            CGRect pageCropRect = [self getPageContentCGRect:[_pdfViewCtrl.currentDoc getPage:i] isWholePage:YES];
            int margin = 15;
            pageCropRect = [Utility convertCGRectWithMargin:pageCropRect size:pageSize margin:margin];
            [self.cropView.arrayPageCropRects addObject:[NSValue valueWithCGRect:pageCropRect]];
        }
        
        [self calcCurrentPreviewedCropRects];
        [self setPreviousAndNextBtnEnable];
        
		[self.pdfView addSubview:self.cropView];
		[self.viewBackground addSubview:self.pdfView];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleDefault;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden
{
	return NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:self.pdfView.pageIndex];
    float pageWidth = [page getWidth];
    float pageHeight = [page getHeight];
    float bgWidth = self.viewBackground.bounds.size.width;
    float bgHeight = self.viewBackground.bounds.size.height;
    
    float scale = bgWidth / pageWidth;
    if (pageWidth / pageHeight - bgWidth / bgHeight < 0.000001) {
        scale = bgHeight / pageHeight;
    }
    CGRect frame = CGRectMake((bgWidth - pageWidth * scale) / 2, (bgHeight - pageHeight * scale) / 2, pageWidth * scale, pageHeight * scale);
    self.pdfView.frame = frame;
	self.cropView.frame = self.pdfView.bounds;
}

- (void)viewDidUnload {
	[self setViewBackground:nil];
	[self setButtonNoCrop:nil];
	[self setButtonSmartCrop:nil];
	[self setButtonCrop:nil];
	[self setButtonDetect:nil];
	[self setButtonFull:nil];
    [self setButtonApply2All:nil];
    [self setButtonApply2OddEven:nil];
    [self setButtonPrevPage:nil];
    [self setButtonNextPage:nil];
	[super viewDidUnload];
}

- (IBAction)autoCropClicked:(id)sender
{
    [self.cropView resetDefaultCrop];
}

- (IBAction)fullCropClicked:(id)sender
{
	[self.cropView resetNoCrop];
}

- (IBAction)apply2allClicked:(id)sender {
    self.isApply2All = YES;
    for (int i = 0; i < self.cropView.arrayPageCropRects.count; i++) {
        self.cropView.arrayPageCropRects[i] = [NSValue valueWithCGRect:self.cropView.currentRect];
    }
}

- (IBAction)apply2oddevenClicked:(id)sender {
    for (int i = self.pdfView.pageIndex & 1; i < self.cropView.arrayPageCropRects.count; i+= 2) {
        self.cropView.arrayPageCropRects[i] = [NSValue valueWithCGRect:self.cropView.currentRect];
    }
}

-(void)setPreviousAndNextBtnEnable
{
    if (self.pdfView.pageIndex <= 0)
    {
        self.buttonPrevPage.enabled = NO;
    }else
    {
        self.buttonPrevPage.enabled = YES;
    }
    
    if (self.pdfView.pageIndex >= [_pdfViewCtrl getPageCount] - 1)
    {
        self.buttonNextPage.enabled = NO;
    }else
    {
        self.buttonNextPage.enabled = YES;
    }
    
    [self.buttonPageIndex setTitle:[NSString stringWithFormat:@"%d",self.pdfView.pageIndex+1] forState:UIControlStateNormal];
    if (self.pdfView.pageIndex & 1) {
        [self.buttonApply2OddEven setTitle:NSLocalizedStringFromTable(@"kApply2Even", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
    }
    else {
        [self.buttonApply2OddEven setTitle:NSLocalizedStringFromTable(@"kApply2Odd", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
    }
}

- (IBAction)prevPageClicked:(id)sender {
    if (self.pdfView.pageIndex > 0) {
        [_pdfViewCtrl gotoPage:--self.pdfView.pageIndex animated:NO];
        [self setPreviousAndNextBtnEnable];
        [self calcCurrentPreviewedCropRects];
        [self.pdfView setNeedsDisplay];
        [self.cropView setNeedsDisplay];
    }
}

- (IBAction)nextPageClicked:(id)sender {
    if (self.pdfView.pageIndex < [_pdfViewCtrl getPageCount] - 1) {
        [_pdfViewCtrl gotoPage:++self.pdfView.pageIndex animated:NO];
        [self setPreviousAndNextBtnEnable];
        [self calcCurrentPreviewedCropRects];
        [self.pdfView setNeedsDisplay];
        [self.cropView setNeedsDisplay];
    }
}

- (IBAction)smartCropClicked:(id)sender
{
	MBProgressHUD *progressView = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	progressView.labelText = NSLocalizedStringFromTable(@"kCropSmartCalculating", @"FoxitLocalizable", nil);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

		
		dispatch_async(dispatch_get_main_queue(), ^{
			[MBProgressHUD hideHUDForView:self.view animated:YES];
			
            [_pdfViewCtrl setCropMode:PDF_CROP_MODE_CONTENTSBOX];
            [self close];
		});
	});
}

- (IBAction)noCropClicked:(id)sender
{
    [_pdfReader.settingBarController.settingBar setItemState:NO value:0 itemType:CROPPAGE];
    [_pdfViewCtrl setCropMode:PDF_CROP_MODE_NONE];
    [self close];
}

- (IBAction)doneClicked:(id)sender
{
    
    int pageCount = [_pdfViewCtrl getPageCount];
    for (int i = 0; i < pageCount; i++) {
        FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:i];
        float pageWidth = [page getWidth];
        float pageHeight = [page getHeight];
        CGSize pageSize = CGSizeMake(pageWidth, pageHeight);
        UIEdgeInsets insets = [Utility convertCGRect2Insets:[self.cropView.arrayPageCropRects[i] CGRectValue] size:pageSize];
        FSRectF* pdfrect = [[FSRectF alloc] init];
        pdfrect.top = insets.top;
        pdfrect.left = insets.left;
        pdfrect.bottom = pageSize.height - insets.bottom;
        pdfrect.right = pageSize.width - insets.right;
        [_pdfViewCtrl setCropPageRect:i pdfRect:pdfrect];
    }
    
    [_pdfViewCtrl setCropMode:PDF_CROP_MODE_CUSTOMIZED];
    [self close];

}

- (void)close
{
    self.isApply2All = NO;
	if (self.cropViewClosedHandler) {
		self.cropViewClosedHandler();
	}
	[self dismissViewControllerAnimated:YES completion:^{
	}];
}

- (void)setCropMode:(NSString *)path cropMode:(int)cropMode cropInsets:(NSString *)cropInsets
{
}

@end

@implementation CropPDFView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.pageIndex = 0;
    }
    return self;
    
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
}

// Draw into the layer
-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
    CGRect clipRect = CGContextGetClipBoundingBox(context);
    if (clipRect.size.width == 0 || clipRect.size.height == 0) {
        return;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGAffineTransform trans = CGContextGetCTM(context);
    trans.a /= scale;
    trans.d /= scale;
    
    int _width = self.bounds.size.width;
    int _height = self.bounds.size.height;
        
    UIImage *img = nil;
    img = [self drawPage:clipRect.size.width * trans.a dibHeight:clipRect.size.height * -trans.d pdfX:-clipRect.origin.x * trans.a pdfY:-clipRect.origin.y * -trans.d pdfWidth:_width * trans.a pdfHeight:_height * -trans.d];
    
    if (!img) {
        if (![NSThread isMainThread]) {
            CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
            CGContextFillRect(context,clipRect);
        }
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, 2 * clipRect.origin.y + clipRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, clipRect, img.CGImage);
    CGContextRestoreGState(context);

}

- (UIImage*)drawPage:(int)dibWidth dibHeight:(int)dibHeight pdfX:(int)pdfX pdfY:(int)pdfY pdfWidth:(int)pdfWidth pdfHeight:(int)pdfHeight
{
    UIImage *img = nil;
    
    CGFloat scale = [UIScreen mainScreen].scale;
#ifdef CONTEXT_DRAW
    scale = 1;
#endif
    int newDibWidth = dibWidth * scale;
    int newDibHeight = dibHeight * scale;
    int newPdfX = pdfX * scale;
    int newPdfY = pdfY * scale;
    int newPdfWidth = pdfWidth * scale;
    int newPdfHeight = pdfHeight * scale;
    

    @synchronized(self)
    {
        FSPDFPage *page = [self.pdfViewCtrl.currentDoc getPage:self.pageIndex];
        if (!page)
        {
            return img;
        }
        
#ifdef CONTEXT_DRAW
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newDibWidth, newDibHeight), YES, [[UIScreen mainScreen] scale]);
        CGContextRef context = UIGraphicsGetCurrentContext();
#else
        //create a 24bit bitmap
        int size = newDibWidth*newDibHeight*3;
        void *pBuf = malloc(size);
        FSBitmap* fsbitmap = [FSBitmap create:newDibWidth height:newDibHeight format:e_dibRgb buffer:(unsigned char*)pBuf pitch:newDibWidth*3];
#endif
        
        //render page, must have
#ifdef CONTEXT_DRAW
        FSRenderer* fsrenderer = [FSRenderer createFromContext:context deviceType:e_deviceTypeDisplay];
#else
        FSRenderer* fsrenderer = [FSRenderer create:fsbitmap rgbOrder:YES];
#endif
        [fsrenderer setTransformAnnotIcon:NO];
        FSMatrix* fsmatrix = [page getDisplayMatrix:newPdfX yPos:newPdfY xSize:newPdfWidth ySize:newPdfHeight rotate:e_rotation0];
        if (self.pdfViewCtrl.isNightMode)
        {
#ifndef CONTEXT_DRAW
            //set background color of bitmap to black
            memset(pBuf, 0x00, size);
#endif
            [fsrenderer setColorMode:e_colorModeMapping];
            [fsrenderer setMappingModeColors:UX_BG_COLOR_NIGHT_PAGEVIEW foreColor:UX_TEXT_COLOR_NIGHT];
        }
        else
        {
#ifdef CONTEXT_DRAW
            CGContextSetRGBFillColor(context, 1, 1, 1, 1);
            CGContextFillRect(context, CGRectMake(0, 0, newDibWidth, newDibHeight));
#else
            //set background color of bitmap to white
            memset(pBuf, 0xff, size);
#endif
        }
        
        void(^releaseRender)(BOOL freepBuf) = ^(BOOL freepBuf)
        {
#ifdef CONTEXT_DRAW
            UIGraphicsEndImageContext();
#else
            if (freepBuf)
            {
                free(pBuf);
            }
#endif
        };
        int contextFlag = e_renderAnnot | e_renderPage;
        [fsrenderer setRenderContent:contextFlag];
        enum FS_PROGRESSSTATE state = [fsrenderer startRender:page matrix:fsmatrix pause:nil];
        if (e_progressError == state)
        {
            releaseRender(YES);
            return img;
        }
        else if (e_progressToBeContinued == state)
        {
            while (e_progressToBeContinued == state)
            {
                state = [fsrenderer continueRender];
            }
            if (e_progressFinished != state)
            {
                releaseRender(YES);
                return img;
            }
        }
        
#ifdef CONTEXT_DRAW
        img = UIGraphicsGetImageFromCurrentImageContext();
#else
        img = [Utility rgbDib2img:pBuf size:size dibWidth:newDibWidth dibHeight:newDibHeight withAlpha:NO freeWhenDone:YES]; //todel
#endif
        releaseRender(img == nil);
    }
    return img;
}
@end

@implementation CropView

- (instancetype)initWithCropPDFView:(CropPDFView*)pdfView;
{
	self = [super init];
	if (self) {
		// Initialization code
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
		[self addGestureRecognizer:panGesture];
		
        self.pdfView = pdfView;
		_currentRealRect = CGRectZero;
        self.arrayPageCropRects = [NSMutableArray array];
	}
	return self;
	
}

- (void)dealloc
{
}

- (void)setCurrentRect:(CGRect)currentRect
{
    _currentRect = currentRect;
    self.arrayPageCropRects[self.pdfView.pageIndex] = [NSValue valueWithCGRect:_currentRect];
    
}

- (void)resetDefaultCrop
{
	self.currentRect = self.originalRect;
	[self setNeedsDisplay];
}

- (void)resetNoCrop
{
	self.currentRect = CGRectMake(0, 0, self.originalSize.width, self.originalSize.height);
	[self setNeedsDisplay];
}

- (NSArray*)getMovePointInRect:(CGRect)rect
{
	if (rect.size.width == 0 || rect.size.height == 0) {
		return nil;
	}
	float iconRadius = 7.5f;
	NSMutableArray *array = [NSMutableArray array];
	[array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x - iconRadius, rect.origin.y - iconRadius, iconRadius * 2, iconRadius * 2)]];
	[array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x + rect.size.width - iconRadius, rect.origin.y - iconRadius, iconRadius * 2, iconRadius * 2)]];
	[array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x - iconRadius, rect.origin.y + rect.size.height - iconRadius, iconRadius * 2, iconRadius * 2)]];
	[array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x + rect.size.width - iconRadius, rect.origin.y + rect.size.height - iconRadius, iconRadius * 2, iconRadius * 2)]];
	return array;
}

- (CGRect)getCurrentRealRect
{
	float scale = self.bounds.size.width / self.originalSize.width;
	CGRect croppedRect = CGRectMake(self.currentRect.origin.x * scale, self.currentRect.origin.y * scale, self.currentRect.size.width * scale, self.currentRect.size.height * scale);
	return croppedRect;
}

- (CGRect)getCurrentRect:(CGRect)rect
{
	float scale = self.originalSize.width / self.bounds.size.width;
	CGRect pageRect = CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);
	return pageRect;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
	CGPoint point = [recognizer locationInView:self];
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		_currentEditPointIndex = -1;
		_currentRealRect = [self getCurrentRealRect];
		NSArray *movePointArray = [self getMovePointInRect:_currentRealRect];
		[movePointArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			 CGRect dotRect = [obj CGRectValue];
			 dotRect = CGRectInset(dotRect, -20, -20);
			 if (CGRectContainsPoint(dotRect, point)) {
				 _currentEditPointIndex = idx;
				 *stop = YES;
			 }
		 }];
		if (_currentEditPointIndex == -1) {
			if (CGRectContainsPoint(_currentRealRect, point)) {
				_currentEditPointIndex = 4;
			}
		}
	} else if (recognizer.state == UIGestureRecognizerStateChanged) {
		if (_currentEditPointIndex == -1) {
			return;
		}
		
		CGPoint translationPoint = [recognizer translationInView:self];
		[recognizer setTranslation:CGPointZero inView:self];
		float tw = translationPoint.x;
		float th = translationPoint.y;
		CGRect rect = _currentRealRect;
		
		if (_currentEditPointIndex == 0) {
			rect.origin.x += tw;
			rect.origin.y += th;
			rect.size.width -= tw;
			rect.size.height -= th;
		} else if (_currentEditPointIndex == 1) {
			rect.size.width += tw;
			rect.origin.y += th;
			rect.size.height -= th;
		} else if (_currentEditPointIndex == 2) {
			rect.origin.x += tw;
			rect.size.width -= tw;
			rect.size.height += th;
		} else if (_currentEditPointIndex == 3) {
			rect.size.width += tw;
			rect.size.height += th;
		} else if (_currentEditPointIndex == 4) {
			rect.origin.x += tw;
			rect.origin.y += th;
		}
		
		_currentRealRect = rect;
		[self setNeedsDisplay];
	} else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
		_currentEditPointIndex = -1;
		self.currentRect = [self getCurrentRect:CGRectStandardize(_currentRealRect)];
		_currentRealRect = CGRectZero;
		[self setNeedsDisplay];
	}
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	// Drawing code
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context, 0, 0, 0, .2);
	CGContextFillRect(context, rect);
	
	CGRect croppedRect = _currentRealRect;
	if (CGRectEqualToRect(croppedRect, CGRectZero)) {
		croppedRect = [self getCurrentRealRect];
	}
	
	CGContextClearRect(context, croppedRect);
	CGContextSetLineWidth(context, 1.0);
	CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:0x179cd8] CGColor]);
	CGContextStrokeRect(context, croppedRect);
	
	UIImage *dragDot = [UIImage imageNamed:@"annotation_drag"];
	NSArray *movePointArray = [self getMovePointInRect:croppedRect];
	[movePointArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		CGRect dotRect = [obj CGRectValue];
		[dragDot drawAtPoint:dotRect.origin];
    }];
}

@end
