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
#import "MoreAnnotationsBar.h"
#import "AppDelegate.h"
#import "MenuView.h"
#import "FileSelectDestinationViewController.h"
#import "UIExtensionsSharedHeader.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import "SettingBarController.h"

#define STATE_NORMAL 1
#define STATE_PAGENAVIGATE 2
#define STATE_SEARCH 3
#define STATE_EDIT 4
#define STATE_ANNOTTOOL 6
#define STATE_THUMBNAIL 8

@protocol IStateChangeListener <NSObject>
@required
-(void)onStateChanged:(int)state;
@end

typedef void (^ AnnotAuthorCallBack)();

@protocol IFullScreenListener <NSObject>

-(void)onFullScreen:(BOOL)isFullScreen;

@end


@class FSPDFViewCtrl;

@interface ReadFrame : NSObject<IStateChangeListener,ILayoutEventListener, IDocEventListener,UIPopoverControllerDelegate,  IRotationEventListener, IGestureEventListener, IToolEventListener, IAnnotEventListener, ISearchEventListener, IPageEventListener>

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


@property (nonatomic, strong) UIExtensionsManager* extensionsMgr;
@property (nonatomic, strong) FSPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, strong) UINavigationController *naviCon;

@property (nonatomic, strong) UIViewController *CordovaPluginViewController;

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
@property (nonatomic, retain) NSMutableArray *stateChangeListeners;
@property (nonatomic, assign) BOOL isDocModified;

+(instancetype)sharedInstance;
-(id)initWithPdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl;

-(void)registerFullScreenListener:(id<IFullScreenListener>)listener;
-(void)unregisterFullScreenListener:(id<IFullScreenListener>)listener;

-(void)registerRotateChangedListener:(id<IRotationEventListener>)listener;
-(void)unregisterRotateChangedListener:(id<IRotationEventListener>)listener;

- (void)registerStateChangeListener:(id<IStateChangeListener>)listener;
- (void)unregisterStateChangeListener:(id<IStateChangeListener>)listener;

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

- (int)getState;
- (void)changeState:(int)state;
@end
