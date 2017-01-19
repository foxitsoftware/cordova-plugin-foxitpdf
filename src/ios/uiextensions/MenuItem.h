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

/** @brief The item of menu. */
@interface MenuItem : NSObject
@property (nonatomic,strong)NSString* title;
@property (nonatomic,strong)id object;
@property (nonatomic,assign)SEL action; // TYPE: (void)action:(id)object;
-(id)initWithTitle:(NSString*)title object:(id)object action:(SEL)action;
@end
