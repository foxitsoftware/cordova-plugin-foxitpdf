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
#import "UIExtensionsManager+Private.h"

@protocol IToolHandler;
@class UIExtensionsManager;
@class TaskServer;
@class NoteDialog;

/**@brief A note tool handler to handle its own events. */
@interface NoteToolHandler : NSObject<IToolHandler>
@property (nonatomic, assign) enum FS_ANNOTTYPE type;
@property (nonatomic, retain) NoteDialog *currentVC;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;
@end
