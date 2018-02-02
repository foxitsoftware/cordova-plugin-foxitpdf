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

#import <FoxitRDK/FSPDFViewControl.h>
#import <UIKit/UIKit.h>

@class AnnotationSignature;
@class SignatureListViewController;

@protocol SignatureListDelegate <NSObject>
- (void)signatureListViewController:(SignatureListViewController *)signatureListViewController openSignature:(AnnotationSignature *)signature;
- (void)signatureListViewController:(SignatureListViewController *)signatureListViewController selectSignature:(AnnotationSignature *)signature;
- (void)signatureListViewController:(SignatureListViewController *)signatureListViewController deleteSignature:(AnnotationSignature *)signature;
- (void)cancelSignature;
@end

@interface SignatureListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *signatureArray;
@property (nonatomic, strong) NSMutableDictionary *selectDict;
@property (nonatomic, strong) NSMutableDictionary *refreshDict;
@property (nonatomic, strong) NSString *currentName;
@property (nonatomic, assign) BOOL isFieldSigList;
@property (nonatomic, weak) id<SignatureListDelegate> delegate;

@end
