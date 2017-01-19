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
#import <Foundation/Foundation.h>
#import <FoxitRDK/FSPDFViewControl.h>
#import "UIExtensionsManager.h"
#import "IPanelSpec.h"
#import "PanelController.h"

@protocol IPanelSpec;
@protocol IAppModule;
@class AnnotationListViewController;

/** @brief Annotation panel to show the list of all annotations in the document. */
@interface AnnotationPanel : NSObject<IPanelSpec,IDocEventListener>
@property (nonatomic, retain) UIButton *editButton;
@property (nonatomic, strong) AnnotationListViewController *annotationCtrl;
@property (nonatomic, retain) PanelController* panelController;


- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager panelController:(PanelController*)panelController;
- (void)load;
@end
