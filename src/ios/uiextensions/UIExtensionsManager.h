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

/**
 * @file	UIExtensionsManager.h
 * @details	The UI extensions mangager consists of additional UI bars and tools.
 */

#ifndef UIExtensionsManager_h
#define UIExtensionsManager_h

#import "Panel/PanelController.h"
#import "SettingBar/SettingBar.h"
#import "UIExtensionsModulesConfig.h"
#import <FoxitRDK/FSPDFViewControl.h>

#define FS_TOPBAR_ITEM_BOOKMARK_TAG 100     ///< tag of bookmark button item in top tool bar
#define FS_TOPBAR_ITEM_BACK_TAG 101         ///< tag of back button item in top tool bar
#define FS_TOPBAR_ITEM_MORE_TAG 102         ///< tag of more button item in top tool bar
#define FS_TOPBAR_ITEM_SEARCH_TAG 103       ///< tag of search button item in top tool bar
#define FS_BOTTOMBAR_ITEM_PANEL_TAG 200     ///< tag of panel button item in bottom tool bar
#define FS_BOTTOMBAR_ITEM_ANNOT_TAG 201     ///< tag of annotation button item in top bottom bar
#define FS_BOTTOMBAR_ITEM_SIGNATURE_TAG 202 ///< tag of signature button item in top bottom bar
#define FS_BOTTOMBAR_ITEM_READMODE_TAG 203  ///< tag of read mode button item in top bottom bar

#define Tool_Select @"Select"         ///< name of select tool
#define Tool_Note @"Note"             ///< name of note tool
#define Tool_Freetext @"Freetext"     ///< name of free text tool
#define Tool_Pencil @"Pencil"         ///< name of pencil tool
#define Tool_Eraser @"Eraser"         ///< name of eraser tool
#define Tool_Stamp @"Stamp"           ///< name of stamp tool
#define Tool_Insert @"Insert"         ///< name of insert text tool
#define Tool_Replace @"Replace"       ///< name of replace text tool
#define Tool_Attachment @"Attachment" ///< name of attachment tool
#define Tool_Signature @"Signature"   ///< name of signature tool
#define Tool_Line @"Line"             ///< name of line tool
#define Tool_Arrow @"Arrow"           ///< name of arrow line tool
#define Tool_Markup @"Markup"         ///< name of markup tool, which includes highlight squiggly strikeout and underline tools
#define Tool_Highlight @"Highlight"   ///< name of highlight tool
#define Tool_Squiggly @"Squiggly"     ///< name of squiggly tool
#define Tool_StrikeOut @"StrikeOut"   ///< name of strikeout tool
#define Tool_Underline @"Underline"   ///< name of underline tool
#define Tool_Shape @"Shape"           ///< name of shape tool, which includes rectangle and oval tools
#define Tool_Rectangle @"Rectangle"   ///< name of rectangle tool
#define Tool_Oval @"Oval"             ///< name of oval tool

NS_ASSUME_NONNULL_BEGIN

/** @brief Annotation event listener. */
@protocol IAnnotEventListener <NSObject>
@optional
/** @brief Triggered when the annotation is added. */
- (void)onAnnotAdded:(FSPDFPage *)page annot:(FSAnnot *)annot;
/** @brief Triggered when the annotation is deleted. */
- (void)onAnnotDeleted:(FSPDFPage *)page annot:(FSAnnot *)annot;
/** @brief Triggered when the annotation is modified. */
- (void)onAnnotModified:(FSPDFPage *)page annot:(FSAnnot *)annot;
/** @brief Triggered when the annotation is selected. */
- (void)onAnnotSelected:(FSPDFPage *)page annot:(FSAnnot *)annot;
/** @brief Triggered when the annotation is deselected. */
- (void)onAnnotDeselected:(FSPDFPage *)page annot:(FSAnnot *)annot;
@end

/** @brief A Tool event listener. */
@protocol IToolEventListener <NSObject>
@required
/** @brief Triggered when the current tool handler of extensions manager is changed. */
- (void)onToolChanged:(NSString *)lastToolName CurrentToolName:(NSString *)toolName;
@end

/** @brief A search event listener. */
@protocol ISearchEventListener <NSObject>
@optional
/** @brief Triggered when the text searching is started. */
- (void)onSearchStarted;
/** @brief Triggered when the text searching is canceled. */
- (void)onSearchCanceled;
@end

/** @brief The tool handler, it handles the gesture and touches events, which a tool should always implement most of them.*/
@protocol IToolHandler <NSObject>
/** @brief Get/set the current annot type if it's a annotation tool handler. */
@property (nonatomic, assign) FSAnnotType type;
/** @brief Get the tool name. */
- (NSString *)getName;
/** @brief If the tool handler is enabled. */
- (BOOL)isEnabled;
/** @brief If the tool handler is activated. */
- (void)onActivate;
/** @brief If the tool handler is deactivated. */
- (void)onDeactivate;

#pragma mark - PageView Gesture+Touch
/** @brief Long press gesture on the specified page. */
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer;
/** @brief Tap gesture on the specified page. */
- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer;
/** @brief Pan gesture on the specified page. */
- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer;
/** @brief Should being gesture on the specified page. */
- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer;
/** @brief Touches began on the specified page. */
- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event;
/** @brief Touches moved on the specified page. */
- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event;
/** @brief Touches ended on the specified page. */
- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event;
/** @brief Touches cancelled on the specified page. */
- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event;
@optional
/** @brief Drawing event on the specified page. */
- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context;
@end

/** @brief The annotation handler, it should handle the operations on the specified annotation. */
@protocol IAnnotHandler <NSObject>
/** brief Get the annotation type */
- (FSAnnotType)getType;
/** brief Can hit the annotation at specified point. */
- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point;
/** brief When the annotation is selected. */
- (void)onAnnotSelected:(FSAnnot *)annot;
/** brief When the annotation is deselected. */
- (void)onAnnotDeselected:(FSAnnot *)annot;
/** brief Add a new annotation to a specified page. It's equal to the following one with the param addUndo YES. */
- (void)addAnnot:(FSAnnot *)annot;
/** brief Add a new annotation to a specified page, undo/redo will be supported if the param addUndo is YES. */
- (void)addAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo;
/** brief Modify an annotation. It's equal to the following one with the param addUndo YES. */
- (void)modifyAnnot:(FSAnnot *)annot;
/** brief Modify an annotation, undo/redo will be supported if the param addUndo is YES. */
- (void)modifyAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo;
/** brief Remove an annotation. It's equal to the following one with the param addUndo YES. */
- (void)removeAnnot:(FSAnnot *)annot;
/** brief Remove an annotation, undo/redo will be supported if the param addUndo is YES. */
- (void)removeAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo;

#pragma mark - PageView Gesture+Touch
/** @brief Long press gesture on the specified page. */
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot *)annot;
/** @brief Tap gesture on the specified page. */
- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot *)annot;
/** @brief Pan gesture on the specified page. */
- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot;
/** @brief Should being gesture on the specified page. */
- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot *)annot;
/** @brief Touches began on the specified page. */
- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot;
/** @brief Touches moved on the specified page. */
- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot;
/** @brief Touches ended on the specified page. */
- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot;
/** @brief Touches cancelled on the specified page. */
- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot;
@optional
/** @brief Drawing event on the specified page. */
- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context annot:(FSAnnot *)annot;
/** @brief Changed property event on the specified annot. */
- (void)onAnnotChanged:(FSAnnot *)annot property:(long)property from:(NSValue *)oldValue to:(NSValue *)newValue;
@end

/** @brief The full screen event listener. */
@protocol IFullScreenListener <NSObject>
/**
 * @brief Triggered when toggle full screen. When full screen, top/bottom tool bars are to be hidden.
 *
 * @param[in] isFullScreen     Is full screen or not.
 */
- (void)onFullScreen:(BOOL)isFullScreen;
@end

/** @brief A link event listener. */
@protocol ILinkEventListener <NSObject>
@optional
/** @brief Triggered when the link is clicked. 
 *
 *  @param[in] note	pointParam	Point in page view space.
 */
- (BOOL)onLinkOpen:(id)link LocationInfo:(CGPoint)pointParam;
@end

/** @brief The UI extensions mangager which has included the default implementation of text selection tool, annotation tools... and so on. */
@interface UIExtensionsManager : NSObject <FSPDFUIExtensionsManager, IDocEventListener, IPageEventListener, IRotationEventListener, IAnnotEventListener, IRecoveryEventListener, ILinkEventListener>
/** @brief The PDF view control. */
@property (nonatomic, strong, readonly) FSPDFViewCtrl *pdfViewCtrl;
/** @brief The Current tool handler. */
@property (nonatomic, strong, nullable) id<IToolHandler> currentToolHandler;
/** @brief The Current selected annotation. */
@property (nonatomic, strong, nullable) FSAnnot *currentAnnot;
/** @brief Whether to allow to jump to link address when tap on the link annatation. */
@property (nonatomic, assign) BOOL enableLinks;
/** @brief Whether to allow to highlight links. */
@property (nonatomic, assign) BOOL enableHighlightLinks;
/** @brief Get/Set the hightlight color for links. */
@property (nonatomic, strong) UIColor *linksHighlightColor;
/** @brief Get/Set the hightlight color for text selection. */
@property (nonatomic, strong) UIColor *selectionHighlightColor;
/** @brief Caller can choose to provide a block to execute when user tap on 'back' button on the top toolbar. */
@property (nonatomic, copy, nullable) void (^goBack)();

@property (nonatomic, strong) UIToolbar *topToolbar;
@property (nonatomic, strong) UIToolbar *bottomToolbar;
/** @brief The panel controller. */
@property (nonatomic, strong) FSPanelController *panelController;
/** @brief The setting bar. It shows when tap on the view button in the bottom bar. */
@property (nonatomic, strong) SettingBar *settingBar;
/** @brief Whether to keep tool active after using it to add an annotation. */
@property (nonatomic, assign) BOOL continueAddAnnot;
/** @brief Whether is full screen. When full screen, top and bottom bar is not shown. */
@property (nonatomic, assign) BOOL isFullScreen;
/** @brief Whether screen rotation is locked or not. */
@property (nonatomic, assign) BOOL isScreenLocked;

/**
 * @brief Intialize extensions manager.
 *
 * @param[in]	viewctrl	The PDF view control.
 *
 * @return	The extensions mananger instance.
 */
- (id)initWithPDFViewControl:(FSPDFViewCtrl *)viewctrl;
/**
 * @brief Intialize extensions manager.
 *
 * @param[in]	viewctrl        The PDF view control.
 * @param[in]	jsonConfigData	The json file data. See uiextensions_config.json for an example
 *
 * @return	The extensions mananger instance.
 */
- (id)initWithPDFViewControl:(FSPDFViewCtrl *)viewctrl configuration:(NSData *_Nullable)jsonConfigData;
/**
 * @brief Intialize extensions manager.
 *
 * @param[in]	viewctrl        The PDF view control.
 * @param[in]	configuration	The modules configuration.
 *
 * @return	The extensions mananger instance.
 */
- (id)initWithPDFViewControl:(FSPDFViewCtrl *)viewctrl configurationObject:(UIExtensionsModulesConfig *_Nonnull)configuration;

/** @brief Register a full screen event listener. */
- (void)registerFullScreenListener:(id<IFullScreenListener>)listener;
/** @brief Unregister a full screen event listener. */
- (void)unregisterFullScreenListener:(id<IFullScreenListener>)listener;
/** @brief Register a rotation event listener. */
- (void)registerRotateChangedListener:(id<IRotationEventListener>)listener;
/** @brief Unregister a rotation event listener. */
- (void)unregisterRotateChangedListener:(id<IRotationEventListener>)listener;
/**
 * @brief Enable or disable top toolbar.
 *
 * @param[in]	isEnabled	Whether top toolbar is enabled or not.
 */
- (void)enableTopToolbar:(BOOL)isEnabled;
/**
 * @brief Enable or disable bottom toolbar.
 *
 * @param[in]	isEnabled	Whether bottom toolbar is enabled or not.
 */
- (void)enableBottomToolbar:(BOOL)isEnabled;

#pragma mark - Toolhandler and AnnotHandler registration.
/** @brief Get the current tool handler by name, which is defined above Tool_XXX. */
- (id<IToolHandler>)getToolHandlerByName:(NSString *)name;
/** @brief Get the annotation handler by annotation type. */
- (id<IAnnotHandler>)getAnnotHandlerByType:(FSAnnotType)type;
/** @brief Register a tool handler. */
- (void)registerToolHandler:(id<IToolHandler>)toolHandler;
/** @brief Remove a tool handler. */
- (void)unregisterToolHandler:(id<IToolHandler>)toolHandler;
/** @brief Register an annotation handler. */
- (void)registerAnnotHandler:(id<IAnnotHandler>)annotHandler;
/** @brief Remove an annotation handler. */
- (void)unregisterAnnotHandler:(id<IAnnotHandler>)annotHandler;

#pragma mark - Tool and annotation event listeners.
/** @brief Register the annotation event listener. */
- (void)registerAnnotEventListener:(id<IAnnotEventListener>)listener;
/** @brief Unregister the annotation event listener. */
- (void)unregisterAnnotEventListener:(id<IAnnotEventListener>)listener;
/** @brief Register the tool event listener. */
- (void)registerToolEventListener:(id<IToolEventListener>)listener;
/** @brief Unregister the tool event listener. */
- (void)unregisterToolEventListener:(id<IToolEventListener>)listener;

#pragma mark - link event listeners.
/** @brief Register the link event listener. */
- (void)registerLinkEventListener:(id<ILinkEventListener>)listener;
/** @brief Unregister the link event listener. */
- (void)unregisterLinkEventListener:(id<ILinkEventListener>)listener;

#pragma mark - Property bar of annoatation for setting/getting annotation color and opacity.
/** @brief Show the property bar to set annotation color and opacity. */
- (void)showProperty:(FSAnnotType)annotType rect:(CGRect)rect inView:(UIView *)view;
/** @brief Get current setting annotation color from property bar. */
- (unsigned int)getPropertyBarSettingColor:(FSAnnotType)annotType;
/** @brief Get current setting annotation opacity from property bar. */
- (unsigned int)getPropertyBarSettingOpacity:(FSAnnotType)annotType;
/** @brief Show or hide the text searching bar on the UI main screen. It will appear on the top of main screen. */
- (void)showSearchBar:(BOOL)show;
/** @brief Register the tool event listener. */
- (void)registerSearchEventListener:(id<ISearchEventListener>)listener;
/** @brief Unregister the tool event listener. */
- (void)unregisterSearchEventListener:(id<ISearchEventListener>)listener;

/** @brief Get current selected text. */
- (NSString *)getCurrentSelectedText;

/** @brief Show thumbnails to switch and manipulate pages. */
- (void)showThumbnailView;

/** @brief set topToolbar item hide/show.
 *
 * @details Currently, if the itemTag is just one of following formats,
 *          {@link FS_TOPBAR_ITEM_BOOKMARK_TAG},
 *          {@link FS_TOPBAR_ITEM_BACK_TAG},
 *          {@link FS_TOPBAR_ITEM_MORE_TAG},
 *          {@link FS_TOPBAR_ITEM_SEARCH_TAG}
 *          For other unsupported itemTag, this function will do nothing change.
 *
 * @param[in]	itemTag	The item tag will show/hide.
 * @param[in]	isHidden The item show/hide .
 *
 */
-(void)setTopToolbarItemHiddenWithTag:(NSUInteger)itemTag hidden:(BOOL)isHidden;
@end

NS_ASSUME_NONNULL_END

#endif /* UIExtensionsManager_h */
