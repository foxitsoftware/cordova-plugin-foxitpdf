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

#ifndef UIExtensionsManager_h
#define UIExtensionsManager_h

//to disable nullability warnings
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

#import <UIKit/UIKit.h>
#import <FoxitRDK/FSPDFViewControl.h>
#import <FoxitRDK/FSPDFObjC.h>

@class FSPDFReader;

/** @brief Customized annotation type on application level. */
#define e_annotArrowLine    99
#define e_annotInsert      101

/** @brief These tools are automatically activated or deactivated by extensions manager. */
#define Tool_Select @"Tool_Select"
#define Tool_Note @"Tool_Note"
#define Tool_Markup @"Tool_Markup"
#define Tool_Shape @"Tool_Shape"
#define Tool_Freetext @"Tool_Freetext"
#define Tool_Pencil @"Tool_Pencil"
#define Tool_Eraser @"Tool_Eraser"
#define Tool_Line @"Tool_Line"
#define Tool_Stamp @"Tool_Stamp"
#define Tool_Insert @"Tool_Insert"
#define Tool_Replace @"Tool_Replace"
#define Tool_Attachment @"Tool_Attachment"
#define Tool_Signature @"Tool_Signature"

/** @brief Nofitication center messeage, will notify when reading bookmark is updated from panel.*/
#define UPDATEBOOKMARK @"UpdateBookmark"

@protocol IModule <NSObject>
-(NSString*)getName;
@end

/** @brief Annotation event listener. */
@protocol IAnnotEventListener <NSObject>
@optional
/** @brief Triggered when the annotation is added. */
- (void)onAnnotAdded:(FSPDFPage* )page annot:(FSAnnot*)annot;
/** @brief Triggered when the annotation is deleted. */
- (void)onAnnotDeleted:(FSPDFPage* )page annot:(FSAnnot*)annot;
/** @brief Triggered when the annotation is modified. */
- (void)onAnnotModified:(FSPDFPage* )page annot:(FSAnnot*)annot;
/** @brief Triggered when the annotation is selected. */
- (void)onAnnotSelected:(FSPDFPage* )page annot:(FSAnnot*)annot;
/** @brief Triggered when the annotation is deselected. */
- (void)onAnnotDeselected:(FSPDFPage* )page annot:(FSAnnot*)annot;
@end

/** @brief A listener for annotation property bar. */
@protocol IAnnotPropertyListener <NSObject>
@optional
/** @brief Triggered when the color of annotation is changed. */
- (void)onAnnotColorChanged:(unsigned int)color annotType:(enum FS_ANNOTTYPE)annotType;
/** @brief Triggered when the opacity of annotation is changed. */
- (void)onAnnotOpacityChanged:(unsigned int)opacity annotType:(enum FS_ANNOTTYPE)annotType;
- (void)onAnnotLineWidthChanged:(unsigned int)lineWidth annotType:(enum FS_ANNOTTYPE)annotType;
- (void)onAnnotFontNameChanged:(NSString*)fontName annotType:(enum FS_ANNOTTYPE)annotType;
- (void)onAnnotFontSizeChanged:(unsigned int)fontSize annotType:(enum FS_ANNOTTYPE)annotType;
- (void)onAnnotIconChanged:(int)icon annotType:(enum FS_ANNOTTYPE)annotType;
@end

/** @brief A Tool event listener. */
@protocol IToolEventListener <NSObject>
@required
/** @brief Triggered when the current tool handler of extensions manager is changed. */
- (void)onToolChanged:(NSString*)lastToolName CurrentToolName:(NSString*)toolName;
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
@property (nonatomic, assign)enum FS_ANNOTTYPE type;
/** @brief Get the tool name. */
-(NSString*)getName;
/** @brief If the tool handler is enabled. */
-(BOOL)isEnabled;
/** @brief If the tool handler is activated. */
-(void)onActivate;
/** @brief If the tool handler is deactivated. */
-(void)onDeactivate;

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
- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet*)touches withEvent:(UIEvent*)event;
/** @brief Touches moved on the specified page. */
- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event;
/** @brief Touches ended on the specified page. */
- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event;
/** @brief Touches cancelled on the specified page. */
- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event;
@optional
/** @brief Drawing event on the specified page. */
-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context;
@end

/** @brief The annotation handler, it should handle the operations on the specified annotation. */
@protocol IAnnotHandler <NSObject>
/** brief Get the annotation type */
-(enum FS_ANNOTTYPE)getType;
/** brief Can hit the annotation at specified point. */
-(BOOL)isHitAnnot:(FSAnnot*)annot point:(FSPointF*)point;
/** brief When the annotation is selected. */
-(void)onAnnotSelected:(FSAnnot*)annot;
/** brief When the annotation is deselected. */
-(void)onAnnotDeselected:(FSAnnot*)annot;
/** brief Add a new annotation to a specified page. It's equal to the following one with the param addUndo YES. */
-(void)addAnnot:(FSAnnot*)annot;
/** brief Add a new annotation to a specified page, undo/redo will be supported if the param addUndo is YES. */
-(void)addAnnot:(FSAnnot*)annot addUndo:(BOOL)addUndo;
/** brief Modify an annotation. It's equal to the following one with the param addUndo YES. */
-(void)modifyAnnot:(FSAnnot*)annot;
/** brief Modify an annotation, undo/redo will be supported if the param addUndo is YES. */
-(void)modifyAnnot:(FSAnnot*)annot addUndo:(BOOL)addUndo;
/** brief Remove an annotation. It's equal to the following one with the param addUndo YES. */
-(void)removeAnnot:(FSAnnot*)annot;
/** brief Remove an annotation, undo/redo will be supported if the param addUndo is YES. */
-(void)removeAnnot:(FSAnnot*)annot addUndo:(BOOL)addUndo;

#pragma mark - PageView Gesture+Touch
/** @brief Long press gesture on the specified page. */
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot*)annot;
/** @brief Tap gesture on the specified page. */
- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot*)annot;
/** @brief Pan gesture on the specified page. */
- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot*)annot;
/** @brief Should being gesture on the specified page. */
- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot*)annot;
/** @brief Touches began on the specified page. */
- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet*)touches withEvent:(UIEvent*)event annot:(FSAnnot*)annot;
/** @brief Touches moved on the specified page. */
- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot*)annot;
/** @brief Touches ended on the specified page. */
- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot*)annot;
/** @brief Touches cancelled on the specified page. */
- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot*)annot;
@optional
/** @brief Drawing event on the specified page. */
-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context annot:(FSAnnot*)annot;
/** @brief Changed property event on the specified annot. */
-(void)onAnnot:(FSAnnot*)annot property:(long)property changedFrom:(NSValue*)oldValue to:(NSValue*)newValue;
@end

/** @brief The undo/redo listener. */
@protocol IFSUndoEventListener <NSObject>
/** @brief Triggered after the state of undo or redo changed. */
-(void)onUndoChanged;
@end

/** @brief The undo/redo handler,it should handle the operations about undo/redo. */
@interface FSUndo : NSObject
/** @brief Check whether can undo or not. */
-(BOOL)canUndo;
/** @brief Check whether can redo or not. */
-(BOOL)canRedo;
/** @brief Undo the previous operation. */
-(void)undo;
/** @brief Redo the previous operation. */
-(void)redo;
/** @brief Clear all the recorded undo/redo operations. */
-(void)clearUndoRedo;
@end

/** @brief The UI extensions mangager which has included the default implementation of text selection tool, annotation tools... and so on. */
@interface UIExtensionsManager : FSUndo<FSPDFUIExtensionsManager, IDocEventListener, IPageEventListener, IRotationEventListener, IAnnotEventListener,IRecoveryEventListener>
/** @brief The PDF view control. */
@property (nonatomic, strong, readonly) FSPDFViewCtrl* pdfViewCtrl;
/** @brief The Current selected annotation. */
@property (nonatomic, strong) FSAnnot*  currentAnnot;
/** @brief Whether to allow to jump to link address when tap on the link annatation. */
@property (nonatomic, assign) BOOL enableLinks;
/** @brief Whether to allow to highlight links. */
@property (nonatomic, assign) BOOL enableHighlightLinks;
/** @brief Get/Set the hightlight color for links. */
@property (nonatomic, strong) UIColor* linksHighlightColor;
/** @brief Get/Set the hightlight color for text selection. */
@property (nonatomic, strong) UIColor* selectionHighlightColor;
/** @brief UIExtensionsManager had implemented a complete PDF reader with the default toolbars, navigation controller, ...etc. This is a quick way to get the complete pdf reader.
 *
 *  @note To get a complete reader, UIExtensionsManager must be initialized with configuration of "defaultReader" set to true.If it's not, nil will be returned.
 */
@property (nonatomic, strong, readonly) FSPDFReader* pdfReader;

/** @brief Intialize extensions manager with the pdf view control. */
-(id)initWithPDFViewControl:(FSPDFViewCtrl*)viewctrl;
/** @brief Intialize extensions manager with the pdf view control and specified configuration. 
 *  See uiextensions_config.json for an example.
 */
-(id)initWithPDFViewControl:(FSPDFViewCtrl*)viewctrl configuration:(NSData*)jsonConfigData;

#pragma mark - Toolhandler and AnnotHandler registration.
/** @brief Get the current tool handler by name, which is defined above Tool_XXX. */
-(id<IToolHandler>)getToolHandlerByName:(NSString*)name;
/** @brief Get the annotation handler by annotation type. */
-(id<IAnnotHandler>)getAnnotHandlerByType:(enum FS_ANNOTTYPE)type;
/** @brief Set the current tool handler.*/
-(void)setCurrentToolHandler:(id<IToolHandler>)toolHandler;
/** @brief Get the handler of current tool. */
-(id<IToolHandler>)getCurrentToolHandler;
/** @brief Register a tool handler. */
-(void)registerToolHandler:(id<IToolHandler>)toolHandler;
/** @brief Remove a tool handler. */
-(void)unregisterToolHandler:(id<IToolHandler>)toolHandler;
/** @brief Register an annotation handler. */
-(void)registerAnnotHandler:(id<IAnnotHandler>)annotHandler;
/** @brief Remove an annotation handler. */
-(void)unregisterAnnotHandler:(id<IAnnotHandler>)annotHandler;

#pragma mark - Tool and annotation event listeners.
/** @brief Register the annotation event listener. */
- (void)registerAnnotEventListener:(id<IAnnotEventListener>)listener;
/** @brief Unregister the annotation event listener. */
- (void)unregisterAnnotEventListener:(id<IAnnotEventListener>)listener;
/** @brief Register the tool event listener. */
- (void)registerToolEventListener:(id<IToolEventListener>)listener;
/** @brief Unregister the tool event listener. */
- (void)unregisterToolEventListener:(id<IToolEventListener>)listener;

#pragma mark - Undo/redo event listeners.
/** @brief Register the undo/redo event listener. */
-(void)registerUndoEventListener:(id<IFSUndoEventListener>)listener;
/** @brief Unregister the undo/redo event listener. */
-(void)unregisterUndoEventListener:(id<IFSUndoEventListener>)listener;

#pragma mark - Property bar of annoatation for setting/getting annotation color and opacity.
/** @brief Show the property bar to set annotation color and opacity. */
-(void)showProperty:(enum FS_ANNOTTYPE)annotType rect:(CGRect)rect inView:(UIView*)view;
/** @brief Get current setting annotation color from property bar. */
-(unsigned int)getPropertyBarSettingColor:(enum FS_ANNOTTYPE)annotType;
/** @brief Get current setting annotation opacity from property bar. */
-(unsigned int)getPropertyBarSettingOpacity:(enum FS_ANNOTTYPE)annotType;
/** @brief Register annotation property change event listener. */
-(void)registerAnnotPropertyListener:(id<IAnnotPropertyListener>)listener;
/** @brief Unregister annotation property change event listener. */
-(void)unregisterAnnotPropertyListener:(id<IAnnotPropertyListener>)listener;
/** @brief Show or hide the text searching bar on the UI main screen. It will appeare on the top of main screen. */
- (void)showSearchBar:(BOOL)show;
/** @brief Register the tool event listener. */
- (void)registerSearchEventListener:(id<ISearchEventListener>)listener;
/** @brief Unregister the tool event listener. */
- (void)unregisterSearchEventListener:(id<ISearchEventListener>)listener;

/** @brief Get current selected text. */
-(NSString*)getCurrentSelectedText;

/** @brief End form filling. */
-(void)stopFormFilling;
-(void)exitFormFilling;

- (void)showThumbnailView;

@end

#pragma clang diagnostic pop

#endif /* UIExtensionsManager_h */
