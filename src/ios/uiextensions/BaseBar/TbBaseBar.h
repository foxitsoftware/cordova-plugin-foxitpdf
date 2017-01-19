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
#import "TbBaseItem.h"


typedef enum TB_Orientation
{
    Orientation_HORIZONTAL,
    Orientation_VERTICAL,
} TB_Orientation;

typedef enum TB_Position
{
    Position_LT,
    Position_CENTER,
    Position_RB,
} TB_Position;

/** @brief The customized tool bar. */
@interface TbBaseBar : NSObject

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, assign) TB_Orientation direction;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) BOOL interval;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) int intervalWidth;
@property (nonatomic, assign) BOOL top;
@property (nonatomic, assign) BOOL hasDivide;

- (BOOL)addItem:(TbBaseItem*)item displayPosition:(TB_Position)position;
- (BOOL)removeItemByIndex:(int)tag displayPosition:(TB_Position)position;
- (BOOL)removeItem:(TbBaseItem*)item;
- (BOOL)removeAllItems;
- (BOOL)removeLtItems;
- (BOOL)removeCenterItems;
- (BOOL)removeRbItems;
@end
