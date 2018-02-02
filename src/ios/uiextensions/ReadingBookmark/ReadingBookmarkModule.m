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

#import "ReadingBookmarkModule.h"
#import "PanelController+private.h"
#import "UIExtensionsManager+Private.h"

@interface ReadingBookmarkModule () {
    UIExtensionsManager *__weak _extensionsManager;
}
@end

@implementation ReadingBookmarkModule

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        [self loadModule];
    }
    return self;
}

- (void)loadModule {
    //Adding reading bookmark button.
    if (_extensionsManager.modulesConfig.loadReadingBookmark) {
        self.bookmarkButton = [Utility createButtonWithImage:[UIImage imageNamed:@"readview_bookmark.png"]];
        [self.bookmarkButton setImage:[UIImage imageNamed:@"readview_bookmarkselect.png"] forState:UIControlStateSelected];
        [self.bookmarkButton setImage:nil forState:UIControlStateDisabled];
        self.bookmarkButton.tag = FS_TOPBAR_ITEM_BOOKMARK_TAG;
        [self.bookmarkButton addTarget:self action:@selector(onClickBookmarkButton:) forControlEvents:UIControlEventTouchUpInside];

        _extensionsManager.topToolbar.items = ({
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.bookmarkButton];
            item.tag = FS_TOPBAR_ITEM_BOOKMARK_TAG;
            NSMutableArray *items = (_extensionsManager.topToolbar.items ?: @[]).mutableCopy;
            [items addObject:item];
            items;
        });

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBookmarkButtonState) name:UPDATEBOOKMARK object:nil];
        [_extensionsManager.pdfViewCtrl registerDocEventListener:self];
        [_extensionsManager.pdfViewCtrl registerPageEventListener:self];
        [_extensionsManager.pdfViewCtrl registerLayoutEventListener:self];
    }
}

- (NSString *)getName {
    return @"ReadingBookmark";
}

- (void)onClickBookmarkButton:(UIButton *)button {
    if ([_extensionsManager currentAnnot]) {
        [_extensionsManager setCurrentAnnot:nil];
    }
    FSPDFViewCtrl *pdfViewCtrl = _extensionsManager.pdfViewCtrl;
    int currentPage = [pdfViewCtrl getCurrentPage];
    if ([pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO || [pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_MIDDLE) {
        currentPage = currentPage / 2 * 2;
    }
    FSReadingBookmark *bookmark = [Utility getReadingBookMarkAtPage:pdfViewCtrl.currentDoc page:currentPage];
    if (!bookmark) {
        [pdfViewCtrl.currentDoc insertReadingBookmark:-1 title:[NSString stringWithFormat:@"%@ %d", FSLocalizedString(@"kPage"), currentPage + 1] pageIndex:currentPage];
        self.bookmarkButton.selected = YES;
    } else {
        [pdfViewCtrl.currentDoc removeReadingBookmark:bookmark];
        self.bookmarkButton.selected = NO;
    }
    [_extensionsManager.panelController reloadReadingBookmarkPanel];
}

- (void)updateBookmarkButtonState {
    FSPDFViewCtrl* pdfViewCtrl = _extensionsManager.pdfViewCtrl;
    int currentPage = [pdfViewCtrl getCurrentPage];
    if ([pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO || [pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_MIDDLE) {
        currentPage = currentPage / 2 * 2;
    }
    FSReadingBookmark *bookmark = [Utility getReadingBookMarkAtPage:pdfViewCtrl.currentDoc page:currentPage];
    self.bookmarkButton.selected = bookmark ? YES : NO;
}

#pragma mark IDocEventListener
- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    [self updateBookmarkButtonState];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([Utility canAssembleDocument:document]) {
            self.bookmarkButton.userInteractionEnabled = YES;
            self.bookmarkButton.alpha = 1;
        } else {
            self.bookmarkButton.userInteractionEnabled = NO;
            self.bookmarkButton.alpha = 0.5;
        }
    });
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    self.bookmarkButton.userInteractionEnabled = YES;
    self.bookmarkButton.alpha = 1.0f;
}

#pragma mark IPageEventListener
- (void)onPageChanged:(int)oldIndex currentIndex:(int)currentIndex {
    [self updateBookmarkButtonState];
}

#pragma mark ILayeroutEventListener
- (void)onLayoutModeChanged:(PDF_LAYOUT_MODE)oldLayoutMode newLayoutMode:(PDF_LAYOUT_MODE)newLayoutMode {
    [self updateBookmarkButtonState];
}


@end
