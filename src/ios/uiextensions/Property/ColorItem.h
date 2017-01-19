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
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../Utility/Utility.h"
#import "PropertyBar.h"

@interface ColorItem : UIView

@property (nonatomic, assign) int color;
@property (nonatomic, copy) CallBackInt callback;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setSelected:(BOOL)selected;

@end
