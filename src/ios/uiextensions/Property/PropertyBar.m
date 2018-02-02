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

#import "PropertyBar.h"
#import "ColorLayout.h"
#import "FontLayout.h"
#import "LineWidthLayout.h"
#import "OpacityLayout.h"
#import "PropertyMainView.h"

#import "ColorUtility.h"
#import "Const.h"
#import "FSAnnotExtent.h"
#import "UIExtensionsManager+Private.h"
#import "UIExtensionsManager.h"
#import <FoxitRDK/FSPDFViewControl.h>

#define PDFVIEWCTRLWIDTH _pdfViewCtrl.bounds.size.width
#define PDFVIEWCTRLHEIGHT _pdfViewCtrl.bounds.size.height

@interface PropertyBar ()

@property (nonatomic, strong) NSMutableArray *propertyBarListeners;
@property (nonatomic, strong) id<IPropertyValueChangedListener> currentListener;
@property (nonatomic, assign) long currentItems;
@property (nonatomic, strong) NSArray *currentColors;
@property (nonatomic, assign) int currentColor;
@property (nonatomic, strong) PropertyMainView *mainView;
@property (nonatomic, strong) ColorLayout *colorLayout;
@property (nonatomic, strong) OpacityLayout *opacityLayout;
@property (nonatomic, strong) FontLayout *fontLayout;
@property (nonatomic, strong) IconLayout *typeLayout;
@property (nonatomic, strong) RotationLayout *rotationLayout;
@property (nonatomic, strong) UIControl *maskView;
@property (nonatomic, strong) UIPopoverController *popoverCtr;
@property (nonatomic, strong) UIViewController *popViewCtr;
@property (nonatomic, assign) CGRect tempFrame;
@property (nonatomic, strong) DistanceUnitLayout *distanceUnitLayout;
@end

@implementation PropertyBar {
    FSPDFViewCtrl *_pdfViewCtrl;
    UIExtensionsManager *_extensionsManager;
}

- (instancetype)initWithPDFViewController:(FSPDFViewCtrl *)pdfViewCtrl extensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
        _extensionsManager = extensionsManager;
        self.maskView = [[UIControl alloc] initWithFrame:_pdfViewCtrl.bounds];
        self.maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
        self.propertyBarListeners = [NSMutableArray array];
        [_extensionsManager registerRotateChangedListener:self];
    }
    return self;
}

- (void)resetBySupportedItems:(long)items frame:(CGRect)frame {
    self.currentItems = items;
    self.mainView = [[PropertyMainView alloc] init];
    self.mainView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight;
    CGRect mainFrame;
    if (DEVICE_iPHONE) {
        if (!CGRectIsEmpty(frame))
            mainFrame = frame;
        else {
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                mainFrame = CGRectMake(0, _pdfViewCtrl.bounds.size.width, _pdfViewCtrl.bounds.size.height, 500);

            } else {
                mainFrame = CGRectMake(0, _pdfViewCtrl.bounds.size.height, _pdfViewCtrl.bounds.size.width, 500);
            }
        }
    } else {
        mainFrame = CGRectMake(0, 0, 300, 300);
    }

    self.mainView.frame = mainFrame;
    self.mainView.backgroundColor = [UIColor whiteColor];
    if (items & PROPERTY_COLOR) {
        CGRect colorFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.colorLayout = [[ColorLayout alloc] initWithFrame:colorFrame propertyBar:self];
        [self.colorLayout setColors:self.currentColors];
        self.colorLayout.tag = PROPERTY_COLOR;
        [self.mainView addLayoutAtTab:self.colorLayout tab:TAB_FILL];
    }
    if (items & PROPERTY_OPACITY) {
        CGRect opacityFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.opacityLayout = [[OpacityLayout alloc] initWithFrame:opacityFrame];
        self.opacityLayout.tag = PROPERTY_OPACITY;
        [self.mainView addLayoutAtTab:self.opacityLayout tab:TAB_FILL];
    }
    if (items & PROPERTY_ROTATION) {
        CGRect rotationFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.rotationLayout = [[RotationLayout alloc] initWithFrame:rotationFrame];
        self.rotationLayout.tag = PROPERTY_ROTATION;
        [self.mainView addLayoutAtTab:self.rotationLayout tab:TAB_FILL];
    }
    if (items & PROPERTY_LINEWIDTH) {
        self.lineWidthLayout = [[LineWidthLayout alloc] initWithFrame:CGRectMake(0, 0, self.mainView.frame.size.width, 40)];
        self.lineWidthLayout.tag = PROPERTY_LINEWIDTH;
        [self.mainView addLayoutAtTab:self.lineWidthLayout tab:TAB_BORDER];
    }
    if (items & PROPERTY_FONTNAME) {
        self.fontLayout = [[FontLayout alloc] initWithFrame:CGRectMake(0, 0, self.mainView.frame.size.width, 100)];
        self.fontLayout.tag = PROPERTY_FONTNAME;
        [self.mainView addLayoutAtTab:self.fontLayout tab:TAB_FONT];
    }
    if (items & PROPERTY_FONTSIZE) {
    }
    if (items & PROPERTY_ICONTYPE) {
        self.typeLayout = [[IconLayout alloc] initWithFrame:CGRectMake(0, 0, self.mainView.frame.size.width, 100) iconType:PROPERTY_ICONTYPE];
        self.typeLayout.tag = PROPERTY_ICONTYPE;
        [self.mainView addLayoutAtTab:self.typeLayout tab:TAB_TYPE];
    }
    if (items & PROPERTY_ATTACHMENT_ICONTYPE) {
        self.typeLayout = [[IconLayout alloc] initWithFrame:CGRectMake(0, 0, self.mainView.frame.size.width, 100) iconType:PROPERTY_ATTACHMENT_ICONTYPE];
        self.typeLayout.tag = PROPERTY_ATTACHMENT_ICONTYPE;
        [self.mainView addLayoutAtTab:self.typeLayout tab:TAB_TYPE];
    }
    
    if (items & PROPERTY_DISTANCE_UNIT) {
        self.distanceUnitLayout = [[DistanceUnitLayout alloc] initWithFrame:CGRectMake(0, 0, self.mainView.frame.size.width, 100)];
        self.distanceUnitLayout.tag = PROPERTY_DISTANCE_UNIT;
        [self.mainView addLayoutAtTab:self.distanceUnitLayout tab:TAB_DISTANCE_UNIT];
    }
    
    if (self.mainView.segmentItems.count > 0) {
        SegmentView *segmentView = [[SegmentView alloc] initWithFrame:CGRectMake(20, 5, self.mainView.frame.size.width - 40, TABHEIGHT - 10) segmentItems:self.mainView.segmentItems];
        segmentView.delegate = self.mainView;
        [self.mainView addSubview:segmentView];
        if (items & PROPERTY_COLOR) {
            [self.mainView showTab:TAB_FILL];
            for (SegmentItem *item in [segmentView getItems]) {
                if (item.tag == TAB_FILL) {
                    [segmentView setSelectItem:item];
                }
            }
        }
    }
    self.tempFrame = self.mainView.frame;
}

- (void)setColors:(NSArray *)array {
    self.currentColors = array;
}

- (void)setProperty:(long)property intValue:(int)value {
    if (property & PROPERTY_COLOR) {
        self.currentColor = [[UIColor colorWithRGBHex:value] rgbHex];
        [self.colorLayout setCurrentColor:[[UIColor colorWithRGBHex:value] rgbHex]];
    }
    if (property & PROPERTY_OPACITY) {
        [self.opacityLayout setCurrentOpacity:value];
    }
    if (property & PROPERTY_LINEWIDTH) {
        [self.lineWidthLayout setCurrentColor:self.currentColor];
        [self.lineWidthLayout setCurrentLineWidth:value];
    }
    if (property & PROPERTY_ICONTYPE) {
        [self.typeLayout setCurrentIconType:value];
    }
    if (property & PROPERTY_ATTACHMENT_ICONTYPE) {
        [self.typeLayout setCurrentIconType:value];
    }
    if (property & PROPERTY_ROTATION) {
        [self.rotationLayout setCurrentRotation:value];
    }
}

- (void)setProperty:(long)property floatValue:(float)value {
    if (property & PROPERTY_FONTSIZE) {
        [self.fontLayout setCurrentFontSize:value];
    }
}

- (void)setProperty:(long)property stringValue:(NSString *)value {
    if (property & PROPERTY_FONTNAME) {
        [self.fontLayout setCurrentFontName:value];
    }
    
    if (property & PROPERTY_DISTANCE_UNIT) {
        [self.distanceUnitLayout setCurrentUnitName:value];
    }
}

- (void)addListener:(id<IPropertyValueChangedListener>)listener {
    self.currentListener = listener;
    if (self.colorLayout) {
        [self.colorLayout setCurrentListener:listener];
    }
    if (self.opacityLayout) {
        [self.opacityLayout setCurrentListener:listener];
    }
    if (self.lineWidthLayout) {
        [self.lineWidthLayout setCurrentListener:listener];
    }
    if (self.fontLayout) {
        [self.fontLayout setCurrentListener:listener];
    }
    if (self.typeLayout) {
        [self.typeLayout setCurrentListener:listener];
    }

    if (self.distanceUnitLayout) {
        [self.distanceUnitLayout setCurrentListener:listener];
    }
    if (self.rotationLayout) {
        [self.rotationLayout setCurrentListener:listener];
    }
}

- (void)addTabByTitle:(NSString *)title atIndex:(int)tabIndex {
}

- (void)updatePropertyBar:(CGRect)frame {
}

- (void)showPropertyBar:(CGRect)frame inView:(UIView *)view viewsCanMove:(NSArray *)views {
    float DISPLAYVIEWWIDTH = [_pdfViewCtrl getDisplayView].bounds.size.width;
    float DISPLAYVIEWHEIGHT = [_pdfViewCtrl getDisplayView].bounds.size.height;
    FSAnnot *annot = _extensionsManager.currentAnnot;
    if (annot) {
        int pageIndex = annot.pageIndex;
        CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:pageIndex];
        float width = DISPLAYVIEWWIDTH;
        float height = DISPLAYVIEWHEIGHT;
        ;

        if ((dvRect.origin.x + dvRect.size.width) <= 0 || dvRect.origin.y + dvRect.size.height <= 0 || dvRect.origin.x > width || dvRect.origin.y > height) {
            return;
        }
    }

    frame = CGRectInset(frame, -10, -10);
    if (DEVICE_iPHONE) {
        self.maskView.backgroundColor = [UIColor blackColor];
        self.maskView.alpha = 0.3f;
        self.maskView.tag = 200;

        [view addSubview:self.maskView];
        [view addSubview:self.mainView];
        [self.maskView addTarget:self action:@selector(dismissPropertyBar) forControlEvents:UIControlEventTouchUpInside];
        CGRect newFrame = self.mainView.frame;
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            newFrame.origin.y = DISPLAYVIEWWIDTH - newFrame.size.height;
            self.maskView.frame = CGRectMake(0, 0, DISPLAYVIEWHEIGHT, DISPLAYVIEWWIDTH);
        } else {
            newFrame.origin.y = DISPLAYVIEWHEIGHT - newFrame.size.height;
            self.maskView.frame = CGRectMake(0, 0, DISPLAYVIEWWIDTH, DISPLAYVIEWHEIGHT);
        }
        self.maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
        [UIView animateWithDuration:0.4
                         animations:^{
                             self.mainView.frame = newFrame;
                         }];

        CGRect manViewFrame = newFrame;
        FSAnnot *annot = _extensionsManager.currentAnnot;
        if (annot) {
            CGPoint oldPvPoint = [_pdfViewCtrl convertDisplayViewPtToPageViewPt:CGPointMake(0, 0) pageIndex:annot.pageIndex];
            FSPointF *oldPdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:oldPvPoint pageIndex:annot.pageIndex];

            CGRect pvAnnotRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
            CGRect dvAnnotRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvAnnotRect pageIndex:annot.pageIndex];

            float positionY;
            if (DEVICE_iPHONE && !OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                positionY = _pdfViewCtrl.bounds.size.width - dvAnnotRect.origin.y - dvAnnotRect.size.height;
            } else {
                positionY = _pdfViewCtrl.bounds.size.height - dvAnnotRect.origin.y - dvAnnotRect.size.height;
            }

            if (positionY < manViewFrame.size.height) {
                float dvOffsetY = positionY < 0 ? manViewFrame.size.height : (manViewFrame.size.height - positionY + 20);

                CGRect offsetRect = CGRectMake(0, 0, 100, dvOffsetY);

                CGRect pvRect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:offsetRect pageIndex:annot.pageIndex];
                FSRectF *pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:annot.pageIndex];
                float pdfOffsetY = [pdfRect getTop] - [pdfRect getBottom];

                if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_SINGLE) {
                    [_pdfViewCtrl setBottomOffset:dvOffsetY];
                } else if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_CONTINUOUS) {
                    if ([_pdfViewCtrl getCurrentPage] == [_pdfViewCtrl.currentDoc getPageCount] - 1) {
                        FSRectF *fsRect = [[FSRectF alloc] init];
                        [fsRect set:0 bottom:pdfOffsetY right:pdfOffsetY top:0];
                        float tmpPvOffset = [_pdfViewCtrl convertPdfRectToPageViewRect:fsRect pageIndex:annot.pageIndex].size.width;
                        CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
                        CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:annot.pageIndex];
                        [_pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
                    } else {
                        FSPDFPage *page = [annot getPage];
                        FSRotation rotate = [page getRotation];
                        int x = oldPdfPoint.x;
                        int y = oldPdfPoint.y - pdfOffsetY;
                        switch (rotate) {
                        case e_rotation180:
                            y = oldPdfPoint.y + pdfOffsetY;
                            break;
                        case e_rotation90:
                            x = oldPvPoint.x + pdfOffsetY;
                            y = oldPvPoint.y;
                        case e_rotation270:
                            x = oldPvPoint.x - pdfOffsetY;
                            y = oldPvPoint.y;
                        default:
                            break;
                        }
                        FSPointF *jumpPdfPoint = [[FSPointF alloc] init];
                        [jumpPdfPoint set:x y:y];
                        [_pdfViewCtrl gotoPage:annot.pageIndex withDocPoint:jumpPdfPoint animated:YES];
                    }
                }
            }
        }
    } else {
        self.mainView.frame = self.tempFrame;
        self.popoverCtr.contentViewController.view = self.mainView;

        self.popoverCtr.delegate = self;
        self.popViewCtr.preferredContentSize = CGSizeMake(300, self.mainView.frame.size.height);
        [self.popoverCtr setPopoverContentSize:CGSizeMake(300, self.mainView.frame.size.height)];
        if (frame.origin.x < 300 && frame.origin.y < self.mainView.frame.size.height && _pdfViewCtrl.bounds.size.width - frame.size.width - frame.origin.x < 300 && _pdfViewCtrl.bounds.size.height - frame.size.height - frame.origin.y < self.mainView.frame.size.height) {
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                frame = CGRectMake(_pdfViewCtrl.bounds.size.height / 2, _pdfViewCtrl.bounds.size.width / 2, 10, 10);
            } else {
                frame = CGRectMake(_pdfViewCtrl.bounds.size.width / 2, _pdfViewCtrl.bounds.size.height / 2, 10, 10);
            }
        }
        [self.popoverCtr presentPopoverFromRect:frame inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
        self.popoverCtr.passthroughViews = [NSArray arrayWithArray:views];
    }
}

- (void)refreshPropertyLayout {
    for (UIView *view in self.mainView.subviews) {
        [view removeFromSuperview];
    }

    [self.mainView.segmentItems removeAllObjects];

    CGRect mainFrame;
    if (DEVICE_iPHONE) {
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            mainFrame = CGRectMake(0, PDFVIEWCTRLWIDTH, PDFVIEWCTRLHEIGHT, 500);
        } else {
            mainFrame = CGRectMake(0, PDFVIEWCTRLHEIGHT, PDFVIEWCTRLWIDTH, 500);
        }
    } else {
        mainFrame = CGRectMake(0, 0, 300, 300);
    }
    self.mainView.frame = mainFrame;
    if (self.currentItems & PROPERTY_COLOR) {
        CGRect colorFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.colorLayout.frame = colorFrame;
        [self.colorLayout resetLayout];
        [self.mainView addLayoutAtTab:self.colorLayout tab:TAB_FILL];
    }
    if (self.currentItems & PROPERTY_OPACITY) {
        CGRect opacityFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.opacityLayout.frame = opacityFrame;
        [self.opacityLayout resetLayout];
        [self.mainView addLayoutAtTab:self.opacityLayout tab:TAB_FILL];
    }
    if (self.currentItems & PROPERTY_ROTATION) {
        CGRect rotationFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.rotationLayout.frame = rotationFrame;
        [self.rotationLayout resetLayout];
        [self.mainView addLayoutAtTab:self.rotationLayout tab:TAB_FILL];
    }
    if (self.currentItems & PROPERTY_LINEWIDTH) {
        CGRect linewidthFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.lineWidthLayout.frame = linewidthFrame;
        [self.lineWidthLayout resetLayout];
        [self.mainView addLayoutAtTab:self.lineWidthLayout tab:TAB_BORDER];
    }
    if (self.currentItems & PROPERTY_FONTNAME) {
        CGRect fontNameFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.fontLayout.frame = fontNameFrame;
        [self.fontLayout resetLayout];
        [self.mainView addLayoutAtTab:self.fontLayout tab:TAB_FONT];
    }
    if (self.currentItems & PROPERTY_FONTSIZE) {
    }
    if (self.currentItems & PROPERTY_ICONTYPE || self.currentItems & PROPERTY_ATTACHMENT_ICONTYPE) {
        CGRect typeFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.typeLayout.frame = typeFrame;
        [self.typeLayout resetLayout];
        [self.mainView addLayoutAtTab:self.typeLayout tab:TAB_TYPE];
    }

    if (self.currentItems & PROPERTY_DISTANCE_UNIT) {
        CGRect fontNameFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.distanceUnitLayout.frame = fontNameFrame;
        [self.distanceUnitLayout resetLayout];
        [self.mainView addLayoutAtTab:self.distanceUnitLayout tab:TAB_DISTANCE_UNIT];
    }
    
    if (self.mainView.segmentItems.count > 0) {
        SegmentView *segmentView = [[SegmentView alloc] initWithFrame:CGRectMake(20, 5, self.mainView.frame.size.width - 40, TABHEIGHT - 10) segmentItems:self.mainView.segmentItems];
        segmentView.delegate = self.mainView;
        [self.mainView addSubview:segmentView];
        if (self.currentItems & PROPERTY_COLOR) {
            [self.mainView showTab:TAB_FILL];
            for (SegmentItem *item in [segmentView getItems]) {
                if (item.tag == TAB_FILL) {
                    [segmentView setSelectItem:item];
                }
            }
        }
    }
    if (DEVICE_iPHONE) {
        self.mainView.frame = CGRectMake(0, PDFVIEWCTRLHEIGHT - self.mainView.frame.size.height, PDFVIEWCTRLWIDTH, self.mainView.frame.size.height);
    }
    self.tempFrame = self.mainView.frame;
}

- (UIPopoverController *)popoverCtr {
    if (!_popoverCtr) {
        self.popViewCtr = [[UIViewController alloc] init];
        self.popoverCtr = [[UIPopoverController alloc] initWithContentViewController:self.popViewCtr];
    }
    return _popoverCtr;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self dismissPropertyBar];
}

- (BOOL)isShowing {
    if (DEVICE_iPHONE) {
        if (self.maskView.alpha == 0.3f) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return self.popoverCtr.popoverVisible;
    }
}

- (void)dismissPropertyBar {
    if (DEVICE_iPHONE) {
        [UIView animateWithDuration:0.4
            animations:^{
                self.maskView.alpha = 0.1f;
            }
            completion:^(BOOL finished) {
                [self.maskView removeFromSuperview];
            }];

        CGRect newFrame = self.mainView.frame;
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            newFrame.origin.y = _pdfViewCtrl.bounds.size.width;
        } else {
            newFrame.origin.y = _pdfViewCtrl.bounds.size.height;
        }

        [UIView animateWithDuration:0.4
            animations:^{
                self.mainView.frame = newFrame;
            }
            completion:^(BOOL finished) {
                [self.mainView removeFromSuperview];
            }];
        FSAnnot *annot = _extensionsManager.currentAnnot;
        if (annot) {
            if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_SINGLE || annot.pageIndex == [_pdfViewCtrl.currentDoc getPageCount] - 1) {
                [_pdfViewCtrl setBottomOffset:0];
            }
        }

    } else {
        [self.popoverCtr dismissPopoverAnimated:NO];
    }
    for (id<IPropertyBarListener> listener in self.propertyBarListeners) {
        if ([listener respondsToSelector:@selector(onPropertyBarDismiss)]) {
            [listener onPropertyBarDismiss];
        }
    }
}

- (void)registerPropertyBarListener:(id<IPropertyBarListener>)listener {
    if (listener && ![self.propertyBarListeners containsObject:listener]) {
        [self.propertyBarListeners addObject:listener];
    }
}

- (void)unregisterPropertyBarListener:(id<IPropertyBarListener>)listener {
    if ([self.propertyBarListeners containsObject:listener]) {
        [self.propertyBarListeners removeObject:listener];
    }
}

- (void)setDistanceLayoutsForbidEdit {
    [self.distanceUnitLayout forbidUnit];
}

#pragma mark IRotationEventListener
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (![self isShowing])
        return;

    if (!DEVICE_iPHONE) {
        if (!_extensionsManager.currentAnnot && !_extensionsManager.currentToolHandler)
            [self dismissPropertyBar];
    }

    for (UIView *view in self.mainView.subviews) {
        [view removeFromSuperview];
    }

    [self.mainView.segmentItems removeAllObjects];

    CGRect mainFrame;
    if (DEVICE_iPHONE) {
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            mainFrame = CGRectMake(0, _pdfViewCtrl.bounds.size.width, _pdfViewCtrl.bounds.size.height, 500);
        } else {
            mainFrame = CGRectMake(0, _pdfViewCtrl.bounds.size.height, _pdfViewCtrl.bounds.size.width, 500);
        }
    } else {
        mainFrame = CGRectMake(0, 0, 300, 300);
    }
    self.mainView.frame = mainFrame;
    if (self.currentItems & PROPERTY_COLOR) {
        CGRect colorFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.colorLayout.frame = colorFrame;
        [self.colorLayout resetLayout];
        [self.mainView addLayoutAtTab:self.colorLayout tab:TAB_FILL];
    }
    if (self.currentItems & PROPERTY_OPACITY) {
        CGRect opacityFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.opacityLayout.frame = opacityFrame;
        [self.opacityLayout resetLayout];
        [self.mainView addLayoutAtTab:self.opacityLayout tab:TAB_FILL];
    }
    if (self.currentItems & PROPERTY_ROTATION) {
        CGRect rotationFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.rotationLayout.frame = rotationFrame;
        [self.rotationLayout resetLayout];
        [self.mainView addLayoutAtTab:self.rotationLayout tab:TAB_FILL];
    }
    if (self.currentItems & PROPERTY_LINEWIDTH) {
        CGRect linewidthFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.lineWidthLayout.frame = linewidthFrame;
        [self.lineWidthLayout resetLayout];
        [self.mainView addLayoutAtTab:self.lineWidthLayout tab:TAB_BORDER];
    }
    if (self.currentItems & PROPERTY_FONTNAME) {
        CGRect fontNameFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.fontLayout.frame = fontNameFrame;
        [self.fontLayout resetLayout];
        [self.mainView addLayoutAtTab:self.fontLayout tab:TAB_FONT];
    }
    if (self.currentItems & PROPERTY_FONTSIZE) {
    }
    if (self.currentItems & PROPERTY_ICONTYPE || self.currentItems & PROPERTY_ATTACHMENT_ICONTYPE) {
        CGRect typeFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.typeLayout.frame = typeFrame;
        [self.typeLayout resetLayout];
        [self.mainView addLayoutAtTab:self.typeLayout tab:TAB_TYPE];
    }

    if (self.currentItems & PROPERTY_DISTANCE_UNIT) {
        CGRect fontNameFrame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        self.distanceUnitLayout.frame = fontNameFrame;
        [self.distanceUnitLayout resetLayout];
        [self.mainView addLayoutAtTab:self.distanceUnitLayout tab:TAB_DISTANCE_UNIT];
    }
    
    CGRect rect = self.mainView.frame;
    if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        rect.origin.y = _pdfViewCtrl.bounds.size.width - rect.size.height;
    } else {
        rect.origin.y = _pdfViewCtrl.bounds.size.height - rect.size.height;
    }
    self.mainView.frame = rect;
    if (self.mainView.segmentItems.count > 0) {
        SegmentView *segmentView = [[SegmentView alloc] initWithFrame:CGRectMake(20, 5, self.mainView.frame.size.width - 40, TABHEIGHT - 10) segmentItems:self.mainView.segmentItems];
        segmentView.delegate = self.mainView;
        [self.mainView addSubview:segmentView];
        if (self.currentItems & PROPERTY_COLOR) {
            [self.mainView showTab:TAB_FILL];
            for (SegmentItem *item in [segmentView getItems]) {
                if (item.tag == TAB_FILL) {
                    [segmentView setSelectItem:item];
                }
            }
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

@end
