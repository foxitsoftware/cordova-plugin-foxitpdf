/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>
#import "uiextensions/UIExtensionsManager.h"


NSString *SN = @"bgz0XjRACpxIdWe1xLZOo2gjXG1MYXxj+yPTSml903F8T7Hv6tt8xQ==";
NSString *UNLOCK = @"ezJvj93HvBh39LusL0W0ja6n7P901Et7D1kNPS1MELvfNklxI+pXl0k2vWX5IVNHmA54JOed1UEqUKj1Ks56tzIN0MfkLNmKJLcoqOuqn1aQqXicX3GUqaczTFgbKwo+8T6C4A/3q+HQsd7pcO+HhCzxgJesJFWr2uCLE3sMQZdY/Xr54SsObkFs9lQeltVHy33k13/0DKAZECDkOJl8Tja4NHwOOXDGiFXRTczy50MH6V11U71jUNoCNYEj1UyqnveOVE7/xlgsCPx4QbFOX0EHzeNNVk0dpubLTT8rOkcOnxILBn6WwU+Br9r9WXz2y8oG+59+wechhquSWqx8KPPylLbPQuehVeI1dQ0hOq66PYmWGeEdNpay27KdaElYuuZa2/zaqaDHKoXbl3PSzdONw4dqq8shFNMemO6IzyB0tnh0CATRbfMHCVNanOKMCUMurepBAqwgigxxaN+U2zX6SKYXTNrPp6v223jt/6nuQnMefthXp54KGZwLsR/d40bE3AH2x+TNJ/yUc0Frz8DwpgPRuIhmxj9QZkmV4nbKFtXQ9pySpfHE00hWjyhf7C+W8A5S0U/U63sTIzJcGrWa4FPPZIai2sVhdJRgpbcGZ1nL4dqxQcAhDOckHP66QkgTtHGa+JwtSm0zUuznX8Ajdw3C7a+0octliOXmrazwAAVseXN/KbiYcw9Buld9hrI60O2yo92CYbofqLzsT5IsgW1AU3CLNsLLkYUhoRsx07XAYWtneJq9QRZMGWjLOH2cMOydEn5ISeOzKO4W+/yipgSFmZdeJUTqOrCXnWlQNdhbpKrXpiHG6ZO4exBqNByZTCsQAI+Dt/NsjdgaaOZ5h8UDTOHiDXVYzjZZScRBO0v9TBmB1E33htIH7wS0n29hijsSz1mzkW95hgemrDnVpjh/UdznfejXIV4sc7ze3IL+IAcOWuQ+ulUX5Ww4f57CiNYabi1MfquxRArTwUIGkd7iWcVq4PI0gO12CRMOgrDrox/F2hvHTfuXu1UM+saXAwbg4OY6C+ckgWa7QccmBo6MAf4VkjFuI6QzYy5aPXVErybQ0D0IZ4R2fyYzrtmrSO1wmRsBoGdnS3tNI3a9LQi2C/Sjm8UHM+uFrMEbmQRyUztmgpUE4cg4VlUhYzomlUib2Jgj0zfAjh+IWyFG0qMTyX1JwTcG30g7h6A3GAMIwX2g6+St5Q7c7cSu0/e7tNPe";

@interface FoxitPdf : CDVPlugin <IDocEventListener>{
    // Member variables go here.
}
@property (nonatomic, strong) NSArray *topToolbarVerticalConstraints;
@property (nonatomic, strong) UIExtensionsManager *extensionsMgr;
@property (nonatomic, strong) FSPDFViewCtrl *pdfViewControl;
@property (nonatomic, strong) UIViewController *pdfViewController;

- (void)Preview:(CDVInvokedUrlCommand *)command;
@end

@implementation FoxitPdf
{
    NSString *tmpCommandCallbackID;
}

- (void)Preview:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult = nil;
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSLog(@"%@", docDir);
    
    // URL
    NSString *filePath = [command.arguments objectAtIndex:0];
    
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
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

# pragma mark -- Foxit preview
-(void)FoxitPdfPreview:(NSString *)filePath {
    // init foxit sdk
    FSErrorCode eRet = [FSLibrary init:SN key:UNLOCK];
    if (e_errSuccess != eRet) {
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
    
    if (e_errSuccess != eRet) {
        NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check License" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    self.pdfViewController = [[UIViewController alloc] init];
    self.pdfViewController.view = self.pdfViewControl;
    
    [self.pdfViewControl openDoc:filePath
                        password:nil
                      completion:^(FSErrorCode error) {
                          if (error != e_errSuccess) {
                              UIAlertView *alert = [[UIAlertView alloc]
                                                    initWithTitle:@"error"
                                                    message:@"Failed to open the document"
                                                    delegate:nil
                                                    cancelButtonTitle:nil
                                                    otherButtonTitles:@"ok", nil];
                              [alert show];
                          }
                      }];
    
    UINavigationController *test = [[UINavigationController alloc] initWithRootViewController:self.pdfViewController];
    test.navigationBarHidden = YES;
    UIViewController *top = [UIApplication sharedApplication].keyWindow.rootViewController;
    [top presentViewController:test animated:YES completion:nil];
    
    [self wrapTopToolbar];
    self.topToolbarVerticalConstraints = @[];
    
    self.extensionsMgr.goBack = ^() {
        [self.viewController dismissViewControllerAnimated:YES completion:nil];
    };
}

#pragma mark <IDocEventListener>

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    // Called when a document is opened.
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    // Called when a document is closed.
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

