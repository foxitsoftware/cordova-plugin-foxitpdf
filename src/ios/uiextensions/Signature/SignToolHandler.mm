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

#import "SignToolHandler.h"
#import "../Common/UIExtensionsSharedHeader.h"
#import "AlertView.h"
#import "AnnotationSignature.h"
#import "ColorUtility.h"
#import "DigitalSignatureAnnotHandler.h"
#import "FileSelectDestinationViewController.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "ShapeUtil.h"
#import "SignatureListViewController.h"
#import "SignatureViewController.h"

@interface SignToolHandler () <SignatureListDelegate>

@property (nonatomic, strong) UIImage *annotImage;
@property (nonatomic, strong) SignatureListViewController *signatureListCtr;
@property (nonatomic, strong) UIControl *maskView;
@property (nonatomic, assign) int currentPageIndex;
@property (nonatomic, assign) CGPoint currentPoint;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL isShowList;
@property (nonatomic, strong) NSObject *currentCtr;
@property (nonatomic, strong) DigitalSignatureAnnotHandler *annotHandler;
@end

@implementation SignToolHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
    EDIT_ANNOT_RECT_TYPE _editType;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        _type = e_annotWidget;
        self.docChanging = nil;
        self.isPerformOnce = YES;
        self.isDeleting = NO;

        self.docChanging = ^(NSString *newDocPath) {
            if ([_extensionsManager.delegate respondsToSelector:@selector(uiextensionsManager:openNewDocAtPath:)]) {
                BOOL isOpen = [_extensionsManager.delegate uiextensionsManager:_extensionsManager openNewDocAtPath:newDocPath];
            } else {
                [extensionsManager.pdfViewCtrl openDoc:newDocPath password:nil completion:nil];
            }
        };
        self.getDocPath = ^NSString *() {
            return extensionsManager.pdfViewCtrl.filePath;
        };

        //Create signature data store directory.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory;
        NSError *error = nil;
        if (![fileManager fileExistsAtPath:SIGNATURE_PATH isDirectory:&isDirectory] || !isDirectory) {
            BOOL success = [fileManager createDirectoryAtPath:SIGNATURE_PATH withIntermediateDirectories:YES attributes:nil error:&error];
            if (!success) {
                FoxitLog(@"Fail to create %@. %@", SIGNATURE_PATH, [error localizedDescription]);
            }
        }
    }
    return self;
}

- (SignatureListViewController *)signatureListCtr {
    if (!_signatureListCtr) {
        _signatureListCtr = [[SignatureListViewController alloc] init];
    }
    return _signatureListCtr;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.shouldShowMenu = NO;
        self.isShowList = NO;
        self.currentCtr = nil;
    }
    return self;
}

- (NSString *)getName {
    return Tool_Signature;
}

- (BOOL)isEnabled {
    return YES;
}

- (void)onActivate {
    self.isAdded = NO;
}

- (void)onDeactivate {
    if (!_isDeleting)
        [self delete];
}

- (BOOL)isHitAnnot:(AnnotationSignature *)annot point:(FSPointF *)point {
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.rect pageIndex:annot.pageIndex];
    pvRect = CGRectInset(pvRect, -30, -30);
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:annot.pageIndex]; //pageView docToPageViewPoint:point];
    if (CGRectContainsPoint(pvRect, pvPoint)) {
        return YES;
    }
    return NO;
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer {
    self.currentPageIndex = pageIndex;
    CGPoint point = CGPointZero;
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    if (recognizer) {
        point = [recognizer locationInView:pageView];
    } else {
        point = _signatureStartPoint;
    }
    if (!_isAdded) {
        _maxWidth = pageView.frame.size.width;
        _minWidth = 10;
        _maxHeight = pageView.frame.size.height;
        _minHeight = 10;

        NSString *name = [AnnotationSignature getSignatureSelected];
        UIImage *image = [AnnotationSignature getSignatureImage:name];
        image = [Utility scaleToSize:image size:CGSizeMake(image.size.width / 2, image.size.height / 2)];
        if (!image) {
            _signatureStartPoint = point;
            [self signList];
            return YES;
        }

        self.signature = [AnnotationSignature getSignature:name];
        self.signature.pageIndex = pageIndex;
        CGSize signSize = image.size;
        CGRect signRect = CGRectMake(point.x - signSize.width / 2, point.y - signSize.height / 2, signSize.width, signSize.height);
        if (signRect.origin.x < 0) {
            signRect = CGRectMake(0, signRect.origin.y, signSize.width, signSize.height);
        }
        if (signRect.origin.y < 0) {
            signRect = CGRectMake(signRect.origin.x, 0, signSize.width, signSize.height);
        }
        if ((signRect.origin.x + signRect.size.width) > _maxWidth) {
            signRect = CGRectMake(_maxWidth - signSize.width, signRect.origin.y, signSize.width, signSize.height);
        }
        if ((signRect.origin.y + signRect.size.height) > _maxHeight) {
            signRect = CGRectMake(signRect.origin.x, _maxHeight - signSize.height, signSize.width, signSize.height);
        }
        self.signature.rect = [_pdfViewCtrl convertPageViewRectToPdfRect:signRect pageIndex:pageIndex];

        self.annotImage = image;
        _isAdded = YES;

        NSMutableArray *array = [NSMutableArray array];

        MenuItem *signItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kSignAction") object:self action:@selector(sign)];
        MenuItem *deleteItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kDelete") object:self action:@selector(delete)];

        [array addObject:signItem];
        [array addObject:deleteItem];

        CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:signRect pageIndex:pageIndex];
        _extensionsManager.menuControl.menuItems = array;

        [_extensionsManager.menuControl setRect:dvRect margin:20];
        [_extensionsManager.menuControl showMenu];

        self.shouldShowMenu = YES;
        signRect = CGRectInset(signRect, -30, -30);
        [_pdfViewCtrl refresh:signRect pageIndex:pageIndex needRender:YES];
    } else {
        [self delete];
    }
    return YES;
}

- (FSSignature *)createSignature:(FSPDFPage *)page withParam:(DIGITALSIGNATURE_PARAM *)param {
    FSSignature *sign = NULL;
    FSRectF *rect = param.rect;

    //Add an unsigned signature field with blank appearance on the specified position of page.
    sign = [page addSignature:rect];
    if (nil == sign)
        return nil;

    [sign setKeyValue:e_signatureKeyNameFilter value:@"Adobe.PPKLite"];
    [sign setKeyValue:e_signatureKeyNameSubFilter value:param.subfilter];

    NSDate *now = [NSDate date];
    FSDateTime *time = [Utility convert2FSDateTime:now];
    [sign setSignTime:time];

    [sign setAppearanceFlags:e_signatureAPFlagBitmap];

    NSData *data = [AnnotationSignature getSignatureData:param.sigName];
    FSBitmap *bmp = [Utility imgDataToBitmap:data];
    [sign setBitmap:bmp];
    for (int i = 0; i < [sign getControlCount]; i++) {
        [[[sign getControl:i] getWidget] resetAppearanceStream];
    }

    return sign;
}

- (void)initSignature:(FSSignature *)sign withParam:(DIGITALSIGNATURE_PARAM *)param {
    //Add an unsigned signature field with blank appearance on the specified position of page.
    [sign setKeyValue:e_signatureKeyNameFilter value:@"Adobe.PPKLite"];
    [sign setKeyValue:e_signatureKeyNameSubFilter value:param.subfilter];

    NSDate *now = [NSDate date];
    FSDateTime *time = [Utility convert2FSDateTime:now];
    [sign setSignTime:time];
    [sign setAppearanceFlags:e_signatureAPFlagBitmap];

    NSData *data = [NSData dataWithContentsOfFile:param.imagePath];
    FSBitmap *bmp = [Utility imgDataToBitmap:data];
    [sign setBitmap:bmp];
    for (int i = 0; i < [sign getControlCount]; i++) {
        [[[sign getControl:i] getWidget] resetAppearanceStream];
    }
}

- (BOOL)signSignature:(FSSignature *)sign withParam:(DIGITALSIGNATURE_PARAM *)param {
    FSProgressive *ret = [sign startSign:param.certFile cert_password:param.certPwd digest_algorithm:e_digestSHA1 client_data:nil pause:nil save_path:param.signFilePath];
    
    if (ret != nil) {
        FSProgressState state = [ret resume];
        while (e_progressToBeContinued == state) {
            state = [ret resume];
        }
        return e_progressFinished == state;
    }else{
        return YES;
    }
}

- (FSSignatureStates)verifyDigitalSignature:(NSString *)fileName signature:(FSSignature *)signature {
    @try {
        FSProgressive *ret = [signature startVerify:nil pause:nil];
        if (ret != nil) {
            FSProgressState state = [ret resume];
            while (e_progressToBeContinued == state) {
                state = [ret resume];
            }
        }
    } @catch (NSException *exception) {
        
    }
    return [signature getState];
}

- (NSArray *)getHandleSignArray:(NSArray *)listArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    for (NSString *sigName in listArray) {
        AnnotationSignature *sig = [AnnotationSignature getSignature:sigName];
        if (!(sig.certMD5 && sig.certPasswd && sig.certFileName)) {
            [mutableArray addObject:sigName];
        }
    }
    return mutableArray;
}

- (void)changedSignImage {
    NSString *name = [AnnotationSignature getSignatureSelected];
    UIImage *image = [AnnotationSignature getSignatureImage:name];
    image = [Utility scaleToSize:image size:CGSizeMake(image.size.width / 2, image.size.height / 2)];
    CGRect oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.currentPageIndex];
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(oldRect), CGRectGetMidY(oldRect));
    self.signature = [AnnotationSignature getSignature:name];
    self.signature.pageIndex = self.currentPageIndex;
    CGSize signSize = image.size;
    CGRect signRect = CGRectMake(centerPoint.x - signSize.width / 2, centerPoint.y - signSize.height / 2, signSize.width, signSize.height);
    self.signature.rect = [_pdfViewCtrl convertPageViewRectToPdfRect:signRect pageIndex:self.currentPageIndex];
    self.annotImage = image;

    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.currentPageIndex];
    newRect = CGRectUnion(newRect, oldRect);
    newRect = CGRectInset(newRect, -60, -60);
    [_pdfViewCtrl refresh:newRect pageIndex:self.currentPageIndex needRender:YES];
}

- (void)sign {
    if (!_isAdded) {
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.currentPageIndex];
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:self.currentPageIndex needRender:YES];

        return;
    }

    BOOL isSaveTip = [Preference getBoolValue:Module_Signature type:@"SignSaveTip" delaultValue:NO];
    if (!isSaveTip) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm"
                                                        message:@"kConfirmSign"
                                             buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                 if (buttonIndex == 0) { // no
                                                     [self delete];
                                                     [_extensionsManager setCurrentToolHandler:nil];

                                                     CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.currentPageIndex];
                                                     newRect = CGRectInset(newRect, -30, -30);
                                                     [_pdfViewCtrl refresh:newRect pageIndex:self.currentPageIndex needRender:YES];

                                                     self.currentCtr = nil;
                                                 } else if (buttonIndex == 1) { // yes
                                                     [self addSign];
                                                     self.currentCtr = nil;
                                                     [Preference setBoolValue:Module_Signature type:@"SignSaveTip" value:YES];
                                                 }
                                             }
                                              cancelButtonTitle:@"kNo"
                                              otherButtonTitles:@"kYes", nil];
        [alertView show];
        self.currentCtr = alertView;
    } else {
        [self addSign];
    }
}

- (void)addSignAsImage {
    AnnotationSignature *signAnnot = [AnnotationSignature createWithDefaultOptionForPageIndex:self.signature.pageIndex rect:self.signature.rect];
    signAnnot.data = [AnnotationSignature getSignatureData:self.signature.name];
    signAnnot.contents = @"FoxitMobilePDF/Erutangis";
    signAnnot.name = @"FoxitMobilePDF/Erutangis";
    FSBitmap *dib = [Utility imgDataToBitmap:signAnnot.data];
    if (!dib)
        return;
    FSPDFDoc *doc = [_pdfViewCtrl currentDoc];
    FSPDFPage *page = [doc getPage:self.signature.pageIndex];
    if (!page)
        return;
    FSPDFImageObject *imageObj = [FSPDFImageObject create:doc];
    [imageObj setBitmap:dib mask:nil];

    FSMatrix *matrix = [[FSMatrix alloc] init];
    FSRectF *rect = self.signature.rect;
    int imageWidth = rect.right - rect.left;
    int imageHeight = rect.top - rect.bottom;
    FSRotation rotate = [page getRotation];
    switch (rotate) {
    case e_rotation0:
        [matrix set:imageWidth b:0 c:0 d:imageHeight e:rect.left f:rect.bottom];
        break;
    case e_rotation90:
        [matrix set:0 b:imageHeight c:-imageWidth d:0 e:rect.left + imageWidth f:rect.bottom];
        break;
    case e_rotation270:
        [matrix set:0 b:-imageHeight c:imageWidth d:0 e:rect.left f:rect.bottom + imageHeight];
        break;
    case e_rotation180:
        [matrix set:-imageWidth b:0 c:0 d:-imageHeight e:rect.left + imageWidth f:rect.bottom + imageHeight];
        break;
    default:
        break;
    }

    [imageObj setMatrix:matrix];
    void *lastObjPos = [page getLastGraphicsObjectPosition:e_graphicsObjTypeAll];
    [page insertGraphicsObject:lastObjPos graphicsObj:imageObj];
    [page generateContent];
    [Utility parsePage:page];
    [_pdfViewCtrl refresh:self.signature.pageIndex needRender:YES];
}

- (void)addSignAsStamp {
    AnnotationSignature *signAnnot = [AnnotationSignature createWithDefaultOptionForPageIndex:self.signature.pageIndex rect:self.signature.rect];

    signAnnot.data = [AnnotationSignature getSignatureData:self.signature.name];
    signAnnot.contents = @"FoxitMobilePDF/Erutangis";
    signAnnot.name = @"FoxitMobilePDF/Erutangis";

    {
        FSRectF *rect = signAnnot.rect;
        //patch rect to avoid sdk parm check
        if (rect.left != 0 && rect.left == rect.right) {
            rect.right++;
        }
        if (rect.bottom != 0 && rect.bottom == rect.top) {
            rect.top++;
        }

        FSPDFPage *pdfPage = [[_pdfViewCtrl getDoc] getPage:signAnnot.pageIndex];
        signAnnot.signature = [pdfPage addAnnot:e_annotStamp rect:rect];
        if (signAnnot.signature) {
            //Set name (uuid)
            [signAnnot.signature setUniqueID:[Utility getUUID]];
            //Set author
            //Set add and modify time
            NSDate *now = [NSDate date];
            [signAnnot.signature setCreateDate:now];
            [signAnnot.signature setModifiedDate:now];

            FSBitmap *dib = [Utility imgDataToBitmap:signAnnot.data];
            [(FSStamp *) signAnnot.signature setBitmap:dib];
            [signAnnot.signature resetAppearanceStream];
        }
    }
    _isAdded = NO;
    self.annotImage = nil;
}

- (void)addSign {
    NSString *imagePath = [SIGNATURE_PATH stringByAppendingPathComponent:[self.signature.name stringByAppendingString:@"_i"]];
    FSRectF *rect = self.signature.rect;
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:self.signature.pageIndex];

    if (rect.left != 0 && rect.left == rect.right) {
        rect.right++;
    }
    if (rect.bottom != 0 && rect.bottom == rect.top) {
        rect.top++;
    }

    BOOL isDigitalSignature = NO;
    if (self.signature.certFileName && self.signature.certPasswd && self.signature.certMD5) {
        isDigitalSignature = YES;
    }

    if (!isDigitalSignature) {
        [self addSignAsImage];
    } else {
        [self addDigitalSign:page signArea:(FSRectF *) rect signImagePath:imagePath];
    }
    _isAdded = NO;

    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
    newRect = CGRectInset(newRect, -30, -30);
    [_pdfViewCtrl refresh:newRect pageIndex:self.signature.pageIndex needRender:YES];

    if (self.isPerformOnce)
        [_extensionsManager setCurrentToolHandler:nil];
    [_extensionsManager removeThumbnailCacheOfPageAtIndex:self.signature.pageIndex];
}

- (void)addDigitalSign:(FSPDFPage *)page signArea:(FSRectF *)rect signImagePath:(NSString *)imagePath {
    FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
    selectDestination.isRootFileDirectory = YES;
    selectDestination.fileOperatingMode = FileListMode_Select;
    [selectDestination loadFilesWithPath:DOCUMENT_PATH];
    selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder) {
        [controller dismissViewControllerAnimated:YES completion:nil];
        typedef void (^NumbBlock)(void);
        NumbBlock __block inputFileName = ^() {
            InputAlertView *inputAlertView = [[InputAlertView alloc] initWithTitle:@"kInputNewFileName"
                                                                           message:nil
                                                                buttonClickHandler:^(UIView *alertView, NSInteger buttonIndex) {
                                                                    if (buttonIndex == 0) {
                                                                        return;
                                                                    }
                                                                    InputAlertView *inputAlert = (InputAlertView *) alertView;
                                                                    NSString *fileName = inputAlert.inputTextField.text;

                                                                    if ([fileName rangeOfString:@"/"].location != NSNotFound) {
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning"
                                                                                                                            message:@"kIllegalNameWarning"
                                                                                                                 buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                         inputFileName();
                                                                                                                     });
                                                                                                                     return;
                                                                                                                 }
                                                                                                                  cancelButtonTitle:@"kOK"
                                                                                                                  otherButtonTitles:nil];
                                                                            [alertView show];
                                                                        });
                                                                        return;
                                                                    } else if (fileName.length == 0) {
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            inputFileName();
                                                                        });
                                                                        return;
                                                                    }

                                                                    void (^createPDF)(NSString *pdfFilePath) = ^(NSString *pdfFilePath) {
                                                                        DIGITALSIGNATURE_PARAM *param = [[DIGITALSIGNATURE_PARAM alloc] init];
                                                                        param.certFile = [SIGNATURE_PATH stringByAppendingPathComponent:self.signature.certMD5];
                                                                        param.certPwd = self.signature.certPasswd;
                                                                        param.subfilter = @"adbe.pkcs7.detached";
                                                                        param.imagePath = imagePath;
                                                                        param.rect = rect;
                                                                        param.sigName = self.signature.name;
                                                                        param.signFilePath = pdfFilePath;
                                                                        FSSignature *signature = [self createSignature:page withParam:param];
                                                                        BOOL isSuccess = [self signSignature:signature withParam:param];
                                                                        if (isSuccess) {
                                                                            double delayInSeconds = 0.4;
                                                                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {

                                                                                AlertView *alertView = [[AlertView alloc] initWithTitle:@""
                                                                                                                                message:@"kSaveSignedDocSuccess"
                                                                                                                     buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                                                                                         double delayInSeconds = 0.4;
                                                                                                                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                                                                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                                                                                             if (self.docChanging) {
                                                                                                                                 self.docChanging(pdfFilePath);
                                                                                                                             }
                                                                                                                         });
                                                                                                                         return;
                                                                                                                     }
                                                                                                                      cancelButtonTitle:nil
                                                                                                                      otherButtonTitles:@"kOK", nil];
                                                                                [alertView show];
                                                                            });
                                                                        } else {
                                                                            double delayInSeconds = 0.4;
                                                                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                                                AlertView *alertView = [[AlertView alloc] initWithTitle:@"" message:@"kSaveSignedDocFailure" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
                                                                                [alertView show];
                                                                            });
                                                                        }
                                                                    };

                                                                    NSString *pdfFilePath = [destinationFolder[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf", fileName]];
                                                                    NSFileManager *fileManager = [NSFileManager defaultManager];
                                                                    if ([fileManager fileExistsAtPath:pdfFilePath]) {
                                                                        double delayInSeconds = 0.3;
                                                                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                                            AlertView *alert = [[AlertView alloc] initWithTitle:@"kWarning"
                                                                                                                        message:@"kFileAlreadyExists"
                                                                                                             buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                                                                                 if (buttonIndex == 0) {
                                                                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                         inputFileName();
                                                                                                                     });
                                                                                                                 } else {
                                                                                                                     [fileManager removeItemAtPath:pdfFilePath error:nil];
                                                                                                                     createPDF(pdfFilePath);
                                                                                                                     inputFileName = nil;
                                                                                                                 }
                                                                                                             }
                                                                                                              cancelButtonTitle:@"kCancel"
                                                                                                              otherButtonTitles:@"kReplace", nil];
                                                                            [alert show];
                                                                        });
                                                                        return;
                                                                    }

                                                                    createPDF(pdfFilePath);
                                                                    inputFileName = nil;
                                                                }
                                                                 cancelButtonTitle:@"kCancel"
                                                                 otherButtonTitles:@"kOK", nil];
            inputAlertView.style = TSAlertViewStyleInputText;
            inputAlertView.buttonLayout = TSAlertViewButtonLayoutNormal;
            inputAlertView.usesMessageTextView = NO;
            [inputAlertView show];
        };
        inputFileName();
    };
    selectDestination.cancelHandler = ^(FileSelectDestinationViewController *controller) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    };
    UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:selectDestinationNavController animated:YES completion:nil];
}

- (void)signList {
    typeof(self) __weak weakSelf = self;
    UIViewController *rootViewController = _pdfViewCtrl.window.rootViewController; //[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([AnnotationSignature getSignatureList].count <= 0) {
        SignatureViewController *signatureCtr = [[SignatureViewController alloc] initWithUIExtensionsManager:_extensionsManager];
        signatureCtr.modalPresentationStyle = UIModalPresentationOverFullScreen;
        signatureCtr.currentSignature = nil;
        signatureCtr.saveHandler = ^{
            [weakSelf showAnnotMenu];
            weakSelf.currentCtr = nil;
        };
        signatureCtr.cancelHandler = ^{
            [weakSelf showAnnotMenu];
            weakSelf.currentCtr = nil;
            SignToolHandler *strongSelf = weakSelf;
            assert(strongSelf);
            if (strongSelf) {
                [strongSelf->_extensionsManager setCurrentToolHandler:nil];
            }
        };

        dispatch_async(dispatch_get_main_queue(), ^{
            [rootViewController presentViewController:signatureCtr
                                             animated:NO
                                           completion:^{
                                               weakSelf.currentCtr = signatureCtr;
                                           }];
        });
        return;
    };

    if (DEVICE_iPHONE) {
        [rootViewController presentViewController:self.signatureListCtr
                                         animated:YES
                                       completion:^{
                                           self.isShowList = YES;
                                       }];
    } else {
        CGRect screenFrame = _pdfViewCtrl.bounds;
        self.signatureListCtr.view.frame = CGRectMake(screenFrame.size.width - 300, 0, 300, screenFrame.size.height);
        self.signatureListCtr.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;

        self.maskView = [[UIControl alloc] initWithFrame:_pdfViewCtrl.bounds];
        self.maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
        self.maskView.backgroundColor = [UIColor blackColor];
        self.maskView.alpha = 0.3f;
        self.maskView.tag = 200;
        [self.maskView addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [rootViewController.view addSubview:self.maskView];
        [rootViewController.view addSubview:self.signatureListCtr.view];
        CGRect preFrame = CGRectMake(screenFrame.size.width, 0, 300, screenFrame.size.height);
        CGRect afterFrame = CGRectMake(screenFrame.size.width - 300, 0, 300, screenFrame.size.height);
        self.signatureListCtr.view.frame = preFrame;
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.signatureListCtr.view.frame = afterFrame;
                         }];
        self.isShowList = YES;
    }

    self.signatureListCtr.delegate = self;
}

- (void)openCreateSign {
    typeof(self) __weak weakSelf = self;
    if ([AnnotationSignature getSignatureList].count <= 0) {
        SignatureViewController *signatureCtr = [[SignatureViewController alloc] initWithUIExtensionsManager:_extensionsManager];
        signatureCtr.modalPresentationStyle = UIModalPresentationOverFullScreen;
        signatureCtr.currentSignature = nil;
        signatureCtr.saveHandler = ^{
            weakSelf.currentCtr = nil;
        };
        signatureCtr.cancelHandler = ^{
            weakSelf.currentCtr = nil;
            [_extensionsManager setCurrentToolHandler:nil];
        };
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:signatureCtr
                                         animated:NO
                                       completion:^{
                                           weakSelf.currentCtr = signatureCtr;
                                       }];
        return;
    };
}

- (void)dismiss {
    CGRect screenFrame = _pdfViewCtrl.bounds;
    CGRect preFrame = CGRectMake(screenFrame.size.width - 300, 0, 300, screenFrame.size.height);
    CGRect afterFrame = CGRectMake(screenFrame.size.width, 0, 300, screenFrame.size.height);

    self.signatureListCtr.view.frame = preFrame;
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.signatureListCtr.view.frame = afterFrame;
                         [self.signatureListCtr.view removeFromSuperview];
                         [self.maskView removeFromSuperview];
                     }];

    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
    CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:self.signature.pageIndex];
    if (_isAdded) {
        self.shouldShowMenu = YES;

        [_extensionsManager.menuControl setRect:dvRect margin:20];
        [_extensionsManager.menuControl showMenu];
        dvRect = CGRectInset(dvRect, -10, -10);
        [_pdfViewCtrl refresh:dvRect pageIndex:self.signature.pageIndex needRender:YES];
    }

    self.isShowList = NO;
    if ([AnnotationSignature getSignatureList].count <= 0) {
        [_extensionsManager setCurrentToolHandler:nil];
    }
}

- (void) delete {
    _isDeleting = YES;
    _isAdded = NO;
    self.annotImage = nil;

    if (self.signature) {
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:self.signature.pageIndex needRender:YES];
        //    if (self.isPerformOnce)
        //        [_extensionsManager setCurrentToolHandler:nil];
    } else {
        [_pdfViewCtrl refresh:_extensionsManager.currentPageIndex];
    }
    _isDeleting = NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    if (self != _extensionsManager.currentToolHandler) {
        return NO;
    }

    if (!_isAdded) {
        return NO;
    }

    if (pageIndex != self.signature.pageIndex) {
        return NO;
    }
    UIView *pageView = [_pdfViewCtrl getPageView:self.signature.pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (![self isHitAnnot:self.signature point:pdfPoint]) {
            return NO;
        }

        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }

        _editType = EDIT_ANNOT_RECT_TYPE_FULL;

        NSArray *movePointArray = [ShapeUtil getMovePointInRect:CGRectInset([_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex], -5, -5)];
        [movePointArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect dotRect = [obj CGRectValue];

            dotRect = CGRectInset(dotRect, -20, -20);

            if (CGRectContainsPoint(dotRect, point)) {
                _editType = (EDIT_ANNOT_RECT_TYPE) idx;
                *stop = YES;
            }
        }];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (![self isHitAnnot:self.signature point:pdfPoint]) {
            return NO;
        }

        CGPoint translationPoint = [recognizer translationInView:pageView];
        [recognizer setTranslation:CGPointZero inView:pageView];
        float tw = translationPoint.x;
        float th = translationPoint.y;
        CGRect oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
        FSRectF *rect = [Utility CGRect2FSRectF:oldRect];

        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_LEFTMIDDLE ||
            _editType == EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            rect.left += tw;
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL) {
                // Not left over right
                if ((rect.left + _minWidth) > rect.right) {
                    rect.right = rect.left + _minWidth;
                } else if (ABS(rect.right - rect.left) > _maxWidth) {
                    rect.left -= tw;
                }
            }
        }
        if (_editType == EDIT_ANNOT_RECT_TYPE_RIGHTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTMIDDLE ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            rect.right += tw;
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL) {
                if ((rect.left + _minWidth) > rect.right) {
                    rect.left = rect.right - _minWidth;
                } else if (ABS(rect.right - rect.left) > _maxWidth) {
                    rect.right -= tw;
                }
            }
        }
        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_MIDDLETOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTTOP ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            rect.top += th;
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL) {
                if ((rect.top + _minHeight) > rect.bottom) {
                    rect.bottom = rect.top + _minHeight;
                } else if (ABS(rect.bottom - rect.top) > _maxHeight) {
                    rect.top -= th;
                }
            }
        }
        if (_editType == EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_MIDDLEBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_RIGHTBOTTOM ||
            _editType == EDIT_ANNOT_RECT_TYPE_FULL) {
            rect.bottom += th;
            if (_editType != EDIT_ANNOT_RECT_TYPE_FULL) {
                if ((rect.top + _minHeight) > rect.bottom) {
                    rect.top = rect.bottom - _minHeight;
                } else if (ABS(rect.bottom - rect.top) > _maxHeight) {
                    rect.bottom -= th;
                }
            }
        }

        CGRect newRect = [Utility FSRectF2CGRect:rect];
        rect = [_pdfViewCtrl convertPageViewRectToPdfRect:newRect pageIndex:self.signature.pageIndex];

        if (!(newRect.origin.x <= 0 || newRect.origin.x + newRect.size.width >= pageView.frame.size.width || newRect.origin.y <= 0 || newRect.origin.y + newRect.size.height >= pageView.frame.size.height)) {
            self.signature.rect = rect;

            CGRect refreshRect = CGRectUnion(newRect, oldRect);
            refreshRect = CGRectInset(refreshRect, -80, -80);
            [_pdfViewCtrl refresh:refreshRect pageIndex:self.signature.pageIndex needRender:NO];
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        _editType = EDIT_ANNOT_RECT_TYPE_UNKNOWN;
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:newRect pageIndex:self.signature.pageIndex];

        [_extensionsManager.menuControl setRect:showRect margin:20];
        [_extensionsManager.menuControl showMenu];

        showRect = CGRectInset(showRect, -80, -80);
        [_pdfViewCtrl refresh:showRect pageIndex:self.signature.pageIndex needRender:NO];
    }
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer {
    UIView *pageView = [_pdfViewCtrl getPageView:self.signature.pageIndex];
    CGPoint point = [gestureRecognizer locationInView:pageView];
    FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:self.signature.pageIndex];
    if (_extensionsManager.currentToolHandler == self) {
        if (!_isAdded) {
            return YES;
        } else {
            if ([self isHitAnnot:self.signature point:pdfPoint]) {
                return YES;
            }
        }
    }
    if (pageIndex == self.signature.pageIndex && [self isHitAnnot:self.signature point:pdfPoint]) {
        return YES;
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

#pragma mark IRotateChangedListener

- (void)onRotateChangedBefore:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissAnnotMenu];
}

- (void)onRotateChangedAfter:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self showAnnotMenu];
}

#pragma mark IDvTouchEventListener

- (void)onScrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
{
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView {
    [self showAnnotMenu];
}

- (void)showAnnotMenu {
    if (_isAdded) {
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.signature.pageIndex];
        if (self.shouldShowMenu) {
            [_extensionsManager.menuControl setRect:showRect margin:20];
            [_extensionsManager.menuControl showMenu];
            showRect = CGRectInset(showRect, -80, -80);
            [_pdfViewCtrl refresh:showRect pageIndex:self.signature.pageIndex needRender:YES];
        }
    }
}

- (void)dismissAnnotMenu {
    if (_isAdded) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
    }
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
    if (_extensionsManager.currentToolHandler != self || !_isAdded) {
        return;
    }

    if (pageIndex != self.signature.pageIndex) {
        return;
    }

    if (self.annotImage == nil) {
        return;
    }

    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
    if (self.annotImage) {
        CGContextSaveGState(context);

        CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
        CGContextTranslateCTM(context, 0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
        CGContextDrawImage(context, rect, [self.annotImage CGImage]);

        CGContextRestoreGState(context);

        rect = CGRectInset(rect, -5, -5);

        CGContextSetLineWidth(context, 2.0);
        CGFloat dashArray[] = {3, 3, 3, 3};
        CGContextSetLineDash(context, 3, dashArray, 4);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRGBHex:self.signature.color] CGColor]);
        CGContextStrokeRect(context, rect);

        UIImage *dragDot = [UIImage imageNamed:@"annotation_drag.png"];
        NSArray *movePointArray = [ShapeUtil getMovePointInRect:rect];
        [movePointArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect dotRect = [obj CGRectValue];
            CGPoint point = CGPointMake(dotRect.origin.x - 2, dotRect.origin.y - 2);
            [dragDot drawAtPoint:point];
        }];
    }
}

#pragma mark - IDocEventListener

- (void)onDocWillClose:(FSPDFDoc *)document;
{
    self.shouldShowMenu = NO;
    _isAdded = NO;
    if (self.isShowList) {
        if (DEVICE_iPHONE) {
            [self.signatureListCtr dismissViewControllerAnimated:YES
                                                      completion:^{
                                                          self.isShowList = NO;
                                                      }];
        } else {
            [self dismiss];
        }
    }
    if (self.currentCtr) {
        if ([self.currentCtr isKindOfClass:[SignatureViewController class]]) {
            [(SignatureViewController *) self.currentCtr dismissViewControllerAnimated:NO
                                                                            completion:^{
                                                                                self.currentCtr = nil;
                                                                            }];
        } else if ([self.currentCtr isKindOfClass:[AlertView class]]) {
            [((AlertView *) self.currentCtr) dismissWithClickedButtonIndex:0 animated:NO];
            self.currentCtr = nil;
        }
    }
}

#pragma mark SignatureListDelegate

- (void)signatureListViewController:(SignatureListViewController *)signatureListViewController openSignature:(AnnotationSignature *)signature {
    if (DEVICE_iPHONE) {
        [signatureListViewController dismissViewControllerAnimated:YES
                                                        completion:^{
                                                            self.isShowList = NO;
                                                        }];
    } else {
        [self dismiss];
    }
    SignatureViewController *signatureCtr = [[SignatureViewController alloc] initWithUIExtensionsManager:_extensionsManager];
    signatureCtr.modalPresentationStyle = UIModalPresentationOverFullScreen;
    signatureCtr.currentSignature = signature;
    typeof(self) __weak weakSelf = self;
    signatureCtr.saveHandler = ^{
        if (weakSelf.isAdded) {
            [weakSelf changedSignImage];
        }
        [weakSelf showAnnotMenu];
        weakSelf.currentCtr = nil;
    };
    signatureCtr.cancelHandler = ^{
        [weakSelf showAnnotMenu];
        weakSelf.currentCtr = nil;
    };

    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    double delayInSeconds = 0.05;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [rootViewController presentViewController:signatureCtr
                                         animated:NO
                                       completion:^{
                                           self.currentCtr = signatureCtr;
                                       }];
    });
}

- (void)signatureListViewController:(SignatureListViewController *)signatureListViewController selectSignature:(AnnotationSignature *)signature {
    if (DEVICE_iPHONE) {
        self.isShowList = NO;
        [self changedSignImage];
        [self showAnnotMenu];
    } else {
        [self dismiss];
        [self changedSignImage];
    }
}

- (void)signatureListViewController:(SignatureListViewController *)signatureListViewController deleteSignature:(AnnotationSignature *)signature {
    UIImage *image = [AnnotationSignature getSignatureImage:self.signature.name];
    image = [Utility scaleToSize:image size:CGSizeMake(image.size.width / 2, image.size.height / 2)];
    if (!image) {
        _isAdded = NO;
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
        self.annotImage = nil;
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:self.signature.pageIndex needRender:NO];
    } else {
        self.annotImage = image;
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:self.signature.pageIndex needRender:NO];
        [self showAnnotMenu];
    }
}

- (void)cancelSignature {
    if (DEVICE_iPHONE) {
        [self showAnnotMenu];

        if ([AnnotationSignature getSignatureList].count <= 0) {
            [_extensionsManager setCurrentToolHandler:nil];
        }
    }
}

@end
