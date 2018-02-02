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

#import "../Thirdparties/TSAlertView/TSAlertView.h"
#import <UIKit/UIKit.h>

@class AlertView;

typedef void (^AlertViewButtonClickedHandler)(AlertView *alertView, NSInteger buttonIndex);

//a wrapper for UIAlertView to facilite callback. It handles:
//1. button click delegate
//2. NSLocalizedString

@interface AlertView : UIAlertView <UIAlertViewDelegate> {
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonClickHandler:(AlertViewButtonClickedHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;
- (id)initWithTitle:(NSString *)title message:(NSString *)message style:(UIAlertViewStyle)style buttonClickHandler:(AlertViewButtonClickedHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

@property (nonatomic, copy) AlertViewButtonClickedHandler buttonClickedHandler;
@property (nonatomic, assign) id outerDelegate;

@end

@class InputAlertView;

typedef void (^InputAlertViewButtonClickedHandler)(InputAlertView *alertView, NSInteger buttonIndex);

@interface InputAlertView : TSAlertView <TSAlertViewDelegate>

- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonClickHandler:(InputAlertViewButtonClickedHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

@property (nonatomic, copy) InputAlertViewButtonClickedHandler buttonClickedHandler;

@end
