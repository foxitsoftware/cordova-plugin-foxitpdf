/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFObjC.h>
#import <FoxitRDK/FSPDFViewControl.h>
#import "ReadFrame.h"
#import "UIExtensionsSharedHeader.h"


NSString *SN = @"K1MIy5QqeOLg2itvQGvYArLqSflvfaepWtADqcp1IaF1LqLTNRXwVA==";
NSString *UNLOCK = @"ezKXjm/atGhzdHouI0W0jOrQ7J1oyG55b8dIP+/ON1y1R/N2I6hZZym7thraBIt1Fcso47vZ2ehqdcUocV7+12sLvUDlLWn55zKRes8iD4KknQnMtHyAe8cQU6Uv9zMFYAYNQnh4s/TBbMMBK8GorFxxeEzGJQ8uNEYhCd8XpjMCnhOJDrNZ1unz9mgFty/7ySAo56W/xknuPY/ssIINrZcQrQ69VPwhYB1cgm+IyTocCmmaNqCS7DuWt4XVl/zOG/WQJcjfXWx65dUKyEV4fyphVK57rySd+a1XsAyK7yFnOyZCGX4kEbAxbK521Ht5kQQ9pRYjeeNKDFf2WqSDpSZhg5o34VnA6ououVY7PmPPx9QiDdySIw16SX1x7V07wfM32iHM/U9khJVlnMe8U501T2aHB9xdCBHrDv9ogYqe/D/r03R6/N80nO+uGVkBPQPS6ZzdV/lYPhP2BHiypY8oLB4i2X2AFmuOVQNFd5KjrQwgp2ize+cNPqxFGzGA0mGk2Pq7co5oNh5hWrhGyclvUTlnGeHMMZ2hHr5Ejzzmq6m39sPjU4FhmTOct1aGacifwHnl9/pggwGTG80QJ+Rsma/s+Mz1c20O+dLD/kJBFR0dN2xPsgjqpFsvxNga6hKOcazUKlnUdQj/1ogDODMCK4VMf+aHUJaihgG5PrGu9ww/e+5YLs1YurDporOy7yS2OUKpDZcULozIWc7Thb7nyeAjDlAAU0B6aGcMNgwnitrFjjuZjYBBAhaLSLZYCiaz68QY8BOheLhdBzBVusAI2t5L34FfWqs9qgnJQqhp6KSFA5tSOhHPT111miYM2R+xnAE91YnBuGOFCUmObYzVaXTTeWn5pGsj3pxyvcR3I2qoP79xKrfVvtnsCY3uJHyquJF0wz0376JU3MGf6SEFgxCJVy7I9NHdoi0aA8b/+U4hHKPhwzxGBA6fLsaKqQkP0QImHTCwwjoC/35/HBePqmzpiq4DKAnjqxZqGpvXMdqYFErMx9+tKOA39xWcrRfHHvyXb37IMIZTpEkOHB8nrToaeaTLpe6oKDh/OSrWQa7rIws92/uRMLsY9+WVaA9vcgaSLB43c0jXRrRlKnRXtzmb6btngXY+pYbYvv4CUk3nUz13LAjozHpUU6Iob6bABr0B7JtqagF49T3JX57oefX+7qjOSYj3ayqv/BZ1u6R2xt6/jAUwDQLxwadKD6dNsw==";

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
