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

#import "DigitalSignatureCom.h"
#import <Foundation/Foundation.h>
#import <openssl/err.h>
#import <openssl/evp.h>
#import <openssl/objects.h>
#import <openssl/pem.h>
#import <openssl/pkcs12.h>
#import <openssl/pkcs7.h>
#import <openssl/rand.h>
#import <openssl/rsa.h>
#import <openssl/ssl.h>
#import <openssl/x509.h>

int parseP12File(NSString *path, NSString *pwd, EVP_PKEY **pkey, X509 **x509, STACK_OF(X509) * *ca);
int getCertInfo(NSString *path, NSString *pwd, CERT_INFO *info);
