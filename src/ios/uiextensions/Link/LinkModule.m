/**
 * Copyright (C) 2003-2017, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "LinkModule.h"
#import "UIExtensionsManager+Private.h"
#import "LinkAnnotHandler.h"

@interface LinkModule ()
{
    UIExtensionsManager* __weak _extensionsManager;
    FSPDFReader* __weak _pdfReader;
}
@end

@implementation LinkModule

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager pdfReader:(FSPDFReader*)pdfReader
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfReader = pdfReader;
        [[LinkAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
    }
    return self;
}

-(NSString*)getName
{
    return @"Link";
}

@end

