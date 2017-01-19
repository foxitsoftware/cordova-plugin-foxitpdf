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

@class PanelButton;
@class PanelHost;
@class UIExtensionsManager;
@class PanelController;

PanelController* getCurrentPanelController();

@protocol IPanelChangedListener <NSObject>

-(void)onPanelChanged:(BOOL)isHidden;

@end

/** @brief Panel controller to manage all the panels. */
@interface PanelController : NSObject

@property (nonatomic, strong) PanelHost* panel;
@property (nonatomic, retain) NSMutableArray* panelListeners;
@property (nonatomic, assign) BOOL isHidden;

-(instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;
-(void)registerPanelChangedListener:(id<IPanelChangedListener>)listener;
-(void)unregisterPanelChangedListener:(id<IPanelChangedListener>)listener;

-(void)reloadReadingBookmarkPanel;
@end
