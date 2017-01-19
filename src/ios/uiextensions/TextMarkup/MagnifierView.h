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
#import <UIKit/UIKit.h>

/**@brief A magnifier to show a selected text. */
@interface MagnifierView : UIView {
	UIView *viewToMagnify;
	CGPoint touchPoint;
    CGPoint magnifyPoint;
}

@property (nonatomic, retain) UIView *viewToMagnify;
@property (nonatomic, assign) CGPoint touchPoint;
@property (nonatomic, assign) CGPoint magnifyPoint;

@end
