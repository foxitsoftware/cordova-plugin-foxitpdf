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
#import "FbBaseBrowser.h"

@interface FbBaseBrowser ()

@end

@implementation FbBaseBrowser


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (BOOL)isEditState
{
    return YES;
}
- (void)setPath:(NSString *)filePath
{
    
}

- (void)setEditState
{
    
}

- (void)updateDataSource:(NSMutableArray *)dataSource
{
    
}

- (NSArray *)getCheckedItems
{
    return nil;
}

- (UIView *)getContentView
{
    return nil;
}
- (NSArray *)getDataSource:(NSString *)path
{
    return nil;
}

- (void)initializeViewWithDelegate:(id<IFbFileDelegate>)delegate fileListType:(FileListType)type
{
    
}

@end
