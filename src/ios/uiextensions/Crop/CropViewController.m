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

#import "CropViewController.h"
#import "MBProgressHUD.h"
#import "SettingBar+private.h"
#import "SettingBar.h"
#import "Utility.h"

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
@property (nonatomic, strong) CropPDFView *pdfView;

- (instancetype)initWithCropPDFView:(CropPDFView *)pdfView;
- (void)resetDefaultCrop;
- (void)resetNoCrop;

@end

@interface CropViewController () {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
}

@property (nonatomic, strong) CropPDFView *pdfView;
@property (nonatomic, strong) CropView *cropView;
@property (assign, nonatomic) BOOL isApplyToAllOddPages;
@property (assign, nonatomic) BOOL isApplyToAllEvenPages;
@end

@implementation CropViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.isApplyToAllOddPages = NO;
        self.isApplyToAllEvenPages = NO;
    }
    return self;
}

- (void)dealloc {
    self.pdfView = nil;
    self.cropView = nil;
    self.cropViewClosedHandler = nil;
}

- (void)setExtension:(UIExtensionsManager *)extensionsManager {
    _extensionsManager = extensionsManager;
    _pdfViewCtrl = extensionsManager.pdfViewCtrl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.extendedLayoutIncludesOpaqueBars = YES; //replace "self.wantsFullScreenLayout = YES;" by deprecation
    self.topToolbar.clipsToBounds = YES;
    self.viewStatusBar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    self.topToolbar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    self.bottomToolbar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];

    [self.buttonCrop setTitle:FSLocalizedString(@"kCropDone") forState:UIControlStateNormal];
    [self.buttonDetect setTitle:FSLocalizedString(@"kCropDetect") forState:UIControlStateNormal];
    [self.buttonFull setTitle:FSLocalizedString(@"kCropFull") forState:UIControlStateNormal];
    [self.buttonNoCrop setTitle:FSLocalizedString(@"kCropNo") forState:UIControlStateNormal];
    [self.buttonSmartCrop setTitle:FSLocalizedString(@"kCropSmart") forState:UIControlStateNormal];
    [self.buttonPageIndex setTitle:[NSString stringWithFormat:@"%d", self.pdfView.pageIndex + 1] forState:UIControlStateNormal];
    [self.buttonApply2All setTitle:FSLocalizedString(@"kApply2All") forState:UIControlStateNormal];
    if (self.pdfView.pageIndex & 1) {
        [self.buttonApply2OddEven setTitle:FSLocalizedString(@"kApply2Even") forState:UIControlStateNormal];
    } else {
        [self.buttonApply2OddEven setTitle:FSLocalizedString(@"kApply2Odd") forState:UIControlStateNormal];
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

- (CGRect)getPageContentCGRect:(FSPDFPage *)page isWholePage:(BOOL)isWholePage {
    CGRect rect = CGRectZero;

    FSRectF *rectBBox = nil;
    if (isWholePage) {
        rectBBox = [[FSRectF alloc] init];
        rectBBox.left = 0;
        rectBBox.bottom = 0;
        FSRotation rotation = [page getRotation];
        if (rotation == e_rotation0 || rotation == e_rotation180) {
            rectBBox.right = [page getWidth];
            rectBBox.top = [page getHeight];
        } else {
            rectBBox.right = [page getHeight];
            rectBBox.top = [page getWidth];
        }
    } else {
        if ([page isParsed] == NO) {
            BOOL parseSuccess = [Utility parsePage:page];
            if (!parseSuccess) {
                return rect;
            }
        }

        rectBBox = [page calcContentBBox:e_calcContentsBox];
    }

    if (rectBBox.left != 0 || rectBBox.right != 0 || rectBBox.top != 0 || rectBBox.bottom != 0) {
        FSRectF *newRectBBox = [[FSRectF alloc] init];
        newRectBBox.left = rectBBox.left;
        newRectBBox.right = rectBBox.right;
        newRectBBox.top = rectBBox.top;
        newRectBBox.bottom = rectBBox.bottom;

        CGRect newRect = CGRectZero;
        FSRotation rotation = [page getRotation];
        switch (rotation) {
        case e_rotation0:
            newRect = CGRectMake(MIN(newRectBBox.left, newRectBBox.right),
                                 [page getHeight] - MAX(newRectBBox.top, newRectBBox.bottom),
                                 ABS(newRectBBox.right - newRectBBox.left),
                                 ABS(newRectBBox.top - newRectBBox.bottom));
            break;
        case e_rotation90:
            newRect = CGRectMake(newRectBBox.bottom,
                                 newRectBBox.left,
                                 ABS(newRectBBox.top - newRectBBox.bottom),
                                 ABS(newRectBBox.right - newRectBBox.left));
            break;
        case e_rotation180:
            newRect = CGRectMake([page getWidth] - newRectBBox.right,
                                 newRectBBox.bottom,
                                 ABS(newRectBBox.right - newRectBBox.left),
                                 ABS(newRectBBox.top - newRectBBox.bottom));
            break;
        case e_rotation270:
            newRect = CGRectMake(
                [page getWidth] - newRectBBox.top,
                [page getHeight] - newRectBBox.right,
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

- (FSRectF *)convertCGRect2PDFRect:(CGRect)cgrect {
    FSRectF *pdfrect = [[FSRectF alloc] init];
    [pdfrect set:0 bottom:0 right:0 top:0];
    CGRect temp = cgrect;
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:self.pdfView.pageIndex];
    FSRotation rotation = [page getRotation];
    if (rotation == e_rotation90 || rotation == e_rotation270) {
        //to do
    }

    pdfrect.left = temp.origin.x;
    pdfrect.right = temp.origin.x + temp.size.width;
    pdfrect.top = [page getHeight] - temp.origin.y;
    pdfrect.bottom = pdfrect.top - temp.size.height;
    return pdfrect;
}

- (void)calcCurrentPreviewedCropRects {
    FSPDFPage *page = nil;
    @try {
        page = [_pdfViewCtrl.currentDoc getPage:self.pdfView.pageIndex];
    } @catch (NSException *_) {
        self.cropView.currentRect = CGRectMake(0, 0, 0, 0);
        return;
    }
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
    self.cropView.currentRect = ({
        CGSize pageSize = CGSizeMake(pageWidth, pageHeight);
        CGRect pageContentRect = [self getPageContentCGRect:page isWholePage:YES];
        int margin = 15;
        CGRect pageCropRect = [Utility convertCGRectWithMargin:pageContentRect size:pageSize margin:margin];
        pageCropRect;
    });
}

- (void)viewWillAppear:(BOOL)animated {
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

        [self calcCurrentPreviewedCropRects];
        [self setPreviousAndNextBtnEnable];

        [self.pdfView addSubview:self.cropView];
        [self.viewBackground addSubview:self.pdfView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:self.pdfView.pageIndex];
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

- (IBAction)autoCropClicked:(id)sender {
    [self.cropView resetDefaultCrop];
}

- (IBAction)fullCropClicked:(id)sender {
    [self.cropView resetNoCrop];
}

- (IBAction)apply2allClicked:(id)sender {
    self.isApplyToAllOddPages = YES;
    self.isApplyToAllEvenPages = YES;
}

- (IBAction)apply2oddevenClicked:(id)sender {
    UIButton *button = (UIButton *)sender;
    if ([@"Use on Odd" isEqualToString:button.titleLabel.text]) {
        self.isApplyToAllOddPages = YES;
        self.isApplyToAllEvenPages = NO;
    } else {
        self.isApplyToAllOddPages = NO;
        self.isApplyToAllEvenPages = YES;
    }
}

- (void)setPreviousAndNextBtnEnable {
    if (self.pdfView.pageIndex <= 0) {
        self.buttonPrevPage.enabled = NO;
    } else {
        self.buttonPrevPage.enabled = YES;
    }

    if (self.pdfView.pageIndex >= [_pdfViewCtrl getPageCount] - 1) {
        self.buttonNextPage.enabled = NO;
    } else {
        self.buttonNextPage.enabled = YES;
    }

    [self.buttonPageIndex setTitle:[NSString stringWithFormat:@"%d", self.pdfView.pageIndex + 1] forState:UIControlStateNormal];
    if (self.pdfView.pageIndex & 1) {
        [self.buttonApply2OddEven setTitle:FSLocalizedString(@"kApply2Even") forState:UIControlStateNormal];
    } else {
        [self.buttonApply2OddEven setTitle:FSLocalizedString(@"kApply2Odd") forState:UIControlStateNormal];
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
    self.isApplyToAllOddPages = NO;
    self.isApplyToAllEvenPages = NO;
}

- (IBAction)nextPageClicked:(id)sender {
    if (self.pdfView.pageIndex < [_pdfViewCtrl getPageCount] - 1) {
        [_pdfViewCtrl gotoPage:++self.pdfView.pageIndex animated:NO];
        [self setPreviousAndNextBtnEnable];
        [self calcCurrentPreviewedCropRects];
        [self.pdfView setNeedsDisplay];
        [self.cropView setNeedsDisplay];
    }
    self.isApplyToAllOddPages = NO;
    self.isApplyToAllEvenPages = NO;
}

- (IBAction)smartCropClicked:(id)sender {
    MBProgressHUD *progressView = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressView.labelText = FSLocalizedString(@"kCropSmartCalculating");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];

            [_pdfViewCtrl setCropMode:PDF_CROP_MODE_CONTENTSBOX];
            [self close];
        });
    });
}

- (IBAction)noCropClicked:(id)sender {
    ((UIButton *) [_extensionsManager.settingBar getItemView:CROPPAGE]).selected = NO;
    [_pdfViewCtrl setCropMode:PDF_CROP_MODE_NONE];
    _extensionsManager.settingBar.panAndZoomBtn.enabled = YES;
    [self close];
}

- (IBAction)doneClicked:(id)sender {
    int currentPageIndex = self.cropView.pdfView.pageIndex;
    CGRect cropRect = self.cropView.currentRect;

    void (^setPageCropRect)(int pageIndex) = ^(int pageIndex) {
        FSPDFPage *page = nil;
        @try {
            page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
        } @catch (NSException *e) {
            return;
        }
        float pageWidth = [page getWidth];
        float pageHeight = [page getHeight];
        CGSize pageSize = CGSizeMake(pageWidth, pageHeight);

        UIEdgeInsets insets = [Utility convertCGRect2Insets:cropRect size:pageSize];
        FSRectF *pdfrect = [[FSRectF alloc] init];
        pdfrect.top = insets.top;
        pdfrect.left = insets.left;
        pdfrect.bottom = pageSize.height - insets.bottom;
        pdfrect.right = pageSize.width - insets.right;
        [_pdfViewCtrl setCropPageRect:pageIndex pdfRect:pdfrect];
    };
    setPageCropRect(currentPageIndex);
    int pageCount = [_pdfViewCtrl getPageCount];
    for (int i = 0; i < pageCount; i++) {
        if (i == currentPageIndex) {
            continue;
        }
        if (i % 2 == 1 && self.isApplyToAllEvenPages) {
            setPageCropRect(i);
        } else if (i % 2 == 0 && self.isApplyToAllOddPages) {
            setPageCropRect(i);
        }
    }

    [_pdfViewCtrl setCropMode:PDF_CROP_MODE_CUSTOMIZED];
    [self close];
}

- (void)close {
    self.isApplyToAllOddPages = NO;
    self.isApplyToAllEvenPages = NO;
    if (self.cropViewClosedHandler) {
        self.cropViewClosedHandler();
    }
    [self dismissViewControllerAnimated:YES
                             completion:^{
                             }];
}

- (void)setCropMode:(NSString *)path cropMode:(int)cropMode cropInsets:(NSString *)cropInsets {
}

@end

@implementation CropPDFView

- (id)initWithFrame:(CGRect)frame {
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
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
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
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(context, clipRect);
        return;
    }

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, 2 * clipRect.origin.y + clipRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, clipRect, img.CGImage);
    CGContextRestoreGState(context);
}

- (UIImage *)drawPage:(int)dibWidth dibHeight:(int)dibHeight pdfX:(int)pdfX pdfY:(int)pdfY pdfWidth:(int)pdfWidth pdfHeight:(int)pdfHeight {
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

    UIImage *img = nil;
    @synchronized(self) {
        FSPDFPage *page = nil;
        @try {
            page = [self.pdfViewCtrl.currentDoc getPage:self.pageIndex];
        } @catch (NSException *exception) {
            return nil;
        }
        if (!page) {
            return nil;
        }

#ifdef CONTEXT_DRAW
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newDibWidth, newDibHeight), YES, [[UIScreen mainScreen] scale]);
        CGContextRef context = UIGraphicsGetCurrentContext();
#else
        //create a 24bit bitmap
        int size = newDibWidth * newDibHeight * 3;
        void *pBuf = malloc(size);
        FSBitmap *fsbitmap = [[FSBitmap alloc] initWithWidth:newDibWidth height:newDibHeight format:e_dibRgb buffer:(unsigned char *) pBuf pitch:newDibWidth * 3];
#endif

//render page, must have
#ifdef CONTEXT_DRAW
        FSRenderer *fsrenderer = [FSRenderer createFromContext:context deviceType:e_deviceTypeDisplay];
#else
        FSRenderer *fsrenderer = [[FSRenderer alloc] initWithBitmap:fsbitmap rgbOrder:YES];
#endif
        [fsrenderer setTransformAnnotIcon:NO];
        FSMatrix *fsmatrix = [page getDisplayMatrix:newPdfX yPos:newPdfY xSize:newPdfWidth ySize:newPdfHeight rotate:e_rotation0];
        if (self.pdfViewCtrl.colorMode == e_colorModeMapping) {
#ifndef CONTEXT_DRAW
            //set background color of bitmap to black
            UIColor *backgroundColor = self.pdfViewCtrl.mappingModeBackgroundColor;
            int8_t r = (int8_t)(backgroundColor.red * 255);
            int8_t g = (int8_t)(backgroundColor.green * 255);
            int8_t b = (int8_t)(backgroundColor.blue * 255);
            int8_t(*pixel)[3];
            for (pixel = (typeof(pixel)) pBuf; (char *) pixel < (char *) pBuf + size; pixel++) {
                int8_t *channel = (int8_t *) pixel;
                channel[0] = r;
                channel[1] = g;
                channel[2] = b;
            }
#endif
            [fsrenderer setColorMode:e_colorModeMapping];
            [fsrenderer setMappingModeColors:self.pdfViewCtrl.mappingModeBackgroundColor.argbHex foreColor:self.pdfViewCtrl.mappingModeForegroundColor.argbHex];
        } else {
#ifdef CONTEXT_DRAW
            CGContextSetRGBFillColor(context, 1, 1, 1, 1);
            CGContextFillRect(context, CGRectMake(0, 0, newDibWidth, newDibHeight));
#else
            //set background color of bitmap to white
            memset(pBuf, 0xff, size);
#endif
        }

        void (^releaseRender)(void) = ^(void) {
#ifdef CONTEXT_DRAW
            UIGraphicsEndImageContext();
#endif
        };
        int contextFlag = e_renderAnnot | e_renderPage;
        [fsrenderer setRenderContent:contextFlag];
        FSProgressive *ret = [fsrenderer startRender:page matrix:fsmatrix pause:nil];
        
        if (ret != nil) {
            FSProgressState state = [ret resume];
            if (e_progressError == state) {
                releaseRender();
                return img;
            } else if (e_progressToBeContinued == state) {
                while (e_progressToBeContinued == state) {
                    state = [ret resume];
                }
                if (e_progressFinished != state) {
                    releaseRender();
                    return img;
                }
            }
        }

#ifdef CONTEXT_DRAW
        img = UIGraphicsGetImageFromCurrentImageContext();
#else
        img = [Utility rgbDib2img:pBuf size:size dibWidth:newDibWidth dibHeight:newDibHeight withAlpha:NO freeWhenDone:YES]; 
#endif
        releaseRender();
    }
    return img;
}
@end

@implementation CropView

- (instancetype)initWithCropPDFView:(CropPDFView *)pdfView;
{
    self = [super init];
    if (self) {
        // Initialization code
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];

        self.pdfView = pdfView;
        _currentRealRect = CGRectZero;
    }
    return self;
}

- (void)resetDefaultCrop {
    self.currentRect = self.originalRect;
    [self setNeedsDisplay];
}

- (void)resetNoCrop {
    self.currentRect = CGRectMake(0, 0, self.originalSize.width, self.originalSize.height);
    [self setNeedsDisplay];
}

- (NSArray *)getMovePointInRect:(CGRect)rect {
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

- (CGRect)getCurrentRealRect {
    float scale = self.bounds.size.width / self.originalSize.width;
    CGRect croppedRect = CGRectMake(self.currentRect.origin.x * scale, self.currentRect.origin.y * scale, self.currentRect.size.width * scale, self.currentRect.size.height * scale);
    return croppedRect;
}

- (CGRect)getCurrentRect:(CGRect)rect {
    float scale = self.originalSize.width / self.bounds.size.width;
    CGRect pageRect = CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);
    return pageRect;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        _currentEditPointIndex = -1;
        _currentRealRect = [self getCurrentRealRect];
        NSArray *movePointArray = [self getMovePointInRect:_currentRealRect];
        [movePointArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect dotRect = [obj CGRectValue];
            dotRect = CGRectInset(dotRect, -20, -20);
            if (CGRectContainsPoint(dotRect, point)) {
                _currentEditPointIndex = (int) idx;
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
- (void)drawRect:(CGRect)rect {
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
