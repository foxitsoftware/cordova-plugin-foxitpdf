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
#import "ReadFrame.h"
//#import "ViewController.h"
#import "MenuGroup.h"
#import "MvMenuItem.h"
#import "DXPopover.h"
#import "UIExtensionsSharedHeader.h"
#import <FoxitRDK/FSPDFObjC.h>
#import "AppDelegate.h"
#import "MoreModule.h"
#import "PageNavigationModule.h"
#import "MarkupModule.h"
#import "NoteModule.h"
#import "ShapeModule.h"
#import "FreetextModule.h"
#import "PencilModule.h"
#import "EraseModule.h"
#import "LineModule.h"
#import "StampModule.h"
#import "ReplaceModule.h"
#import "InsertModule.h"
#import "FormModule.h"

@interface ReadFrame()

@property (nonatomic, retain) NSMutableArray *fullScreenListeners;
@property (nonatomic, retain) NSMutableArray *rotateListeners;
@property (nonatomic, retain) NSMutableArray *panelListeners;
@property (nonatomic, retain) TbBaseItem *backItem;
@property (nonatomic, retain) TbBaseItem *moreAnnotItem;
@property (nonatomic, retain) UIPopoverController *moreToolbarPopoverCtr;
@property (nonatomic, retain) TbBaseItem *annotItem;
@property (nonatomic, assign) BOOL isPopoverhidden;
@property (nonatomic, copy) AnnotAuthorCallBack callBack;
@property (nonatomic, assign)int currentState;

@end

static ReadFrame* _instance = nil;

@implementation ReadFrame
{
    UIControl * maskView;
    DXPopover *popover;
}

+(instancetype)sharedInstance
{
    return _instance;
}

-(id)initWithPdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl
{
    if (self = [super init])
    {
        self.fullScreenListeners = [[[NSMutableArray alloc] init] autorelease];
        self.rotateListeners = [[[NSMutableArray alloc] init] autorelease];
        self.panelListeners = [[[NSMutableArray alloc] init] autorelease];
        self.stateChangeListeners = [NSMutableArray array];
        self.currentState = STATE_NORMAL;
        self.pdfViewCtrl = pdfViewCtrl;
        [pdfViewCtrl registerDocEventListener:self];
        [pdfViewCtrl registerLayoutChangedEventListener:self];
        
        [self buildToolbars];
        [self buildItems];
        
        _extensionsMgr = [[UIExtensionsManager alloc] initWithPDFViewControl:pdfViewCtrl];
        pdfViewCtrl.extensionsManager = _extensionsMgr;
        
        [_extensionsMgr registerToolEventListener:self];
        [_extensionsMgr registerAnnotEventListener:self];
        [_extensionsMgr registerSearchEventListener:self];
        self.isDocModified = NO;
        [pdfViewCtrl registerGestureEventListener:self]; // must after extensions manager, so guesture event will pass to extensions manager first.
        [pdfViewCtrl registerPageEventListener:self];
        [self registerStateChangeListener:self];
        [self registerRotateChangedListener:_extensionsMgr];
        
        self.panelController = [[[PanelController alloc] initWithUIExtensionsManager:_extensionsMgr] autorelease];
        self.panelController.isHidden = YES;
        
        [[[PageNavigationModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[MarkupModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[NoteModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[MoreModule alloc] initWithViewCtrl:self.pdfViewCtrl readFrame:self] autorelease];
        [[[FormModule alloc] initWithViewCtrl:self.pdfViewCtrl readFrame:self] autorelease];
        [[[ShapeModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[FreetextModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[PencilModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[EraseModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[LineModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[StampModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[ReplaceModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        [[[InsertModule alloc] initWithUIExtensionsManager:_extensionsMgr readFrame:self] autorelease];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBookmarkButtonState) name:UPDATEBOOKMARK object:nil];
    }
    _instance = self;
    return self;
}

- (void)buildToolbars
{
    CGRect screenFrame = [UIScreen mainScreen].bounds;
    if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        screenFrame = CGRectMake(0, 0, screenFrame.size.height, screenFrame.size.width);
    }
    
    maskView = [[UIControl alloc] initWithFrame:[UIScreen mainScreen].bounds];
    maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;

    self.topToolbar = [[[TbBaseBar alloc] init] autorelease];
    self.topToolbar.contentView.frame = CGRectMake(0, 0, screenFrame.size.width, 64);
    self.topToolbar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    
    self.bottomToolbar = [[[TbBaseBar alloc] init] autorelease];
    self.bottomToolbar.top = NO;
    self.bottomToolbar.contentView.frame = CGRectMake(0, screenFrame.size.height-49, screenFrame.size.width, 49);
    self.bottomToolbar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    self.bottomToolbar.intervalWidth = 100.f;
    if (DEVICE_iPHONE) {
        self.bottomToolbar.intervalWidth = 40.f;
    }
    
    self.editDoneBar = [[[TbBaseBar alloc] init] autorelease];
    self.editDoneBar.contentView.frame = CGRectMake(0, 0, 200, 64);
    self.editDoneBar.top = YES;
    self.editDoneBar.hasDivide = NO;
    
    self.editBar = [[[TbBaseBar alloc] init] autorelease];
    self.editBar.top = NO;
    self.editBar.hasDivide = NO;
    if (DEVICE_iPHONE) {
        self.editBar.interval = YES;
    }
    else
    {
        self.editBar.intervalWidth = 30;
    }
    self.editBar.contentView.frame = CGRectMake(0, screenFrame.size.height-49, screenFrame.size.width, 49);
    
    self.toolSetBar = [[[TbBaseBar alloc] init] autorelease];
    self.toolSetBar.contentView.frame = CGRectMake(0, screenFrame.size.height - 49, screenFrame.size.width,49);
    self.toolSetBar.hasDivide = NO;
    self.toolSetBar.top = NO;
    if (DEVICE_iPHONE) {
        self.toolSetBar.intervalWidth = 20;
    }
    else
    {
        self.toolSetBar.intervalWidth = 30;
    }
    
    self.more = [[[MenuView alloc] init] autorelease];
    [self.more getContentView].frame = CGRectMake([UIScreen mainScreen].bounds.size.width-300, 0, 300,[UIScreen mainScreen].bounds.size.height);
    [self.more setMenuTitle:NSLocalizedString(@"kMore", nil)];
    
    self.moreToolsBar = [[[MoreAnnotationsBar alloc] init:DEVICE_iPHONE ? CGRectMake(0, screenFrame.size.height-250, screenFrame.size.width, 250) : CGRectMake(0, 0, 300, 250)] autorelease];
    
    [self.pdfViewCtrl addSubview:self.topToolbar.contentView];
    [self.pdfViewCtrl addSubview:self.bottomToolbar.contentView];
    
    [self.pdfViewCtrl addSubview:self.editDoneBar.contentView];
    [self.pdfViewCtrl addSubview:self.editBar.contentView];
    [self.pdfViewCtrl addSubview:self.toolSetBar.contentView];
    [self.pdfViewCtrl addSubview:[self.more getContentView]];
    if (DEVICE_iPHONE) {
        [self.pdfViewCtrl addSubview:self.moreToolsBar.contentView];
    }
    self.settingBarController = [[[SettingBarController alloc] initWithPDFViewCtrl:self.pdfViewCtrl] autorelease];

    self.hiddenEditDoneBar = YES;
    self.hiddenEditBar = YES;
    self.hiddenToolSetBar = YES;
    self.hiddenMoreMenu = YES;
    self.hiddenMoreToolsBar = YES;
    self.isPopoverhidden = NO;

}

-(void)buildItems
{
    UIImage *commonBackBlack = [UIImage imageNamed:@"common_back_black"];
    self.backItem = [TbBaseItem createItemWithImage:commonBackBlack imageSelected:commonBackBlack imageDisable:commonBackBlack];
    self.backItem.enable = NO;
    self.backItem.onTapClick = ^(TbBaseItem *item){
        
        if (_extensionsMgr.currentAnnot) {
            [_extensionsMgr setCurrentAnnot:nil];
        }
        
        if (![self.pdfViewCtrl.currentDoc isModified]) {
            [self.pdfViewCtrl.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
//            [((ViewController*)[[UIApplication sharedApplication].delegate window].rootViewController).navController popViewControllerAnimated:YES];
            [self.pdfViewCtrl closeDoc:nil];
        }
        else
        {
            UIView *menu = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 100)] autorelease];
            UIButton *save = [[UIButton alloc] initWithFrame:CGRectMake(10, 15, 130, 20)];
            [save setTitle:NSLocalizedString(@"kSave", nil) forState:UIControlStateNormal];
            [save setTitleColor:[UIColor colorWithRed:23.f/255.f green:156.f/255.f blue:216.f/255.f alpha:1] forState:UIControlStateNormal];
            [save setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            save.titleLabel.font = [UIFont systemFontOfSize:15];
            [save addTarget:self action:@selector(buttonSaveClick) forControlEvents:UIControlEventTouchUpInside];
            [menu addSubview:save];
            UIButton *discard = [[UIButton alloc] initWithFrame:CGRectMake(10, 65, 130, 20)];
            [discard setTitle:NSLocalizedString(@"kDiscardChange", nil) forState:UIControlStateNormal];
            [discard setTitleColor:[UIColor colorWithRed:23.f/255.f green:156.f/255.f blue:216.f/255.f alpha:1] forState:UIControlStateNormal];
            [discard setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            discard.titleLabel.font = [UIFont systemFontOfSize:15];
            [discard addTarget:self action:@selector(buttonDiscardChangeClick) forControlEvents:UIControlEventTouchUpInside];
            [menu addSubview:discard];
            UIView *line = [[[UIView alloc] initWithFrame:CGRectMake(10, 50, 130, 1)] autorelease];
            line.backgroundColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1];
            [menu addSubview:line];
            
            CGRect frame = item.contentView.frame;
            CGPoint startPoint = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
            popover = [DXPopover popover];
            [popover showAtPoint:startPoint popoverPosition:DXPopoverPositionDown withContentView:menu inView:self.pdfViewCtrl];
            popover.didDismissHandler = ^{
                
            };
        }
    };
    [self.topToolbar addItem:self.backItem displayPosition:Position_LT];
    
    //Adding reading bookmark button.
    self.bookmarkItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"readview_bookmark.png"] imageSelected:[UIImage imageNamed:@"readview_bookmarkselect.png"] imageDisable:nil];
    self.bookmarkItem.tag = 100;
    self.bookmarkItem.onTapClick = ^(TbBaseItem *item){
        if ([_extensionsMgr currentAnnot]) {
            [_extensionsMgr setCurrentAnnot:nil];
        }
        
        int currentPage = [_pdfViewCtrl getCurrentPage];
        if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO) {
            currentPage = currentPage / 2 * 2;
        }
        FSReadingBookmark* bookmark = [self getReadingBookMarkAtPage:currentPage];
        if (!bookmark)
        {
            [self.pdfViewCtrl.currentDoc insertReadingBookmark:-1 title:[NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"kPage", nil), currentPage+1] pageIndex:currentPage];
            self.bookmarkItem.selected = YES;
        } else
        {
            [self.pdfViewCtrl.currentDoc removeReadingBookmark:bookmark];
            self.bookmarkItem.selected = NO;
        }
        [self.panelController reloadReadingBookmarkPanel];
        
    };
    [self.topToolbar addItem:self.bookmarkItem displayPosition:Position_RB];
    
    //search button.
    TbBaseItem *searchItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"search.png"]
                                               imageSelected:[UIImage imageNamed:@"search.png"]
                                                imageDisable:[UIImage imageNamed:@"search.png"]];
    searchItem.tag = 2;
    searchItem.onTapClick = ^(TbBaseItem *item)
    {
        if (self.extensionsMgr.currentAnnot) {
            [self.extensionsMgr setCurrentAnnot:nil];
        }

        [self.extensionsMgr showSearchBar:YES];
    };
    [self.topToolbar addItem:searchItem displayPosition:Position_RB];
    
    UIImage *commonReadMore = [UIImage imageNamed:@"common_read_more"];
    UIImage *annoToolitembg = [UIImage imageNamed:@"annotation_toolitembg"];
    self.moreAnnotItem = [TbBaseItem createItemWithImage:commonReadMore imageSelected:commonReadMore imageDisable:commonReadMore background:annoToolitembg];
    self.moreAnnotItem.tag = 1;
    self.moreAnnotItem.onTapClick = ^(TbBaseItem*item){
        if (_extensionsMgr.currentAnnot) {
            [_extensionsMgr setCurrentAnnot:nil];
        }
        self.hiddenMoreToolsBar = NO;
    };
    [self.editBar addItem:self.moreAnnotItem displayPosition:DEVICE_iPHONE?Position_RB:Position_CENTER];
    
    UIImage *commonBackBlue = [UIImage imageNamed:@"common_back_blue"];
    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:commonBackBlue imageSelected:commonBackBlue imageDisable:commonBackBlue background:nil];
    doneItem.tag = 0;
    [self.editDoneBar addItem:doneItem displayPosition:Position_LT];
    doneItem.onTapClick = ^(TbBaseItem*item){
        [_extensionsMgr setCurrentToolHandler:nil];
        if (_extensionsMgr.currentAnnot) {
            [_extensionsMgr setCurrentAnnot:nil];
        }
        [self changeState:STATE_NORMAL];
        
    };

    UIImage *readPanel = [UIImage imageNamed:@"read_panel"];
    TbBaseItem *panelItem = [TbBaseItem createItemWithImageAndTitle:NSLocalizedString(@"kReadList", nil) imageNormal:readPanel imageSelected:readPanel imageDisable:readPanel background:nil imageTextRelation:RELATION_BOTTOM];
    panelItem.textColor = [UIColor blackColor];
    panelItem.textFont = [UIFont systemFontOfSize:9.f];
    panelItem.onTapClick = ^(TbBaseItem *item){
        if (_extensionsMgr.currentAnnot) {
            [_extensionsMgr setCurrentAnnot:nil];
        }
        self.panelController.isHidden = NO;
    };
    [self.bottomToolbar addItem:panelItem displayPosition:Position_CENTER];
    
    UIImage *readModeImg = [UIImage imageNamed:@"read_mode"];
    TbBaseItem *readmodeItem = [TbBaseItem createItemWithImageAndTitle:NSLocalizedString(@"kReadView", nil) imageNormal:readModeImg imageSelected:readModeImg imageDisable:readModeImg background:nil imageTextRelation:RELATION_BOTTOM];
    readmodeItem.textColor = [UIColor blackColor];
    readmodeItem.textFont = [UIFont systemFontOfSize:9.f];
    readmodeItem.onTapClick = ^(TbBaseItem *item){
        if (_extensionsMgr.currentAnnot) {
            [_extensionsMgr setCurrentAnnot:nil];
        }
        self.hiddenSettingBar = NO;
    };
    [self.bottomToolbar addItem:readmodeItem displayPosition:Position_CENTER];
    
    UIImage *readAnnotImg = [UIImage imageNamed:@"read_annot"];
    self.annotItem = [TbBaseItem createItemWithImageAndTitle:NSLocalizedString(@"kReadComment", nil) imageNormal:readAnnotImg imageSelected:readAnnotImg imageDisable:readAnnotImg background:nil imageTextRelation:RELATION_BOTTOM];
    self.annotItem.textColor = [UIColor blackColor];
    self.annotItem.textFont = [UIFont systemFontOfSize:9.f];
    self.annotItem.onTapClick = ^(TbBaseItem *item){
        if (_extensionsMgr.currentAnnot) {
            [_extensionsMgr setCurrentAnnot:nil];
        }
        [self changeState:STATE_EDIT];
    };
    [self.bottomToolbar addItem:self.annotItem displayPosition:Position_CENTER];

    if (DEVICE_iPHONE) {
        panelItem.contentView.center = CGPointMake(SCREENWIDTH/4, 25);
        readmodeItem.contentView.center = CGPointMake(SCREENWIDTH/2, 25);
        self.annotItem.contentView.center = CGPointMake(SCREENWIDTH*3/4, 25);
    }
    else
    {
        panelItem.contentView.center = CGPointMake(SCREENWIDTH/8*3, 25);
        readmodeItem.contentView.center = CGPointMake(SCREENWIDTH/2, 25);
        self.annotItem.contentView.center = CGPointMake(SCREENWIDTH/8*5, 25);
    }
}

-(FSReadingBookmark*)getReadingBookMarkAtPage:(int)page
{
    int count = [self.pdfViewCtrl.currentDoc getReadingBookmarkCount];
    for(int i = 0; i < count; i ++) {
        FSReadingBookmark* bookmark = [self.pdfViewCtrl.currentDoc getReadingBookmark:i];
        if([bookmark getPageIndex] == page)
            return bookmark;
    }
    return nil;
}

-(void)buttonSaveClick
{
    [popover dismiss];
    popover = nil;
    DEMO_APPDELEGATE.isFileEdited = YES;
    _isDocModified = NO;
    
//    [((ViewController*)[[UIApplication sharedApplication].delegate window].rootViewController).navController popViewControllerAnimated:YES];
    [self.pdfViewCtrl.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
   
    NSString* tmpPath = nil;
    NSString* filePath = DEMO_APPDELEGATE.filePath;
    if(filePath)
    {
        NSString* tempDir = NSTemporaryDirectory();
        tmpPath = [tempDir stringByAppendingPathComponent:[filePath lastPathComponent]];
        [self.pdfViewCtrl saveDoc:tmpPath flag:e_saveFlagIncremental];
    }
    
    [self.pdfViewCtrl closeDoc:^()
     {
         if(filePath)
         {
             NSFileManager * fileManager = [NSFileManager defaultManager];
             NSError* error = nil;
             if([fileManager fileExistsAtPath:filePath])
             {
                 [fileManager removeItemAtPath:filePath error:nil];
             }
             BOOL success = [fileManager copyItemAtPath:tmpPath toPath:filePath error:&error];
             success = success;
             [fileManager removeItemAtPath:tmpPath error:nil];
         }
     }];
}

-(void)buttonDiscardChangeClick
{
    [popover dismiss];
    popover = nil;
    DEMO_APPDELEGATE.isFileEdited = NO;
    _isDocModified = NO;
//    [((ViewController*)[[UIApplication sharedApplication].delegate window].rootViewController).navController popViewControllerAnimated:YES];
    [self.pdfViewCtrl closeDoc:nil];
    [self.pdfViewCtrl.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setHiddenToolSetBar:(BOOL)hiddenToolSetBar
{
    _hiddenToolSetBar = hiddenToolSetBar;
    if (hiddenToolSetBar)
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.toolSetBar.contentView.alpha = 0.f;
        }];
        self.toolSetBar.hidden = hiddenToolSetBar;
        [self.toolSetBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(@49);
            make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
            make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
            make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
        }];
    }
    else
    {
        self.toolSetBar.hidden = hiddenToolSetBar;
        [UIView animateWithDuration:0.2 animations:^{
            self.toolSetBar.contentView.alpha = 1.f;
            [self.toolSetBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@49);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
            }];
        }];
    }
}

- (void)setHiddenEditBar:(BOOL)hiddenEditBar
{
    if (_hiddenEditBar == hiddenEditBar) {
        return;
    }
    _hiddenEditBar = hiddenEditBar;
    if (hiddenEditBar)
    {
        CGRect newFrame = self.editBar.contentView.frame;
        newFrame.origin.y = [UIScreen mainScreen].bounds.size.height;
        [UIView animateWithDuration:0.3 animations:^{
            self.editBar.contentView.frame = newFrame;
            [self.editBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@49);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
            }];
        }];
    }
    else
    {
        CGRect newFrame = self.editBar.contentView.frame;
        newFrame.origin.y = [UIScreen mainScreen].bounds.size.height - self.editBar.contentView.frame.size.height;
        [UIView animateWithDuration:0.3 animations:^{
            self.editBar.contentView.frame = newFrame;
            [self.editBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@49);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
            }];
        }];
    }
}

- (void)setHiddenEditDoneBar:(BOOL)hiddenEditDoneBar
{
    if (_hiddenEditDoneBar == hiddenEditDoneBar) {
        return;
    }
    _hiddenEditDoneBar = hiddenEditDoneBar;
    if (hiddenEditDoneBar)
    {
        CGRect newFrame = self.editDoneBar.contentView.frame;
        newFrame.origin.y = -self.editDoneBar.contentView.frame.size.height;
        [UIView animateWithDuration:0.3 animations:^{
            
            self.editDoneBar.contentView.frame = newFrame;
            [self.editDoneBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@64);
                make.width.mas_equalTo(@200);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_top).offset(0);
            }];
            
        } completion:^(BOOL finished) {
            
        }];
    }
    else
    {
        CGRect newFrame = self.editDoneBar.contentView.frame;
        newFrame.origin.y = 0;
        [UIView animateWithDuration:0.3 animations:^{
            self.editDoneBar.contentView.frame = newFrame;
            [self.editDoneBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@64);
                make.width.mas_equalTo(@200);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
            }];
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)setHiddenBottomToolbar:(BOOL)hiddenBottomToolbar
{
    if (_hiddenBottomToolbar == hiddenBottomToolbar) {
        return;
    }
    _hiddenBottomToolbar = hiddenBottomToolbar;
    if (hiddenBottomToolbar)
    {
        CGRect newFrame = self.bottomToolbar.contentView.frame;
        newFrame.origin.y = [UIScreen mainScreen].bounds.size.height;
        [UIView animateWithDuration:0.3 animations:^{
            self.bottomToolbar.contentView.frame = newFrame;
            [self.bottomToolbar.contentView  mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@49);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
            }];
        }];
        
    }
    else
    {
        CGRect newFrame = self.bottomToolbar.contentView.frame;
        newFrame.origin.y = [UIScreen mainScreen].bounds.size.height - self.bottomToolbar.contentView.frame.size.height;
        [UIView animateWithDuration:0.3 animations:^{
            self.bottomToolbar.contentView.frame = newFrame;
            [self.bottomToolbar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@49);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                
            }];
        }];
        
    }
}

-(void)setHiddenTopToolbar:(BOOL)hiddenTopToolbar
{
    if (_hiddenTopToolbar == hiddenTopToolbar) {
        return;
    }
    _hiddenTopToolbar = hiddenTopToolbar;
    if (hiddenTopToolbar)
    {
        CGRect newFrame = self.topToolbar.contentView.frame;
        newFrame.origin.y = -self.topToolbar.contentView.frame.size.height;
        [UIView animateWithDuration:0.3 animations:^{
            self.topToolbar.contentView.frame = newFrame;
            [self.topToolbar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@64);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_top).offset(0);
            }];
        } completion:^(BOOL finished) {
        }];
    }
    else
    {
        CGRect newFrame = self.topToolbar.contentView.frame;
        newFrame.origin.y = 0;
        [UIView animateWithDuration:0.3 animations:^{
            self.topToolbar.contentView.frame = newFrame;
            [self.topToolbar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(@64);
                make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
            }];
        } completion:^(BOOL finished) {
        }];
    }
    
}

-(void)setHiddenMoreToolsBar:(BOOL)hiddenMoreToolsBar
{
    if (_hiddenMoreToolsBar == hiddenMoreToolsBar) {
        return;
    }
    _hiddenMoreToolsBar = hiddenMoreToolsBar;
    if (DEVICE_iPHONE) {
        if (hiddenMoreToolsBar)
        {
            [UIView animateWithDuration:0.4 animations:^{
                maskView.alpha = 0.1f;
            } completion:^(BOOL finished) {
                
                [maskView removeFromSuperview];
            }];
            
            CGRect newFrame = self.moreToolsBar.contentView.frame;
            if (DEVICE_iPHONE)
            {
                newFrame.origin.y = [UIScreen mainScreen].bounds.size.height;
            }
            else
            {
                newFrame.origin.x = [UIScreen mainScreen].bounds.size.width;
            }
            
            [UIView animateWithDuration:0.4 animations:^{
                self.moreToolsBar.contentView.frame = newFrame;
                [self.moreToolsBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                    make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                    make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                    make.height.mas_equalTo(self.moreToolsBar.contentView.frame.size.height);
                    
                }];
            }];
        }
        else
        {
            maskView.frame = [UIScreen mainScreen].bounds;
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
            CGRect newFrame = self.moreToolsBar.contentView.frame;
            if (DEVICE_iPHONE)
            {
                newFrame.origin.y = [UIScreen mainScreen].bounds.size.height - newFrame.size.height;
            }
            else
            {
                newFrame.origin.x = [UIScreen mainScreen].bounds.size.width - newFrame.size.width;
            }
            [UIView animateWithDuration:0.4 animations:^{
                self.moreToolsBar.contentView.frame = newFrame;
                [self.moreToolsBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                    make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                    make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                    make.height.mas_equalTo(self.moreToolsBar.contentView.frame.size.height);
                }];
            }];
        }
    }
    else
    {
        if (!hiddenMoreToolsBar) {
            if ([self getState] == STATE_ANNOTTOOL) {
                CGRect rect = CGRectMake(SCREENWIDTH/2 + 85, SCREENHEIGHT - 49, 40, 40);
                [self.moreToolbarPopoverCtr presentPopoverFromRect:rect inView:self.pdfViewCtrl permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
            else
            {
                [self.moreToolbarPopoverCtr presentPopoverFromRect:self.moreAnnotItem.contentView.bounds inView:self.moreAnnotItem.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
            
        }
        else
        {
            if (self.moreToolbarPopoverCtr.isPopoverVisible) {
                [self.moreToolbarPopoverCtr dismissPopoverAnimated:YES];
            }
        }
    }
    
}

-(UIPopoverController *)moreToolbarPopoverCtr
{
    if (!_moreToolbarPopoverCtr) {
        UIViewController *viewCtr = [[[UIViewController alloc] init] autorelease];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 250)];
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
        [self.moreToolbarPopoverCtr setPopoverContentSize:CGSizeMake(300, 250)];
    }
    return _moreToolbarPopoverCtr;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self setHiddenMoreToolsBar:YES];
}

-(void)setHiddenMoreMenu:(BOOL)hiddenMoreMenu
{
    if (_hiddenMoreMenu == hiddenMoreMenu) {
        return;
    }
    _hiddenMoreMenu = hiddenMoreMenu;
    if (hiddenMoreMenu)
    {
        [UIView animateWithDuration:0.4 animations:^{
            maskView.alpha = 0.1f;
        } completion:^(BOOL finished) {
            
            [maskView removeFromSuperview];
        }];
        
        
        CGRect newFrame = [self.more getContentView].frame;
        
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            newFrame.origin.x = [UIScreen mainScreen].bounds.size.height;
        }
        else
        {
            newFrame.origin.x = [UIScreen mainScreen].bounds.size.width;
        }
        
        [UIView animateWithDuration:0.4 animations:^{
            
            [self.more getContentView].frame = newFrame;
            [[self.more getContentView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                if (DEVICE_iPHONE) {
                    make.left.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                    make.width.mas_equalTo(newFrame.origin.x);
                }
                else
                {
                    make.left.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                    make.width.mas_equalTo(300);
                }
            }];
            
        }];
    }
    else
    {
        maskView.frame = [UIScreen mainScreen].bounds;
        maskView.backgroundColor = [UIColor blackColor];
        maskView.alpha = 0.3f;
        maskView.tag = 201;
        [maskView addTarget:self action:@selector(dissmiss:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.pdfViewCtrl insertSubview:maskView belowSubview:[self.more getContentView]];
        [maskView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(maskView.superview.mas_left).offset(0);
            make.right.equalTo(maskView.superview.mas_right).offset(0);
            make.top.equalTo(maskView.superview.mas_top).offset(0);
            make.bottom.equalTo(maskView.superview.mas_bottom).offset(0);
        }];
        
        CGRect newFrame = [self.more getContentView].frame;
        
        if (DEVICE_iPHONE)
        {
            newFrame.origin.x = 0;
        }
        else
        {
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                newFrame.origin.x = [UIScreen mainScreen].bounds.size.height-[self.more getContentView].frame.size.width;
            }
            else
            {
               newFrame.origin.x = [UIScreen mainScreen].bounds.size.width-[self.more getContentView].frame.size.width;
            }
            
        }
        
        [UIView animateWithDuration:0.4 animations:^{
            [self.more getContentView].frame = newFrame;
            [[self.more getContentView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.pdfViewCtrl.mas_top).offset(0);
                make.bottom.equalTo(self.pdfViewCtrl.mas_bottom).offset(0);
                if (DEVICE_iPHONE) {
                    make.left.equalTo(self.pdfViewCtrl.mas_left).offset(0);
                    make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                }
                else
                {
                    make.width.mas_equalTo(300);
                    make.right.equalTo(self.pdfViewCtrl.mas_right).offset(0);
                }
            }];
        }];
    }
}

-(BOOL)hiddenSettingBar
{
    return self.settingBarController.hiddenSettingBar;
}

-(void)setHiddenSettingBar:(BOOL)hiddenSettingBar
{
    self.settingBarController.hiddenSettingBar = hiddenSettingBar;
}

-(BOOL)hiddenPanel
{
    return self.panelController.isHidden;
}

-(void)setHiddenPanel:(BOOL)hiddenPanel
{
    self.panelController.isHidden = hiddenPanel;
}

-(void)dissmiss:(id)sender
{
    UIControl *control = (UIControl*)sender;
    if (control.tag == 200)
    {
        self.hiddenMoreToolsBar = YES;
    }
    else if (control.tag == 201)
    {
        self.hiddenMoreMenu = YES;
    }
}

#pragma mark - IStateChangeListener

- (void)onStateChanged:(int)state
{
    self.hiddenTopToolbar = YES;
    self.hiddenBottomToolbar = YES;
    self.hiddenEditBar = YES;
    self.hiddenEditDoneBar = YES;
    self.hiddenToolSetBar = YES;
    self.hiddenEditDoneBar = YES;
    self.hiddenMoreMenu = YES;
    self.hiddenMoreToolsBar = YES;
    self.hiddenSettingBar = YES;
    switch (state)
    {
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
}

-(void)onLayoutModeChanged:(PDF_LAYOUT_MODE)oldLayoutMode newLayoutMode:(PDF_LAYOUT_MODE)newLayoutMode
{
    if(newLayoutMode == PDF_LAYOUT_MODE_MULTIPLE)
        [self changeState:STATE_THUMBNAIL];
    else
        [self changeState:STATE_NORMAL];
    
    [self.settingBarController onLayoutModeChanged:oldLayoutMode newLayoutMode:newLayoutMode];
    [self updateBookmarkButtonState];
}

#pragma mark - handle fullScreen event

-(void)setIsFullScreen:(BOOL)isFullScreen
{
    if (_isFullScreen == isFullScreen) {
        return;
    }
    _isFullScreen = isFullScreen;
    if ([self getState] == STATE_NORMAL) {
        if (_isFullScreen) {
            self.hiddenTopToolbar = YES;
            self.hiddenBottomToolbar = YES;
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
        }
        else
        {
            self.hiddenTopToolbar = NO;
            self.hiddenBottomToolbar = NO;
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
        }
    }
    for (id<IFullScreenListener> listener in self.fullScreenListeners) {
        if ([listener respondsToSelector:@selector(onFullScreen:)]) {
            [listener onFullScreen:_isFullScreen];
        }
    }
}

-(void)registerFullScreenListener:(id<IFullScreenListener>)listener
{
    if (self.fullScreenListeners) {
        [self.fullScreenListeners addObject:listener];
    }
}

-(void)unregisterFullScreenListener:(id<IFullScreenListener>)listener
{
    if ([self.fullScreenListeners containsObject:listener]) {
        [self.fullScreenListeners removeObject:listener];
    }
}

# pragma mark - IRotationEventListener

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.rotateListeners.count > 0) {
        for (id<IRotationEventListener> listener in self.rotateListeners) {
            if ([listener respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)]) {
                [listener willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
            }
        }
    }
    if (!DEVICE_iPHONE && [self.moreToolbarPopoverCtr isPopoverVisible]) {
        [self.moreToolbarPopoverCtr dismissPopoverAnimated:NO];
        self.isPopoverhidden = YES;
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (!DEVICE_iPHONE && self.isPopoverhidden) {
        self.isPopoverhidden = NO;
        if ([self getState] == STATE_ANNOTTOOL) {
            CGRect rect = CGRectMake(SCREENWIDTH/2 + 85, SCREENHEIGHT - 49, 40, 40);
            [self.moreToolbarPopoverCtr presentPopoverFromRect:rect inView:self.pdfViewCtrl permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        else
        {
            [self.moreToolbarPopoverCtr presentPopoverFromRect:self.moreAnnotItem.contentView.bounds inView:self.moreAnnotItem.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
	
    if (self.rotateListeners.count > 0) {
        for (id<IRotationEventListener> listener in self.rotateListeners) {
            if ([listener respondsToSelector:@selector(didRotateFromInterfaceOrientation:)]) {
                [listener didRotateFromInterfaceOrientation:fromInterfaceOrientation];
            }
        }
    }
}

-(void)registerRotateChangedListener:(id<IRotationEventListener>)listener
{
    if (self.rotateListeners) {
        [self.rotateListeners addObject:listener];
    }
}

-(void)unregisterRotateChangedListener:(id<IRotationEventListener>)listener
{
    if ([self.rotateListeners containsObject:listener]) {
        [self.rotateListeners removeObject:listener];
    }
}

-(void)registerStateChangeListener:(id<IStateChangeListener>)listener
{
    if (self.stateChangeListeners) {
        [self.stateChangeListeners addObject:listener];
    }
}

-(void)unregisterStateChangeListener:(id<IStateChangeListener>)listener
{
    if ([self.stateChangeListeners containsObject:listener]) {
        [self.stateChangeListeners removeObject:listener];
    }
}


-(void)changeState:(int)state
{
    if (state == STATE_NORMAL) {
        [_extensionsMgr setCurrentToolHandler:nil];
        [_extensionsMgr setCurrentAnnot:nil];
    }
    self.currentState = state;
    if (self.stateChangeListeners) {
        for (id<IStateChangeListener> listener in self.stateChangeListeners) {
            if ([listener respondsToSelector:@selector(onStateChanged:)]) {
                [listener onStateChanged:state];
            }
        }
    }
    
}

-(int)getState
{
    return self.currentState;
}

-(void)updateBookmarkButtonState
{
    int currentPage = [self.pdfViewCtrl getCurrentPage];
    if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO) {
        currentPage = currentPage / 2 * 2;
    }
    FSReadingBookmark* bookmark = [self getReadingBookMarkAtPage:currentPage];
    self.bookmarkItem.selected = bookmark ? YES : NO;
}

# pragma mark - IDocEventListener

- (void)onDocWillOpen
{
    
}

- (void)onDocOpened:(FSPDFDoc* )document error:(int)error
{
    self.backItem.enable = YES;
    if (document) {
        unsigned long allPermission = [document getUserPermissions];
        BOOL canAddAnnot = (allPermission & e_permAnnotForm);
        self.annotItem.enable = canAddAnnot;
    }

    [self.topToolbar removeCenterItems];
    [self updateBookmarkButtonState];
    
}

- (void)onDocWillClose:(FSPDFDoc* )document
{
    
}

- (void)onDocClosed:(FSPDFDoc* )document error:(int)error
{
    self.annotItem.enable = YES;
}

-(void)onDocWillSave:(FSPDFDoc *)document
{
    
}

#pragma mark - IGestureEventListener

- (BOOL)onTap:(UITapGestureRecognizer *)recognizer
{
    if(_currentState == STATE_PAGENAVIGATE)
        return NO;
    FSPDFViewCtrl* pdfView = self.pdfViewCtrl;
    UIView* pageView = [pdfView getPageView:[pdfView getCurrentPage]];
    CGPoint point = [recognizer locationInView:pageView];
    CGFloat width = pageView.bounds.size.width;
    if (width * 0.2 < point.x && point.x < width * 0.8) {
        self.isFullScreen = !self.isFullScreen;
        return YES;
    }else if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO && width * 1.2 < point.x && point.x < width * 1.8) {
        self.isFullScreen = !self.isFullScreen;
        return YES;
    }else{
        return NO;
    }
}

#pragma mark - IToolEventListener

- (void)onToolChanged:(NSString*)lastToolName CurrentToolName:(NSString*)toolName
{
    if(toolName == nil)
    {
        //Dismiss annotation type.
        FSPDFViewCtrl* pdfViewCtrl = self.pdfViewCtrl;
        for (UIView *view in pdfViewCtrl.subviews) {
            if (view.tag == 2113) {
                [view removeFromSuperview];
            }
        }
    }
}

#pragma mark - IAnnotEventListener
- (void)onAnnotAdded:(FSPDFPage* )page annot:(FSAnnot*)annot
{
    self.isDocModified = YES;
    if([self getState] != STATE_ANNOTTOOL)
        return;
    if (!self.continueAddAnnot && ![[[_extensionsMgr getCurrentToolHandler] getName] isEqualToString:Tool_Pencil]) {
        [_extensionsMgr setCurrentToolHandler:nil];
        [self changeState:STATE_EDIT];
    }
}
- (void)onAnnotDeleted:(FSPDFPage* )page annot:(FSAnnot*)annot
{
    self.isDocModified = YES;
}
- (void)onAnnotModified:(FSPDFPage* )page annot:(FSAnnot*)annot
{
    self.isDocModified = YES;
}
- (void)onCurrentAnnotChanged:(FSAnnot*)lastAnnot currentAnnot:(FSAnnot*)currentAnnot
{

}

#pragma mark - ISearchEventListener
- (void)onSearchStarted
{
    [self changeState:STATE_SEARCH];
}

- (void)onSearchCanceled
{
    [self changeState:STATE_NORMAL];
}

#pragma mark - IPageEventListener
- (void)onPageVisible:(int)index
{
    
    
}
- (void)onpageInvisible:(int)index
{
    
    
}
- (void)onPageChanged:(int)oldIndex currentIndex:(int)currentIndex;
{
    [self updateBookmarkButtonState];
}


- (void)dealloc
{
    _instance = nil;
    
    [_panelController release];
    [_more release];
    [_topToolbar release];
    [_bottomToolbar release];
    [_settingBarController release];
    [_editBar release];
    [_editDoneBar release];
    [_moreToolsBar release];
    [_toolSetBar release];
    [_bookmarkItem release];
    [_extensionsMgr release];
    [_pdfViewCtrl release];
    [_naviCon release];
    [_stateChangeListeners release];
    [_rotateListeners release];
    [_panelListeners release];
    [_backItem release];
    [_moreAnnotItem release];
    [_moreToolbarPopoverCtr release];
    [_annotItem release];
    [_callBack release];
    
    [super dealloc];
}

@end
