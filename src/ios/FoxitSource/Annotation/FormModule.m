/**
 * Copyright (C) 2003-2016, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 
 */
#import "FormModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "UIExtensionsSharedHeader.h"
#import "AppDelegate.h"
#import "Utility+Demo.h"
#import "Defines.h"

@interface FormModule ()
{
    FSPDFViewCtrl* _pdfViewCtrl;
    UIExtensionsManager* _extensionsManager;
    ReadFrame* _readFrame;
}

@property (nonatomic, retain) MenuGroup *group;
@property (nonatomic, retain) MenuView *moreMenu;
@property (nonatomic, retain) MvMenuItem *exportFormItem;
@property (nonatomic, retain) MvMenuItem *importFormItem;
@property (nonatomic, retain) MvMenuItem *resetFormItem;

@end

@implementation FormModule

-(void)dealloc
{
    [_group release];
    [_moreMenu release];
    [_exportFormItem release];
    [_importFormItem release];
    [_resetFormItem release];
    [_currentCtr release];
    [super dealloc];
}


-(instancetype)initWithViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl readFrame:(ReadFrame*)readFrame
{
    self = [super init];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
        _readFrame = readFrame;
        [self loadModule];
    }
    return self;
}

-(void)loadModule
{
    self.moreMenu = _readFrame.more;
    self.group = [self.moreMenu getGroup:TAG_GROUP_FORM];
    if (!self.group) {
        self.group = [[[MenuGroup alloc] init] autorelease];
        self.group.title = NSLocalizedString(@"kForm", nil);
        self.group.tag = TAG_GROUP_FORM;
        [self.moreMenu addGroup:self.group];
    }
    self.exportFormItem = [[[MvMenuItem alloc] init] autorelease];
    self.exportFormItem.tag = TAG_ITEM_EXPORTFORM;
    self.exportFormItem.callBack = self;
    self.exportFormItem.text = NSLocalizedString(@"kExportForm", nil);
    [self.moreMenu addMenuItem:self.group.tag withItem:self.exportFormItem];
    
    self.importFormItem = [[[MvMenuItem alloc] init] autorelease];
    self.importFormItem.tag = TAG_ITEM_IMPORTFORM;
    self.importFormItem.callBack = self;
    self.importFormItem.text = NSLocalizedString(@"kImportForm", nil);
    [self.moreMenu addMenuItem:self.group.tag withItem:self.importFormItem];
    
    self.resetFormItem = [[[MvMenuItem alloc] init] autorelease];
    self.resetFormItem.tag = TAG_ITEM_RESETFORM;
    self.resetFormItem.callBack = self;
    self.resetFormItem.text = NSLocalizedString(@"kResetFormFields", nil);
    [self.moreMenu addMenuItem:self.group.tag withItem:self.resetFormItem];
}

-(void)onClick:(MvMenuItem *)item
{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    _readFrame.hiddenMoreMenu = YES;
    
    if (![_pdfViewCtrl.currentDoc hasForm]) {
        AlertView *alertView = [[[AlertView alloc] initWithTitle:nil message:@"kNoFormAvailable" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil, nil] autorelease];
        [alertView show];
        self.currentCtr = alertView;
        return;
    }
    
    if (item.tag == TAG_ITEM_EXPORTFORM) {
        unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
        bool canFillForm = allPermission & e_permFillForm;
        if (!canFillForm) {
            AlertView *alertView = [[[AlertView alloc] initWithTitle:@"kWarning" message:@"kRMSNoAccess" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil, nil] autorelease];
            [alertView show];
            return;
        }
        
        FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
        selectDestination.isRootFileDirectory = YES;
        selectDestination.fileOperatingMode = FileListMode_Select;
        [selectDestination loadFilesWithPath:DOCUMENT_PATH];
        selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder)
        {
            [selectDestination dismissModalViewControllerAnimated:YES];
            
            __block void(^inputFileName)() = ^()
            {
                inputFileName = [inputFileName copy];
                InputAlertView *inputAlertView = [[InputAlertView alloc] initWithTitle:NSLocalizedString(@"kInputNewFileName", nil) message:nil buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                    InputAlertView *inputAlert = (InputAlertView *)alertView;
                    NSString *fileName = inputAlert.inputTextField.text;
                    
                    if ([fileName rangeOfString:@"/"].location != NSNotFound)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            AlertView *alertView = [[AlertView alloc] initWithTitle:NSLocalizedString(@"kWarning",nil) message:NSLocalizedString(@"kIllegalNameWarning",nil) buttonClickHandler:^(UIView *alertView, int buttonIndex){
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    inputFileName();
                                    [inputFileName release];
                                });
                                return;
                            } cancelButtonTitle:@"kOK" otherButtonTitles:nil];
                            [alertView show];
                            [alertView release];
                        });
                        return;
                    }
                    else if(fileName.length == 0)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            inputFileName();
                            [inputFileName release];
                        });
                        return;
                    }
                    
                    void(^createXML)(NSString *xmlFilePath) = ^(NSString *xmlFilePath)
                    {
                        NSString *tmpFilePath = [TEMP_PATH stringByAppendingPathComponent:[xmlFilePath lastPathComponent]];
                        FSForm* form = [_pdfViewCtrl.currentDoc getForm];
                        if (nil == form)
                            return;
                        BOOL sucess = [form exportToXML:tmpFilePath];
                        if (sucess)
                        {
                            double delayInSeconds = 0.4;
                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                
                                AlertView *alertView = [[[AlertView alloc] initWithTitle:@"" message:@"kExportFormSucess" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil] autorelease];
                                [alertView show];
                                [filemanager moveItemAtPath:tmpFilePath toPath:xmlFilePath error:nil];
                            });
                        }
                        else
                        {
                            double delayInSeconds = 0.4;
                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                AlertView *alertView = [[[AlertView alloc] initWithTitle:@"" message:@"kExportFormFailed" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil] autorelease];
                                [alertView show];
                            });
                        }
                        
                    };
                    
                    NSString *xmlFilePath = [destinationFolder[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml",fileName]];
                    
                    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
                    if ([fileManager fileExistsAtPath:xmlFilePath])
                    {
                        double delayInSeconds = 0.3;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            AlertView *alert = [[AlertView alloc] initWithTitle:NSLocalizedString(@"kWarning", nil) message:NSLocalizedString(@"kFileAlreadyExists", nil) buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                                if (buttonIndex == 0)
                                {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        inputFileName();
                                        [inputFileName release];
                                    });
                                }
                                else
                                {
                                    [fileManager removeItemAtPath:xmlFilePath error:nil];
                                    createXML(xmlFilePath);
                                    [inputFileName release];
                                }
                            } cancelButtonTitle:NSLocalizedString(@"kCancel", nil) otherButtonTitles:NSLocalizedString(@"kReplace", nil), nil];
                            [alert show];
                            [alert release];
                        });
                        return;
                    }
                    
                    createXML(xmlFilePath);
                    [inputFileName release];
                } cancelButtonTitle:NSLocalizedString(@"kOK", nil) otherButtonTitles:nil];
                inputAlertView.style = TSAlertViewStyleInputText;
                inputAlertView.buttonLayout = TSAlertViewButtonLayoutNormal;
                inputAlertView.usesMessageTextView = NO;
                [inputAlertView show];
                [inputAlertView release];
            };
            
            inputFileName();
        };
        selectDestination.cancelHandler=^
        {
            [selectDestination dismissModalViewControllerAnimated:YES];
        };
        UINavigationController *selectDestinationNavController= [[UINavigationController alloc] initWithRootViewController:selectDestination];
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:selectDestinationNavController
                                                                         animated:YES completion:nil];
        [selectDestination release];
        [selectDestinationNavController release];
    }
    else if (item.tag == TAG_ITEM_IMPORTFORM)
    {
        unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
        bool canFillForm = allPermission & e_permFillForm;
        if (!canFillForm) {
            AlertView *alertView = [[[AlertView alloc] initWithTitle:@"kWarning" message:@"kRMSNoAccess" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil, nil] autorelease];
            [alertView show];
            return;
        }
        
        FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
        selectDestination.isRootFileDirectory = YES;
        selectDestination.fileOperatingMode = FileListMode_Import;
        selectDestination.expectFileType = [NSArray arrayWithObject:@"xml"];
        [selectDestination loadFilesWithPath:DOCUMENT_PATH];
        
        
        selectDestination.operatingHandler=^(FileSelectDestinationViewController *controller, NSArray *destinationFolder)
        {
            [controller dismissModalViewControllerAnimated:YES];
            if (destinationFolder.count > 0)
            {
                FSForm* form = [_pdfViewCtrl.currentDoc getForm];
                if (nil == form)
                    return;
                BOOL isSuccess = [form importFromXML:destinationFolder[0]];
                if (isSuccess)
                {
                    double delayInSeconds = 0.3;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        AlertView *alertView = [[[AlertView alloc] initWithTitle:@"" message:@"kImportFormSucess" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil] autorelease];
                        [alertView show];
                    });
                }
                else
                {
                    double delayInSeconds = 0.3;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        AlertView *alertView = [[[AlertView alloc] initWithTitle:@"" message:@"kImportFormFailed" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil] autorelease];
                        [alertView show];
                    });
                }
            }
        };
        selectDestination.cancelHandler=^()
        {
            [selectDestination dismissModalViewControllerAnimated:YES];
        };
        UINavigationController *selectDestinationNavController= [[UINavigationController alloc] initWithRootViewController:selectDestination];
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:selectDestinationNavController
                                                                         animated:YES completion:nil];
        [selectDestination release];
        [selectDestinationNavController release];
        
    }
    else if (item.tag == TAG_ITEM_RESETFORM)
    {
        unsigned long allPermission = [_pdfViewCtrl.currentDoc getUserPermissions];
        bool canFillForm = allPermission & e_permFillForm;
        if (!canFillForm) {
            AlertView *alertView = [[[AlertView alloc] initWithTitle:@"kWarning" message:@"kRMSNoAccess" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil, nil] autorelease];
            [alertView show];
            self.currentCtr = alertView;
            return;
        }
        
        AlertView *alertView = [[[AlertView alloc] initWithTitle:@"kConfirm" message:@"kSureToResetFormFields" buttonClickHandler:^(UIView *alertView, int buttonIndex) {
            if (buttonIndex == 1) {
                FSForm* form = [_pdfViewCtrl.currentDoc getForm];
                if (nil == form)
                    return;
                [form reset];
            }
        } cancelButtonTitle:@"kNo" otherButtonTitles:@"kYes", nil] autorelease];
        self.currentCtr = alertView;
        [alertView show];
    }
}

@end
