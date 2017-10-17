//
//  NSArray+containsAnyObjectsInArray.h
//  uiextensions
//
//  Created by lzw on 02/08/2017.
//  Copyright © 2017 lzw. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSSet (containsAnyObjectInArray)

- (BOOL)containsAnyObjectInArray:(NSArray *)array;
- (BOOL)containsAnyObjectNotInArray:(NSArray *)array;

@end
