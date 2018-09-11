/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>
#import <uiextensionsDynamic/uiextensionsDynamic.h>



NSString *SN = @"DW6QUNWzT4IF0JluGTcsD/OOs12XAfWdNkVPejrfj72Mi6P3xjaElw==";
NSString *UNLOCK = @"ezJvj18mvB539PsXZqX8Iklssh9qvOZTXwsIO/MBC0bmgJ1qz4F0lwleIbZghw4SQD11gx1jqOJvZixkxBpuX+IYO08ZheJYkMQumnRHZ+eSysccHXuESTewCCK1K/MgHY/k54IqDvVbkdKIJu9QmzmxEJhP8zrulCE5v/XtHRKbNVNsvDpNop2HE1XwRtNon3s6YQ+j+c8BACgApAsRalO9SQP2GlkkBEAYqvY2JrrnRhfeZngd25kw9CZGd9p3QToervqkj64UV/3I4sqU/0arSotj32QPFCYAt9roaKCzAYoTeaE/l7zlnpd3dcZwf7NiYwSSrQ2LNpD+r2lHGi8WGr2hO7hwWtX9vdklMHOf/YFo+/05XxoVlnVAtYXRxx7S3MVeSEnhswujY+AswVbBgKGJRGRWzKnv7py3803X3DH5PGqRRayjTceiRq0ddSf7GiNtRQittqcRQSBYet43Rvyca+NyBxa5DddneG1VbBaVtM12C2Xv02/8HNLAf5AF3Vua/6O1gRi2ofIm0dqpk59lj19OiyqBIV6Ma/HZ93SwKLycOxDOHIcn2cVM1UtY+pF7ptUGz4Mq2V9YBaB2wxFB7I3mUEBjGOx1Y1ZAyvpWclWebMpIUct3ku4PmLsuSeX1uAd4iGOggcIFXPiUdYu7RytAbIlnWLtd5FZnwAfsyN/norSSmAtdZMHEv0xmh865YCFDkyo7Lw5ilhUICpZV2qJqqg6n757PdZcyO+M57r5bdcMto40q3M+lmiqOV8Wj/ui9v1h+UHOKQBvCti5TYvI5FWN/biCleETDEXUV1aMvVm/Zcyuu4njBWgL+0FMzCx72Lv0oIHsSl3THc2TS95YL9/3QpYQTAue6VpXdEAN1s3u4rzQVJCmT2QPK4FP/pznBYEP289VheUd1I521v93LZf9TWFDeIUIjE83bEGdtlJRdbqPR2fXccdtLWUeG+Ky97MqncQHy4REqjmBqNxjlo/gvEshBV7VOntNcUmpCLHKyZF+IupSlQ5zO0lJ9RaPShX+VkaI9rx17Oif8q0qvz29nA9s5XyBe87VjQm6BjA7b5hZnixsuZlv+R7ZhyWU5jaTh1BuLbz3zIDAO90rK9qnMP2hm5AFRmy962CqDi/vW0nyQISpgMlSJsGkPUxpg5TuhiGe13TEHMQyHVdBodOcMUBaO1sk4mdeYk7qUm78ek2VL4PhgZHZO3KE+B1ASiVG4iqGAbYiM";

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
    if (jsfilePathSaveTo && jsfilePathSaveTo.length >0 ) {
        NSURL *filePathSaveTo = [[NSURL alloc] initWithString:jsfilePathSaveTo];
        self.filePathSaveTo = filePathSaveTo.path;
    }else{
        self.filePathSaveTo  = nil;
    }
    
    // URL
    //    NSString *filePath = [command.arguments objectAtIndex:0];
    NSString *filePath = [options objectForKey:@"filePath"];
    
    // check file exist
    NSURL *fileURL = [[NSURL alloc] initWithString:filePath];
    BOOL isFileExist = [self isExistAtPath:fileURL.path];
    
    if (filePath != nil && filePath.length > 0  && isFileExist) {
        // preview
        [self FoxitPdfPreview:fileURL.path];
        
        // result object
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"preview success"];
        tmpCommandCallbackID = command.callbackId;
    } else {
        NSString* errMsg = [NSString stringWithFormat:@"file not find"];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR  messageAsString:@"file not found"];
    }
    
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

# pragma mark -- Foxit preview
-(void)FoxitPdfPreview:(NSString *)filePath {
    // init foxit sdk
    FSErrorCode eRet = [FSLibrary initialize:SN key:UNLOCK];
    if (FSErrSuccess != eRet) {
        NSString* errMsg = [NSString stringWithFormat:@"Invalid license"];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check License" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    self.pdfViewControl = [[FSPDFViewCtrl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check License" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    self.pdfViewController = [[UIViewController alloc] init];
    self.pdfViewController.view = self.pdfViewControl;
    
    if(self.filePathSaveTo && self.filePathSaveTo.length >0){
        self.extensionsMgr.preventOverrideFilePath = self.filePathSaveTo;
    }
    
    [self.pdfViewControl openDoc:filePath
                        password:nil
                      completion:^(FSErrorCode error) {
                          if (error != FSErrSuccess) {
                              UIAlertView *alert = [[UIAlertView alloc]
                                                    initWithTitle:@"error"
                                                    message:@"Failed to open the document"
                                                    delegate:nil
                                                    cancelButtonTitle:nil
                                                    otherButtonTitles:@"ok", nil];
                              [alert show];
                          }
                      }];
    
    __weak FoxitPdf* weakSelf = self;
    self.pdfViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.viewController presentViewController:self.pdfViewController animated:YES completion:nil];
    });
    
    [self wrapTopToolbar];
    self.topToolbarVerticalConstraints = @[];
    
    self.extensionsMgr.goBack = ^() {
        [weakSelf.viewController dismissViewControllerAnimated:YES completion:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
    };

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleStatusBarOrientationChange:)
                                                name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
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


