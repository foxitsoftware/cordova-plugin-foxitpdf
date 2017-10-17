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

#import "DigitalSignatureAnnotHandler.h"
#import "AlertView.h"
#import "AnnotationSignature.h"
#import "ColorUtility.h"
#import "CustomIOSAlertView.h"
#import "DigitalSignatureCom.h"
#import "FileSelectDestinationViewController.h"
#import "Masonry.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "SignToolHandler.h"
#import "SignatureListViewController.h"
#import "SignatureOperator.h"
#import "SignatureViewController.h"
#import <openssl/evp.h>
#import <sys/stat.h>

@interface DigitalSignatureAnnotHandler () <UIPopoverControllerDelegate, SignatureListDelegate> {
}
@property (nonatomic, strong) FSSignature *currentSelectSign;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, strong) FSAnnot *editAnnot;
@property (nonatomic, strong) NSMutableDictionary *digitalSignDic;
@property (nonatomic, strong) SignatureListViewController *signatureListCtr;
@property (nonatomic, strong) UIPopoverController *popoverCtr;
@property (nonatomic, assign) BOOL isAdded;
@property (nonatomic, strong) UIImage *annotImage;
@property (nonatomic, strong) AnnotationSignature *signature;
@property (nonatomic, strong) SignatureViewController *signViewCtr;
@property (nonatomic, assign) BOOL isShowList;
@property (nonatomic, assign) UIUserInterfaceSizeClass currentSizeclass;
@property (nonatomic, assign) BOOL isReview;
@property (nonatomic, assign) BOOL isShowVerifyInfo;
@property (nonatomic, strong) CustomIOSAlertView *customAlertView;
@property (nonatomic, strong) SignToolHandler *signToolHandler;
@end
static unsigned long get_file_size(const char *path);
@implementation DigitalSignatureAnnotHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _extensionsManager = extensionsManager;
        [_pdfViewCtrl registerScrollViewEventListener:self];
        [_extensionsManager registerRotateChangedListener:self];
        [_extensionsManager registerAnnotHandler:self];
        self.signToolHandler = (SignToolHandler *) [_extensionsManager getToolHandlerByName:Tool_Signature];

        self.shouldShowMenu = NO;
        self.editAnnot = nil;
        self.digitalSignDic = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (SignatureListViewController *)signatureListCtr {
    if (!_signatureListCtr) {
        _signatureListCtr = [[SignatureListViewController alloc] init];
        _signatureListCtr.isFieldSigList = YES;
    }
    return _signatureListCtr;
}

- (FSAnnotType)getType {
    return e_annotWidget;
}

- (BOOL)annotCanAnswer:(FSAnnot *)annot {
    return YES;
}

- (FSRectF *)getAnnotBBox:(FSAnnot *)annot {
    return [annot getRect];
}

- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point {
    CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    pvRect = CGRectInset(pvRect, -30, -30);
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:annot.pageIndex];
    if (CGRectContainsPoint(pvRect, pvPoint)) {
        return YES;
    }

    return NO;
}

- (void)onAnnotSelected:(FSAnnot *)annot {
    self.editAnnot = annot;
    FSPDFPage *page = [self.editAnnot getPage];
    float x = self.editAnnot.fsrect.left + (self.editAnnot.fsrect.right - self.editAnnot.fsrect.left) * 0.5;
    float y = self.editAnnot.fsrect.bottom + (self.editAnnot.fsrect.top - self.editAnnot.fsrect.bottom) * 0.5;

    FSPointF *pt = [[FSPointF alloc] init];
    [pt set:x y:y];
    FSAnnot *annotTemp = [page getAnnotAtPos:pt tolerance:0];
    if ([annotTemp getType] != e_annotWidget) {
        return;
    }
    FSFormField *field = [(FSWidget *) annotTemp getField];
    if ([field getType] != e_formFieldSignature) {
        return;
    }
    FSSignature *sig = (FSSignature *) field;
    self.currentSelectSign = sig;

    BOOL isSigned = [sig isSigned];

    NSMutableArray *array = [NSMutableArray array];

    self.shouldShowMenu = YES;
    self.currentSizeclass = SIZECLASS;
    if (isSigned) {
        MenuItem *vaildDigitalSign = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kVerifySign") object:self action:@selector(vaildDigitalSign)];
        MenuItem *cancel = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kCancel") object:self action:@selector(cancel)];
        [array addObject:vaildDigitalSign];
        [array addObject:cancel];
        _extensionsManager.menuControl.menuItems = array;
        [self showAnnotMenu];
    } else {
        BOOL canFillForm = [Utility canFillFormInDocument:[page getDocument]];
        if (!canFillForm) {
            return;
        }

        int flags = [field getFlags];
        if (flags == e_formFieldFlagReadonly) {
            [_extensionsManager setCurrentAnnot:nil];
            return;
        }

        MenuItem *addSign = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kAddSign") object:self action:@selector(sign)];
        MenuItem *signList = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kSignList") object:self action:@selector(signList)];
        MenuItem *deleteSign = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kDeleteSign") object:self action:@selector(deleteSign)];
        [array addObject:addSign];
        [array addObject:signList];
        [array addObject:deleteSign];
        _extensionsManager.menuControl.menuItems = array;

        //Fill the necessary field of signature for signning if there is no such one.
        FSPDFDictionary *sigDict = [sig getSignatureDict];
        if (![sigDict hasKey:@"Filter"]) {
            FSPDFObject *value = [FSPDFObject createFromName:@"Adobe.PPKLite"];
            [sigDict setAt:@"Filter" object:value];
        }
        if (![sigDict hasKey:@"SubFilter"]) {
            FSPDFObject *value = [FSPDFObject createFromName:@"adbe.pkcs7.detached"];
            [sigDict setAt:@"SubFilter" object:value];
        }
        if (![sigDict hasKey:@"ByteRange"]) {
            FSPDFObject *value = [FSPDFObject createFromName:@"A123456789012345678901234567890123B"];
            [sigDict setAt:@"ByteRange" object:value];
        }

        if (![sigDict hasKey:@"Contents"]) {
            char *pContent = (char *) malloc(SIGCONTENT_LENGTH + 1);
            memset((void *) pContent, (int) '0', (size_t) SIGCONTENT_LENGTH);
            pContent[SIGCONTENT_LENGTH] = 0;
            NSString *content = [NSString stringWithUTF8String:pContent];
            FSPDFObject *value = [FSPDFObject createFromString:content];
            [sigDict setAt:@"Contents" object:value];
            free(pContent);
        }

        [self addFieldSign];
    }
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

- (void)onReviewStateChanged:(BOOL)start {
    if (start) {
        _isReview = YES;
    } else {
        _isReview = NO;
    }
}

- (void)addFieldSign {
    NSString *selectSig = [AnnotationSignature getSignatureSelected];
    AnnotationSignature *signnature = [AnnotationSignature getSignature:selectSig];
    if (signnature.certMD5 && signnature.certPasswd && signnature.certFileName) {
        _isAdded = YES;
        self.signature = signnature;
        self.annotImage = [AnnotationSignature getSignatureImage:signnature.name];

        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:self.editAnnot.pageIndex];
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:self.editAnnot.pageIndex needRender:NO];

        [self showAnnotMenu];
    } else {
        if ([AnnotationSignature getCertSignatureList].count <= 0) {
            SignatureViewController *signatureCtr = [[SignatureViewController alloc] initWithUIExtensionsManager:_extensionsManager];
            self.signViewCtr = signatureCtr;
            signatureCtr.modalPresentationStyle = UIModalPresentationOverFullScreen;
            signatureCtr.isFieldSig = YES;
            signatureCtr.currentSignature = nil;
            DigitalSignatureAnnotHandler *__weak weakSelf = self;
            signatureCtr.saveHandler = ^{
                NSString *selectSig = [AnnotationSignature getSignatureSelected];
                AnnotationSignature *signnature = [AnnotationSignature getSignature:selectSig];
                DigitalSignatureAnnotHandler *strongSelf = weakSelf;
                assert(strongSelf);
                strongSelf->_isAdded = YES;
                strongSelf.signature = signnature;
                strongSelf.annotImage = [AnnotationSignature getSignatureImage:signnature.name];
                int pageIndex = strongSelf.editAnnot.pageIndex;
                CGRect newRect = [strongSelf->_pdfViewCtrl convertPdfRectToPageViewRect:strongSelf.editAnnot.fsrect pageIndex:pageIndex];
                newRect = CGRectInset(newRect, -30, -30);
                [strongSelf->_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:NO];
                weakSelf.shouldShowMenu = YES;
                [strongSelf showAnnotMenu];
            };
            signatureCtr.cancelHandler = ^{
                DigitalSignatureAnnotHandler *strongSelf = weakSelf;
                assert(strongSelf);
                [strongSelf->_extensionsManager setCurrentAnnot:nil];
            };
            weakSelf.shouldShowMenu = NO;
            UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
            [rootViewController presentViewController:signatureCtr
                                             animated:NO
                                           completion:^{

                                           }];
        } else {
            [self signList];
        }
    }
}

- (void)cancel {
    [_extensionsManager setCurrentAnnot:nil];
}

- (void)vaildDigitalSign {
    FSSignature *sig = self.currentSelectSign;
    CERT_INFO *info = [[CERT_INFO alloc] init];

    FSSignatureStates status = [self.signToolHandler verifyDigitalSignature:nil signature:sig];
    info.signDate = [sig getSignTime];
    info.certSerialNum = [sig getCertificateInfo:@"SerialNumber"];
    info.certStartDate = [sig getCertificateInfo:@"ValidPeriodFrom"];
    info.certEndDate = [sig getCertificateInfo:@"ValidPeriodTo"];
    NSString *certIssuer = [sig getCertificateInfo:@"Issuer"];
    NSRange r = [certIssuer rangeOfString:@"CN="];
    if (0 < r.length) {
        certIssuer = [certIssuer substringFromIndex:r.location + 3];
        r = [certIssuer rangeOfString:@","];
        if (0 < r.length) {
            info.certPublisher = [certIssuer substringToIndex:r.location];
        }
    }

    NSString *certSubject = [sig getCertificateInfo:@"Subject"];
    r = [certSubject rangeOfString:@"E="];
    if (0 < r.length) {
        certSubject = [certSubject substringFromIndex:r.location + 2];
        r = [certSubject rangeOfString:@","];
        if (0 < r.length) {
            info.certEmailInfo = [certSubject substringToIndex:r.location];
        }
    }

    BOOL isFileChanged = NO;
    NSString *fileName = @"";
    if (self.signToolHandler.getDocPath) {
        fileName = self.signToolHandler.getDocPath();
    }
    unsigned long fileLength = get_file_size([fileName UTF8String]);
    NSArray<NSNumber *> *byteRanges = [sig getByteRanges];
    if (byteRanges) {
        unsigned int r1 = [byteRanges[2] unsignedIntValue];
        unsigned int r2 = [byteRanges[3] unsignedIntValue];
        if (fileLength != (r1 + r2)) {
            isFileChanged = YES;
        }
    }

    CustomIOSAlertView *alertView = [[CustomIOSAlertView alloc] init];
    self.customAlertView = alertView;
    [alertView setContainerView:[self createAlertContentView:status certInfo:info isFileChange:isFileChanged]];

    [alertView setButtonTitles:[NSMutableArray arrayWithObjects:FSLocalizedString(@"kOK"), nil]];

    [alertView setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
        [alertView close];
        _isShowVerifyInfo = NO;
    }];

    [alertView setUseMotionEffects:true];

    [alertView show];
    _isShowVerifyInfo = YES;
    [_extensionsManager setCurrentAnnot:nil];
}

static unsigned long get_file_size(const char *path) {
    unsigned long filesize = -1;
    struct stat statbuff;
    if (stat(path, &statbuff) < 0) {
        return filesize;
    } else {
        filesize = (unsigned long) statbuff.st_size;
    }
    return filesize;
}

- (UIView *)createAlertContentView:(FSSignatureStates)status certInfo:(CERT_INFO *)certInfo isFileChange:(BOOL)isFileChange {
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 290)];
    contentView.backgroundColor = [UIColor whiteColor];
    UILabel *titleLable = [[UILabel alloc] init];
    titleLable.text = FSLocalizedString(@"kVerifyTitle");
    titleLable.font = [UIFont boldSystemFontOfSize:16];
    [contentView addSubview:titleLable];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize size = [titleLable.text boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:16], NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    [titleLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(titleLable.superview.mas_top).offset(10);
        make.centerX.mas_equalTo(titleLable.superview.mas_centerX);
        make.width.mas_equalTo(size.width + 1);
        make.height.mas_equalTo(size.height);
    }];

    UILabel *signatureViald = [[UILabel alloc] init];
    if (status == e_signatureStateVerifyValid) {
        if (isFileChange) {
            signatureViald.text = FSLocalizedString(@"kVerifyVaildModifyResult");
        } else {
            signatureViald.text = FSLocalizedString(@"kVerifyVaildResult");
        }

    } else if (status == e_signatureStateUnknown) {
        signatureViald.text = FSLocalizedString(@"kVerifyUnknownResult");
    } else {
        signatureViald.text = FSLocalizedString(@"kVerifyInvaildResult");
    }
    signatureViald.font = [UIFont systemFontOfSize:15];
    signatureViald.numberOfLines = 0;
    [contentView addSubview:signatureViald];
    size = [signatureViald.text boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15], NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    [signatureViald mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(titleLable.mas_bottom).offset(15);
        make.left.mas_equalTo(signatureViald.superview.mas_left).offset(10);
        make.width.mas_equalTo(size.width + 1);
    }];

    float maxWidth = 0;
    CGSize issuerSize = [FSLocalizedString(@"kCertIssuer") boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14], NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    if (maxWidth < issuerSize.width) {
        maxWidth = issuerSize.width;
    }
    CGSize serialNumSize = [FSLocalizedString(@"kCertSerialNum") boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14], NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    if (maxWidth < serialNumSize.width) {
        maxWidth = serialNumSize.width;
    }
    CGSize emailSize = [FSLocalizedString(@"kCertEmail") boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14], NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    if (maxWidth < emailSize.width) {
        maxWidth = emailSize.width;
    }
    CGSize certDateSSize = [FSLocalizedString(@"kCertStartTime") boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14], NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    if (maxWidth < certDateSSize.width) {
        maxWidth = certDateSSize.width;
    }
    CGSize certDateESize = [FSLocalizedString(@"kCertEndTime") boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14], NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    if (maxWidth < certDateESize.width) {
        maxWidth = certDateESize.width;
    }
    CGSize signDateSize = [FSLocalizedString(@"kSignDate") boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14], NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
    if (maxWidth < signDateSize.width) {
        maxWidth = signDateSize.width;
    }

    UILabel *issuerKeyLabel = [[UILabel alloc] init];
    issuerKeyLabel.text = FSLocalizedString(@"kCertIssuer");
    issuerKeyLabel.font = [UIFont systemFontOfSize:14];
    issuerKeyLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    [contentView addSubview:issuerKeyLabel];
    [issuerKeyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(signatureViald.mas_bottom).offset(15);
        make.left.mas_equalTo(issuerKeyLabel.superview.mas_left).offset(10);
        make.width.mas_equalTo(issuerSize.width + 1);
        make.height.mas_equalTo(issuerSize.height);
    }];

    UILabel *issuerValueLabel = [[UILabel alloc] init];
    issuerValueLabel.text = certInfo.certPublisher;
    issuerValueLabel.font = [UIFont systemFontOfSize:14];
    issuerValueLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    issuerValueLabel.numberOfLines = 0;
    [contentView addSubview:issuerValueLabel];
    [issuerValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(maxWidth + 10 + 2);
        make.top.mas_equalTo(issuerKeyLabel.mas_top);
        make.right.mas_equalTo(issuerValueLabel.superview.mas_right).offset(-10);
    }];

    UILabel *serialNumKeyLabel = [[UILabel alloc] init];
    serialNumKeyLabel.text = FSLocalizedString(@"kCertSerialNum");
    serialNumKeyLabel.font = [UIFont systemFontOfSize:14];
    serialNumKeyLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    [contentView addSubview:serialNumKeyLabel];
    [serialNumKeyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        if (issuerValueLabel.text.length < 1) {
            make.top.mas_equalTo(issuerKeyLabel.mas_bottom).offset(5);
        } else {
            make.top.mas_equalTo(issuerValueLabel.mas_bottom).offset(5);
        }
        make.left.mas_equalTo(serialNumKeyLabel.superview.mas_left).offset(10);
        make.width.mas_equalTo(serialNumSize.width + 1);
        make.height.mas_equalTo(serialNumSize.height);
    }];

    UILabel *serialNumValueLabel = [[UILabel alloc] init];
    serialNumValueLabel.text = certInfo.certSerialNum;
    serialNumValueLabel.font = [UIFont systemFontOfSize:14];
    serialNumValueLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    serialNumValueLabel.numberOfLines = 0;
    [contentView addSubview:serialNumValueLabel];
    [serialNumValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(maxWidth + 10 + 2);
        make.top.mas_equalTo(serialNumKeyLabel.mas_top);
        make.right.mas_equalTo(serialNumValueLabel.superview.mas_right).offset(-10);
    }];

    UILabel *eamilKeyLabel = [[UILabel alloc] init];
    eamilKeyLabel.text = FSLocalizedString(@"kCertEmail");
    eamilKeyLabel.font = [UIFont systemFontOfSize:14];
    eamilKeyLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    [contentView addSubview:eamilKeyLabel];
    [eamilKeyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        if (serialNumValueLabel.text.length < 1) {
            make.top.mas_equalTo(serialNumKeyLabel.mas_bottom).offset(5);
        } else {
            make.top.mas_equalTo(serialNumValueLabel.mas_bottom).offset(5);
        }
        make.left.mas_equalTo(eamilKeyLabel.superview.mas_left).offset(10);
        make.width.mas_equalTo(emailSize.width + 1);
        make.height.mas_equalTo(emailSize.height);
    }];

    UILabel *emailValueLabel = [[UILabel alloc] init];
    emailValueLabel.text = certInfo.certEmailInfo;
    emailValueLabel.font = [UIFont systemFontOfSize:14];
    emailValueLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    emailValueLabel.numberOfLines = 0;
    [contentView addSubview:emailValueLabel];
    [emailValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(maxWidth + 10 + 2);
        make.top.mas_equalTo(eamilKeyLabel.mas_top);
        make.right.mas_equalTo(emailValueLabel.superview.mas_right).offset(-10);
    }];

    UILabel *certVaildDateKeyLabel = [[UILabel alloc] init];
    certVaildDateKeyLabel.text = FSLocalizedString(@"kCertStartTime");
    certVaildDateKeyLabel.font = [UIFont systemFontOfSize:14];
    certVaildDateKeyLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    [contentView addSubview:certVaildDateKeyLabel];
    [certVaildDateKeyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        if (emailValueLabel.text.length < 1) {
            make.top.mas_equalTo(eamilKeyLabel.mas_bottom).offset(5);
        } else {
            make.top.mas_equalTo(emailValueLabel.mas_bottom).offset(5);
        }
        make.left.mas_equalTo(certVaildDateKeyLabel.superview.mas_left).offset(10);
        make.width.mas_equalTo(certDateSSize.width + 1);
        make.height.mas_equalTo(certDateSSize.height);
    }];

    UILabel *vaildDateValueLabel = [[UILabel alloc] init];
    vaildDateValueLabel.text = certInfo.certStartDate;
    vaildDateValueLabel.font = [UIFont systemFontOfSize:14];
    vaildDateValueLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    [contentView addSubview:vaildDateValueLabel];
    [vaildDateValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(maxWidth + 10 + 2);
        make.top.mas_equalTo(certVaildDateKeyLabel.mas_top);
        make.bottom.mas_equalTo(certVaildDateKeyLabel.mas_bottom);
        make.right.mas_equalTo(vaildDateValueLabel.superview.mas_right).offset(-10);
    }];

    UILabel *certInvaildDateKeyLabel = [[UILabel alloc] init];
    certInvaildDateKeyLabel.text = FSLocalizedString(@"kCertEndTime");
    certInvaildDateKeyLabel.font = [UIFont systemFontOfSize:14];
    certInvaildDateKeyLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    [contentView addSubview:certInvaildDateKeyLabel];
    [certInvaildDateKeyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(certVaildDateKeyLabel.mas_bottom).offset(5);
        make.left.mas_equalTo(certInvaildDateKeyLabel.superview.mas_left).offset(10);
        make.width.mas_equalTo(certDateESize.width + 1);
        make.height.mas_equalTo(certDateESize.height);
    }];

    UILabel *invaildDateValueLabel = [[UILabel alloc] init];
    invaildDateValueLabel.text = certInfo.certEndDate;
    invaildDateValueLabel.font = [UIFont systemFontOfSize:14];
    invaildDateValueLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    [contentView addSubview:invaildDateValueLabel];
    [invaildDateValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(maxWidth + 10 + 2);
        make.top.mas_equalTo(certInvaildDateKeyLabel.mas_top);
        make.bottom.mas_equalTo(certInvaildDateKeyLabel.mas_bottom);
        make.right.mas_equalTo(invaildDateValueLabel.superview.mas_right).offset(-10);
    }];

    UILabel *signDateKeyLabel = [[UILabel alloc] init];
    signDateKeyLabel.text = FSLocalizedString(@"kSignDate");
    signDateKeyLabel.font = [UIFont systemFontOfSize:14];
    signDateKeyLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    [contentView addSubview:signDateKeyLabel];
    [signDateKeyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(certInvaildDateKeyLabel.mas_bottom).offset(5);
        make.left.mas_equalTo(signDateKeyLabel.superview.mas_left).offset(10);
        make.width.mas_equalTo(signDateSize.width + 1);
        make.height.mas_equalTo(signDateSize.height);
    }];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    UILabel *signDateValueLabel = [[UILabel alloc] init];
    signDateValueLabel.text = [dateFormatter stringFromDate:[Utility convertFSDateTime2NSDate:certInfo.signDate]];
    signDateValueLabel.font = [UIFont systemFontOfSize:14];
    signDateValueLabel.textColor = [UIColor colorWithRGBHex:0x8A8A8A];
    [contentView addSubview:signDateValueLabel];
    [signDateValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(maxWidth + 10 + 2);
        make.top.mas_equalTo(signDateKeyLabel.mas_top);
        make.bottom.mas_equalTo(signDateKeyLabel.mas_bottom);
        make.right.mas_equalTo(signDateValueLabel.superview.mas_right).offset(-10);
    }];

    return contentView;
}

- (void)addDigitalSign:(FSSignature *)sig signArea:(FSRectF *)rect signImagePath:(NSString *)imagePath {
    FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
    selectDestination.isRootFileDirectory = YES;
    selectDestination.fileOperatingMode = FileListMode_Select;
    [selectDestination loadFilesWithPath:DOCUMENT_PATH];
    selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder) {
        [controller dismissViewControllerAnimated:YES completion:nil];
        __block void (^inputFileName)() = ^() {
            InputAlertView *inputAlertView = [[InputAlertView alloc] initWithTitle:@"kInputNewFileName"
                                                                           message:nil
                                                                buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                                                                    if (buttonIndex == 0) {
                                                                        return;
                                                                    }
                                                                    InputAlertView *inputAlert = (InputAlertView *) alertView;
                                                                    NSString *fileName = inputAlert.inputTextField.text;

                                                                    if ([fileName rangeOfString:@"/"].location != NSNotFound) {
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning"
                                                                                                                            message:@"kIllegalNameWarning"
                                                                                                                 buttonClickHandler:^(UIView *alertView, int buttonIndex) {
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
                                                                        NSString *selectSig = [AnnotationSignature getSignatureSelected];
                                                                        AnnotationSignature *signature = [AnnotationSignature getSignature:selectSig];

                                                                        DIGITALSIGNATURE_PARAM *param = [[DIGITALSIGNATURE_PARAM alloc] init];
                                                                        param.certFile = [SIGNATURE_PATH stringByAppendingPathComponent:signature.certMD5];
                                                                        param.certPwd = signature.certPasswd;
                                                                        param.subfilter = @"adbe.pkcs7.detached";
                                                                        param.imagePath = imagePath;
                                                                        param.rect = rect;
                                                                        param.sigName = signature.name;
                                                                        param.signFilePath = pdfFilePath;
                                                                        [self.signToolHandler initSignature:sig withParam:param];
                                                                        [[NSFileManager defaultManager] removeItemAtPath:param.imagePath error:nil];
                                                                        BOOL isSuccess = [self.signToolHandler signSignature:sig withParam:param];
                                                                        if (isSuccess) {
                                                                            double delayInSeconds = 0.4;
                                                                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {

                                                                                AlertView *alertView = [[AlertView alloc] initWithTitle:@""
                                                                                                                                message:@"kSaveSignedDocSuccess"
                                                                                                                     buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                                                                                                                         double delayInSeconds = 0.4;
                                                                                                                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                                                                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                                                                                             if (self.signToolHandler.docChanging) {
                                                                                                                                 self.signToolHandler.docChanging(pdfFilePath);
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
                                                                    NSFileManager *fileManager = [[NSFileManager alloc] init];
                                                                    if ([fileManager fileExistsAtPath:pdfFilePath]) {
                                                                        double delayInSeconds = 0.3;
                                                                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                                            AlertView *alert = [[AlertView alloc] initWithTitle:@"kWarning"
                                                                                                                        message:@"kFileAlreadyExists"
                                                                                                             buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                                                                                                                 if (buttonIndex == 0) {
                                                                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                         inputFileName();
                                                                                                                     });
                                                                                                                 } else {
                                                                                                                     [fileManager removeItemAtPath:pdfFilePath error:nil];
                                                                                                                     createPDF(pdfFilePath);
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
    typeof(selectDestination) __weak weakSelectDestination = selectDestination;
    selectDestination.cancelHandler = ^{
        [weakSelectDestination dismissViewControllerAnimated:YES completion:nil];
    };
    UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:selectDestinationNavController
                                     animated:YES
                                   completion:nil];
}

- (void)sign {
    if (!_isAdded) {
        self.currentSelectSign = nil;
        _annotImage = nil;
        _isAdded = NO;

        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.signature.rect pageIndex:self.signature.pageIndex];
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:self.signature.pageIndex needRender:YES];
        return;
    }

    BOOL isSaveTip = [Preference getBoolValue:Module_Signature type:@"SignSaveTip" delaultValue:NO];
    if (!isSaveTip) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm"
                                                        message:@"kConfirmSign"
                                             buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                                                 if (buttonIndex == 0) { // no
                                                     [self deleteSign];
                                                 } else if (buttonIndex == 1) { // yes
                                                     [self addSign];
                                                     [Preference setBoolValue:Module_Signature type:@"SignSaveTip" value:YES];
                                                 }
                                             }
                                              cancelButtonTitle:@"kNo"
                                              otherButtonTitles:@"kYes", nil];
        [alertView show];
    } else {
        [self addSign];
    }
}

- (void)addSign {
    FSSignature *sig = self.currentSelectSign;
    NSString *selectSig = [AnnotationSignature getSignatureSelected];
    AnnotationSignature *signnature = [AnnotationSignature getSignature:selectSig];
    if (signnature.certMD5 && signnature.certPasswd && signnature.certFileName) {
        NSString *imagePath = [SIGNATURE_PATH stringByAppendingPathComponent:[selectSig stringByAppendingString:@"_i"]];
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:self.editAnnot.pageIndex];
        UIImage *tmpImage = [Utility scaleToSize:[UIImage imageWithContentsOfFile:imagePath] size:rect.size];
        NSString *tmpPath = [imagePath stringByAppendingString:@"_tmp"];
        [UIImagePNGRepresentation(tmpImage) writeToFile:tmpPath atomically:YES];

        [self addDigitalSign:sig signArea:self.editAnnot.fsrect signImagePath:tmpPath];
    }
    self.annotImage = nil;
    [_extensionsManager setCurrentAnnot:nil];
}

- (void)signList {
    self.shouldShowMenu = NO;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact) {
        [rootViewController presentViewController:self.signatureListCtr
                                         animated:YES
                                       completion:^{
                                           self.isShowList = YES;
                                       }];
    } else {
        UIPopoverController *popoverCtr = [[UIPopoverController alloc] initWithContentViewController:self.signatureListCtr];
        self.popoverCtr = popoverCtr;
        [popoverCtr setPopoverContentSize:CGSizeMake(300, 420)];
        popoverCtr.delegate = self;

        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:self.editAnnot.pageIndex];
        [popoverCtr presentPopoverFromRect:rect inView:rootViewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        self.isShowList = YES;
    }

    self.signatureListCtr.delegate = self;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.isShowList = NO;
    _signatureListCtr = nil;
    if (self.signature) {
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    } else {
        [_extensionsManager setCurrentAnnot:nil];
    }
}

- (void)deleteSign {
    _isAdded = NO;
    self.annotImage = nil;
    self.signature = nil;

    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:self.editAnnot.pageIndex];
    newRect = CGRectInset(newRect, -30, -30);
    [_pdfViewCtrl refresh:newRect pageIndex:self.editAnnot.pageIndex needRender:NO];
    [_extensionsManager setCurrentAnnot:nil];
}

- (void)onAnnotDeselected:(FSAnnot *)annot {
    self.currentSelectSign = nil;
    _annotImage = nil;
    if (_isAdded) {
        [self deleteSign];
        _isAdded = NO;
    }
    MenuControl *annotMenu = _extensionsManager.menuControl;
    if (annotMenu.isMenuVisible) {
        [annotMenu setMenuVisible:NO animated:YES];
    }
}

- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    if (_extensionsManager.currentAnnot == annot) {
        CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
            if (self.shouldShowMenu)
                [self showAnnotMenu];
            return YES;
        } else {
            if (_isAdded) {
                [self deleteSign];
            } else {
                _annotImage = nil;
                _isAdded = NO;
                [_extensionsManager setCurrentAnnot:nil];
            }
            return YES;
        }
    } else {
        [_extensionsManager setCurrentAnnot:annot];
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot *)annot {
    if ([_extensionsManager getAnnotHandlerByAnnot:annot] == self) {
        CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context annot:(FSAnnot *)annot {
    if (_extensionsManager.currentAnnot == annot && pageIndex == annot.pageIndex && _isAdded) {
        if (self.annotImage) {
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            UIImage *image = [Utility scaleToSize:self.annotImage size:rect.size];
            CGContextSaveGState(context);

            CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
            CGContextTranslateCTM(context, 0, rect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
            CGContextDrawImage(context, rect, [image CGImage]);

            CGContextRestoreGState(context);
        }
    }
}

- (void)onDocWillOpen {
    _signViewCtr = nil;
    self.signature = nil;
    _isShowList = NO;
    [self.digitalSignDic removeAllObjects];
}

#pragma mark IRotateChangedListener

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissAnnotMenu];
    if (_isShowList) {
        [self.signatureListCtr dismissViewControllerAnimated:NO
                                                  completion:^{
                                                      _signatureListCtr = nil;
                                                  }];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self showAnnotMenu];
    if (_isShowList) {
        [self signList];
    }
}

#pragma mark IScrollViewEventListener

- (void)onScrollViewWillBeginDragging:(UIScrollView *)dviewer {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)dviewer willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)dviewer {
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)dviewer {
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)dviewer {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)dviewer {
    double delayInSeconds = .2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self showAnnotMenu];
    });
}

- (void)showAnnotMenu {
    if (self.shouldShowMenu) {
        if (_extensionsManager.currentAnnot == self.editAnnot && [_extensionsManager getAnnotHandlerByAnnot:_extensionsManager.currentAnnot] == self) {
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:self.editAnnot.pageIndex];
            CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.editAnnot.pageIndex];
            MenuControl *annotMenu = _extensionsManager.menuControl;
            [annotMenu setRect:showRect];
            [annotMenu showMenu];
        }
    }
}

- (void)dismissAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot && [_extensionsManager getAnnotHandlerByAnnot:_extensionsManager.currentAnnot] == self) {
        MenuControl *annotMenu = _extensionsManager.menuControl;
        if (annotMenu.isMenuVisible) {
            [annotMenu setMenuVisible:NO animated:YES];
        }
    }
}

#pragma mark SignatureListDelegate

- (void)signatureListViewController:(SignatureListViewController *)signatureListViewController openSignature:(AnnotationSignature *)signature {
    self.isShowList = NO;

    [signatureListViewController dismissViewControllerAnimated:YES
                                                    completion:^{
                                                        _signatureListCtr = nil;
                                                        self.isShowList = NO;
                                                    }];
    SignatureViewController *signatureCtr = [[SignatureViewController alloc] initWithUIExtensionsManager:_extensionsManager];
    self.signViewCtr = signatureCtr;
    signatureCtr.modalPresentationStyle = UIModalPresentationOverFullScreen;
    signatureCtr.currentSignature = signature;
    signatureCtr.isFieldSig = YES;
    DigitalSignatureAnnotHandler *__weak weakSelf = self;
    signatureCtr.saveHandler = ^{
        NSString *selectSig = [AnnotationSignature getSignatureSelected];
        AnnotationSignature *signnature = [AnnotationSignature getSignature:selectSig];
        DigitalSignatureAnnotHandler *strongSelf = weakSelf;
        assert(strongSelf);
        strongSelf->_isAdded = YES;
        strongSelf.signature = signnature;
        strongSelf.annotImage = [AnnotationSignature getSignatureImage:signnature.name];

        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:strongSelf.editAnnot.fsrect pageIndex:strongSelf.editAnnot.pageIndex];
        newRect = CGRectInset(newRect, -30, -30);
        [strongSelf->_pdfViewCtrl refresh:newRect pageIndex:self.editAnnot.pageIndex needRender:YES];
        strongSelf.shouldShowMenu = YES;
        [strongSelf showAnnotMenu];
    };
    signatureCtr.cancelHandler = ^{
        DigitalSignatureAnnotHandler *strongSelf = weakSelf;
        assert(strongSelf);
        if (strongSelf.signature) {
            strongSelf.shouldShowMenu = YES;
            [strongSelf showAnnotMenu];
        } else {
            [strongSelf->_extensionsManager setCurrentAnnot:nil];
        }
    };
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:signatureCtr
                                     animated:NO
                                   completion:^{

                                   }];
}

- (void)signatureListViewController:(SignatureListViewController *)signatureListViewController deleteSignature:(AnnotationSignature *)signature {
    if ([self.signature.name isEqualToString:signature.name]) {
        [self deleteSign];
        if ([AnnotationSignature getCertSignatureList].count < 1) {
            [signatureListViewController dismissViewControllerAnimated:YES
                                                            completion:^{
                                                                _signatureListCtr = nil;
                                                                self.isShowList = NO;
                                                            }];
        }
    }
}

- (void)signatureListViewController:(SignatureListViewController *)signatureListViewController selectSignature:(AnnotationSignature *)signature {
    NSString *selectSig = [AnnotationSignature getSignatureSelected];
    AnnotationSignature *signnature = [AnnotationSignature getSignature:selectSig];
    if (signnature.certMD5 && signnature.certPasswd && signnature.certFileName) {
        _isAdded = YES;
        self.signature = signnature;
        self.annotImage = [AnnotationSignature getSignatureImage:signnature.name];

        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:self.editAnnot.pageIndex];
        newRect = CGRectInset(newRect, -30, -30);
        [_pdfViewCtrl refresh:newRect pageIndex:self.editAnnot.pageIndex needRender:NO];
    }
    self.isShowList = NO;
    self.shouldShowMenu = YES;
    [self showAnnotMenu];
}

- (void)cancelSignature {
    _signatureListCtr = nil;
    if (self.signature) {
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    } else {
        [_extensionsManager setCurrentAnnot:nil];
    }
    self.isShowList = NO;
}

@end
