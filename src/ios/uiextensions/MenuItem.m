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
#import "MenuItem.h"

@implementation MenuItem

-(id)initWithTitle:(NSString*)title object:(id)object action:(SEL)action
{
    if (self = [super init])
    {
        self.title = title;
        self.object = object;
        self.action = action;
    }
    return self;
}

-(void)setAction:(SEL)action
{
    _action = action;
}

-(void)setTitle:(NSString *)title
{
    if (_title!=title)
    {
        _title = [title copy];
    }
}

-(BOOL)dontDismiss
{
    return YES;
}

@end
