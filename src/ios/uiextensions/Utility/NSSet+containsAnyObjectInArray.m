//
//  NSArray+containsAnyObjectsInArray.m
//  uiextensions
//
//  Created by lzw on 02/08/2017.
//  Copyright © 2017 lzw. All rights reserved.
//

#import "NSSet+containsAnyObjectInArray.h"

@implementation NSSet (containsAnyObjectInArray)

- (BOOL)containsAnyObjectInArray:(NSArray *)array {
    for (id obj in array) {
        if ([self containsObject:obj]) {
            return true;
        }
    }
    return false;
}

- (BOOL)containsAnyObjectNotInArray:(NSArray *)array {
    for (id obj in self) {
        if (![array containsObject:obj]) {
            return true;
        }
    }
    return false;
}

@end
