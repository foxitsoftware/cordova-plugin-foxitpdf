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

#import "ReadingBookmarkPanel.h"
#import "AlertView.h"
#import "ColorUtility.h"
#import "IPanelSpec.h"
#import "PanelController+private.h"
#import "PanelHost.h"
#import "ReadingBookmarkModule.h"
#import "ReadingBookmarkViewController.h"
#import "TbBaseBar.h"
#import "UIButton+EnlargeEdge.h"
#import "UIExtensionsManager+Private.h"
#import "UniversalEditViewController.h"

@interface ReadingBookmarkPanel () {
    FSPDFViewCtrl *_pdfViewCtrl;
    UIExtensionsManager *_extensionsManager;
    FSPanelController *_panelController;
}

@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) PanelButton *button;
@property (nonatomic, strong) ReadingBookmarkViewController *bookmarkCtrl;
@end

@implementation ReadingBookmarkPanel

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager panelController:(FSPanelController *)panelController {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _panelController = panelController;
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 180, 25)];
        title.backgroundColor = [UIColor clearColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        title.text = FSLocalizedString(@"kBookmark");
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

        self.bookmarkCtrl = [[ReadingBookmarkViewController alloc] initWithStyle:UITableViewStylePlain pdfViewCtrl:_pdfViewCtrl panelController:_panelController];
        _bookmarkCtrl.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _bookmarkCtrl.view.backgroundColor = [UIColor clearColor];
        _bookmarkCtrl.bookmarkGotoPageHandler = ^(int page) {

        };
        _bookmarkCtrl.bookmarkSelectionHandler = ^() {

        };

        _bookmarkCtrl.bookmarkDeleteHandler = ^() {
            [[NSNotificationCenter defaultCenter] postNotificationName:UPDATEBOOKMARK object:nil];
        };
        self.editButton = [[UIButton alloc] initWithFrame:CGRectMake(self.toolbar.frame.size.width - 65, 20, 55, 35)];
        [_editButton addTarget:self action:@selector(clearBookmark:) forControlEvents:UIControlEventTouchUpInside];
        [_editButton setTitleColor:[UIColor colorWithRed:0 / 255.f green:150.f / 255.f blue:212.f / 255.f alpha:1] forState:UIControlStateNormal];
        [_editButton setTitle:FSLocalizedString(@"kClear") forState:UIControlStateNormal];
        _editButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [_editButton setEnlargedEdge:ENLARGE_EDGE];

        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelBookmark)];
        backgroundView.userInteractionEnabled = YES;
        [backgroundView addGestureRecognizer:tapG];
        [self.toolbar addSubview:backgroundView];

        UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 32, 12, 12)];
        [cancelButton addTarget:self action:@selector(cancelBookmark) forControlEvents:UIControlEventTouchUpInside];
        cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"panel_cancel.png"] forState:UIControlStateNormal];

        _bookmarkCtrl.view.frame = self.contentView.bounds;
        [self.contentView addSubview:_bookmarkCtrl.view];
        title.center = CGPointMake(self.toolbar.bounds.size.width / 2, title.center.y);

        UIView *divideView = [[UIView alloc] initWithFrame:CGRectMake(0, 106, _pdfViewCtrl.bounds.size.width, [Utility realPX:1.0f])];
        divideView.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
        divideView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [self.toolbar addSubview:divideView];

        [self.toolbar addSubview:title];
        [self.toolbar addSubview:_editButton];
        if (DEVICE_iPHONE) {
            [backgroundView addSubview:cancelButton];
        }
    }
    return self;
}

- (void)cancelBookmark {
    _panelController.isHidden = YES;
}

- (void)clearBookmark:(id)sender {
    if ([_bookmarkCtrl getBookmarkCount] > 0) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm"
                                                        message:@"kClearBookmark"
                                             buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {
                                                 if (buttonIndex == 1) {        // no
                                                 } else if (buttonIndex == 0) { // yes
                                                     [_bookmarkCtrl clearData:YES];
                                                     [[NSNotificationCenter defaultCenter] postNotificationName:UPDATEBOOKMARK object:nil];
                                                 }
                                             }
                                              cancelButtonTitle:@"kYes"
                                              otherButtonTitles:@"kNo", nil];
        [alertView show];
    }
}

- (void)load {
    [_pdfViewCtrl registerDocEventListener:self];
    [_pdfViewCtrl registerPageEventListener:self];
    [_panelController.panel addSpec:self];
    _panelController.panel.currentSpace = self;
}

- (void)unload {
}

- (void)editBookMark {
    _bookmarkCtrl.isContentEditing = !_bookmarkCtrl.isContentEditing;
}

- (void)reloadData {
    [_bookmarkCtrl loadData];
}

#pragma mark--- IDocEventListener

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
//    [_bookmarkCtrl clearData:NO];
    [_bookmarkCtrl loadData];
    if (![Utility canAssembleDocument:document]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.editButton.enabled = NO;
            self.editButton.hidden = YES;
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.editButton.enabled = YES;
            self.editButton.hidden = NO;
            [_editButton setTitleColor:[UIColor colorWithRed:0 / 255.f green:150.f / 255.f blue:212.f / 255.f alpha:1] forState:UIControlStateNormal];
        });
    }
}

- (void)onDocWillClose:(FSPDFDoc *)document {
    [_bookmarkCtrl clearData:NO];
    if (self.bookmarkCtrl.currentVC) {
        if ([self.bookmarkCtrl.currentVC isKindOfClass:[UINavigationController class]]) {
            [(UINavigationController *) self.bookmarkCtrl.currentVC dismissViewControllerAnimated:NO completion:nil];
        }

        else if ([self.bookmarkCtrl.currentVC isKindOfClass:[UniversalEditViewController class]]) {
            [(UniversalEditViewController *) self.bookmarkCtrl.currentVC dismissViewControllerAnimated:NO completion:nil];
        }

        else if ([self.bookmarkCtrl.currentVC isKindOfClass:[AlertView class]]) {
            [(AlertView *) self.bookmarkCtrl.currentVC dismissWithClickedButtonIndex:0 animated:NO];
        } else if ([self.bookmarkCtrl.currentVC isKindOfClass:[TSAlertView class]]) {
            [(TSAlertView *) self.bookmarkCtrl.currentVC dismissWithClickedButtonIndex:0 animated:NO];
        }
    }
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.editButton.enabled = YES;
        [_editButton setTitleColor:[UIColor colorWithRed:0 / 255.f green:150.f / 255.f blue:212.f / 255.f alpha:1] forState:UIControlStateNormal];
    });
}

- (void)onDocWillSave:(FSPDFDoc *)document {
}

#pragma mark IPageEventListener
- (void)onPagesWillRemove:(NSArray<NSNumber *> *)indexes {
}

- (void)onPagesWillMove:(NSArray<NSNumber *> *)indexes dstIndex:(int)dstIndex {
}

- (void)onPagesWillRotate:(NSArray<NSNumber *> *)indexes rotation:(int)rotation {
}

- (void)onPagesRemoved:(NSArray<NSNumber *> *)indexes {
    FSPDFDoc *doc = _pdfViewCtrl.currentDoc;
    int count = [doc getReadingBookmarkCount];
    for (int i = count - 1; i > -1; i--) {
        FSReadingBookmark *rb = [doc getReadingBookmark:i];
        int index = [rb getPageIndex];
        if (-1 == index) {
            [doc removeReadingBookmark:rb];
        }
    }

    [_bookmarkCtrl clearData:NO];
    [_bookmarkCtrl loadData];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.editButton.enabled = YES;
        [_editButton setTitleColor:[UIColor colorWithRed:0 / 255.f green:150.f / 255.f blue:212.f / 255.f alpha:1] forState:UIControlStateNormal];
    });
}

- (void)onPagesMoved:(NSArray<NSNumber *> *)indexes dstIndex:(int)dstIndex {
    [_bookmarkCtrl clearData:NO];
    [_bookmarkCtrl loadData];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.editButton.enabled = YES;
        [_editButton setTitleColor:[UIColor colorWithRed:0 / 255.f green:150.f / 255.f blue:212.f / 255.f alpha:1] forState:UIControlStateNormal];
    });
}

- (void)onPagesRotated:(NSArray<NSNumber *> *)indexes rotation:(int)rotation {
}

- (int)getTag {
    return FSPanelTagReadingBookmark;
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
    [self.bookmarkCtrl hideCellEditView];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
}

@end
