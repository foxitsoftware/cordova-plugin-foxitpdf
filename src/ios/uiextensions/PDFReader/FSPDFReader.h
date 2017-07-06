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

#import "MoreAnnotationsBar.h"
//#import "AppDelegate.h"
#import "MoreMenu/MenuView.h"
#import "../UIExtensionsSharedHeader.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import "SettingBar/SettingBarController.h"

#define STATE_NORMAL 1
#define STATE_REFLOW 2
#define STATE_SEARCH 3
#define STATE_EDIT 4
#define STATE_ANNOTTOOL 6
#define STATE_THUMBNAIL 8
#define STATE_PAGENAVIGATE 9
#define STATE_SIGNATURE 10

@protocol IStateChangeListener <NSObject>
@required
-(void)onStateChanged:(int)state;
@end

typedef void (^ AnnotAuthorCallBack)();

@protocol IFullScreenListener <NSObject>

-(void)onFullScreen:(BOOL)isFullScreen;

@end

@class FSPDFViewCtrl;
@class SettingBarController;
@class MoreAnnotationsBar;

@interface FSPDFReader : NSObject<IStateChangeListener,ILayoutEventListener, IDocEventListener,UIPopoverControllerDelegate,  IRotationEventListener, IGestureEventListener, IToolEventListener, IAnnotEventListener, ISearchEventListener, IPageEventListener>
@property (nonatomic, strong) UINavigationController* rootViewController;
@property (nonatomic, strong) UIViewController* filelistViewController;
@property (nonatomic, strong) UIView* contentView;
@property (nonatomic, strong) PanelController *panelController;
@property (nonatomic, strong) MenuView * more;

@property (nonatomic, strong) TbBaseBar *topToolbar;
@property (nonatomic, strong) TbBaseBar *bottomToolbar;
@property (nonatomic, strong) SettingBarController* settingBarController;
@property (nonatomic, strong) TbBaseBar *editBar;
@property (nonatomic, strong) TbBaseBar *editDoneBar;
@property (nonatomic, strong) MoreAnnotationsBar *moreToolsBar;
@property (nonatomic, strong) TbBaseBar *toolSetBar;
@property (nonatomic, strong) TbBaseItem *bookmarkItem;
@property (nonatomic, strong) TbBaseItem *signatureItem;

@property (nonatomic, strong, readonly) UIExtensionsManager* extensionsMgr;
@property (nonatomic, strong, readonly) FSPDFViewCtrl *pdfViewCtrl;

@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL hiddenPanel;
@property (nonatomic, assign) BOOL hiddenMoreMenu;

@property (nonatomic, assign) BOOL hiddenTopToolbar;
@property (nonatomic, assign) BOOL hiddenBottomToolbar;
@property (nonatomic, assign) BOOL hiddenSettingBar;
@property (nonatomic, assign) BOOL hiddenEditBar;
@property (nonatomic, assign) BOOL hiddenEditDoneBar;
@property (nonatomic, assign) BOOL hiddenMoreToolsBar;
@property (nonatomic, assign) BOOL hiddenToolSetBar;

@property (nonatomic, assign) BOOL continueAddAnnot;
@property (nonatomic, strong) NSMutableArray *stateChangeListeners;
@property (nonatomic, assign) BOOL isDocModified;
@property (nonatomic, assign) BOOL isFileEdited;
@property (nonatomic, copy) NSString* filePath;
@property (nonatomic, copy) NSString* password;
@property (nonatomic, assign) BOOL isScreenLocked;

@property (nonatomic, strong) NSMutableDictionary *folderSizeDictionary;

+(instancetype)sharedInstance;
-(id)initWithPdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl extensions:(UIExtensionsManager*) extensions;

-(BOOL)openPDFAtPath:(NSString*)path withPassword:(NSString*)password;

-(void)registerFullScreenListener:(id<IFullScreenListener>)listener;
-(void)unregisterFullScreenListener:(id<IFullScreenListener>)listener;

-(void)registerRotateChangedListener:(id<IRotationEventListener>)listener;
-(void)unregisterRotateChangedListener:(id<IRotationEventListener>)listener;

-(void)registerStateChangeListener:(id<IStateChangeListener>)listener;
-(void)unregisterStateChangeListener:(id<IStateChangeListener>)listener;

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

-(int)getState;
-(void)changeState:(int)state;

-(void)enableTopToolbar:(BOOL)isEnabled;
-(void)enableBottomToolbar:(BOOL)isEnabled;

-(FSReadingBookmark*)getReadingBookMarkAtPage:(int)page;

@end
