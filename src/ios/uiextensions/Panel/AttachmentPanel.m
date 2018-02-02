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

#import "AttachmentPanel.h"
#import "AlertView.h"
#import "ColorUtility.h"
#import "FileSelectDestinationViewController.h"
#import "Masonry.h"
#import "PanelController+private.h"
#import "PanelHost.h"
#import "TbBaseBar.h"
#import "UIButton+EnlargeEdge.h"
#import "UIExtensionsManager+Private.h"
#import "Utility.h"

@interface AttachmentPanel ()
@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) PanelButton *button;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIView *backgroundView;
@end

@implementation AttachmentPanel {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager panelController:(FSPanelController *)panelController {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _panelController = panelController;

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 100, 25)];
        title.backgroundColor = [UIColor clearColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        title.text = FSLocalizedString(@"kAttachments");
        title.textColor = [UIColor blackColor];

        self.toolbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _pdfViewCtrl.bounds.size.width, 64)];
        self.toolbar.backgroundColor = [UIColor whiteColor];
        self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 107, DEVICE_iPHONE ? CGRectGetWidth(_pdfViewCtrl.bounds) : 300, _pdfViewCtrl.bounds.size.height - 107)];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentView.backgroundColor = [UIColor clearColor];
        self.button = [PanelButton buttonWithType:UIButtonTypeCustom];
        self.button.spec = self;
        self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;

        self.addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.toolbar.frame.size.width - 85, 20, 75, 35)];
        [self.addButton addTarget:self action:@selector(addAttachment) forControlEvents:UIControlEventTouchUpInside];
        [self.addButton setTitleColor:[UIColor colorWithRed:0 / 255.f green:150.f / 255.f blue:212.f / 255.f alpha:1] forState:UIControlStateNormal];
        [self.addButton setTitle:FSLocalizedString(@"kAdd") forState:UIControlStateNormal];
        self.addButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.addButton setEnlargedEdge:ENLARGE_EDGE];

        self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelAttachment)];
        _backgroundView.userInteractionEnabled = YES;
        [_backgroundView addGestureRecognizer:tapG];
        [self.toolbar addSubview:_backgroundView];

        self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 32, 12, 12)];
        [_cancelButton addTarget:self action:@selector(cancelAttachment) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [_cancelButton setBackgroundImage:[UIImage imageNamed:@"panel_cancel.png"] forState:UIControlStateNormal];

        self.attachmentCtr = [[AttachmentViewController alloc] initWithStyle:UITableViewStyleGrouped extensionsManager:_extensionsManager module:self];

        [self.contentView addSubview:self.attachmentCtr.view];
        [self.attachmentCtr.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView.mas_left).offset(0);
            make.right.equalTo(self.contentView.mas_right).offset(0);
            make.top.equalTo(self.contentView.mas_top).offset(0);
            make.bottom.equalTo(self.contentView.mas_bottom).offset(0);
        }];
        title.center = CGPointMake(self.toolbar.bounds.size.width / 2, title.center.y);

        UIView *divideView = [[UIView alloc] initWithFrame:CGRectMake(0, 106, _pdfViewCtrl.bounds.size.width, [Utility realPX:1.0f])];
        divideView.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
        divideView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [self.toolbar addSubview:divideView];

        [self.toolbar addSubview:title];
        [self.toolbar addSubview:_addButton];
        if (DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact) {
            [_backgroundView addSubview:_cancelButton];
        }
    }
    return self;
}

- (void)load {
    [_pdfViewCtrl registerDocEventListener:self];
    [_panelController.panel addSpec:self];
    _panelController.panel.currentSpace = self;
}

- (int)getTag {
    return FSPanelTagAttachment;
}

- (PanelButton *)getButton {
    return self.button;
}

- (UIView *)getTopToolbar {
    return self.toolbar;
}

- (UIView *)getContentView {
    return self.contentView;
}

- (void)onActivated {
}

- (void)onDeactivated {
    [self.attachmentCtr hideCellEditView];
}

- (void)_addDocumentAttachemnt:(NSString *)attachmentFilePath addUndo:(BOOL)addUndo {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:attachmentFilePath isDirectory:&isDir] || isDir) {
        return;
    }
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:attachmentFilePath error:nil];
    if (!attributes) {
        return;
    }
    NSString *fileName = attachmentFilePath.lastPathComponent;
    FSPDFNameTree *nameTree = [[FSPDFNameTree alloc] initWithPDFDoc:_pdfViewCtrl.currentDoc type:e_nameTreeEmbeddedFiles];
    if ([nameTree hasName:fileName]) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning"
                                                        message:[NSString stringWithFormat:FSLocalizedString(@"kFailedAddAttachmentForExistedName"), 50]
                                             buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                             }
                                              cancelButtonTitle:@"kOK"
                                              otherButtonTitles:nil];
        [alertView show];
    } else {
        FSFileSpec *fileSpec = [[FSFileSpec alloc] initWithPDFDoc:_pdfViewCtrl.currentDoc];
        [fileSpec setFileName:fileName];
        [fileSpec embed:attachmentFilePath];
        [fileSpec setCreationDateTime:[Utility convert2FSDateTime:[attributes fileCreationDate]]];
        [fileSpec setModifiedDateTime:[Utility convert2FSDateTime:[attributes fileModificationDate]]];
        if ([nameTree add:fileName pdfObj:[fileSpec getDict]]) {
            AttachmentItem *attachmentItem = [AttachmentItem itemWithDocumentAttachment:fileName file:fileSpec PDFPath:_pdfViewCtrl.filePath];
            [self.attachmentCtr onDocumentAttachmentAdded:attachmentItem];

            // undo/redo support
            if (addUndo) {
                [_extensionsManager addUndoItem:[UndoItem itemWithUndo:^(UndoItem *item) {
                                        if ([nameTree hasName:fileName]) {
                                            [nameTree removeObj:fileName];
                                        }
                                        [self.attachmentCtr onDocumentAttachmentDeleted:attachmentItem];
                                    }
                                                    redo:^(UndoItem *item) {
                                                        [self _addDocumentAttachemnt:attachmentFilePath addUndo:NO];
                                                    }
                                                    pageIndex:-1]];
            }
        } else {
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning"
                                                            message:[NSString stringWithFormat:FSLocalizedString(@"kFailedAddAttachment"), 50]
                                                 buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                 }
                                                  cancelButtonTitle:@"kOK"
                                                  otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (void)addAttachment {
    FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
    selectDestination.isRootFileDirectory = YES;
    selectDestination.fileOperatingMode = FileListMode_Import;
    selectDestination.expectFileType = [[NSArray alloc] initWithObjects:@"*", nil];
    [selectDestination loadFilesWithPath:DOCUMENT_PATH];
    selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder) {
        [controller dismissViewControllerAnimated:YES completion:nil];
        if (destinationFolder.count > 0) {
            NSFileManager *fileManager = [NSFileManager defaultManager];

            NSDictionary *fileAttribute = [fileManager attributesOfItemAtPath:destinationFolder[0] error:nil];
            long long fileSize = [fileAttribute fileSize];
            if (fileSize > 50 * 1024 * 1024) { // 50MB
                AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning"
                                                                message:[NSString stringWithFormat:FSLocalizedString(@"kAttachmentMaxSize"), 50]
                                                     buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                     }
                                                      cancelButtonTitle:@"kOK"
                                                      otherButtonTitles:nil];
                [alertView show];
                return;
            }
            NSString *attachmentFilePath = destinationFolder[0];
            [self _addDocumentAttachemnt:attachmentFilePath addUndo:NO];
        }
    };
    selectDestination.cancelHandler = ^(FileSelectDestinationViewController *controller) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    };
    UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
    selectDestinationNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    selectDestinationNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_pdfViewCtrl.window.rootViewController presentViewController:selectDestinationNavController animated:YES completion:nil];
}

- (void)cancelAttachment {
    _panelController.isHidden = YES;
}

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    if ([Utility canModifyContentsInDocument:document]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.addButton.enabled = YES;
            [self.addButton setTitleColor:[UIColor colorWithRed:0 / 255.f green:150.f / 255.f blue:212.f / 255.f alpha:1] forState:UIControlStateNormal];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.addButton.enabled = NO;
            [self.addButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        });
    }
}

@end
