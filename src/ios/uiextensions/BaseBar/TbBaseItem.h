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

typedef enum TB_ImageTextRelation
{
    RELATION_TOP, //title top
    RELATION_LEFT, //title left
    RELATION_RIGHT, //title right
    RELATION_BOTTOM, //title bottom
} TB_ImageTextRelation;

typedef enum TB_ItemDisplayStyle
{
    Item_Title,
    Item_Image,
    Item_Title_Image,
} TB_ItemDisplayStyle;

#define ENLARGE_EDGE 3

/** @brief The customized tool bar item. */
@interface TbBaseItem : NSObject

typedef void(^Callback)(TbBaseItem *item);

@property (nonatomic, assign) int tag;


@property (nonatomic, strong) UIButton *button;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSAttributedString *attributedText;
@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong) UIColor *textColor;

@property (nonatomic, strong) UIImage *imageNormal;
@property (nonatomic, strong) UIImage *imageSelected;
@property (nonatomic, strong) UIImage *imageDisabled;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *backgroundColorSelected;
@property (nonatomic, strong) UIColor *backgroundColorDisable;

@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, copy) Callback onTapClick;
@property (nonatomic, copy) Callback onLongPress;

@property (nonatomic, assign) TB_ImageTextRelation imageTextRelation;
@property (nonatomic, assign) CGRect rect;

+ (TbBaseItem*)createItemWithTitle:(NSString*)title;

+ (TbBaseItem*)createItemWithImage:(UIImage*)imageNormal
                    imageSelected:(UIImage*)imageSelected
                     imageDisable:(UIImage*)imageDisabled;

+ (TbBaseItem*)createItemWithImageAndTitle:(NSString*)title
                              imageNormal:(UIImage*)imageNormal
                            imageSelected:(UIImage*)imageSelected
                             imageDisable:(UIImage*)imageDisabled
                        imageTextRelation:(TB_ImageTextRelation)imageTextRelation;

+ (TbBaseItem*)createItemWithTitle:(NSString*)title
                         background:(UIImage*)background;

+ (TbBaseItem*)createItemWithImage:(UIImage*)imageNormal
                      imageSelected:(UIImage*)imageSelected
                       imageDisable:(UIImage*)imageDisabled
                         background:(UIImage*)background;

+ (TbBaseItem*)createItemWithImageAndTitle:(NSString*)title
                                imageNormal:(UIImage*)imageNormal
                              imageSelected:(UIImage*)imageSelected
                               imageDisable:(UIImage*)imageDisabled
                                 background:(UIImage*)background
                          imageTextRelation:(TB_ImageTextRelation)imageTextRelation;

+ (UIImage *)imageByApplyingAlpha:(UIImage*)image alpha:(CGFloat) alpha;

- (void) setAttributedText:(NSAttributedString *) string;
- (void) setInsideCircleColor:(int)color;

@end
