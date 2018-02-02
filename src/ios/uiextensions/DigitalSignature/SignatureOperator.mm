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

#define FREE_CERT_KEY        \
    if (pkey)                \
        EVP_PKEY_free(pkey); \
    if (x509)                \
        X509_free(x509);     \
    if (ca)                  \
        sk_X509_free(ca);

#import "SignatureOperator.h"

@implementation CERT_INFO

@end

@implementation DIGITALSIGNATURE_PARAM

@end

static void HexCryptBuffer(const char *pOriginBuf, unsigned int nOriginLen, char *pCryptedBuf);
static time_t getTimeFromASN1(const ASN1_TIME *aTime);

int parseP12File(NSString *path, NSString *pwd, EVP_PKEY **pkey, X509 **x509, STACK_OF(X509) * *ca) {
    FILE *fp = NULL;
    if (!(fp = fopen([path UTF8String], "rb"))) {
        fprintf(stderr, "Error opening file %s\n", [path UTF8String]);
        return 0;
    }

    PKCS12 *p12 = d2i_PKCS12_fp(fp, NULL);
    fclose(fp);
    if (!p12) {
        fprintf(stderr, "Error reading PKCS#12 file\n");
        ERR_print_errors_fp(stderr);
        return P12FILESCANFERROR;
    }

    if (!PKCS12_parse(p12, [pwd UTF8String], pkey, x509, ca)) {
        fprintf(stderr, "Error parsing PKCS#12 file\n");
        return P12FILEPASSWDERROR;
    }

    PKCS12_free(p12);
    if (!pkey) {
        ERR_print_errors_fp(stderr);
        return 0;
    }
    return 1;
}

int getCertInfo(NSString *path, NSString *pwd, CERT_INFO *info) {
    FILE *fp = NULL;
    if (!(fp = fopen([path UTF8String], "rb"))) {
        fprintf(stderr, "Error opening file %s\n", [path UTF8String]);
        return 0;
    }

    PKCS12 *p12 = d2i_PKCS12_fp(fp, NULL);
    fclose(fp);
    if (!p12) {
        fprintf(stderr, "Error reading PKCS#12 file\n");
        ERR_print_errors_fp(stderr);
        return P12FILESCANFERROR;
    }
    X509 *cert = NULL;
    STACK_OF(X509) *ca = NULL;
    EVP_PKEY *pkey = NULL;

    if (!PKCS12_parse(p12, [pwd UTF8String], &pkey, &cert, &ca)) {
        fprintf(stderr, "Error parsing PKCS#12 file\n");
        return P12FILEPASSWDERROR;
    }

    ASN1_INTEGER *serial = X509_get_serialNumber(cert);
    char pHexData[256] = {0};
    HexCryptBuffer((const char *) serial->data, serial->length, pHexData);
    info.certSerialNum = [NSString stringWithUTF8String:pHexData];

    char csbuf[256] = {0};
    X509_NAME *issuerName = X509_get_issuer_name(cert);
    int issuerNameCount = X509_NAME_entry_count(issuerName);
    ASN1_STRING *vlaue = NULL;
    for (int i = 0; i < issuerNameCount; i++) {
        X509_NAME_ENTRY *issuerNameEntry = X509_NAME_get_entry(issuerName, i);
        long Nid = OBJ_obj2nid(issuerNameEntry->object);
        if (Nid == NID_commonName) {
            vlaue = issuerNameEntry->value;
            break;
        }
        vlaue = NULL;
    }

    memset(csbuf, 256 * sizeof(char), 0);
    X509_NAME_get_text_by_NID(issuerName, NID_commonName, csbuf, 256);
    if (vlaue->type == V_ASN1_BMPSTRING) {
        info.certPublisher = [[NSString alloc] initWithBytes:csbuf length:strlen(csbuf) encoding:NSUTF8StringEncoding];
    } else {
        info.certPublisher = [NSString stringWithUTF8String:csbuf];
    }

    X509_NAME *subjectName = X509_get_subject_name(cert);
    int subjectNameCount = X509_NAME_entry_count(subjectName);
    ASN1_STRING *vlaue2 = NULL;
    for (int i = 0; i < subjectNameCount; i++) {
        X509_NAME_ENTRY *subjectEntry = X509_NAME_get_entry(subjectName, i);
        long Nid = OBJ_obj2nid(subjectEntry->object);
        if (Nid == NID_pkcs9_emailAddress) {
            vlaue2 = subjectEntry->value;
            break;
        }
        vlaue2 = NULL;
    }

    memset(csbuf, 256 * sizeof(char), 0);
    X509_NAME_get_text_by_NID(subjectName, NID_pkcs9_emailAddress, csbuf, 256);
    if (vlaue2->type == V_ASN1_BMPSTRING) {
        info.certEmailInfo = [[NSString alloc] initWithBytes:csbuf length:strlen(csbuf) encoding:NSUTF8StringEncoding];
    } else {
        info.certEmailInfo = [NSString stringWithUTF8String:csbuf];
    }

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    ASN1_TIME *startTime = X509_getm_notBefore(cert);
    time_t timeStart = getTimeFromASN1(startTime);
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:timeStart];
    info.certStartDate = [dateFormatter stringFromDate:startDate];

    ASN1_TIME *endTime = X509_getm_notAfter(cert);
    time_t timeEnd = getTimeFromASN1(endTime);
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:timeEnd];
    info.certEndDate = [dateFormatter stringFromDate:endDate];
    X509_free(cert);
    EVP_PKEY_free(pkey);

    return 1;
}

static void HexCryptBuffer(const char *pOriginBuf, unsigned int nOriginLen, char *pCryptedBuf) {
    char *pCB = pCryptedBuf;
    unsigned int i;
    for (i = 0; i < nOriginLen; i++) {
        int b = (*pOriginBuf & 0xF0) >> 4;
        *pCB++ = (b <= 9) ? b + '0' : (b - 10) + 'A';
        b = *pOriginBuf & 0x0F;
        *pCB++ = (b <= 9) ? b + '0' : (b - 10) + 'A';
        pOriginBuf++;
    }
}

static time_t getTimeFromASN1(const ASN1_TIME *aTime) {
    time_t lResult = 0;

    char lBuffer[24];
    char *pBuffer = lBuffer;

    size_t lTimeLength = aTime->length;
    char *pString = (char *) aTime->data;

    if (aTime->type == V_ASN1_UTCTIME) {
        if ((lTimeLength < 11) || (lTimeLength > 17)) {
            return 0;
        }

        memcpy(pBuffer, pString, 10);
        pBuffer += 10;
        pString += 10;
    } else {
        if (lTimeLength < 13) {
            return 0;
        }

        memcpy(pBuffer, pString, 12);
        pBuffer += 12;
        pString += 12;
    }

    if ((*pString == 'Z') || (*pString == '-') || (*pString == '+')) {
        *(pBuffer++) = '0';
        *(pBuffer++) = '0';
    } else {
        *(pBuffer++) = *(pString++);
        *(pBuffer++) = *(pString++);
        // Skip any fractional seconds...
        if (*pString == '.') {
            pString++;
            while ((*pString >= '0') && (*pString <= '9')) {
                pString++;
            }
        }
    }

    *(pBuffer++) = 'Z';
    *(pBuffer++) = '\0';

    time_t lSecondsFromUCT;
    if (*pString == 'Z') {
        lSecondsFromUCT = 0;
    } else {
        if ((*pString != '+') && (pString[5] != '-')) {
            return 0;
        }

        lSecondsFromUCT = ((pString[1] - '0') * 10 + (pString[2] - '0')) * 60;
        lSecondsFromUCT += (pString[3] - '0') * 10 + (pString[4] - '0');
        if (*pString == '-') {
            lSecondsFromUCT = -lSecondsFromUCT;
        }
    }

    tm lTime;
    lTime.tm_sec = ((lBuffer[10] - '0') * 10) + (lBuffer[11] - '0');
    lTime.tm_min = ((lBuffer[8] - '0') * 10) + (lBuffer[9] - '0');
    lTime.tm_hour = ((lBuffer[6] - '0') * 10) + (lBuffer[7] - '0');
    lTime.tm_mday = ((lBuffer[4] - '0') * 10) + (lBuffer[5] - '0');
    lTime.tm_mon = (((lBuffer[2] - '0') * 10) + (lBuffer[3] - '0')) - 1;
    lTime.tm_year = ((lBuffer[0] - '0') * 10) + (lBuffer[1] - '0');
    if (lTime.tm_year < 50) {
        lTime.tm_year += 100; // RFC 2459
    }
    lTime.tm_wday = 0;
    lTime.tm_yday = 0;
    lTime.tm_isdst = 0; // No DST adjustment requested

    lResult = timegm(&lTime);
    if ((time_t) -1 != lResult) {
        if (0 != lTime.tm_isdst) {
            lResult -= 3600; // mktime may adjust for DST  (OS dependent)
        }
        lResult += lSecondsFromUCT;
    } else {
        lResult = 0;
    }

    return lResult;
}
