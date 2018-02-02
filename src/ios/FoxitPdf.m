/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>
#import "uiextensions/UIExtensionsManager.h"


NSString *SN = @"aDNKDiqm639Z6RqqBazD6rJ3vxkm10zmBVjI06KM/B6bDumXrvGGKg==";
NSString *UNLOCK = @"ezJvj93HtGhz9LvoL0WQjY6n7q2DskrbykNKI0MicbTltpNxCSRq01lkum771xm7FU5HIH1Y7tkt96WmUUxWWbbz3DJUlfS0Zl+6yWiJuLLzCzdx3DiGbddA1Ls2GIJlGxzw71jx/kk04SCEJN01e1QmkdKCoioOZ3Ic0FWJqSdaBaNyQPPPjzwS6q/2wqb7iJwAsuloQgesJRzGuMhFEMxrZENO7OXARDChZKZ05s0kR+YIXb/hRoFmqK53cq8nAGrcLUKlhwjJfqpNQ8yklgozymeFIH6PMhHIi2ndBtFEG7dxB0totxK7b+PMZO5ws6o/kL0jdd1r8PHoc5Z13goHyzLENxUjnvd7Wu4NISj0C9361GgVPaddyAIUWt0Gmlo1AHy6vWXxvw6Gq467tA+TKX8Bj4Qjk6AZBr99tuA/MP+PCEYWNMN7WBfUYJ1d9ZqrRWE7gZB/uQe2Zz3Za78TekGuNcTa9DCvgWRk6hv7TJDhLwx18OcliKIFYTYhFHJne/NjYTuYa0HRd83leL/jiidwNqAWORVmMT2Nnx6wwXpdtamRq1GTy7PSt3F/wHyusNQnLj7pYdbvhaVLnuueKLM6XceKiyctJet4eO3VsXd627ObLdCc9MMfYq3enKRnV28dLj+/paV59c9mlg1U2UKIV+L3pjxVKAd8V4Y3GdtV+ITRMYLKzuS6a7rbX8Tt5XY6wygAovuc77Ne7rc8W8R2bfiLjTWtkcYBtJllXTPkLx6js9I/8P4ifqx4mJatw3r1Y4Ehhcl6g+KbTDGVhyKOox1VzSRq1Y1AJD5FDX/WZWOUurQEf95jxFbhrBtLD5tU4lGqwJT8vav/PBdHOJc/Fnr4lRFZTxa0cD1/WGEf1Yi5ypvoWH0TRY4bnlct3vzn2vn+CMy7FdFF9a8gHwOQf2Xq4IKYeRENHdBiSW2Z16anU21I6iONRXpzdPYxKJ8RDOfNPakiSYiFAsucRMynliZBe5DSOQ5cIq3BWcbXiZkllTiN/TUfKvhDKzHRlo7W45mPp+kKwqKuArQL+XC4PaJHtJxQgc9aqJksw1okB6qVrqAcOf2bRGYH8SZgWDikbh3JoRD2O6HhK1Mzgy6/FT87dndannoYhd52C0Dl+DcXrW7aIzpzxg5GSD91hRfg9/m8ZCt6D8jNFammIe7FNIxUNYNeZpnYODqQ2r8C/3pCynyr+2/ZoIqsIeZRBrMLmWkcITxG8WTqbg==";

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

