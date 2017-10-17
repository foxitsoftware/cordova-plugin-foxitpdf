//
//  UIExtensionsModulesConfig+private.h
//  uiextensions
//
//  Created by lzw on 11/08/2017.
//  Copyright © 2017 lzw. All rights reserved.
//

#ifndef UIExtensionsModulesConfig_private_h
#define UIExtensionsModulesConfig_private_h

#import <FoxitRDK/FSPDFObjC.h>

@interface UIExtensionsModulesConfig ()

- (BOOL)isToolEnabled:(NSString *)tool;
- (BOOL)canInteractWithAnnot:(FSAnnot *)annot;

@end

#endif /* UIExtensionsModulesConfig_private_h */
