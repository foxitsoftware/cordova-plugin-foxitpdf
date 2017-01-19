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

#import "FileTreeNode.h"

@implementation FileTreeNode
@synthesize title= _title;
@synthesize key= _key;
@synthesize data= _data;
@synthesize parentNode= _parentNode;
@synthesize childrenNodes= _childrenNodes;
@synthesize expanded= _expanded;

- (id)init
{
    return [self initWithTitle:@"Node" key:nil data:nil];
}

- (id)initWithTitle:(NSString *)title key:(NSString *)key data:(id)data
{
    if (self= [super init])
    {
        self.parentNode= nil;
        self.childrenNodes= nil;
        self.expanded= NO;
    }
    self.title= title;
    self.key= key;
    self.data= data;
    return self;
}

- (void)dealloc
{
    self.title= nil;
    self.key= nil;
    self.childrenNodes= nil;
    self.data= nil;
    self.parentNode= nil;
    [super dealloc];
}

- (void)addChild:(FileTreeNode *)childNode
{
    if (childNode == nil)
    {
        return;
    }
    if (self.childrenNodes==nil)
    {
        self.childrenNodes= [NSMutableArray array];
    }
    childNode.parentNode= self;
    [self.childrenNodes addObject:childNode];
}

- (BOOL)hasChildren
{
    if (self.childrenNodes!=nil && self.childrenNodes.count>0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (FileTreeNode *)searchNodeWithKey:(NSString *)key
{
    FileTreeNode *result= nil;
    if ([self.key compare:key options:NSCaseInsensitiveSearch]==NSOrderedSame)
    {
        result= self;
    }
    else
    {
        for (FileTreeNode *child in self.childrenNodes)
        {
            result= [child searchNodeWithKey:key];
            if (result != nil)
            {
                break;
            }
        }
    }
    return result;
}

- (void)removeNodeWithKey:(NSString *)key
{
    NSMutableArray *children= [NSMutableArray array];
    for (FileTreeNode *child in self.childrenNodes)
    {
        if ([child.key compare:key options:NSCaseInsensitiveSearch]==NSOrderedSame)
        {
            [children addObject:child];
        }
        else
        {
            [child removeNodeWithKey:key];
        }
    }
    if (children.count>0)
    {
        for (FileTreeNode *node in children)
        {
            [self.childrenNodes removeObject:node];
        }
    }
}

- (NSInteger)deep
{
    return self.parentNode==nil?0:[self.parentNode deep]+1;
}

- (NSMutableArray *)enumerateNodes:(BOOL)expandedOnly
{
    NSMutableArray *resultNodes=[NSMutableArray array];
    if (self.parentNode==nil)
    {
        [resultNodes addObject:self];
    }
    if (expandedOnly)
    {
        if (self.expanded)
        {
            if (self.childrenNodes!=nil)
            {
                for (FileTreeNode *child in self.childrenNodes)
                {
                    [resultNodes addObject:child];
                    if (child.expanded)
                    {
                        [resultNodes addObjectsFromArray:[child enumerateNodes:expandedOnly]];
                    }
                }
            }
        }
    }
    else
    {
        if (self.childrenNodes!=nil)
        {
            for (FileTreeNode *child in self.childrenNodes)
            {
                [resultNodes addObject:child];
                [resultNodes addObjectsFromArray:[child enumerateNodes:expandedOnly]];
            }
        }        
    }
    return resultNodes;
}
@end
