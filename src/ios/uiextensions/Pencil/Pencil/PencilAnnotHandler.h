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

@interface PencilAnnotHandler : NSObject<IAnnotHandler,IPropertyBarListener,IRotationEventListener,IGestureEventListener, IScrollViewEventListener, IAnnotPropertyListener>
{
    EDIT_ANNOT_RECT_TYPE _editType;
    
    float _maxWidth;
    float _minWidth;
    float _maxHeight;
    float _minHeight;
    float _topLimit;
    float _bottomLimit;
    float _leftLimit;
    float _rightLimit;
}
@property (nonatomic, assign) unsigned int color;
@property (nonatomic, assign) int opacity;
@property (nonatomic, assign) int lineWidth;
@property (nonatomic, retain) UIViewController *replyVC;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;

@end
