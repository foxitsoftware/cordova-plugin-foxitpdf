/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFObjC.h>
#import <FoxitRDK/FSPDFViewControl.h>
#import "ReadFrame.h"
#import "UIExtensionsSharedHeader.h"


NSString *SN = @"NomcW2Wm9G4CK5qsStEYjrb9W/9QIc0VrSuzE0rzMG6bncM2rPYoTQ==";
NSString *UNLOCK = @"ezKXjt0ntBhz9LvoL0WQjYra6L8MRhW2h+8oMOY2s5pWx011YwYlxvRb4F1MS0SJQxM8Y3146g2o8GWXQU8UVd4qcZVl62b0XvYl93uVypUIVB+J8DikaOXIOqdxmE7tNgw4QikFXI7zBxJXuazGaf/3YUbOJQ9uDF4hCd8X3q0FHhJZ5ml1PtsfzjKRnhHnXtI1f8m3T245tAeZ7CrKLFRq9M7HtGC4qAs710H7ogV3JTqROeIylUFieYV5+tWPJtMgefGEU79C7bacyK3qYXjrrPR1oVbxJSyQYCp+/JYHXloUNmkaqn5jR9By9MiZbTn4w0vT924BhiZ4ke0/p92zT+FC3eFhVOLRoww8AmwxDnD3diFw6BzuKQ8yFSO2yoHJyHjGuOrQGXE6Mpog7EjPhSjPRxZrXFIXfSaUPPv9xfMQmqmCtUWFSPjBUHg/8HKGeXmVqSgYlycAuY44eUV1oYTmfHzTm0pUqrNN3RyRc6fleHu7yGz7jovgu2HoEYDyIlz8u8TwDq1efrnecz4Ut2PBaf1TEAL/iK1uqZritHgwHgHUUN4EZwqEd6Zpd9MUSQanAML7WXXOYdCDn177zJlxUr5aKgC5m7qBlewW3cF8YFCP7nXi7LBT2ZztjJ8kqz5ii+a7NucnCnfZBazmsYumPfyXOksPFmVoUkV5pNGsil8/MXsVsY3p198ngYgb7NsUZuUi6xWZxcIt0dcqJtxjz59P9R4d22LV1gBArZ06eA/7WL3V8p+37CMEQYXvs0sv37r1neOXTSnWOoOu9ipijXUWJy6vvrogQsgrfxh07wNdGU4C8zJ1aTRZVhFLD6KqP2PO3OYxWk+JYtUKxDFwIKS40381PpqQ5lReiMfYXYRDwxeTT3K5IaH1Exa9/KwbKAFQNeyqff31Z9HQS05PUhOQTSqdoq4bGwp+NqdCTLvZNBp3lu/NpUBYYUnm0UtmI97/0AwNoCc8IKm/xY88w9/70nfVlqAj0I3QnqMbIARPEQkyd84Jd4DFe3YNdhHq++rHWxqG1Aq1owt0A3MT4o+rvcPMwnIW+NP2v7dXBtYNG9CbMQXqwV5Ju4TTWazmFdVfa6XvDGf7WVUmPHbGpAq4wJnZjAVEfUkd9eJqqZTrclQ3Xdb9VhcI8+pHl50fgiz3bIgB9FS+oivfE+0YwUzeCp0597KdMD7FNSIyJkFYZO3te6jRLT6qP5qc4BQ=";

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
