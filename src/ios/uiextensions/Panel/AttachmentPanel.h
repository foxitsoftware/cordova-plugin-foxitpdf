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

#import <FoxitRDK/FSPDFViewControl.h>
#import "UIExtensionsManager.h"
#import "IPanelSpec.h"
#import "PanelController.h"
#import "AttachmentViewController.h"

@class PanelButton;

/** @brief Attachment panel to show the list of all attachments in the document. */
@interface AttachmentPanel : NSObject<IPanelSpec, IDocEventListener>

@property (nonatomic, strong) PanelButton *addButton;
@property (nonatomic, strong) AttachmentViewController *attachmentCtr;
@property (nonatomic, strong) PanelController* panelController;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager panelController:(PanelController*)panelController;
- (void)load;

@end
