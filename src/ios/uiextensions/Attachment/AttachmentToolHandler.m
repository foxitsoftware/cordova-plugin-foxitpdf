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

#import "AttachmentToolHandler.h"
#import "AlertView.h"
#import "AttachmentAnnotHandler.h"
#import "FileSelectDestinationViewController.h"
#import "UIExtensionsManager+Private.h"

@interface AttachmentToolHandler ()

@end

@implementation AttachmentToolHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        _type = e_annotFileAttachment;
    }
    return self;
}

- (NSString *)getName {
    return Tool_Attachment;
}

- (BOOL)isEnabled {
    return YES;
}

- (void)onActivate {
}

- (void)onDeactivate {
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

#define ATTACHMENT_WIDTH 20
#define ATTACHMENT_HEIGHT 24

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    float scale = [_pdfViewCtrl getPageViewWidth:pageIndex] / 1000.0;
    CGRect rect = CGRectMake(point.x - ATTACHMENT_WIDTH * scale / 2, point.y - ATTACHMENT_HEIGHT * scale / 2, ATTACHMENT_WIDTH * scale, ATTACHMENT_HEIGHT * scale);

    FSRectF *dibRect = [_pdfViewCtrl convertPageViewRectToPdfRect:rect pageIndex:pageIndex];

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
                AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:[NSString stringWithFormat:FSLocalizedString(@"kAttachmentMaxSize"), 50] buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
                [alertView show];
                return;
            }

            FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
            if (!page)
                return;

            FSFileAttachment *annot = (FSFileAttachment *) [page addAnnot:self.type rect:dibRect];
            annot.NM = [Utility getUUID];
            annot.author = [SettingPreference getAnnotationAuthor];
            annot.icon = _extensionsManager.attachmentIcon;
            annot.color = [_extensionsManager getAnnotColor:self.type];
            annot.opacity = [_extensionsManager getAnnotOpacity:self.type] / 100.0f;
            FSFileSpec *attachFile = [[FSFileSpec alloc] initWithPDFDoc:_pdfViewCtrl.currentDoc];
            if (attachFile && [attachFile embed:destinationFolder[0]]) {
                NSString *fileName = [destinationFolder[0] lastPathComponent];
                [attachFile setFileName:fileName];
                [attachFile setCreationDateTime:[Utility convert2FSDateTime:[fileAttribute fileCreationDate]]];
                [attachFile setModifiedDateTime:[Utility convert2FSDateTime:[fileAttribute fileModificationDate]]];
                [annot setFileSpec:attachFile];
            }
            FSDateTime *now = [Utility convert2FSDateTime:[NSDate date]];
            [annot setCreationDateTime:now];
            [annot setModifiedDateTime:now];

            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
            [annotHandler addAnnot:annot];
        }
    };
    selectDestination.cancelHandler = ^(FileSelectDestinationViewController *controller) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    };
    UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
    selectDestinationNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    selectDestinationNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:selectDestinationNavController animated:YES completion:nil];
    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (self != _extensionsManager.currentToolHandler) {
        return NO;
    }
    return YES;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
}

@end
