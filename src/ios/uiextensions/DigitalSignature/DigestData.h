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

#import <Foundation/Foundation.h>
#import <openssl/sha.h>
#import <FoxitRDK/FSPDFObjC.h>

// FS_DigestData
class FS_DigestData
{
public:
    FS_DigestData(){}
    ~FS_DigestData(){}
public:
    FSSignature* m_pSig;
    void* m_file;
    const unsigned int* m_pByteRangeArray;
    unsigned int m_sizeofArray;
};

//FS_DigestContext
class FS_DigestContext
{
public:
    FS_DigestContext();
    ~FS_DigestContext();
public:
    //Initialize and Finalize functions.
    void	Initialize();
    void	Release();
    
    //Set variable m_pDigestData.
    BOOL	SetData(void* file, const unsigned int* byteRangeArray, unsigned int sizeofArray);
    //Get variable m_pDigestData.
    BOOL	GetData(FS_DigestData*& data);
    
public:
    FS_DigestData* m_pDigestData;
    SHA_CTX m_sSHA_CTX;
};

