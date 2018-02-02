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

#import "RotationItem.h"
#import "PropertyBar.h"
#import <CoreText/CoreText.h>

@interface RotationItem ()

@property (nonatomic, strong) UIButton *button;

@end

@implementation RotationItem

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        //        self.button.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [self.button addTarget:self action:@selector(onClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.button];
        [self.button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        //        [self.button setTitleColor:[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] forState:UIControlStateHighlighted];
        //        [self.button setTitleColor:[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] forState:UIControlStateSelected];
        self.button.titleLabel.font = [UIFont systemFontOfSize:10];
        self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;

        UIImage *highlightImage = [UIImage imageNamed:@"property_rotation_background_highlighted"];
        [self.button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
        [self.button setBackgroundImage:highlightImage forState:UIControlStateSelected];
        [self.button setBackgroundImage:[UIImage imageNamed:@"property_rotation_background"] forState:UIControlStateNormal];
        [self.button sizeToFit];
    }
    return self;
}

- (void)setRotation:(int)rotation {
    _rotation = rotation;
    NSString *text = [NSString stringWithFormat:@"%d", rotation];
    [self.button setTitle:text forState:UIControlStateNormal];

    //    NSString *text = [NSString stringWithFormat:@"%do", rotation];
    //    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10]}];
    ////    [string beginEditing];
    ////    [string addAttribute:kCTSuperscriptAttributeName
    ////                   value:@(1)
    ////                   range:NSMakeRange(text.length - 1, 1)];
    ////    [string endEditing];
    //    [self.button.titleLabel setAttributedText:string];
}
//- (void)setOpacity:(int)opacity {
//    _opacity = opacity;
//    switch (opacity) {
//    case 25:
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_25"] forState:UIControlStateNormal];
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_25_selected"] forState:UIControlStateHighlighted];
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_25_selected"] forState:UIControlStateSelected];
//        break;
//    case 50:
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_50"] forState:UIControlStateNormal];
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_50_selected"] forState:UIControlStateHighlighted];
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_50_selected"] forState:UIControlStateSelected];
//        break;
//    case 75:
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_75"] forState:UIControlStateNormal];
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_75_selected"] forState:UIControlStateHighlighted];
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_75_selected"] forState:UIControlStateSelected];
//        break;
//    case 100:
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_100"] forState:UIControlStateNormal];
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_100_selected"] forState:UIControlStateHighlighted];
//        [self.button setImage:[UIImage imageNamed:@"property_opacity_100_selected"] forState:UIControlStateSelected];
//        break;
//    default:
//        break;
//    }
//
//    NSString *st_opacity = [NSString stringWithFormat:@"%d %@", opacity, @"%"];
//    [self.button setTitle:st_opacity forState:UIControlStateNormal];
//    [self.button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [self.button setTitleColor:[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] forState:UIControlStateHighlighted];
//    [self.button setTitleColor:[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] forState:UIControlStateSelected];
//    self.button.titleLabel.font = [UIFont systemFontOfSize:10];
//    self.button.titleEdgeInsets = UIEdgeInsetsMake(0, -32, -32, 0);
//    self.button.imageEdgeInsets = UIEdgeInsetsMake(-10, 0, 0, -10);
//    self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
//}

- (void)onClick {
    if (self.callback) {
        self.callback(PROPERTY_ROTATION, self.rotation);
    }
}

- (void)setSelected:(BOOL)selected {
    self.button.selected = selected;
}

@end
