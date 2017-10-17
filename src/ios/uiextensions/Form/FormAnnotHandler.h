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

#import "TbBaseBar.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

@protocol IGestureEventListener;

@interface FormAnnotHandler : FSFormFillerAssist <UITextViewDelegate, IAnnotHandler, IDocEventListener, IRotationEventListener> {
    BOOL _isOver;

    BOOL _keyboardShown;
    CGRect _originalRect;
    float _keyboardHeight;
}

@property (nonatomic, weak) FSPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, weak) UIExtensionsManager *extensionsManager;
@property (nonatomic, strong) NSTimer *formTimer;
@property (nonatomic, retain) FSTimer *formTimerCallback;
@property (nonatomic, assign) BOOL hasFormChanged;
@property (nonatomic, assign) int editFormControlNeedTextInput;
@property (nonatomic, assign) BOOL editFormControlNeedSetCursor;
@property (nonatomic, strong) UITextView *hiddenTextField;
@property (nonatomic, assign) CGRect currentEditRect;
@property (nonatomic, copy) NSString *lastText;
@property (nonatomic, strong) TbBaseBar *formNaviBar;
@property (nonatomic, strong) TbBaseBar *textFormNaviBar;
@property (nonatomic, retain) FSFormFiller *formFiller;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager;
- (TbBaseBar *)buildFormNaviBar;
- (void)endTextInput;

- (void)refresh:(FSPDFPage *)page pdfRect:(FSRectF *)pdfRect;
- (BOOL)setTimer:(int)elapse timerFunc:(FSTimer *)timerFunc timerID:(int *)timerID;
- (BOOL)killTimer:(int)timerID;
- (void)focusGotOnControl:(FSFormControl *)control fieldValue:(NSString *)fieldValue;
- (void)focusLostFromControl:(FSFormControl *)control fieldValue:(NSString *)fieldValue;

@end
