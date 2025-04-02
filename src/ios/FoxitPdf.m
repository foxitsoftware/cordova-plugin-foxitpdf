/**
 * Copyright (C) 2003-2023, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc. .
 */
/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>
#import <uiextensionsDynamic/uiextensionsDynamic.h>
#import <FoxitPDFScanUI/PDFScanManager.h>

static inline NSUInteger hexStrToInt(NSString *str) {
    uint32_t result = 0;
    sscanf([str UTF8String], "%X", &result);
    return result;
}

static BOOL hexStrToRGBA(NSString *str,
                         CGFloat *r, CGFloat *g, CGFloat *b, CGFloat *a) {
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    str = [[str stringByTrimmingCharactersInSet:set] uppercaseString];
    if ([str hasPrefix:@"#"]) {
        str = [str substringFromIndex:1];
    } else if ([str hasPrefix:@"0X"]) {
        str = [str substringFromIndex:2];
    }else if ([str hasPrefix:@"0x"]) {
        str = [str substringFromIndex:2];
    }
    
    NSUInteger length = [str length];
    //         RGB            ARGB          RRGGBB        AARRGGBB
    if (length != 3 && length != 4 && length != 6 && length != 8) {
        return NO;
    }
    
    //RGB,ARGB,RRGGBB,AARRGGBB
    if (length < 5) {
        int i = 0;
        if (length == 4) i+=1;
        *r = hexStrToInt([str substringWithRange:NSMakeRange(i, 1)]) / 255.0f;
        *g = hexStrToInt([str substringWithRange:NSMakeRange(i + 1, 1)]) / 255.0f;
        *b = hexStrToInt([str substringWithRange:NSMakeRange(i + 2, 1)]) / 255.0f;
        if (length == 4)  *a = hexStrToInt([str substringWithRange:NSMakeRange(0, 1)]) / 255.0f;
        else *a = 1;
    } else {
        int i = 0;
        if (length == 8) i+=2;
        *r = hexStrToInt([str substringWithRange:NSMakeRange(i, 2)]) / 255.0f;
        *g = hexStrToInt([str substringWithRange:NSMakeRange(i + 2, 2)]) / 255.0f;
        *b = hexStrToInt([str substringWithRange:NSMakeRange(i + 4, 2)]) / 255.0f;
        if (length == 8) *a = hexStrToInt([str substringWithRange:NSMakeRange(0, 2)]) / 255.0f;
        else *a = 1;
    }
    return YES;
}

@interface UIColor (Extensions)
+ (UIColor *)colorWithHexString:(NSString *)hexStr;
+ (UIColor *)colorWithRGB:(uint32_t)rgbValue alpha:(CGFloat)alpha;
+ (UIColor *)fs_colorWithLight:(UIColor *)light dark:(UIColor *)dark;
@end

@implementation UIColor (Extensions)

+ (instancetype)colorWithHexString:(NSString *)hexStr {
    CGFloat r, g, b, a;
    if (hexStrToRGBA(hexStr, &r, &g, &b, &a)) {
        return [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
    return nil;
}

+ (UIColor *)colorWithRGB:(uint32_t)rgbValue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0f
                           green:((rgbValue & 0xFF00) >> 8) / 255.0f
                            blue:(rgbValue & 0xFF) / 255.0f
                           alpha:alpha];
}

+ (UIColor *)fs_colorWithLight:(UIColor *)light dark:(UIColor *)dark{
   return [self fs_colorWithOwner:nil light:light dark:dark];
}

+ (UIColor *)fs_colorWithOwner:(nullable id<UITraitEnvironment>)owner light:(UIColor *)light dark:(UIColor *)dark {
    if (!light && !dark) return nil;
    if (!light) light = [self whiteColor];
    if (!dark) return light;
   return [UIColor fs_colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
       #if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_12_0
       if (@available(iOS 12.0, *)) {
           if (owner) {
               traitCollection = owner.traitCollection;
           }
           if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
               return dark;
           }
       }
       #endif
       return light;
    }];
}

+ (UIColor *)fs_colorWithDynamicProvider:(UIColor * (^)(UITraitCollection *traitCollection))dynamicProvider{
    return [[self alloc] fs_initWithDynamicProvider:dynamicProvider];
}

- (UIColor *)fs_initWithDynamicProvider:(UIColor * (^)(UITraitCollection *traitCollection))dynamicProvider{
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        return [[UIColor alloc] initWithDynamicProvider:dynamicProvider];
    }
#elif __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_12_0
    if (@available(iOS 12.0, *)) {
        return dynamicProvider([UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]);
    }
#endif
    return dynamicProvider([UITraitCollection new]);
}

@end

@interface FSPDFPermissionProvider : FSPermissionProvider
@property (nonatomic, assign) BOOL hiddenBookmakr;
@end

@implementation FSPDFPermissionProvider

- (FSPermissionState) checkPermission:(FSFunction)function{
    if (function == FSFunctionPDFBookMark){
        return self.hiddenBookmakr ?  FSPermissionStateHide :  FSPermissionStateShow;
    }
    return [super checkPermission:function];
}

@end


@interface PDFViewController : UIViewController
@property (nonatomic, weak) UIExtensionsManager *extensionsManager;
@end

@interface FoxitPdf : CDVPlugin <IDocEventListener,UIExtensionsManagerDelegate>{
    // Member variables go here.
}
@property (nonatomic, strong) FSPDFPermissionProvider *pdfPermissionProvider;
@property (nonatomic, strong) NSArray *topToolbarVerticalConstraints;
@property (nonatomic, strong) UIExtensionsManager *extensionsMgr;
@property (nonatomic, strong) FSPDFViewCtrl *pdfViewControl;
@property (nonatomic, strong) UINavigationController *pdfRootViewController;
@property (nonatomic, strong) PDFViewController *pdfViewController;
@property (nonatomic, strong) FSPDFDoc *currentDoc;

@property (nonatomic, strong) CDVInvokedUrlCommand *pluginCommand;

@property (nonatomic, strong) NSString *filePathSaveTo;
@property (nonatomic, copy) NSString *filePassword;
@property (nonatomic, assign) BOOL isEnableAnnotations;

@property (nonatomic, strong) FSPDFDoc *tempDoc;
@property (nonatomic, strong) NSMutableArray *bottomBarItemStatus;
@property (nonatomic, strong) NSMutableArray *topBarItemStatus;
@property (nonatomic, strong) NSMutableArray *toolbarItemStatus;

- (void)Preview:(CDVInvokedUrlCommand *)command;
@end

@implementation FoxitPdf
{
    NSString *tmpCommandCallbackID;
}
static FSErrorCode initializeCode = FSErrUnknown;
static NSString *initializeSN;
static NSString *initializeKey;

- (void)handleCDVInvokedUrlCommand:(CDVInvokedUrlCommand *)command status:(CDVCommandStatus)status msg:(id)msg{
    CDVPluginResult *pluginResult;
    if ([msg isKindOfClass:[NSString class]]){
        pluginResult = [CDVPluginResult resultWithStatus:status messageAsString:msg];
    }else if ([msg isKindOfClass:[NSDictionary class]]){
        pluginResult = [CDVPluginResult resultWithStatus:status messageAsDictionary:msg];
    }else if ([msg isKindOfClass:[NSArray class]]){
        pluginResult = [CDVPluginResult resultWithStatus:status messageAsArray:msg];
    }else if ([msg isKindOfClass:[NSValue class]]){
        pluginResult = [CDVPluginResult resultWithStatus:status messageAsBool:[msg boolValue]];
    }
    
    if (pluginResult){
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)initialize:(CDVInvokedUrlCommand*)command{
    // init foxit sdk
    
    NSDictionary *options = [command argumentAtIndex:0];
    if ([options isKindOfClass:[NSNull class]]) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"Invalid license"];
        return;
    }
    self.isEnableAnnotations = YES;
    NSString *sn = options[@"foxit_sn"];
    NSString *key = options[@"foxit_key"];
    
    if (![initializeSN isEqualToString:sn] || ![initializeKey isEqualToString:key]) {
        if (initializeCode == FSErrSuccess) [FSLibrary destroy];
        initializeCode = [FSLibrary initialize:sn key:key];
        if (initializeCode != FSErrSuccess) {
            [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"Invalid license"];
            return;
        }else{
            initializeSN = sn;
            initializeKey = key;
            self.bottomBarItemStatus = @[].mutableCopy;
            self.topBarItemStatus = @[].mutableCopy;
            self.toolbarItemStatus = @[].mutableCopy;
            [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Initialize succeeded"];
        }
    }else{
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Initialized"];
    }
}

- (void)openDocument:(CDVInvokedUrlCommand*)command{
    [self Preview:command];
}

- (void)setBottomToolbarItemVisible:(CDVInvokedUrlCommand*)command{
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:errMsg];
        return;
    }
    
    
    NSDictionary* options = [command argumentAtIndex:0];
    int index = [options[@"index"] intValue];
    id obj = [options objectForKey:@"visible"];
    BOOL isHidden = obj ? !([obj boolValue]) : NO;
    
    NSUInteger itemTag = -1;
    switch (index) {
        case 0:
            itemTag = FS_TOOLBAR_ITEM_TAG_PANEL; // list
            break;
        case 1:
            itemTag = FS_TOOLBAR_ITEM_TAG_VIEW_SETTINGS; // view
            break;
        case 2:
            itemTag = FS_TOOLBAR_ITEM_TAG_THUMBNAIL; //thumbnail
            break;
        case 3:
            itemTag = FS_TOOLBAR_ITEM_TAG_READING_BOOKMARK; // bookmark
            break;
        default:
            break;
    }
    
    if (itemTag == -1) return;
    
    NSMutableDictionary *status = @{}.mutableCopy;
    [status setObject:@(itemTag) forKey:@"itemTag"];
    [status setObject:@(isHidden) forKey:@"hidden"];
    [self.bottomBarItemStatus addObject:status];
}

- (void)setTopToolbarItemVisible:(CDVInvokedUrlCommand*)command{
    
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:errMsg];
        return;
    }
    
    
    NSDictionary* options = [command argumentAtIndex:0];
    int index = [options[@"index"] intValue];
    id obj = [options objectForKey:@"visible"];
    BOOL isHidden = obj ? !([obj boolValue]) : NO;
    
    NSUInteger itemTag = -1;
    switch (index) {
        case 0:
            itemTag = FS_TOOLBAR_ITEM_TAG_BACK; // back
            break;
        case 1:
            itemTag = FS_TOOLBAR_ITEM_TAG_PANEL; // panel
            break;
        case 2:
            itemTag = FS_TOOLBAR_ITEM_TAG_THUMBNAIL; //thumbnail
            break;
        case 3:
            itemTag = FS_TOOLBAR_ITEM_TAG_READING_BOOKMARK; // bookmark
            break;
        case 4:
            itemTag = FS_TOOLBAR_ITEM_TAG_SEARCH; // search
            break;
        case 5:
            itemTag = FS_TOOLBAR_ITEM_TAG_MORE; // more
            break;
        default:
            break;
    }
    
    if (itemTag == -1) return;
    
    NSMutableDictionary *status = @{}.mutableCopy;
    [status setObject:@(itemTag) forKey:@"itemTag"];
    [status setObject:@(isHidden) forKey:@"hidden"];
    [self.topBarItemStatus addObject:status];
}

- (void)setToolbarItemVisible:(CDVInvokedUrlCommand*)command{
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:errMsg];
        return;
    }
    
    
    NSDictionary* options = [command argumentAtIndex:0];
    int index = [options[@"index"] intValue];
    id obj = [options objectForKey:@"visible"];
    BOOL isHidden = obj ? !([obj boolValue]) : NO;
    
    NSUInteger itemTag = -1;
    switch (index) {
        case 0:
            itemTag = FS_TOOLBAR_ITEM_TAG_BACK; // back
            break;
        case 1:
            itemTag = FS_TOOLBAR_ITEM_TAG_MORE; // more
            break;
        case 2:
            itemTag = FS_TOOLBAR_ITEM_TAG_SEARCH; //search
            break;
        case 3:
            itemTag = FS_TOOLBAR_ITEM_TAG_PANEL; // panel
            break;
        case 4:
            itemTag = FS_TOOLBAR_ITEM_TAG_VIEW_SETTINGS; // view
            break;
        case 5:
            itemTag = FS_TOOLBAR_ITEM_TAG_THUMBNAIL; // thumbnail
            break;
        case 6:
            itemTag = FS_TOOLBAR_ITEM_TAG_READING_BOOKMARK; // bookmark
            break;
        case 7:
            itemTag = FS_TOOLBAR_ITEM_TAG_HOME; // home
            break;
        case 8:
            itemTag = FS_TOOLBAR_ITEM_TAG_EDIT; // edit
            break;
        case 9:
            itemTag = FS_TOOLBAR_ITEM_TAG_COMMENT; // comment
            break;
        case 10:
            itemTag = FS_TOOLBAR_ITEM_TAG_DRAWING; // drawing
            break;
        case 11:
            itemTag = FS_TOOLBAR_ITEM_TAG_VIEW; // view
            break;
        case 12:
            itemTag = FS_TOOLBAR_ITEM_TAG_FORM; // form
            break;
        case 13:
            itemTag = FS_TOOLBAR_ITEM_TAG_SIGN; // sign
            break;
        case 14:
            itemTag = FS_TOOLBAR_ITEM_TAG_PROTECT; // protect
            break;
        default:
            break;
    }
    
    if (itemTag == -1) return;
    
    NSMutableDictionary *status = @{}.mutableCopy;
    [status setObject:@(itemTag) forKey:@"itemTag"];
    [status setObject:@(isHidden) forKey:@"hidden"];
    [self.toolbarItemStatus addObject:status];
}

- (void)initializeScanner:(CDVInvokedUrlCommand*)command{
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    unsigned long serial1 = [options[@"serial1"] unsignedLongValue];
    unsigned long serial2 = [options[@"serial2"] unsignedLongValue];
    [PDFScanManager initializeScanner:serial1 serial2:serial2];

    if ([PDFScanManager initializeScanner:serial1 serial2:serial2] != FSErrSuccess) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"Invalid license"];
    }else{
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:nil];
    }
}

- (void)initializeCompression:(CDVInvokedUrlCommand*)command{
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    unsigned long serial1 = [options[@"serial1"] unsignedLongValue];
    unsigned long serial2 = [options[@"serial2"] unsignedLongValue];
    [PDFScanManager initializeScanner:serial1 serial2:serial2];

    if ([PDFScanManager initializeScanner:serial1 serial2:serial2] != FSErrSuccess) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"Invalid license"];
    }else{
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:nil];
    }
}

- (void)createScanner:(CDVInvokedUrlCommand*)command{
    UIViewController *VC = [[PDFScanManager shareManager] getPDFScanView];
    if (VC) {
        VC.modalPresentationStyle = UIModalPresentationFullScreen;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.viewController presentViewController:VC animated:YES completion:nil];
        });
        [PDFScanManager setSaveAsCallBack:^(NSError * _Nullable error, NSString * _Nullable savePath) {
              if (savePath) {
                  if (VC.presentingViewController) {
                      [VC.presentingViewController dismissViewControllerAnimated:NO completion:nil];
                  }
                  [VC dismissViewControllerAnimated:NO completion:nil];
                  [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@{@"type":@"onDocumentAdded", @"error":@(0), @"info":savePath}];
              }else{
                  [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@{@"type":@"onDocumentAdded", @"error":@(1), @"info":@""}];

              }
        }];
    }
}

- (void)setSavePath:(CDVInvokedUrlCommand *)command{
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    NSString *savePath = [options objectForKey:@"savePath"];
    self.filePathSaveTo = [self correctFilePath:savePath];
    
    if (self.filePathSaveTo) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Set savePath succeeded"];
    }else{
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"Set savePath failed"];
    }
}

- (void)importFromFDF:(CDVInvokedUrlCommand*)command{
    
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    NSString *fdfPath = [options objectForKey:@"fdfPath"];
    fdfPath = [self correctFilePath:fdfPath];
    if (!fdfPath) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"fdfPath is not found"];
        return;
    }
    
    if (!self.pdfViewControl || !self.currentDoc || [self.currentDoc isEmpty]) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"current doc is empty"];
        return;
    }
    
    NSNumber *types = [options objectForKey:@"dataType"];
    NSArray *pageRange = [options objectForKey:@"pageRange"];
    
    FSFDFDoc *fdoc = [[FSFDFDoc alloc] initWithPath:fdfPath];
    if ([fdoc isEmpty]) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"fdf doc is empty"];
        return;
    }
    FSPDFDoc *doc = self.currentDoc;
    FSRange *range = [[FSRange alloc] init];
    
    for (int i = 0; i < pageRange.count; i++) {
        NSArray *rangeNum = pageRange[i];
        if ([rangeNum isKindOfClass:[NSArray class]] && rangeNum.count != 0) {
            int start = [(NSNumber *)rangeNum[0] intValue];
            int end = [(NSNumber *)rangeNum[1] intValue];
            [range addSegment:start end_index:start+end-1 filter:FSRangeAll];
        }
    }
    
    @try {
        BOOL flag = [doc importFromFDF:fdoc types:types.intValue page_range:range];
        if (flag) {
            [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Successfully import the fdf doc"];
            [self.extensionsMgr.pdfViewCtrl refresh];
            self.extensionsMgr.isDocModified = YES;
        }
    } @catch (NSException *exception) {
        NSLog(@"Import the FDF failed");
    }
}

- (void)exportToFDF:(CDVInvokedUrlCommand*)command{
    
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    NSString *exportPath = [options objectForKey:@"exportPath"];
    exportPath = [self correctFilePath:exportPath];
    if (!exportPath) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"exportPath is error"];
        return;
    }
    
    if (!self.pdfViewControl || !self.currentDoc || [self.currentDoc isEmpty]) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"current doc is empty"];
        return;
    }
    
    NSNumber *types = [options objectForKey:@"dataType"];
    NSArray *pageRange = [options objectForKey:@"pageRange"];
    NSNumber *fdfDocType = [options objectForKey:@"fdfDocType"];
    
    FSFDFDoc *fdoc = [[FSFDFDoc alloc] initWithType:fdfDocType.intValue];
    if ([fdoc isEmpty]) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"fdf doc is empty"];
        return;
    }
    FSPDFDoc *doc = self.currentDoc;
    FSRange *range = [[FSRange alloc] init];
    
    for (int i = 0; i < pageRange.count; i++) {
        NSArray *rangeNum = pageRange[i];
        if ([rangeNum isKindOfClass:[NSArray class]] && rangeNum.count != 0) {
            int start = [(NSNumber *)rangeNum[0] intValue];
            int end = [(NSNumber *)rangeNum[1] intValue];
            [range addSegment:start end_index:start+end-1 filter:FSRangeAll];
        }
    }
    
    @try {
        BOOL flag = [doc exportToFDF:fdoc types:types.intValue page_range:range];
        if (flag) {
            [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Successfully export the fdf doc"];
            [self.extensionsMgr.pdfViewCtrl refresh:self.extensionsMgr.pdfViewCtrl.getCurrentPage];
            if ([fdoc saveAs:exportPath]) {
                NSLog(@"Successfully save the fdf doc");
                [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Successfully save the fdf doc"];
            }
        }else{
            [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"Export the FDF failed"];
        }
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"Export the FDF failed"];
    }
}

- (void)Preview:(CDVInvokedUrlCommand*)command
{
    self.pluginCommand = command;
    
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:errMsg];
        return;
    }
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSLog(@"%@", docDir);
    
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    NSString *password = [options objectForKey:@"password"];
    password = [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (password.length >0 ) {
        self.filePassword = password;
    }
    
    // URL
    //    NSString *filePath = [command.arguments objectAtIndex:0];
    NSString *filePath = [options objectForKey:@"path"];
    
    // check file exist
    filePath = [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *fileURL = [[NSURL alloc] initWithString:filePath];
    [fileURL.path stringByRemovingPercentEncoding];
    
    BOOL isFileExist = [self isExistAtPath:fileURL.path];
    
    if (filePath != nil && filePath.length > 0 && isFileExist) {
        // preview
        [self FoxitPdfPreview:fileURL.path];
    } else {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"file not found"];
    }
}

- (void)enableAnnotations:(CDVInvokedUrlCommand*)command
{
    self.pluginCommand = command;
    
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:errMsg];
        return;
    }
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = nil;
    }
    id obj = [options objectForKey:@"enable"];
    BOOL val = obj?[obj boolValue]:YES;
    self.isEnableAnnotations = options?val:YES;

}

- (void)setAutoSaveDoc:(CDVInvokedUrlCommand*)command
{
    self.pluginCommand = command;
    
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:errMsg];
        return;
    }
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = nil;
    }
    id obj = [options objectForKey:@"enable"];
    BOOL val = obj ? [obj boolValue] : YES;
    self.extensionsMgr.isAutoSaveDoc = options ? val : YES;

}

- (UIColor *)jsvalueToOCColor:(id)jsvalue{
    UIColor *color = nil;
    if ([jsvalue isKindOfClass:[NSString class]]) {
        if ([jsvalue hasPrefix:@"#"] || [jsvalue hasPrefix:@"0x"] || [jsvalue hasPrefix:@"0X"]) {
            color = [UIColor colorWithHexString:jsvalue];
        }else if ([jsvalue hasPrefix:@"rgb"] || [jsvalue hasPrefix:@"rgba"]){
            float r = 0, g = 0, b = 0, a = 0;
            if (sscanf([jsvalue UTF8String], "rgba(%f,%f,%f,%f)", &r, &g, &b, &a) == 4) {
                color = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a];
            }else if (sscanf([jsvalue UTF8String], "rgb(%f,%f,%f)", &r, &g, &b) == 3){
                color = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1];
            }
        }
    }else if ([jsvalue isKindOfClass:[NSNumber class]]){
        NSUInteger hex = [jsvalue unsignedIntegerValue];
        if (hex > 0xFFFFFF) {
            color = [UIColor colorWithRed:((hex & 0xFF0000) >> 16) / 255.0f
                                    green:((hex & 0xFF00) >> 8) / 255.0f
                                     blue:(hex & 0xFF) / 255.0f
                                    alpha:((hex & 0xFF000000) >> 24) / 255.0f];
        }else{
            color = [UIColor colorWithRed:((hex & 0xFF0000) >> 16) / 255.0f
                                    green:((hex & 0xFF00) >> 8) / 255.0f
                                     blue:(hex & 0xFF) / 255.0f
                                    alpha:1];
        }
        
    }
    return color;
}

- (void)setPrimaryColor:(CDVInvokedUrlCommand*)command
{
    self.pluginCommand = command;
    
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:errMsg];
        return;
    }
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = nil;
    }
    id light = [options objectForKey:@"light"];
    id dark = [options objectForKey:@"dark"];
    
    light = [self jsvalueToOCColor:light];
    dark = [self jsvalueToOCColor:dark];
    
    UIColor *color = [UIColor fs_colorWithLight:light dark:dark];
    [UIExtensionsManager setPrimaryColor:color];
}

- (FSPDFViewCtrl *)pdfViewControl{
    if (!_pdfViewControl) {
        _pdfViewControl = [[FSPDFViewCtrl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [_pdfViewControl setRMSAppClientId:@"972b6681-fa03-4b6b-817b-c8c10d38bd20" redirectURI:@"com.foxitsoftware.com.mobilepdf-for-ios://authorize"];
        [_pdfViewControl registerDocEventListener:self];
        _pdfViewControl.extensionsManager = self.extensionsMgr;
    }
    return _pdfViewControl;
}

- (FSPDFPermissionProvider *)pdfPermissionProvider{
    if (!_pdfPermissionProvider) {
        _pdfPermissionProvider = [[FSPDFPermissionProvider alloc] init];
    }
    return _pdfPermissionProvider;
}

- (UIExtensionsManager *)extensionsMgr{
    if (!_extensionsMgr) {
        NSString *configPath = [[NSBundle mainBundle] pathForResource:@"uiextensions_config" ofType:@"json"];
        UIExtensionsConfig* uiConfig = [[UIExtensionsConfig alloc] initWithJSONData:[NSData dataWithContentsOfFile:configPath]];
        _extensionsMgr = [[UIExtensionsManager alloc] initWithPDFViewControl:self.pdfViewControl configurationObject:uiConfig];
        _extensionsMgr.delegate = self;
        _extensionsMgr.permissionProvider = self.pdfPermissionProvider;
        
        if(self.isEnableAnnotations == NO) {
            uiConfig.loadAttachment = NO;
            uiConfig.tools = [[NSMutableSet<NSString *> alloc] initWithObjects:Tool_Select,Tool_Signature, nil];
        }
        
        for (int i = 0; i < self.toolbarItemStatus.count; i++) {
            NSMutableDictionary* status = self.toolbarItemStatus[i];
            FS_TOOLBAR_ITEM_TAG itemTag = [status[@"itemTag"] intValue];
            id obj = [status objectForKey:@"hidden"];
            BOOL isHidden = obj ? [obj boolValue] : NO;
            [_extensionsMgr setToolbarItemHiddenWithTag:itemTag hidden:isHidden];
            if (itemTag == FS_TOOLBAR_ITEM_TAG_MORE){
                UIView *more = [_extensionsMgr valueForKeyPath:@"smallTopToolbar.moreBtn"];
                more.hidden = isHidden;
            }
            if (itemTag == FS_TOOLBAR_ITEM_TAG_READING_BOOKMARK){
                self.pdfPermissionProvider.hiddenBookmakr = isHidden;
            }

        }
        for (int i = 0; i < self.bottomBarItemStatus.count; i++) {
            NSMutableDictionary* status = self.bottomBarItemStatus[i];
            FS_TOOLBAR_ITEM_TAG itemTag = [status[@"itemTag"] intValue];
            id obj = [status objectForKey:@"hidden"];
            BOOL isHidden = obj ? [obj boolValue] : NO;
            [_extensionsMgr setToolbarItemHiddenWithTag:itemTag hidden:isHidden];
            if (itemTag == FS_TOOLBAR_ITEM_TAG_READING_BOOKMARK){
                self.pdfPermissionProvider.hiddenBookmakr = isHidden;
            }
        }
        
        for (int i = 0; i < self.topBarItemStatus.count; i++) {
            NSMutableDictionary* status = self.topBarItemStatus[i];
            FS_TOOLBAR_ITEM_TAG itemTag = [status[@"itemTag"] intValue];
            id obj = [status objectForKey:@"hidden"];
            BOOL isHidden = obj ? [obj boolValue] : NO;
            [_extensionsMgr setToolbarItemHiddenWithTag:itemTag hidden:isHidden];
            if (itemTag == FS_TOOLBAR_ITEM_TAG_MORE){
                UIView *more = [_extensionsMgr valueForKeyPath:@"smallTopToolbar.moreBtn"];
                more.hidden = isHidden;
            }
        }

    }
    return _extensionsMgr;
}

- (PDFViewController *)pdfViewController{
    if (!_pdfViewController) {
        _pdfViewController = [[PDFViewController alloc] init];
        _pdfViewController.extensionsManager = self.extensionsMgr;
        _pdfViewController.view = self.pdfViewControl;
    }
    return _pdfViewController;
}

- (UINavigationController *)pdfRootViewController{
    if (!_pdfRootViewController) {

        _pdfRootViewController = [[UINavigationController alloc] initWithRootViewController:self.pdfViewController];
        _pdfRootViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        _pdfRootViewController.navigationBarHidden = YES;
    }
    return _pdfRootViewController;
}


# pragma mark -- Foxit preview
-(void)FoxitPdfPreview:(NSString *)filePath {
    
    //load doc
    if (filePath == nil) {
        filePath = [[NSBundle mainBundle] pathForResource:@"getting_started_ios" ofType:@"pdf"];
    }
    
    if(self.filePathSaveTo && self.filePathSaveTo.length >0){
        self.extensionsMgr.preventOverrideFilePath = self.filePathSaveTo;
    }
    
    __weak FoxitPdf* weakSelf = self;
    [self.pdfViewControl openDoc:filePath
                        password:self.filePassword
                      completion:^(FSErrorCode error) {
                          if (error != FSErrSuccess) {
                              [self handleCDVInvokedUrlCommand:self.pluginCommand status:CDVCommandStatus_ERROR msg:@{@"FSErrorCode":@(error), @"info":@"failed open the pdf"}];
                              
                              dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
                              
                              dispatch_after(delayTime, dispatch_get_main_queue(), ^{
                                  [weakSelf showAlertViewWithTitle:@"error" message:@"Failed to open the document"];
                                  [weakSelf.pdfViewController dismissViewControllerAnimated:YES completion:nil];
                              });
                              
                              [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
                          }else{
                              weakSelf.currentDoc = weakSelf.pdfViewControl.currentDoc;
                              [self handleCDVInvokedUrlCommand:self.pluginCommand status:CDVCommandStatus_OK msg:@{@"FSErrorCode":@(error), @"info":@"Open the document successfully"}];
                              // Run later to avoid the "took a long time" log message.
                              weakSelf.pdfRootViewController.modalPresentationStyle = UIModalPresentationFullScreen;
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [weakSelf.viewController presentViewController:weakSelf.pdfRootViewController animated:YES completion:nil];
                              });
                          }
                      }];
    //    self.pdfViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    self.topToolbarVerticalConstraints = @[];
    
    self.extensionsMgr.goBack = ^() {
        [weakSelf.pdfViewController dismissViewControllerAnimated:YES completion:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
    };
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleStatusBarOrientationChange:)
                                                name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:action];
        [self.topViewController presentViewController:alertController animated:YES completion:nil];
    });
}

#pragma mark - rotate event
- (void)handleStatusBarOrientationChange: (NSNotification *)notification{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self.extensionsMgr didRotateFromInterfaceOrientation:interfaceOrientation];
}

#pragma mark <IDocEventListener>

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    // Called when a document is opened.
    self.currentDoc = document;
    
    [self handleCDVInvokedUrlCommand:self.pluginCommand status:CDVCommandStatus_OK msg:@{@"type":@"onDocOpened", @"info":@"info", @"error":@(error)}];
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    // Called when a document is closed.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.currentDoc = nil;
        [self.bottomBarItemStatus removeAllObjects];
        [self.topBarItemStatus removeAllObjects];
        [self.toolbarItemStatus removeAllObjects];
    });
}

- (void)onDocWillSave:(FSPDFDoc *)document {
    self.currentDoc = document;
    
    [self handleCDVInvokedUrlCommand:self.pluginCommand status:CDVCommandStatus_OK msg:@{@"type":@"onDocWillSave", @"info":@"info"}];
}

- (void)onDocSaved:(FSPDFDoc *)document error:(int)error{
    self.currentDoc = document;
    
    [self handleCDVInvokedUrlCommand:self.pluginCommand status:CDVCommandStatus_OK msg:@{@"type":@"onDocSaved", @"info":@"info", @"error":@(error)}];
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

- (NSString *)correctFilePath:(NSString *)filePath{
    NSString *path = [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (path.length >0 ) {
        NSURL *filePathSaveTo = [NSURL fileURLWithPath:path];
        path = [filePathSaveTo.path stringByRemovingPercentEncoding];
        if ([path hasPrefix:@"/file:/"]) {
            path = [path stringByReplacingOccurrencesOfString:@"/file:" withString:@""];
        }
        return path;
    }
    return nil;
}

# pragma mark form
-(BOOL)checkIfCanUsePDFFormCommand:(CDVInvokedUrlCommand *)command{
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:errMsg];
        return NO;
    }
    
    if (!self.pdfViewControl || !self.currentDoc || [self.currentDoc isEmpty]) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"current doc is empty"];
        return NO;
    }
    
    if (![self.currentDoc hasForm]) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"The current document does not have interactive form."];
        return NO;
    }
    
    return YES;
}

- (void)getAllFormFields:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    @try {
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        int fieldCount = [pForm getFieldCount:@""];
        NSMutableArray *tempArray = @[].mutableCopy;
        for (int i = 0; i < fieldCount; i++) {
            FSField* pFormField = [pForm getField:i filter:@""];
            
            NSMutableDictionary *tempField = @{}.mutableCopy;
            tempField = [self getDictionaryOfField:pFormField form:nil];
            [tempField setObject:@(i) forKey:@"fieldIndex"];
            
            [tempArray addObject:tempField];
        }
        
        NSLog(@"%@",tempArray);
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:tempArray];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
}

- (void)getForm:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;

    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    @try {
        
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        
        NSMutableDictionary *tempFormInfo = @{}.mutableCopy;
        [tempFormInfo setObject:@(pForm.alignment) forKey:@"alignment"];
        [tempFormInfo setObject:@(pForm.needConstructAppearances) forKey:@"needConstructAppearances"];
        
        NSMutableDictionary *defaultAppearance = @{}.mutableCopy;
        FSDefaultAppearance *fsdefaultappearance = pForm.defaultAppearance;
        [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"flags"];
        [defaultAppearance setObject:@(fsdefaultappearance.text_size) forKey:@"textSize"];
        [defaultAppearance setObject:@(fsdefaultappearance.text_color) forKey:@"textColor"];
        [tempFormInfo setObject:defaultAppearance forKey:@"defaultAppearance"];
        
        NSLog(@"%@",tempFormInfo);
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:tempFormInfo];
        
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
}

- (void)updateForm:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;

    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    @try {
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        
        NSDictionary* options = [command argumentAtIndex:0];
        NSLog(@"%@",options);
        NSDictionary *formInfo = options[@"forminfo"];
        
        BOOL isModified = NO;
        
        if ([formInfo objectForKey:@"alignment"] && pForm.alignment != [formInfo[@"alignment"] intValue]) {
            pForm.alignment = [formInfo[@"alignment"] intValue];
            isModified = YES;
        }
        
        if ([formInfo objectForKey:@"needConstructAppearances"] && pForm.needConstructAppearances != [formInfo[@"needConstructAppearances"] boolValue]) {
            [pForm setConstructAppearances:[formInfo[@"needConstructAppearances"] boolValue]];
            isModified = YES;
        }
        
        if ([formInfo objectForKey:@"defaultAppearance"]) {
            NSDictionary *dfapDict = [formInfo objectForKey:@"defaultAppearance"];
            FSDefaultAppearance *fsdefaultappearance = pForm.defaultAppearance;
            
            if ([dfapDict objectForKey:@"flags"] ) {
                [fsdefaultappearance setFlags:[[dfapDict objectForKey:@"flags"] intValue]];
                isModified = true;
            }
            
            if ([dfapDict objectForKey:@"textSize"] ) {
                [fsdefaultappearance setText_size:[[dfapDict objectForKey:@"textSize"] floatValue]];
                isModified = true;
            }
            
            if ([dfapDict objectForKey:@"textColor"] ) {
                [fsdefaultappearance setText_color: [[dfapDict objectForKey:@"textColor"] intValue]];
                isModified = true;
            }
            
            pForm.defaultAppearance = fsdefaultappearance;
        }
        
        self.extensionsMgr.isDocModified = isModified;
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Update form info success"];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
}

- (void)formValidateFieldName:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    @try {
        
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        
        NSDictionary* options = [command argumentAtIndex:0];
        NSLog(@"%@",options);
        
        int fSFieldType = [options[@"fieldType"] intValue];
        NSString *fieldName = options[@"fieldName"];
        
        BOOL isCanbeUsed = [pForm validateFieldName:fSFieldType field_name:fieldName];
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@(isCanbeUsed)];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (void)formRenameField:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int fieldIndex = [options[@"fieldIndex"] intValue];
    NSString *newFieldName = options[@"newFieldName"];
    
    @try {
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        int fieldCount = [pForm getFieldCount:@""];
        
        BOOL isRenameSuccessed = NO;
        for (int i = 0; i < fieldCount; i++) {
            if (i == fieldIndex) {
                FSField* pFormField = [pForm getField:i filter:@""];
                isRenameSuccessed = [pForm renameField:pFormField new_field_name:newFieldName];
                self.extensionsMgr.isDocModified = isRenameSuccessed;
            }
        }
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"The field was successfully renamed"];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (void)formRemoveField:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int fieldIndex = [options[@"fieldIndex"] intValue];
    
    @try {
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        FSField* pFormField = [pForm getField:fieldIndex filter:@""];
        [pForm removeField:pFormField];
        
        self.extensionsMgr.isDocModified = YES;
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Remove field success"];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (void)formReset:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    @try {
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        BOOL isReset = [pForm reset];
        self.extensionsMgr.isDocModified = isReset;
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"The form was successfully reset"];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (void)formExportToXML:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    NSString *filePath = options[@"filePath"];
    filePath = [self correctFilePath:filePath];
    @try {
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        BOOL isExport = [pForm exportToXML:filePath];
        //        self.extensionsMgr.isDocModified = isExport;
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"The form has been successfully exported."];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
}

- (void)formImportFromXML:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    NSString *filePath = options[@"filePath"];
    filePath = [self correctFilePath:filePath];
    @try {
        
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        BOOL isImport = [pForm importFromXML:filePath];
        self.extensionsMgr.isDocModified = isImport;

        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"The form has been successfully imported."];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (void)formGetPageControls:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int pageIndex = [options[@"pageIndex"] intValue];
    
    @try {
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        FSPDFPage *page = [self.currentDoc getPage:pageIndex];
        int pageControlCount = [pForm getControlCount:page];
        
        NSMutableArray *tempArr = @[].mutableCopy;
        for (int i = 0 ; i < pageControlCount; i++) {
            FSControl *pControl = [pForm getControl:page index:i];
            
            NSMutableDictionary *tempDic = @{}.mutableCopy;
            [tempDic setObject:@(i) forKey:@"controlIndex"];
            [tempDic setObject:pControl.exportValue forKey:@"exportValue"];
            [tempDic setObject:@([pControl isChecked]) forKey:@"isChecked"];
            [tempDic setObject:@([pControl isDefaultChecked]) forKey:@"isDefaultChecked"];
            
            [tempArr addObject:tempDic];
        }
        
        NSLog(@"%@",tempArr);
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:tempArr];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
}

- (void)formRemoveControl:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int pageIndex = [options[@"pageIndex"] intValue];
    int controlIndex = [options[@"controlIndex"] intValue];
    
    @try {
        
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        FSPDFPage *page = [self.currentDoc getPage:pageIndex];
        
        FSControl *pControl = [pForm getControl:page index:controlIndex];
        [pForm removeControl:pControl];
        
        self.extensionsMgr.isDocModified = YES;
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Remove control success"];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (void)formAddControl:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
    if (FSErrSuccess != initializeCode) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:errMsg];
        return;
    }
    
    if (!self.pdfViewControl || !self.currentDoc || [self.currentDoc isEmpty]) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:@"current doc is empty"];
        return;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int pageIndex = [options[@"pageIndex"] intValue];
    NSString *fieldName = options[@"fieldName"];
    int fieldType = [options[@"fieldType"] intValue];
    NSDictionary *rect = options[@"rect"];
    
    @try {
        FSRectF *fsrect = [[FSRectF alloc] initWithLeft1:[[rect objectForKey:@"left"] floatValue] bottom1:[[rect objectForKey:@"bottom"] floatValue] right1:[[rect objectForKey:@"right"] floatValue] top1:[[rect objectForKey:@"top"] floatValue] ];
        
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        FSPDFPage *page = [self.currentDoc getPage:pageIndex];
        
        FSControl *pControl = [pForm addControl:page field_name:fieldName field_type:fieldType rect:fsrect];
        
        NSMutableDictionary *tempDic = @{}.mutableCopy;
        [tempDic setObject:@([pForm getControlCount:page] -1) forKey:@"controlIndex"];
        [tempDic setObject:pControl.exportValue forKey:@"exportValue"];
        [tempDic setObject:@([pControl isChecked]) forKey:@"isChecked"];
        [tempDic setObject:@([pControl isDefaultChecked]) forKey:@"isDefaultChecked"];
        
        self.extensionsMgr.isDocModified = YES;
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:tempDic];
        
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (void)formUpdateControl:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    
    int pageIndex = [options[@"pageIndex"] intValue];
    int controlIndex = [options[@"controlIndex"] intValue];
    NSDictionary *control = options[@"control"];
    
    @try {
        
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        FSPDFPage *page = [self.currentDoc getPage:pageIndex];
        
        FSControl *pControl = [pForm getControl:page index:controlIndex];
        
        BOOL isModified = NO;
        
        if ([control objectForKey:@"exportValue"] && ![pControl.exportValue isEqualToString:control[@"exportValue"]]) {
            pControl.exportValue = control[@"exportValue"];
            isModified = YES;
        }
        
        if ([control objectForKey:@"isChecked"] && pControl.isChecked != [control[@"isChecked"] boolValue]) {
            [pControl setChecked:[control[@"isChecked"] boolValue]];
            isModified = YES;
        }
        
        if ([control objectForKey:@"isDefaultChecked"] && pControl.isDefaultChecked != [control[@"isDefaultChecked"] boolValue]) {
            [pControl setDefaultChecked:[control[@"isDefaultChecked"] boolValue]];
            isModified = YES;
        }
        
        self.extensionsMgr.isDocModified = isModified;
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"Update control info success"];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (NSMutableDictionary *)getDictionaryOfField:(FSField *)pFormField form:(FSForm *)pForm {
    NSMutableDictionary *tempField = @{}.mutableCopy;
    
    if (pForm != nil) {
        int fieldIndex = -1;
        int fieldCount = [pForm getFieldCount:@""];
        for (int i = 0; i < fieldCount; i++) {
            FSField *tempField = [pForm getField:i filter:@""];
            if (tempField.getType == pFormField.getType && [tempField.getName isEqualToString:pFormField.getName] ) {
                fieldIndex = i;
            }
        }
        [tempField setObject:@(fieldIndex) forKey:@"fieldIndex"];
    }
    
    NSString* name = [pFormField getName];
    FSFieldType fieldType = [pFormField getType];
    NSString* defValue = [pFormField getDefaultValue];
    NSString* value = [pFormField getValue];
    FSFieldFlags fieldFlag = [pFormField getFlags];
    
    [tempField setObject:name forKey:@"name"];
    [tempField setObject:@(fieldType) forKey:@"fieldType"];
    [tempField setObject:defValue forKey:@"defValue"];
    [tempField setObject:value forKey:@"value"];
    [tempField setObject:@(fieldFlag) forKey:@"fieldFlag"];
    [tempField setObject:@(pFormField.alignment) forKey:@"alignment"];
    [tempField setObject:pFormField.alternateName forKey:@"alternateName"];
    
    NSMutableDictionary *defaultAppearance = @{}.mutableCopy;
    FSDefaultAppearance *fsdefaultappearance = pFormField.defaultAppearance;
    [defaultAppearance setObject:@(fsdefaultappearance.flags) forKey:@"flags"];
    [defaultAppearance setObject:@([fsdefaultappearance getText_size]) forKey:@"textSize"];
    [defaultAppearance setObject:@([fsdefaultappearance getText_color]) forKey:@"textColor"];
    
    [tempField setObject:defaultAppearance forKey:@"defaultAppearance"];
    [tempField setObject:pFormField.mappingName forKey:@"mappingName"];
    [tempField setObject:@(pFormField.maxLength) forKey:@"maxLength"];
    [tempField setObject:@(pFormField.topVisibleIndex) forKey:@"topVisibleIndex"];
    
    if (pFormField.options) {
        NSMutableArray *tempArray2 = @[].mutableCopy;
        for (int i = 0; i < [pFormField.options getSize]; i++)
        {
            FSChoiceOption *choiceoption = [pFormField.options getAt:i];
            NSMutableDictionary *tempChoiceoption = @{}.mutableCopy;
            [tempChoiceoption setObject:choiceoption.option_value forKey:@"optionValue"];
            [tempChoiceoption setObject:choiceoption.option_label forKey:@"optionLabel"];
            [tempChoiceoption setObject:@(choiceoption.selected) forKey:@"selected"];
            [tempChoiceoption setObject:@(choiceoption.default_selected) forKey:@"defaultSelected"];
            
            [tempArray2 addObject:tempChoiceoption];
        }
        
        [tempField setObject:tempArray2 forKey:@"choiceOptions"];
    }
    
    return tempField;
}

- (void)getFieldByControl:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    int pageIndex = [options[@"pageIndex"] intValue];
    int controlIndex = [options[@"controlIndex"] intValue];
    
    @try {
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        FSPDFPage *page = [self.currentDoc getPage:pageIndex];
        
        FSControl *pControl = [pForm getControl:page index:controlIndex];
        
        FSField *pFormField = [pControl getField];
        
        NSMutableDictionary *tempField = @{}.mutableCopy;
        tempField = [self getDictionaryOfField:pFormField form:pForm];
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:tempField];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}


- (void)FieldUpdateField:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    int fieldIndex = [options[@"fieldIndex"] intValue];
    NSDictionary *fsfield = options[@"field"];
    
    @try {
        
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        FSField *field = [pForm getField:fieldIndex filter:@""];
        
        BOOL isModified = NO;
        if ([fsfield objectForKey:@"value"]) {
            field.value = [fsfield objectForKey:@"value"];
            isModified = YES;
        }
        
        if ([fsfield objectForKey:@"topVisibleIndex"]) {
            field.topVisibleIndex = [[fsfield objectForKey:@"topVisibleIndex"] intValue];
            isModified = YES;
        }
        
        if ([fsfield objectForKey:@"name"]) {
            [pForm renameField:field new_field_name:[fsfield objectForKey:@"name"]];
            isModified = YES;
        }
        
        if ([fsfield objectForKey:@"maxLength"]) {
            field.maxLength = [[fsfield objectForKey:@"maxLength"] intValue];
            isModified = YES;
        }
        
        if ([fsfield objectForKey:@"mappingName"]) {
            field.mappingName = [fsfield objectForKey:@"mappingName"];
            isModified = YES;
        }
        
        if ([fsfield objectForKey:@"value"]) {
            field.flags = [[fsfield objectForKey:@"flags"] intValue];
            isModified = YES;
        }
        
        if ([fsfield objectForKey:@"defValue"]) {
            field.defaultValue = [fsfield objectForKey:@"defValue"];
            isModified = YES;
        }
        
        if ([fsfield objectForKey:@"alternateName"]) {
            field.alternateName = [fsfield objectForKey:@"alternateName"];
            isModified = YES;
        }
        
        if ([fsfield objectForKey:@"alignment"]) {
            field.alignment = [[fsfield objectForKey:@"alignment"] intValue];
            isModified = YES;
        }
        
        //    field.fieldType = fsfield[@"fieldType"];
        
        //appearance
        if ([fsfield objectForKey:@"defaultAppearance"]) {
            NSDictionary *dfapDict = [fsfield objectForKey:@"defaultAppearance"];
            FSDefaultAppearance *fsdefaultappearance = field.defaultAppearance;
            
            if ([dfapDict objectForKey:@"flags"] ) {
                [fsdefaultappearance setFlags:[[dfapDict objectForKey:@"flags"] intValue]];
                isModified = true;
            }
            
            if ([dfapDict objectForKey:@"textSize"] ) {
                [fsdefaultappearance setText_size:[[dfapDict objectForKey:@"textSize"] floatValue]];
                isModified = true;
            }
            
            if ([dfapDict objectForKey:@"textColor"] ) {
                [fsdefaultappearance setText_color:[[dfapDict objectForKey:@"textColor"] intValue] ];
                isModified = true;
            }
            
            field.defaultAppearance = fsdefaultappearance;
        }
        
        //choice
        if ([fsfield objectForKey:@"choiceOptions"]) {
            NSArray *choiceArr = [[NSArray alloc] initWithArray:fsfield[@"choiceOptions"]];
            if (choiceArr.count > 0 ) {
                FSChoiceOptionArray *choiceOptionArr = [[FSChoiceOptionArray alloc] init];
                for (int i = 0 ; i < choiceArr.count; i++) {
                    NSDictionary *choice = [[NSDictionary alloc] initWithDictionary: [choiceArr objectAtIndex:i]];
                    FSChoiceOption *choiceOption = [[FSChoiceOption alloc] initWithOption_value:choice[@"optionValue"] option_label:choice[@"optionLabel"] selected:choice[@"selected"] default_selected:choice[@"defaultSelected"]];
                    [choiceOptionArr add:choiceOption];
                }
                field.options = choiceOptionArr;
                
                isModified = YES;
            }
        }
        
        NSMutableDictionary *tempField = @{}.mutableCopy;
        tempField = [self getDictionaryOfField:field form:pForm];
        
        self.extensionsMgr.isDocModified = isModified;
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:tempField];
        
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
    
}

- (void)FieldReset:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    int fieldIndex = [options[@"fieldIndex"] intValue];
    
    @try {
        
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        int fieldCount = [pForm getFieldCount:@""];
        BOOL isReset = NO;
        for (int i = 0; i < fieldCount; i++) {
            if (i == fieldIndex) {
                FSField* pFormField = [pForm getField:i filter:@""];
                isReset = [pFormField reset];
            }
        }
        self.extensionsMgr.isDocModified = isReset;
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:@"The field was successfully reset"];
        
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (void)getFieldControls:(CDVInvokedUrlCommand*)command{
    self.pluginCommand = command;
    
    if (![self checkIfCanUsePDFFormCommand:command]) {
        return ;
    }
    
    NSDictionary* options = [command argumentAtIndex:0];
    NSLog(@"%@",options);
    int fieldIndex = [options[@"fieldIndex"] intValue];
    
    @try {
        
        FSForm *pForm = [[FSForm alloc] initWithDocument:self.currentDoc];
        int fieldCount = [pForm getFieldCount:@""];
        NSMutableArray *tempArr = @[].mutableCopy;
        for (int i = 0; i < fieldCount; i++) {
            if (i == fieldIndex) {
                FSField* pFormField = [pForm getField:i filter:@""];
                int fieldControlCount = [pFormField getControlCount];
                for (int i = 0 ; i < fieldControlCount; i++) {
                    FSControl *pControl = [pFormField getControl:i];
                    
                    NSMutableDictionary *tempDic = @{}.mutableCopy;
                    [tempDic setObject:@([pControl getIndex]) forKey:@"controlIndex"];
                    [tempDic setObject:pControl.exportValue forKey:@"exportValue"];
                    [tempDic setObject:@([pControl isChecked]) forKey:@"isChecked"];
                    [tempDic setObject:@([pControl isDefaultChecked]) forKey:@"isDefaultChecked"];
                    
                    [tempArr addObject:tempDic];
                }
            }
        }
        
        NSLog(@"%@",tempArr);
        
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_OK msg:tempArr];
    } @catch (NSException *exception) {
        [self handleCDVInvokedUrlCommand:command status:CDVCommandStatus_ERROR msg:exception.reason];
        return;
    }
    
}

- (UIViewController *)topViewController {
    UIViewController *presentingViewController = self.viewController;
    while (presentingViewController.presentedViewController != nil) {
        presentingViewController = presentingViewController.presentedViewController;
    }
    return presentingViewController;
}

@end

@implementation PDFViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return !self.extensionsManager.isScreenLocked;
}

- (BOOL)shouldAutorotate {
    return !self.extensionsManager.isScreenLocked;
}

- (BOOL)prefersStatusBarHidden {
    return self.extensionsManager.prefersStatusBarHidden;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end


