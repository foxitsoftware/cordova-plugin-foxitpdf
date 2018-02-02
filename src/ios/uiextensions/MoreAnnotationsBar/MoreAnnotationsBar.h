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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^DumbBlock)(void);

@class UIExtensionsModulesConfig;

@interface MoreAnnotationsBar : NSObject

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, copy) DumbBlock highLightClicked;
@property (nonatomic, copy) DumbBlock underLineClicked;
@property (nonatomic, copy) DumbBlock strikeOutClicked;
@property (nonatomic, copy) DumbBlock breakLineClicked;
@property (nonatomic, copy) DumbBlock replaceClicked;
@property (nonatomic, copy) DumbBlock insertClicked;

@property (nonatomic, copy) DumbBlock rectClicked;
@property (nonatomic, copy) DumbBlock lineClicked;
@property (nonatomic, copy) DumbBlock circleClicked;
@property (nonatomic, copy) DumbBlock arrowsClicked;
@property (nonatomic, copy) DumbBlock pencileClicked;
@property (nonatomic, copy) DumbBlock eraserClicked;
@property (nonatomic, copy) DumbBlock polygonClicked;
@property (nonatomic, copy) DumbBlock cloudClicked;

@property (nonatomic, copy) DumbBlock typerwriterClicked;
@property (nonatomic, copy) DumbBlock textboxClicked;
@property (nonatomic, copy) DumbBlock noteClicked;
@property (nonatomic, copy) DumbBlock stampClicked;
@property (nonatomic, copy) DumbBlock distanceClicked;
@property (nonatomic, copy) DumbBlock imageClicked;
@property (nonatomic, copy) DumbBlock attachmentClicked;

- (MoreAnnotationsBar *)initWithWidth:(CGFloat)width config:(UIExtensionsModulesConfig *)config;
- (void)refreshLayoutWithWidth:(CGFloat)width;

@end
