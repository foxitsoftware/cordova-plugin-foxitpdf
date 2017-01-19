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
#import "UIView+EnlargeEdge.h"
#import <objc/runtime.h>

static char topEdgeKey;
static char leftEdgeKey;
static char bottomEdgeKey;
static char rightEdgeKey;

@implementation UIView (UIViewEnlargeEdge)

- (void)setEnlargedEdge:(CGFloat)enlargedEdge
{
    [self setEnlargedEdgeWithTop:enlargedEdge left:enlargedEdge bottom:enlargedEdge right:enlargedEdge];
}

-(CGFloat)enlargedEdge
{
    return [(NSNumber*)objc_getAssociatedObject(self, &topEdgeKey) floatValue];
}

- (void)setEnlargedEdgeWithTop:(CGFloat)top left:(CGFloat)left bottom:(CGFloat)bottom right:(CGFloat)right
{
    objc_setAssociatedObject(self, &topEdgeKey, [NSNumber numberWithFloat:top], OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, &leftEdgeKey, [NSNumber numberWithFloat:left], OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, &bottomEdgeKey, [NSNumber numberWithFloat:bottom], OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, &rightEdgeKey, [NSNumber numberWithFloat:right], OBJC_ASSOCIATION_RETAIN);
}

-(CGRect)enlargeRect
{
    NSNumber *topEdge = objc_getAssociatedObject(self, &topEdgeKey);
    NSNumber *leftEdge = objc_getAssociatedObject(self, &leftEdgeKey);
    NSNumber *bottomEdge = objc_getAssociatedObject(self, &bottomEdgeKey);
    NSNumber *rightEdge = objc_getAssociatedObject(self, &rightEdgeKey);
    if (topEdge && rightEdge && bottomEdge && leftEdge)
    {
        return CGRectMake(self.bounds.origin.x - leftEdge.floatValue,
                          self.bounds.origin.y - topEdge.floatValue,
                          self.bounds.size.width + leftEdge.floatValue + rightEdge.floatValue,
                          self.bounds.size.height + topEdge.floatValue + bottomEdge.floatValue);
    }
    else
    {
        return self.bounds;
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect newBounds = [self enlargeRect];
    return CGRectContainsPoint(newBounds, point) ? YES : NO;
}

@end
