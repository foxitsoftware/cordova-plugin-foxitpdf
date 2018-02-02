/**
 * Copyright (C) 2003-2018, Foxit Software Inc..
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
#import "LinkAnnotHandler.h"
#import "UIExtensionsManager+Private.h"

@interface LinkModule () {
    UIExtensionsManager *__weak _extensionsManager;
}
@end

@implementation LinkModule

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        LinkAnnotHandler* annotHandler = [[LinkAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_extensionsManager.pdfViewCtrl registerDocEventListener:annotHandler];
        [_extensionsManager.pdfViewCtrl registerPageEventListener:annotHandler];
        [_extensionsManager registerAnnotHandler:annotHandler];
    }
    return self;
}

- (NSString *)getName {
    return @"Link";
}

@end
