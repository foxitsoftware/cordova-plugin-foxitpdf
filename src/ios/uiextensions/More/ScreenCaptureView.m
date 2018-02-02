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

#import "ScreenCaptureView.h"
 #import "Utility.h"

@implementation ScreenCaptureView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        _captureRect = CGRectZero;
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

- (void)dealloc
{
    [Utility removeAllGestureRecognizer:self];
    self.rectSelectedHandler = nil;
    
   // [super dealloc];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        _beginPoint = point;
        _isMoving = YES;
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if (_isMoving)
        {
            _captureRect = [Utility convertToCGRect:point p2:_beginPoint];
            [self setNeedsDisplay];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        _captureRect = [Utility convertToCGRect:point p2:_beginPoint];
        _isMoving = NO;
        
        if (!CGRectIsEmpty(_captureRect))
        {
            [self setNeedsDisplay];
            if (self.rectSelectedHandler)
            {
                self.rectSelectedHandler(_captureRect);
            }
        }
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBFillColor(context, 0, 0, 0, .2);
    CGContextFillRect(context, rect);
    
    if (!CGRectIsEmpty(_captureRect))
    {
        CGContextClearRect(context, _captureRect);
        CGContextSetLineWidth(context, 2.0);
        CGFloat dashArray[] = {5,5,5,5};
        CGContextSetLineDash(context, 3, dashArray, 4);
        CGContextSetStrokeColorWithColor(context, [[UIColor blueColor] CGColor]);
        CGContextStrokeRect(context, _captureRect);
    }
}

- (void)reset
{
    _captureRect = CGRectZero;
    [self setNeedsDisplay];
}

@end
