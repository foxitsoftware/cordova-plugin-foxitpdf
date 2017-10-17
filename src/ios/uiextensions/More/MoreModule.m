/**
 * Copyright (C) 2003-2017, Foxit Software Inc..
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

@interface MoreModule ()

@property (nonatomic, strong) FSPDFDoc *document;

@property (nonatomic, weak) UIButton *moreButton;
@property (nonatomic, assign) CGRect moreRect;
@property (nonatomic, strong) MenuView *moreMenu;

@property (nonatomic, strong) MenuGroup *othersGroup;
@property (nonatomic, strong) MvMenuItem *saveItem;
@property (nonatomic, strong) MvMenuItem *fileInfoItem;
@property (nonatomic, strong) MvMenuItem *reduceFileSizeItem;

@property (nonatomic, strong) NSObject *currentVC;
@property (nonatomic, strong) UIPopoverController *sharePopoverController;
@property (nonatomic, assign) BOOL haddismiss;

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
    self.moreRect = self.moreButton.frame;

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
    
    [self.moreMenu addMenuItem:self.othersGroup.tag withItem:self.fileInfoItem];
    [self.moreMenu addMenuItem:self.othersGroup.tag withItem:self.reduceFileSizeItem];
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
    }
}

- (void)onDocWillOpen {
}

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    self.moreRect = self.moreButton.frame;
    self.haddismiss = NO;
}

- (void)onDocWillClose:(FSPDFDoc *)document {
    if (self.currentVC) {
        if ([self.currentVC isKindOfClass:[UIViewController class]]) {
            [(UIViewController *) self.currentVC dismissViewControllerAnimated:NO completion:nil];
        } else if ([self.currentVC isKindOfClass:[UIDocumentInteractionController class]]) {
            [(UIDocumentInteractionController *) self.currentVC dismissMenuAnimated:NO];
            [(UIDocumentInteractionController *) self.currentVC dismissPreviewAnimated:NO];
        } else if ([self.currentVC isKindOfClass:[UIPrintInteractionController class]]) {
            [(UIPrintInteractionController *) self.currentVC dismissAnimated:NO];
        } else if ([self.currentVC isKindOfClass:[AlertView class]]) {
            [(AlertView *) self.currentVC dismissWithClickedButtonIndex:0 animated:NO];
        }
        self.currentVC = nil;
    }
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    self.haddismiss = NO;
}

- (void)onDocWillSave:(FSPDFDoc *)document {
}

- (void)fileInfo {
    FileInformationViewController *fileInfoCtr = [[FileInformationViewController alloc] initWithNibName:nil bundle:nil];
    [fileInfoCtr setUIExtensionsManager:_extensionsManager];
    self.currentVC = fileInfoCtr;
    UINavigationController *fileInfoNavCtr = [[UINavigationController alloc] initWithRootViewController:fileInfoCtr];
    fileInfoNavCtr.delegate = fileInfoCtr;
    fileInfoNavCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    fileInfoNavCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_extensionsManager.pdfViewCtrl.window.rootViewController presentViewController:fileInfoNavCtr animated:YES completion:nil];
}

- (void)reduceFileSize {
    //todo:cyy
    AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm" message:@"kReduceFileSizeDescription" buttonClickHandler:^(UIView *alertView, int buttonIndex) {
        if (0 == buttonIndex) {
            return ;
        }
        self.extensionsManager.docSaveFlag = e_saveFlagXRefStream;
        _extensionsManager.hiddenMoreMenu = YES;
    } cancelButtonTitle:@"kCancel" otherButtonTitles:@"kOK", nil];
    
    [alertView show];
}

#pragma mark rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.currentVC) {
        if ([self.currentVC isKindOfClass:[UIDocumentInteractionController class]]) {
            [(UIDocumentInteractionController *) self.currentVC dismissMenuAnimated:NO];
            [(UIDocumentInteractionController *) self.currentVC dismissPreviewAnimated:NO];
        } else if ([self.currentVC isKindOfClass:[UIPrintInteractionController class]]) {
            ((UIPrintInteractionController *) self.currentVC).printPageRenderer = nil;
            [(UIPrintInteractionController *) self.currentVC dismissAnimated:NO];
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.moreRect = self.moreButton.frame;
    if (self.currentVC && !self.haddismiss) {
        if ([self.currentVC isKindOfClass:[UIDocumentInteractionController class]]) {
        }
    }
}

#pragma mark UIDocumentInteractionController delegate

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    self.haddismiss = YES;
}

- (void)popoverController:(UIPopoverController *)popoverController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *_Nonnull *)view {
    *rect = self.moreRect;
}

@end
