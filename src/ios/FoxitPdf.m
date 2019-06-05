/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>
#import <uiextensionsDynamic/uiextensionsDynamic.h>

@interface PDFNavigationController : UINavigationController
@property (nonatomic, weak) UIExtensionsManager *extensionsManager;
@end

@interface FoxitPdf : CDVPlugin <IDocEventListener,UIExtensionsManagerDelegate>{
    // Member variables go here.
}
@property (nonatomic, strong) NSArray *topToolbarVerticalConstraints;
@property (nonatomic, strong) UIExtensionsManager *extensionsMgr;
@property (nonatomic, strong) FSPDFViewCtrl *pdfViewControl;
@property (nonatomic, strong) PDFNavigationController *pdfRootViewController;
@property (nonatomic, strong) UIViewController *pdfViewController;
@property (nonatomic, strong) FSPDFDoc *currentDoc;

@property (nonatomic, strong) CDVInvokedUrlCommand *pluginCommand;

@property (nonatomic, strong) NSString *filePathSaveTo;
@property (nonatomic, copy) NSString *filePassword;
@property (nonatomic, assign) BOOL isEnableAnnotations;

@property (nonatomic, strong) FSPDFDoc *tempDoc;

- (void)Preview:(CDVInvokedUrlCommand *)command;
@end

@implementation FoxitPdf
{
    NSString *tmpCommandCallbackID;
}
static FSFileListViewController *fileVC;
static FSErrorCode initializeCode = FSErrUnknown;
static NSString *initializeSN;
static NSString *initializeKey;
- (void)initialize:(CDVInvokedUrlCommand*)command{
    // init foxit sdk
    
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary *options = [command argumentAtIndex:0];
    if ([options isKindOfClass:[NSNull class]]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid license"];
        block();
        return;
    }
    self.isEnableAnnotations = YES;
    NSString *sn = options[@"foxit_sn"];
    NSString *key = options[@"foxit_key"];
    
    if (![initializeSN isEqualToString:sn] || ![initializeKey isEqualToString:key]) {
        if (initializeCode == FSErrSuccess) [FSLibrary destroy];
        initializeCode = [FSLibrary initialize:sn key:key];
        if (initializeCode != FSErrSuccess) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid license"];
            block();
            return;
        }else{
            initializeSN = sn;
            initializeKey = key;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Initialize succeeded"];
            block();
        }
        if (!fileVC) fileVC = [[FSFileListViewController alloc] init];
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Initialized"];
        block();
    }
}

- (void)openDocument:(CDVInvokedUrlCommand*)command{
    [self Preview:command];
}

- (void)setSavePath:(CDVInvokedUrlCommand*)command{
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    NSString *savePath = [options objectForKey:@"savePath"];
    self.filePathSaveTo = [self correctFilePath:savePath];
    
    CDVPluginResult *pluginResult = nil;
    if (self.filePathSaveTo) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"set savePath succeeded"];
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR  messageAsString:@"set savePath failed"];
    }
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

- (void)importFromFDF:(CDVInvokedUrlCommand*)command{
    
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSString *fdfPath = [options objectForKey:@"fdfPath"];
    fdfPath = [self correctFilePath:fdfPath];
    if (!fdfPath) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"fdfPath is not found"];
        block();
        return;
    }
    
    if (!self.pdfViewControl || !self.currentDoc || [self.currentDoc isEmpty]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"current doc is is empty"];
        block();
        return;
    }
    
    NSNumber *types = [options objectForKey:@"dataType"];
    NSArray *pageRange = [options objectForKey:@"pageRange"];
    
    FSFDFDoc *fdoc = [[FSFDFDoc alloc] initWithPath:fdfPath];
    if ([fdoc isEmpty]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"fdf doc is is empty"];
        block();
        return;
    }
    FSPDFDoc *doc = self.currentDoc;
    FSRange *range = [[FSRange alloc] init];
    
    for (int i = 0; i < pageRange.count; i++) {
        NSArray *rangeNum = pageRange[i];
        if ([rangeNum isKindOfClass:[NSArray class]] && rangeNum.count != 0) {
            int start = [(NSNumber *)rangeNum[0] intValue];
            int end = [(NSNumber *)rangeNum[1] intValue];
            [range addSegment:start end_index:start+end-1 filter:FSRangeAll];
        }
    }
    
    @try {
        BOOL flag = [doc importFromFDF:fdoc types:types.intValue page_range:range];
        if (flag) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Successfully import the fdf doc"];
            block();
            [self.extensionsMgr.pdfViewCtrl refresh];
            self.extensionsMgr.isDocModified = YES;
        }
    } @catch (NSException *exception) {
        NSLog(@"Import the FDF failed");
    }
}

- (void)exportToFDF:(CDVInvokedUrlCommand*)command{
    
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSString *exportPath = [options objectForKey:@"exportPath"];
    exportPath = [self correctFilePath:exportPath];
    if (!exportPath) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"exportPath is error"];
        block();
        return;
    }
    
    if (!self.pdfViewControl || !self.currentDoc || [self.currentDoc isEmpty]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"current doc is is empty"];
        block();
        return;
    }
    
    NSNumber *types = [options objectForKey:@"dataType"];
    NSArray *pageRange = [options objectForKey:@"pageRange"];
    NSNumber *fdfDocType = [options objectForKey:@"fdfDocType"];
    
    FSFDFDoc *fdoc = [[FSFDFDoc alloc] initWithType:fdfDocType.intValue];
    if ([fdoc isEmpty]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"fdf doc is is empty"];
        block();
        return;
    }
    FSPDFDoc *doc = self.currentDoc;
    FSRange *range = [[FSRange alloc] init];
    
    for (int i = 0; i < pageRange.count; i++) {
        NSArray *rangeNum = pageRange[i];
        if ([rangeNum isKindOfClass:[NSArray class]] && rangeNum.count != 0) {
            int start = [(NSNumber *)rangeNum[0] intValue];
            int end = [(NSNumber *)rangeNum[1] intValue];
            [range addSegment:start end_index:start+end-1 filter:FSRangeAll];
        }
    }
    
    @try {
        BOOL flag = [doc exportToFDF:fdoc types:types.intValue page_range:range];
        if (flag) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Successfully export the fdf doc"];
            block();
            [self.extensionsMgr.pdfViewCtrl refresh:self.extensionsMgr.pdfViewCtrl.getCurrentPage];
            if ([fdoc saveAs:exportPath]) {
                NSLog(@"Successfully save the fdf doc");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Successfully save the fdf doc"];
            }
        }else{
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Export the FDF failed"];
            block();
        }
    } @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Export the FDF failed"];
        block();
    }
}

- (void)Preview:(CDVInvokedUrlCommand*)command
{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
        block();
        return;
    }
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSLog(@"%@", docDir);
    
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    NSString *password = [options objectForKey:@"password"];
    password = [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (password.length >0 ) {
        self.filePassword = password;
    }
    
    // URL
    //    NSString *filePath = [command.arguments objectAtIndex:0];
    NSString *filePath = [options objectForKey:@"path"];
    
    // check file exist
    filePath = [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *fileURL = [[NSURL alloc] initWithString:filePath];
    [fileURL.path stringByRemovingPercentEncoding];
    
    BOOL isFileExist = [self isExistAtPath:fileURL.path];
    
    if (filePath != nil && filePath.length > 0 && isFileExist) {
        // preview
        [self FoxitPdfPreview:fileURL.path];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR  messageAsString:@"file not found"];
        block();
    }
}

- (void)enableAnnotations:(CDVInvokedUrlCommand*)command
{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
        block();
        return;
    }
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = nil;
    }
    id obj = [options objectForKey:@"enable"];
    BOOL val = obj?[obj boolValue]:YES;
    self.isEnableAnnotations = options?val:YES;
    
}

# pragma mark -- Foxit preview
-(void)FoxitPdfPreview:(NSString *)filePath {
    
    self.pdfViewControl = [[FSPDFViewCtrl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.pdfViewControl setRMSAppClientId:@"972b6681-fa03-4b6b-817b-c8c10d38bd20" redirectURI:@"com.foxitsoftware.com.mobilepdf-for-ios://authorize"];
    [self.pdfViewControl registerDocEventListener:self];
    
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"uiextensions_config" ofType:@"json"];
    UIExtensionsConfig* uiConfig = [[UIExtensionsConfig alloc] initWithJSONData:[NSData dataWithContentsOfFile:configPath]];
    if(self.isEnableAnnotations == NO) {
        uiConfig.loadAttachment = NO;
        uiConfig.tools = [[NSMutableSet<NSString *> alloc] initWithObjects:Tool_Select,Tool_Signature, nil];
    }
    self.extensionsMgr = [[UIExtensionsManager alloc] initWithPDFViewControl:self.pdfViewControl configurationObject:uiConfig];
    self.pdfViewControl.extensionsManager = self.extensionsMgr;
    self.extensionsMgr.delegate = self;
    
    //load doc
    if (filePath == nil) {
        filePath = [[NSBundle mainBundle] pathForResource:@"getting_started_ios" ofType:@"pdf"];
    }
    
    self.pdfViewController = [[UIViewController alloc] init];
    self.pdfViewController.view = self.pdfViewControl;
    
    self.pdfRootViewController = [[PDFNavigationController alloc] initWithRootViewController:self.pdfViewController];
    self.pdfRootViewController.navigationBarHidden = YES;
    self.pdfRootViewController.extensionsManager = self.extensionsMgr;
    
    if(self.filePathSaveTo && self.filePathSaveTo.length >0){
        self.extensionsMgr.preventOverrideFilePath = self.filePathSaveTo;
    }
    
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.pluginCommand.callbackId];
    };
    
    __weak FoxitPdf* weakSelf = self;
    [self.pdfViewControl openDoc:filePath
                        password:self.filePassword
                      completion:^(FSErrorCode error) {
                          if (error != FSErrSuccess) {
                              
                              pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                           messageAsDictionary:@{@"FSErrorCode":@(FSErrSuccess), @"info":@"failed open the pdf"}];
                              block();
                              
                              dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
                              
                              dispatch_after(delayTime, dispatch_get_main_queue(), ^{
                                  [weakSelf showAlertViewWithTitle:@"error" message:@"Failed to open the document"];
                                  [weakSelf.viewController dismissViewControllerAnimated:YES completion:nil];
                              });
                              
                              [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
                          }else{
                              self.currentDoc = self.pdfViewControl.currentDoc;
                              pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                           messageAsDictionary:@{@"FSErrorCode":@(FSErrSuccess), @"info":@"Open the document successfully"}];
                              block();
                              // Run later to avoid the "took a long time" log message.
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [weakSelf.viewController presentViewController:weakSelf.pdfRootViewController animated:YES completion:nil];
                              });
                          }
                      }];
    //    self.pdfViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self wrapTopToolbar];
    self.topToolbarVerticalConstraints = @[];
    
    self.extensionsMgr.goBack = ^() {
        [weakSelf.viewController dismissViewControllerAnimated:YES completion:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
    };
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleStatusBarOrientationChange:)
                                                name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
}

- (FSClientInfo *)getClientInfo {
    FSClientInfo *client_info = [[FSClientInfo alloc] init];
    client_info.device_id = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    client_info.device_name = [UIDevice currentDevice].name;
    client_info.device_model = [[UIDevice currentDevice] model];
    client_info.mac_address = @"mac_address";
    client_info.os = [NSString stringWithFormat:@"%@ %@",
                      [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
    client_info.product_name = @"RDK";
    client_info.product_vendor = @"Foxit";
    client_info.product_version = @"5.2.0";
    client_info.product_language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    return client_info;
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    });
}

#pragma mark - rotate event
- (void)handleStatusBarOrientationChange: (NSNotification *)notification{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self.extensionsMgr didRotateFromInterfaceOrientation:interfaceOrientation];
}

#pragma mark <IDocEventListener>

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    // Called when a document is opened.
    self.currentDoc = document;
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:@{@"type":@"onDocOpened", @"info":@"info", @"error":@(error)}];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.pluginCommand.callbackId];
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    // Called when a document is closed.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.currentDoc = nil;
    });
}

- (void)onDocWillSave:(FSPDFDoc *)document {
    self.currentDoc = document;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:@{@"type":@"onDocWillSave", @"info":@"info"}];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.pluginCommand.callbackId];
}

- (void)onDocSaved:(FSPDFDoc *)document error:(int)error{
    self.currentDoc = document;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:@{@"type":@"onDocSaved", @"info":@"info", @"error":@(error)}];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.pluginCommand.callbackId];
}

# pragma mark -- isExistAtPath
- (BOOL)isExistAtPath:(NSString *)filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    return isExist;
}

#pragma mark <UIExtensionsManagerDelegate>
- (void)uiextensionsManager:(UIExtensionsManager *)uiextensionsManager setTopToolBarHidden:(BOOL)hidden {
    UIToolbar *topToolbar = self.extensionsMgr.topToolbar;
    UIView *topToolbarWrapper = topToolbar.superview;
    id topGuide = self.pdfViewController.topLayoutGuide;
    assert(topGuide);
    
    [self.pdfViewControl removeConstraints:self.topToolbarVerticalConstraints];
    if (!hidden) {
        NSMutableArray *contraints = @[].mutableCopy;
        [contraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-0-[topToolbar(44)]"
                                                 options:0
                                                 metrics:nil
                                                   views:NSDictionaryOfVariableBindings(topToolbar, topGuide)]];
        [contraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topToolbarWrapper]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(topToolbarWrapper)]];
        self.topToolbarVerticalConstraints = contraints;
        
    } else {
        self.topToolbarVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[topToolbarWrapper]-0-[topGuide]"
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:NSDictionaryOfVariableBindings(topToolbarWrapper, topGuide)];
    }
    [self.pdfViewControl addConstraints:self.topToolbarVerticalConstraints];
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self.pdfViewControl layoutIfNeeded];
                     }];
}

- (void)wrapTopToolbar {
    // let status bar be translucent. top toolbar is top layout guide (below status bar), so we need a wrapper to cover the status bar.
    UIToolbar *topToolbar = self.extensionsMgr.topToolbar;
    [topToolbar setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    UIView *topToolbarWrapper = [[UIToolbar alloc] init];
    [topToolbarWrapper setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.pdfViewControl insertSubview:topToolbarWrapper belowSubview:topToolbar];
    [topToolbarWrapper addSubview:topToolbar];
    
    [self.pdfViewControl addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[topToolbarWrapper]-0-|"
                                             options:0
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(topToolbarWrapper)]];
    [topToolbarWrapper addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[topToolbar]-0-|"
                                             options:0
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(topToolbar)]];
    [topToolbarWrapper addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:[topToolbar]-0-|"
                                             options:0
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(topToolbar)]];
}

- (NSString *)correctFilePath:(NSString *)filePath{
    NSString *path = [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (path.length >0 ) {
        NSURL *filePathSaveTo = [NSURL fileURLWithPath:path];
        path = [filePathSaveTo.path stringByRemovingPercentEncoding];
        if ([path hasPrefix:@"/file:/"]) {
            path = [path stringByReplacingOccurrencesOfString:@"/file:" withString:@""];
        }
        return path;
    }
    return nil;
}

# pragma mark form
- (void)getAllFormFields:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    int fieldCount = [pForm getFieldCount:@""];
    NSMutableArray *tempArray = @[].mutableCopy;
    for (int i = 0; i < fieldCount; i++) {
        FSField* pFormField = [pForm getField:i filter:@""];
        
        NSString* name = [pFormField getName];
        FSFieldType fieldType = [pFormField getType];
        NSString* defValue = [pFormField getDefaultValue];
        NSString* value = [pFormField getValue];
        FSFieldFlags fieldFlag = [pFormField getFlags];
        
        NSMutableDictionary *tempField = @{}.mutableCopy;
        [tempField setObject:@(i) forKey:@"fieldIndex"];
        [tempField setObject:name forKey:@"name"];
        [tempField setObject:@(fieldType) forKey:@"fieldType"];
        [tempField setObject:defValue forKey:@"defValue"];
        [tempField setObject:value forKey:@"value"];
        [tempField setObject:@(fieldFlag) forKey:@"fieldFlag"];
        [tempField setObject:@(pFormField.alignment) forKey:@"alignment"];
        [tempField setObject:@(pFormField.alignment) forKey:@"alternateName"];
        
        NSMutableDictionary *defaultAppearance = @{}.mutableCopy;
        FSDefaultAppearance *fsdefaultappearance = pFormField.defaultAppearance;
        [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"flags"];
        [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"textSize"];
        [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"textColor"];
        [defaultAppearance setObject:[fsdefaultappearance.font getName] forKey:@"font"];
        
        [tempField setObject:defaultAppearance forKey:@"defaultAppearance"];
        [tempField setObject:pFormField.mappingName forKey:@"mappingName"];
        [tempField setObject:@(pFormField.maxLength) forKey:@"maxLength"];
        [tempField setObject:@(pFormField.topVisibleIndex) forKey:@"topVisibleIndex"];
        
        if (pFormField.options) {
            NSMutableArray *tempArray2 = @[].mutableCopy;
            for (int i = 0; i < [pFormField.options getSize]; i++)
            {
                FSChoiceOption *choiceoption = [pFormField.options getAt:i];
                NSMutableDictionary *tempChoiceoption = @{}.mutableCopy;
                [tempChoiceoption setObject:choiceoption.option_value forKey:@"optionValue"];
                [tempChoiceoption setObject:choiceoption.option_label forKey:@"optionLabel"];
                [tempChoiceoption setObject:@(choiceoption.selected) forKey:@"selected"];
                [tempChoiceoption setObject:@(choiceoption.default_selected) forKey:@"defaultSelected"];
                
                [tempArray2 addObject:tempChoiceoption];
            }
            
            [tempField setObject:tempArray2 forKey:@"choiceOptions"];
        }
        
        [tempArray addObject:tempField];
    }
    
    NSLog(@"%@",tempArray);
    
    if (tempArray == nil ) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"get form feilds faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:tempArray];
        block();
    }
}

- (void)getForm:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    
    NSMutableDictionary *tempFormInfo = @{}.mutableCopy;
    [tempFormInfo setObject:@(pForm.alignment) forKey:@"alignment"];
    [tempFormInfo setObject:@(pForm.needConstructAppearances) forKey:@"needConstructAppearances"];
    
    NSMutableDictionary *defaultAppearance = @{}.mutableCopy;
    FSDefaultAppearance *fsdefaultappearance = pForm.defaultAppearance;
    [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"flags"];
    [defaultAppearance setObject:@(fsdefaultappearance.text_size) forKey:@"textSize"];
    [defaultAppearance setObject:@(fsdefaultappearance.text_color) forKey:@"textColor"];
    [defaultAppearance setObject:[fsdefaultappearance.font getName] forKey:@"font"];
    [tempFormInfo setObject:defaultAppearance forKey:@"defaultAppearance"];
    
    NSLog(@"%@",tempFormInfo);
    
    if (tempFormInfo == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"get form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:tempFormInfo];
        block();
    }
}

- (void)updateForm:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    NSDictionary *formInfo = options[@"forminfo"];
    
    if (pForm.alignment != (int)formInfo[@"alignment"]) {
        pForm.alignment = (int)formInfo[@"alignment"];
    }
    
    if (pForm.needConstructAppearances != (BOOL)formInfo[@"needConstructAppearances"]) {
        [pForm setConstructAppearances:(BOOL)formInfo[@"needConstructAppearances"]];
    }
    
    NSMutableDictionary *defaultAppearance = @{}.mutableCopy;
    FSDefaultAppearance *fsdefaultappearance = pForm.defaultAppearance;
    [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"flags"];
    [defaultAppearance setObject:@(fsdefaultappearance.text_size) forKey:@"textSize"];
    [defaultAppearance setObject:@(fsdefaultappearance.text_color) forKey:@"textColor"];
    [defaultAppearance setObject:[fsdefaultappearance.font getName] forKey:@"font"];
    
    if (![defaultAppearance isEqual:options[@"defaultAppearance"]]) {
        FSFont *newFont = nil;
        if ([[fsdefaultappearance.font getName] isEqualToString:defaultAppearance[@"font"] ]) {
            newFont = [[FSFont alloc] initWithName:defaultAppearance[@"font"] styles:0 charset:FSFontCharsetDefault weight:0];
        }else{
            newFont = fsdefaultappearance.font;
        }
        FSDefaultAppearance *newfsdefaultappearance = [[FSDefaultAppearance alloc] initWithFlags:fsdefaultappearance.flags font:newFont text_size:fsdefaultappearance.text_size text_color:fsdefaultappearance.text_color];
        pForm.defaultAppearance = newfsdefaultappearance;
    }
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"update form info success"];
        block();
    }
}

- (void)formValidateFieldName:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int fSFieldType = (int)options[@"fSFieldType"];
    NSString *fieldName = options[@"field_name"];
    
    BOOL isCanbeUsed = [pForm validateFieldName:fSFieldType field_name:fieldName];
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isCanbeUsed];
        block();
    }
}

- (void)formRenameField:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int fieldIndex = (int)options[@"fieldIndex"];
    NSString *newFieldName = options[@"newFieldName"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    int fieldCount = [pForm getFieldCount:@""];
    
    BOOL isRenameSuccessed = NO;
    for (int i = 0; i < fieldCount; i++) {
        if (i == fieldIndex) {
            FSField* pFormField = [pForm getField:i filter:@""];
            isRenameSuccessed = [pForm renameField:pFormField new_field_name:newFieldName];
        }
    }
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isRenameSuccessed];
        block();
    }
}

- (void)formRemoveField:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int fieldIndex = (int)options[@"fieldIndex"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    int fieldCount = [pForm getFieldCount:@""];
    
    for (int i = 0; i < fieldCount; i++) {
        if (i == fieldIndex) {
            FSField* pFormField = [pForm getField:i filter:@""];
            [pForm removeField:pFormField];
        }
    }
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"remove field success"];
        block();
    }
}

- (void)formReset:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    BOOL isReset = [pForm reset];
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isReset];
        block();
    }
}

- (void)formExportToXML:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    NSString *filePath = options[@"filePath"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    BOOL isExport = [pForm exportToXML:filePath];
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isExport];
        block();
    }
}

- (void)formImportFromXML:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    NSString *filePath = options[@"filePath"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    BOOL isImport = [pForm importFromXML:filePath];
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isImport];
        block();
    }
}

- (void)formGetPageControls:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int pageIndex = (int)options[@"pageIndex"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    FSPDFPage *page = [self.currentDoc getPage:pageIndex];
    int pageControlCount = [pForm getControlCount:page];
    
    NSMutableArray *tempArr = @[].mutableCopy;
    for (int i = 0 ; i < pageControlCount; i++) {
        FSControl *pControl = [pForm getControl:page index:i];
        
        NSMutableDictionary *tempDic = @{}.mutableCopy;
        [tempDic setObject:@([pControl getIndex]) forKey:@"controlIndex"];
        [tempDic setObject:pControl.exportValue forKey:@"exportValue"];
        [tempDic setObject:@([pControl isChecked]) forKey:@"isChecked"];
        [tempDic setObject:@([pControl isDefaultChecked]) forKey:@"isDefaultChecked"];
        
        [tempArr addObject:tempDic];
    }
    
    NSLog(@"%@",tempArr);
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:tempArr];
        block();
    }
}

- (void)formRemoveControl:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int pageIndex = (int)options[@"pageIndex"];
    int controlIndex = (int)options[@"controlIndex"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    FSPDFPage *page = [self.currentDoc getPage:pageIndex];
    
    FSControl *pControl = [pForm getControl:page index:controlIndex];
    [pForm removeControl:pControl];
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"remove control success"];
        block();
    }
}

- (void)formAddControl:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int pageIndex = (int)options[@"pageIndex"];
    NSString *fieldName = options[@"fieldName"];
    int fieldType = (int)options[@"fieldType"];
    NSDictionary *rect = options[@"rect"];
    
    FSRectF *fsrect = [[FSRectF alloc] initWithLeft1:[rect[@"left"] floatValue] bottom1:[rect[@"bottom"] floatValue] right1:[rect[@"right"] floatValue] top1:[rect[@"top"] floatValue]];
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    FSPDFPage *page = [self.currentDoc getPage:pageIndex];
    
    FSControl *pControl = [pForm addControl:page field_name:fieldName field_type:fieldType rect:fsrect];
    
    NSMutableDictionary *tempDic = @{}.mutableCopy;
    [tempDic setObject:@([pControl getIndex]) forKey:@"controlIndex"];
    [tempDic setObject:pControl.exportValue forKey:@"exportValue"];
    [tempDic setObject:@([pControl isChecked]) forKey:@"isChecked"];
    [tempDic setObject:@([pControl isDefaultChecked]) forKey:@"isDefaultChecked"];
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:tempDic];
        block();
    }
}

- (void)formUpdateControl:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int pageIndex = (int)options[@"pageIndex"];
    int controlIndex = (int)options[@"controlIndex"];
    NSDictionary *control = options[@"control"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    FSPDFPage *page = [self.currentDoc getPage:pageIndex];
    
    FSControl *pControl = [pForm getControl:page index:controlIndex];
    
    if (![pControl.exportValue isEqualToString:control[@"exportValue"]]) {
        pControl.exportValue = control[@"exportValue"];
    }
    
    if (pControl.isChecked != (BOOL)control[@"isChecked"]) {
        [pControl setChecked:(BOOL)control[@"isChecked"]];
    }
    
    if (pControl.isDefaultChecked != (BOOL)control[@"isDefaultChecked"]) {
        [pControl setDefaultChecked:(BOOL)control[@"isDefaultChecked"]];
    }
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"update control info success"];
        block();
    }
}

- (void)getFieldByControl:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    int pageIndex = (int)options[@"pageIndex"];
    int controlIndex = (int)options[@"controlIndex"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    FSPDFPage *page = [self.currentDoc getPage:pageIndex];
    
    FSControl *pControl = [pForm getControl:page index:controlIndex];
    
    FSField *pFormField = [pControl getField];
    
    int fieldIndex = -1;
    int fieldCount = [pForm getFieldCount:@""];
    for (int i = 0; i < fieldCount; i++) {
        FSField *tempField = [pForm getField:i filter:@""];
        if (tempField.getType == pFormField.getType && [tempField.getName isEqualToString:pFormField.getName] ) {
            fieldIndex = i;
        }
    }
    
    NSString* name = [pFormField getName];
    FSFieldType fieldType = [pFormField getType];
    NSString* defValue = [pFormField getDefaultValue];
    NSString* value = [pFormField getValue];
    FSFieldFlags fieldFlag = [pFormField getFlags];
    
    NSMutableDictionary *tempField = @{}.mutableCopy;
    [tempField setObject:@(fieldIndex) forKey:@"fieldIndex"];
    [tempField setObject:name forKey:@"name"];
    [tempField setObject:@(fieldType) forKey:@"fieldType"];
    [tempField setObject:defValue forKey:@"defValue"];
    [tempField setObject:value forKey:@"value"];
    [tempField setObject:@(fieldFlag) forKey:@"fieldFlag"];
    [tempField setObject:@(pFormField.alignment) forKey:@"alignment"];
    [tempField setObject:@(pFormField.alignment) forKey:@"alternateName"];
    
    NSMutableDictionary *defaultAppearance = @{}.mutableCopy;
    FSDefaultAppearance *fsdefaultappearance = pFormField.defaultAppearance;
    [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"flags"];
    [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"textSize"];
    [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"textColor"];
    [defaultAppearance setObject:[fsdefaultappearance.font getName] forKey:@"font"];
    
    [tempField setObject:defaultAppearance forKey:@"defaultAppearance"];
    [tempField setObject:pFormField.mappingName forKey:@"mappingName"];
    [tempField setObject:@(pFormField.maxLength) forKey:@"maxLength"];
    [tempField setObject:@(pFormField.topVisibleIndex) forKey:@"topVisibleIndex"];
    
    if (pFormField.options) {
        NSMutableArray *tempArray2 = @[].mutableCopy;
        for (int i = 0; i < [pFormField.options getSize]; i++)
        {
            FSChoiceOption *choiceoption = [pFormField.options getAt:i];
            NSMutableDictionary *tempChoiceoption = @{}.mutableCopy;
            [tempChoiceoption setObject:choiceoption.option_value forKey:@"optionValue"];
            [tempChoiceoption setObject:choiceoption.option_label forKey:@"optionLabel"];
            [tempChoiceoption setObject:@(choiceoption.selected) forKey:@"selected"];
            [tempChoiceoption setObject:@(choiceoption.default_selected) forKey:@"defaultSelected"];
            
            [tempArray2 addObject:tempChoiceoption];
        }
        
        [tempField setObject:tempArray2 forKey:@"Choice"];
    }
    
    if (initializeCode == nil ) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"get form feilds faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:tempField];
        block();
    }
}


- (void)fSFieldUpdateField:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    int fieldIndex = (int)options[@"fieldIndex"];
    NSDictionary *fsfield = options[@"field"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    FSField *field = [pForm getField:fieldIndex filter:@""];
    
    field.value = fsfield[@"value"];
    field.topVisibleIndex = fsfield[@"topVisibleIndex"];
    [pForm renameField:field new_field_name:fsfield[@"name"]];
    
    field.maxLength = fsfield[@"maxLength"];
    field.mappingName = fsfield[@"mappingName"];
    //    field.fieldType = fsfield[@"fieldType"];
    field.flags = fsfield[@"fieldFlag"];
    field.defaultValue = fsfield[@"defValue"];
    field.alternateName = fsfield[@"alternateName"];
    field.alignment = fsfield[@"alignment"];
    
    //appearance
    NSMutableDictionary *defaultAppearance = @{}.mutableCopy;
    FSDefaultAppearance *fsdefaultappearance = field.defaultAppearance;
    [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"flags"];
    [defaultAppearance setObject:@(fsdefaultappearance.text_size) forKey:@"textSize"];
    [defaultAppearance setObject:@(fsdefaultappearance.text_color) forKey:@"textColor"];
    [defaultAppearance setObject:[fsdefaultappearance.font getName] forKey:@"font"];
    
    if (![defaultAppearance isEqual:options[@"defaultAppearance"]]) {
        FSFont *newFont = nil;
        if ([[fsdefaultappearance.font getName] isEqualToString:defaultAppearance[@"font"] ]) {
            newFont = [[FSFont alloc] initWithName:defaultAppearance[@"font"] styles:0 charset:FSFontCharsetDefault weight:0];
        }else{
            newFont = fsdefaultappearance.font;
        }
        FSDefaultAppearance *newfsdefaultappearance = [[FSDefaultAppearance alloc] initWithFlags:fsdefaultappearance.flags font:newFont text_size:fsdefaultappearance.text_size text_color:fsdefaultappearance.text_color];
        field.defaultAppearance = newfsdefaultappearance;
    }
    
    //choice
    NSArray *choiceArr = [[NSArray alloc] initWithArray:fsfield[@"choiceOptions"]];
    if (choiceArr.count > 0 ) {
        FSChoiceOptionArray *choiceOptionArr = [[FSChoiceOptionArray alloc] init];
        for (int i = 0 ; i < choiceArr.count; i++) {
            NSDictionary *choice = [[NSDictionary alloc] initWithDictionary: [choiceArr objectAtIndex:i]];
            FSChoiceOption *choiceOption = [[FSChoiceOption alloc] initWithOption_value:choice[@"optionValue"] option_label:choice[@"optionLabel"] selected:choice[@"selected"] default_selected:choice[@"defaultSelected"]];
            [choiceOptionArr add:choiceOption];
        }
        field.options = choiceOptionArr;
    }
    
    if (initializeCode == nil ) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"get form feilds faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:nil];
        block();
    }
}

- (void)fSFieldReset:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    int fieldIndex = (int)options[@"fieldIndex"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    int fieldCount = [pForm getFieldCount:@""];
    BOOL isReset = NO;
    for (int i = 0; i < fieldCount; i++) {
        if (i == fieldIndex) {
            FSField* pFormField = [pForm getField:i filter:@""];
            isReset = [pFormField reset];
        }
    }
    
    if (initializeCode == nil ) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"get form feilds faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isReset];
        block();
    }
}

- (void)getFieldControls:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    __block CDVPluginResult *pluginResult = nil;
    
    void (^block)(void) = ^{
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    int fieldIndex = (int)options[@"fieldIndex"];
    
    FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
    int fieldCount = [pForm getFieldCount:@""];
    NSMutableArray *tempArr = @[].mutableCopy;
    for (int i = 0; i < fieldCount; i++) {
        if (i == fieldIndex) {
            FSField* pFormField = [pForm getField:i filter:@""];
            int fieldControlCount = [pFormField getControlCount];
            NSMutableArray *tempArr = @[].mutableCopy;
            for (int i = 0 ; i < fieldControlCount; i++) {
                FSControl *pControl = [pFormField getControl:i];
                
                NSMutableDictionary *tempDic = @{}.mutableCopy;
                [tempDic setObject:@([pControl getIndex]) forKey:@"controlIndex"];
                [tempDic setObject:pControl.exportValue forKey:@"exportValue"];
                [tempDic setObject:@([pControl isChecked]) forKey:@"isChecked"];
                [tempDic setObject:@([pControl isDefaultChecked]) forKey:@"isDefaultChecked"];
                
                [tempArr addObject:tempDic];
            }
        }
    }
    
    NSLog(@"%@",tempArr);
    
    if (initializeCode != FSErrSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"update form info faild"];
        block();
        return;
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:tempArr];
        block();
    }
}

@end

@implementation PDFNavigationController
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return !self.extensionsManager.isScreenLocked;
}

- (BOOL)shouldAutorotate {
    return !self.extensionsManager.isScreenLocked;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end

