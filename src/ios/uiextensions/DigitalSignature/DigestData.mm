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

#import "DigestData.h"

//Construct and Destruct functions.

FS_DigestContext::FS_DigestContext() {
    m_pDigestData = NULL;
}

FS_DigestContext::~FS_DigestContext() {
    if (NULL != m_pDigestData) {
        delete m_pDigestData;
        m_pDigestData = NULL;
    }
}

//Initialize function.
void FS_DigestContext::Initialize() {
}

//Finalize function.
void FS_DigestContext::Release() {
}

//Set variable m_pDigestData.
BOOL FS_DigestContext::SetData(void *file, const unsigned int *byteRangeArray, unsigned int sizeofArray) {
    if (NULL != m_pDigestData) {
        delete m_pDigestData;
        m_pDigestData = NULL;
    }

    FS_DigestData *pData = new FS_DigestData;
    pData->m_file = file;
    pData->m_pByteRangeArray = byteRangeArray;
    pData->m_sizeofArray = sizeofArray;

    m_pDigestData = pData;

    return TRUE;
}

//Get variable m_pDigestData.
BOOL FS_DigestContext::GetData(FS_DigestData *&data) {
    data = m_pDigestData;
    return TRUE;
}
