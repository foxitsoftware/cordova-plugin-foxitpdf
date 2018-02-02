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

#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

@protocol IAnnotHandler;
@class UIExtensionsManager;

static NSString *LINK_DES_TYPE = @"DesType";
static NSString *LINK_DES_INDEX = @"DesIndex";
static NSString *LINK_DES_RECT = @"DesRect";
static NSString *LINK_DES_URL = @"DesURL";
static NSString *LINK_DES_AREA = @"DesArea";
static NSString *LINK_DES_FILE = @"DesFile";

/**@brief A link annotation handler to handle touches and gestures on tha link annotation. */
@interface LinkAnnotHandler : NSObject <IAnnotHandler, IDocEventListener, IPageEventListener> {
    NSString *_url;
}

@property (nonatomic, strong) NSMutableDictionary *dictAnnotLink;

- (void)loadAnnotLink:(FSPDFPage *)dmpage;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager;

@end
