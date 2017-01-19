/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFObjC.h>
#import <FoxitRDK/FSPDFViewControl.h>
#import "ReadFrame.h"
#import "UIExtensionsSharedHeader.h"


NSString *SN = @"Q03VQoZzUrPy3RkJqM401mt4KTI2GoCaIX1z3VnXQ1a5NOJQWaVOWg==";
NSString *UNLOCK = @"ezJvj93HvBh39LusL0W0ja4n+FSgXqp1ClndarfUeOP9wvCzbZdxF4ycpQufTTdu0MY9hJl6zUhrSykko0KyjhpaMFEn6IBy2Hiz7FezBuXN6xqYV1gE6OFxjeXHuiUMmVumuqq9TwbaUO3J7oa7wowS2vID86ofnSU5HyQwIZca5S7cqTnaRJEgzmo5rOWeb/UaqxDYhaEg4wnGLOqNAKk1f3byiS1jl84EJH33DLtf+sVZEuHtYSl8ES1YEni6IAbdkS6VelEdK7Pne4vn+e5FFkl0i4JrasjzbY3R34InVcID5w40lmDgMt6+YOd55tFhfLgJ4X+VLbYLNz6pTmO+GZdY5BwHfs8ZLNOd/xGWt7sRsoQt4PQ6KF+mrf91sCqKuGzEdjW+VHzWXwDhHot4dIA5xgZpRcdoqqDwC7huGvGv4W1cO1Xo1e1n+xcxNZ01uQ3hoE6iJBR1IhAUAhj90eZN2he9YX6UG3F9e6fJQeM8kWd/BxW6Oz9VE/k+EBQ6JKseWpbehuEZJ8VwocNpw1gt/U/WMOn93jt4NmMhbwP0PXD/7Ji1F4OMjFtx3wDu/zMvye286LvN1Vqt/KdMHs+xDvfy4SLr8bIn6emHXnWvzNtRBAJGVAi/A4XN4nTv+l+Nj+PdJy27SrbjUPI9b9brkizdWqbz+2sMDU9ln3LtfaXJloJRUTSli85YwGBXdyQaak888EQGMKsmOTmbgilrZ9CVuV7pIXUq1bsCCawuXzIxvCoQXjKTvVCHdC3MSzHDYd88vyHa9Qi2iGf0MPcXvQPw+CkaIsE3ziGbv8tTfo9Yjol+eaH9UCxPhtR3He8B/qIwpRoW6bTl79uTAo0vz+jiyzov9j2LH7fJZuwzx84UfsBoYiBMY4xR1usVPqPLoy4Ut49OP5lJYmzdrvKQc8v3PLmxWZk3t8Ga9C6wWCrEAdkqFKamWPlhSjXECNoVsVJWlpu7gyHD2ipAHP8879Q1z7z5Y1+ozmLirA+eUPBcl5l+GdR6DATSfZZGegMqbSDpzO+sghUYxCRAyeL0GHjs1kEPJpmcQFTAObh6+vQJyrTRULo+BAjhdFSvvaE17P9RTYzm72Nm0KD0o9PEdFHDvpCohXbRF/Uwj3l6/vti9kbXXQ8bQrCuN6lByCxidHhP+GcP7lQQCTmUGOP4pF/JqINV2BJ9Tk1UZGl2E33C8xDs0WDIQA==";

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
