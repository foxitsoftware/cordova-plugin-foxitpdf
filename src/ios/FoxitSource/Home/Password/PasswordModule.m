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
#import "AppDelegate.h"
#import "PasswordModule.h"
#import "MvMenuItem.h"
#import "MenuGroup.h"
#import "AppDelegate.h"


@interface PasswordModule() <TSAlertViewDelegate>
@property (nonatomic, copy) PromptNeedPasswordCallback passwordHandler;
@property (nonatomic, retain) TSAlertView *currentAlertView;
@end


@implementation PasswordModule

- (id)init
{
	if (self = [super init]) {
        self.passwordHandler = nil;
        self.inputPassword = nil;
    }
    return self;
}

#pragma mark - TSAlertViewDelegate

- (void)alertView:(TSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	TSAlertView *tsAlertView = (TSAlertView *)alertView;
	double delayInSeconds = .1;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	
	if (alertView.tag == 2) {
		if (buttonIndex == 1) {
			NSString *password = tsAlertView.inputTextField.text;
			self.inputPassword = password;
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
				if (self.passwordHandler) {
					_passwordHandler(YES, password);
				}
			});
		} else {
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
				if (self.passwordHandler) {
                    self.inputPassword = nil;
					_passwordHandler(NO, nil);
				}
			});
		}
        [[NSNotificationCenter defaultCenter] removeObserver:self];
	}
}

- (void)promptWithTitle:(NSString*)title callback:(PromptNeedPasswordCallback)callback
{
    self.passwordHandler = callback;
	dispatch_async(dispatch_get_main_queue(), ^{
		TSAlertView* alertView = [[[TSAlertView alloc] init] autorelease];
        alertView.title = title;
        self.currentAlertView = alertView;
		[alertView addButtonWithTitle:NSLocalizedString(@"kCancel", nil)];
		[alertView addButtonWithTitle:NSLocalizedString(@"kOK", nil)];
		alertView.style = TSAlertViewStyleInputText;
		alertView.buttonLayout = TSAlertViewButtonLayoutNormal;
		alertView.usesMessageTextView = NO;
		alertView.inputTextField.secureTextEntry = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputTextFieldChange:) name:UITextFieldTextDidChangeNotification object:alertView.inputTextField];
		alertView.delegate = self;
		alertView.tag = 2;  // open password
        UIButton *sureBtn = alertView.buttons.lastObject;
        sureBtn.enabled = NO;
        [sureBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
		[alertView show];
	});
}

- (void)inputTextFieldChange:(NSNotification *)aNotification
{
    if ([self.currentAlertView.inputTextField isEqual:aNotification.object]) {
        UIButton *sureBtn = self.currentAlertView.buttons.lastObject;
        if (((UITextField *)aNotification.object).text.length != 0) {
            sureBtn.enabled = YES;
            [sureBtn setTitleColor:[UIColor colorWithRed:0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1] forState:UIControlStateNormal];
        }else
        {
            sureBtn.enabled = NO;
            [sureBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        }
    }
}

@end
