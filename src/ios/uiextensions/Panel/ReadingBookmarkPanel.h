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

#import "IPanelSpec.h"
#import "PanelController.h"
#import "UIExtensionsManager+Private.h"
#import <Foundation/Foundation.h>
#import <FoxitRDK/FSPDFViewControl.h>
#import <UIKit/UIKit.h>

@interface ReadingBookmarkPanel : NSObject <IPanelSpec, IDocEventListener, IPageEventListener>
@property (nonatomic, strong) UIButton *editButton;
- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager panelController:(FSPanelController *)panelController;
- (void)load;
- (void)reloadData;
@end
