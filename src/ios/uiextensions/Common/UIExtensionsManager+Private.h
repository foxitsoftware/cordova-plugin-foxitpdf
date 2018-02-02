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

#ifndef UIExtensionsManager_Private_h
#define UIExtensionsManager_Private_h
#import "../BaseBar/TbBaseBar.h"
#import "../More/MoreMenu/MenuView.h"
#import "../MoreAnnotationsBar/MoreAnnotationsBar.h"
#import "../Property/PropertyBar.h"
#import "../UIExtensionsManager.h"
#import "../Undo/FSUndo.h"
#import "../Utility/Utility.h"
#import "Const.h"
#import "Defines.h"
#import "FSAnnotExtent.h"
#import "Preference.h"
#import "SettingPreference.h"
#import "TaskServer.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import <UIKit/UIKit.h>

/** @brief Module base. */
@protocol IModule <NSObject>
/** @brief Get the module name. */
- (NSString *)getName;
@end

/** @brief States of extensions manager. */
#define STATE_NORMAL 1
#define STATE_REFLOW 2
#define STATE_SEARCH 3
#define STATE_EDIT 4
#define STATE_ANNOTTOOL 6
#define STATE_THUMBNAIL 8
#define STATE_PAGENAVIGATE 9
#define STATE_SIGNATURE 10

/** @brief The state change event listener. */
@protocol IStateChangeListener <NSObject>
@required
/**
 * @brief Triggered when state changed.
 *
 * @param[in] state     New state.
 */
- (void)onStateChanged:(int)state;
@end

/** @brief A listener for annotation property bar. */
@protocol IAnnotPropertyListener <NSObject>
@optional
/** @brief Triggered when the color of annotation is changed. */
- (void)onAnnotColorChanged:(unsigned int)color annotType:(FSAnnotType)annotType;
/** @brief Triggered when the opacity of annotation is changed. */
- (void)onAnnotOpacityChanged:(unsigned int)opacity annotType:(FSAnnotType)annotType;
- (void)onAnnotLineWidthChanged:(unsigned int)lineWidth annotType:(FSAnnotType)annotType;
- (void)onAnnotFontNameChanged:(NSString *)fontName annotType:(FSAnnotType)annotType;
- (void)onAnnotFontSizeChanged:(unsigned int)fontSize annotType:(FSAnnotType)annotType;
- (void)onAnnotIconChanged:(int)icon annotType:(FSAnnotType)annotType;
- (void)onAnnotDistanceUnitChanged:(int)icon annotType:(FSAnnotType)annotType;
- (void)onAnnotRotationChanged:(FSRotation)rotation annotType:(FSAnnotType)annotType;
@end

/** @brief The undo/redo listener. */
@protocol IFSUndoEventListener <NSObject>
/** @brief Triggered after the state of undo or redo changed. */
- (void)onUndoChanged;
@end

/** @brief The undo/redo handler,it should handle the operations about undo/redo. */
@protocol FSUndo <NSObject>
/** @brief Check whether can undo or not. */
- (BOOL)canUndo;
/** @brief Check whether can redo or not. */
- (BOOL)canRedo;
/** @brief Undo the previous operation. */
- (void)undo;
/** @brief Redo the previous operation. */
- (void)redo;
/** @brief Clear all the recorded undo/redo operations. */
- (void)clearUndoRedo;
@end

@class MenuControl;
@class ExAnnotIconProviderCallback;
@class ExActionHandler;
@class PasswordModule;
@protocol FSPageOrganizerDelegate;

/** @brief Private implementation for extension manager, these properites and methods are not supposed to be called. */
@interface UIExtensionsManager () <FSUndo, IDrawEventListener, IPropertyValueChangedListener, IGestureEventListener, IScrollViewEventListener, ISearchEventListener>
@property (nonatomic, strong) MenuView *more;
@property (nonatomic, strong) TbBaseBar *editBar;
@property (nonatomic, strong) TbBaseBar *editDoneBar;
@property (nonatomic, strong) TbBaseBar *toolSetBar;
@property (nonatomic, strong) MoreAnnotationsBar *moreToolsBar;
@property (nonatomic, assign) BOOL hiddenMoreToolsBar;
@property (nonatomic, assign) BOOL hiddenMoreMenu;
@property (nonatomic, assign) BOOL hiddenEditBar;
@property (nonatomic, assign) BOOL hiddenEditDoneBar;
@property (nonatomic, assign) BOOL hiddenToolSetBar;

@property (nonatomic, assign) BOOL isDocModified;
@property (nonatomic, assign) BOOL isFileEdited;
@property (nonatomic, assign) FSSaveFlags docSaveFlag;

@property (nonatomic, strong) NSMutableArray *stateChangeListeners;
@property (nonatomic, strong) NSMutableArray *annotListeners;
@property (nonatomic, strong) NSMutableArray *toolListeners;
@property (nonatomic, strong) NSMutableArray *searchListeners;
@property (nonatomic, strong) NSMutableArray *toolHandlers;
@property (nonatomic, strong) NSMutableArray *annotHandlers;
@property (nonatomic, assign) int noteIcon;
@property (nonatomic, assign) int attachmentIcon;
@property (nonatomic, assign) int eraserLineWidth;
@property (nonatomic, assign) int stampIcon;
@property (nonatomic, strong) NSString *distanceUnit;
@property (nonatomic, assign) FSRotation screenAnnotRotation;
@property (nonatomic, strong) PropertyBar *propertyBar;
@property (nonatomic, strong) TaskServer *taskServer;
@property (nonatomic, strong) MenuControl *menuControl;

@property (nonatomic, strong) ExAnnotIconProviderCallback *iconProvider;
@property (nonatomic, strong) ExActionHandler *actionHandler;

@property (nonatomic, strong) UIExtensionsModulesConfig *modulesConfig;
@property (nonatomic, strong) PasswordModule *passwordModule;

@property (nonatomic, assign) BOOL isShowBlankMenu;
@property (nonatomic, strong) FSPointF *currentPoint;
@property (nonatomic, assign) int currentPageIndex;

@property (nonatomic, assign) BOOL hiddenPanel;
@property (nonatomic, assign) BOOL hiddenTopToolbar;
@property (nonatomic, assign) BOOL hiddenBottomToolbar;
@property (nonatomic, assign) BOOL hiddenSettingBar;

@property (nonatomic, strong) NSMutableArray<UndoItem *> *undoItems;
@property (nonatomic, strong) NSMutableArray<UndoItem *> *redoItems;
@property (nonatomic, strong) NSMutableArray<IFSUndoEventListener> *undoListeners;

- (void)setCurrentAnnot:(FSAnnot *)anot;
- (unsigned int)getAnnotColor:(FSAnnotType)annotType;
- (void)setAnnotColor:(unsigned int)color annotType:(FSAnnotType)annotType;
- (int)getAnnotOpacity:(FSAnnotType)annotType;
- (void)setAnnotOpacity:(int)opacity annotType:(FSAnnotType)annotType;
- (int)getAnnotLineWidth:(FSAnnotType)annotType;
- (void)setAnnotLineWidth:(int)lineWidth annotType:(FSAnnotType)annotType;
- (int)getAnnotFontSize:(FSAnnotType)annotType;
- (void)setAnnotFontSize:(int)fontSize annotType:(FSAnnotType)annotType;
- (NSString *)getAnnotFontName:(FSAnnotType)annotType;
- (void)setAnnotFontName:(NSString *)fontName annotType:(FSAnnotType)annotType;
- (int)filterAnnotType:(FSAnnotType)annotType;
- (id<IAnnotHandler>)getAnnotHandlerByAnnot:(FSAnnot *)annot;

- (void)saveAndCloseCurrentDoc:(void (^_Nullable)(BOOL success))completion;

- (void)registerRotateChangedListener:(id<IRotationEventListener>)listener;
- (void)unregisterRotateChangedListener:(id<IRotationEventListener>)listener;

- (void)registerGestureEventListener:(id<IGestureEventListener>)listener;
- (void)unregisterGestureEventListener:(id<IGestureEventListener>)listener;

- (void)removeThumbnailCacheOfPageAtIndex:(NSUInteger)pageIndex;
- (void)clearThumbnailCachesForPDFAtPath:(NSString *)path;

/** @brief Register annotation property change event listener. */
- (void)registerAnnotPropertyListener:(id<IAnnotPropertyListener>)listener;
/** @brief Unregister annotation property change event listener. */
- (void)unregisterAnnotPropertyListener:(id<IAnnotPropertyListener>)listener;

/**
 * @brief Get state of extensions manager.
 *
 * @return	current state. Please refer to {@link STATE_NORMAL STATE_XXX} values and it would be one of these values.
 */
- (int)getState;
/**
 * @brief Change state of extensions manager.
 *
 * @param[in]	state	New state. Please refer to {@link STATE_NORMAL STATE_XXX} values and it would be one of these values.
 */
- (void)changeState:(int)state;
/** @brief Register a state change event listener. */
- (void)registerStateChangeListener:(id<IStateChangeListener>)listener;
/** @brief Unregister a state change event listener. */
- (void)unregisterStateChangeListener:(id<IStateChangeListener>)listener;

#pragma mark - Undo/redo event listeners.
/** @brief Register the undo/redo event listener. */
- (void)registerUndoEventListener:(id<IFSUndoEventListener>)listener;
/** @brief Unregister the undo/redo event listener. */
- (void)unregisterUndoEventListener:(id<IFSUndoEventListener>)listener;

- (void)addUndoItem:(UndoItem *)undoItem;

@end

@interface ExAnnotIconProviderCallback : FSAnnotIconProviderCallback
- (NSString *)getProviderID;
- (NSString *)getProviderVersion;
- (BOOL)hasIcon:(FSAnnotType)annotType iconName:(NSString *)iconName;
- (BOOL)canChangeColor:(FSAnnotType)annotType iconName:(NSString *)iconName;
- (FSPDFPage *)getIcon:(FSAnnotType)annotType iconName:(NSString *)iconName color:(unsigned int)color;
- (FSShadingColor *)getShadingColor:(FSAnnotType)annotType iconName:(NSString *)iconName refColor:(unsigned int)refColor shadingIndex:(int)shadingIndex;
- (NSNumber *)getDisplayWidth:(FSAnnotType)annotType iconName:(NSString *)iconName;
- (NSNumber *)getDisplayHeight:(FSAnnotType)annotType iconName:(NSString *)iconName;
@end

@interface ExActionHandler : FSActionHandler
@property (nonatomic, strong) FSPDFViewCtrl *pdfViewCtrl;

- (id)initWithPDFViewControl:(FSPDFViewCtrl *)viewctrl;
- (int)getCurrentPage:(FSPDFDoc *)pdfDoc;
- (void)setCurrentPage:(FSPDFDoc *)pdfDoc pageIndex:(int)pageIndex;
- (FSRotation)getPageRotation:(FSPDFDoc *)pdfDoc pageIndex:(int)pageIndex;
- (BOOL)setPageRotation:(FSPDFDoc *)pdfDoc pageIndex:(int)pageIndex rotation:(FSRotation)rotation;
- (int)alert:(NSString *)msg title:(NSString *)title type:(int)type icon:(int)icon;
- (FSIdentityProperties *)getIdentityProperties;
@end

#endif /* UIExtensionsManager_Private_h */
