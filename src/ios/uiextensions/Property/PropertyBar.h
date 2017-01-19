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
#import "ColorItem.h"
#import "OpacityItem.h"
#import "ColorLayout.h"
#import "OpacityLayout.h"
#import "LineWidthLayout.h"
#import "FontLayout.h"
#import "IconLayout.h"
#import "../UIExtensionsManager.h"

#define TABHEIGHT 44
#define LAYOUTTITLEHEIGHT 20
#define LAYOUTTBSPACE 15
#define ITEMLRSPACE 20

static const long  PROPERTY_UNKNOWN = 0x00000000;
static const long  PROPERTY_COLOR = 0x00000001;
static const long  PROPERTY_OPACITY = 0x00000002;
static const long  PROPERTY_LINEWIDTH = 0x00000004;
static const long  PROPERTY_FONTNAME = 0x00000008;
static const long  PROPERTY_FONTSIZE = 0x00000010;
static const long  PROPERTY_ICONTYPE = 0x00000100;
static const long  PROPERTY_ALL = 0x0000003F;

enum Property_TabType {
    TAB_FILL = 100,
    TAB_BORDER,
    TAB_FONT,
    TAB_TYPE,
};

typedef enum Property_TabType Property_TabType;


@protocol IPropertyValueChangedListener <NSObject>

@required
- (void)onIntValueChanged:(long)property value:(int)value;
- (void)onFloatValueChanged:(long)property value:(float)value;
- (void)onStringValueChanged:(long)property value:(NSString*)value;

@end

@protocol IPropertyBarListener <NSObject>

@required
- (void)onPropertyBarDismiss;

@end

@class FSPDFViewCtrl;
@protocol IRotationEventListener;

@interface PropertyBar : NSObject <UIPopoverControllerDelegate,IRotationEventListener>

@property (nonatomic, retain) LineWidthLayout *lineWidthLayout;
@property (nonatomic,assign) BOOL isShowing;

- (instancetype)initWithPDFViewController:(FSPDFViewCtrl*)pdfViewCtrl extensionsManager:(UIExtensionsManager*)extensionsManager;
- (void)resetBySupportedItems:(long)items;

- (void)setColors:(NSArray*)array;
- (void)setProperty:(long)property intValue:(int)value;
- (void)setProperty:(long)property floatValue:(float)value;
- (void)setProperty:(long)property stringValue:(NSString*)value;
- (void)addListener:(id<IPropertyValueChangedListener>)listener;

- (void)addTabByTitle:(NSString*)title atIndex:(int)tabIndex;

- (void)updatePropertyBar:(CGRect)frame;
- (void)showPropertyBar:(CGRect)frame inView:(UIView*)view viewsCanMove:(NSArray*)views;

- (void)refreshPropertyLayout;
- (void)dismissPropertyBar;

- (void)registerPropertyBarListener:(id<IPropertyBarListener>)listener;
- (void)unregisterPropertyBarListener:(id<IPropertyBarListener>)listener;

@end
