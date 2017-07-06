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

#import "FSPDFReader.h"
#import "MenuGroup.h"
#import "MvMenuItem.h"
#import "DXPopover.h"
#import "UIExtensionsSharedHeader.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFObjC.h>
#import "DocumentModule.h"
#import "PasswordModule.h"

@interface FSPDFReader()

@property (nonatomic, strong) NSArray* modules;
@property (nonatomic, strong) NSMutableArray *fullScreenListeners;
@property (nonatomic, strong) NSMutableArray *rotateListeners;
@property (nonatomic, strong) NSMutableArray *panelListeners;
@property (nonatomic, strong) TbBaseItem *backItem;
@property (nonatomic, strong) TbBaseItem *moreAnnotItem;
@property (nonatomic, strong) UIPopoverController *moreToolbarPopoverCtr;
@property (nonatomic, strong) TbBaseItem *annotItem;
@property (nonatomic, assign) BOOL isPopoverhidden;
@property (nonatomic, copy) AnnotAuthorCallBack callBack;
@property (nonatomic, assign)int currentState;
@property (nonatomic, strong) DXPopover *popover;

@property (nonatomic, strong) TbBaseBar *topToolbarSaved;
@property (nonatomic, strong) TbBaseBar *bottomToolbarSaved;

@end

static FSPDFReader* _instance = nil;

@implementation FSPDFReader
{
    UIControl * maskView;
}

+(instancetype)sharedInstance
{
    return _instance;
}

-(id)initWithPdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl extensions:(UIExtensionsManager*) extensions 
{
    if (self = [super init])
    {
        self.fullScreenListeners = [[NSMutableArray alloc] init];
        self.rotateListeners = [[NSMutableArray alloc] init];
        self.panelListeners = [[NSMutableArray alloc] init];
        self.stateChangeListeners = [NSMutableArray array];
        self.currentState = STATE_NORMAL;
        _pdfViewCtrl = pdfViewCtrl;
        _extensionsMgr = extensions;
        [pdfViewCtrl registerDocEventListener:self];
        [pdfViewCtrl registerLayoutChangedEventListener:self];
        
        [self buildToolbars];
        [self buildItems];
        
        [_extensionsMgr registerToolEventListener:self];
        [_extensionsMgr registerAnnotEventListener:self];
        [_extensionsMgr registerSearchEventListener:self];
        self.isDocModified = NO;
        [pdfViewCtrl registerGestureEventListener:self]; // must after extensions manager, so guesture event will pass to extensions manager first.
        [pdfViewCtrl registerPageEventListener:self];
        [self registerStateChangeListener:self];
        [self registerRotateChangedListener:_extensionsMgr];
        
        self.panelController = [[PanelController alloc] initWithUIExtensionsManager:_extensionsMgr];
        self.panelController.isHidden = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBookmarkButtonState) name:UPDATEBOOKMARK object:nil];
        
        self.rootViewController = [[UINavigationController alloc] init];
        self.rootViewController.navigationBarHidden = YES;
        self.rootViewController.view.frame = [[UIScreen mainScreen] bounds];

    }
    _instance = self;
    self.folderSizeDictionary = [[NSMutableDictionary alloc] init];
    return self;
}

- (UIViewController*)filelistViewController
{
    if(!_filelistViewController)
    {
        _filelistViewController = [[UIViewController alloc] init];
        [_filelistViewController.view addSubview:[_extensionsMgr.documentModule getTopToolbar]];
        [_filelistViewController.view addSubview:[_extensionsMgr.documentModule getContentView]];
    }
    return _filelistViewController;
}

- (BOOL)openPDFAtPath:(NSString*)path withPassword:(NSString*)password
{
    FSPDFDoc* pdfDoc = [FSPDFDoc createFromFilePath:path];
    if (nil == pdfDoc) {
        return NO;
    }
    self.filePath = nil;
    self.password = nil;
    
    __weak typeof(self) weakSelf = self;
    [self.extensionsMgr.passwordModule tryLoadPDFDocument:pdfDoc guessPassword:password success:^(NSString *password) {
        weakSelf.filePath = path;
        weakSelf.password = password;
        FSPDFViewCtrl* pdfViewCtrl = weakSelf.pdfViewCtrl;
        [pdfViewCtrl setDoc:pdfDoc];
        
        UINavigationController* rootNav = self.rootViewController;
        if (rootNav.topViewController.view != pdfViewCtrl) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIViewController* pdfViewController = [[UIViewController alloc] init];
                pdfViewController.view = pdfViewCtrl;
                pdfViewController.automaticallyAdjustsScrollViewInsets = NO;
                [rootNav pushViewController:pdfViewController animated:YES];
            });
        }
    } error:^(NSString* description) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"kFailOpenFile", @"FoxitLocalizable", nil), [path lastPathComponent]]
                                                        message:description
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedStringFromTable(@"kOK", @"FoxitLocalizable", nil) otherButtonTitles:nil, nil];
        [alert show];
    } abort:^{
        [weakSelf.pdfViewCtrl closeDoc:nil];
    }];
    
    return YES;
}

- (void)buildToolbars
{
    CGRect screenFrame = [UIScreen mainScreen].bounds;
    if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        screenFrame = CGRectMake(0, 0, screenFrame.size.height, screenFrame.size.width);
    }
    
    maskView = [[UIControl alloc] initWithFrame:[UIScreen mainScreen].bounds];
    maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;

    self.topToolbar = [[TbBaseBar alloc] init];
    self.topToolbar.contentView.frame = CGRectMake(0, 0, screenFrame.size.width, 64);
    self.topToolbar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    
    self.bottomToolbar = [[TbBaseBar alloc] init];
    self.bottomToolbar.top = NO;
    self.bottomToolbar.contentView.frame = CGRectMake(0, screenFrame.size.height-49, screenFrame.size.width, 49);
    self.bottomToolbar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    self.bottomToolbar.intervalWidth = 100.f;
    if (DEVICE_iPHONE) {
        self.bottomToolbar.intervalWidth = 40.f;
    }
    
    self.editDoneBar = [[TbBaseBar alloc] init];
    self.editDoneBar.contentView.frame = CGRectMake(0, 0, 200, 64);
    self.editDoneBar.top = YES;
    self.editDoneBar.hasDivide = NO;
    
    self.editBar = [[TbBaseBar alloc] init];
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
    
    self.toolSetBar = [[TbBaseBar alloc] init];
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
    
    self.more = [[MenuView alloc] init];
    [self.more getContentView].frame = CGRectMake([UIScreen mainScreen].bounds.size.width-300, 0, 300,[UIScreen mainScreen].bounds.size.height);
    [self.more setMenuTitle:NSLocalizedStringFromTable(@"kMore", @"FoxitLocalizable", nil)];
    
    self.moreToolsBar = [[MoreAnnotationsBar alloc] init:DEVICE_iPHONE ? CGRectMake(0, screenFrame.size.height-250, screenFrame.size.width, 250) : CGRectMake(0, 0, 300, 250)];
    
    [self.pdfViewCtrl addSubview:self.topToolbar.contentView];
    [self.pdfViewCtrl addSubview:self.bottomToolbar.contentView];    
    [self.pdfViewCtrl addSubview:self.editDoneBar.contentView];
    [self.pdfViewCtrl addSubview:self.editBar.contentView];
    [self.pdfViewCtrl addSubview:self.toolSetBar.contentView];
    [self.pdfViewCtrl addSubview:[self.more getContentView]];
    if (DEVICE_iPHONE) {
        [self.pdfViewCtrl addSubview:self.moreToolsBar.contentView];
    }
    self.settingBarController = [[SettingBarController alloc] initWithPDFViewCtrl:self.pdfViewCtrl pdfReader:self];

    self.hiddenEditDoneBar = YES;
    self.hiddenEditBar = YES;
    self.hiddenToolSetBar = YES;
    self.hiddenMoreMenu = YES;
    self.hiddenMoreToolsBar = YES;
    self.isPopoverhidden = NO;

}

-(void)buildItems
{
    __weak typeof(self) weakSelf = self;
    
    UIImage *commonBackBlack = [UIImage imageNamed:@"common_back_black"];
    self.backItem = [TbBaseItem createItemWithImage:commonBackBlack imageSelected:commonBackBlack imageDisable:commonBackBlack];
    self.backItem.enable = NO;
    self.backItem.onTapClick = ^(TbBaseItem *item){
        if (weakSelf.extensionsMgr.currentAnnot) {
            [weakSelf.extensionsMgr setCurrentAnnot:nil];
        }
        
        [weakSelf.settingBarController.settingBar setItemState:NO value:0 itemType:CROPPAGE];
        
        if (![weakSelf.pdfViewCtrl.currentDoc isModified]) {
            [weakSelf.rootViewController popViewControllerAnimated:YES];
            [weakSelf.pdfViewCtrl closeDoc:nil];
        }
        else
        {
            UIView *menu = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 100)];
            UIButton *save = [[UIButton alloc] initWithFrame:CGRectMake(10, 15, 130, 20)];
            [save setTitle:NSLocalizedStringFromTable(@"kSave", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
            [save setTitleColor:[UIColor colorWithRed:23.f/255.f green:156.f/255.f blue:216.f/255.f alpha:1] forState:UIControlStateNormal];
            [save setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            save.titleLabel.font = [UIFont systemFontOfSize:15];
            [save addTarget:weakSelf action:@selector(buttonSaveClick) forControlEvents:UIControlEventTouchUpInside];
            [menu addSubview:save];
            UIButton *discard = [[UIButton alloc] initWithFrame:CGRectMake(10, 65, 130, 20)];
            [discard setTitle:NSLocalizedStringFromTable(@"kDiscardChange", @"FoxitLocalizable", nil) forState:UIControlStateNormal];
            [discard setTitleColor:[UIColor colorWithRed:23.f/255.f green:156.f/255.f blue:216.f/255.f alpha:1] forState:UIControlStateNormal];
            [discard setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            discard.titleLabel.font = [UIFont systemFontOfSize:15];
            [discard addTarget:weakSelf action:@selector(buttonDiscardChangeClick) forControlEvents:UIControlEventTouchUpInside];
            [menu addSubview:discard];
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, 50, 130, 1)];
            line.backgroundColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1];
            [menu addSubview:line];
            
            CGRect frame = item.contentView.frame;
            CGPoint startPoint = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
            weakSelf.popover = [DXPopover popover];
            [weakSelf.popover showAtPoint:startPoint popoverPosition:DXPopoverPositionDown withContentView:menu inView:weakSelf.pdfViewCtrl];
            weakSelf.popover.didDismissHandler = ^{
                
            };
        }
    };
    [self.topToolbar addItem:self.backItem displayPosition:Position_LT];
    
        
    UIImage *commonReadMore = [UIImage imageNamed:@"common_read_more"];
    UIImage *annoToolitembg = [UIImage imageNamed:@"annotation_toolitembg"];
    self.moreAnnotItem = [TbBaseItem createItemWithImage:commonReadMore imageSelected:commonReadMore imageDisable:commonReadMore background:annoToolitembg];
    self.moreAnnotItem.tag = 1;
    self.moreAnnotItem.onTapClick = ^(TbBaseItem*item){
        if (weakSelf.extensionsMgr.currentAnnot) {
            [weakSelf.extensionsMgr setCurrentAnnot:nil];
        }
        weakSelf.hiddenMoreToolsBar = NO;
    };
    [self.editBar addItem:self.moreAnnotItem displayPosition:DEVICE_iPHONE?Position_RB:Position_CENTER];
    
    UIImage *commonBackBlue = [UIImage imageNamed:@"common_back_blue"];
    TbBaseItem *doneItem = [TbBaseItem createItemWithImage:commonBackBlue imageSelected:commonBackBlue imageDisable:commonBackBlue background:nil];
    doneItem.tag = 0;
    [self.editDoneBar addItem:doneItem displayPosition:Position_LT];
    doneItem.onTapClick = ^(TbBaseItem*item){
        [weakSelf.extensionsMgr setCurrentToolHandler:nil];
        if (weakSelf.extensionsMgr.currentAnnot) {
            [weakSelf.extensionsMgr setCurrentAnnot:nil];
        }
        [self changeState:STATE_NORMAL];
        
    };

    int itemCount = 0;
    NSMutableArray* array = [[NSMutableArray alloc] init];
    
    if(_extensionsMgr.modulesConfig.loadReadingBookmark || _extensionsMgr.modulesConfig.loadOutline || _extensionsMgr.modulesConfig.loadAnnotations || _extensionsMgr.modulesConfig.loadAttachment)
    {
        UIImage *readPanel = [UIImage imageNamed:@"read_panel"];
        TbBaseItem *panelItem = [TbBaseItem createItemWithImageAndTitle:NSLocalizedStringFromTable(@"kReadList", @"FoxitLocalizable", nil) imageNormal:readPanel imageSelected:readPanel imageDisable:readPanel background:nil imageTextRelation:RELATION_BOTTOM];
        panelItem.textColor = [UIColor blackColor];
        panelItem.textFont = [UIFont systemFontOfSize:9.f];
        panelItem.onTapClick = ^(TbBaseItem *item){
            if (weakSelf.extensionsMgr.currentAnnot) {
                [weakSelf.extensionsMgr setCurrentAnnot:nil];
            }
            self.panelController.isHidden = NO;
        };
        [self.bottomToolbar addItem:panelItem displayPosition:Position_CENTER];
        itemCount++;
        [array addObject:panelItem];
    }
    
    UIImage *readModeImg = [UIImage imageNamed:@"read_mode"];
    TbBaseItem *readmodeItem = [TbBaseItem createItemWithImageAndTitle:NSLocalizedStringFromTable(@"kReadView", @"FoxitLocalizable", nil) imageNormal:readModeImg imageSelected:readModeImg imageDisable:readModeImg background:nil imageTextRelation:RELATION_BOTTOM];
    readmodeItem.textColor = [UIColor blackColor];
    readmodeItem.textFont = [UIFont systemFontOfSize:9.f];
    readmodeItem.onTapClick = ^(TbBaseItem *item){
        if (weakSelf.extensionsMgr.currentAnnot) {
            [weakSelf.extensionsMgr setCurrentAnnot:nil];
        }
        self.hiddenSettingBar = NO;
    };
    [self.bottomToolbar addItem:readmodeItem displayPosition:Position_CENTER];
    itemCount++;
    [array addObject:readmodeItem];
    
    if(_extensionsMgr.modulesConfig.loadAnnotations)
    {
        UIImage *readAnnotImg = [UIImage imageNamed:@"read_annot"];
        self.annotItem = [TbBaseItem createItemWithImageAndTitle:NSLocalizedStringFromTable(@"kReadComment", @"FoxitLocalizable", nil) imageNormal:readAnnotImg imageSelected:readAnnotImg imageDisable:readAnnotImg background:nil imageTextRelation:RELATION_BOTTOM];
        self.annotItem.textColor = [UIColor blackColor];
        self.annotItem.textFont = [UIFont systemFontOfSize:9.f];
        self.annotItem.onTapClick = ^(TbBaseItem *item){
            if (weakSelf.extensionsMgr.currentAnnot) {
                [weakSelf.extensionsMgr setCurrentAnnot:nil];
            }
            [weakSelf changeState:STATE_EDIT];
        };
        [self.bottomToolbar addItem:self.annotItem displayPosition:Position_CENTER];
        itemCount++;
        [array addObject:self.annotItem];
    }

    if(_extensionsMgr.modulesConfig.loadSignature)
    {
        UIImage *signatureImg = [UIImage imageNamed:@"signature"];
        self.signatureItem = [TbBaseItem createItemWithImageAndTitle:NSLocalizedStringFromTable(@"kSignatureTitle", @"FoxitLocalizable", nil) imageNormal:signatureImg imageSelected:signatureImg imageDisable:signatureImg background:nil imageTextRelation:RELATION_BOTTOM];
        self.signatureItem.textColor = [UIColor blackColor];
        self.signatureItem.textFont = [UIFont systemFontOfSize:9.f];
        [self.bottomToolbar addItem:self.signatureItem displayPosition:Position_CENTER];
        itemCount++;
        [array addObject:self.signatureItem];
    }
    
    switch (itemCount) {
        case 1:
        {
            TbBaseItem* item1 = [array objectAtIndex:0];
            item1.contentView.center = CGPointMake(SCREENWIDTH/2, 25);
            break;
        }
        case 2:
        {
            TbBaseItem* item1 = [array objectAtIndex:0];
            item1.contentView.center = CGPointMake(SCREENWIDTH/3, 25);
            TbBaseItem* item2 = [array objectAtIndex:1];
            item2.contentView.center = CGPointMake(SCREENWIDTH*2/3, 25);
            break;
        }
        case 3:
        {
            TbBaseItem* item1 = [array objectAtIndex:0];
            item1.contentView.center = CGPointMake(SCREENWIDTH/4, 25);
            TbBaseItem* item2 = [array objectAtIndex:1];
            item2.contentView.center = CGPointMake(SCREENWIDTH*2/4, 25);
            TbBaseItem* item3 = [array objectAtIndex:2];
            item3.contentView.center = CGPointMake(SCREENWIDTH*3/4, 25);
            break;
        }
        case 4:
        {
            TbBaseItem* item1 = [array objectAtIndex:0];
            item1.contentView.center = CGPointMake(SCREENWIDTH/5, 25);
            TbBaseItem* item2 = [array objectAtIndex:1];
            item2.contentView.center = CGPointMake(SCREENWIDTH*2/5, 25);
            TbBaseItem* item3 = [array objectAtIndex:2];
            item3.contentView.center = CGPointMake(SCREENWIDTH*3/5, 25);
            TbBaseItem* item4 = [array objectAtIndex:3];
            item4.contentView.center = CGPointMake(SCREENWIDTH*4/5, 25);
            break;
        }
        default:
            break;
    }


}

-(FSReadingBookmark*)getReadingBookMarkAtPage:(int)page
{
    int count;
    @try {
        count = [self.pdfViewCtrl.currentDoc getReadingBookmarkCount];
    } @catch (NSException *exception) {
        return nil;
    }
    for(int i = 0; i < count; i ++) {
        FSReadingBookmark* bookmark = [self.pdfViewCtrl.currentDoc getReadingBookmark:i];
        if([bookmark getPageIndex] == page)
            return bookmark;
    }
    return nil;
}

-(void)buttonSaveClick
{
    [self.popover dismiss];
    self.popover = nil;
    self.isFileEdited = YES;
    _isDocModified = NO;
    [self.rootViewController popViewControllerAnimated:YES];
   
    NSString* tmpPath = nil;
    NSString* filePath = self.filePath;
    
    if(filePath)
    {
        NSString* tempDir = NSTemporaryDirectory();
        tmpPath = [tempDir stringByAppendingPathComponent:[filePath lastPathComponent]];
        [self.pdfViewCtrl saveDoc:tmpPath flag:e_saveFlagIncremental];
        
        //update folder size dictionary
        NSString* key = [[self.filePath componentsSeparatedByString:DOCUMENT_PATH] objectAtIndex:1];
        while ( ![(key = [key stringByDeletingLastPathComponent]) isEqualToString:@"/"] ) {
            [self.folderSizeDictionary removeObjectForKey:key];
        }
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
    [self.popover dismiss];
    self.popover = nil;
    self.isFileEdited = NO;
    _isDocModified = NO;
    [self.rootViewController popViewControllerAnimated:YES];
    [self.pdfViewCtrl closeDoc:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_extensionsMgr clearThumbnailCachesForCurrentDocument];
    });
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
        UIViewController *viewCtr = [[UIViewController alloc] init];
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
        [self.extensionsMgr stopFormFilling];
        
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
    
    [self.pdfViewCtrl willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
     [self.pdfViewCtrl willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
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
    
    if (DEVICE_iPHONE) {
        [self.moreToolsBar refreshAnnotationBarLayout];
    }
    
    [self.pdfViewCtrl didRotateFromInterfaceOrientation:fromInterfaceOrientation];
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

-(void)enableTopToolbar:(BOOL)isEnabled
{
    if(isEnabled)
    {
        if(self.topToolbar)
            return;
        
        if(self.topToolbarSaved)
        {
            [self.pdfViewCtrl addSubview:self.topToolbarSaved.contentView];
            self.topToolbar = self.topToolbarSaved;
        }
    }
    else
    {
        if(!self.topToolbar)
            return;
        self.topToolbarSaved = self.topToolbar;
        [self.topToolbar.contentView removeFromSuperview];
        self.topToolbar = nil;
    }
    
}

-(void)enableBottomToolbar:(BOOL)isEnabled
{
    if(isEnabled)
    {
        if(self.bottomToolbar)
            return;

        if(self.bottomToolbarSaved)
        {
            [self.pdfViewCtrl addSubview:self.bottomToolbarSaved.contentView];
            self.bottomToolbar = self.bottomToolbarSaved;
        }
    }
    else
    {
        if(!self.bottomToolbar)
            return;
        self.bottomToolbarSaved = self.bottomToolbar;
        [self.bottomToolbar.contentView removeFromSuperview];
        self.bottomToolbar = nil;
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
        self.annotItem.enable = [Utility canAddAnnotToDocument:document];
        self.signatureItem.enable = [Utility canAddSignToDocument:document];
    }

    [self.topToolbar removeCenterItems];
    [self updateBookmarkButtonState];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([Utility canAssembleDocument:document ]) {
            self.bookmarkItem.button.userInteractionEnabled = YES;
            self.bookmarkItem.button.alpha = 1;
        } else {
            self.bookmarkItem.button.userInteractionEnabled = NO;
            self.bookmarkItem.button.alpha = 0.5;
        }
    });
}

- (void)onDocWillClose:(FSPDFDoc* )document
{
}

- (void)onDocClosed:(FSPDFDoc* )document error:(int)error
{
    self.bookmarkItem.button.userInteractionEnabled = YES;
    self.bookmarkItem.button.alpha = 1.0f;
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
    if (toolName && ![toolName isEqualToString:Tool_Select] && ![toolName isEqualToString:Tool_Signature]) {
        if ([_extensionsMgr getToolHandlerByName:toolName] != nil) {
            [self changeState:STATE_ANNOTTOOL];
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

- (void)onPageInvisible:(int)index
{
}

- (void)onPageChanged:(int)oldIndex currentIndex:(int)currentIndex;
{
    [self updateBookmarkButtonState];
}

- (void)dealloc
{
    maskView = nil;
    _instance = nil;
}

@end
