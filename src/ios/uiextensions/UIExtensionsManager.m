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

#import "UIExtensionsManager.h"
#import "AttachmentAnnotHandler.h"
#import "AttachmentToolHandler.h"
#import "CaretAnnotHandler.h"
#import "DigitalSignatureAnnotHandler.h"
#import "EraseToolHandler.h"
#import "FormAnnotHandler.h"
#import "FtAnnotHandler.h"
#import "FtToolHandler.h"
#import "InsertToolHandler.h"
#import "LineAnnotHandler.h"
#import "LineToolHandler.h"
#import "LinkAnnotHandler.h"
#import "NoteAnnotHandler.h"
#import "NoteToolHandler.h"
#import "PencilAnnotHandler.h"
#import "PencilToolHandler.h"
#import "PolygonAnnotHandler.h"
#import "PolygonToolHandler.h"
#import "ReplaceToolHandler.h"
#import "SelectToolHandler.h"
#import "ShapeAnnotHandler.h"
#import "ShapeToolHandler.h"
#import "SignToolHandler.h"
#import "StampAnnotHandler.h"
#import "StampIconController.h"
#import "StampToolHandler.h"
#import "TextMKAnnotHandler.h"
#import "TextMKToolHandler.h"
#import "UIExtensionsManager+Private.h"
#import "UIExtensionsModulesConfig+private.h"
#import "Utility/Utility.h"
#import <Foundation/Foundation.h>
#import <FoxitRDK/FSPDFViewControl.h>

#import "AnnotationPanel.h"
#import "OutlinePanel.h"

#import "CropViewController.h"
#import "PanAndZoomViewController.h"

#import "AlertView.h"
#import "ColorUtility.h"
#import "DXPopover.h"
#import "FSAnnotExtent.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "NoteDialog.h"
#import "PropertyBar.h"
#import "SettingBar+private.h"
#import "UIButton+EnlargeEdge.h"
#import "Utility/NSSet+containsAnyObjectInArray.h"

#import "FSThumbnailCache.h"
#import "FSThumbnailViewController.h"

#import "AttachmentModule.h"
#import "EraseModule.h"
#import "FSUndo.h"
#import "FormModule.h"
#import "FreetextModule.h"
#import "ImageModule.h"
#import "InsertModule.h"
#import "LineModule.h"
#import "LinkModule.h"
#import "MarkupModule.h"
#import "MoreModule.h"
#import "NoteModule.h"
#import "PageNavigationModule.h"
#import "PasswordModule.h"
#import "PencilModule.h"
#import "PolygonModule.h"
#import "ReadingBookmarkModule.h"
#import "ReflowModule.h"
#import "ReplaceModule.h"
#import "Search/SearchModule.h"
#import "SelectionModule.h"
#import "ShapeModule.h"
#import "SignToolHandler.h"
#import "SignatureModule.h"
#import "StampModule.h"
#import "TextboxModule.h"
#import "UndoModule.h"
#import "DistanceModule.h"

@interface UIExtensionsManager () <UIPopoverControllerDelegate, FSThumbnailViewControllerDelegate, SettingBarDelegate, ILayoutEventListener>

@property (nonatomic, strong) NSMutableDictionary *propertyBarListeners;
@property (nonatomic, strong) NSMutableArray *rotateListeners;

@property (nonatomic, strong) NSMutableDictionary *annotColors;
@property (nonatomic, strong) NSMutableDictionary *annotOpacities;
@property (nonatomic, strong) NSMutableDictionary *annotLineWidths;
@property (nonatomic, strong) NSMutableDictionary *annotFontSizes;
@property (nonatomic, strong) NSMutableDictionary *annotFontNames;

@property (nonatomic, strong) NSMutableArray<IAnnotPropertyListener> *annotPropertyListeners;

@property (nonatomic, strong) NSMutableArray<IGestureEventListener> *guestureEventListeners;

@property (nonatomic, strong) NSMutableArray<ILinkEventListener> *linkEventListeners;

@property (nonatomic, strong) StampIconController *stampIconController;
@property (nonatomic, strong) UIPopoverController *popOverController;

@property (nonatomic, strong) NSMutableArray *securityHandlers;
@property (nonatomic, strong) NSMutableArray *modules;

@property (nonatomic, strong) FSThumbnailViewController *thumbnailViewController;
//@property (nonatomic) PDF_LAYOUT_MODE prevLayoutMode; // for returning from thumbnail
@property (nonatomic, strong) FSThumbnailCache *thumbnailCache;

@property (nonatomic, strong) NSMutableArray *fullScreenListeners;
@property (nonatomic, strong) NSMutableArray *panelListeners;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) TbBaseItem *moreAnnotItem;
@property (nonatomic, strong) UIPopoverController *moreToolbarPopoverCtr;
@property (nonatomic, strong) UIButton *annotButton;
@property (nonatomic, assign) BOOL isPopoverhidden;
@property (nonatomic, assign) int currentState;
@property (nonatomic, strong) DXPopover *popover;

@property (nonatomic, strong) UIToolbar *topToolbarSaved;
@property (nonatomic, strong) UIToolbar *bottomToolbarSaved;

@property (nonatomic, strong) NSArray<UIBarButtonItem*> *topToolBarItemsArr;
@property (nonatomic, strong) NSArray<UIBarButtonItem*> *bottomToolBarItemsArr;

@property (nonatomic, strong) UIControl *settingBarMaskView;

//pan&zoom
@property (nonatomic, strong) UIToolbar *PanZoomBottomBar;
@property (nonatomic, strong) PanZoomView* panZoomView;
@property (nonatomic, strong) UISlider* zoomSlider;
@property (nonatomic, strong) UIBarButtonItem* prevPageButtonItem;
@property (nonatomic, strong) UIBarButtonItem* nextPageButtonItem;

@end

@implementation UIExtensionsManager {
    UIControl *maskView;
}

- (id)initWithPDFViewControl:(FSPDFViewCtrl *)viewctrl {
    return [self initWithPDFViewControl:viewctrl configuration:nil];
}

- (id)initWithPDFViewControl:(FSPDFViewCtrl *)viewctrl configuration:(NSData *_Nullable)jsonConfigData {
    UIExtensionsModulesConfig *config;
    if (jsonConfigData) {
        config = [[UIExtensionsModulesConfig alloc] initWithJSONData:jsonConfigData];
        if (!config) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid JSON" message:@"Extensions manager could not be loaded." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            return nil;
        }
    } else {
        config = [[UIExtensionsModulesConfig alloc] init];
    }
    return [self initWithPDFViewControl:viewctrl configurationObject:config];
}

- (id)initWithPDFViewControl:(FSPDFViewCtrl *)viewctrl configurationObject:(UIExtensionsModulesConfig *_Nonnull)configuration {
    self = [super init];
    _pdfViewCtrl = viewctrl;
    self.modulesConfig = configuration;

    self.fullScreenListeners = [[NSMutableArray alloc] init];
    self.panelListeners = [[NSMutableArray alloc] init];
    self.stateChangeListeners = [NSMutableArray array];
    self.currentState = STATE_NORMAL;

    self.toolHandlers = [NSMutableArray array];
    self.annotHandlers = [NSMutableArray array];
    self.annotListeners = [NSMutableArray array];
    self.toolListeners = [NSMutableArray array];
    self.searchListeners = [NSMutableArray array];
    self.currentToolHandler = nil;
    self.propertyBarListeners = [NSMutableDictionary dictionary];
    self.rotateListeners = [[NSMutableArray alloc] init];
    self.annotColors = [NSMutableDictionary dictionary];
    self.annotOpacities = [NSMutableDictionary dictionary];
    self.annotLineWidths = [NSMutableDictionary dictionary];
    self.annotFontSizes = [NSMutableDictionary dictionary];
    self.annotFontNames = [NSMutableDictionary dictionary];
    self.annotPropertyListeners = [NSMutableArray<IAnnotPropertyListener> array];
    self.enableLinks = YES;
    self.enableHighlightLinks = YES;
    self.noteIcon = 2;
    self.attachmentIcon = 1;
    self.eraserLineWidth = 4;
    self.distanceUnit = @"1 inch = 1 inch";
    self.screenAnnotRotation = e_rotation0;
    self.linksHighlightColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:0.3];
    self.selectionHighlightColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.3];
    self.securityHandlers = [NSMutableArray array];
    self.isShowBlankMenu = NO;
    self.isDocModified = NO;
    self.docSaveFlag = e_saveFlagIncremental;
    self.taskServer = [[TaskServer alloc] init];

    self.undoItems = [NSMutableArray<UndoItem *> array];
    self.redoItems = [NSMutableArray<UndoItem *> array];
    self.undoListeners = [NSMutableArray<IFSUndoEventListener> array];

    [_pdfViewCtrl registerLayoutEventListener:self];
    [self buildToolbars];
    [self buildItems];

    [_pdfViewCtrl registerDrawEventListener:self];
    [_pdfViewCtrl registerGestureEventListener:self];
    [_pdfViewCtrl registerRecoveryEventListener:self];
    [_pdfViewCtrl registerDocEventListener:self];
    [_pdfViewCtrl registerPageEventListener:self];

    self.panelController = [[FSPanelController alloc] initWithExtensionsManager:self];
    self.panelController.isHidden = YES;

    self.propertyBar = [[PropertyBar alloc] initWithPDFViewController:viewctrl extensionsManager:self];

    NSMutableArray *modules = [NSMutableArray array];
    if (self.modulesConfig.loadPageNavigation)
        [modules addObject:[[PageNavigationModule alloc] initWithUIExtensionsManager:self]];
    if (self.modulesConfig.loadReadingBookmark)
        [modules addObject:[[ReadingBookmarkModule alloc] initWithUIExtensionsManager:self]];
    if (self.modulesConfig.loadSearch)
        [modules addObject:[[SearchModule alloc] initWithUIExtensionsManager:self]];
    [modules addObject:[[MoreModule alloc] initWithUIExtensionsManager:self]];
    if (self.modulesConfig.loadForm)
        [modules addObject:[[FormModule alloc] initWithUIExtensionsManager:self]];

    NSSet *tools = self.modulesConfig.tools;
    if ([tools containsAnyObjectNotInArray:@[ Tool_Select ]]) {
        [modules addObject:[[UndoModule alloc] initWithUIExtensionsManager:self]];
    }
    // annotations
    if ([tools containsAnyObjectInArray:@[ Tool_Highlight, Tool_Underline, Tool_Squiggly ]]) {
        [modules addObject:[[MarkupModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsObject:Tool_Note]) {
        [modules addObject:[[NoteModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsAnyObjectInArray:@[ Tool_Oval, Tool_Rectangle ]]) {
        [modules addObject:[[ShapeModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsObject:Tool_Freetext]) {
        [modules addObject:[[FreetextModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsObject:Tool_Textbox]) {
        [modules addObject:[[TextboxModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsObject:Tool_Pencil]) {
        [modules addObject:[[PencilModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsObject:Tool_Eraser]) {
        [modules addObject:[[EraseModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsAnyObjectInArray:@[ Tool_Line, Tool_Arrow ]]) {
        [modules addObject:[[LineModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsAnyObjectInArray:@[ Tool_Distance ]]) {
        [modules addObject:[[DistanceModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsObject:Tool_Stamp]) {
        [modules addObject:[[StampModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsObject:Tool_Insert]) {
        [modules addObject:[[InsertModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsObject:Tool_Replace]) {
        [modules addObject:[[ReplaceModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsObject:Tool_Image]) {
        [modules addObject:[[ImageModule alloc] initWithUIExtensionsManager:self]];
    }
    if ([tools containsAnyObjectInArray:@[ Tool_Polygon, Tool_Cloud ]]) {
        [modules addObject:[[PolygonModule alloc] initWithUIExtensionsManager:self]];
    }
    if (self.modulesConfig.loadAttachment) {
        [modules addObject:[[AttachmentModule alloc] initWithUIExtensionsManager:self]];
    }

    [modules addObject:[[ReflowModule alloc] initWithUIExtensionsManager:self]];
    if (self.modulesConfig.loadSignature)
        [modules addObject:[[SignatureModule alloc] initWithUIExtensionsManager:self]];
    if ([self.modulesConfig.tools containsObject:Tool_Select])
        [modules addObject:[[SelectionModule alloc] initWithUIExtensionsManager:self]];
    [modules addObject:[[LinkModule alloc] initWithUIExtensionsManager:self]];
    self.passwordModule = [[PasswordModule alloc] initWithExtensionsManager:self];
    [modules addObject:self.passwordModule];
    self.modules = modules;
    self.menuControl = [[MenuControl alloc] initWithUIExtensionsManager:self];

    _iconProvider = [[ExAnnotIconProviderCallback alloc] init];
    [FSLibrary setAnnotIconProvider:_iconProvider];
    _actionHandler = [[ExActionHandler alloc] initWithPDFViewControl:viewctrl];
    [FSLibrary setActionHandler:_actionHandler];

    self.thumbnailCache = [[FSThumbnailCache alloc] initWithUIExtenionsManager:self];
    [_pdfViewCtrl registerPageEventListener:self.thumbnailCache];
    [self registerAnnotEventListener:self.thumbnailCache];
    [_pdfViewCtrl registerScrollViewEventListener:self];
    
    return self;
}

#pragma mark - get bottomToolbar item hide/show status
-(NSMutableDictionary *)getBottomToolbarItemHiddenStatus {
    NSMutableDictionary *bottombarbuttonInfo = [@{
                                               @"LIST":@"YES",
                                               @"VIEW":@"YES",
                                               @"COMMENT":@"YES",
                                               @"SIGNATURE":@"YES",
                                               } mutableCopy];
    
    NSMutableDictionary *bottomItemTagDic = [@{
                                               [NSNumber numberWithInt:FS_BOTTOMBAR_ITEM_PANEL_TAG]:@"LIST",
                                               [NSNumber numberWithInt:FS_BOTTOMBAR_ITEM_READMODE_TAG]:@"VIEW",
                                               [NSNumber numberWithInt:FS_BOTTOMBAR_ITEM_ANNOT_TAG]:@"COMMENT",
                                               [NSNumber numberWithInt:FS_BOTTOMBAR_ITEM_SIGNATURE_TAG]:@"SIGNATURE",
                                              } mutableCopy];
    
    for (UIBarButtonItem *tempbarItem in self.bottomToolbar.items) {
        NSArray *tempArr = [bottomItemTagDic allKeys];
        NSNumber *tag = [NSNumber numberWithLong:tempbarItem.tag];
        if ([tempArr containsObject: tag]) {
            [bottombarbuttonInfo setObject:@"NO" forKey:[bottomItemTagDic objectForKey:tag]];
        }
    }
    
    return bottombarbuttonInfo;
}

#pragma mark - get topToolbar item hide/show status
-(NSMutableDictionary *)getTopToolbarItemHiddenStatus {
    NSMutableDictionary *topbarbuttonInfo = [@{
                                               @"BACK":self.backButton.isHidden ? @"YES":@"NO",
                                               } mutableCopy];
    
    NSMutableArray *tempArr = [[NSMutableArray alloc] initWithCapacity:3];
    
    for (UIBarButtonItem *tempbarItem in self.topToolbar.items) {
        [tempArr addObject:[NSNumber numberWithLong:tempbarItem.tag ]];
    }
    
    NSString *bookmarkResult = @"NO";
    NSString *searchResult = @"NO";
    NSString *morekResult = @"NO";
    NSString *backResult = @"NO";
    bookmarkResult = [tempArr containsObject:[NSNumber numberWithInt:FS_TOPBAR_ITEM_BOOKMARK_TAG]] ? @"NO" : @"YES";
    searchResult = [tempArr containsObject:[NSNumber numberWithInt:FS_TOPBAR_ITEM_SEARCH_TAG]] ?  @"NO" : @"YES";
    morekResult = [tempArr containsObject:[NSNumber numberWithInt:FS_TOPBAR_ITEM_MORE_TAG]] ?  @"NO" : @"YES";
    backResult = [tempArr containsObject:[NSNumber numberWithInt:FS_TOPBAR_ITEM_BACK_TAG]] ?  @"NO" : @"YES";
    
    [topbarbuttonInfo setObject:bookmarkResult forKey:@"BOOKMARK"];
    [topbarbuttonInfo setObject:searchResult forKey:@"SEARCH"];
    [topbarbuttonInfo setObject:morekResult forKey:@"MORE"];
    [topbarbuttonInfo setObject:backResult forKey:@"BACK"];
    
    return topbarbuttonInfo;
}

#pragma mark - set toolbar items hide/show
-(void)setToolbarItemHiddenWithTag:(NSUInteger)itemTag hidden:(BOOL)isHidden{
    NSMutableArray *toolBarItems = nil;
    if(itemTag < 200)
        toolBarItems = [self.topToolbar.items mutableCopy];
    else
        toolBarItems = [self.bottomToolbar.items mutableCopy];
    if (isHidden){
        UIBarButtonItem *waitRemoveItem = nil;
        for (UIBarButtonItem *tempbarItem in toolBarItems) {
            if (tempbarItem.tag == itemTag) {
                waitRemoveItem = tempbarItem;
            }
        }
        
        if(waitRemoveItem && [toolBarItems containsObject:waitRemoveItem]){
            [toolBarItems removeObject:waitRemoveItem];
        }
    }else{
        UIBarButtonItem *waitAddItem = nil;
        for (UIBarButtonItem *tempbarItem in _topToolBarItemsArr) {
            if (tempbarItem.tag == itemTag) {
                waitAddItem = tempbarItem;
            }
        }
        
        if(waitAddItem && ![toolBarItems containsObject:waitAddItem]){
            [toolBarItems addObject:waitAddItem];
        }
    }
    
    if(itemTag < 200)
        [self.topToolbar setItems:toolBarItems animated:NO];
    else
        [self.bottomToolbar setItems:toolBarItems animated:NO];
}

#pragma mark <SettingBarDelegate>

- (void)settingBarSinglePageLayout:(SettingBar *)settingBar {
    [self.pdfViewCtrl setPageLayoutMode:PDF_LAYOUT_MODE_SINGLE];
    self.hiddenSettingBar = YES;
}

- (void)settingBarContinuousLayout:(SettingBar *)settingBar {
    [self.pdfViewCtrl setPageLayoutMode:PDF_LAYOUT_MODE_CONTINUOUS];
    self.hiddenSettingBar = YES;
}

- (void)settingBarDoublePageLayout:(SettingBar *)settingBar {
    [self.pdfViewCtrl setPageLayoutMode:PDF_LAYOUT_MODE_TWO];
    self.hiddenSettingBar = YES;
}

- (void)settingBarCoverPageLayout:(SettingBar *)settingBar {
    [self.pdfViewCtrl setPageLayoutMode:PDF_LAYOUT_MODE_TWO_RIGHT];
    self.hiddenSettingBar = YES;
}

- (void)settingBarThumbnail:(SettingBar *)settingBar {
    [self showThumbnailView];
    self.hiddenSettingBar = YES;
}

- (void)settingBarReflow:(SettingBar *)settingBar {
    ReflowModule *reflowModule = nil;
    for (id module in self.modules) {
        if ([module respondsToSelector:@selector(getName)] && [[module getName] isEqualToString:@"Reflow"]) {
            reflowModule = module;
            break;
        }
    }
    assert(reflowModule);
    [reflowModule enterReflowMode:YES];
    self.hiddenSettingBar = YES;
}

- (void)settingBarCrop:(SettingBar *)settingBar {
    [self setCropMode];
    self.hiddenSettingBar = YES;
}

- (void)settingBarPanAndZoom:(SettingBar *)settingBar {
    [self setPanAndZoomMode];
    self.hiddenSettingBar = YES;
}

- (void)settingBar:(SettingBar *)settingBar setLockScreen:(BOOL)isLockScreen {
    self.isScreenLocked = isLockScreen;
    self.hiddenSettingBar = YES;
}

- (void)settingBar:(SettingBar *)settingBar setNightMode:(BOOL)isNightMode {
    self.pdfViewCtrl.isNightMode = isNightMode;
    self.hiddenSettingBar = YES;
}

#pragma mark - IPageEventListener

- (void)onPagesRemoved:(NSArray<NSNumber *> *)indexes {
    self.docSaveFlag = e_saveFlagXRefStream;
    // remove all undo/redo items in removed pages
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UndoItem *undoItem, NSDictionary *bindings) {
        return ![indexes containsObject:[NSNumber numberWithInt:undoItem.pageIndex]];
    }];
    [self.undoItems filterUsingPredicate:predicate];
    [self.redoItems filterUsingPredicate:predicate];

    void (^updatePageIndex)(UndoItem *item) = ^(UndoItem *item) {
        int subcount = 0;
        for (NSNumber *x in indexes) {
            if (item.pageIndex > [x intValue])
                subcount++;
        }
        item.pageIndex -= subcount;
    };

    [self.undoItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        updatePageIndex((UndoItem *) obj);
    }];

    [self.redoItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        updatePageIndex((UndoItem *) obj);
    }];

    for (id<IFSUndoEventListener> listener in self.undoListeners) {
        [listener onUndoChanged];
    }
}

- (void)onPagesMoved:(NSArray<NSNumber *> *)indexes dstIndex:(int)dstIndex {
    //todo wei update undo/redo
}

- (void)onPagesInsertedAtRange:(NSRange)range {
    //Load Form if there it is.
    FormAnnotHandler *handler = (FormAnnotHandler *) [self getAnnotHandlerByType:e_annotWidget];
    if (!handler)
        return;
    [handler onDocOpened:self.pdfViewCtrl.currentDoc error:0];

    //Reset the cropMode.
    [_pdfViewCtrl setCropMode:PDF_CROP_MODE_NONE];
    ((UIButton *) [self.settingBar getItemView:CROPPAGE]).selected = NO;
}

- (void)onPageChanged:(int)oldIndex currentIndex:(int)currentIndex {
    [self dismissAnnotMenu];
    self.isShowBlankMenu = NO;
    if (self.zoomSlider) {
        self.zoomSlider.value = [_pdfViewCtrl getZoom];
        if ([_pdfViewCtrl getPageCount] - 1 == _pdfViewCtrl.getCurrentPage) {
            self.nextPageButtonItem.enabled = NO;
        } else {
            self.nextPageButtonItem.enabled = YES;
        }
        if (0 == _pdfViewCtrl.getCurrentPage) {
            self.prevPageButtonItem.enabled = NO;
        } else {
            self.prevPageButtonItem.enabled = YES;
        }
    }
}

- (void)setPanAndZoomMode {
    self.panZoomView = [[PanZoomView alloc] initWithUIExtensionsManager:self];
    
    [self.pdfViewCtrl addSubview:self.panZoomView];
    
    _topToolBarItemsArr = self.topToolbar.items;
    _bottomToolBarItemsArr = self.bottomToolbar.items;
    
    [self buildPanZoomBottomBar];
}

- (void)buildPanZoomBottomBar {
    
    UIButton* exitButton = [Utility createButtonWithImage:[UIImage imageNamed:@"common_back_blue"]];
    [exitButton addTarget:self action:@selector(onClickExitPanZoomButton) forControlEvents:UIControlEventTouchUpInside];
    exitButton.enabled = YES;
    UIBarButtonItem *exitButtonItem = [[UIBarButtonItem alloc] initWithCustomView:exitButton];
    
    //zoom tool
    UIButton* zoomOutButton = [Utility createButtonWithImage:[UIImage imageNamed:@"zoom_out"]];
    zoomOutButton.enabled = NO;
    UIBarButtonItem *zoomOutButtonItem = [[UIBarButtonItem alloc] initWithCustomView:zoomOutButton];
    zoomOutButtonItem.enabled = NO;
    
    UIButton* zoomInButton = [Utility createButtonWithImage:[UIImage imageNamed:@"zoom_in"]];
    zoomInButton.enabled = NO;
    UIBarButtonItem *zoomInButtonItem = [[UIBarButtonItem alloc] initWithCustomView:zoomInButton];
    zoomInButtonItem.enabled = NO;
    
    //page change tool
    UIButton* prevPageButton = [Utility createButtonWithImage:[UIImage imageNamed:@"zoom_prevPage"]];
    [prevPageButton addTarget:self action:@selector(onClickPrevPageButton) forControlEvents:UIControlEventTouchUpInside];
    self.prevPageButtonItem = [[UIBarButtonItem alloc] initWithCustomView:prevPageButton];
    
    UIButton* nextPageButton = [Utility createButtonWithImage:[UIImage imageNamed:@"zoom_nextPage"]];
    [nextPageButton addTarget:self action:@selector(onClickNextPageButton) forControlEvents:UIControlEventTouchUpInside];
    self.nextPageButtonItem = [[UIBarButtonItem alloc] initWithCustomView:nextPageButton];
    
    int width = zoomInButton.frame.size.width + zoomOutButton.frame.size.width + prevPageButton.frame.size.width + nextPageButton.frame.size.width;
    self.zoomSlider = [[UISlider alloc] initWithFrame:CGRectMake( 0, 0, SCREENWIDTH - width - 100, 20)];
    self.zoomSlider.maximumValue = 10.0;
    self.zoomSlider.minimumValue = 1.0;
    self.zoomSlider.value = [_pdfViewCtrl getZoom];
    self.zoomSlider.continuous = YES;
    [self.zoomSlider addTarget:self action:@selector(onZoomSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem* zoomSliderItem = [[UIBarButtonItem alloc] initWithCustomView:self.zoomSlider];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.topToolbar.items = @[ exitButtonItem, flexibleSpace ];
    self.bottomToolbar.items = @[ flexibleSpace, zoomOutButtonItem, zoomSliderItem, zoomInButtonItem, flexibleSpace, self.prevPageButtonItem, flexibleSpace, self.nextPageButtonItem, flexibleSpace ];
    
    if ([_pdfViewCtrl getPageCount] - 1 == _pdfViewCtrl.getCurrentPage) {
        self.nextPageButtonItem.enabled = NO;
    }
    if (0 == _pdfViewCtrl.getCurrentPage) {
        self.prevPageButtonItem.enabled = NO;
    }
}

- (void)onClickExitPanZoomButton {
    [self.panZoomView removeFromSuperview];
    
    [self unregisterAnnotEventListener:self.panZoomView];
    [self unregisterRotateChangedListener:self.panZoomView];
    [_pdfViewCtrl unregisterPageEventListener:self.panZoomView];
    [_pdfViewCtrl unregisterScrollViewEventListener:self.panZoomView];
    [_pdfViewCtrl unregisterLayoutEventListener:self.panZoomView];
    [_pdfViewCtrl unregisterDocEventListener:self.panZoomView];
    
    self.panZoomView = nil;
    
    self.topToolbar.items = _topToolBarItemsArr;
    self.bottomToolbar.items = _bottomToolBarItemsArr;
}

- (void)onZoomSliderValueChanged:(UISlider*)slider {
    CGFloat scale = slider.value;
    [_pdfViewCtrl setZoom:scale];
}

- (void)onClickPrevPageButton {
    [_pdfViewCtrl gotoPrevPage:NO];
}

- (void)onClickNextPageButton {
    [_pdfViewCtrl gotoNextPage:NO];
}

- (void)setCropMode {
    self.settingBar.panAndZoomBtn.enabled = NO;
    
    CropViewController *cropViewController = [[CropViewController alloc] initWithNibName:@"CropViewController" bundle:nil];
    [cropViewController setExtension:self];
    cropViewController.cropViewClosedHandler = ^() {
    };
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:cropViewController];
    navController.navigationBarHidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_pdfViewCtrl.window.rootViewController presentViewController:navController animated:YES completion:nil];
    });
}

- (void)showAnnotMenu {
    if (self.isShowBlankMenu) {
        double delayInSeconds = .05;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            MenuControl *annotMenu = self.menuControl;
            CGPoint dvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.currentPoint pageIndex:self.currentPageIndex];
            CGRect dvRect = CGRectMake(dvPoint.x, dvPoint.y, 2, 2);

            CGRect rectDisplayView = [[_pdfViewCtrl getDisplayView] bounds];
            if (CGRectIsEmpty(dvRect) || CGRectIsNull(CGRectIntersection(dvRect, rectDisplayView)))
                return;

            dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:dvRect pageIndex:self.currentPageIndex];
            [annotMenu setRect:dvRect];
            [annotMenu showMenu];
        });
    }
}

- (void)dismissAnnotMenu {
    if (self.isShowBlankMenu) {
        MenuControl *annotMenu = self.menuControl;
        if ([annotMenu isMenuVisible]) {
            [annotMenu hideMenu];
        }
        self.isShowBlankMenu = YES;
    }
}

- (void)setCurrentToolHandler:(id<IToolHandler>)toolHandler {
    id<IToolHandler> lastToolHandler = _currentToolHandler;
    if (lastToolHandler != nil) {
        [lastToolHandler onDeactivate];
    }
    if (toolHandler != nil) {
        if ([self currentAnnot] != nil)
            [self setCurrentAnnot:nil];
    }

    _currentToolHandler = toolHandler;

    if (_currentToolHandler != nil) {
        [_currentToolHandler onActivate];
    }

    for (id<IToolEventListener> listener in self.toolListeners) {
        if ([listener respondsToSelector:@selector(onToolChanged:CurrentToolName:)]) {
            [listener onToolChanged:[lastToolHandler getName] CurrentToolName:[_currentToolHandler getName]];
        }
    }
}

- (id<IToolHandler>)getToolHandlerByName:(NSString *)name {
    // tools share one tool handler
    if ([@[ Tool_Highlight, Tool_Squiggly, Tool_StrikeOut, Tool_Underline ] containsObject:name]) {
        name = Tool_Markup;
    } else if ([@[ Tool_Rectangle, Tool_Oval ] containsObject:name]) {
        name = Tool_Shape;
    } else if ([name isEqualToString:Tool_Arrow]) {
        name = Tool_Line;
    }
    for (id<IToolHandler> toolHandler in self.toolHandlers) {
        if ([toolHandler respondsToSelector:@selector(getName)]) {
            if ([[toolHandler getName] isEqualToString:name]) {
                return toolHandler;
            }
        }
    }
    return nil;
}

- (void)registerToolHandler:(id<IToolHandler>)toolHandler {
    if (self.toolHandlers) {
        [self.toolHandlers addObject:toolHandler];
    }
}

- (void)unregisterToolHandler:(id<IToolHandler>)toolHandler {
    if ([self.toolHandlers containsObject:toolHandler]) {
        [self.toolHandlers removeObject:toolHandler];
    }
}
- (void)registerAnnotHandler:(id<IAnnotHandler>)annotHandler {
    if (self.annotHandlers && ![self.annotHandlers containsObject:annotHandler]) {
        [self.annotHandlers addObject:annotHandler];
    }
}
- (void)unregisterAnnotHandler:(id<IAnnotHandler>)annotHandler {
    if ([self.annotHandlers containsObject:annotHandler]) {
        [self.annotHandlers removeObject:annotHandler];
    }
}

- (id<IAnnotHandler>)getAnnotHandlerByType:(FSAnnotType)type {
    if (type == e_annotSquiggly || type == e_annotStrikeOut || type == e_annotUnderline) {
        type = e_annotHighlight;
    }
    if (type == e_annotSquare) {
        type = e_annotCircle;
    }
    for (id<IAnnotHandler> annotHandler in self.annotHandlers) {
        if ([annotHandler respondsToSelector:@selector(getType)]) {
            if ([annotHandler getType] == type) {
                return annotHandler;
            }
        }
    }
    return nil;
}

- (id<IAnnotHandler>)getAnnotHandlerByAnnot:(FSAnnot *)annot {
    FSAnnotType type = [annot getType];
    if (type == e_annotSquiggly || type == e_annotStrikeOut || type == e_annotUnderline) {
        type = e_annotHighlight;
    }
    if (type == e_annotSquare) {
        type = e_annotCircle;
    }
    for (id<IAnnotHandler> annotHandler in self.annotHandlers) {
        if ([annotHandler respondsToSelector:@selector(getType)]) {
            if ([annotHandler getType] == type) {
                if (e_annotWidget == type) {
                    FSWidget *widget = (FSWidget *) annot;
                    FSFormFieldType fieldType = [[widget getField] getType];
                    if (e_formFieldSignature == fieldType && [annotHandler isKindOfClass:[DigitalSignatureAnnotHandler class]]) {
                        return annotHandler;
                    }
                    if (e_formFieldSignature != fieldType && [annotHandler isKindOfClass:[FormAnnotHandler class]]) {
                        return annotHandler;
                    }
                } else
                    return annotHandler;
            }
        }
    }
    return nil;
}

- (void)registerAnnotEventListener:(id<IAnnotEventListener>)listener {
    if (self.annotListeners) {
        [self.annotListeners addObject:listener];
    }
}
- (void)unregisterAnnotEventListener:(id<IAnnotEventListener>)listener {
    if ([self.annotListeners containsObject:listener]) {
        [self.annotListeners removeObject:listener];
    }
}

- (void)registerToolEventListener:(id<IToolEventListener>)listener {
    if (self.toolListeners) {
        [self.toolListeners addObject:listener];
    }
}
- (void)unregisterToolEventListener:(id<IToolEventListener>)listener {
    if ([self.toolListeners containsObject:listener]) {
        [self.toolListeners removeObject:listener];
    }
}

- (void)registerUndoEventListener:(id<IFSUndoEventListener>)listener {
    if (self.undoListeners) {
        [self.undoListeners addObject:listener];
    }
}

- (void)unregisterUndoEventListener:(id<IFSUndoEventListener>)listener {
    if ([self.undoListeners containsObject:listener]) {
        [self.undoListeners removeObject:listener];
    }
}

- (void)registerSearchEventListener:(id<ISearchEventListener>)listener {
    if (self.searchListeners) {
        [self.searchListeners addObject:listener];
    }
}

- (void)unregisterSearchEventListener:(id<ISearchEventListener>)listener {
    if ([self.searchListeners containsObject:listener]) {
        [self.searchListeners removeObject:listener];
    }
}

#pragma mark - IGestureEventListener

- (void)registerGestureEventListener:(id<IGestureEventListener>)listener {
    if (!self.guestureEventListeners) {
        self.guestureEventListeners = [NSMutableArray<IGestureEventListener> array];
    }
    if (![self.guestureEventListeners containsObject:listener]) {
        [self.guestureEventListeners addObject:listener];
    }
}

- (void)unregisterGestureEventListener:(id<IGestureEventListener>)listener {
    [self.guestureEventListeners removeObject:listener];
}

- (void)comment {
    self.isShowBlankMenu = NO;
    unsigned int color = [self getPropertyBarSettingColor:e_annotNote];

    float pageWidth = [_pdfViewCtrl getPageViewWidth:self.currentPageIndex];
    float pageHeight = [_pdfViewCtrl getPageViewHeight:self.currentPageIndex];

    float scale = pageWidth / 1000.0;
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.currentPoint pageIndex:self.currentPageIndex];

    if (pvPoint.x > pageWidth - NOTE_ANNOTATION_WIDTH * scale * 2)
        pvPoint.x = pageWidth - NOTE_ANNOTATION_WIDTH * scale * 2;
    if (pvPoint.y > pageHeight - NOTE_ANNOTATION_WIDTH * scale * 2)
        pvPoint.y = pageHeight - NOTE_ANNOTATION_WIDTH * scale * 2;

    CGRect rect = CGRectMake(pvPoint.x - NOTE_ANNOTATION_WIDTH * scale / 2, pvPoint.y - NOTE_ANNOTATION_WIDTH * scale / 2, NOTE_ANNOTATION_WIDTH * scale, NOTE_ANNOTATION_WIDTH * scale);
    FSRectF *dibRect = [_pdfViewCtrl convertPageViewRectToPdfRect:rect pageIndex:self.currentPageIndex];

    NoteDialog *noteDialog = [[NoteDialog alloc] init];
    [noteDialog show:nil replyAnnots:nil title:nil];
    noteDialog.noteEditDone = ^(NoteDialog *dialog) {
        FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:self.currentPageIndex];
        if (!page)
            return;

        FSNote *note = (FSNote *) [page addAnnot:e_annotNote rect:dibRect];
        note.color = color;
        int opacity = [self getPropertyBarSettingOpacity:e_annotNote];
        note.opacity = opacity / 100.0f;
        note.icon = self.noteIcon;
        note.author = [SettingPreference getAnnotationAuthor];
        note.contents = [dialog getContent];
        note.NM = [Utility getUUID];
        note.lineWidth = 2;
        note.modifiedDate = [NSDate date];
        note.createDate = [NSDate date];
        [note resetAppearanceStream];
        id<IAnnotHandler> annotHandler = [self getAnnotHandlerByAnnot:note];
        [annotHandler addAnnot:note];
    };
    [self setCurrentToolHandler:nil];
}

- (void)typeWriter {
    self.isShowBlankMenu = NO;
    FtToolHandler *toolHandler = (FtToolHandler *) [self getToolHandlerByName:Tool_Freetext];
    [self setCurrentToolHandler:toolHandler];
    toolHandler.freeTextStartPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.currentPoint pageIndex:self.currentPageIndex];
    [toolHandler onPageViewTap:self.currentPageIndex recognizer:nil];
    toolHandler.isTypewriterToolbarActive = NO;
    if (self.currentToolHandler == (id<IToolHandler>)self) { // todo
        [self setCurrentToolHandler:nil];
    }
}

- (void)signature {
    self.isShowBlankMenu = NO;
    SignToolHandler *toolHandler = (SignToolHandler *) [self getToolHandlerByName:Tool_Signature];
    [self setCurrentToolHandler:toolHandler];
    toolHandler.isAdded = NO;
    toolHandler.signatureStartPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.currentPoint pageIndex:self.currentPageIndex];
    [toolHandler onPageViewTap:self.currentPageIndex recognizer:nil];
}

- (void)showBlankMenu:(int)pageIndex point:(CGPoint)point {
    self.isShowBlankMenu = YES;
    self.currentPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    self.currentPageIndex = pageIndex;
    NSMutableArray *array = [NSMutableArray array];
    MenuItem *commentItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kNote") object:self action:@selector(comment)];
    MenuItem *typeWriterItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kTypewriter") object:self action:@selector(typeWriter)];
    MenuItem *signatureItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kSignAction") object:self action:@selector(signature)];

    if ([Utility canAddAnnotToDocument:_pdfViewCtrl.currentDoc]) {
        if ([self.modulesConfig.tools containsObject:Tool_Note]) {
            [array addObject:commentItem];
        }
        if ([self.modulesConfig.tools containsObject:Tool_Freetext]) {
            [array addObject:typeWriterItem];
        }
    }
    if ([Utility canAddSignToDocument:_pdfViewCtrl.currentDoc]) {
        if (self.modulesConfig.loadSignature)
            [array addObject:signatureItem];
    }

    if (array.count > 0) {
        CGRect dvRect = CGRectMake(point.x, point.y, 2, 2);
        dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:dvRect pageIndex:pageIndex];
        MenuControl *annotMenu = self.menuControl;
        annotMenu.menuItems = array;
        [annotMenu setRect:dvRect];
        [annotMenu showMenu];
    } else {
        self.isShowBlankMenu = NO;
    }
}

- (BOOL)onLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getDisplayView]];
    int pageIndex = [_pdfViewCtrl getPageIndex:point];
    if (pageIndex < 0)
        return NO;
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint cgPoint = [gestureRecognizer locationInView:pageView];
    CGRect rect1 = [pageView frame];
    CGSize size = rect1.size;
    if (cgPoint.x > size.width || cgPoint.y > size.height || cgPoint.x < 0 || cgPoint.y < 0)
        return NO;

    //avoid to call onLongPress again when showBlankMenu
    if (self.isShowBlankMenu) {
        return YES;
    }

    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_REFLOW) {
        return NO;
    }
    id<IToolHandler> originToolHandler = self.currentToolHandler;
    if (self.currentToolHandler != nil) {
        if ([self.currentToolHandler onPageViewLongPress:pageIndex recognizer:gestureRecognizer]) {
            return YES;
        }
    }
    id<IToolHandler> selectTool = [self getToolHandlerByName:Tool_Select];
    if (self.currentToolHandler == selectTool)
        [self setCurrentToolHandler:nil];

    if (self.currentToolHandler == nil) {
        //annot handler
        FSAnnot *annot = nil;
        id<IAnnotHandler> annotHandler = nil;
        annot = self.currentAnnot;
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            return [annotHandler onPageViewLongPress:pageIndex recognizer:gestureRecognizer annot:annot];
        }

        point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        annot = [self getAnnotAtPoint:point pageIndex:pageIndex];
        if (annot != nil) {
            if ([annot getType] != e_annotLink && ![annot isKindOfClass:[FSTextMarkup class]]) //for adding text markups one more at same text
            {
                annotHandler = [self getAnnotHandlerByAnnot:annot];
                if (annotHandler != nil) {
                    return [annotHandler onPageViewLongPress:pageIndex recognizer:gestureRecognizer annot:annot];
                }
            }
        }

        id<IAnnotHandler> linkAnnotHandler = [self getAnnotHandlerByType:e_annotLink];
        if (linkAnnotHandler && [linkAnnotHandler onPageViewLongPress:pageIndex recognizer:gestureRecognizer annot:nil]) {
            return YES;
        }

        if (originToolHandler != selectTool && [selectTool onPageViewLongPress:pageIndex recognizer:gestureRecognizer]) {
            if (self.currentToolHandler == nil) {
                [self setCurrentToolHandler:selectTool];
            }
            return YES;
        }

        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            [self showBlankMenu:pageIndex point:point];
            return YES;
        }
    }

    for (id<IGestureEventListener> listener in self.guestureEventListeners) {
        if ([listener respondsToSelector:@selector(onLongPress:)]) {
            if ([listener onLongPress:gestureRecognizer])
                return YES;
        }
    }

    return NO;
}

#pragma mark ILinkEventListener

- (void)registerLinkEventListener:(id<ILinkEventListener>)listener {
    if (!self.linkEventListeners) {
        self.linkEventListeners = [NSMutableArray<ILinkEventListener> array];
    }
    [self.linkEventListeners addObject:listener];
}

- (void)unregisterLinkEventListener:(id<ILinkEventListener>)listener {
    [self.linkEventListeners removeObject:listener];
}

- (BOOL)onLinkOpen:(id)link LocationInfo:(CGPoint)pointParam {
    for (id<ILinkEventListener> listener in self.linkEventListeners) {
        if ([listener respondsToSelector:@selector(onLinkOpen:LocationInfo:)]) {
            if ([listener onLinkOpen:link LocationInfo:pointParam])
                return YES;
        }
    }
    return NO;
}

- (BOOL)onTap:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getDisplayView]];
    int pageIndex = [_pdfViewCtrl getPageIndex:point];
    if (pageIndex < 0)
        return NO;
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint cgPoint = [gestureRecognizer locationInView:pageView];
    CGRect rect1 = [pageView frame];
    CGSize size = rect1.size;
    if (cgPoint.x > size.width || cgPoint.y > size.height || cgPoint.x < 0 || cgPoint.y < 0)
        return NO;

    self.isShowBlankMenu = NO;
    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_REFLOW) {
        return NO;
    }
    id<IToolHandler> originToolHandler = self.currentToolHandler;
    if (self.currentToolHandler != nil) {
        if ([self.currentToolHandler onPageViewTap:pageIndex recognizer:gestureRecognizer]) {
            return YES;
        }
    }
    id<IToolHandler> selectTool = [self getToolHandlerByName:Tool_Select];
    if (self.currentToolHandler == selectTool)
        [self setCurrentToolHandler:nil];

    if (self.currentToolHandler == nil) {
        //annot handler
        FSAnnot *annot = nil;
        id<IAnnotHandler> annotHandler = nil;
        annot = self.currentAnnot;
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            return [annotHandler onPageViewTap:pageIndex recognizer:gestureRecognizer annot:annot];
        }
        point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        annot = [self getAnnotAtPoint:point pageIndex:pageIndex];

        if (originToolHandler != selectTool && [selectTool onPageViewTap:pageIndex recognizer:gestureRecognizer]) {
            return YES;
        }
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            if (annotHandler != nil) {
                return [annotHandler onPageViewTap:pageIndex recognizer:gestureRecognizer annot:annot];
            }
        }

        id<IAnnotHandler> linkAnnotHandler = [self getAnnotHandlerByType:e_annotLink];
        if (linkAnnotHandler && [linkAnnotHandler onPageViewTap:pageIndex recognizer:gestureRecognizer annot:nil]) {
            return YES;
        }
    }

    for (id<IGestureEventListener> listener in self.guestureEventListeners) {
        if ([listener respondsToSelector:@selector(onTap:)]) {
            if ([listener onTap:gestureRecognizer])
                return YES;
        }
    }

    if (_currentState == STATE_PAGENAVIGATE)
        return NO;
    CGFloat width = pageView.bounds.size.width;
    if (width * 0.2 < point.x && point.x < width * 0.8) {
        self.isFullScreen = !self.isFullScreen;
        return YES;
    } else if (([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_RIGHT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_MIDDLE) && width * 1.2 < point.x && point.x < width * 1.8) {
        self.isFullScreen = !self.isFullScreen;
        return YES;
    } else {
        return NO;
    }

    return NO;
}

- (BOOL)onPan:(UIPanGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getDisplayView]];
    int pageIndex = [_pdfViewCtrl getPageIndex:point];
    if (pageIndex < 0)
        return NO;
    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_REFLOW) {
        return NO;
    }
    id<IToolHandler> originToolHandler = self.currentToolHandler;
    if (self.currentToolHandler != nil) {
        if ([self.currentToolHandler onPageViewPan:pageIndex recognizer:recognizer]) {
            return YES;
        }
    }
    id<IToolHandler> selectTool = [self getToolHandlerByName:Tool_Select];
    if (self.currentToolHandler == selectTool)
        [self setCurrentToolHandler:nil];

    if (self.currentToolHandler == nil) {
        //annot handler
        FSAnnot *annot = nil;
        id<IAnnotHandler> annotHandler = nil;
        annot = self.currentAnnot;
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            return [annotHandler onPageViewPan:pageIndex recognizer:recognizer annot:annot];
        }

        point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        annot = [self getAnnotAtPoint:point pageIndex:pageIndex];
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            if (annotHandler != nil) {
                return [annotHandler onPageViewPan:pageIndex recognizer:recognizer annot:annot];
            }
        }
        id<IToolHandler> selectTool = [self getToolHandlerByName:Tool_Select];
        if (originToolHandler != selectTool && [selectTool onPageViewPan:pageIndex recognizer:recognizer]) {
            return YES;
        }
    }
    for (id<IGestureEventListener> listener in self.guestureEventListeners) {
        if ([listener respondsToSelector:@selector(onPan:)]) {
            if ([listener onPan:recognizer])
                return YES;
        }
    }
    return NO;
}

- (FSAnnot *)getAnnotAtPoint:(CGPoint)pvPoint pageIndex:(int)pageIndex {
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    FSMatrix *matrix = [_pdfViewCtrl getDisplayMatrix:pageIndex];
    FSPointF *devicePoint = [[FSPointF alloc] init];
    [devicePoint set:pvPoint.x y:pvPoint.y];
    FSAnnot *annot = [page getAnnotAtDevicePos:matrix position:devicePoint tolerance:5];

    if (!annot) {
        return nil;
    }
    if (![self.modulesConfig canInteractWithAnnot:annot]) {
        return nil;
    }

    id<IAnnotHandler> annotHandler = [self getAnnotHandlerByAnnot:annot];
    if ([annotHandler isHitAnnot:annot point:[_pdfViewCtrl convertPageViewPtToPdfPt:pvPoint pageIndex:pageIndex]]) {
        return annot;
    }

    if (annot.type == e_annotStrikeOut) {
        FSMarkup *markup = (FSMarkup *) annot;
        for (int i = 0; i < [markup getGroupElementCount]; i++) {
            FSAnnot *groupAnnot = [markup getGroupElement:i];
            if (groupAnnot.type == e_annotCaret) {
                return groupAnnot;
            }
        }
        return annot;
    }
    return nil;
}

- (BOOL)onShouldBegin:(UIGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getDisplayView]];
    int pageIndex = [_pdfViewCtrl getPageIndex:point];
    if (pageIndex < 0)
        return NO;

    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_REFLOW) {
        return NO;
    }
    if (_currentToolHandler != nil) {
        if ([_currentToolHandler respondsToSelector:@selector(onPageViewShouldBegin:recognizer:)] && [_currentToolHandler onPageViewShouldBegin:pageIndex recognizer:recognizer]) {
            return YES;
        }
    }

    if (self.currentToolHandler == nil || [[self.currentToolHandler getName] isEqualToString:Tool_Select]) {
        //annot handler
        FSAnnot *annot = nil;
        id<IAnnotHandler> annotHandler = nil;
        annot = self.currentAnnot;
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            return [annotHandler onPageViewShouldBegin:pageIndex recognizer:recognizer annot:annot];
        }

        if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            if (((UITapGestureRecognizer *) recognizer).numberOfTapsRequired == 2) {
                return NO;
            }
        }

        if ([recognizer isKindOfClass:[UITapGestureRecognizer class]] ||
            [recognizer isKindOfClass:[UILongPressGestureRecognizer class]] ||
            [recognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
            annot = [self getAnnotAtPoint:point pageIndex:pageIndex];
            if (annot != nil) {
                annotHandler = [self getAnnotHandlerByAnnot:annot];
                if (annotHandler != nil && ![recognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
                    return [annotHandler onPageViewShouldBegin:pageIndex recognizer:recognizer annot:annot];
                }
            }

            id<IAnnotHandler> linkAnnotHandler = [self getAnnotHandlerByType:e_annotLink];
            if (linkAnnotHandler && [linkAnnotHandler onPageViewShouldBegin:pageIndex recognizer:recognizer annot:nil] && ![recognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
                return YES;
            }

            id<IToolHandler> selectTool = [self getToolHandlerByName:Tool_Select];
            if (self.currentToolHandler != selectTool && [selectTool onPageViewShouldBegin:pageIndex recognizer:recognizer]) {
                return YES;
            }
        }
        return NO;
    }
    // return no here,
    // make the pan gesture recognized by the page container
    if (self.currentToolHandler != nil) {
        NSString *name = [self.currentToolHandler getName];
        if (name != nil) {
            return YES;
        }
    }

    for (id<IGestureEventListener> listener in self.guestureEventListeners) {
        if ([listener respondsToSelector:@selector(onShouldBegin:)]) {
            if ([listener onShouldBegin:recognizer])
                return YES;
        }
    }

    return NO;
}

- (BOOL)onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[_pdfViewCtrl getDisplayView]];
    int pageIndex = [_pdfViewCtrl getPageIndex:point];
    if (pageIndex < 0)
        return NO;

    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_REFLOW) {
        return NO;
    }
    if (_currentToolHandler != nil) {
        if ([_currentToolHandler onPageViewTouchesBegan:pageIndex touches:touches withEvent:event]) {
            return YES;
        }
    } else {
        //annot handler
        FSAnnot *annot = nil;
        id<IAnnotHandler> annotHandler = nil;
        annot = self.currentAnnot;
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            return [annotHandler onPageViewTouchesBegan:pageIndex touches:touches withEvent:event annot:annot];
        }
        point = [[touches anyObject] locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        annot = [self getAnnotAtPoint:point pageIndex:pageIndex];
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            if (annotHandler != nil) {
                return [annotHandler onPageViewTouchesBegan:pageIndex touches:touches withEvent:event annot:annot];
            }
        }
        return NO;
    }
    return NO;
}
- (BOOL)onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[_pdfViewCtrl getDisplayView]];
    int pageIndex = [_pdfViewCtrl getPageIndex:point];
    if (pageIndex < 0)
        return NO;

    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_REFLOW) {
        return NO;
    }
    if (_currentToolHandler != nil) {
        if ([_currentToolHandler onPageViewTouchesMoved:pageIndex touches:touches withEvent:event]) {
            return YES;
        }
    } else {
        //annot handler
        FSAnnot *annot = nil;
        id<IAnnotHandler> annotHandler = nil;
        annot = self.currentAnnot;
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            return [annotHandler onPageViewTouchesMoved:pageIndex touches:touches withEvent:event annot:annot];
        }
        point = [[touches anyObject] locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        annot = [self getAnnotAtPoint:point pageIndex:pageIndex];
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            if (annotHandler != nil) {
                return [annotHandler onPageViewTouchesMoved:pageIndex touches:touches withEvent:event annot:annot];
            }
        }
        return NO;
    }
    return NO;
}

- (BOOL)onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[_pdfViewCtrl getDisplayView]];
    int pageIndex = [_pdfViewCtrl getPageIndex:point];
    if (pageIndex < 0)
        return NO;

    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_REFLOW) {
        return NO;
    }
    /** The current tool will handle the tourches first if it's actived. */
    if (_currentToolHandler != nil) {
        if ([_currentToolHandler onPageViewTouchesEnded:pageIndex touches:touches withEvent:event]) {
            return YES;
        }
    } else {
        //annot handler
        FSAnnot *annot = nil;
        id<IAnnotHandler> annotHandler = nil;
        annot = self.currentAnnot;
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            return [annotHandler onPageViewTouchesEnded:pageIndex touches:touches withEvent:event annot:annot];
        }
        point = [[touches anyObject] locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        annot = [self getAnnotAtPoint:point pageIndex:pageIndex];
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            if (annotHandler != nil) {
                return [annotHandler onPageViewTouchesEnded:pageIndex touches:touches withEvent:event annot:annot];
            }
        }
        return NO;
    }
    return NO;
}

- (BOOL)onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[_pdfViewCtrl getDisplayView]];
    int pageIndex = [_pdfViewCtrl getPageIndex:point];
    if (pageIndex < 0)
        return NO;

    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_REFLOW) {
        return NO;
    }

    if (_currentToolHandler != nil) {
        if ([_currentToolHandler onPageViewTouchesCancelled:pageIndex touches:touches withEvent:event]) {
            return YES;
        }
    } else {
        //annot handler
        FSAnnot *annot = nil;
        id<IAnnotHandler> annotHandler = nil;
        annot = self.currentAnnot;
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            return [annotHandler onPageViewTouchesCancelled:pageIndex touches:touches withEvent:event annot:annot];
        }
        point = [[touches anyObject] locationInView:[_pdfViewCtrl getPageView:pageIndex]];
        annot = [self getAnnotAtPoint:point pageIndex:pageIndex];
        if (annot != nil) {
            annotHandler = [self getAnnotHandlerByAnnot:annot];
            if (annotHandler != nil) {
                return [annotHandler onPageViewTouchesCancelled:pageIndex touches:touches withEvent:event annot:annot];
            }
        }
        return NO;
    }
    return NO;
}

#pragma mark IDrawEventListener
- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
    for (id<IToolHandler> handler in self.toolHandlers) {
        if ([handler respondsToSelector:@selector(onDraw:inContext:)]) {
            [handler onDraw:pageIndex inContext:context];
        }
    }

    if (self.currentAnnot) {
        id<IAnnotHandler> annotHandler = [self getAnnotHandlerByAnnot:self.currentAnnot];
        if ([annotHandler respondsToSelector:@selector(onDraw:inContext:annot:)]) {
            [annotHandler onDraw:pageIndex inContext:context annot:self.currentAnnot];
        }
    }

    id<IAnnotHandler> annotHandler = [self getAnnotHandlerByType:e_annotLink];
    if (annotHandler) {
        if ([annotHandler respondsToSelector:@selector(onDraw:inContext:annot:)]) {
            [annotHandler onDraw:pageIndex inContext:context annot:nil];
        }
    }
}

- (void)onAnnotAdded:(FSPDFPage *)page annot:(FSAnnot *)annot {
    for (id<IAnnotEventListener> listener in self.annotListeners) {
        if ([listener respondsToSelector:@selector(onAnnotAdded:annot:)]) {
            [listener onAnnotAdded:page annot:annot];
        }
    }
    self.isDocModified = YES;
    if ([self getState] != STATE_ANNOTTOOL)
        return;
    if (!self.continueAddAnnot && ![[self.currentToolHandler getName] isEqualToString:Tool_Pencil]) {
        [self setCurrentToolHandler:nil];
        [self changeState:STATE_EDIT];
    }
}

- (void)onAnnotWillDelete:(FSPDFPage *)page annot:(FSAnnot *)annot {
    if (annot == self.currentAnnot) {
        _currentAnnot = nil;
    }

    for (id<IAnnotEventListener> listener in self.annotListeners) {
        if ([listener respondsToSelector:@selector(onAnnotWillDelete:annot:)]) {
            [listener onAnnotWillDelete:page annot:annot];
        }
    }
}

- (void)onAnnotDeleted:(FSPDFPage *)page annot:(FSAnnot *)annot {
    for (id<IAnnotEventListener> listener in self.annotListeners) {
        if ([listener respondsToSelector:@selector(onAnnotDeleted:annot:)]) {
            [listener onAnnotDeleted:page annot:annot];
        }
    }
    self.isDocModified = YES;
}

- (void)onAnnotModified:(FSPDFPage *)page annot:(FSAnnot *)annot {
    for (id<IAnnotEventListener> listener in self.annotListeners) {
        if ([listener respondsToSelector:@selector(onAnnotModified:annot:)]) {
            [listener onAnnotModified:page annot:annot];
        }
    }

    self.isDocModified = YES;
}
- (void)onAnnotSelected:(FSPDFPage *)page annot:(FSAnnot *)annot {
    for (id<IAnnotEventListener> listener in self.annotListeners) {
        if ([listener respondsToSelector:@selector(onAnnotSelected:annot:)]) {
            [listener onAnnotSelected:page annot:annot];
        }
    }
}

- (void)onAnnotDeselected:(FSPDFPage *)page annot:(FSAnnot *)annot {
    for (id<IAnnotEventListener> listener in self.annotListeners) {
        if ([listener respondsToSelector:@selector(onAnnotDeselected:annot:)]) {
            [listener onAnnotDeselected:page annot:annot];
        }
    }
}

- (void)onScrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}
- (void)onScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
{
    [self showAnnotMenu];
}
- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}
- (void)onScrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self showAnnotMenu];
}
- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView {
    [self dismissAnnotMenu];
}
- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView {
    [self showAnnotMenu];
    if (self.zoomSlider) {
        self.zoomSlider.value = [_pdfViewCtrl getZoom];
    }
}

- (void)setCurrentAnnot:(FSAnnot *)annot {
    if ([self.currentAnnot getCptr] == [annot getCptr]) {
        return;
    }

    if (self.currentAnnot != nil) {
        id<IAnnotHandler> annotHandler = [self getAnnotHandlerByAnnot:self.currentAnnot];
        if (annotHandler) {
            [annotHandler onAnnotDeselected:self.currentAnnot];
            [self onAnnotDeselected:[annot getPage] annot:self.currentAnnot];
        }
    }

    _currentAnnot = annot;
    if (annot != nil) {
        int pageIndex = annot.pageIndex;
        CGRect pvRect = [Utility getAnnotRect:annot pdfViewCtrl:_pdfViewCtrl];
        pvRect = CGRectIntersection([_pdfViewCtrl getPageView:pageIndex].bounds, pvRect);
        CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:pageIndex];
        BOOL isAnnotVisible = CGRectContainsRect(_pdfViewCtrl.bounds, dvRect);

        void (^block)(void) = ^{
            id<IAnnotHandler> annotHandler = [self getAnnotHandlerByAnnot:annot];
            if (annotHandler) {
                [annotHandler onAnnotSelected:annot];
                [self onAnnotSelected:[annot getPage] annot:annot];
            }
        };

        if (isAnnotVisible) {
            block();
        } else {
            FSPointF *fspt = [[FSPointF alloc] init];
            FSRectF *fsrect = annot.type == e_annotCaret ? [Utility getCaretAnnotRect:(FSCaret *) annot] : annot.fsrect;
            [fspt set:fsrect.left y:fsrect.top];
            if (DEVICE_iPHONE) {
                //Avoid being sheltered from top bar. To do, need to check page rotation.
                [fspt setY:[fspt getY] + 64];
            }
            [_pdfViewCtrl gotoPage:pageIndex withDocPoint:fspt animated:YES];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                block();
            });
        }
    }
}

#pragma mark - annot property

- (void)showProperty:(FSAnnotType)annotType rect:(CGRect)rect inView:(UIView *)view {
    // stamp
    if (annotType == e_annotStamp) {
        {
            __weak UIExtensionsManager *weakSelf = self;
            self.stampIconController = [[StampIconController alloc] initWithUIExtensionsManager:self];
            self.stampIconController.selectHandler = ^(int icon) {
                ((StampToolHandler *) [weakSelf getToolHandlerByName:Tool_Stamp]).stampIcon = icon;
                if (DEVICE_iPHONE) {
                    [weakSelf.stampIconController dismissViewControllerAnimated:YES completion:nil];
                }
            };
        }
        if (DEVICE_iPHONE) {
            UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
            [rootViewController presentViewController:self.stampIconController animated:YES completion:nil];
        } else {
            self.popOverController = [[UIPopoverController alloc] initWithContentViewController:self.stampIconController];
            self.popOverController.delegate = self;
            [self.popOverController setPopoverContentSize:CGSizeMake(300, 420)];
            [self.popOverController presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        return;
    }
    // eraser
    if (annotType == e_annotInk && [[self.currentToolHandler getName] isEqualToString:Tool_Eraser]) {
        [self.propertyBar resetBySupportedItems:PROPERTY_LINEWIDTH frame:CGRectZero];
        [self.propertyBar setProperty:PROPERTY_COLOR intValue:[UIColor grayColor].rgbHex];
        [self.propertyBar setProperty:PROPERTY_LINEWIDTH intValue:self.eraserLineWidth];
        [self.propertyBar addListener:self];
        [self.propertyBar showPropertyBar:rect inView:view viewsCanMove:nil];
        return;
    }

    // image
    if (annotType == e_annotScreen) {
        [self.propertyBar resetBySupportedItems:PROPERTY_OPACITY | PROPERTY_ROTATION frame:CGRectZero];
        [self.propertyBar setProperty:PROPERTY_COLOR intValue:[UIColor grayColor].rgbHex];
        [self.propertyBar setProperty:PROPERTY_OPACITY intValue:[self getAnnotOpacity:annotType]];
        [self.propertyBar setProperty:PROPERTY_ROTATION intValue:self.screenAnnotRotation];
        [self.propertyBar addListener:self];
        [self.propertyBar showPropertyBar:rect inView:view viewsCanMove:nil];
        return;
    }

    NSArray *colors = nil;
    if (annotType == e_annotHighlight) {
        colors = @[ @0xFFFF00, @0xCCFF66, @0x00FFFF, @0x99CCFF, @0x7480FC, @0xCC99FF, @0xFF99FF, @0xFF9999, @0x00CC66, @0x22F3B1 ];
    } else if (annotType == e_annotUnderline || annotType == e_annotSquiggly) {
        colors = @[ @0x33CC00, @0xCCCC00, @0xFF9933, @0x0099CC, @0xBBBBBB, @0x3366FF, @0xCC33FF, @0xCC0099, @0xFF0000, @0x686767 ];
    } else if (annotType == e_annotStrikeOut) {
        colors = @[ @0xFF3333, @0xFF00FF, @0x9966FF, @0x66CC33, @0x996666, @0xCCCC00, @0xFF9900, @0x00CCFF, @0x00CCCC, @0x000000 ];
    } else if (annotType == e_annotNote) {
        colors = @[ @0xFF9F40, @0x8080FF, @0xBAE94C, @0xFFF160, @0xC3C3C3, @0xFF4C4C, @0x669999, @0xC72DA1, @0x996666, @0x000000 ];
    } else if (annotType == e_annotCircle || annotType == e_annotSquare || annotType == e_annotLine) {
        colors = @[ @0xFF9F40, @0x8080FF, @0xBAE94C, @0xFFF160, @0xC3C3C3, @0xFF4C4C, @0x669999, @0xC72DA1, @0x996666, @0x000000 ];
    } else if (annotType == e_annotFreeText) {
        if ([[self.currentToolHandler getName] isEqualToString:Tool_Textbox]) {
            colors = @[ @0x7480FC, @0xFFFF00, @0xCCFF66, @0x00FFFF, @0x99CCFF, @0xCC99FF, @0xFF9999, @0xFFFFFF, @0xC3C3C3, @0x000000 ];
        } else {
            colors = @[ @0x3366CC, @0x669933, @0xCC6600, @0xCC9900, @0xA3A305, @0xCC0000, @0x336666, @0x660066, @0x000000, @0x8F8E8E ];
        }
    } else if (annotType == e_annotInk) {
        colors = @[ @0xFF9F40, @0x8080FF, @0xBAE94C, @0xFFF160, @0xC3C3C3, @0xFF4C4C, @0x669999, @0xC72DA1, @0x996666, @0x000000 ];
    } else if (annotType == e_annotCaret || annotType == e_annotFileAttachment) {
        colors = @[ @0xFF9F40, @0x8080FF, @0xBAE94C, @0xFFF160, @0x996666, @0xFF4C4C, @0x669999, @0xFFFFFF, @0xC3C3C3, @0x000000 ];
    } else if (annotType == e_annotPolygon) {
        colors = ((PolygonAnnotHandler *) [self getAnnotHandlerByType:e_annotPolygon]).colors;
    }

    [self.propertyBar setColors:colors];

    if (annotType == e_annotSquare || annotType == e_annotCircle || (annotType == e_annotLine && ![[self.currentToolHandler getName] isEqualToString:Tool_Distance]) || annotType == e_annotPolygon) {
        [self.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_LINEWIDTH frame:CGRectZero];
        [self.propertyBar setProperty:PROPERTY_LINEWIDTH intValue:[self getAnnotLineWidth:annotType]];
    } else if (annotType == e_annotFreeText) {
        [self.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_FONTNAME | PROPERTY_FONTSIZE frame:CGRectZero];
        [self.propertyBar setProperty:PROPERTY_FONTSIZE floatValue:[self getAnnotFontSize:annotType]];
        [self.propertyBar setProperty:PROPERTY_FONTNAME stringValue:[self getAnnotFontName:annotType]];
    } else if (annotType == e_annotInk) {
        [self.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_LINEWIDTH frame:CGRectZero];
        [self.propertyBar setProperty:PROPERTY_LINEWIDTH intValue:[self getAnnotLineWidth:annotType]];
    } else if (annotType == e_annotFileAttachment) {
        [self.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_ATTACHMENT_ICONTYPE frame:CGRectZero];
        [self.propertyBar setProperty:PROPERTY_ATTACHMENT_ICONTYPE intValue:self.attachmentIcon];
    }
    // distance
    else if (annotType == e_annotLine && [[self.currentToolHandler getName] isEqualToString:Tool_Distance]) {
        [self.propertyBar resetBySupportedItems:PROPERTY_DISTANCE_UNIT | PROPERTY_COLOR | PROPERTY_OPACITY frame:CGRectZero];
        
        [self.propertyBar setProperty:PROPERTY_COLOR intValue:[self getPropertyBarSettingColor:annotType]];
        [self.propertyBar setProperty:PROPERTY_OPACITY intValue:[self getAnnotOpacity:annotType]];
        
        [self.propertyBar setProperty:PROPERTY_DISTANCE_UNIT stringValue:self.distanceUnit];
    
        [self.propertyBar addListener:self];
        [self.propertyBar showPropertyBar:rect inView:view viewsCanMove:nil];
        return;
    }
    else {
        [self.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY frame:CGRectZero];
    }
    [self.propertyBar setProperty:PROPERTY_COLOR intValue:[self getPropertyBarSettingColor:annotType]];
    [self.propertyBar setProperty:PROPERTY_OPACITY intValue:[self getAnnotOpacity:annotType]];

    
    
    if (annotType == e_annotNote) {
        if (self.noteIcon == 0) {
            self.noteIcon = 2;
        }
        [self.propertyBar setProperty:PROPERTY_ICONTYPE intValue:self.noteIcon];
    }
    [self.propertyBar addListener:self];
    [self.propertyBar showPropertyBar:rect inView:view viewsCanMove:nil];
}

/** @brief Customized annotation type on application level. */
#define e_annotArrowLine 99
#define e_annotInsert 101
#define e_annotTextbox 103
#define e_annotCloud 105

- (int)filterAnnotType:(FSAnnotType)annotType {
    if (e_annotLine == annotType) {
        LineToolHandler *toolHandler = [self getToolHandlerByName:Tool_Line];
        if (toolHandler.isArrowLine)
            return e_annotArrowLine;
    } else if (e_annotCaret == annotType) {
        NSString *toolHandlerName = [self.currentToolHandler getName];
        if ([toolHandlerName isEqualToString:Tool_Insert]) {
            return e_annotInsert;
        } else if ([toolHandlerName isEqualToString:Tool_Replace])
            return e_annotCaret;
        CaretAnnotHandler *annotHandler = (CaretAnnotHandler *) [self getAnnotHandlerByType:e_annotCaret];
        if (annotHandler.isInsert) {
            return e_annotInsert;
        }
    } else if (e_annotFreeText == annotType) {
        BOOL isTextbox = NO;
        if ([[self.currentToolHandler getName] isEqualToString:Tool_Textbox]) {
            isTextbox = YES;
        } else if (self.currentAnnot && self.currentAnnot.type == e_annotFreeText && self.currentAnnot.intent == nil) {
            isTextbox = YES;
        }
        if (isTextbox) {
            return e_annotTextbox;
        }
    } else if (e_annotPolygon == annotType) {
        BOOL isPolygon = YES;
        if ([[self.currentToolHandler getName] isEqualToString:Tool_Polygon]) {
            isPolygon = ((PolygonToolHandler *) self.currentToolHandler).isPolygon;
        } else if (self.currentAnnot && self.currentAnnot.type == e_annotPolygon) {
            isPolygon = !([[((FSPolygon *) self.currentAnnot) getBorderInfo] getStyle] == e_borderStyleCloudy);
        }
        if (!isPolygon) {
            return e_annotCloud;
        }
    }

    return annotType;
}

- (unsigned int)getPropertyBarSettingColor:(FSAnnotType)annotType {
    return [self getAnnotColor:annotType];
}

- (unsigned int)getPropertyBarSettingOpacity:(FSAnnotType)annotType {
    return [self getAnnotOpacity:annotType];
}

- (unsigned int)getAnnotColor:(FSAnnotType)annotType {
    NSNumber *colorNum = self.annotColors[[NSNumber numberWithInt:[self filterAnnotType:annotType]]];
    if (colorNum != nil) {
        return colorNum.intValue;
    } else {
        // markup
        if (annotType == e_annotHighlight) {
            return 0xFFFF00;
        } else if (annotType == e_annotUnderline || annotType == e_annotSquiggly) {
            return 0x33CC00;
        } else if (annotType == e_annotStrikeOut) {
            return 0xFF3333;
        }
        // note
        else if (annotType == e_annotNote) {
            return 0xFF9F40;
        }
        // shape
        else if (annotType == e_annotSquare || annotType == e_annotCircle || annotType == e_annotLine) {
            return 0xFF9F40;
        }
        // free text
        else if (annotType == e_annotFreeText) {
            return 0x3366CC;
        } else if (annotType == e_annotInk) {
            return 0xbae94c;
        } else if (annotType == e_annotCaret || annotType == e_annotFileAttachment) {
            return 0xFF9F40;
        } else {
            return 0;
        }
    }
}

- (void)setAnnotColor:(unsigned int)color annotType:(FSAnnotType)annotType {
    self.annotColors[[NSNumber numberWithInt:[self filterAnnotType:annotType]]] = @(color);
    for (id<IAnnotPropertyListener> listender in self.annotPropertyListeners) {
        if ([listender respondsToSelector:@selector(onAnnotColorChanged:annotType:)])
            [listender onAnnotColorChanged:color annotType:annotType];
    }
}

- (int)getAnnotOpacity:(FSAnnotType)annotType {
    int opacity = ((NSNumber *) self.annotOpacities[[NSNumber numberWithInt:[self filterAnnotType:annotType]]]).intValue;
    return opacity ? opacity : 100;
}

- (void)setAnnotOpacity:(int)opacity annotType:(FSAnnotType)annotType {
    self.annotOpacities[[NSNumber numberWithInt:[self filterAnnotType:annotType]]] = @(opacity);
    for (id<IAnnotPropertyListener> listender in self.annotPropertyListeners) {
        if ([listender respondsToSelector:@selector(onAnnotOpacityChanged:annotType:)])
            [listender onAnnotOpacityChanged:opacity annotType:annotType];
    }
}

- (int)getAnnotLineWidth:(FSAnnotType)annotType {
    NSNumber *widthNum = self.annotLineWidths[[NSNumber numberWithInt:[self filterAnnotType:annotType]]];
    if (widthNum != nil) {
        return widthNum.intValue;
    } else {
        return 2;
    }
}

- (void)setAnnotLineWidth:(int)lineWidth annotType:(FSAnnotType)annotType {
    self.annotLineWidths[[NSNumber numberWithInt:[self filterAnnotType:annotType]]] = @(lineWidth);
    for (id<IAnnotPropertyListener> listener in self.annotPropertyListeners) {
        if ([listener respondsToSelector:@selector(onAnnotLineWidthChanged:annotType:)]) {
            [listener onAnnotLineWidthChanged:lineWidth annotType:annotType];
        }
    }
}

- (int)getAnnotFontSize:(FSAnnotType)annotType {
    NSNumber *num = (NSNumber *) self.annotFontSizes[@([self filterAnnotType:annotType])];
    if (num) {
        return num.intValue;
    } else {
        return 18;
    }
}

- (void)setAnnotFontSize:(int)fontSize annotType:(FSAnnotType)annotType {
    self.annotFontSizes[@([self filterAnnotType:annotType])] = @(fontSize);
    for (id<IAnnotPropertyListener> listener in self.annotPropertyListeners) {
        if ([listener respondsToSelector:@selector(onAnnotFontSizeChanged:annotType:)]) {
            [listener onAnnotFontSizeChanged:fontSize annotType:annotType];
        }
    }
}

- (NSString *)getAnnotFontName:(FSAnnotType)annotType {
    return self.annotFontNames[@([self filterAnnotType:annotType])] ?: @"Courier";
}

- (void)setAnnotFontName:(NSString *)fontName annotType:(FSAnnotType)annotType {
    self.annotFontNames[@([self filterAnnotType:annotType])] = fontName;
    for (id<IAnnotPropertyListener> listener in self.annotPropertyListeners) {
        if ([listener respondsToSelector:@selector(onAnnotFontNameChanged:annotType:)]) {
            [listener onAnnotFontNameChanged:fontName annotType:annotType];
        }
    }
}

- (void)setNoteIcon:(int)noteIcon {
    _noteIcon = noteIcon;
    for (id<IAnnotPropertyListener> listener in self.annotPropertyListeners) {
        if ([listener respondsToSelector:@selector(onAnnotIconChanged:annotType:)]) {
            [listener onAnnotIconChanged:noteIcon annotType:e_annotNote];
        }
    }
}

- (void)setAttachmentIcon:(int)attachmentIcon {
    _attachmentIcon = attachmentIcon;
    for (id<IAnnotPropertyListener> listener in self.annotPropertyListeners) {
        if ([listener respondsToSelector:@selector(onAnnotIconChanged:annotType:)]) {
            [listener onAnnotIconChanged:attachmentIcon annotType:e_annotFileAttachment];
        }
    }
}

- (void)setScreenAnnotRotation:(FSRotation)screenAnnotRotation {
    _screenAnnotRotation = screenAnnotRotation;
    for (id<IAnnotPropertyListener> listener in self.annotPropertyListeners) {
        if ([listener respondsToSelector:@selector(onAnnotRotationChanged:annotType:)]) {
            [listener onAnnotRotationChanged:screenAnnotRotation annotType:e_annotScreen];
        }
    }
}

#pragma mark - IPropertyValueChangedListener
- (void)onProperty:(long)property changedFrom:(NSValue *)oldValue to:(NSValue *)newValue {
    FSAnnot *annot = self.currentAnnot;
    if (annot) {
        //        BOOL addUndo;
        //        switch (annot.type) {
        //        case e_annotNote:
        //        case e_annotCircle:
        //        case e_annotSquare:
        //        case e_annotFreeText:
        //        // text markup
        //        case e_annotHighlight:
        //        case e_annotUnderline:
        //        case e_annotStrikeOut:
        //        case e_annotSquiggly:
        //
        //        case e_annotLine:
        //        case e_annotInk:
        //        case e_annotCaret:
        //        case e_annotStamp:
        //            addUndo = NO;
        //            break;
        //        default:
        //            addUndo = YES;
        //            break;
        //        }
        [self changeAnnot:annot property:property from:oldValue to:newValue];
    }

    FSAnnotType annotType = annot ? annot.type : _currentToolHandler.type;
    switch (property) {
    case PROPERTY_COLOR:
        [self setAnnotColor:[(NSNumber *) newValue unsignedIntValue] annotType:annotType];
        break;
    case PROPERTY_OPACITY:
        [self setAnnotOpacity:[(NSNumber *) newValue unsignedIntValue] annotType:annotType];
        break;
    case PROPERTY_ICONTYPE:
        self.noteIcon = [(NSNumber *) newValue intValue];
        break;
    case PROPERTY_ATTACHMENT_ICONTYPE:
        self.attachmentIcon = [(NSNumber *) newValue unsignedIntValue];
        break;
    case PROPERTY_LINEWIDTH:
        if ([[self.currentToolHandler getName] isEqualToString:Tool_Eraser]) {
            self.eraserLineWidth = [(NSNumber *) newValue unsignedIntValue];
        } else {
            [self setAnnotLineWidth:[(NSNumber *) newValue unsignedIntValue] annotType:annotType];
        }
        break;
    case PROPERTY_FONTSIZE:
        [self setAnnotFontSize:[(NSNumber *) newValue unsignedIntValue] annotType:annotType];
        break;
    case PROPERTY_FONTNAME:
        [self setAnnotFontName:(NSString *) [newValue nonretainedObjectValue] annotType:annotType];
        break;
    case PROPERTY_DISTANCE_UNIT:
        self.distanceUnit = (NSString *) [newValue nonretainedObjectValue];
            break;
    case PROPERTY_ROTATION:
        self.screenAnnotRotation = [Utility rotationForValue:newValue];
        break;
    default:
        break;
    }
}

- (void)changeAnnot:(FSAnnot *)annot property:(long)property from:(NSValue *)oldValue to:(NSValue *)newValue // addUndo:(BOOL)addUndo
{
    int pageIndex = annot.pageIndex;
    CGRect oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    BOOL modified = YES;
    switch (property) {
    case PROPERTY_COLOR:
        annot.color = [(NSNumber *) newValue unsignedIntValue];
        break;
    case PROPERTY_OPACITY:
        annot.opacity = [(NSNumber *) newValue unsignedIntValue] / 100.0f;
        break;
    case PROPERTY_ICONTYPE:
        if (annot.type == e_annotNote) {
            ((FSNote *) annot).icon = [(NSNumber *) newValue unsignedIntValue];
        } else {
            modified = NO;
        }
        break;
    case PROPERTY_ATTACHMENT_ICONTYPE:
        if (annot.type == e_annotFileAttachment) {
            ((FSFileAttachment *) annot).icon = [(NSNumber *) newValue unsignedIntValue];
        } else {
            modified = NO;
        }
        break;
    case PROPERTY_LINEWIDTH:
        annot.lineWidth = [(NSNumber *) newValue unsignedIntValue];
        break;
    case PROPERTY_FONTSIZE:
        if (annot.type == e_annotFreeText) {
            FSFreeText *freeText = (FSFreeText *) annot;
            int newFontSize = [(NSNumber *) newValue unsignedIntValue];
            FSDefaultAppearance *ap = [freeText getDefaultAppearance];
            ap.fontSize = newFontSize;
            [freeText setDefaultAppearance:ap];
        } else {
            modified = NO;
        }
        break;
    case PROPERTY_FONTNAME:
        if (annot.type == e_annotFreeText) {
            FSFreeText *freeText = (FSFreeText *) annot;
            NSString *newFontName = (NSString *) [newValue nonretainedObjectValue];
            FSDefaultAppearance *ap = [freeText getDefaultAppearance];
            FSFont *originFont = ap.font;
            if ([newFontName caseInsensitiveCompare:[originFont getName]] != NSOrderedSame) {
                int fontID = [Utility toStandardFontID:newFontName];
                if (fontID == -1) {
                    ap.font = [[FSFont alloc] initWithFontName:newFontName fontStyles:0 weight:0 charset:e_fontCharsetDefault];
                } else {
                    ap.font = [[FSFont alloc] initWithStandardFontID:fontID];
                }
                [freeText setDefaultAppearance:ap];
            }
        } else {
            modified = NO;
        }
        break;
    case PROPERTY_DISTANCE_UNIT:
        if (annot.type == e_annotLine) {
            FSLine *lineAnnot = (FSLine *) annot;
            if ([[lineAnnot getIntent] isEqualToString:@"LineDimension"]) {
                NSString *unitName = (NSString *) [newValue nonretainedObjectValue];
                annot.subject = unitName;
            }
        }
        break;
    case PROPERTY_ROTATION:
        if (annot.type == e_annotScreen) {
            FSRotation rotation = [Utility rotationForValue:newValue];
            [(FSScreen *) annot setRotation:rotation];
        } else {
            modified = NO;
        }
        break;
    default:
        modified = NO;
        break;
    }
    if (modified) {
        FSDateTime *now = [Utility convert2FSDateTime:[NSDate date]];
        [annot setModifiedDateTime:now];
        [annot resetAppearanceStream];

        // keep annot in bounds
        {
            FSRectF *rect = annot.fsrect;
            FSPDFPage *page = [annot getPage];
            BOOL isOutOfBounds = NO;
            if (rect.bottom < 0) {
                rect.top -= rect.bottom;
                rect.bottom = 0;
                isOutOfBounds = YES;
            }
            float w = [page getWidth];
            if (rect.right > w) {
                rect.left -= rect.right - w;
                rect.right = w;
                isOutOfBounds = YES;
            }
            if (isOutOfBounds) {
                annot.fsrect = rect;
                [annot resetAppearanceStream];
            }
        }

        id<IAnnotHandler> annotHandler = [self getAnnotHandlerByAnnot:annot];
        if ([annotHandler respondsToSelector:@selector(onAnnotChanged:property:from:to:)]) {
            [annotHandler onAnnotChanged:annot property:property from:oldValue to:newValue];
        }

        if ([self shouldDrawAnnot:annot]) {
            CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            rect = CGRectUnion(rect, oldRect);
            rect = CGRectInset(rect, -20, -20);
            [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
        }

        if (annot.type == e_annotCaret && [(FSMarkup *) annot isGrouped]) {
            for (int i = 0; i < [(FSMarkup *) annot getGroupElementCount]; i++) {
                FSAnnot *groupAnnot = [(FSMarkup *) annot getGroupElement:i];
                if (groupAnnot && ![groupAnnot.NM isEqualToString:annot.NM]) {
                    [self changeAnnot:groupAnnot property:property from:oldValue to:newValue];
                }
            }
        }
    }
}

- (void)registerAnnotPropertyListener:(id<IAnnotPropertyListener>)listener {
    [self.annotPropertyListeners addObject:listener];
}

- (void)unregisterAnnotPropertyListener:(id<IAnnotPropertyListener>)listener {
    if (listener) {
        [self.annotPropertyListeners removeObject:listener];
    }
}

- (void)showSearchBar:(BOOL)show {
    __block SearchModule *search = nil;
    [self.modules enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<IModule> module = obj;
        if ([module respondsToSelector:@selector(getName)] &&
            [[module getName] isEqualToString:@"Search"]) {
            search = (SearchModule *) module;
            *stop = YES;
        }
    }];
    [search showSearchBar:show];
}

- (NSString *)getCurrentSelectedText {
    id<IToolHandler> toolHandler = [self getToolHandlerByName:Tool_Select];
    if (!toolHandler)
        return nil;
    SelectToolHandler *selHandler = (SelectToolHandler *) toolHandler;
    return [selHandler copyText];
}

#pragma mark - IRecoveryEventListener

- (void)onWillRecover {
    self.currentAnnot = nil;
    self.currentToolHandler = nil;
}

- (void)onRecovered {
    [FSLibrary setAnnotIconProvider:_iconProvider];
    [FSLibrary setActionHandler:_actionHandler];
    //    [FSLibrary registerDefaultSignatureHandler];
}

- (BOOL)shouldDrawAnnot:(FSAnnot *)annot {
    if (!self.currentAnnot) {
        return YES;
    }
    // these types should draw in annot handler
    static FSAnnotType shouldNotRenderTypes[] = {
        e_annotFreeText,
        e_annotLine,
        e_annotNote,
        e_annotInk,
        e_annotSquare,
        e_annotCircle,
        e_annotStamp,
        e_annotFileAttachment,
        e_annotScreen,
        e_annotPolygon};
    if ((self.currentAnnot == annot || [self.currentAnnot.NM isEqualToString:annot.NM])) {
        FSAnnotType type = annot.type;
        for (int i = 0; i < sizeof(shouldNotRenderTypes) / sizeof(shouldNotRenderTypes[0]); i++) {
            if (shouldNotRenderTypes[i] == type) {
                if (type == e_annotFreeText) {
                    NSString *intent = [((FSMarkup *) annot) getIntent];
                    if (intent && [intent caseInsensitiveCompare:@"FreeTextTypewriter"] != NSOrderedSame)
                        return YES;
                }
                return NO;
            }
        }
    }
    if (annot.type == e_annotInk) {
        FSPDFPath *path = [(FSInk *) annot getInkList];
        if ([path getPointCount] <= 1) {
            return NO;
        }
    }
    if ([[self.currentToolHandler getName] isEqualToString:Tool_Polygon]) {
        if (((PolygonToolHandler *) self.currentToolHandler).annot == annot) {
            return NO;
        }
    }
    return YES;
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popOverController = nil;
    self.isShowBlankMenu = NO;

    [self setHiddenMoreToolsBar:YES];
}

#pragma mark IDocEventListener

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    _currentAnnot = nil;
    _currentToolHandler = nil;
    [self clearUndoRedo];
    self.menuControl.menuItems = nil;
    self.isShowBlankMenu = NO;
}

#pragma mark thumbnail

- (void)showThumbnailView {
    if (!self.thumbnailViewController) {
        self.thumbnailViewController = [[FSThumbnailViewController alloc] initWithDocument:self.pdfViewCtrl.currentDoc];
        self.thumbnailViewController.delegate = self;
        self.thumbnailViewController.pageManipulationDelegate = self.pdfViewCtrl;
        [self registerRotateChangedListener:self.thumbnailViewController];
    }

    [self.pdfViewCtrl addSubview:self.thumbnailViewController.view];
    [UIView transitionWithView:self.pdfViewCtrl duration:0.8 options:UIViewAnimationOptionTransitionFlipFromRight animations:nil completion:nil];
}

- (void)removeThumbnailCacheOfPageAtIndex:(NSUInteger)pageIndex {
    [self.thumbnailCache removeThumbnailCacheOfPageAtIndex:pageIndex];
}

- (void)clearThumbnailCachesForPDFAtPath:(NSString *)path {
    [self.thumbnailCache clearThumbnailCachesForPDFAtPath:path];
}

#pragma mark <FSThumbnailViewControllerDelegate>

- (void)exitThumbnailViewController:(FSThumbnailViewController *)thumbnailViewController {
    [thumbnailViewController.view removeFromSuperview];
    self.thumbnailViewController = nil; //to delete
    [UIView transitionWithView:_pdfViewCtrl duration:0.8 options:UIViewAnimationOptionTransitionFlipFromLeft animations:nil completion:nil];
    [self.settingBar updateLayoutButtonsWithLayout:[_pdfViewCtrl getPageLayoutMode]];
}

- (void)thumbnailViewController:(FSThumbnailViewController *)thumbnailViewController openPage:(int)page {
    [thumbnailViewController.view removeFromSuperview];
    self.thumbnailViewController = nil; //to delete
    [_pdfViewCtrl gotoPage:page animated:NO];
    [UIView transitionWithView:_pdfViewCtrl duration:0.8 options:UIViewAnimationOptionTransitionFlipFromLeft animations:nil completion:nil];
    [self.settingBar updateLayoutButtonsWithLayout:[_pdfViewCtrl getPageLayoutMode]];
}

- (void)thumbnailViewController:(FSThumbnailViewController *)thumbnailViewController getThumbnailForPageAtIndex:(NSUInteger)index thumbnailSize:(CGSize)thumbnailSize needPause:(BOOL (^__nullable)(void))needPause callback:(void (^__nonnull)(UIImage *))callback {
    [self.thumbnailCache getThumbnailForPageAtIndex:index withThumbnailSize:thumbnailSize needPause:needPause callback:callback];
}

- (void)buildToolbars {
    CGRect screenFrame = _pdfViewCtrl.bounds;
    if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        screenFrame = CGRectMake(0, 0, screenFrame.size.height, screenFrame.size.width);
    }

    maskView = [[UIControl alloc] initWithFrame:_pdfViewCtrl.bounds];
    maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;

    self.topToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screenFrame.size.width, 44)];
    self.topToolbar.clipsToBounds = YES; // remove border line
    self.topToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    self.bottomToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, screenFrame.size.height - 49, screenFrame.size.width, 49)];

    self.editDoneBar = [[TbBaseBar alloc] init];
    self.editDoneBar.contentView.frame = CGRectMake(0, 0, 200, 64);
    self.editDoneBar.top = YES;
    self.editDoneBar.hasDivide = NO;

    self.editBar = [[TbBaseBar alloc] init];
    self.editBar.top = NO;
    self.editBar.hasDivide = NO;
    if (DEVICE_iPHONE) {
        self.editBar.interval = YES;
    } else {
        self.editBar.intervalWidth = 30;
    }
    self.editBar.contentView.frame = CGRectMake(0, screenFrame.size.height - 49, screenFrame.size.width, 49);

    self.toolSetBar = [[TbBaseBar alloc] init];
    self.toolSetBar.contentView.frame = CGRectMake(0, screenFrame.size.height - 49, screenFrame.size.width, 49);
    self.toolSetBar.hasDivide = NO;
    self.toolSetBar.top = NO;
    if (DEVICE_iPHONE) {
        self.toolSetBar.intervalWidth = 20;
    } else {
        self.toolSetBar.intervalWidth = 30;
    }

    self.more = [[MenuView alloc] init];
    [self.more getContentView].frame = CGRectMake(_pdfViewCtrl.bounds.size.width - 300, 0, 300, _pdfViewCtrl.bounds.size.height);
    [self.more setMenuTitle:FSLocalizedString(@"kMore")];
    typeof(self) __weak weakSelf = self;
    self.more.onCancelClicked = ^{
        [weakSelf setHiddenMoreMenu:YES];
    };

    self.settingBar = [[SettingBar alloc] initWithUIExtensionsManager:self];
    self.settingBar.delegate = self;

    self.moreToolsBar = [[MoreAnnotationsBar alloc] initWithWidth:DEVICE_iPHONE ? screenFrame.size.width : 300 config:self.modulesConfig];

    [self.pdfViewCtrl addSubview:self.topToolbar];
    [self.pdfViewCtrl addSubview:self.bottomToolbar];
    [self.pdfViewCtrl addSubview:self.editDoneBar.contentView];
    [self.pdfViewCtrl addSubview:self.editBar.contentView];
    [self.pdfViewCtrl addSubview:self.toolSetBar.contentView];
    [self.pdfViewCtrl addSubview:[self.more getContentView]];
    [self.pdfViewCtrl addSubview:self.settingBar.contentView];
    if (DEVICE_iPHONE) {
        [self.pdfViewCtrl addSubview:self.moreToolsBar.contentView];
    }

    [self setHiddenSettingBar:YES animated:NO];
    [self setHiddenEditDoneBar:YES animated:NO];
    [self setHiddenEditBar:YES animated:NO];
    [self setHiddenToolSetBar:YES animated:NO];
    [self setHiddenMoreMenu:YES animated:NO];
    [self setHiddenMoreToolsBar:YES animated:NO];
    self.isPopoverhidden = NO;
}

- (void)buildItems {
    __weak typeof(self) weakSelf = self;

    // top toolbar
    self.backButton = [Utility createButtonWithImage:[UIImage imageNamed:@"common_back_black"]];
    self.backButton.tag = FS_TOPBAR_ITEM_BACK_TAG;
    [self.backButton addTarget:self action:@selector(onClickBackButton:) forControlEvents:UIControlEventTouchUpInside];
    self.backButton.enabled = NO;

    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    backButtonItem.tag = FS_TOPBAR_ITEM_BACK_TAG;
    UIBarButtonItem *leftPadding = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    const CGFloat paddingWidth = 10.f;
    leftPadding.width = paddingWidth - [Utility getUIToolbarPaddingX];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.topToolbar.items = @[ leftPadding, backButtonItem, flexibleSpace ];
    
    _topToolBarItemsArr = [self.topToolbar.items mutableCopy];

    // edit toolbar
    UIImage *commonReadMore = [UIImage imageNamed:@"common_read_more"];
    UIImage *annoToolitembg = [UIImage imageNamed:@"annotation_toolitembg"];
    self.moreAnnotItem = [TbBaseItem createItemWithImage:commonReadMore imageSelected:commonReadMore imageDisable:commonReadMore background:annoToolitembg];
    self.moreAnnotItem.tag = 1;
    self.moreAnnotItem.onTapClick = ^(TbBaseItem *item) {
        if (weakSelf.currentAnnot) {
            [weakSelf setCurrentAnnot:nil];
        }
        weakSelf.hiddenMoreToolsBar = NO;
    };
    [self.editBar addItem:self.moreAnnotItem displayPosition:DEVICE_iPHONE ? Position_RB : Position_CENTER];

    UIImage *commonBackBlue = [UIImage imageNamed:@"common_back_blue"];
    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:commonBackBlue imageSelected:commonBackBlue imageDisable:commonBackBlue background:nil];
    doneItem.tag = 0;
    [self.editDoneBar addItem:doneItem displayPosition:Position_LT];
    doneItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf setCurrentToolHandler:nil];
        if (weakSelf.currentAnnot) {
            [weakSelf setCurrentAnnot:nil];
        }
        [self changeState:STATE_NORMAL];

    };

    // bottom toolbar
    NSMutableArray<UIBarButtonItem *> *bottomBarItems = @[].mutableCopy;
    if (self.modulesConfig.loadReadingBookmark || self.modulesConfig.loadOutline || [self.modulesConfig.tools containsAnyObjectNotInArray:@[ Tool_Select, Tool_Eraser ]] || self.modulesConfig.loadAttachment) {
        UIButton *panelButton = [self createButtonWithTitle:FSLocalizedString(@"kReadList") image:[UIImage imageNamed:@"read_panel"]];
        panelButton.contentEdgeInsets = UIEdgeInsetsMake((CGRectGetHeight(self.bottomToolbar.frame) - CGRectGetHeight(panelButton.frame)) / 2, 0, 0, 0);
        panelButton.tag = FS_BOTTOMBAR_ITEM_PANEL_TAG;
        [panelButton addTarget:self action:@selector(onClickBottomBarButton:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:panelButton];
        item.tag = FS_BOTTOMBAR_ITEM_PANEL_TAG;
        [bottomBarItems addObject:item];
    }

    UIButton *readModeButton = [self createButtonWithTitle:FSLocalizedString(@"kReadView") image:[UIImage imageNamed:@"read_mode"]];
    readModeButton.contentEdgeInsets = UIEdgeInsetsMake((49 - CGRectGetHeight(readModeButton.frame)) / 2, 0, 0, 0);
    readModeButton.tag = FS_BOTTOMBAR_ITEM_READMODE_TAG;
    [readModeButton addTarget:self action:@selector(onClickBottomBarButton:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:readModeButton];
    item.tag = FS_BOTTOMBAR_ITEM_READMODE_TAG;
    [bottomBarItems addObject:item];

    if ([self.modulesConfig.tools containsAnyObjectNotInArray:@[ Tool_Select ]] || self.modulesConfig.loadAttachment) {
        self.annotButton = [self createButtonWithTitle:FSLocalizedString(@"kReadComment") image:[UIImage imageNamed:@"read_annot"]];
        self.annotButton.contentEdgeInsets = UIEdgeInsetsMake((49 - CGRectGetHeight(self.annotButton.frame)) / 2, 0, 0, 0);
        self.annotButton.tag = FS_BOTTOMBAR_ITEM_ANNOT_TAG;
        [self.annotButton addTarget:self action:@selector(onClickBottomBarButton:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.annotButton];
        item.tag = FS_BOTTOMBAR_ITEM_ANNOT_TAG;
        [bottomBarItems addObject:item];
    }

    NSMutableArray<UIBarButtonItem *> *tmpArray = @[].mutableCopy;
    for (UIBarButtonItem *item in bottomBarItems) {
        [tmpArray addObject:flexibleSpace];
        [tmpArray addObject:item];
    }
    [tmpArray addObject:flexibleSpace];
    bottomBarItems = tmpArray;
    self.bottomToolbar.items = bottomBarItems;
}

- (UIButton *)createButtonWithTitle:(NSString *)title image:(UIImage *)image {
    UIFont *textFont = [UIFont systemFontOfSize:9.f];
    CGSize titleSize = [Utility getTextSize:title fontSize:textFont.pointSize maxSize:CGSizeMake(400, 100)];
    float width = image.size.width;
    float height = image.size.height;
    CGRect frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width : width, titleSize.height + height);

    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [button setEnlargedEdge:ENLARGE_EDGE];

    [button setTitle:title forState:UIControlStateNormal];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, -height, 0);
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = textFont;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];

    [button setImage:image forState:UIControlStateNormal];
    UIImage *translucentImage = [Utility imageByApplyingAlpha:image alpha:0.5];
    [button setImage:translucentImage forState:UIControlStateHighlighted];
    [button setImage:translucentImage forState:UIControlStateDisabled];
    button.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width);

    return button;
}

- (void)saveAndCloseCurrentDoc:(void (^_Nullable)(BOOL success))completion {
    NSString *intermediateFilePath = nil;
    NSString *filePath = self.pdfViewCtrl.filePath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isAsync = ![fileManager fileExistsAtPath:filePath];
    if (filePath) {
        if (!isAsync) {
            NSString *tempDir = NSTemporaryDirectory();
            intermediateFilePath = [tempDir stringByAppendingPathComponent:[filePath lastPathComponent]];
            [self.pdfViewCtrl saveDoc:intermediateFilePath flag:self.docSaveFlag];
        } else {
            NSString *fileName = [filePath lastPathComponent];
            NSString *path = [DOCUMENT_PATH stringByAppendingPathComponent:fileName];
            if ([fileManager fileExistsAtPath:path]) {
                [fileManager removeItemAtPath:path error:nil];
            }
            NSLog(@"saving async doc to %@...", path);
            // todo wei, show alert view with cancel button
            [self.pdfViewCtrl saveDoc:path flag:self.docSaveFlag];
        }
    }
    [self.pdfViewCtrl closeDoc:^() {
        BOOL isOK = YES;
        if (filePath && !isAsync) {
            NSError *error = nil;
            if ([fileManager fileExistsAtPath:filePath]) {
                [fileManager removeItemAtPath:filePath error:nil];
            }
            isOK = [fileManager moveItemAtPath:intermediateFilePath toPath:filePath error:&error];
        }
        if (completion) {
            completion(isOK);
        }
    }];
}

- (void)buttonSaveClick {
    [self.popover dismiss];
    self.popover = nil;
    self.isFileEdited = YES;
    _isDocModified = NO;

    [self saveAndCloseCurrentDoc:^(BOOL success) {
        if (self.goBack)
            self.goBack();
    }];
}

- (void)buttonDiscardChangeClick {
    [self.popover dismiss];
    self.popover = nil;
    self.isFileEdited = NO;
    _isDocModified = NO;
    NSString *filePath = self.pdfViewCtrl.filePath;
    [self.pdfViewCtrl closeDoc:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self clearThumbnailCachesForPDFAtPath:filePath];
    });
    if (self.goBack)
        self.goBack();
}

- (void)setHiddenToolSetBar:(BOOL)hiddenToolSetBar {
    [self setHiddenToolSetBar:hiddenToolSetBar animated:YES];
}

- (void)setHiddenToolSetBar:(BOOL)hiddenToolSetBar animated:(BOOL)animated {
    _hiddenToolSetBar = hiddenToolSetBar;
    if (hiddenToolSetBar) {
        if (animated) {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.toolSetBar.contentView.alpha = 0.f;
                             }];
        } else {
            self.toolSetBar.contentView.alpha = 0.f;
        }
        self.toolSetBar.hidden = hiddenToolSetBar;
        [self.toolSetBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(@49);
            make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
            make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
            make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
        }];
    } else {
        self.toolSetBar.hidden = hiddenToolSetBar;
        if (animated) {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.toolSetBar.contentView.alpha = 1.f;
                                 [self.toolSetBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                     make.height.mas_equalTo(@49);
                                     make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                     make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                     make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                                 }];
                             }];
        } else {
            self.toolSetBar.contentView.alpha = 1.f;
            [self.toolSetBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@49);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
            }];
        }
    }
}

- (void)setHiddenEditBar:(BOOL)hiddenEditBar {
    [self setHiddenEditBar:hiddenEditBar animated:YES];
}

- (void)setHiddenEditBar:(BOOL)hiddenEditBar animated:(BOOL)animated {
    if (_hiddenEditBar == hiddenEditBar) {
        return;
    }
    _hiddenEditBar = hiddenEditBar;
    if (hiddenEditBar) {
        CGRect newFrame = self.editBar.contentView.frame;
        newFrame.origin.y = _pdfViewCtrl.bounds.size.height;
        if (animated) {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.editBar.contentView.frame = newFrame;
                                 [self.editBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                     make.height.mas_equalTo(@49);
                                     make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                     make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                     make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                                 }];
                             }];
        } else {
            self.editBar.contentView.frame = newFrame;
            [self.editBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@49);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
            }];
        }
    } else {
        CGRect newFrame = self.editBar.contentView.frame;
        newFrame.origin.y = _pdfViewCtrl.bounds.size.height - self.editBar.contentView.frame.size.height;
        if (animated) {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.editBar.contentView.frame = newFrame;
                                 [self.editBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                     make.height.mas_equalTo(@49);
                                     make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                     make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                     make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                                 }];
                             }];
        } else {
            self.editBar.contentView.frame = newFrame;
            [self.editBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@49);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
            }];
        }
    }
}

- (void)setHiddenEditDoneBar:(BOOL)hiddenEditDoneBar {
    [self setHiddenEditDoneBar:hiddenEditDoneBar animated:YES];
}

- (void)setHiddenEditDoneBar:(BOOL)hiddenEditDoneBar animated:(BOOL)animated {
    if (_hiddenEditDoneBar == hiddenEditDoneBar) {
        return;
    }
    _hiddenEditDoneBar = hiddenEditDoneBar;
    if (hiddenEditDoneBar) {
        CGRect newFrame = self.editDoneBar.contentView.frame;
        newFrame.origin.y = -self.editDoneBar.contentView.frame.size.height;
        if (animated) {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.editDoneBar.contentView.frame = newFrame;
                                 [self.editDoneBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                     make.height.mas_equalTo(@64);
                                     make.width.mas_equalTo(@200);
                                     make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                     make.bottom.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                                 }];
                             }
                             completion:^(BOOL finished){
                             }];
        } else {
            self.editDoneBar.contentView.frame = newFrame;
            [self.editDoneBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@64);
                make.width.mas_equalTo(@200);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_top).offset(0);
            }];
        }
    } else {
        CGRect newFrame = self.editDoneBar.contentView.frame;
        newFrame.origin.y = 0;
        if (animated) {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.editDoneBar.contentView.frame = newFrame;
                                 [self.editDoneBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                     make.height.mas_equalTo(@64);
                                     make.width.mas_equalTo(@200);
                                     make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                     make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                                 }];
                             }
                             completion:^(BOOL finished){
                             }];
        } else {
            self.editDoneBar.contentView.frame = newFrame;
            [self.editDoneBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@64);
                make.width.mas_equalTo(@200);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
            }];
        }
    }
}

- (void)setHiddenBottomToolbar:(BOOL)isHiddenBottomToolbar {
    if (_hiddenBottomToolbar == isHiddenBottomToolbar) {
        return;
    }
    _hiddenBottomToolbar = isHiddenBottomToolbar;
    if (_hiddenBottomToolbar) {
        CGRect newFrame = self.bottomToolbar.frame;
        newFrame.origin.y = _pdfViewCtrl.bounds.size.height;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.bottomToolbar.frame = newFrame;
                             [self.bottomToolbar mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.height.mas_equalTo(@49);
                                 make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                 make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                 make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                             }];
                         }];

    } else {
        CGRect newFrame = self.bottomToolbar.frame;
        newFrame.origin.y = _pdfViewCtrl.bounds.size.height - self.bottomToolbar.frame.size.height;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.bottomToolbar.frame = newFrame;
                             [self.bottomToolbar mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.height.mas_equalTo(@49);
                                 make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                 make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                 make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                             }];
                         }];
    }
}

- (void)setHiddenTopToolbar:(BOOL)hiddenTopToolbar {
    if (IOS11_OR_LATER) {
        UIToolbar *topToolbar = self.topToolbar;
        UIView *topToolbarWrapper = topToolbar.superview;
        
        [topToolbarWrapper layoutIfNeeded];
        [topToolbarWrapper bringSubviewToFront:topToolbar];
    }
    
    if (_hiddenTopToolbar == hiddenTopToolbar) {
        return;
    }
    _hiddenTopToolbar = hiddenTopToolbar;
    if ([self.delegate respondsToSelector:@selector(uiextensionsManager:setTopToolBarHidden:)]) {
        [self.delegate uiextensionsManager:self setTopToolBarHidden:hiddenTopToolbar];
        return;
    }
    if (hiddenTopToolbar) {
        CGRect newFrame = self.topToolbar.frame;
        newFrame.origin.y = -self.topToolbar.frame.size.height;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.topToolbar.frame = newFrame;
                             [self.topToolbar mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.height.mas_equalTo(@44);
                                 make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                 make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                 make.bottom.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                             }];
                         }
                         completion:^(BOOL finished){
                         }];
    } else {
        CGRect newFrame = self.topToolbar.frame;
        newFrame.origin.y = 0;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.topToolbar.frame = newFrame;
                             [self.topToolbar mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.height.mas_equalTo(@44);
                                 make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                 make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                 make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                             }];
                         }
                         completion:^(BOOL finished){
                         }];
    }
}

- (void)setHiddenMoreToolsBar:(BOOL)hiddenMoreToolsBar {
    [self setHiddenMoreToolsBar:hiddenMoreToolsBar animated:YES];
}

- (void)setHiddenMoreToolsBar:(BOOL)hiddenMoreToolsBar animated:(BOOL)animated {
    if (_hiddenMoreToolsBar == hiddenMoreToolsBar) {
        return;
    }
    _hiddenMoreToolsBar = hiddenMoreToolsBar;
    if (DEVICE_iPHONE) {
        if (hiddenMoreToolsBar) {
            if (animated) {
                [UIView animateWithDuration:0.4
                    animations:^{
                        maskView.alpha = 0.1f;
                    }
                    completion:^(BOOL finished) {

                        [maskView removeFromSuperview];
                    }];
            } else {
                maskView.alpha = 0.1f;
                [maskView removeFromSuperview];
            }

            CGRect newFrame = self.moreToolsBar.contentView.frame;
            if (DEVICE_iPHONE) {
                newFrame.origin.y = _pdfViewCtrl.bounds.size.height;
            } else {
                newFrame.origin.x = _pdfViewCtrl.bounds.size.width;
            }

            if (animated) {
                [UIView animateWithDuration:0.4
                                 animations:^{
                                     self.moreToolsBar.contentView.frame = newFrame;
                                     [self.moreToolsBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                         make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                                         make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                         make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                         make.height.mas_equalTo(self.moreToolsBar.contentView.frame.size.height);

                                     }];
                                 }];
            } else {
                self.moreToolsBar.contentView.frame = newFrame;
                [self.moreToolsBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                    make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                    make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                    make.height.mas_equalTo(self.moreToolsBar.contentView.frame.size.height);

                }];
            }
        } else {
            maskView.frame = _pdfViewCtrl.bounds;
            maskView.backgroundColor = [UIColor blackColor];
            maskView.alpha = 0.3f;
            maskView.tag = 200;
            [maskView addTarget:self action:@selector(dissmiss:) forControlEvents:UIControlEventTouchUpInside];
            [self.pdfViewCtrl insertSubview:maskView belowSubview:self.moreToolsBar.contentView];
            [maskView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(maskView.superview.mas_left).offset(0);
                make.right.equalTo(maskView.superview.mas_right).offset(0);
                make.top.equalTo(maskView.superview.mas_top).offset(0);
                make.bottom.equalTo(maskView.superview.mas_bottom).offset(0);
            }];
            CGFloat width = CGRectGetWidth(_pdfViewCtrl.bounds);
            [self.moreToolsBar refreshLayoutWithWidth:width];
            CGRect newFrame = self.moreToolsBar.contentView.frame;
            if (DEVICE_iPHONE) {
                newFrame.origin.y = _pdfViewCtrl.bounds.size.height - newFrame.size.height;
            } else {
                newFrame.origin.x = _pdfViewCtrl.bounds.size.width - newFrame.size.width;
            }
            if (animated) {
                [UIView animateWithDuration:0.4
                                 animations:^{
                                     self.moreToolsBar.contentView.frame = newFrame;
                                     [self.moreToolsBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                         make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                                         make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                         make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                         make.height.mas_equalTo(self.moreToolsBar.contentView.frame.size.height);
                                     }];
                                 }];
            } else {
                self.moreToolsBar.contentView.frame = newFrame;
                [self.moreToolsBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                    make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                    make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                    make.height.mas_equalTo(self.moreToolsBar.contentView.frame.size.height);
                }];
            }
        }
    } else {
        if (!hiddenMoreToolsBar) {
            if ([self getState] == STATE_ANNOTTOOL) {
                CGRect rect = CGRectMake(CGRectGetWidth(_pdfViewCtrl.bounds) / 2 + 85, SCREENHEIGHT - 49, 40, 40);
                [self.moreToolbarPopoverCtr presentPopoverFromRect:rect inView:self.pdfViewCtrl permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            } else {
                [self.moreToolbarPopoverCtr presentPopoverFromRect:self.moreAnnotItem.contentView.bounds inView:self.moreAnnotItem.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }

        } else {
            if (self.moreToolbarPopoverCtr.isPopoverVisible) {
                [self.moreToolbarPopoverCtr dismissPopoverAnimated:YES];
            }
        }
    }
}

- (UIPopoverController *)moreToolbarPopoverCtr {
    if (!_moreToolbarPopoverCtr) {
        UIViewController *viewCtr = [[UIViewController alloc] init];
        UIView *view = [[UIView alloc] initWithFrame:self.moreToolsBar.contentView.bounds];
        [view addSubview:self.moreToolsBar.contentView];
        [viewCtr.view addSubview:view];

        [self.moreToolsBar.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(view.mas_left).offset(0);
            make.right.equalTo(view.mas_right).offset(0);
            make.top.equalTo(view.mas_top).offset(0);
            make.bottom.equalTo(view.mas_bottom).offset(0);
        }];

        _moreToolbarPopoverCtr = [[UIPopoverController alloc] initWithContentViewController:viewCtr];
        self.moreToolbarPopoverCtr.delegate = self;
        [self.moreToolbarPopoverCtr setPopoverContentSize:self.moreToolsBar.contentView.bounds.size];
    }
    return _moreToolbarPopoverCtr;
}

- (void)setHiddenMoreMenu:(BOOL)hiddenMoreMenu {
    [self setHiddenMoreMenu:hiddenMoreMenu animated:YES];
}

- (void)setHiddenMoreMenu:(BOOL)hiddenMoreMenu animated:(BOOL)animated {
    if (_hiddenMoreMenu == hiddenMoreMenu) {
        return;
    }
    _hiddenMoreMenu = hiddenMoreMenu;
    if (hiddenMoreMenu) {
        if (animated) {
            [UIView animateWithDuration:0.4
                animations:^{
                    maskView.alpha = 0.1f;
                }
                completion:^(BOOL finished) {

                    [maskView removeFromSuperview];
                }];
        } else {
            maskView.alpha = 0.1f;
            [maskView removeFromSuperview];
        }

        CGRect newFrame = [self.more getContentView].frame;

        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            newFrame.origin.x = _pdfViewCtrl.bounds.size.height;
        } else {
            newFrame.origin.x = _pdfViewCtrl.bounds.size.width;
        }

        if (animated) {
            [UIView animateWithDuration:0.4
                             animations:^{
                                 [self.more getContentView].frame = newFrame;
                                 [[self.more getContentView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                                     make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                                     make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                                     if (DEVICE_iPHONE) {
                                         make.left.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                         make.width.mas_equalTo(newFrame.origin.x);
                                     } else {
                                         make.left.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                         make.width.mas_equalTo(300);
                                     }
                                 }];

                             }];
        } else {
            [self.more getContentView].frame = newFrame;
            [[self.more getContentView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                if (DEVICE_iPHONE) {
                    make.left.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                    make.width.mas_equalTo(newFrame.origin.x);
                } else {
                    make.left.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                    make.width.mas_equalTo(300);
                }
            }];
        }
    } else {
        self.currentToolHandler = nil;
        self.currentAnnot = nil;

        maskView.frame = _pdfViewCtrl.bounds;
        maskView.backgroundColor = [UIColor blackColor];
        maskView.alpha = 0.3f;
        maskView.tag = 201;
        [maskView addTarget:self action:@selector(dissmiss:) forControlEvents:UIControlEventTouchUpInside];

        [self.pdfViewCtrl bringSubviewToFront:[self.more getContentView]];
        [self.pdfViewCtrl insertSubview:maskView belowSubview:[self.more getContentView]];
        [maskView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(maskView.superview.mas_left).offset(0);
            make.right.equalTo(maskView.superview.mas_right).offset(0);
            make.top.equalTo(maskView.superview.mas_top).offset(0);
            make.bottom.equalTo(maskView.superview.mas_bottom).offset(0);
        }];

        CGRect newFrame = [self.more getContentView].frame;

        if (DEVICE_iPHONE) {
            newFrame.origin.x = 0;
        } else {
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                newFrame.origin.x = _pdfViewCtrl.bounds.size.height - [self.more getContentView].frame.size.width;
            } else {
                newFrame.origin.x = _pdfViewCtrl.bounds.size.width - [self.more getContentView].frame.size.width;
            }
        }

        if (animated) {
            [UIView animateWithDuration:0.4
                             animations:^{
                                 [self.more getContentView].frame = newFrame;
                                 [[self.more getContentView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                                     make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                                     make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                                     if (DEVICE_iPHONE) {
                                         make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                                         make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                     } else {
                                         make.width.mas_equalTo(300);
                                         make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                                     }
                                 }];
                             }];
        } else {
            [self.more getContentView].frame = newFrame;
            [[self.more getContentView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                if (DEVICE_iPHONE) {
                    make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                    make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                } else {
                    make.width.mas_equalTo(300);
                    make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                }
            }];
        }
    }
}

- (void)setHiddenSettingBar:(BOOL)hiddenSettingBar {
    [self setHiddenSettingBar:hiddenSettingBar animated:YES];
}
- (void)setHiddenSettingBar:(BOOL)hiddenSettingBar animated:(BOOL)animated {
    if (_hiddenSettingBar == hiddenSettingBar) {
        return;
    }
    _hiddenSettingBar = hiddenSettingBar;
    if (hiddenSettingBar) {
        if (animated) {
            [UIView animateWithDuration:0.4
                animations:^{
                    _settingBarMaskView.alpha = 0.1f;
                }
                completion:^(BOOL finished) {
                    [_settingBarMaskView removeFromSuperview];
                }];
        } else {
            _settingBarMaskView.alpha = 0.1f;
            [_settingBarMaskView removeFromSuperview];
        }

        CGRect newFrame = self.settingBar.contentView.frame;
        newFrame.origin.y = _pdfViewCtrl.bounds.size.height;
        if (animated) {
            [UIView animateWithDuration:0.4
                             animations:^{
                                 self.settingBar.contentView.frame = newFrame;
                                 [self.settingBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                     make.top.equalTo(_pdfViewCtrl.mas_bottom).offset(0);
                                     make.left.equalTo(_pdfViewCtrl.mas_left).offset(0);
                                     make.right.equalTo(_pdfViewCtrl.mas_right).offset(0);
                                     make.height.mas_equalTo(self.settingBar.contentView.frame.size.height);
                                 }];
                             }];
        } else {
            self.settingBar.contentView.frame = newFrame;
            [self.settingBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(_pdfViewCtrl.mas_bottom).offset(0);
                make.left.equalTo(_pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(_pdfViewCtrl.mas_right).offset(0);
                make.height.mas_equalTo(self.settingBar.contentView.frame.size.height);
            }];
        }
    } else {
        if (!_settingBarMaskView) {
            _settingBarMaskView = [[UIControl alloc] initWithFrame:_pdfViewCtrl.bounds];
            _settingBarMaskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
            _settingBarMaskView.backgroundColor = [UIColor blackColor];
            _settingBarMaskView.alpha = 0.3f;
            _settingBarMaskView.tag = 203;
            [_settingBarMaskView addTarget:self action:@selector(hideSettingBar) forControlEvents:UIControlEventTouchUpInside];
        } else {
            _settingBarMaskView.frame = _pdfViewCtrl.bounds;
        }
        [_pdfViewCtrl bringSubviewToFront:self.settingBar.contentView];
        [_pdfViewCtrl insertSubview:_settingBarMaskView belowSubview:self.settingBar.contentView];
        [_settingBarMaskView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_pdfViewCtrl.mas_left).offset(0);
            make.right.equalTo(_pdfViewCtrl.mas_right).offset(0);
            make.top.equalTo(_pdfViewCtrl.mas_top).offset(0);
            make.bottom.equalTo(_pdfViewCtrl.mas_bottom).offset(0);
        }];

        [self.settingBar updateBtnLayout];
        CGRect frame = self.settingBar.contentView.frame;
        frame.origin.y -= self.settingBar.contentView.frame.size.height;
        if (animated) {
            [UIView animateWithDuration:0.4
                             animations:^{
                                 self.settingBar.contentView.frame = frame;
                                 [self.settingBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                     make.bottom.equalTo(_pdfViewCtrl.mas_bottom).offset(0);
                                     make.left.equalTo(_pdfViewCtrl.mas_left).offset(0);
                                     make.right.equalTo(_pdfViewCtrl.mas_right).offset(0);
                                     make.height.mas_equalTo(self.settingBar.contentView.frame.size.height);
                                 }];
                             }];
        } else {
            self.settingBar.contentView.frame = frame;
            [self.settingBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(_pdfViewCtrl.mas_bottom).offset(0);
                make.left.equalTo(_pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(_pdfViewCtrl.mas_right).offset(0);
                make.height.mas_equalTo(self.settingBar.contentView.frame.size.height);
            }];
        }
    }
}

- (void)hideSettingBar {
    self.hiddenSettingBar = YES;
}

- (BOOL)hiddenPanel {
    return self.panelController.isHidden;
}

- (void)setHiddenPanel:(BOOL)hiddenPanel {
    self.panelController.isHidden = hiddenPanel;
}

- (void)dissmiss:(id)sender {
    UIControl *control = (UIControl *) sender;
    if (control.tag == 200) {
        self.hiddenMoreToolsBar = YES;
    } else if (control.tag == 201) {
        self.hiddenMoreMenu = YES;
    }
}

#pragma mark <ILayoutEventListener>

- (void)onLayoutModeChanged:(PDF_LAYOUT_MODE)oldLayoutMode newLayoutMode:(PDF_LAYOUT_MODE)newLayoutMode {
    //    if (newLayoutMode == PDF_LAYOUT_MODE_MULTIPLE)
    //        [self changeState:STATE_THUMBNAIL];
    //    else
    [self changeState:STATE_NORMAL];
}

#pragma mark - handle fullScreen event

- (void)setIsFullScreen:(BOOL)isFullScreen {
    if (_isFullScreen == isFullScreen) {
        return;
    }
    _isFullScreen = isFullScreen;
    if ([self getState] == STATE_NORMAL) {
        if (_isFullScreen) {
            self.hiddenTopToolbar = YES;
            self.hiddenBottomToolbar = YES;
            //            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
        } else {
            self.hiddenTopToolbar = NO;
            self.hiddenBottomToolbar = NO;
            //            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
        }
    }
    for (id<IFullScreenListener> listener in self.fullScreenListeners) {
        if ([listener respondsToSelector:@selector(onFullScreen:)]) {
            [listener onFullScreen:_isFullScreen];
        }
    }
}

- (void)registerFullScreenListener:(id<IFullScreenListener>)listener {
    if (self.fullScreenListeners) {
        [self.fullScreenListeners addObject:listener];
    }
}

- (void)unregisterFullScreenListener:(id<IFullScreenListener>)listener {
    if ([self.fullScreenListeners containsObject:listener]) {
        [self.fullScreenListeners removeObject:listener];
    }
}

#pragma mark - IRotationEventListener

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissAnnotMenu];

    for (id<IRotationEventListener> listener in self.rotateListeners) {
        if ([listener respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)]) {
            [listener willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
        }
    }
    if (!DEVICE_iPHONE && [self.moreToolbarPopoverCtr isPopoverVisible]) {
        [self.moreToolbarPopoverCtr dismissPopoverAnimated:NO];
        self.isPopoverhidden = YES;
    }

    [self.pdfViewCtrl willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissAnnotMenu];

    [self.pdfViewCtrl willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self showAnnotMenu];

    if (!DEVICE_iPHONE && self.isPopoverhidden) {
        self.isPopoverhidden = NO;
        if ([self getState] == STATE_ANNOTTOOL) {
            CGRect rect = CGRectMake(CGRectGetWidth(_pdfViewCtrl.bounds) / 2 + 85, SCREENHEIGHT - 49, 40, 40);
            [self.moreToolbarPopoverCtr presentPopoverFromRect:rect inView:self.pdfViewCtrl permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else {
            [self.moreToolbarPopoverCtr presentPopoverFromRect:self.moreAnnotItem.contentView.bounds inView:self.moreAnnotItem.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }

    for (id<IRotationEventListener> listener in self.rotateListeners) {
        if ([listener respondsToSelector:@selector(didRotateFromInterfaceOrientation:)]) {
            [listener didRotateFromInterfaceOrientation:fromInterfaceOrientation];
        }
    }

    [self.pdfViewCtrl didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if (DEVICE_iPHONE && [self.pdfViewCtrl getDoc]) {
        CGFloat width;
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            width = CGRectGetHeight(_pdfViewCtrl.frame);
        } else {
            width = CGRectGetWidth(_pdfViewCtrl.frame);
        }
        [self.moreToolsBar refreshLayoutWithWidth:width];
    }
    
    //pan zoom
    if (self.panZoomView) {
        [self buildPanZoomBottomBar];
    }
}

- (void)registerRotateChangedListener:(id<IRotationEventListener>)listener {
    if (self.rotateListeners && ![self.rotateListeners containsObject:listener]) {
        [self.rotateListeners addObject:listener];
    }
}

- (void)unregisterRotateChangedListener:(id<IRotationEventListener>)listener {
    if ([self.rotateListeners containsObject:listener]) {
        [self.rotateListeners removeObject:listener];
    }
}

- (void)registerStateChangeListener:(id<IStateChangeListener>)listener {
    if (self.stateChangeListeners) {
        [self.stateChangeListeners addObject:listener];
    }
}

- (void)unregisterStateChangeListener:(id<IStateChangeListener>)listener {
    if ([self.stateChangeListeners containsObject:listener]) {
        [self.stateChangeListeners removeObject:listener];
    }
}

- (void)changeState:(int)state {
    if (state == STATE_NORMAL) {
        [self setCurrentToolHandler:nil];
        [self setCurrentAnnot:nil];
    }
    self.currentState = state;

    self.hiddenTopToolbar = YES;
    self.hiddenBottomToolbar = YES;
    self.hiddenEditBar = YES;
    self.hiddenEditDoneBar = YES;
    self.hiddenToolSetBar = YES;
    self.hiddenMoreMenu = YES;
    self.hiddenMoreToolsBar = YES;
    self.hiddenSettingBar = YES;
    switch (state) {
    case STATE_NORMAL:
        self.hiddenTopToolbar = NO;
        self.hiddenBottomToolbar = NO;
        break;
    case STATE_EDIT:
        self.hiddenEditBar = NO;
        self.hiddenEditDoneBar = NO;
        break;
    case STATE_ANNOTTOOL:
        self.hiddenToolSetBar = NO;
        self.hiddenEditDoneBar = NO;
        break;
    case STATE_SEARCH:
        break;
    default:
        break;
    }
    if (self.stateChangeListeners) {
        for (id<IStateChangeListener> listener in self.stateChangeListeners) {
            if ([listener respondsToSelector:@selector(onStateChanged:)]) {
                [listener onStateChanged:state];
            }
        }
    }
}

- (void)enableTopToolbar:(BOOL)isEnabled {
    if (isEnabled) {
        if (self.topToolbar)
            return;

        if (self.topToolbarSaved) {
            self.topToolbar = self.topToolbarSaved;
            [self.pdfViewCtrl addSubview:self.topToolbar];
        }
    } else {
        if (!self.topToolbar)
            return;
        [self.topToolbar removeFromSuperview];
        self.topToolbarSaved = self.topToolbar;
        self.topToolbar = nil;
    }
}

- (void)enableBottomToolbar:(BOOL)isEnabled {
    if (isEnabled) {
        if (self.bottomToolbar)
            return;

        if (self.bottomToolbarSaved) {
            self.bottomToolbar = self.bottomToolbarSaved;
            [self.pdfViewCtrl addSubview:self.bottomToolbar];
        }
    } else {
        if (!self.bottomToolbar)
            return;
        [self.bottomToolbar removeFromSuperview];
        self.bottomToolbarSaved = self.bottomToolbar;
        self.bottomToolbar = nil;
    }
}

- (int)getState {
    return self.currentState;
}

#pragma mark - IDocEventListener

- (void)onDocWillOpen {
}

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    self.backButton.enabled = YES;
    if (document) {
        self.annotButton.enabled = [Utility canAddAnnotToDocument:document];
    }
}

- (void)onDocModified:(FSPDFDoc *)document {
}

- (void)onDocWillClose:(FSPDFDoc *)document {
    id<IToolHandler> toolHandler = [self getToolHandlerByName:Tool_Freetext];
    if (toolHandler && [toolHandler isKindOfClass:[FtToolHandler class]]) {
        FtToolHandler *ftToolhandler = (FtToolHandler *) toolHandler;
        [ftToolhandler exitWithoutSave];
    }
}

- (void)onDocWillSave:(FSPDFDoc *)document {
}

#pragma mark - IToolEventListener

- (void)onToolChanged:(NSString *)lastToolName CurrentToolName:(NSString *)toolName {
    if (toolName == nil) {
        //Dismiss annotation type.
        FSPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
        for (UIView *view in pdfViewCtrl.subviews) {
            if (view.tag == 2113) {
                [view removeFromSuperview];
            }
        }
    }
    if (toolName && ![toolName isEqualToString:Tool_Select] && ![toolName isEqualToString:Tool_Signature]) {
        if ([self getToolHandlerByName:toolName] != nil) {
            [self changeState:STATE_ANNOTTOOL];
        }
    }
}

- (void)onCurrentAnnotChanged:(FSAnnot *)lastAnnot currentAnnot:(FSAnnot *)currentAnnot {
}

#pragma mark <ISearchEventListener>

- (void)onSearchStarted {
    [self changeState:STATE_SEARCH];
    for (id<ISearchEventListener> listener in self.searchListeners) {
        if ([listener respondsToSelector:@selector(onSearchStarted)]) {
            [listener onSearchStarted];
        }
    }
}

- (void)onSearchCanceled {
    [self changeState:STATE_NORMAL];
    for (id<ISearchEventListener> listener in self.searchListeners) {
        if ([listener respondsToSelector:@selector(onSearchCanceled)]) {
            [listener onSearchCanceled];
        }
    }
}

#pragma mark - IPageEventListener
- (void)onPageVisible:(int)index {
}

- (void)onPageInvisible:(int)index {
}

#pragma mark - top and bottom toolbar events

- (void)onClickBackButton:(UIButton *)button {
    if (self.currentAnnot) {
        [self setCurrentAnnot:nil];
    }

    BOOL isAsync = (self.pdfViewCtrl.filePath != nil) && ![[NSFileManager defaultManager] fileExistsAtPath:self.pdfViewCtrl.filePath];
    if (!isAsync && ![self.pdfViewCtrl.currentDoc isModified] && !_isDocModified) {
        [self.pdfViewCtrl closeDoc:nil];
        if (self.goBack)
            self.goBack();
        return;
    }
    UIView *menu = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 100)];
    UIButton *save = [[UIButton alloc] initWithFrame:CGRectMake(10, 15, 130, 20)];
    [save setTitle:FSLocalizedString(@"kSave") forState:UIControlStateNormal];
    [save setTitleColor:[UIColor colorWithRed:23.f / 255.f green:156.f / 255.f blue:216.f / 255.f alpha:1] forState:UIControlStateNormal];
    [save setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    save.titleLabel.font = [UIFont systemFontOfSize:15];
    [save addTarget:self action:@selector(buttonSaveClick) forControlEvents:UIControlEventTouchUpInside];
    [menu addSubview:save];
    UIButton *discard = [[UIButton alloc] initWithFrame:CGRectMake(10, 65, 130, 20)];
    [discard setTitle:FSLocalizedString(isAsync ? @"kDonotSave" : @"kDiscardChange") forState:UIControlStateNormal];
    [discard setTitleColor:[UIColor colorWithRed:23.f / 255.f green:156.f / 255.f blue:216.f / 255.f alpha:1] forState:UIControlStateNormal];
    [discard setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    discard.titleLabel.font = [UIFont systemFontOfSize:15];
    [discard addTarget:self action:@selector(buttonDiscardChangeClick) forControlEvents:UIControlEventTouchUpInside];
    [menu addSubview:discard];
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, 50, 130, 1)];
    line.backgroundColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1];
    [menu addSubview:line];

    CGPoint startPoint = CGPointMake(CGRectGetMidX(button.frame), CGRectGetMaxY(button.frame));
    self.popover = [DXPopover popover];
    [self.popover showAtPoint:startPoint popoverPosition:DXPopoverPositionDown withContentView:menu inView:self.pdfViewCtrl];
    self.popover.didDismissHandler = ^{
    };
}

- (void)onClickBottomBarButton:(UIButton *)button {
    if (self.currentAnnot) {
        [self setCurrentAnnot:nil];
    }
    switch (button.tag) {
    case FS_BOTTOMBAR_ITEM_PANEL_TAG:
        self.panelController.isHidden = NO;
        break;
    case FS_BOTTOMBAR_ITEM_READMODE_TAG:
        self.hiddenSettingBar = NO;
        break;
    case FS_BOTTOMBAR_ITEM_ANNOT_TAG:
        [self changeState:STATE_EDIT];
        break;
    default:
        break;
    }
}

#pragma mark <FSUndo>

- (void)addUndoItem:(UndoItem *)undoItem {
    if (!undoItem)
        return;
    [self.undoItems addObject:undoItem];
    [self.redoItems removeAllObjects];
    for (id<IFSUndoEventListener> listener in self.undoListeners) {
        [listener onUndoChanged];
    }
}

- (BOOL)canUndo {
    return self.undoItems.count > 0;
}

- (BOOL)canRedo {
    return self.redoItems.count > 0;
}

- (void)undo {
    if (self.currentAnnot) {
        [self setCurrentAnnot:nil];
    }
    //todel
    if ([[self.currentToolHandler getName] isEqualToString:Tool_Freetext]) {
        [(FtToolHandler *) self.currentToolHandler save];
    }
    if (self.undoItems.count == 0)
        return;
    @synchronized(self) {
        UndoItem *item = [self.undoItems objectAtIndex:self.undoItems.count - 1];
        if (item.undo) {
            item.undo(item);
        }
        [self.redoItems addObject:item];
        [self.undoItems removeObject:item];
        for (id<IFSUndoEventListener> listener in self.undoListeners) {
            [listener onUndoChanged];
        }
    }
}

- (void)redo {
    if (self.currentAnnot) {
        [self setCurrentAnnot:nil];
    }
    if ([[self.currentToolHandler getName] isEqualToString:Tool_Freetext]) {
        [(FtToolHandler *) self.currentToolHandler save];
    }
    if (self.redoItems.count == 0)
        return;
    @synchronized(self) {
        UndoItem *item = [self.redoItems objectAtIndex:self.redoItems.count - 1];
        if (item.redo) {
            item.redo(item);
        }
        [self.undoItems addObject:item];
        [self.redoItems removeObject:item];
        for (id<IFSUndoEventListener> listener in self.undoListeners) {
            [listener onUndoChanged];
        }
    }
}

- (void)clearUndoRedo {
    [self.undoItems removeAllObjects];
    [self.redoItems removeAllObjects];
    for (id<IFSUndoEventListener> listener in self.undoListeners) {
        [listener onUndoChanged];
    }
}

#pragma mark print methods

+ (void)printDoc:(FSPDFDoc *)doc animated:(BOOL)animated jobName:(nullable NSString *)jobName delegate:(nullable id<UIPrintInteractionControllerDelegate>)delegate completionHandler:(nullable UIPrintInteractionCompletionHandler)completion {
    [Utility printDoc:doc animated:animated jobName:jobName delegate:delegate completionHandler:completion];
}

+ (void)printDoc:(FSPDFDoc *)doc fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated jobName:(nullable NSString *)jobName delegate:(nullable id<UIPrintInteractionControllerDelegate>)delegate completionHandler:(nullable UIPrintInteractionCompletionHandler)completion {
    [Utility printDoc:doc fromRect:rect inView:view animated:animated jobName:jobName delegate:delegate completionHandler:completion];
}

@end

@interface ExAnnotIconProviderCallback ()

@property (nonatomic, strong) NSMutableArray *iconDocs;

@end

@implementation ExAnnotIconProviderCallback

- (NSString *)getProviderID {
    return @"FX";
}

- (NSString *)getProviderVersion {
    return @"0";
}

- (BOOL)hasIcon:(FSAnnotType)annotType iconName:(NSString *)iconName {
    if (annotType == e_annotNote || annotType == e_annotFileAttachment || annotType == e_annotStamp) {
        return YES;
    }
    return NO;
}
- (BOOL)canChangeColor:(FSAnnotType)annotType iconName:(NSString *)iconName {
    if (annotType == e_annotNote || annotType == e_annotFileAttachment) {
        return YES;
    }
    return NO;
}

- (FSShadingColor *)getShadingColor:(FSAnnotType)annotType iconName:(NSString *)iconName refColor:(unsigned int)refColor shadingIndex:(int)shadingIndex;
{
    FSShadingColor *shadingColor = [[FSShadingColor alloc] init];
    [shadingColor set:refColor secondColor:refColor];
    return shadingColor;
}

- (NSNumber *)getDisplayWidth:(FSAnnotType)annotType iconName:(NSString *)iconName {
    return [NSNumber numberWithFloat:32];
}

- (NSNumber *)getDisplayHeight:(FSAnnotType)annotType iconName:(NSString *)iconName {
    return [NSNumber numberWithFloat:32];
}

- (FSPDFPage *)getIcon:(FSAnnotType)annotType iconName:(NSString *)iconName color:(unsigned int)color {
    static NSArray *arrayNames = nil;
    if (!arrayNames) {
        arrayNames = [Utility getAllIconLowercaseNames];
    }

    NSInteger iconIndex = -1;
    if (annotType == e_annotNote || annotType == e_annotFileAttachment || annotType == e_annotStamp) {
        iconName = [iconName lowercaseString];
        if ([arrayNames containsObject:iconName]) {
            iconIndex = [arrayNames indexOfObject:iconName];
        }
    }

    if (iconIndex >= 0 && iconIndex < arrayNames.count) {
        if (!self.iconDocs) {
            self.iconDocs = [NSMutableArray arrayWithCapacity:arrayNames.count];
            for (int i = 0; i < arrayNames.count; i++) {
                [self.iconDocs addObject:[NSNull null]];
            }
        }

        FSPDFDoc *iconDoc = self.iconDocs[iconIndex];
        if ([iconDoc isEqual:[NSNull null]]) {
            NSString *path = [[NSBundle mainBundle] pathForResource:iconName ofType:@"pdf"];
            if (path) {
                iconDoc = [[FSPDFDoc alloc] initWithFilePath:path];
                FSErrorCode err = [iconDoc load:nil];
                if (e_errSuccess == err) {
                    self.iconDocs[iconIndex] = iconDoc;
                }
            }
        }
        return [iconDoc isEqual:[NSNull null]] ? nil : [iconDoc getPage:0];
    }

    return nil;
}

@end

int _formCurrentPageIndex = 0;

@implementation ExActionHandler

- (id)initWithPDFViewControl:(FSPDFViewCtrl *)viewctrl {
    if (self = [super init]) {
        _pdfViewCtrl = viewctrl;
    }
    return self;
}

- (int)getCurrentPage:(FSPDFDoc *)pdfDoc {
    if (_pdfViewCtrl.currentDoc == pdfDoc)
        return _formCurrentPageIndex;
    else
        return 0;
}

- (void)setCurrentPage:(FSPDFDoc *)pdfDoc pageIndex:(int)pageIndex {
    if (_pdfViewCtrl.currentDoc == pdfDoc)
        _formCurrentPageIndex = pageIndex;
}

- (FSRotation)getPageRotation:(FSPDFDoc *)pdfDoc pageIndex:(int)pageIndex {
    return 0;
}

- (BOOL)setPageRotation:(FSPDFDoc *)pdfDoc pageIndex:(int)pageIndex rotation:(FSRotation)rotation {
    return NO;
}

- (int)alert:(NSString *)msg title:(NSString *)title type:(int)type icon:(int)icon {
    __block int retCode = -1;
    AlertView *alertView = [[AlertView alloc] initWithTitle:title
                                                    message:msg
                                         buttonClickHandler:^(AlertView *alertView, NSInteger buttonIndex) {

                                             if (type == 0 || type == 4) {
                                                 retCode = 1;
                                             } else if (type == 1) {
                                                 if (buttonIndex == 0) {
                                                     retCode = 1;
                                                 } else {
                                                     retCode = 2;
                                                 }
                                             } else if (type == 2) {
                                                 if (buttonIndex == 0) {
                                                     retCode = 4;
                                                 } else {
                                                     retCode = 3;
                                                 }
                                             } else if (type == 3) {
                                                 if (buttonIndex == 0) {
                                                     retCode = 4;
                                                 } else if (buttonIndex == 0) {
                                                     retCode = 3;
                                                 } else {
                                                     retCode = 2;
                                                 }
                                             } else
                                                 retCode = 0;

                                         }
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil];
    if (type == 0 || type == 4) {
        [alertView addButtonWithTitle:FSLocalizedString(@"kOK")];
    } else if (type == 1) {
        [alertView addButtonWithTitle:FSLocalizedString(@"kOK")];
        [alertView addButtonWithTitle:FSLocalizedString(@"kCancel")];
    } else if (type == 2) {
        [alertView addButtonWithTitle:FSLocalizedString(@"kYes")];
        [alertView addButtonWithTitle:FSLocalizedString(@"kNo")];
    } else if (type == 3) {
        [alertView addButtonWithTitle:FSLocalizedString(@"kYes")];
        [alertView addButtonWithTitle:FSLocalizedString(@"kNo")];
        [alertView addButtonWithTitle:FSLocalizedString(@"kCancel")];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView show];
    });

    while (retCode == -1) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }

    return retCode;
}

- (FSIdentityProperties *)getIdentityProperties {
    FSIdentityProperties *ip = [[FSIdentityProperties alloc] init];
    [ip setCorporation:@"Foxit"];
    [ip setEmail:@"Foxit"];
    [ip setLoginName:[SettingPreference getAnnotationAuthor]];
    [ip setName:[SettingPreference getAnnotationAuthor]];
    return ip;
}

@end
