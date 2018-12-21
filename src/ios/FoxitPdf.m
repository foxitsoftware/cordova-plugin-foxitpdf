/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>
#import <uiextensionsDynamic/uiextensionsDynamic.h>



NSString *SN = @"bqtPqJXM3tVmLYMw3mgUwjLPx0UOd3Cbqg2CNIkgu0KuUPonSVmDxQ==";
NSString *UNLOCK = @"ezJvj18mvB539PsXZqXcIklsLeajS1uJbsdKB3VmELeRxklqf9iSxqwvpPpwG3DJeVUCVBNz+EQlthgUzBkbNgWhSLL6Ukv/FGJjTBrm642ffdWUWWKEaWbWQ1srEw4+8f72amQFJHhZo7d53A5FgqTw7x39i+Xl63DLOSHG2QVCIZO8lLs7bE3fwuFD6Klx/Qzrn7s3oT81fEpP5UgMTDttZINOaL8LWTCho5phYqqiRAQ5XUfgRoFlqK57cq8jQGLcLULEh2nJCn7UhtW9UY/6SbEf95LWtOTHGI6S1sunR35i8PWeBmAJThuFuBYpoJl8JSl8eixd2jAiUQ8EwwjXCwQeEkZUxVFSuTfkGsFdyPGbvNqFqiQb7w74F8aaXc3Vl36iRvQNesl+9ebxCR77uSMg15U94LoEdK0P+JWLS60QKR7d/LyjzckKZ5lfPZ2qAvR1+4zaAw78aaXUwlwN7P8luig+XU564NmNfFqZAd+TvfLzfFKsEEoJ1B/H3r4MEJ6p5w6hiigAnFQQN5mksJblt+1msoYKnTflcYcaf7tv3sv1MKvLz8+SgTi1BfBhOd2WEXqeqmqUxetz2XHgSDbf0i0egh/XzPFeEafPLkZCjfjaA8LcWxZkhetSuqzqNuI+rBtPsrsIQbcu9xTH/HskFXEi3UHsX2LGm5zNa2vaTJQKO/Lyic57DbNh+SDvpAmIUuQeTMt9mvcZzFIkKuc0D/Ufbf/vfdd1mmxvFN0t9OjBZvknAvcROYdzDHYWsytXR7EvTrS2BI7KHTaEVRPIETDcmj5R5GebPx1bgZZVIcdTckA99rgxbv93LO/598Orblr04d/yvUmAOL/DEyaxNcOJx7HcvAHiCTYP6B0FidABKMadgt73gVDIZDguWGrt3QG6vDIEMQzRuxCTP5md4pNdNezkHDwxWGTUr95PXbGYxcRNqecePhHUqXyxCTUfGAGkwWdwHQU9oIzYt7eODzCBJZedynsrTKFpNQpvbx4LZlIZ56Wis3CmAQ7fKbf0qFva+fU3mqII6/mARtg+URnz6NqcK/kqsD7et5uuYr96YomISyeBtLSUplEflEokObf4XsNl/c779p5qZs79DEYYyME6z9NBswhxjkkxsq4Se5RYQKbFTAS3wrwqXJ4qywXiRHgFAPyrwdw0KXRYT3/IiFJ+ygI+vaypfK1BHdGvHi3BAGeaKLzwRFhFJ90kQArQBzabuWHzj8f/9Hs=";

@interface FoxitPdf : CDVPlugin <IDocEventListener,UIExtensionsManagerDelegate>{
    // Member variables go here.
}
@property (nonatomic, strong) NSArray *topToolbarVerticalConstraints;
@property (nonatomic, strong) UIExtensionsManager *extensionsMgr;
@property (nonatomic, strong) FSPDFViewCtrl *pdfViewControl;
@property (nonatomic, strong) UIViewController *pdfViewController;

@property (nonatomic, strong) CDVInvokedUrlCommand *pluginCommand;

@property (nonatomic, strong) NSString *filePathSaveTo;

- (void)Preview:(CDVInvokedUrlCommand *)command;
@end

@implementation FoxitPdf
{
    NSString *tmpCommandCallbackID;
}

- (void)Preview:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult = nil;
    self.pluginCommand = command;
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSLog(@"%@", docDir);
    
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    NSString *jsfilePathSaveTo = [options objectForKey:@"filePathSaveTo"];
    jsfilePathSaveTo = [jsfilePathSaveTo stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (jsfilePathSaveTo && jsfilePathSaveTo.length >0 ) {
        NSURL *filePathSaveTo = [NSURL fileURLWithPath:jsfilePathSaveTo];
        self.filePathSaveTo = [filePathSaveTo.path stringByRemovingPercentEncoding];
    }else{
        self.filePathSaveTo  = nil;
    }
    
    // URL
    //    NSString *filePath = [command.arguments objectAtIndex:0];
    NSString *filePath = [options objectForKey:@"filePath"];
    
    // check file exist
    filePath = [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *fileURL = [[NSURL alloc] initWithString:filePath];
    [fileURL.path stringByRemovingPercentEncoding];
    
    BOOL isFileExist = [self isExistAtPath:fileURL.path];
    
    if (filePath != nil && filePath.length > 0 && isFileExist) {
        // preview
        [self FoxitPdfPreview:fileURL.path];
        
        // result object
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"preview success"];
        tmpCommandCallbackID = command.callbackId;
    } else {
        NSString* errMsg = [NSString stringWithFormat:@"file not find"];
        [self showAlertViewWithTitle:@"Error" message:errMsg];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR  messageAsString:@"file not found"];
    }
    
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

# pragma mark -- Foxit preview
static FSFileListViewController *fileVC;
-(void)FoxitPdfPreview:(NSString *)filePath {
    // init foxit sdk
    FSErrorCode eRet = [FSLibrary initialize:SN key:UNLOCK];
    if (!fileVC) fileVC = [[FSFileListViewController alloc] init];
    if (FSErrSuccess != eRet) {
        NSString* errMsg = [NSString stringWithFormat:@"Invalid license"];
        [self showAlertViewWithTitle:@"Check License" message:errMsg];
        return;
    }
    
    self.pdfViewControl = [[FSPDFViewCtrl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.pdfViewControl setRMSAppClientId:@"972b6681-fa03-4b6b-817b-c8c10d38bd20" redirectURI:@"com.foxitsoftware.com.mobilepdf-for-ios://authorize"];
    [self.pdfViewControl registerDocEventListener:self];
    
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"uiextensions_config" ofType:@"json"];
    self.extensionsMgr = [[UIExtensionsManager alloc] initWithPDFViewControl:self.pdfViewControl configuration:[NSData dataWithContentsOfFile:configPath]];
    self.pdfViewControl.extensionsManager = self.extensionsMgr;
    self.extensionsMgr.delegate = self;
    
    //load doc
    if (filePath == nil) {
        filePath = [[NSBundle mainBundle] pathForResource:@"getting_started_ios" ofType:@"pdf"];
    }
    
    if (FSErrSuccess != eRet) {
        NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
        [self showAlertViewWithTitle:@"Check License" message:errMsg];
        return;
    }
    
    self.pdfViewController = [[UIViewController alloc] init];
    self.pdfViewController.view = self.pdfViewControl;
    
    if(self.filePathSaveTo && self.filePathSaveTo.length >0){
        self.extensionsMgr.preventOverrideFilePath = self.filePathSaveTo;
    }
    
    __weak FoxitPdf* weakSelf = self;
    [self.pdfViewControl openDoc:filePath
                        password:nil
                      completion:^(FSErrorCode error) {
                          if (error != FSErrSuccess) {
                              [weakSelf showAlertViewWithTitle:@"error" message:@"Failed to open the document"];
                              [weakSelf.viewController dismissViewControllerAnimated:YES completion:nil];
                              [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
                          }else{
                              // Run later to avoid the "took a long time" log message.
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [weakSelf.viewController presentViewController:weakSelf.pdfViewController animated:YES completion:nil];
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
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    // Called when a document is closed.
}
- (void)onDocSaved:(FSPDFDoc *)document error:(int)error{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:@{@"type":@"onDocSaved", @"info":@"info"}];
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
@end


