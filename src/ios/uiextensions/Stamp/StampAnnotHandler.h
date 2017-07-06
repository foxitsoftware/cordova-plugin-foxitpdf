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

#import <FoxitRDK/FSPDFViewControl.h>
#import "UIExtensionsManager.h"
#import "UIExtensionsManager+Private.h"

@interface StampAnnotHandler : NSObject<IAnnotHandler,IRotationEventListener,IGestureEventListener, IScrollViewEventListener, IPropertyBarListener>
{
    EDIT_ANNOT_RECT_TYPE _editType;
    float _minWidth;
    float _minHeight;
}

@property (nonatomic, assign) int stampIcon;
@property (nonatomic, strong) UIImage *annotImage;
@property (nonatomic, strong) UIViewController *replyVC;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;

@end
