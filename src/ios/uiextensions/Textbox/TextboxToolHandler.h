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

#import "UIExtensionsManager.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface TextboxToolHandler : NSObject <IToolHandler> {
    UITextView *_textView;
    FSPointF *_originalDibPoint;
    BOOL _isSaved;
    BOOL _keyboardShown;

    BOOL _onlyAddOnce;
}

@property (nonatomic, assign) FSAnnotType type;

//@property (nonatomic, assign) unsigned int color;
//@property (nonatomic, assign) int opacity;
//@property (nonatomic, assign) float fontSize;
//@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, assign) CGPoint freeTextStartPoint;
//@property (nonatomic, assign) BOOL isSelectoolCreate;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager;

@end
