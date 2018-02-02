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

#ifndef UIExtensionsModulesConfig_private_h
#define UIExtensionsModulesConfig_private_h

#import <FoxitRDK/FSPDFObjC.h>

@interface UIExtensionsModulesConfig ()

- (BOOL)isToolEnabled:(NSString *)tool;
- (BOOL)canInteractWithAnnot:(FSAnnot *)annot;

@end

#endif /* UIExtensionsModulesConfig_private_h */
