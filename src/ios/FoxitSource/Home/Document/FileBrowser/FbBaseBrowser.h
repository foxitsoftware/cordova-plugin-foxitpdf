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
#import <UIKit/UIKit.h>
#import "IFbFileDelegate.h"
#include "FbFileEnum.h"
@interface FbBaseBrowser : NSObject


@property(nonatomic,unsafe_unretained)DisplayStyle style;
- (UIView *)getContentView;
- (void)setPath:(NSString *)filePath;
- (void)updateDataSource:(NSMutableArray *)dataSource;
- (NSArray *)getDataSource:(NSString *)path;
- (NSArray *)getCheckedItems;
@end
