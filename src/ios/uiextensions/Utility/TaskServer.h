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

typedef void (^TaskBlock)(void);

/** @brief A simple task. */
@interface Task : NSObject

@property (nonatomic,copy) TaskBlock run;

@end

/** @brief The task server to synchronize all the tasks. */
@interface TaskServer : NSObject

- (void)executeSync:(Task*)task;
- (void)executeBlockSync:(TaskBlock)task;

@end