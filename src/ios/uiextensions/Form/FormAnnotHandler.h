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
#import "UIExtensionsManager+Private.h"

@protocol IGestureEventListener;


@interface FormAnnotHandler : FSFormFillerAssist<UITextViewDelegate,IAnnotHandler,IDocEventListener>
{
    BOOL _isOver;
    
    BOOL _keyboardShown;
    CGRect _originalRect;
}

@property (nonatomic,assign) NSTimer *formTimer;
@property (nonatomic,assign) FS_CALLBACK_TIMER formTimerCallback;
@property (nonatomic,assign) BOOL hasFormChanged;
@property (nonatomic,assign) FSFormControl* editFormControl;
@property (nonatomic,assign) int editFormControlNeedTextInput;
@property (nonatomic,assign) int editFormControlNeedSetCursor;
@property (nonatomic,retain) UITextView *hiddenTextField;
@property (nonatomic,assign) CGRect currentEditRect;
@property (nonatomic,copy) NSString *lastText;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;
- (void)endTextInput;

-(void)refresh: (FSPDFPage*)page pdfRect: (FSRectF*)pdfRect;
-(BOOL)setTimer: (int)elapse timerFunc: (FS_CALLBACK_TIMER)timerFunc timerID: (int *)timerID;
-(BOOL)killTimer: (int)timerID;
-(void)focusGotOnControl: (FSFormControl*)control fieldValue: (NSString *)fieldValue;
-(void)focusLostFromControl: (FSFormControl*)control fieldValue: (NSString *)fieldValue;

@end
