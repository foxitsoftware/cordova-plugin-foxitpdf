/* ----------------------------------------------------------------------------
 * This file was automatically generated by SWIG (http://www.swig.org).
 * Version 2.0.6
 *
 * This file is not intended to be easily readable and contains a number of
 * coding conventions designed to improve portability and efficiency. Do not make
 * changes to this file unless you know what you are doing--modify the SWIG
 * interface file instead.
 * ----------------------------------------------------------------------------- */

/**
 * @file	FSPDFSecurity.h
 * @brief	This file contains definitions of object-c APIs for Foxit PDF SDK.
 */

#import "FSCommon.h"
/**
 * @brief	Enumeration for encryption type.
 *
 * @details	Values of this enumeration should be used alone.
 */
enum FS_ENCRYPTTYPE {
    /** @brief	Unknown encryption type. */
    e_encryptUnknown   =  -1,
    /** @brief	No encryption pattern. */
    e_encryptNone	  =	 0,
    /** @brief	Encryption type: password, which is the standard encryption. */
    e_encryptPassword	=	1,
    /** @brief	Encryption type: digital certificate encryption. */
    e_encryptCertificate	=	2,
    /** @brief	Encryption type: Foxit DRM encryption. */
    e_encryptFoxitDRM	=	3,
    /** @brief	Encryption type: customized encryption. */
    e_encryptCustom	=	4,
    /** @brief	Encryption type: Microsoft RMS encryption. */
    e_encryptRMS	=	5
};

/**
 * @brief	Class to represent the base class for other concrete security callback object.
 *
 * @note	This is just a base class. User should not inherit this class directly when implementing a security callback for any type of decryption and encryption.
 *			User should inherit any derived callback class of this base class.
 */
@interface FSSecurityCallback : NSObject
{
    /** @brief SWIG proxy related property, it's deprecated to use it. */
    void *swigCPtr;
    /** @brief SWIG proxy related property, it's deprecated to use it. */
    BOOL swigCMemOwn;
}
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(void*)getCptr;
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(id)initWithCptr: (void*)cptr swigOwnCObject: (BOOL)ownCObject;
/**
 * @brief	Get the encryption type of current security handler.
 *
 * @return	The encryption type.
 *			Please refer to {@link FS_ENCRYPTTYPE::e_encryptPassword FS_ENCRYPTTYPE::e_encryptXXX} values and this would be one these values.
 */
-(enum FS_ENCRYPTTYPE) getSecurityType;

/** @brief Free the object. */
-(void)dealloc;

@end

/**
 * @brief	Class to represent a callback object for certificate decryption.
 *
 * @note	User should inherit this callback class and implement the pure virtual functions (as callback functions).
 *			User can register their own certificate security callback object to Foxit PDF SDK, by function [FSLibrary registerSecurityCallback] with <i>filter</i> "Adobe.PubSec".
 *			Function [FSLibrary unregisterSecurityCallback] can be called to unregister the security callback object with the registered filter name.
 */
@interface FSCertificateSecurityCallback : FSSecurityCallback

/**
 * @brief	Get the encryption type of current security callback.
 *
 * @note	Caller should not override this function, otherwise there will be unexpected behavior.
 *
 * @return	The encryption type. It would always be {@link FS_ENCRYPTTYPE::e_encryptCertificate}.
 */
-(enum FS_ENCRYPTTYPE) getSecurityType;

/**
 * @brief	Get the PKCS12 format data buffer, usually it's a .pfx file.
 *
 * @param[in]  envelope    The PKCS#7 object which is referred to as the enveloped data.
 *
 * @return  The PKCS12 format data buffer.
 */
-(NSData *)getPKCS12: (NSData*)envelope;

/**
 * @brief	Get the password for the PKCS12 format data.
 *
 * @param[in]  pkcs12    The PKCS12 format data buffer.
 *
 * @return	The password string used to parse the PKCS12 object.
 */
-(NSString *)getPasswordForPKCS12: (NSData*)pkcs12;

-(void)dealloc;
@end

/**
 * @brief   Enumeration for Encryption Algorithm.
 *
 * @details Values of this enumeration should be used alone.
 */
enum FS_CIPHERTYPE {
    /** @brief  Not use encryption algorithm. */\
    e_cipherNone = 0,
    /** @brief  Use RC4 encryption algorithm, with the key length between 5-bytes and 16-bytes. */\
    e_cipherRC4 = 1,
    /** @brief  Use AES encryption algorithm, with the key length be 16-bytes or 32-bytes. */\
    e_cipherAES = 2
};


/**
 * @brief	Class to represent a security handler, used for encrypting PDF document.
 *
 * @details	Class ::FSSecurityHandler is the base class. It has following derived classes:
 *			<ul>
 *			<li> Class ::FSStdSecurityHandler is used for password encryption. </li>
 *			<li> Class ::FSCertificateSecurityHandler is used for certificate encryption.</li>
 *			</ul>
 *			To set a security handler to a PDF document, please call function {@link FSPDFDoc::setSecurityHandler:}, then the security handler will take effect during next saving process.
 *			To get the security handler used for a PDF document, please call function {@link FSPDFDoc::setSecurityHandler:}.
 */
@interface FSSecurityHandler : NSObject
{
    /** @brief SWIG proxy related property, it's deprecated to use it. */
    void *swigCPtr;
    /** @brief SWIG proxy related property, it's deprecated to use it. */
    BOOL swigCMemOwn;
}
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(void*)getCptr;
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(id)initWithCptr: (void*)cptr swigOwnCObject: (BOOL)ownCObject;
/**
 * @brief	Get the encryption type of current security handler.
 *
 * @return	The encryption type.
 *			Please refer to {@link FS_ENCRYPTTYPE::e_encryptPassword FS_ENCRYPTTYPE::e_encryptXXX} values and this would be one these values.
 */
-(enum FS_ENCRYPTTYPE) getSecurityType;

/** @brief Free the object. */
-(void)dealloc;

@end

/**
 * @brief	Class to represent a security handler, used for encrypting PDF document.
 *
 * @details	Class ::FSSecurityHandler is the base class. It has following derived classes:
 *			<ul>
 *			<li> Class ::FSStdSecurityHandler is used for password encryption. </li>
 *			<li> Class ::FSCertificateSecurityHandler is used for certificate encryption.</li>
 *			</ul>
 *			To set a security handler to a PDF document, please call function {@link FSPDFDoc::setSecurityHandler:}, then the security handler will take effect during next saving process.
 *			To get the security handler used for a PDF document, please call function {@link FSPDFDoc::setSecurityHandler:}.
 */
@interface FSStdSecurityHandler : FSSecurityHandler

+ (FSStdSecurityHandler*)create;
/**
 * @brief Initialize the standard security handler.
 *
 * @param[in]	userPermissions		The user permissions, see {@link FS_USERPERMISSIONS::e_permPrint FS_USERPERMISSIONS::e_permXXX} values and this would be one or combination of its values.
 * @param[in]	userPassword		The user password, which is used to open the PDF document.
 * @param[in]	ownerPassword		The owner password, which is used to take ownership of the PDF document.
 * @param[in]	cipher				See {FS_CIPHERTYPE::e_cipherXXX} values. e_cipherNone is not allowed.
 * @param[in]	keyLen				The key length, in bytes.
 *									For FSCommonDefines::e_cipherRC4 cipher, this value should be between 5 and 16. The prefered one should be 16.
 *									For FSCommonDefines::e_cipherAES cipher, this value should be 16 or 32.
 * @param[in]	encryptMetadata		Whether to encrypt metadata or not.
 *
 * @return YES if initialize successfully, else NO.
 */
-(BOOL)initialize:(unsigned int)userPermissions userPassword:(NSString*)userPassword ownerPassword:(NSString*)ownerPassword cipher:(enum FS_CIPHERTYPE)cipher keyLen:(int)keyLen encryptMetadata:(BOOL)encryptMetadata;

@end


/**
 * @brief	Class to represent a certificate security handler, used for certificate encryption.
 *
 * @see	FSSecurityHandler
 */
@interface FSCertificateSecurityHandler : FSSecurityHandler

/**
 * @brief	Create a certificate security handler object.
 *
 * @return	A new certificate security handler object.
 */
+(FSCertificateSecurityHandler*)create;

/**
 * @brief	Initialize current certificate security handler.
 *
 * @param[in]	x509Certificates	An array which each element specifies the binary buffer of x509 certificates.
 * @param[in]	cipher				Cipher type.
 *									Please refer to {FS_CIPHERTYPE::e_cipherXXX} values and this should be one of these values,
 *									except {@link FS_CIPHERTYPE::e_cipherNone}.
 * @param[in]	encryptMetadata		A boolean value that indicates whether to encrypt metadata or not.<br>
 *									<b>YES</b> means to encrypt metadata, and <b>NO</b> means not to encrypt metadata.
 *
 * @return	<b>YES</b> means success, while <b>FASLE</b> means failure.
 *
 * @exception	e_errParam		Value of input parameter is invalid.
 */
-(BOOL)initialize: (NSArray<NSData*>*)x509Certificates cipher: (enum FS_CIPHERTYPE)cipher encryptMetadata: (BOOL)encryptMetadata;

-(void)dealloc;

@end