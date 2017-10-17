/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>
#import "uiextensions/UIExtensionsManager.h"


NSString *SN = @"Ljs06YddedKXpyZ7qymbkAe1EFe1jstVhjZXa5aXvrPPzGF3l36HHQ==";
NSString *UNLOCK = @"ezJvj90ntBhz9LvoL0WQjY7NL4K81WvxfWfgcutRsppWR4/JzmaDxKzphJp0Qh8ydhGQUB7Fm/B/Uoc+/etFj3VvOgh+85PS/TSEHVVoS40YW96WOlgUaeac4DrlXHVNg528UOumzHxeH/GY510NHROP3ZJljR6C/d9AsdzSJx/qRPpoidG99h8Jkk4sqPFGhK0Fy0V4jtUrzyjDhR/303bOyI6k26PtttlfLg1Lsvyf+LgQE99mryKDjWrX64cU+dnub5ShxwMqvV/CTlY3Zj2fPSXR02xW1MJ8DKRlVeqURxCihfdX2BfPyQ+a0nwKgy6E8vFwD2yMVaT/BRJMSOel+C6CHadKZOyXILn+kvZum4pfY6OGuV3Ialvd7LPXNN2yW79kHDKheHoWbvmT/t9sdjwEqIXpnxVI4LUzLsPbeJtXTZBsjXyXpoX4I0lsIO+fGoa8N5SQS5RILd7cCFYLLzTkfKSpHXwWtmV8efpcW+JlCS9KzF5UhfDfv4dhdKCq35lrUdxg8TYSjh3xHNQz1OcpsKdHsOm83GvNwUY+O942u32f50i17g6AOCPpthZCli1B3qwoGQQMnOYTcATzbzODRXEape2j50uJybrpuSrSPa0hReSfHM3C9ndA7PdPzkHF5aHxmyKh9RNRgBbegdbnuBkzBkP1WzDxGmbRIjlF4sjvc2PhAnXMSQOea6N4fsurKAsH//KFpKzb7uJGF+Fi+F59qyR/iRDe1LiPHkrz8d9oTZsBj9tB8YXCzMcioNAR4ABLKdMMr5rSCgZMYc/AbZViLBvMMg3hVnaDFItcEVBH2pq3Y79J4e/1zPmnxsovsxyqaOTXdslQMtcgKIL5Jl17EvlA9FzjKemrUOzeOFZjF+i9WXs5H40ZPcKM/dsy2FNGVCTHiqzoIYumgfPSMYKCKWzby8vNiWU+nFXV8QrQB8v8DYv69Sm7k5uqb70G6l2Q2+yrlgntCeNM+JQDGkt3BEVAt22AuyfW6oNXYh/h9M20STvpu2pP8VidkhakFCk1uoWz8WVn79jMn5lzClbdfj0k1E3ZulClT/PdrmbmPuIjg8XwnKTfpUHyT9UhHVwdKRhPqisb4sXU8zEK4QTDjnkL8OOY7PD0885xDFySR3GG9ooBt4goUSRiM4oN6npPb/y8CN+X4VHThT2rNXOERw0TNj8Ho47pL5XZEbNoULTrk5gLCS9lDwNO3qE5B1DyiLW+qqH7S3NA";

@interface FoxitPdf : CDVPlugin <IDocEventListener>{
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
    
    FSPDFViewCtrl *viewcontrol = [[FSPDFViewCtrl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"uiextensions_config" ofType:@"json"];
    
    UIExtensionsManager *extensionMgr = [[UIExtensionsManager alloc] initWithPDFViewControl:viewcontrol configuration:[NSData dataWithContentsOfFile:configPath]];
    
    viewcontrol.extensionsManager = extensionMgr;
    [viewcontrol registerDocEventListener:self];
    
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
    
    UIViewController *previewController = [[UIViewController alloc] init];
    previewController.view = viewcontrol;
    
    [viewcontrol openDoc:filePath
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
    
    [self.viewController presentViewController:previewController animated:YES completion:nil];
}

#pragma mark <IDocEventListener>

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    // Called when a document is opened.
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    // Called when a document is closed.
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
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
