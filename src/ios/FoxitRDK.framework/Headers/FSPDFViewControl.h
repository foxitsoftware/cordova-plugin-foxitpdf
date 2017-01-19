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

/**
 * @file	FSPDFViewControl.h
 * @details	Foxit has implemented an automatically recovering system when the pdf viewer control receives memory warning notification, which is considered as the viewer control will soon run out of memory(OOM).
 *          When this happens, the Foxit PDF SDK will try to restore to the latest reading status before OOM. However, if the user has modified/added/deleted something on PDF document,
 *          those will not be recovered by Foxit PDF SDK.
 *          OOM recovery could be disabled by setting the property 'shouldRecover' of viewer control to 'NO'.
 */

#import <UIKit/UIKit.h>
#import "FSPDFObjC.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

/**
 * @brief	Enumeration for PDF layout mode.
 * 
 * @details	Values of this enumeration should be used alone.
 */
typedef enum
{
	/** @brief	Unknown page mode. */
	PDF_LAYOUT_MODE_UNKNOWN = 0,
	/** @brief	Continuous page mode. */
	PDF_LAYOUT_MODE_CONTINUOUS,
	/** @brief	Single page mode. */
	PDF_LAYOUT_MODE_SINGLE,
	/** @brief	Facing mode. */
	PDF_LAYOUT_MODE_TWO,
	/** @brief	Thumbnail mode. */
	PDF_LAYOUT_MODE_MULTIPLE,
	/** @brief	Reflow mode. Currently, not supported. */
	PDF_LAYOUT_MODE_REFLOW
} PDF_LAYOUT_MODE;

/**
 * @brief	Enumeration for PDF display zoom mode.
 * 
 * @details	Values of this enumeration should be used alone.
 */
typedef enum
{
	/** @brief	Zoom mode: unknown. */
	PDF_DISPLAY_ZOOMMODE_UNKNOWN = 0,
	/** @brief	Zoom mode: fit page. */
	PDF_DISPLAY_ZOOMMODE_FITPAGE,
	/** @brief	Zoom mode: fit page width. */
	PDF_DISPLAY_ZOOMMODE_FITWIDTH,
	/** @brief	Zoom mode: fit page height. */
	PDF_DISPLAY_ZOOMMODE_FITHEIGHT
} PDF_DISPLAY_ZOOMMODE;

/** @brief	 Recovery event listener used when view control runs out of memory. */
@protocol IRecoveryEventListener <NSObject>
@optional
/** 
 * @brief	Triggered before recovering the view control.
 *
 * @return	None.
 */
- (void)onWillRecover;
/** 
 * @brief	Triggered after the view control has recovered from running out of memory.
 *
 * @return	None.
 */
- (void)onRecovered;
@end

/** @brief	Device rotation delegate. */
@protocol IRotationEventListener <NSObject>
@optional
/** 
 * @brief	Triggered when rotation begins. 
 *
 * @param[in]	toInterfaceOrientation      The UI interface orientation.
 * @param[in]	duration                    The Time duration.
 *
 * @return	None.
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
/** 
 * @brief	Triggered when animated rotation begins. 
 *
 * @param[in]	toInterfaceOrientation      The UI interface orientation.
 * @param[in]	duration                    The Time duration.
 *
 * @return	None.
 */
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
/** 
 * @brief	Triggered after rotation is done.
 *
 * @param[in]	fromInterfaceOrientation    The UI interface orientation.
 *
 * @return	None.
 */
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
@end

/** @brief	The PDF document event listener. */
@protocol IDocEventListener <NSObject>
@optional
/** 
 * @brief	Triggered when the document will be opened. 
 *
 * @return	None.
 */
- (void)onDocWillOpen;
/** 
 * @brief	Triggered when the document is opened. 
 *
 * @param[in]	document	PDF document instance which is opened.
 * @param[in]	error		Error code. Please refer to {@link FS_ERRORCODE::e_errSuccess FS_ERRORCODE::e_errXXX} values and it should be one of these values.
 *
 * @return	None.
 */
- (void)onDocOpened:(FSPDFDoc* )document error:(int)error;
/** 
 * @brief	Triggered when the document will be closed. 
 *
 * @param[in]	document	PDF document instance which will be closed.
 *
 * @return	None.
 */
- (void)onDocWillClose:(FSPDFDoc* )document;
/** 
 * @brief	Triggered when the document is closed. 
 *
 * @param[in]	document	PDF document instance which is closed.
 * @param[in]	error		Error code. Please refer to {@link FS_ERRORCODE::e_errSuccess FS_ERRORCODE::e_errXXX} values and it should be one of these values.
 *
 * @return	None.
 */
- (void)onDocClosed:(FSPDFDoc* )document error:(int)error;
/** 
 * @brief	Triggered when the document will be saved. 
 *
 * @param[in]	document	PDF document instance which will be saved.
 *
 * @return	None.
 */
- (void)onDocWillSave:(FSPDFDoc* )document;
/** 
 * @brief	Triggered when the document is saved. 
 *
 * @param[in]	document	PDF document instance which is saved.
 * @param[in]	error		Error code. Please refer to {@link FS_ERRORCODE::e_errSuccess FS_ERRORCODE::e_errXXX} values and it should be one of these values.
 *
 * @return	None.
 */
- (void)onDocSaved:(FSPDFDoc* )document error:(int)error;
@end

/** @brief	The page event listener. */
@protocol IPageEventListener <NSObject>
@optional
/** 
 * @brief	Triggered when current page is changed. 
 *
 * @param[in]	oldIndex		Old page index. Valid range: from 0 to (<i>count</i>-1).
 *								<i>count</i> is the page count.
 * @param[in]	currentIndex	Current page index. Valid range: from 0 to (<i>count</i>-1).
 *								<i>count</i> is the page count.
 *
 * @return	None.
 */
- (void)onPageChanged:(int)oldIndex currentIndex:(int)currentIndex;
/** 
 * @brief	Triggered when the page becomes visible. 
 *
 * @param[in]	index		Page index. Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *
 * @return	None.
 */
- (void)onPageVisible:(int)index;
/** 
 * @brief	Triggered when the page becomes invisible. 
 *
 * @param[in]	index		Page index. Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *
 * @return	None.
 */
- (void)onPageInvisible:(int)index;
/** 
 * @brief	Triggered by the page navigation or link jump.
 *
 * @return	None.
 */
- (void)onPageJumped;
@end

/** @brief	The page layout event listener. */
@protocol ILayoutEventListener <NSObject>
@required
/** 
 * @brief	Triggered when current page layout mode is changed.
 *
 * @param[in]	oldLayoutMode		Old layout mode. 
 *									Please refer to {@link PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_UNKNOWN PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_XXX} values and this should be one of these values.
 * @param[in]	newLayoutMode		New layout mode. 
 *									Please refer to {@link PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_UNKNOWN PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_XXX} values and this should be one of these values.
 *
 * @return	None.
 */
-(void)onLayoutModeChanged:(PDF_LAYOUT_MODE)oldLayoutMode newLayoutMode:(PDF_LAYOUT_MODE)newLayoutMode;
@end

/** @brief	The event listener for scroll view, which is the container of page views. */
@protocol IScrollViewEventListener <NSObject>
@optional
/** 
 * @brief	Triggered when any offset changes.
 *
 * @param[in]	scrollView      The scroll view that displays PDF pages.
 *
 * @return	None.
 */
- (void)onScrollViewDidScroll:(UIScrollView *)scrollView;
/** 
 * @brief	Triggered when any zoom scale changes.
 *
 * @param[in]	scrollView      The scroll view that displays PDF pages.
 *
 * @return	None.
 */
- (void)onScrollViewDidZoom:(UIScrollView *)scrollView;
/** 
 * @brief	Triggered when called on start of dragging (may require some time or distance to move).
 *
 * @param[in]	scrollView      The scroll view that displays PDF pages.
 *
 * @return	None.
 */
- (void)onScrollViewWillBeginDragging:(UIScrollView *)scrollView;
/** 
 * @brief	Triggered when called on finger up if the user dragged.
 *
 * @param[in]	scrollView      The scroll view that displays PDF pages.
 * @param[in]	decelerate      <b>YES</b> means it will continue moving afterwards, while <b>NO</b> means not.
 *
 * @return	None.
 */
- (void)onScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
/** 
 * @brief	Triggered when called on finger up as we are moving.
 *
 * @param[in]	scrollView      The scroll view that displays PDF pages.
 *
 * @return	None.
 */
- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)scrollView;
/** 
 * @brief	Triggered when called when scroll view grinds to a halt.
 *
 * @param[in]	scrollView      The scroll view that displays PDF pages.
 *
 * @return	None.
 */
- (void)onScrollViewDidEndDecelerating:(UIScrollView *)scrollView;
/** 
 * @brief	Triggered when called before the scroll view begins zooming its content.
 *
 * @param[in]	scrollView      The scroll view that displays PDF pages.
 *
 * @return	None.
 */
- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView;
/** 
 * @brief	Triggered when scale between minimum and maximum. called after any "bounce" animations.
 *
 * @param[in]	scrollView      The scroll view that displays PDF pages.
 *
 * @return	None.
 */
- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView;
@end

/** @brief	The gesture event listener. */
@protocol IGestureEventListener <NSObject>
@optional
/** 
 * @brief	Triggered on long press gesture.
 *
 * @param[in]	gestureRecognizer       The gesture recognizer.
 *
 * @return	<b>YES</b> means that this event has been handled by the event listener.
 *			<b>NO</b> means that the event listener did not handle this event.
 */
- (BOOL)onLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;
/** 
 * @brief	Triggered on the tap gesture.
 *
 * @param[in]	gestureRecognizer       The gesture recognizer.
 *
 * @return	<b>YES</b> means that this event has been handled by the event listener.
 *			<b>NO</b> means that the event listener did not handle this event.
 */
- (BOOL)onTap:(UITapGestureRecognizer *)gestureRecognizer;
/** 
 * @brief	Triggered on the pan gesture.
 *
 * @param[in]	gestureRecognizer       The gesture recognizer.
 *
 * @return	<b>YES</b> means that this event has been handled by the event listener.
 *			<b>NO</b> means that the event listener did not handle this event.
 */
- (BOOL)onPan:(UIPanGestureRecognizer *)gestureRecognizer;
/** 
 * @brief	Triggered when a gesture recognizer attempts to transition out of UIGestureRecognizerStatePossible.
 *
 * @param[in]	gestureRecognizer       The gesture recognizer.
 *
 * @return	<b>YES</b> means that this event has been handled by the event listener.
 *			<b>NO</b> means that the event listener did not handle this event.
 */
- (BOOL)onShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
@end

/** @brief	The draw event listener. */
@protocol IDrawEventListener <NSObject>
@required
/** 
 * @brief	Triggered when drawing on a specified page.
 *
 * @param[in]	pageIndex	Index of the specified page. Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 * @param[in]	context     The CGContext object.
 *
 * @return	None.
 */
- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context;
@end

/** @brief	The touch event listener. */
@protocol ITouchEventListener <NSObject>
@optional
/**
 * @brief	Triggered when the touches began.
 *
 * @param[in]	touches     A UITouch object represent touches event on the screen.
 * @param[in]	event       A UIEvent object represents an event in iOS.
 *
 * @return	<b>YES</b> means the touches has been handled successfully by extensions manager.
 *			<b>NO</b> means The extensions manager did not handle the touches.
 */
- (BOOL)onTouchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
/**
 * @brief	Triggered when the touches has moved.
 *
 * @param[in]	touches     A UITouch object represent touches event on the screen.
 * @param[in]	event       A UIEvent object represents an event in iOS.
 *
 * @return	<b>YES</b> means the touches has been handled successfully by extensions manager.
 *			<b>NO</b> means The extensions manager did not handle the touches.
 */
- (BOOL)onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
/**
 * @brief	Triggered when the touches has ended.
 *
 * @param[in]	touches     A UITouch object represent touches event on the screen.
 * @param[in]	event       A UIEvent object represents an event in iOS.
 *
 * @return	<b>YES</b> means the touches has been handled successfully by extensions manager.
 *			<b>NO</b> means The extensions manager did not handle the touches.
 */
- (BOOL)onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
/**
 * @brief	Triggered when the touches has been canceled.
 *
 * @param[in]	touches     A UITouch object represent touches event on the screen.
 * @param[in]	event       A UIEvent object represents an event in iOS.
 *
 * @return	<b>YES</b> means the touches has been handled successfully by extensions manager.
 *			<b>NO</b> means The extensions manager did not handle the touches.
 */
- (BOOL)onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
@end

/** @brief	The  UI extensions manager. */
@protocol FSPDFUIExtensionsManager <IGestureEventListener, IDrawEventListener, ITouchEventListener>
@optional
/**
 * @brief	Whether to draw the annotation.
 *
 * @param[in]	annot     An annotation.
 *
 * @return <b>YES</b> means draw the annotation, while <b>NO</b> means not.
 */
- (BOOL)shouldDrawAnnot:(FSAnnot *)annot;
@end

/** 
 * @brief	Foxit PDF view control for viewing/editing/saving the PDF file. 
 *
 * @details	There are three coordinate systems for PDF viewer control:
 *			<ul>
 *			<li>
 *			Display View CoordiNate System: Which is the displaying area of view control, all the pages will be displayed on the display view. 
 *											Basically it is same frame as the PDF viewer control itself.
 *			</li>
 *			<li>
 *			Page View Coordinate System: Each PDF page is displayed on a UIView, so that it is same as UIView coordinate system.
 *			</li>
 *			<li>
 *			PDF Coordinate System: The PDF page coordinate system.
 *			</li>
 *			</ul>
 */
@interface FSPDFViewCtrl : UIView <IRotationEventListener> {
}
/** @brief	The UI extensions manager. UI extensions manager will implement the UI related features such as annotation, outline.*/
@property (nonatomic, retain) id<FSPDFUIExtensionsManager> extensionsManager;
/** @brief	The current PDF document. */
@property (nonatomic, retain) FSPDFDoc*  currentDoc;
/** @brief	If current reading mode is night mode: <b>YES</b> means in night mode, while <b>NO</b> means not in night mode. */
@property (nonatomic, assign) BOOL isNightMode;
/** @brief	Get or set position of display view from the bottom of control. */
@property (nonatomic, assign) int bottomOffset;
/** @brief	Whether or not should view control recover itself when runs out of memory. Default is YES. */
@property (nonatomic, assign) BOOL shouldRecover;

#pragma mark - View control Initialize
/** 
 * @brief	Initialize the view control.
 *
 * @param[in]	frame	
 *
 * @return	The view control instance.
 */
- (instancetype)initWithFrame:(CGRect)frame;

#pragma mark - Events
/** 
 * @brief	Register a document event listener.
 *
 * @param[in]	listener	A document event listener to be registered.
 *
 * @return	None.
 */
- (void)registerDocEventListener:(id<IDocEventListener>)listener;
/** 
 * @brief	Register a page event listener.
 *
 * @param[in]	listener	A page event listener to be registered.
 *
 * @return	None.
 */
- (void)registerPageEventListener:(id<IPageEventListener>)listener;
/** 
 * @brief	Register an event listener for scrolling page views.
 *
 * @param[in]	listener	An event listener for scrolling page views to be registered.
 *
 * @return	None.
 */
- (void)registerScrollViewEventListener:(id<IScrollViewEventListener>)listener;
/** 
 * @brief	Register an event listener for page layout.
 *
 * @param[in]	listener	An event listener for page layout to be registered.
 *
 * @return	None.
 */
- (void)registerLayoutChangedEventListener:(id<ILayoutEventListener>)listener;
/** 
 * @brief	Register an event listener for gesture.
 *
 * @details	If method implementation of protocol returns <b>YES</b>, then the next listener will not receive the method call. 
 *
 * @param[in]	listener	An event listener for gesture to be registered.
 *
 * @return	None.
 */
- (void)registerGestureEventListener:(id<IGestureEventListener>)listener;
/** 
 * @brief	Register an event listener for drawing page.
 *
 * @param[in]	listener	An event listener for drawing page to be registered.
 *
 * @return	None.
 */
- (void)registerDrawEventListener:(id<IDrawEventListener>)listener;
/** 
 * @brief	Register an event listener for recovery from running out of memory.
 *
 * @param[in]	listener	An event listener for recovery from running out of memory to be registered.
 *
 * @return	None.
 */
- (void)registerRecoveryEventListener:(id<IRecoveryEventListener>)listener;
/** 
 * @brief	Unregister an event listener for recovery from running out of memory.
 *
 * @param[in]	listener	An event listener for recovery from running out of memory to be unregistered.
 *
 * @return	None.
 */
- (void)unregisteRecoveryEventListener:(id<IRecoveryEventListener>)listener;
/** 
 * @brief	Unregister an event listener for drawing page.
 *
 * @param[in]	listener	An event listener for drawing page to be unregistered.
 *
 * @return	None.
 */
- (void)unregisterDrawEventListener:(id<IDrawEventListener>)listener;
/** 
 * @brief	Unregister an event listener for gesture.
 *
 * @param[in]	listener	An event listener for gesture to be unregistered.
 *
 * @return	None.
 */
- (void)unregisterGestureEventListener:(id<IGestureEventListener>)listener;
/** 
 * @brief	Unregister a document event listener.
 *
 * @param[in]	listener	A document event listener to be unregistered.
 *
 * @return	None.
 */
- (void)unregisterDocEventListener:(id<IDocEventListener>)listener;
/** 
 * @brief	Unregister a page event listener.
 *
 * @param[in]	listener	A page event listener to be unregistered.
 *
 * @return	None.
 */
- (void)unregisterPageEventListener:(id<IPageEventListener>)listener;
/** 
 * @brief	Unregister an event listener for scrolling page views.
 *
 * @param[in]	listener	An event listener for scrolling page views to be unregistered.
 *
 * @return	None.
 */
- (void)unregisterScrollViewEventListener:(id<IScrollViewEventListener>)listener;
/** 
 * @brief	Unregister an event listener for page layout.
 *
 * @param[in]	listener	An event listener for page layout to be unregistered.
 *
 * @return	None.
 */
- (void)unregisterLayoutChangedEventListener:(id<ILayoutEventListener>)listener;

#pragma mark - Open/Close/Save Document
/** 
 * @brief	Set the PDF document object to view control, then open the document.
 *
 * @param[in]	doc		A PDF document object.
 *
 * @return	None.
 */
- (void)setDoc:(FSPDFDoc*)doc;
/** 
 * @brief	Get the current PDF document object from view control
 *
 * @return	Current PDF document object.
 */
- (FSPDFDoc*)getDoc;
/** 
 * @brief	Open PDF document from a specified PDF file path.
 *
 * @param[in]	filePath	A PDF file full path.
 * @param[in]	password	The password string, used to load the PDF document content. It can be either user password or owner password.
 *							Set it to <b>nil</b> if the password is unknown.
 * @param[in]   completion  The callback will be called when current document object becomes available or the view control fail to open the document.
 *
 * @return	None.
 */
- (void)openDoc:(NSString*)filePath password:(NSString*)password completion:(void(^)(enum FS_ERRORCODE error))completion;
/** 
 * @brief	Open PDF document from a memory buffer.
 *
 * @param[in]	buffer		A memory buffer, containing the whole PDF file data.
 * @param[in]	password	The password string, used to load the PDF document content. It can be either user password or owner password.
 *							Set it to <b>nil</b> if the password is unknown.
 * @param[in]   completion  The callback will be called when document becomes available or fail to open the document.
 *
 * @return	None.
 */
- (void)openDocFromMemory:(NSData *)buffer password:(NSString*)password completion:(void(^)(enum FS_ERRORCODE error))completion;
/** 
 * @brief	Close the document.
 *
 * @param[in]	cleanup		A callback function to clean up caller managed resources.
 *
 * @return	None.
 */
- (void)closeDoc:(void (^)())cleanup;
/** 
 * @brief	Save the document to a specified file path with saving flag.
 *
 * @param[in]	filePath	File path for the new saved PDF file.
 * @param[in]	flag		Document saving flags. 
 *							Please refer to {@link FS_SAVEFLAGS::e_saveFlagNormal FS_SAVEFLAGS::e_saveFlagXXX} values 
 *							and this can be one or combination of these values.
 *
 * @return	<b>YES</b> means the saving is successfully finished, while <b>NO</b> means failure.
 */
- (BOOL)saveDoc:(NSString*)filePath flag:(int)flag;

#pragma mark - Get Page
/** 
 * @brief	Get the page count of PDF document.
 *
 * @return	The count of page.
 */
- (int)getPageCount;
/** 
 * @brief	Get current page index.
 *
 * @return	Index of current page, starting from 0.
 */
- (int)getCurrentPage;
/** 
 * @brief	Get the page index at the specified point, in display view space.
 *
 * @param[in]	displayViewPt	Point in display view space.
 *
 * @return	Page index, starting from 0.
 */
- (int)getPageIndex:(CGPoint)displayViewPt;
/** 
 * @brief	Get the visible pages in current view control.
 *
 * @details	This method works with layout mode {@link PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_CONTINUOUS} and {@link PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_SINGLE}.
 *
 * @return	NSNumber array of visible pages' indexes.
 */
- (NSMutableArray*)getVisiblePages;
/** 
 * @brief	Check whether a specified page is visible or not.
 *
 * @details	This method works with layout mode {@link PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_CONTINUOUS} and {@link PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_SINGLE}.
 *
 * @param[in]	pageIndex		Index of the specified page. Valid range: from 0 to (<i>count</i>-1).
 *								<i>count</i> is the page count.
 *
 * @return	<b>YES</b> means the specified page is visible.
 *			<b>NO</b> means the specified page is invisible.
 */
- (BOOL)isPageVisible:(int)pageIndex;

#pragma mark - Page Navigation
/** 
 * @brief	Go to a specified page. 
 *
 * @param[in]	index			Page index. Valid range: from 0 to (<i>count</i>-1).
 *								<i>count</i> is the page count.
 * @param[in]	animated		<b>YES</b> means to use animation effects.
 *								<b>NO</b> means not to use animation effects.
 *
 * @return	<b>YES</b> means succeed.
 *			<b>NO</b> means failed.
 */
- (BOOL)gotoPage:(int)index animated:(BOOL)animated;
/** 
 * @brief	Go to a specified page, then move to a specified position in page. 
 *
 * @param[in]	index			Page index. Valid range: from 0 to (<i>count</i>-1).
 *								<i>count</i> is the page count.
 * @param[in]	point			Specified position.
 * @param[in]	animated		<b>YES</b> means to use animation effects.
 *								<b>NO</b> means not to use animation effects.
 *
 * @return	<b>YES</b> means succeed.
 *			<b>NO</b> means failed.
 */
- (BOOL)gotoPage:(int)index withDocPoint:(FSPointF*)point animated:(BOOL)animated;
/** 
 * @brief	Go to the first page. 
 *
 * @param[in]	animated		<b>YES</b> means to use animation effects.
 *								<b>NO</b> means not to use animation effects.
 *
 * @return	<b>YES</b> means succeed.
 *			<b>NO</b> means failed.
 */
- (BOOL)gotoFirstPage:(BOOL)animated;
/** 
 * @brief	Go to the last page. 
 *
 * @param[in]	animated		<b>YES</b> means to use animation effects.
 *								<b>NO</b> means not to use animation effects.
 *
 * @return	<b>YES</b> means succeed.
 *			<b>NO</b> means failed.
 */
- (BOOL)gotoLastPage:(BOOL)animated;
/** 
 * @brief	Go to the next page. 
 *
 * @param[in]	animated		<b>YES</b> means to use animation effects.
 *								<b>NO</b> means not to use animation effects.
 *
 * @return	<b>YES</b> means succeed.
 *			<b>NO</b> means failed.
 */
- (BOOL)gotoNextPage:(BOOL)animated;
/** 
 * @brief	Go to the previous page. 
 *
 * @param[in]	animated		<b>YES</b> means to use animation effects.
 *								<b>NO</b> means not to use animation effects.
 *
 * @return	<b>YES</b> means succeed.
 *			<b>NO</b> means failed.
 */
- (BOOL)gotoPrevPage:(BOOL)animated;
/** 
 * @brief	Check if there it is a page view in the preceding of current page view on the page navigation stack.
 *
 * @details	PDF view control keeps a stack to track navigation on all pages.
 *
 * @return	<b>YES</b> means there is a previous page view.
 *			<b>NO</b> means there is no previous page view.
 */
- (BOOL)hasPrevView;
/** 
 * @brief	Check if there it is a page view next to the current page view on the page navigation stack.
 *
 * @details	PDF view control keeps a stack to track navigation on all pages.
 *
 * @return	<b>YES</b> means there is a next page view.
 *			<b>NO</b> means there is no next page view.
 */
- (BOOL)hasNextView;
/** 
 * @brief	Go to the previous view.
 *
 * @param[in]	animated		<b>YES</b> means to use animation effects.
 *								<b>NO</b> means not to use animation effects.
 * @return	None.
 */
- (void)gotoPrevView:(BOOL)animated;
/** 
 * @brief	Go to the next view.
 *
 * @param[in]	animated		<b>YES</b> means to use animation effects.
 *								<b>NO</b> means not to use animation effects.
 * @return	None,
 */
- (void)gotoNextView:(BOOL)animated;

#pragma mark - Zoom
/** 
 * @brief	Get the zoom level.Valid range: from 1.0 to 10.0.
 *
 * @return	Zoom level.
 */
- (float)getZoom;
/** 
 * @brief	Set the zoom level.
 *
 * @param[in]	zoom	New zoom level.Valid range: from 1.0 to 10.0.
 *
 * @return	None.
 */
- (void)setZoom:(float)zoom;
/** 
 * @brief	Zoom page from the specified position.
 *
 * @param[in]	zoom	New zoom level.
 * @param[in]	origin	A specified position, in display view space.
 *
 * @return	None.
 */
- (void)setZoom:(float)zoom origin:(CGPoint)origin;
/** 
 * @brief	Set the zoom mode.
 *
 * @param[in]	zoomMode	New zoom mode.
 *
 * @return	None.
 */
- (void)setZoomMode:(PDF_DISPLAY_ZOOMMODE)zoomMode;

#pragma mark - Display mode
/** 
 * @brief	Get the page layout mode.
 *
 * @return	Page layout mode.
 *			Please refer to {@link PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_UNKNOWN PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_XXX} values and it would be one of these values.
 */
- (PDF_LAYOUT_MODE)getPageLayoutMode;
/** 
 * @brief	Set the page layout mode.
 *
 * @param[in]	mode	Page layout mode.
 *						Please refer to {@link PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_UNKNOWN PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_XXX} values and it should be one of these values. 
 *						{@link PDF_LAYOUT_MODE::PDF_LAYOUT_MODE_UNKNOWN} will not work.
 *
 * @return	None.
 */
- (void)setPageLayoutMode:(PDF_LAYOUT_MODE)mode;

#pragma mark - Viewer preference
/** 
 * @brief	Set background color of viewer.
 *
 * @param[in]	color		New background color.
 *
 * @return	None.
 */
- (void)setBackgroundColor:(UIColor*)color;

#pragma mark - Viewer properties
/** 
 * @brief	Get the horizontal scroll position.
 *
 * @return	Horizontal scroll position.
 */
- (double)getHScrollPos;
/** 
 * @brief	Get the vertical scroll position.
 *
 * @return	Vertical scroll position.
 */
- (double)getVScrollPos;
/** 
 * @brief	Set the horizontal scroll position.
 *
 * @param[in]	pos         New horizontal scroll position.
 * @param[in]	animated	<b>YES</b> means to use animation effects.
 *							<b>NO</b> means not to use animation effects.
 *
 * @return	None.
 */
- (void)setHScrollPos: (double)pos animated:(BOOL)animated;
/** 
 * @brief	Set the vertical scroll position.
 *
 * @param[in]	pos         New vertical scroll position.
 * @param[in]	animated	<b>YES</b> means to use animation effects.
 *							<b>NO</b> means not to use animation effects.
 *
 * @return	None.
 */
- (void)setVScrollPos: (double)pos animated:(BOOL)animated;
/** 
 * @brief	Get the maximum horizontal scroll range.
 *
 * @return	Horizontal scroll range.
 */
- (double)getHScrollRange;
/** 
 * @brief	Get the maximum vertical scroll range.
 *
 * @return	Vertical scroll range.
 */
- (double)getVScrollRange;

#pragma mark - Viewer dimension
/** 
 * @brief	Get the width of the display view.
 *
 * @return	Width of the display view.
 */
- (float)getDisplayViewWidth;
/** 
 * @brief	Get the height of the display view.
 *
 * @return	Height of the display view.
 */
- (float)getDisplayViewHeight;
/** 
 * @brief	Get the width of a specified page view.
 *
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *							The page specified by this index should be visible.
 *
 * @return	Width of the specified page view.
 */
- (float)getPageViewWidth:(int)pageIndex;
/** 
 * @brief	Get the height of a specified page view.
 *
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
*							The page specified by this index should be visible.
 *
 * @return	Height of the specified page view.
 */
- (float)getPageViewHeight:(int)pageIndex;
/** 
 * @brief	Get the display view.
 *
 * @return	Display view.
 */
- (UIView*)getDisplayView;
/** 
 * @brief	Get the page view by page index. 
 *
 * @details	Page view is used to draw PDF page content and annotations.
 *
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.<br>
 *							The page specified by this index should be visible.
 *
 * @return	The page UI view.
 */
- (UIView*)getPageView:(int)pageIndex;
/**
 * @brief	Get the overlay view on the page, specified by page index. 
 *
 * @details	Overlay view is on top of the page view，visual effects such as the highlight on text, will be drawn on it.
 *			To draw onto the overlay view, IDrawEventListener should be registered first.
 *
 * @param[in]	pageIndex	Page index. Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count. <br>
 *							The page specified by this index should be visible.
 *
 * @return	The overlay UI view.
 */
- (UIView*)getOverlayView:(int)pageIndex;

#pragma mark - Coordinate Conversion
/** 
 * @brief	Convert the page view rectangle to display view coordination.
 *
 * @param[in]	rect        The rectangle on page view, in page view coordinate.
 * @param[in]	pageIndex   Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *                          The specified page should be visible.
 *
 * @return	Rectangle on display page view.
 */
- (CGRect)convertPageViewRectToDisplayViewRect:(CGRect)rect pageIndex:(int)pageIndex;
/** 
 * @brief	Convert the display view rectangle to page view coordination.
 *
 * @param[in]	rect        The rectangle on display view, in display view coordinate.
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
*                          The specified page should be visible.
 *
 * @return	Rectangle on page view.
 */
- (CGRect)convertDisplayViewRectToPageViewRect:(CGRect)rect pageIndex:(int)pageIndex;
/** 
 * @brief	Convert the display view point to page view point.
 *
 * @param[in]	point		The point on the display view, in display view coordinate.
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *                          The specified page should be visible.
 *
 * @return	Point on page view.
 */
- (CGPoint)convertDisplayViewPtToPageViewPt:(CGPoint)point pageIndex:(int)pageIndex;
/** 
 * @brief	Convert the page view point to display view point.
 *
 * @param[in]	point       The point on the page view, in page view coordinate.
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *                          The specified page should be visible.
 *
 * @return	Point on display page view.
 */
- (CGPoint)convertPageViewPtToDisplayViewPt:(CGPoint)point pageIndex:(int)pageIndex;
/** 
 * @brief	Convert the PDF page point to page view point.
 *
 * @param[in]	point		The point on the PDF Page, in PDF coordinate.
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *                          The specified page should be visible.
 *
 * @return	Point on page view.
 */
- (CGPoint)convertPdfPtToPageViewPt:(FSPointF*)point pageIndex:(int)pageIndex;
/** 
 * @brief	Convert the page view point to PDF page point.
 *
 * @param[in]	point       The point on the page view, in page view coordinate.
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *                          The specified page should be visible.
 *
 * @return	Point on PDF page.
 */
- (FSPointF*)convertPageViewPtToPdfPt:(CGPoint)point pageIndex:(int)pageIndex;
/** 
 * @brief	Convert the PDF rectangle to page view rectangle.
 *
 * @param[in]	rect		The rectangle on the PDF page, in pdf coordinate.
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *                          The specified page should be visible.
 *
 * @return	Page view rectangle.
 */
- (CGRect)convertPdfRectToPageViewRect:(FSRectF *)rect pageIndex:(int)pageIndex;
/** 
 * @brief	Convert the page view rectangle to PDF rectangle.
 *
 * @param[in]	rect        The rectangle on page view, in page view coordinate.
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *                          The specified page should be visible.
 *
 * @return	PDF rectangle.
 */
- (FSRectF *)convertPageViewRectToPdfRect:(CGRect)rect pageIndex:(int)pageIndex;
/** 
 * @brief	Get the display matrix of a specified page, which transforms from PDF coordinate to page view coordinate.
 *
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *                          The specified page should be visible.
 *
 * @return	Display matrix.
 */
- (FSMatrix *)getDisplayMatrix:(int)pageIndex;

#pragma mark - Refresh
/** 
 * @brief	Refresh a specified rectangle area on page, in page view coordinate.
 *
 * @param[in]	rect        The rectangle are on page, in page view coordinate.
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *
 * @return	None.
 */
- (void)refresh:(CGRect)rect pageIndex:(int)pageIndex;
/**
 * @brief	Refresh a specified rectangle area on page, in page view coordinate.
 *
 * @param[in]	rect        The rectangle are on page, in page view coordinate.
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 * @param[in]   needRender  If YES, will render the specified PDF page, then refresh the overlay view; if NO, will refresh the overlay view only.
 *
 * @return	None.
 */
- (void)refresh:(CGRect)rect pageIndex:(int)pageIndex needRender:(BOOL)needRender;
/** 
 * @brief	Refresh a specified page view.
 *
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 *
 * @return	None.
 */
- (void)refresh:(int)pageIndex;
/**
 * @brief	Refresh a specified page view.
 *
 * @param[in]	pageIndex	Page index.Valid range: from 0 to (<i>count</i>-1).
 *							<i>count</i> is the page count.
 * @param[in]   needRender  If YES, will render the specified PDF page, then refresh the overlay view; if NO, will refresh the overlay view only.
 *
 * @return	None.
 */
- (void)refresh:(int)pageIndex needRender:(BOOL)needRender;
/** 
 * @brief	Refresh the display view.
 *
 * @return	None.
 */
- (void)refresh;

/** 
 * @brief	Do the recovering when Foxit PDF SDK runs out of memory.
 *
 * @details	Foxit PDF SDK will call this method automatically. 
 *			Caller should use it carefully, current reading status will be restored, but all the editing to document won't be 
 *          restored.
 *
 * @return	None.
 */
+ (void)recoverForOOM;

@end

#pragma clang diagnostic pop

