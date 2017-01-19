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
#import "UIExtensionsSharedHeader.h"

typedef void (^highLightClicked)();
typedef void (^underLineClicked)();
typedef void (^strikeOutClicked)();
typedef void (^breakLineClicked)();
typedef void (^replaceClicked)();
typedef void (^insertClicked)();

typedef void (^rectClicked)();
typedef void (^lineClicked)();
typedef void (^circleClicked)();
typedef void (^arrowsClicked)();
typedef void (^pencileClicked)();
typedef void (^eraserClicked)();

typedef void (^typerwriterClicked)();
typedef void (^noteClicked)();
typedef void (^stampClicked)();

@interface MoreAnnotationsBar : NSObject

@property (nonatomic,retain)UIView *contentView;
@property (nonatomic,copy)highLightClicked highLightClicked;
@property (nonatomic,copy)underLineClicked underLineClicked;
@property (nonatomic,copy)strikeOutClicked strikeOutClicked;
@property (nonatomic,copy)breakLineClicked breakLineClicked;
@property (nonatomic,copy)replaceClicked replaceClicked;
@property (nonatomic,copy)insertClicked insertClicked;

@property (nonatomic,copy)rectClicked rectClicked;
@property (nonatomic,copy)lineClicked lineClicked;
@property (nonatomic,copy)circleClicked circleClicked;
@property (nonatomic,copy)arrowsClicked arrowsClicked;
@property (nonatomic,copy)pencileClicked pencileClicked;
@property (nonatomic,copy)eraserClicked eraserClicked;

@property (nonatomic,copy)typerwriterClicked typerwriterClicked;
@property (nonatomic,copy)noteClicked noteClicked;
@property (nonatomic,copy)stampClicked stampClicked;

-(MoreAnnotationsBar*)init:(CGRect)frame;
@end
