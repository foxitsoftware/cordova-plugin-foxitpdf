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
#import "SearchResult.h"

@implementation SearchInfo
@synthesize snippet;
@synthesize keywordLocation;
@synthesize rects;
@synthesize rtText;
@synthesize rtHeight;

- (void)dealloc
{
    [snippet release];
    [rects release];
    [rtText release];
    [super dealloc];
}

@end

@implementation SearchResult
@synthesize index;
@synthesize infos;

- (void)dealloc
{
    [infos release];
    [super dealloc];
}

@end
