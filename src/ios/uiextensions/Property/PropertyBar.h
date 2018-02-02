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

#import "../UIExtensionsManager.h"
#import "ColorItem.h"
#import "ColorLayout.h"
#import "FontLayout.h"
#import "IconLayout.h"
#import "LineWidthLayout.h"
#import "OpacityItem.h"
#import "OpacityLayout.h"
#import "RotationLayout.h"
#import <Foundation/Foundation.h>
#import "DistanceUnitLayout.h"

#define TABHEIGHT 44
#define LAYOUTTITLEHEIGHT 20
#define LAYOUTTBSPACE 15
#define ITEMLRSPACE 20

static const long PROPERTY_UNKNOWN = 0x00000000;
static const long PROPERTY_COLOR = 0x00000001;
static const long PROPERTY_OPACITY = 0x00000002;
static const long PROPERTY_LINEWIDTH = 0x00000004;
static const long PROPERTY_FONTNAME = 0x00000008;
static const long PROPERTY_FONTSIZE = 0x00000010;
static const long PROPERTY_ICONTYPE = 0x00000100;
static const long PROPERTY_ATTACHMENT_ICONTYPE = 0x00000040;
static const long PROPERTY_ALL = 0x0000003F;
static const long PROPERTY_DISTANCE_UNIT = 0x00001000;
static const long PROPERTY_ROTATION = 0x00000080; // image only

enum Property_TabType {
    TAB_FILL = 100,
    TAB_BORDER,
    TAB_FONT,
    TAB_TYPE,
    TAB_DISTANCE_UNIT,
};

typedef enum Property_TabType Property_TabType;

@protocol IPropertyValueChangedListener <NSObject>

@required
- (void)onProperty:(long)property changedFrom:(NSValue *)oldValue to:(NSValue *)newValue;
@end

@protocol IPropertyBarListener <NSObject>

@required
- (void)onPropertyBarDismiss;

@end

@class FSPDFViewCtrl;
@protocol IRotationEventListener;

@interface PropertyBar : NSObject <UIPopoverControllerDelegate, IRotationEventListener>

@property (nonatomic, strong) LineWidthLayout *lineWidthLayout;
@property (nonatomic, assign) BOOL isShowing;

- (instancetype)initWithPDFViewController:(FSPDFViewCtrl *)pdfViewCtrl extensionsManager:(UIExtensionsManager *)extensionsManager;
- (void)resetBySupportedItems:(long)items frame:(CGRect)frame;

- (void)setColors:(NSArray *)array;
- (void)setProperty:(long)property intValue:(int)value;
- (void)setProperty:(long)property floatValue:(float)value;
- (void)setProperty:(long)property stringValue:(NSString *)value;
- (void)addListener:(id<IPropertyValueChangedListener>)listener;

- (void)addTabByTitle:(NSString *)title atIndex:(int)tabIndex;

- (void)updatePropertyBar:(CGRect)frame;
- (void)showPropertyBar:(CGRect)frame inView:(UIView *)view viewsCanMove:(NSArray *)views;

- (void)refreshPropertyLayout;
- (void)dismissPropertyBar;

- (void)registerPropertyBarListener:(id<IPropertyBarListener>)listener;
- (void)unregisterPropertyBarListener:(id<IPropertyBarListener>)listener;
- (void)setDistanceLayoutsForbidEdit;
@end
