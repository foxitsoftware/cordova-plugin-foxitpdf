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

#import "ShapeUtil.h"

@implementation ShapeUtil

+ (NSArray*)getMovePointInRect:(CGRect)rect
{
    if (rect.size.width == 0 || rect.size.height == 0)
    {
        return nil;
    }
    
    UIImage *dragDot = [UIImage imageNamed:@"annotation_drag.png"];
    float dragWidth = dragDot.size.width;
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x - dragWidth/2, rect.origin.y - dragWidth/2, dragWidth, dragWidth)]];
    [array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x - dragWidth/2, rect.origin.y + rect.size.height/2.0 - dragWidth/2, dragWidth, dragWidth)]];
    [array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x - dragWidth/2, rect.origin.y + rect.size.height - dragWidth/2, dragWidth, dragWidth)]];
    [array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x + rect.size.width/2.0 - dragWidth/2, rect.origin.y - dragWidth/2, dragWidth, dragWidth)]];
    [array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x + rect.size.width/2.0 - dragWidth/2, rect.origin.y + rect.size.height - dragWidth/2, dragWidth, dragWidth)]];
    [array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x + rect.size.width - dragWidth/2, rect.origin.y - dragWidth/2, dragWidth, dragWidth)]];
    [array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x + rect.size.width - dragWidth/2, rect.origin.y + rect.size.height/2.0 - dragWidth/2, dragWidth, dragWidth)]];
    [array addObject:[NSValue valueWithCGRect:CGRectMake(rect.origin.x + rect.size.width - dragWidth/2, rect.origin.y + rect.size.height - dragWidth/2, dragWidth, dragWidth)]];
    return array;
}

+ (EDIT_ANNOT_RECT_TYPE)getEditTypeWithPoint:(CGPoint)point rect:(CGRect)rect defaultEditType:(EDIT_ANNOT_RECT_TYPE)defaultEditType
{
    float left = rect.origin.x;
    float top = rect.origin.y;
    float w = rect.size.width;
    float h = rect.size.height;
    NSArray *pointArray = [NSArray arrayWithObjects:
                             [NSValue valueWithCGPoint:CGPointMake(left, top)],
                             [NSValue valueWithCGPoint:CGPointMake(left, top + h / 2)],
                             [NSValue valueWithCGPoint:CGPointMake(left, top + h)],
                             [NSValue valueWithCGPoint:CGPointMake(left + w / 2, top)],
                             [NSValue valueWithCGPoint:CGPointMake(left + w / 2, top + h)],
                             [NSValue valueWithCGPoint:CGPointMake(left + w, top)],
                             [NSValue valueWithCGPoint:CGPointMake(left + w, top + h / 2)],
                             [NSValue valueWithCGPoint:CGPointMake(left + w, top + h)],
                           [NSValue valueWithCGPoint:CGPointMake(left + w / 2, top + h / 2)],
                             nil];
    __block NSUInteger minIdx;
    __block float minDiff = FLT_MAX;
    [pointArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint pt = [obj CGPointValue];
        float diff = ABS(pt.x - point.x) + ABS(pt.y - point.y);
        if (diff < minDiff) {
            minIdx = idx;
            minDiff = diff;
        }
    }];
    const float tolerance = 25.0f;
    CGPoint closestPoint = [pointArray[minIdx] CGPointValue];
    if ([self isPoint:point closetoPoint:closestPoint tolerance:tolerance]) {
        return (EDIT_ANNOT_RECT_TYPE)minIdx;
    }
    return defaultEditType;
}

+ (BOOL)isPoint:(CGPoint)p1 closetoPoint:(CGPoint)p2 tolerance:(float)tolerance
{
    float dx = p1.x - p2.x;
    float dy = p1.y - p2.y;
    return (dx * dx + dy * dy) < tolerance * tolerance;
}

@end
