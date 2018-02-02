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

#import "UIExtensionsManager+Private.h"
#import "UIExtensionsManager.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface ImageAnnotHandler : NSObject <IAnnotHandler, IRotationEventListener, IGestureEventListener, IScrollViewEventListener, IPropertyBarListener>

// 0.0~1.0
@property (nonatomic) CGFloat minImageWidthInPage;
@property (nonatomic) CGFloat maxImageWidthInPage;
@property (nonatomic) CGFloat minImageHeightInPage;
@property (nonatomic) CGFloat maxImageHeightInPage;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager;

@end
