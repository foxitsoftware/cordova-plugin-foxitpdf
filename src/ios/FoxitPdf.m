/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>
#import "uiextensions/UIExtensionsManager.h"


NSString *SN = @"sS1No48GllWOhaww26EpDX+mGXcYdi5zUHFRsdMSGxodGTyLDgaYWA==";
NSString *UNLOCK = @"ezKfjl3GtGh397voL2Xsb3l6739eBbVCXwu5VfNUsnrnlvx3zI41B75STKd59TXVpkxEbp+B3UEqUNj1KM66ujQN8Mgkr/mKJOJaqOuqngyfs4ccHXmAWTe4ajKpqKI0Y5clxoTqL8tfYrOQZN7SeznxuJdOMwrg2jDyDQc5ffNZSt8Z6nAjHlI4vjZHNrWeW9M+jFgIcaBMRE/hwgZwwQpr/74cdH/VV289PBrvsLtf+hIagpdc0l3tJJzQf00Q/0/PSPp35eeU+YrKuiXiBIm0sLahXrXBU6kdYOoZgteB9dMaH0v2Ev2EF4hzwtcwExvOI8UxUsC71UTl/KJhIiKs9PdM2fZ4AaseldOQvaHs9dGVwsI2LajSXI21IKT3vwOnMHT10V95hnStG/maORwMHDfLjlAyJepfMlP2aU5x7hTFwRKF9bJRgelGeTzn0c3zJM/GhG5YccdzRPtJZvre4RD9oOYw+vrR6/TKoZtX6Nlu5y/FPg2xlA73kLdaaEqulHtDdec25ki/h9ahvyUP30bIMJKaG5F+SPTCemor1Oy4mtaWNhjPY0cVu807luylcfAd70yu/3neiDUc1JlI424i/OLxRkBGJInLdBMgEeU6gY34Rh5QBfWdKq3lHzKsZnHqL7+MDPu16Os3JX+G4rBWVpRMOKxgGTfnp2bkChAUlzL0tX+/iLjWPyADJwpo3AtVyCckdyyQLgvWr93+6nN34YurHHKqYUTQ0oBeRb0a2DYu3fNyAzDgPZ4lXbkbwtMtS4299A4lUnVJcA21ZBEqC0/mcu/eHHd1UdBBouaD6rkXQ53OzznjMCjibCYbNurh4X0toPxSrqbRU7/LBkzNIbUD+YH1AFAG6Uxi/arFjXBV0Wg0JKCZy1WBVeIfpTW/vtOxAaSsL4FX2930kqZhbIrbTBgOwlsDJO4d5LWFZNuCqjvI8U00ilJExKXAz0w5UTUGfLZraS85ur/zHRs6d8V+psFURmcaCpkLHOE8LrSfT+kat8N6GREjuZItoGs0NOkKYvj/lL963WcRWikieGBNP9Pl/hgpdIXew7nue6U9XGoTgdz2lLR6QtC4EFuVHheMP455C7pRlKJ+7gN9L9+LdoZ1c7LgthMGNg76WWkO129/xwSSDyE7l9z/HbWiAyAtYYYJe02Zl1sInDc30jFrpkXpOocoIa9qnh8EZN859NYJqkQiqJE9CIJ66DA0DNk8eNnaJaBNAzAv2eH+lwEXckM5Re5xjo+69QB0T2Fpx7nFR/cnSw==";

@interface FoxitPdf : CDVPlugin <IDocEventListener>{
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
    };
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


