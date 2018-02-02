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

#import "SelectionModule.h"
#import "SelectToolHandler.h"
#import "UIExtensionsManager+Private.h"

@interface SelectionModule () {
    UIExtensionsManager *__weak _extensionsManager;
}
@end

@implementation SelectionModule

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        SelectToolHandler* toolHandler = [[SelectToolHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_extensionsManager registerToolHandler:toolHandler];
        [_extensionsManager registerRotateChangedListener:toolHandler];
        [_extensionsManager registerGestureEventListener:toolHandler];
        [_extensionsManager.pdfViewCtrl registerDocEventListener:toolHandler];
        [_extensionsManager.pdfViewCtrl registerScrollViewEventListener:toolHandler];
        [_extensionsManager.pdfViewCtrl registerPageEventListener:toolHandler];
    }
    return self;
}

- (NSString *)getName {
    return @"Selection";
}

@end
