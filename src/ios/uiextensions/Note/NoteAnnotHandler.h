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
#import <FoxitRDK/FSPDFViewControl.h>

@protocol IPropertyBarListener;
@protocol IRotationEventListener;
@protocol IGestureEventListener;
@class ReplyTableViewController;

/**@brief A note annotation handler to handle touches and gestures on tha note annotation. */
@interface NoteAnnotHandler : NSObject<IAnnotHandler,UIPopoverControllerDelegate,IPropertyBarListener,IRotationEventListener,IScrollViewEventListener,IGestureEventListener,IAnnotPropertyListener>

@property (nonatomic, retain) ReplyTableViewController *currentVC;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;
@end
