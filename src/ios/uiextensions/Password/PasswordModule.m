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

#import "PasswordModule.h"
#import "../Common/UIExtensionsSharedHeader.h"
#import "EncryptOptionViewController.h"
#import "MenuGroup.h"
#import "MvMenuItem.h"

@interface PasswordSecurityInfo : NSObject
@property (nonatomic, copy) NSString *openPassword;
@property (nonatomic, copy) NSString *ownerPassword;
@property (nonatomic, assign) BOOL allowPrint;
@property (nonatomic, assign) BOOL allowPrintHigh;
@property (nonatomic, assign) BOOL allowFillForm;
@property (nonatomic, assign) BOOL allowAddAnnot;
@property (nonatomic, assign) BOOL allowAssemble;
@property (nonatomic, assign) BOOL allowModify;
@property (nonatomic, assign) BOOL allowCopyForAccess;
@property (nonatomic, assign) BOOL allowCopy;

- (id)initWithOpenPassword:(NSString *)openPassword ownerPassword:(NSString *)ownerPassword print:(BOOL)print printHigh:(BOOL)printHigh fillForm:(BOOL)fillForm addAnnot:(BOOL)addAnnot assemble:(BOOL)assemble modify:(BOOL)modify copyForAccess:(BOOL)copyForAccess copy:(BOOL)copy;
@end

@implementation PasswordSecurityInfo

- (id)initWithOpenPassword:(NSString *)openPassword ownerPassword:(NSString *)ownerPassword print:(BOOL)print printHigh:(BOOL)printHigh fillForm:(BOOL)fillForm addAnnot:(BOOL)addAnnot assemble:(BOOL)assemble modify:(BOOL)modify copyForAccess:(BOOL)copyForAccesst copy:(BOOL)copy {
    if (self = [super init]) {
        self.openPassword = openPassword;
        self.ownerPassword = ownerPassword;
        self.allowPrint = print;
        self.allowPrintHigh = printHigh;
        self.allowFillForm = fillForm;
        self.allowAddAnnot = addAnnot;
        self.allowAssemble = assemble;
        self.allowModify = modify;
        self.allowCopy = copy;
        self.allowCopyForAccess = copyForAccesst;
    }
    return self;
}

@end

typedef void (^PasswordCallBack)(BOOL isInputed, NSString *password);

@interface PasswordModule () <IMvCallback, IDocEventListener>
@property (nonatomic, strong) PasswordSecurityInfo *securityInfo;
@property (nonatomic, copy) PasswordCallBack passwordCallback;
@property (nonatomic, strong) TSAlertView *currentAlertView;
@property (nonatomic, assign) FSPasswordType passwordType;
@property (nonatomic, strong) NSObject *currentVC;
@end

@implementation PasswordModule {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
}

- (instancetype)initWithExtensionsManager:(UIExtensionsManager *)extensionsManager {
    if (self = [super init]) {
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _extensionsManager = extensionsManager;

        self.passwordCallback = nil;
        self.inputPassword = nil;
        self.passwordType = e_pwdInvalid;

        if (_extensionsManager.modulesConfig.loadEncryption) {
            MenuGroup *group = [_extensionsManager.more getGroup:TAG_GROUP_PROTECT];
            if (!group) {
                group = [[MenuGroup alloc] init];
                group.tag = TAG_GROUP_PROTECT;

                group.title = FSLocalizedString(@"kSecurity");
                [_extensionsManager.more addGroup:group];
            }
            MvMenuItem *pwdItem = [[MvMenuItem alloc] init];
            pwdItem.tag = TAG_ITEM_PASSWORD;
            pwdItem.text = FSLocalizedString(@"kEncryption");
            pwdItem.callBack = self;
            [_extensionsManager.more addMenuItem:TAG_GROUP_PROTECT withItem:pwdItem];
        }

        [_pdfViewCtrl registerDocEventListener:self];
    }
    return self;
}

#pragma mark - TSAlertViewDelegate

- (void)alertView:(TSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.currentAlertView = nil;

    BOOL isCancelled = (buttonIndex == 0);
    self.inputPassword = isCancelled ? nil : alertView.inputTextField.text;

    if (self.passwordCallback) {
        self.passwordCallback(!isCancelled, self.inputPassword);
    }
}

// prompt an alert view to input user password
- (void)promptForPasswordWithTitle:(NSString *)title callback:(PasswordCallBack)callback {
    self.passwordCallback = callback;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentAlertView = [self createAlertViewToInputPassword];
        self.currentAlertView.tag = 2; // user password
        self.currentAlertView.title = title;
        [self.currentAlertView show];
    });
}

- (void)tryLoadPDFDocument:(FSPDFDoc *)document guessPassword:(NSString *)guessPassword success:(void (^)(NSString *password))success error:(void (^)(NSString *description))error abort:(void (^)())abort {
    self.pdfDoc = document;
    __weak typeof(self) weakSelf = self;
    FSErrorCode status = [document load:guessPassword];
    if (status == e_errSuccess) {
        if (success) {
            success(guessPassword);
        }
    } else if (status == e_errPassword) {
        NSString *title = guessPassword ? FSLocalizedString(@"kDocPasswordError") : FSLocalizedString(@"kDocNeedPassword");
        [self promptForPasswordWithTitle:title
                                callback:^(BOOL isInputed, NSString *newPassword) {
                                    if (isInputed) {
                                        [weakSelf tryLoadPDFDocument:document guessPassword:newPassword success:success error:error abort:abort];
                                    } else if (abort) {
                                        abort();
                                    }
                                }];
    } else {
        if (error) {
            error([Utility getErrorCodeDescription:status]);
        }
    }
}

- (TSAlertView *)createAlertViewToInputPassword {
    TSAlertView *alertView = [[TSAlertView alloc] init];
    [alertView addButtonWithTitle:FSLocalizedString(@"kCancel")];
    [alertView addButtonWithTitle:FSLocalizedString(@"kOK")];
    UIButton *sureBtn = alertView.buttons.lastObject;
    sureBtn.enabled = NO;
    alertView.style = TSAlertViewStyleInputText;
    alertView.buttonLayout = TSAlertViewButtonLayoutNormal;
    alertView.usesMessageTextView = NO;
    alertView.inputTextField.secureTextEntry = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputTextFieldChange:) name:UITextFieldTextDidChangeNotification object:alertView.inputTextField];
    alertView.delegate = self;
    [sureBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    return alertView;
}

- (void)inputTextFieldChange:(NSNotification *)aNotification {
    if ([self.currentAlertView.inputTextField isEqual:aNotification.object]) {
        UIButton *sureBtn = self.currentAlertView.buttons.lastObject;
        if (((UITextField *) aNotification.object).text.length != 0) {
            sureBtn.enabled = YES;
            [sureBtn setTitleColor:[UIColor colorWithRed:0 / 255.0 green:122.0 / 255.0 blue:255.0 / 255.0 alpha:1] forState:UIControlStateNormal];
        } else {
            sureBtn.enabled = NO;
            [sureBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - IMvCallback

- (void)onClick:(MvMenuItem *)item {
    item.enable = NO;
    BOOL isDigitalSignatureDoc = ([self.pdfDoc getSignatureCount] > 0);
    if (isDigitalSignatureDoc) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kHadProtect" message:nil buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
        self.currentVC = alertView;
        [alertView show];
        item.enable = YES;
        return;
    }

    if ([item.text isEqualToString:FSLocalizedString(@"kEncryption")]) {
        [self handleEncryptDocument];
    } else {
        [self handleRemoveEncryption];
    }
    item.enable = YES;
}

- (BOOL)isOwner {
    if (self.passwordType == e_pwdInvalid) {
        [self updatePasswordType];
    }
    if (self.passwordType == e_pwdNoPassword ||
        self.passwordType == e_pwdOwner) {
        return YES;
    }
    return NO;
}

- (BOOL)encryptDocument:(FSPDFDoc *)doc {
    NSString *originalPDFPath = _pdfViewCtrl.filePath;
    NSString *encryptedPDFPath = nil;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isOK = NO;

    @autoreleasepool {
        FSStdSecurityHandler *stdSecurityHandler = [[FSStdSecurityHandler alloc] init];
        int userPermissions = [self permissionsFromInfo];
        isOK = [stdSecurityHandler initialize:userPermissions userPassword:self.securityInfo.openPassword ownerPassword:self.securityInfo.ownerPassword cipher:e_cipherAES keyLen:16 encryptMetadata:YES];
        if (isOK) {
            isOK = [doc setSecurityHandler:stdSecurityHandler];
        }

        if (isOK) {
            NSString *fileName = [originalPDFPath lastPathComponent] ?: @".pdf";
            encryptedPDFPath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"_encryped_%@", fileName]];

            if ([fileManager fileExistsAtPath:encryptedPDFPath]) {
                [fileManager removeItemAtPath:encryptedPDFPath error:nil];
            }
            isOK = [doc saveAs:encryptedPDFPath saveFlags:e_saveFlagNormal];
        }
        if (isOK) {
            isOK = [fileManager removeItemAtPath:originalPDFPath error:nil];
        }
        if (isOK) {
            isOK = [fileManager moveItemAtPath:encryptedPDFPath toPath:originalPDFPath error:nil];
        }
        if (isOK) {
            NSString *password = self.securityInfo.ownerPassword ?: self.securityInfo.openPassword;
            [_pdfViewCtrl openDoc:originalPDFPath password:password completion:nil];
        }
    }
    return isOK;
}

- (BOOL)removeEncrypt:(FSPDFDoc *)pdfDoc {
    BOOL isOK = NO;
    NSString *decryptedPDFPath = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    @autoreleasepool {
        isOK = [pdfDoc removeSecurity];
        if (isOK) {
            NSString *fileName = [_pdfViewCtrl.filePath lastPathComponent];
            decryptedPDFPath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"_decryped_%@", fileName]];
            if ([fileManager fileExistsAtPath:decryptedPDFPath isDirectory:nil]) {
                [fileManager removeItemAtPath:decryptedPDFPath error:nil];
            }
            isOK = [pdfDoc saveAs:decryptedPDFPath saveFlags:e_saveFlagNormal];
        }
        if (isOK) {
            isOK = [fileManager removeItemAtPath:_pdfViewCtrl.filePath error:nil];

            if (isOK) {
                isOK = [fileManager moveItemAtPath:decryptedPDFPath toPath:_pdfViewCtrl.filePath error:nil];
            }
        }
        if (isOK) {
            [_pdfViewCtrl openDoc:_pdfViewCtrl.filePath password:nil completion:nil];
        }
    }

    return isOK;
}

#pragma mark - IDocEventListener

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    if (error != e_errSuccess)
        return;
    self.pdfDoc = document;

    [self updatePasswordType];

    NSString *text = FSLocalizedString(@"kEncryption");
    if (self.passwordType == e_pwdUser ||
        self.passwordType == e_pwdOwner) {
        text = FSLocalizedString(@"kDecryption");
    }
    [self updateItemText:text];
}

- (void)onDocWillClose:(FSPDFDoc *)document {
    if (self.currentVC) {
        if ([self.currentVC isKindOfClass:[AlertView class]]) {
            [(AlertView *) self.currentVC dismissWithClickedButtonIndex:0 animated:NO];
        } else if ([self.currentVC isKindOfClass:[EncryptOptionViewController class]]) {
            if ([((EncryptOptionViewController *) self.currentVC).currentVC isKindOfClass:[AlertView class]]) {
                AlertView *alert = (AlertView *) ((EncryptOptionViewController *) self.currentVC).currentVC;
                [alert dismissWithClickedButtonIndex:0 animated:NO];
            }
            ((EncryptOptionViewController *) self.currentVC).currentVC = nil;
            [(EncryptOptionViewController *) self.currentVC dismissViewControllerAnimated:NO completion:nil];
        }
        self.currentVC = nil;
    }
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    self.passwordType = e_pwdInvalid;
    @autoreleasepool {
        self.pdfDoc = nil;
    }
}

#pragma mark - encrypt document

- (void)handleEncryptDocument {
    EncryptOptionViewController *encryptOptionCtrl = [[EncryptOptionViewController alloc] initWithNibName:@"EncryptOptionViewController" bundle:nil];
    self.currentVC = encryptOptionCtrl;

    encryptOptionCtrl.optionHandler = ^(EncryptOptionViewController *ctrl, BOOL isCancel, NSString *openPassword, NSString *ownerPassword, BOOL print, BOOL printHigh, BOOL fillForm, BOOL addAnnot, BOOL assemble, BOOL modify, BOOL copyForAccess, BOOL copy) {
        if (isCancel)
            return;
        if (openPassword == nil && ownerPassword == nil) {
            return;
        }

        self.securityInfo = [[PasswordSecurityInfo alloc] initWithOpenPassword:openPassword ownerPassword:ownerPassword print:print printHigh:printHigh fillForm:fillForm addAnnot:addAnnot assemble:assemble modify:modify copyForAccess:copyForAccess copy:copy];

        __weak typeof(self) weakSelf = self;
        if ([self.pdfDoc isModified]) { // whether to save before encryption?
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm"
                                                            message:@"Do you want to save document before encryption?"
                                                 buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                                                     BOOL shouldSaveChanges = (buttonIndex == 1);
                                                     if (!shouldSaveChanges) {
                                                         FSPDFDoc *pdfDoc = [[FSPDFDoc alloc] initWithFilePath:_pdfViewCtrl.filePath];
                                                         FSErrorCode error = [pdfDoc load:weakSelf.inputPassword];
                                                         if (error == e_errSuccess) {
                                                             weakSelf.pdfDoc = pdfDoc;
                                                         } else {
                                                             //todo
                                                         }
                                                     }
                                                     [weakSelf encryptDocument:weakSelf.pdfDoc];

                                                 }
                                                  cancelButtonTitle:@"kNo"
                                                  otherButtonTitles:@"kYes", nil];
            self.currentVC = alertView;
            [alertView show];
        } else {
            [self encryptDocument:openPassword ownerPassword:ownerPassword print:print printHigh:printHigh fillForm:fillForm addAnnot:addAnnot modify:modify assemble:assemble copyForAccess:copyForAccess copy:copy];
        }
    };

    // show permission setting option
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *encryptOptionNavCtrl = [[UINavigationController alloc] initWithRootViewController:encryptOptionCtrl];
        encryptOptionNavCtrl.delegate = encryptOptionCtrl;
        if (DEVICE_iPHONE) {
            encryptOptionNavCtrl.modalPresentationStyle = UIModalPresentationCustom;
        } else {
            encryptOptionNavCtrl.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootViewController.view.subviews.count == 1 && [rootViewController.view.subviews.firstObject isKindOfClass:[TSAlertView class]]) {
            [(TSAlertView *) rootViewController.view.subviews.firstObject dismissWithClickedButtonIndex:0 animated:NO];
        }
        rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:encryptOptionNavCtrl animated:YES completion:nil];
    });
}

- (void)encryptDocument:(NSString *)openPassword ownerPassword:(NSString *)ownerPassword print:(BOOL)print printHigh:(BOOL)printHigh fillForm:(BOOL)fillForm addAnnot:(BOOL)addAnnot modify:(BOOL)modify assemble:(BOOL)assemble copyForAccess:(BOOL)copyForAccess copy:(BOOL)copy {
    _extensionsManager.currentAnnot = nil;
    _extensionsManager.currentToolHandler = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL isOK = [self encryptDocument:self.pdfDoc];
            if (!isOK) {
                AlertViewButtonClickedHandler buttonClickedHandler = ^(UIView *alertView, int buttonIndex) {
                    if (buttonIndex == 0) { //no
                        //nothing to do
                    } else if (buttonIndex == 1) { //yes
                        [self encryptDocument:openPassword ownerPassword:ownerPassword print:print printHigh:printHigh fillForm:fillForm addAnnot:addAnnot modify:modify assemble:assemble copyForAccess:copyForAccess copy:copy];
                    }
                };
                AlertView *alertView = [[AlertView alloc] initWithTitle:@"kTryAgain" message:@"kEncryptAddFail" buttonClickHandler:buttonClickedHandler cancelButtonTitle:@"kNo" otherButtonTitles:@"kYes", nil];
                self.currentVC = alertView;
                [alertView show];
            } else {
                [self updatePasswordType];
                [self updateItemText:FSLocalizedString(@"kDecryption")];

                AlertView *alertView = [[AlertView alloc] initWithTitle:@"kSuccess" message:@"kEncryptAddSuccess" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
                self.currentVC = alertView;
                [alertView show];

                // if this file is encrypted by open doc password,
                // clear thumbnail cache. other cache is remained as user can still open it and see.
                if (openPassword != nil) {
                }
            }
        });
    });
}

- (void)handleRemoveEncryption {
    if (![self isEncrypted]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    typedef void (^SuccessCallback)();
    __block void (^promptForOwnerPassword)(NSString *title, SuccessCallback success) = ^(NSString *title, SuccessCallback success) {
        [weakSelf promptForPasswordWithTitle:title
                                    callback:^(BOOL isInputed, NSString *password) {
                                        if (isInputed) {
                                            BOOL isOwner = ([weakSelf.pdfDoc getPasswordType] == e_pwdNoPassword) || ([weakSelf.pdfDoc checkPassword:password] == e_pwdOwner);
                                            if (!isOwner) {
                                                promptForOwnerPassword(FSLocalizedString(@"kDocPasswordError"), success);
                                            } else if (success) {
                                                promptForOwnerPassword = nil; // fix strong-reference-cycle
                                                success();
                                            }
                                        } else {
                                            promptForOwnerPassword = nil; // fix strong-reference-cycle
                                        }
                                    }];
    };
    void (^tryRemoveEncryption)() = ^{
        if ([weakSelf isOwner]) {
            [weakSelf removeEncryption];
        } else {
            promptForOwnerPassword(FSLocalizedString(@"kDocNeedPassword"), ^{
                [weakSelf removeEncryption];
            });
        }
    };
    if ([self.pdfDoc isModified]) { // whether to save before remove encryption?
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm"
                                                        message:@"Do you want to save document before removing encryption?"
                                             buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                                                 BOOL shouldSaveChanges = (buttonIndex == 1);
                                                 if (!shouldSaveChanges) {
                                                     FSPDFDoc *pdfDoc = [[FSPDFDoc alloc] initWithFilePath:_pdfViewCtrl.filePath];
                                                     FSErrorCode error = [pdfDoc load:nil];
                                                     if (error == e_errSuccess) {
                                                         weakSelf.pdfDoc = pdfDoc;
                                                     } else {
                                                         //todo
                                                     }
                                                     self.currentVC = nil;
                                                 }
                                                 tryRemoveEncryption();
                                             }
                                              cancelButtonTitle:@"kNo"
                                              otherButtonTitles:@"kYes", nil];
        self.currentVC = alertView;
        [alertView show];
    } else {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm"
                                                        message:@"kEncryptRemovePass"
                                             buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                                                 if (buttonIndex == 0) { // no
                                                     // nothing to do
                                                 } else if (buttonIndex == 1) { // yes
                                                     tryRemoveEncryption();
                                                 }
                                                 self.currentVC = nil;
                                             }
                                              cancelButtonTitle:@"kNo"
                                              otherButtonTitles:@"kYes", nil];
        self.currentVC = alertView;
        [alertView show];
    }
}

- (void)removeEncryption {
    _extensionsManager.currentAnnot = nil;
    _extensionsManager.currentToolHandler = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL isOK = [self removeEncrypt:self.pdfDoc];
            if (!isOK) {
                AlertView *alertView = [[AlertView alloc] initWithTitle:@"kTryAgain"
                                                                message:@"kEncryptAddFail"
                                                     buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                                                         if (buttonIndex == 0) {
                                                             //nothing to do
                                                         } else if (buttonIndex == 1) { //yes
                                                             [self removeEncryption];
                                                         }
                                                     }
                                                      cancelButtonTitle:@"kNo"
                                                      otherButtonTitles:@"kYes", nil];
                self.currentVC = alertView;
                [alertView show];
            } else {
                [self updateItemText:FSLocalizedString(@"kEncryption")];

                AlertView *alertView = [[AlertView alloc] initWithTitle:@"kSuccess" message:@"kEncryptRemoveSuccess" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
                self.currentVC = alertView;
                [alertView show];
            }
        });
    });
}

#pragma mark - private method

- (BOOL)isEncrypted {
    return [self.pdfDoc getEncryptionType] == e_encryptPassword;
}

- (void)updatePasswordType {
    self.passwordType = [self.pdfDoc getPasswordType];
}

- (void)updateItemText:(NSString *)text {
    MenuGroup *securityGroup = [_extensionsManager.more getGroup:TAG_GROUP_PROTECT];
    for (MvMenuItem *item in [securityGroup getItems]) {
        if (item.tag == TAG_ITEM_PASSWORD) {
            item.text = text;
            break;
        }
    }
    [_extensionsManager.more reloadData];
}

- (int)permissionsFromInfo {
    unsigned int permission = 0x0;
    if (self.securityInfo.allowPrint)
        permission |= e_permPrint;
    if (self.securityInfo.allowPrintHigh)
        permission |= e_permPrint | e_permPrintHigh;
    if (self.securityInfo.allowFillForm)
        permission |= e_permFillForm;
    if (self.securityInfo.allowAddAnnot)
        permission |= e_permAnnotForm | e_permFillForm;
    if (self.securityInfo.allowAssemble)
        permission |= e_permAssemble;
    if (self.securityInfo.allowModify)
        permission |= e_permModify | e_permAssemble | e_permFillForm;
    if (self.securityInfo.allowCopyForAccess)
        permission |= e_permExtractAccess;
    if (self.securityInfo.allowCopy)
        permission |= e_permExtract | e_permExtractAccess;
    return permission;
}

@end
