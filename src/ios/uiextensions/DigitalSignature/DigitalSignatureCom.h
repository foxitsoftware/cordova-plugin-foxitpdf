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

#ifndef DigitalSignatureCom_h
#define DigitalSignatureCom_h

#import <FoxitRDK/FSPDFObjC.h>

@interface CERT_INFO : NSObject
@property (nonatomic, copy) NSString*	certSerialNum;
@property (nonatomic, copy) NSString*	certPublisher;
@property (nonatomic, copy) NSString*	certStartDate;
@property (nonatomic, copy) NSString*	certEndDate;
@property (nonatomic, copy) NSString*	certEmailInfo;
@property (nonatomic, strong) FSDateTime* signDate;
@property (nonatomic, assign) const unsigned int* byteRangeArray;
@property (nonatomic, assign) int sizeofArray;
@end

@interface DIGITALSIGNATURE_PARAM : NSObject
@property (nonatomic, copy) NSString*	certFile;
@property (nonatomic, copy) NSString*	certPwd;
@property (nonatomic, copy) NSString*	subfilter;
@property (nonatomic, copy) NSString*	signFilePath;
@property (nonatomic, copy) NSString*	imagePath;
@property (nonatomic, strong) FSRectF* rect;
@property (nonatomic, copy) NSString*   sigName;
@end


#define P12FILESCANFERROR -10
#define P12FILEPASSWDERROR -11

#endif /* DigitalSignatureCom_h */
