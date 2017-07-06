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
#import "../DigitalSignature/DigitalSignatureCom.h"

@protocol IToolHandler;
@protocol IRotationEventListener;
@class AnnotationSignature;
@class UIExtensionsManager;

typedef void (^onDocChanging)(NSString* newDocPath);
typedef NSString* (^onGetDocPath)();

@interface SignToolHandler : NSObject<IToolHandler,IRotationEventListener, IDocEventListener>
{
    FSRectF* _signatureRect;
    CGSize _signatureOriginalSize;
    
    float _maxWidth;
    float _minWidth;
    float _maxHeight;
    float _minHeight;
}
@property (nonatomic, assign) BOOL isPerformOnce;
@property (nonatomic, assign) BOOL isAdded;
@property (nonatomic, assign) BOOL isDeleting;
@property (nonatomic, assign) CGPoint signatureStartPoint;
@property (nonatomic, strong) AnnotationSignature *signature;
@property (nonatomic, copy) onDocChanging docChanging;
@property (nonatomic, copy) onGetDocPath getDocPath;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;
-(void)changedSignImage;
-(void)signList;
- (void)onDocWillClose:(FSPDFDoc* )document;
-(void)delete;

- (FSSignature*) createSignature:(FSPDFPage*)page withParam:(DIGITALSIGNATURE_PARAM *)param;
- (BOOL) signSignature:(FSSignature*)sign withParam:(DIGITALSIGNATURE_PARAM *)param;
- (BOOL) verifyDigitalSignature:(NSString*)fileName signature:(FSSignature*)signature status:(int *)status;
- (void) initSignature:(FSSignature*)sign withParam:(DIGITALSIGNATURE_PARAM *)param;
- (void)openCreateSign;
@end
