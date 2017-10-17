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

#import "../Thirdparties/TSAlertView/TSAlertView.h"
#import "UIExtensionsManager+Private.h"
#import <Foundation/Foundation.h>
#import <FoxitRDK/FSPDFViewControl.h>

@interface PasswordModule : NSObject <TSAlertViewDelegate>

@property (nonatomic, strong) FSPDFDoc *pdfDoc;
@property (nonatomic, copy) NSString *inputPassword;

- (instancetype)initWithExtensionsManager:(UIExtensionsManager *)extensionsManager;

- (void)tryLoadPDFDocument:(FSPDFDoc *)document guessPassword:(NSString *)guessPassword success:(void (^)(NSString *password))success error:(void (^)(NSString *description))error abort:(void (^)())abort;
@end
