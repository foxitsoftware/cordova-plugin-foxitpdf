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
#import "MagnifierView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MagnifierView
@synthesize viewToMagnify, touchPoint, magnifyPoint;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:CGRectMake(0, 0, 172, 50)]) {
		// make the circle-shape outline with a nice border.
        
        self.layer.cornerRadius = 30;        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(-8, -5, 188, 82)];
        imageView.image = [UIImage imageNamed:@"annotation_magnifier"];
        [self addSubview:imageView];
        [imageView release];
	}
	return self;
}

- (void)setTouchPoint:(CGPoint)pt {
	touchPoint = pt;
	// whenever touchPoint is set, 
	// update the position of the magnifier (to just above what's being magnified)
	self.center = CGPointMake(pt.x, pt.y-62);
}

- (void)drawRect:(CGRect)rect {
	/** here we're just doing some transforms on the view we're magnifying,
	 and rendering that view directly into this view,
	 rather than the previous method of copying an image. */
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context,1*(self.frame.size.width*0.5),1*(self.frame.size.height*0.5));
	CGContextScaleCTM(context, 1.5, 1.5);
	CGContextTranslateCTM(context,-1*(magnifyPoint.x),-1*(magnifyPoint.y));
	[self.viewToMagnify.layer renderInContext:context];
}

- (void)dealloc {
	[viewToMagnify release];
	[super dealloc];
}

@end
