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
#import "TaskServer.h"

@implementation Task

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.run = nil;
    }
    return self;
}

- (void)dealloc
{
    [_run release];
    [super dealloc];
}

@end

@implementation TaskServer

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (id)syncObj
{
	return self;
}

- (void)executeSync:(Task*)task
{
    @synchronized(self)
    {
        task.run();
    }
}

- (void)executeBlockSync:(TaskBlock)task
{
	@synchronized(self)
	{
		task();
	}
}

@end
