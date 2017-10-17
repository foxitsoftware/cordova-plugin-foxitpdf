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

#import "UIView+shake.h"

@implementation UIView (shake)

- (void)shakeStatus:(BOOL)enabled {
    if (enabled) {
        CGFloat rotation = 0.03;

        CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"transform"];
        shake.duration = 0.13;
        shake.autoreverses = YES;
        shake.repeatCount = MAXFLOAT;
        shake.removedOnCompletion = NO;
        shake.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(self.layer.transform, -rotation, 0.0, 0.0, 1.0)];
        shake.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(self.layer.transform, rotation, 0.0, 0.0, 1.0)];

        self.layer.shadowOpacity = 0.01;
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [self.layer addAnimation:shake forKey:@"shakeAnimation"];
    } else {
        [self.layer removeAnimationForKey:@"shakeAnimation"];
    }
}

@end
