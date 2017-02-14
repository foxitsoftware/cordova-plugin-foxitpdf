/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFObjC.h>
#import <FoxitRDK/FSPDFViewControl.h>
#import "ReadFrame.h"
#import "UIExtensionsSharedHeader.h"


NSString *SN = @"WNupzbAC08icmF8NH44Pnq6lYmAVTBR5KGFa1BskVreCZdWKTd5ZWg==";
NSString *UNLOCK = @"ezKXjt8ntBh39DvoP0WQjY7U7x9qvLxe38Qopd+bN8c1BvlwN2ySRqsrpKIEGURboztJ6jcC4bBb2udw77UO5Y9k7gs7t4IH5KxHM7VCH4ZG9wY0JX6GYPdQfqUn9zUkZ4YMUnxYe7P5Xj/DZ9biGRQnDdQ5nhLOuwb4zOcXSIC6S4al1WB7Xe0VnD9gZ2VOlGmW78bFMY3OenEI5phbSNEwj9WZtUZ/9R4suV/0eVTgDrAFDDJeP1BGNTAC7tePJs0kBGecgXzRQ5+6N3uKDeEbh8ZVsjb9N7cXSSFyPmjjNsPxdf4Ir2thR9BK5MiZrTn4w0vT927BhTZ4EWPoW4/FMTj0Kku5sVJIsN1IiM5WaPSmeu4dd1+zq3KUaEnBy+bXNy8WZujJkJZNAyeMjeINnLU5qofUe95YstJ2/ZzcrRAM0r/60NlYYQWRhp3FdvPTMZcXm5t8mIPDygCuC25FhK4rMJyi8qZBQbIYBjclioSnjkh6mAWEznR1hzSy/pUVADakjkIIRfsldD0K5sIKq2wa5IVOUB7XqwhFJT9RYYkNz+0j0gnwluDjmhdhNbddp1xA657zpfsQycA0vDKvEhLUrgg3Bh3MXeOzdn1cRCmIKvPo1V7ToxoCiAKtmcpyXKrtmsIOewXGVQQE0/Xn0GYA0AmiPKG7jYGZPr2ijotbBbLjLcDA46mBghvy+tq9ovlOAHW/s8jILcv4QtzysxGZUkw3xEB+KX9YbreDyaa6zBw37TaAmeOpEgB88St2Tp4MYwaqmWASDUW4uOdtJ0GJFGN0ILSUvrkQQqTuS/YMemS/BN4Ui0YTdzTreKLN/nOH7L37+PdzkAoG0JQnO1zXzd70ycuu4foB5demMY4RphYCjcd0mQ2M4bAyr0YLPgUhVoz3yDabCWtqXY575tQ6+bi2mQ2In/n2SoKOwciw9pTYXuCT2RHCBS06Uyxx36MWvTXeeFpZmqf8xTPhUhMcKU9tY6G23QFZTtH02atEpzet+rrwo4OrvDTmmxUjHwvn+bYOp2+VYZtKA1KcJw17xnegpd++YepuBuytxUk19JoXHzmPKDtHeyPQZ5d1Z1jJ64bBMUa7qw6LYcY6V323en1qcYIY+YrYvv4CUk3nWH5pLAfszntUU6Iobwb2cm794W+5+qpy8xERL8w2Pi0/cXJKX8vxLH5z3fiV2U/0JmNQ1vWv6UjQC4+rPSuo40s=";

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
