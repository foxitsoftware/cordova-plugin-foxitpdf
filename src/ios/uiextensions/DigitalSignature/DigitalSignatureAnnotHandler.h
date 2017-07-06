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

#import <Foundation/Foundation.h>
#import <FoxitRDK/FSPDFObjC.h>
#import "../../../../libs/uiextensions_src/uiextensions/UIExtensionsManager+Private.h"

@protocol IAnnotHandler;
#define SIGCONTENT_LENGTH 15884

@interface DigitalSignatureAnnotHandler : NSObject<IAnnotHandler,IRotationEventListener,IDocEventListener,IScrollViewEventListener>
- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;
- (void)onDocWillOpen;
- (void)onDocumentReloaded:(FSPDFDoc *)document;
@end
