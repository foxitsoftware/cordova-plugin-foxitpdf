/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFObjC.h>
#import <FoxitRDK/FSPDFViewControl.h>
#import "ReadFrame.h"
#import "UIExtensionsSharedHeader.h"


NSString *SN = @"Xzz20N1dgWxJmz0seWOP54wqzhSKaLTXEje18SSUlZF9DVfYrMvyWQ==";
NSString *UNLOCK = @"ezKXjt8ntBh39DvoP0WQjYrUrx9qvbxe38QoPVU5LSr/hXt/7xBt01lwdEe+GX1++LZWB6cDWuVs8xYEMRYmjtpTRWVw62b0XvYl93uVSpW4apyWClgUaea8M3ySf8fMjjbmdBHnl5rEw9VPQUZ2jK40naM9DGVpsufKG8MXEV5B1eBiDrNZ1dVz9mgCjy/7ySAo56W/xkgcTI/s4IINvZUOZcqitBHZy409+sR5BmLMd/koMDrf2TmcHDNEcO/j2u5gBGedgX3Re4e6J3sae3nrrPR1obbyJSyQYCp+/JYHXFoUNkkaqn5jR9By9MiZbTn4w0vT927BhSZ4ke0/J96zTwEjweHl1eLRK6+VFilEcYI1DTLSeHV7CnZUgVOI/+TvACcrRKCT2qNZdslyilu5qZDdVWJwHjoY1BMgQkdfGEsWWNgTQjCeicjUFYHh2ujskos+DeQ0TiTpSRKb3ol/7Q18heWYgnMJfeV5ldFTq9kN1+XeashPsSsf8Yf+vHV4UYXJF96y8gj0IvycGUxquG1GHsAnD9YxPP27c5kEn6rKwGnq0ai5Uf/klffe4Fm+Rq7Pp3YE+gNHwFvNsIpKE9uZFwwIPLY5iJ6clQQBLqgforbeYqwkEWP+oxjutfD0YuYHEj5wbrAm2qtotyRMvYC+Lt3UGB2XscPiB79hnGWuF6vHQf+K7lMUiwgXzeiesyHK1x+6HYS4lnVcTU+0D5h6BfO2REQg1U6naA6CO8xWg/UgFdjj3aBB2WriwwgcIaN5rQtFjRvl3oJ5F8RwUtL3PK5St6LpBU6YVCMTGwDraVd8yi0n5JsezPm8A118PyzvEmlyf6G6HRFWS5PrNEkU4BmXJWVzLUANBP7uTpTzRSrWdvwD2ZU2hhVIkTRIgDY1EprylUq9M9UXH7wRvAfK7XrHag8up0ciswM7Dr3NbN7f3uCT2SndAi0+19my5Go4YEzOhMvPAsLhhTNnEyOQKk99Z1m33QF5Zule5OKNpz9B+cbwp8G+3jilSsyekPP6/LlOn2+dY3v0PfcytJR7xnOgpX24qFnQNs6WVygqcws5sV1Qvh0yeyPvZ5dFd1jN6obBMUa7qw6LYcY6V323en1qcYYY+YrYvv4CUk3nWIR5LA/qDXtUU6Iobwa3yNWUiAAYLQquSuJn7ilxyUmqTeKKynz0nLKwaa8WbV1mJq9geqYjhAvU3ymuMfvq4N0=";

@interface FoxitPdf : CDVPlugin {
    // Member variables go here.
}

@property (nonatomic, strong) ReadFrame* readFrame;

- (void)Preview:(CDVInvokedUrlCommand*)command;
@end

@implementation FoxitPdf
{
    NSString *tmpCommandCallbackID;
}

- (void)Preview:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult = nil;
    
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
        UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Error" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR  messageAsString:@"file not found"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

# pragma mark -- Foxit preview
-(void)FoxitPdfPreview:(NSString *)filePath {
    // init foxit sdk
    enum FS_ERRORCODE eRet = [FSLibrary init:SN key:UNLOCK];
    if (e_errSuccess != eRet) {
        NSString* errMsg = [NSString stringWithFormat:@"Invalid license"];
        UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Check License" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        return;
    }
    
    DEMO_APPDELEGATE.filePath = filePath;
    
    //load doc
    if (filePath == nil) {
        filePath = [[NSBundle mainBundle] pathForResource:@"getting_started_ios" ofType:@"pdf"];
    }
    
    FSPDFDoc* doc = [FSPDFDoc createFromFilePath:filePath];
    
    if (e_errSuccess!=[doc load:nil]) {
        return;
    }
    
    //init PDFViewerCtrl
    FSPDFViewCtrl* pdfViewCtrl;
    pdfViewCtrl = [[FSPDFViewCtrl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [pdfViewCtrl setDoc:doc];
    
    self.readFrame = [[ReadFrame alloc] initWithPdfViewCtrl:pdfViewCtrl];
    [pdfViewCtrl registerDocEventListener:self.readFrame];
    
    UIViewController *navCtr = [[UIViewController alloc] init];
    [navCtr.view addSubview:pdfViewCtrl];
    navCtr.view.backgroundColor = [UIColor whiteColor];
    //    navCtr.modalPresentationStyle = UIModalPresentationFullScreen;
    
    pdfViewCtrl.autoresizesSubviews = YES;
    pdfViewCtrl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    
    self.readFrame.CordovaPluginViewController = navCtr;
    
    [self.viewController presentViewController:navCtr animated:YES completion:nil];
}

# pragma mark -- close preview
-(void)close{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark -- isExistAtPath
- (BOOL)isExistAtPath:(NSString *)filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    return isExist;
}

@end
