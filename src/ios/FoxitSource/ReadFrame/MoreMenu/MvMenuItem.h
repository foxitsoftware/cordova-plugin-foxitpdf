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
#import "IMvCallback.h"
@interface MvMenuItem : NSObject

@property(nonatomic,assign)NSUInteger tag;
@property(nonatomic,retain)NSString *text;
@property(nonatomic,assign)NSInteger iconId;
@property(nonatomic,assign)BOOL enable;
@property(nonatomic,retain)id<IMvCallback> callBack;
@property(nonatomic,retain)UIView *customView;

@end
