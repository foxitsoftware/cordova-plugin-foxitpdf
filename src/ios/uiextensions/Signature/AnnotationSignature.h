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
#import "UIExtensionsManager+Private.h"

#define SETTING_SIGNATURE  @"Annotation_Signature"
#define SETTING_SIGNATURE_OPTION  @"Annotation_Signature_Option"
#define SETTING_SIGNATURE_SELECTED  @"Annotation_Signature_Selected"

@interface AnnotationSignature: NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *contents;
@property (nonatomic, assign) CGRect rectSigPart;
@property (nonatomic, assign) int diameter;
@property (nonatomic, copy) NSString *certFileName;
@property (nonatomic, copy) NSString *certPasswd;
@property (nonatomic, copy) NSString *certMD5;
@property (nonatomic, assign) int pageIndex;
@property (nonatomic, assign) int color;
@property (nonatomic, assign) int opacity;
@property (nonatomic, strong) FSRectF* rect;
@property (nonatomic, strong) NSString* author;
@property (nonatomic, strong) FSAnnot* signature;
@property (nonatomic, strong) FSBitmap* dib;
@property (nonatomic, strong) NSData *data;

+ (AnnotationSignature *)createWithDefaultOptionForPageIndex:(int)pageIndex rect:(FSRectF*)rect;

+ (NSMutableArray*)getSignatureList;

+ (UIImage*)getSignatureImage:(NSString*)name;
+ (void)setSignatureImage:(NSString*)name img:(UIImage*)img;
+ (void)setCertFileToSiganatureSpace:(NSString *)name path:(NSString *)path;

+ (NSData*)getSignatureData:(NSString*)name;
+ (NSData*)getSignatureDib:(NSString*)name;
+ (void)setSignatureDib:(NSString*)name data:(NSData*)data;
+ (void)removeSignatureResource:(NSString*)name;
+ (AnnotationSignature*)getSignature:(NSString*)name;
- (NSString*)add;
- (void)update;
- (void)remove;

+ (AnnotationSignature*)getSignatureOption;
- (void)setOption;
+ (NSString*)getSignatureSelected;
+ (void)setSignatureSelected:(NSString*)name;

+ (NSMutableArray*)getCertSignatureList;
@end
