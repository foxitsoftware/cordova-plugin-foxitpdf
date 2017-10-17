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

#import "UIExtensionsManager+Private.h"
#import "UIExtensionsManager.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface FtAnnotHandler : NSObject <IAnnotHandler, UIPopoverControllerDelegate, IPropertyBarListener, IRotationEventListener, IGestureEventListener, IScrollViewEventListener, IAnnotPropertyListener> {
    UITextView *_textView;
    BOOL _isSaved;
    BOOL _keyboardShown;
    CGRect _originalRect;
}

@property (nonatomic, strong) NSObject *currentVC;
@property (nonatomic, strong) FSFreeText *editAnnot;

- (id)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager;

@end
