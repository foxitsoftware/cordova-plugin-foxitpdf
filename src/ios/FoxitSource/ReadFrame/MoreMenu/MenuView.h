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
#import "MenuGroup.h"
#import "MvMenuItem.h"

typedef void(^MV_Callback)();

@interface MenuView : NSObject
@property (nonatomic, strong) MV_Callback onCancelClicked;
- (void)addGroup:(MenuGroup *)group;
- (void)removeGroup:(NSUInteger)tag;
- (MenuGroup *)getGroup:(NSUInteger)tag;
- (void)addMenuItem:(NSUInteger)groupTag withItem:(MvMenuItem *)item;
- (void)removeMenuItem:(NSUInteger)groupTag WithItemTag:(NSUInteger)itemTag;
- (UIView *)getContentView;
- (void)setMenuTitle:(NSString *)title;
- (void)reloadData;
@end
