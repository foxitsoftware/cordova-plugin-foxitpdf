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

#import <UIKit/UIKit.h>
#import "PropertyBar.h"

@class SignatureView;
@class AnnotationSignature;
@class UIExtensionsManager;
@protocol IPropertyValueChangedListener;

typedef void (^SignatureCancelHandler)(void);
typedef void (^SignatureSaveHandler)(void);

@interface SignatureViewController : UIViewController <IPropertyValueChangedListener>

@property (nonatomic,strong) AnnotationSignature *currentSignature;
@property (nonatomic,copy) SignatureCancelHandler cancelHandler;
@property (nonatomic,copy) SignatureSaveHandler saveHandler;
@property (nonatomic,weak) UIExtensionsManager* extensionsManager;
@property (nonatomic,assign) BOOL isFieldSig;
@property (nonatomic,assign) BOOL isShowed;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;

@end
