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

#import "ReadingBookmarkModule.h"
#import "UIExtensionsManager+Private.h"

@interface ReadingBookmarkModule ()
{
    UIExtensionsManager* __weak _extensionsManager;
    FSPDFReader* __weak _pdfReader;
}
@end

@implementation ReadingBookmarkModule

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager pdfReader:(FSPDFReader*)pdfReader
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfReader = pdfReader;
        [self loadModule];
    }
    return self;
}

-(void)loadModule
{
    //Adding reading bookmark button.
    if(_extensionsManager.modulesConfig.loadReadingBookmark)
    {
        _pdfReader.bookmarkItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"readview_bookmark.png"] imageSelected:[UIImage imageNamed:@"readview_bookmarkselect.png"] imageDisable:nil];
        _pdfReader.bookmarkItem.tag = 100;
        _pdfReader.bookmarkItem.onTapClick = ^(TbBaseItem *item){
            if ([_extensionsManager currentAnnot]) {
                [_extensionsManager setCurrentAnnot:nil];
            }
            FSPDFViewCtrl* pdfViewCtrl = _extensionsManager.pdfViewCtrl;
            int currentPage = [pdfViewCtrl getCurrentPage];
            if ([pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO) {
                currentPage = currentPage / 2 * 2;
            }
            FSReadingBookmark* bookmark = [_pdfReader getReadingBookMarkAtPage:currentPage];
            if (!bookmark)
            {
                [pdfViewCtrl.currentDoc insertReadingBookmark:-1 title:[NSString stringWithFormat:@"%@ %d", NSLocalizedStringFromTable(@"kPage", @"FoxitLocalizable", nil), currentPage+1] pageIndex:currentPage];
                _pdfReader.bookmarkItem.selected = YES;
            } else
            {
                [pdfViewCtrl.currentDoc removeReadingBookmark:bookmark];
                _pdfReader.bookmarkItem.selected = NO;
            }
            [_pdfReader.panelController reloadReadingBookmarkPanel];
            
        };
        [_pdfReader.topToolbar addItem:_pdfReader.bookmarkItem displayPosition:Position_RB];
    }
}

-(NSString*)getName
{
    return @"ReadingBookmark";
}

@end

