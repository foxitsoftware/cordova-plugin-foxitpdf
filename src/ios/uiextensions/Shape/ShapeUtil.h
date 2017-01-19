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
#import "Const.h"

@interface ShapeUtil : NSObject

+ (NSArray*)getMovePointInRect:(CGRect)rect;
+ (EDIT_ANNOT_RECT_TYPE)getEditTypeWithPoint:(CGPoint)point rect:(CGRect)rect defaultEditType:(EDIT_ANNOT_RECT_TYPE)defaultEditType;

@end
