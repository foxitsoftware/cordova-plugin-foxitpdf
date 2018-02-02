/**
 * Copyright (C) 2003-2018, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "MoreModule.h"
#import "FileInformationViewController.h"
#import "MenuGroup.h"
#import "MenuView.h"
#import "PrintRenderer.h"
#import "ScreenCaptureViewController.h"

@interface MoreModule ()

@property (nonatomic, strong) FSPDFDoc *document;

@property (nonatomic, weak) UIButton *moreButton;
@property (nonatomic, strong) MenuView *moreMenu;

@property (nonatomic, strong) MenuGroup *othersGroup;
@property (nonatomic, strong) MvMenuItem *saveItem;
@property (nonatomic, strong) MvMenuItem *fileInfoItem;
@property (nonatomic, strong) MvMenuItem *reduceFileSizeItem;
@property (nonatomic, strong) MvMenuItem *WirelessPrintItem;
@property (nonatomic, strong) MvMenuItem *cropScreenItem;

@property (nonatomic, strong) UIPopoverController *sharePopoverController;

@property (nonatomic, weak) FSPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, weak) UIExtensionsManager *extensionsManager;
@end

@implementation MoreModule

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        self.extensionsManager = extensionsManager;
        self.pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [self loadModule];
    }
    return self;
}

- (void)loadModule {
    [_extensionsManager registerRotateChangedListener:self];
    self.moreMenu = _extensionsManager.more;

    UIButton *moreButton = [Utility createButtonWithImage:[UIImage imageNamed:@"common_read_more"]];
    moreButton.tag = FS_TOPBAR_ITEM_MORE_TAG;
    [moreButton addTarget:self action:@selector(onClickMoreButton:) forControlEvents:UIControlEventTouchUpInside];
    _extensionsManager.topToolbar.items = ({
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:moreButton];
        item.tag = FS_TOPBAR_ITEM_MORE_TAG;
        NSMutableArray *items = (_extensionsManager.topToolbar.items ?: @[]).mutableCopy;
        [items addObject:item];

        //        UIBarButtonItem *reduceRightPadding = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        //        const CGFloat expectedPadding = 12.f;
        //        reduceRightPadding.width = expectedPadding - [Utility getUIToolbarPaddingX];
        //        [items addObject:reduceRightPadding];
        items;
    });
    self.moreButton = moreButton;

    self.othersGroup = [self.moreMenu getGroup:TAG_GROUP_FILE];
    if (!self.othersGroup) {
        self.othersGroup = [[MenuGroup alloc] init];
        self.othersGroup.title = FSLocalizedString(@"kOtherDocumentsFile");
        self.othersGroup.tag = TAG_GROUP_FILE;
        [self.moreMenu addGroup:self.othersGroup];
    }

    self.fileInfoItem = [[MvMenuItem alloc] init];
    self.fileInfoItem.tag = TAG_ITEM_FILEINFO;
    self.fileInfoItem.callBack = self;
    self.fileInfoItem.text = FSLocalizedString(@"kFileInformation");

    self.reduceFileSizeItem = [[MvMenuItem alloc] init];
    self.reduceFileSizeItem.tag = TAG_ITEM_REDUCEFILESIZE;
    self.reduceFileSizeItem.callBack = self;
    self.reduceFileSizeItem.text = FSLocalizedString(@"kReduceFileSize");

    self.WirelessPrintItem = [[MvMenuItem alloc] init];
    self.WirelessPrintItem.tag = TAG_ITEM_WIRELESSPRINT;
    self.WirelessPrintItem.callBack = self;
    self.WirelessPrintItem.text = FSLocalizedString(@"kAirPrint");
    
    self.cropScreenItem = [[MvMenuItem alloc] init];
    self.cropScreenItem.tag = TAG_ITEM_CROP;
    self.cropScreenItem.callBack = self;
    self.cropScreenItem.text = FSLocalizedString(@"kScreenCapture");
    

    [self.moreMenu addMenuItem:self.othersGroup.tag withItem:self.fileInfoItem];
    [self.moreMenu addMenuItem:self.othersGroup.tag withItem:self.reduceFileSizeItem];
    [self.moreMenu addMenuItem:self.othersGroup.tag withItem:self.WirelessPrintItem];
    [self.moreMenu addMenuItem:self.othersGroup.tag withItem:self.cropScreenItem];
}

- (void)onClickMoreButton:(UIButton *)button {
    _extensionsManager.currentAnnot = nil;
    _extensionsManager.hiddenMoreMenu = NO;
}

- (void)onClick:(MvMenuItem *)item {
    if (item.tag == TAG_ITEM_FILEINFO) {
        _extensionsManager.hiddenMoreMenu = YES;
        [self fileInfo];
    } else if (item.tag == TAG_ITEM_REDUCEFILESIZE) {
        [self reduceFileSize];
    } else if (item.tag == TAG_ITEM_WIRELESSPRINT) {
        [self wirelessPrint];
    } else if(item.tag == TAG_ITEM_CROP) {
        _extensionsManager.hiddenMoreMenu = YES;
        [self cropScreen];
    }
}

- (void)fileInfo {
    FileInformationViewController *fileInfoCtr = [[FileInformationViewController alloc] initWithNibName:nil bundle:nil];
    [fileInfoCtr setUIExtensionsManager:_extensionsManager];
    UINavigationController *fileInfoNavCtr = [[UINavigationController alloc] initWithRootViewController:fileInfoCtr];
    fileInfoNavCtr.delegate = fileInfoCtr;
    fileInfoNavCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    fileInfoNavCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_extensionsManager.pdfViewCtrl.window.rootViewController presentViewController:fileInfoNavCtr animated:YES completion:nil];
}

- (void)reduceFileSize {
    //todo:cyy
    AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm"
                                                    message:@"kReduceFileSizeDescription"
                                         buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                             if (0 == buttonIndex) {
                                                 return;
                                             }
                                             self.extensionsManager.docSaveFlag = e_saveFlagXRefStream;
                                             self.extensionsManager.isDocModified = YES;
                                             _extensionsManager.hiddenMoreMenu = YES;
                                         }
                                          cancelButtonTitle:@"kCancel"
                                          otherButtonTitles:@"kOK", nil];

    [alertView show];
}

- (void)wirelessPrint {
    UIPrintInteractionCompletionHandler completion = ^(UIPrintInteractionController *_Nonnull printInteractionController, BOOL completed, NSError *_Nullable error) {
        if (error) {
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:error.localizedDescription buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
            [alertView show];
        }
        //            NSInteger startPage = pic.printFormatter.startPage;
        //            NSInteger pageCount = pic.printFormatter.pageCount;
    };
    NSString *fileName = self.pdfViewCtrl.filePath.lastPathComponent;
    if (DEVICE_iPHONE) {
        [Utility printDoc:self.pdfViewCtrl.currentDoc animated:YES jobName:fileName delegate:nil completionHandler:completion];
    } else {
        CGRect fromRect = [self.pdfViewCtrl convertRect:self.moreButton.bounds fromView:self.moreButton];
        [Utility printDoc:self.pdfViewCtrl.currentDoc fromRect:fromRect inView:self.pdfViewCtrl animated:YES jobName:fileName delegate:nil completionHandler:completion];
    }
}

- (void)cropScreen {
    if (!OS_ISVERSION6) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kScreenCaptureVersion" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
        [alertView show];
        return;
    }
    if (![Utility canCopyForAssessInDocument:self.pdfViewCtrl.currentDoc]) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kRMSNoAccess" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
        [alertView show];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    void(^start)(void) = ^(void)
    {
        weakSelf.extensionsManager.isFullScreen = YES;

        UIImage * img = [Utility screenShot:[_extensionsManager.pdfViewCtrl getDisplayView]];
        ScreenCaptureViewController *screenCaptureViewController = [[ScreenCaptureViewController alloc] initWithNibName:@"ScreenCaptureViewController" bundle:nil];
        
        screenCaptureViewController.img = img;
        screenCaptureViewController.screenCaptureCompelementHandler = ^(CGRect area) {
        };
        screenCaptureViewController.screenCaptureClosedHandler = ^() {
            weakSelf.extensionsManager.isFullScreen = NO;
        };
        
        UINavigationController *shotNavCtr = [[UINavigationController alloc] initWithRootViewController:screenCaptureViewController];
        shotNavCtr.modalPresentationStyle = UIModalPresentationFormSheet;
        shotNavCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [_extensionsManager.pdfViewCtrl.window.rootViewController presentViewController:shotNavCtr animated:YES completion:nil];
    };
    
    if (OS_ISVERSION7) {
        start();
    } else {
        //fix ios6 will make toolbar item disappear bug
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            start();
        });
    }
}

@end
