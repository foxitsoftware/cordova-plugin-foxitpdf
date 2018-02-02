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

#import "SignatureViewController.h"
#import "AlertView.h"
#import "AnnotationSignature.h"
#import "ColorUtility.h"
#import "DigitalCertSelectCtr.h"
#import "Masonry.h"
#import "SignatureView.h"
#import "TbBaseBar.h"

@interface SignatureViewController ()

@property (nonatomic, strong) TbBaseBar *topBar;
@property (nonatomic, strong) TbBaseItem *cancelItem;
@property (nonatomic, strong) TbBaseItem *clearItem;
@property (nonatomic, strong) TbBaseItem *saveItem;
@property (nonatomic, strong) TbBaseItem *propertyButton;
@property (nonatomic, strong) SignatureView *viewSignature;
@property (nonatomic, assign) int currentColor;
@property (nonatomic, assign) float currentLineWidth;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *createCertBtn;
@property (nonatomic, copy) NSString *currentCertFileName;
@property (nonatomic, copy) NSString *currentCertPasswd;
@property (nonatomic, copy) NSString *currentCertMD5;
@property (nonatomic, strong) NSData *currentDib;
@property (nonatomic, assign) CGRect currentRectSigPart;
@property (nonatomic, assign) BOOL isContentCert;
@property (nonatomic, assign) BOOL isShowPropertyBar;
@end

@implementation SignatureViewController

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        self.extensionsManager = extensionsManager;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSubView];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.viewSignature = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    if (self.currentSignature) {
        [self loadSignature];
    }
}

- (void)initSubView {
    self.topBar = [[TbBaseBar alloc] init];
    self.topBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.topBar.contentView];
    [self.topBar.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view.mas_top);
        make.left.mas_equalTo(self.view.mas_left);
        make.right.mas_equalTo(self.view.mas_right);
        make.height.mas_equalTo(64);
    }];

    self.cancelItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"sign_cancel"] imageSelected:[UIImage imageNamed:@"sign_cancel"] imageDisable:[UIImage imageNamed:@"sign_cancel"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    CGSize itemSize = self.cancelItem.contentView.frame.size;
    [self.topBar.contentView addSubview:self.cancelItem.contentView];
    [self.cancelItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.topBar.contentView.mas_left).offset(10);
        make.centerY.mas_equalTo(self.topBar.contentView.mas_centerY);
        make.width.mas_equalTo(itemSize.width);
        make.height.mas_equalTo(itemSize.height);
    }];

    typeof(self) __weak weakSelf = self;
    self.cancelItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf cancelSign];
    };

    self.saveItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"sign_save"] imageSelected:[UIImage imageNamed:@"sign_save"] imageDisable:[UIImage imageNamed:@"sign_save"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    itemSize = self.saveItem.contentView.frame.size;
    [self.topBar.contentView addSubview:self.saveItem.contentView];
    [self.saveItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.topBar.contentView.mas_right).offset(-10);
        make.centerY.mas_equalTo(self.topBar.contentView.mas_centerY);
        make.width.mas_equalTo(itemSize.width);
        make.height.mas_equalTo(itemSize.height);
    }];
    self.saveItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf saveSign];
    };
    self.saveItem.enable = NO;

    self.clearItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"sign_clear"] imageSelected:[UIImage imageNamed:@"sign_clear"] imageDisable:[UIImage imageNamed:@"sign_clear"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
    itemSize = self.clearItem.contentView.frame.size;
    [self.topBar.contentView addSubview:self.clearItem.contentView];
    [self.clearItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.saveItem.contentView.mas_left).offset(-10);
        make.centerY.mas_equalTo(self.topBar.contentView.mas_centerY);
        make.width.mas_equalTo(itemSize.width);
        make.height.mas_equalTo(itemSize.height);
    }];
    self.clearItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf clearSign];
    };

    self.propertyButton = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"annotation_toolitembg"] imageSelected:[UIImage imageNamed:@"annotation_toolitembg"] imageDisable:[UIImage imageNamed:@"annotation_toolitembg"]];
    itemSize = self.propertyButton.contentView.frame.size;
    [self.topBar.contentView addSubview:self.propertyButton.contentView];
    [self.propertyButton.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.clearItem.contentView.mas_left).offset(-10);
        make.centerY.mas_equalTo(self.topBar.contentView.mas_centerY);
        make.width.mas_equalTo(itemSize.width);
        make.height.mas_equalTo(itemSize.height);
    }];
    self.propertyButton.onTapClick = ^(TbBaseItem *item) {
        [weakSelf propertySign:item];
    };

    UIView *divideView = [[UIView alloc] init];
    divideView.backgroundColor = [UIColor colorWithRed:0xE2 / 255.0f green:0xE2 / 255.0f blue:0xE2 / 255.0f alpha:1];
    [self.topBar.contentView addSubview:divideView];
    [divideView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(divideView.superview.mas_left);
        make.height.mas_equalTo(1);
        make.bottom.mas_equalTo(divideView.superview.mas_bottom);
        make.right.mas_equalTo(divideView.superview.mas_right);
    }];

    [self setSignatureDefaultOption];
    //This two lines can make it fullscreen under ios7
    if (DEVICE_iPHONE) {
        self.extendedLayoutIncludesOpaqueBars = YES; //replace "self.wantsFullScreenLayout = YES;" by deprecation
    }

    self.view.frame = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT);
    // Do any additional setup after loading the view from its nib.

    self.viewSignature = [[SignatureView alloc] init];
    [self.view addSubview:self.viewSignature];

    self.viewSignature.signHasChangedCallback = ^(BOOL hasChanged) {
        if (hasChanged && [weakSelf.viewSignature getCurrentImage]) {
            weakSelf.saveItem.enable = YES;
        } else {
            weakSelf.saveItem.enable = NO;
        }
    };

    [self.viewSignature mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(0);
        make.top.equalTo(self.view.mas_top).offset(64);
        make.width.mas_equalTo(MAX(SCREENWIDTH, SCREENHEIGHT));
        make.height.mas_equalTo(MAX(SCREENWIDTH, SCREENHEIGHT));
    }];

    self.bottomBar = [[UIView alloc] init];
    self.createCertBtn = [[UIButton alloc] init];

    self.bottomBar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    [self.view addSubview:self.bottomBar];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.bottomBar.superview.mas_bottom);
        make.left.mas_equalTo(self.bottomBar.superview.mas_left);
        make.right.mas_equalTo(self.bottomBar.superview.mas_right);
        make.height.mas_equalTo(49);
    }];

    if (self.currentSignature) {
        self.currentCertFileName = self.currentSignature.certFileName;
        self.currentCertMD5 = self.currentSignature.certMD5;
        self.currentCertPasswd = self.currentSignature.certPasswd;
    }

    if (self.currentCertFileName) {
        NSString *title = [FSLocalizedString(@"kCurrentSelectCert") stringByAppendingString:self.currentCertFileName];
        [self.createCertBtn setTitle:title forState:UIControlStateNormal];
    } else {
        [self.createCertBtn setTitle:FSLocalizedString(@"kSelectAddCert") forState:UIControlStateNormal];
    }

    [self.createCertBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.createCertBtn.titleLabel.font = [UIFont systemFontOfSize:18.f];
    self.createCertBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.createCertBtn addTarget:self action:@selector(selectCert) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.createCertBtn];
    [_createCertBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(_createCertBtn.superview.mas_bottom);
        make.top.mas_equalTo(_createCertBtn.superview.mas_top);
        make.centerX.mas_equalTo(_createCertBtn.superview.mas_centerX);
        make.width.mas_equalTo(300);
    }];

    self.currentColor = [Preference getIntValue:[self getName] type:@"Color" defaultValue:0x000000];
    self.currentLineWidth = [Preference getFloatValue:[self getName] type:@"Linewidth" defaultValue:2];
    self.viewSignature.color = self.currentColor;
    self.viewSignature.diameter = self.currentLineWidth;
    [self.propertyButton setInsideCircleColor:self.currentColor];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    if (self.viewSignature.hasChanged) {
        self.currentDib = [[self.viewSignature getCurrentDib] copy];
        self.currentRectSigPart = self.viewSignature.rectSigPart;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (!DEVICE_iPHONE) {
        if (self.extensionsManager.propertyBar.isShowing) {
            _isShowPropertyBar = YES;
            [self.extensionsManager.propertyBar dismissPropertyBar];
        } else {
            _isShowPropertyBar = NO;
        }
    }
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            if (_isShowPropertyBar) {
                [self propertySign:self.propertyButton];
            }
        }];
}

- (void)selectCert {
    DigitalCertSelectCtr *digitalCertSelectCtr = [[DigitalCertSelectCtr alloc] init];
    UINavigationController *digitalCertNav = [[UINavigationController alloc] initWithRootViewController:digitalCertSelectCtr];
    digitalCertSelectCtr.title = FSLocalizedString(@"kSelectAddCert");
    [self presentViewController:digitalCertNav
                       animated:YES
                     completion:^{

                     }];
    typeof(self) __weak weakSelf = self;
    digitalCertSelectCtr.doneOperator = ^(NSString *path, NSString *passwd, NSString *md5) {
        NSString *title = [FSLocalizedString(@"kCurrentSelectCert") stringByAppendingString:[path lastPathComponent]];
        SignatureViewController *strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf->_createCertBtn setTitle:title forState:UIControlStateNormal];
        }
        weakSelf.currentCertFileName = [path lastPathComponent];
        weakSelf.currentCertPasswd = passwd;
        weakSelf.currentCertMD5 = md5;
        [AnnotationSignature setCertFileToSiganatureSpace:md5 path:path];
        weakSelf.viewSignature.hasChanged = YES;
        weakSelf.isContentCert = YES;
    };
    digitalCertSelectCtr.cancelOperator = ^(NSString *path, NSString *passwd, NSString *md5) {
    };
}

- (void)updateSignature {
    self.currentSignature.rectSigPart = self.viewSignature.rectSigPart;
    self.currentSignature.color = self.viewSignature.color;
    self.currentSignature.diameter = self.viewSignature.diameter;
    self.currentSignature.certFileName = self.currentCertFileName;
    self.currentSignature.certMD5 = self.currentCertMD5;
    self.currentSignature.certPasswd = self.currentCertPasswd;
    [self setSignatureImage:self.currentSignature.name];
    [self.currentSignature update];
    [AnnotationSignature setSignatureSelected:self.currentSignature.name];
}

- (void)setSignatureImage:(NSString *)name {
    UIImage *img = [self.viewSignature getCurrentImage];
    [AnnotationSignature setSignatureImage:name img:img];
    NSData *data = [self.viewSignature getCurrentDib];
    [AnnotationSignature setSignatureDib:name data:data];
}

- (void)loadSignature {
    NSData *data = [AnnotationSignature getSignatureDib:self.currentSignature.name];
    CGRect rectSigPart = self.currentSignature.rectSigPart;
    if (self.viewSignature.hasChanged) {
        data = self.currentDib;
        rectSigPart = self.currentRectSigPart;
        [self.viewSignature loadSignature:data rect:rectSigPart];
        self.viewSignature.hasChanged = YES;
    } else {
        [self.viewSignature loadSignature:data rect:rectSigPart];
    }
}

- (void)addNewSignature {
    AnnotationSignature *sig = [[AnnotationSignature alloc] init];
    sig.rectSigPart = self.viewSignature.rectSigPart;
    sig.color = self.viewSignature.color;
    sig.diameter = self.viewSignature.diameter;
    sig.certFileName = self.currentCertFileName;
    sig.certMD5 = self.currentCertMD5;
    sig.certPasswd = self.currentCertPasswd;
    NSString *newName = [sig add];
    [self setSignatureImage:newName];
    [AnnotationSignature setSignatureSelected:newName];
}

- (void)setSignatureDefaultOption {
    AnnotationSignature *option = [AnnotationSignature getSignatureOption];
    self.viewSignature.color = option.color;
    self.viewSignature.diameter = option.diameter;
}

#pragma mark - event methods

- (NSString *)getName {
    return Module_Signature;
}

- (void)propertySign:(TbBaseItem *)item {
    NSArray *colors = @[ @0x000000, @0x000066, @0x323232, @0x326600, @0x660000, @0x003232, @0x320099, @0x663200, @0x663266, @0x666600 ];
    [self.extensionsManager.propertyBar setColors:colors];
    [self.extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_LINEWIDTH frame:CGRectMake(0, SCREENHEIGHT, SCREENWIDTH, 500)];
    [self.extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:self.currentColor];
    [self.extensionsManager.propertyBar setProperty:PROPERTY_LINEWIDTH intValue:self.currentLineWidth * 2];
    [self.extensionsManager.propertyBar addListener:self];
    CGRect rect = [self.propertyButton.contentView convertRect:self.propertyButton.contentView.bounds toView:self.view];

    if (DEVICE_iPHONE) {
        [self.extensionsManager.propertyBar showPropertyBar:rect inView:self.view viewsCanMove:nil];
    } else {
        [self.extensionsManager.propertyBar showPropertyBar:item.contentView.bounds inView:item.contentView viewsCanMove:nil];
    }
}

#pragma mark topbar method

- (void)cancelSign {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:NO
                                 completion:^{
                                     if (self.cancelHandler) {
                                         self.cancelHandler();
                                     }
                                 }];
    });
}

- (void)clearSign {
    [self.viewSignature clear];
    self.viewSignature.hasChanged = YES;
}

- (void)saveSign {
    if (self.viewSignature.hasChanged) {
        if (self.currentSignature == nil) //new
        {
            if (_isFieldSig) {
                if (_isContentCert) {
                    [self addNewSignature];
                } else {
                    AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kFieldSignWithoutCert" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
                    [alertView show];
                    return;
                }
            } else {
                [self addNewSignature];
            }
        } else //edit
        {
            [self updateSignature];
        }
    }

    [self dismissViewControllerAnimated:NO
                             completion:^{
                                 if (self.saveHandler) {
                                     self.saveHandler();
                                 }
                             }];
}

- (UIImage *)getImageWithWarning {
    UIImage *img = [self.viewSignature getCurrentImage];
    if (!img) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kSignatureEmpty" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
        [alertView show];
    }
    return img;
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    if (DEVICE_iPHONE) {
//        return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
//    }
//    return YES;
//}

//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    if (DEVICE_iPHONE) {
//        return UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskLandscapeLeft;
//    }
//    return UIInterfaceOrientationMaskAll;
//}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
}

#pragma mark -IPropertyValueChangedListener

- (void)onProperty:(long)property changedFrom:(NSValue *)oldValue to:(NSValue *)newValue {
    if (property == PROPERTY_COLOR) {
        int color = 0;
        [newValue getValue:&color];
        self.viewSignature.color = color;
        self.currentColor = color;
        [Preference setIntValue:[self getName] type:@"Color" value:color];
        [self.propertyButton setInsideCircleColor:color];
    }
    if (property == PROPERTY_LINEWIDTH) {
        int f = 0;
        [newValue getValue:&f];
        self.viewSignature.diameter = (float) f / 2;
        self.currentLineWidth = (float) f / 2;
        [Preference setFloatValue:[self getName] type:@"Linewidth" value:(float) f / 2];
    }
}

- (void)onIntValueChanged:(long)property value:(int)value {
}

- (void)onFloatValueChanged:(long)property value:(float)value {
}

- (void)onStringValueChanged:(long)property value:(NSString *)value {
}

@end
