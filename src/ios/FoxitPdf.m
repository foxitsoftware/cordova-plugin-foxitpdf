/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>

#import "uiextensions/UIExtensionsManager.h"
#import "uiextensions/PDFReader/FSPDFReader.h"
#import "FSStackBottomViewController.h"
#import "FSShowViewController.h"


NSString *SN = @"nU4V+cyy5M+IG3djLjKCTZFiXwUdERkohg+6MB1+pm+BDxbMNIPN2g==";
NSString *UNLOCK = @"ezJvjl3GtG539PsXZqXcIkmEbhuio9ACWf3giDepTwvhp7njD2b+w6Nd/Rr0cOkBP+scVC59Exkp+IOxgP2w42MKnVbnQ/xNfre4UGyTt40QX92XO1hUaeeYALnFXN7tLRqSCt2G6ETeAPGa74kwS4RBgpSdjACC/b9AsdzS9xjqRProhtG98l8Zks4smHGpJB8wC0R6jLWVgZjBOxqTQoRcy47k26HtttlfLh1LkvyD+LgQphwhMR2H5sQzcCbLE3Jzf3HTy/My/44Tm5ql0Ky9RLW2OLK91ryIJOT3yXeepxEgzu260UhAxCRdmNAtaqxk9su+PTbujlYhOX4ZiKXVQfXXA6ZASbVFkDvFOzphoqIfG3M+aWIIaIipdvsMww44peyWg9rqSiu0hZsmzZkQqJhzi90eTTTRxa+/KSaqNnrQl107g9kqiiuYdO6MCgdI+qrsqO66fS08M8fRJ+d5Y89Y/wdydAZwHkmrXBTMx6pt/BgUmvUvIRabH7xyiSOhyPeDfh3uaIcXje4PfXIQS+XzntkUTKhbLcVK3OoKFmPrG/ox8kv2P+3P2Ojju240Lxg6FtPe+Ze2ZYFvDJQ7pzsx+nAA0bzDmq+nPY/sMNHuQwfkb+1oc3OscGPpO4sXvxhmx1cutnT4gNs51Q7eZJiKbnEUymZLVSFk2m+2Y/3cFU4PdrQHSYoi+OBsqcQ8Ve4kWzPO6KFqVJgrRtw9W52Hb7fElbFp9Po4pYEiT+e6HZ4ZSF8m8odCV9W5oy8vVQAVhCULtcaci6yZxh7oMT+jDII5XvqLIYF0eI3FD3Dl1tW+fh7b+Pg2hJrK1lpGgLyknaUuqLWjYpXjVekMkUenBF7OkZ/Cg4y74JOXanzoA71P+qAfHoZes1FPa60NAF20Db6IFMLKrqLiVCmgbpwp2Ko4deHPSNE1CgCZd8P2HLRDvU7yYQVXOz3DgsL5rW23cHuoMnYeWC5ujFl4imEUfjCOutRZwDJvIa0SubCwfBJJO0v2+HEbSTBpw+XtXJ6JJEAsI1pVsP8Op9TFmrznN6BeyY2DPB3KF3Wp3428h274GJSBXzwPJjvspMS/g2pT0LIYb3KfHCW9qDCLjmgn6rgbLxgT8ZjABJqLQsI36QP2ikQPaztDRh56/7vIgurfFpkchWCjhl7mSmt2HgeGzAm/mpEFK5qNbbUn2jn6h2vhGrOAfCRJKxpTeBhlgHMe1EU/FlgzzYHqA4rpfMPN8jko6F2i6SiSCQ==";

@interface FoxitPdf : CDVPlugin {
    // Member variables go here.
}

- (void)Preview:(CDVInvokedUrlCommand *)command;
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check License" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    FSPDFViewCtrl *viewcontrol = [[FSPDFViewCtrl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"uiextensions_config" ofType:@"json"];
    
    UIExtensionsManager *extensionMgr = [[UIExtensionsManager alloc] initWithPDFViewControl:viewcontrol configuration:[NSData dataWithContentsOfFile:configPath]];
    
    viewcontrol.extensionsManager = extensionMgr;
    [viewcontrol registerDocEventListener:self];
    
    //load doc
    if (filePath == nil) {
        filePath = [[NSBundle mainBundle] pathForResource:@"getting_started_ios" ofType:@"pdf"];
    }

    if (nil == extensionMgr || nil == extensionMgr.pdfReader) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Default reader could not be loaded." delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
    
    FSShowViewController *FSShowVC = [[FSShowViewController alloc] init];
    FSShowVC.extensionMgr = extensionMgr;
    FSShowVC.pdfReader = extensionMgr.pdfReader;
    FSShowVC.pdfViewCtrl = viewcontrol;

    [FSShowVC addChildViewController:extensionMgr.pdfReader.rootViewController];
    [FSShowVC.view addSubview:extensionMgr.pdfReader.rootViewController.view];
    
    [extensionMgr.pdfReader openPDFAtPath:filePath withPassword:nil];
    
    
    FSStackBottomViewController *FSStackBottomVC = [[FSStackBottomViewController alloc] init];
    UINavigationController *stackRootVC = [[UINavigationController alloc] initWithRootViewController:FSStackBottomVC];

    FSShowVC.stackRootNavVC = stackRootVC;
    
    [stackRootVC pushViewController:FSShowVC animated:NO];
    
    [self.viewController presentViewController:stackRootVC animated:YES completion:nil];
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
