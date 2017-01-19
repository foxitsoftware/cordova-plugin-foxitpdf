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
#import "UIExtensionsManager.h"
#import "UIExtensionsManager+Private.h"

@protocol IAnnotHandler;
@protocol IGestureEventListener;
@protocol IPropertyBarListener;

/**@brief A text markup annotation handler to handle events between itself and the page. */
@interface MKAnnotHandler : NSObject<IAnnotHandler,UIPopoverControllerDelegate, IScrollViewEventListener,IGestureEventListener, IRotationEventListener, IPropertyBarListener>


@property (nonatomic, retain) UINavigationController *currentVC;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;

@end
