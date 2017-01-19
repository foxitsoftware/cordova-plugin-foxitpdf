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

@interface FileTreeNode : NSObject
@property (copy, nonatomic) NSString *title;
@property (retain, nonatomic) NSString *key;
@property (retain, nonatomic) id data;
@property (assign, nonatomic) FileTreeNode *parentNode;
@property (retain, nonatomic) NSMutableArray *childrenNodes;
@property (assign, nonatomic) BOOL expanded;

- (id)initWithTitle:(NSString *)title key:(NSString *)key data:(id)data;
- (void)addChild:(FileTreeNode *)childNode;
- (BOOL)hasChildren;
- (FileTreeNode *)searchNodeWithKey:(NSString *)key;
- (void)removeNodeWithKey:(NSString *)key;
- (NSInteger)deep;
- (NSMutableArray *)enumerateNodes:(BOOL)expandedOnly;
@end
