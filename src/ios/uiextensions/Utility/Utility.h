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
#import <MessageUI/MessageUI.h>

#import <ifaddrs.h>
#import <netinet/in.h>
#import <sys/socket.h>

#import <FoxitRDK/FSPDFObjC.h>
#import <FoxitRDK/FSPDFViewControl.h>

#import "../Const.h"
#import "../Defines.h"

typedef void(^CallBackInt)(long property,int value);

@class TaskServer;

#define FOXIT_LOG_ON YES

FOUNDATION_EXPORT void FoxitLog(NSString *format, ...);

typedef enum
{
    ScreenSizeMode_35 = 0,    //3.5 inches
    ScreenSizeMode_40,        //4 inches
    ScreenSizeMode_47,        //4.7 inches
    ScreenSizeMode_55,        //5.5 inches
    ScreenSizeMode_97         //9.7 inches
} ScreenSizeMode;


/**
 * @name Macro Definitions for icon type.
 */
/**@{*/
/** @brief note icon type Check. */
#define FPDF_ICONTYPE_NOTE_CHECK			0
/** @brief note icon type Circle. */
#define FPDF_ICONTYPE_NOTE_CIRCLE			1
/** @brief note icon type Comment. */
#define FPDF_ICONTYPE_NOTE_COMMENT			2
/** @brief note icon type Cross. */
#define FPDF_ICONTYPE_NOTE_CROSS			3
/** @brief note icon type Help. */
#define FPDF_ICONTYPE_NOTE_HELP				4
/** @brief note icon type Insert. */
#define FPDF_ICONTYPE_NOTE_INSERT			5
/** @brief note icon type Key. */
#define FPDF_ICONTYPE_NOTE_KEY				6
/** @brief note icon type New Paragraph. */
#define FPDF_ICONTYPE_NOTE_NEWPARAGRAPH		7
/** @brief note icon type Note. */
#define FPDF_ICONTYPE_NOTE_NOTE				8
/** @brief note icon type Paragraph. */
#define FPDF_ICONTYPE_NOTE_PARAGRAPH		9
/** @brief note icon type Right Arrow. */
#define FPDF_ICONTYPE_NOTE_RIGHTARROW		10
/** @brief note icon type Right Pointer. */
#define FPDF_ICONTYPE_NOTE_RIGHTPOINTER		11
/** @brief note icon type Star. */
#define FPDF_ICONTYPE_NOTE_STAR				12
/** @brief note icon type Up Arrow. */
#define FPDF_ICONTYPE_NOTE_UPARROW			13
/** @brief note icon type Upleft Arrow. */
#define FPDF_ICONTYPE_NOTE_UPLEFTARROW		14

/** @brief file attachment icon type Graph. */
#define FPDF_ICONTYPE_FILEATTACH_GRAPH		0
/** @brief file attachment icon type PushPin. */
#define FPDF_ICONTYPE_FILEATTACH_PUSHPIN	1
/** @brief file attachment icon type PaperClip. */
#define FPDF_ICONTYPE_FILEATTACH_PAPERCLIP	2
/** @brief file attachment icon type Tag. */
#define FPDF_ICONTYPE_FILEATTACH_TAG		3

/** @brief Unknown icon type. */
#define FPDF_ICONTYPE_UNKNOWN				-1
/**@}*/

#define UX_BG_COLOR_NIGHT_PAGEVIEW		0xFF00001b
#define UX_TEXT_COLOR_NIGHT             0xFF5d5b71

@interface Utility : NSObject
{}
//get the xib name according to iPhone or iPad
+ (NSString *)getXibName:(NSString *)baseXibName;
/** @brief display date in yyyy-MM-dd HH:mm formate. */
+ (NSString *)displayDateInYMDHM:(NSDate *)date;
/** @brief display date in "yyyy-MM-dd HH:mm" or "yyyyMMddHHmm". */
+ (NSString *)displayDateInYMDHM:(NSDate *)date hasSymbol:(BOOL)hasSymbol;
/** @brief Verify if point is in polygon. */
+ (BOOL)isPointInPolygon:(CGPoint)p polygonPoints:(NSArray*)polygonPoints;
/** @Get Rect by two points. */
+ (CGRect)convertToCGRect:(CGPoint)p1 p2:(CGPoint)p2;
/** @Convert rect to insets. */
+ (UIEdgeInsets)convertCGRect2Insets:(CGRect)rect size:(CGSize)size;
/** @Convert rect with margin. */
+ (CGRect)convertCGRectWithMargin:(CGRect)rect size:(CGSize)size margin:(int)margin;
/** @brief Get Rect by two points. */
+ (FSRectF *)convertToFSRect:(FSPointF *)p1 p2:(FSPointF *)p2;
/** @brief Standard Rect. */
+ (CGRect)getStandardRect:(CGRect)rect;
/** @brief Get UUID. */
+ (NSString *)getUUID;
/** @brief Get the texts bounds. */
+ (CGSize)getTextSize:(NSString*)text fontSize:(float)fontSize maxSize:(CGSize)maxSize;
/** @brief Get the texts size from attributed string. */
+ (CGSize)getAttributedTextSize:(NSAttributedString *)attributedString maxSize:(CGSize)maxSize;
/** @brief Get the adjusted size according to current scale. */
+ (CGFloat)realPX:(CGFloat)wantPX;
/** @brief Get all the annotations from page. */
+ (NSArray<FSAnnot *> *)getAnnotsInPage:(FSPDFPage*)page predicateBlock:(BOOL (^)(FSAnnot * _Nonnull))predicateBlock;
+ (NSArray<FSAnnot*>*)getAnnotationsOfType:(enum FS_ANNOTTYPE)type inPage:(FSPDFPage*)page;
/** @brief Whether markup annot is a caret. */
+ (BOOL)isReplaceText:(FSStrikeOut*)markup;
+ (FSRectF*)getCaretAnnotRect:(FSMarkup*)markup;
/** @brief Apply alpha with the origin image. */
+ (UIImage *)imageByApplyingAlpha:(UIImage*)image alpha:(CGFloat) alpha;
/** @brief Get text selection handler from specified page. */
+ (FSPDFTextSelect*)getTextSelect:(FSPDFDoc*)doc pageIndex:(int)index;
/** @brief Get array of text rectangles in specified text index range */
+ (NSArray*)getTextRects:(FSPDFTextSelect*)fstextPage start:(int)start count:(int)count;
/** @brief Get word range of specified text index */
+ (NSRange)getWordByTextIndex:(int)index textPage:(FSPDFTextSelect*)fstextPage;
/** @brief Verify file type */
+ (BOOL)isGivenPath:(NSString*)path type:(NSString*)type;
+ (BOOL)isGivenExtension:(NSString*)extension type:(NSString*)type;

#pragma mark -
/** @brief Convert bitmap buffer to UImage. */
+ (UIImage*)dib2img:(void*)pBuf size:(int)size dibWidth:(int)dibWidth dibHeight:(int)dibHeight withAlpha:(BOOL)withAlpha;
+ (UIImage*)rgbDib2img:(const void*)pBuf size:(int)size dibWidth:(int)dibWidth dibHeight:(int)dibHeight withAlpha:(BOOL)withAlpha freeWhenDone:(BOOL)b;
/** @brief Compare the two rect. */
+ (BOOL)rectEqualToRect:(FSRectF *)rect rect:(FSRectF *)rect1;
+ (BOOL)quadsEqualToQuads:(FSQuadPoints*)quads1 quads:(FSQuadPoints*)quads2;
+ (BOOL)pointEqualToPoint:(FSPointF*)point1 point:(FSPointF*)point2;
+ (BOOL)inkListEqualToInkList:(FSPDFPath*)inkList1 inkList:(FSPDFPath*)inkList2;

+ (CGRect)FSRectF2CGRect:(FSRectF*)fsrect;
+ (FSRectF*)CGRect2FSRectF:(CGRect)rect;

+ (NSDate*)convertFSDateTime2NSDate:(FSDateTime *)time;
+ (FSDateTime *)convert2FSDateTime:(NSDate*)date;

/** @brief Draw a page tumbnail with specified PDF document and page index. */
+ (UIImage *)drawPageThumbnailWithPDFPath:(NSString *)pdfPath pageIndex:(int)pageIndex pageSize:(CGSize)size;
/** @brief Get page size from specified PDF document and page index. */
+ (CGSize)getPDFPageSizeWithIndex:(NSUInteger)index pdfPath:(NSString *)path;
/** @brief Get security type of specified PDF document. */
+ (enum FS_ENCRYPTTYPE)getDocumentSecurityType:(NSString*)filePath taskServer:(TaskServer*)taskServer;

+ (NSString*)convert2SysFontString:(NSString*)str;

+ (CGSize)getTestSize:(UIFont*)font;

/** @brief Get mininum horizontal/vertical margin of annotation. Called when add a new annot at the edge of page. */
+ (float)getAnnotMinXMarginInPDF:(FSPDFViewCtrl*)pdfViewCtrl pageIndex:(int)pageIndex;
+ (float)getAnnotMinYMarginInPDF:(FSPDFViewCtrl*)pdfViewCtrl pageIndex:(int)pageIndex;

+ (float)convertWidth:(float)width fromPageViewToPDF:(FSPDFViewCtrl*)pdfViewCtrl pageIndex:(int)pageIndex;

/* get annot rect in page view, taken acount of zoom factor */
+ (CGRect)getAnnotRect:(FSAnnot*)annot pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl;
+ (UIImage*)getAnnotImage:(FSAnnot*)annot pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl;
+ (UIImage *)drawPage:(FSPDFPage*)page targetSize:(CGSize)targetSize shouldDrawAnnotation:(BOOL)shouldDrawAnnotation isNightMode:(BOOL)isNightMode;

+ (int)toStandardFontID:(NSString*)fontName;

+ (FSRectF*)normalizeFSRect:(FSRectF*)dibRect;
+ (CGRect)normalizeCGRect:(CGRect)rect;
+ (FSRectF*)makeFSRectWithLeft:(float)left top:(float)top right:(float)right bottom:(float)bottom;
+ (FSPointF*)makeFSPointWithX:(float)x y:(float)y;

+ (NSString*)getErrorCodeDescription:(enum FS_ERRORCODE)error;

+ (FSAnnot*)getAnnotByNM:(NSString*)nm inPage:(FSPDFPage*)page;
+ (FSRectF*)cloneRect:(FSRectF*)rect;
+ (FSPointF*)clonePoint:(FSPointF*)point;
+ (FSPDFPath*)cloneInkList:(FSPDFPath*)inkList;

+(UIImage*)scaleToSize:(UIImage*)oriImage size:(CGSize)size;
+ (NSString *)getThumbnailName:(NSString *)path;

+ (BOOL)isPDFPath:(NSString*)path;
+ (BOOL)isPDFExtension:(NSString*)extension;
+ (BOOL)isSupportFormat:(NSString*)path;
+ (NSString*)getIconName:(NSString*)path;
+ (NSString *)displayFileSize:(unsigned long long)byte;

+ (ScreenSizeMode)getScreenSizeMode;

+ (NSString*)getAttachmentTempFilePath:(FSFileAttachment*)attachment;
+ (NSString*)getDocumentAttachmentTempFilePath:(FSFileSpec*)attachmentFile PDFPath:(NSString*)PDFPath;
+ (BOOL)loadAttachment:(FSFileAttachment*)annot toPath:(NSString*)attachmentPath;
+ (BOOL)loadFileSpec:(FSFileSpec*)fileSpec toPath:(NSString*)path;

+ (NSString*)getStringMD5:(NSString*)string;

+ (FSBitmap*)imgDataToBitmap:(NSData*)imgData;

+ (NSDictionary<NSString*, FSPDFObject*> *)getNSDictionaryFromPDFDictionary:(FSPDFDictionary*)pdfDict;

+ (int)getIconTypeWithIconName:(NSString*)iconName annotType:(enum FS_ANNOTTYPE)annotType;
+ (NSString*)getIconNameWithIconType:(int)iconType annotType:(enum FS_ANNOTTYPE)annotType;
+ (BOOL)isValidIconName:(NSString*)iconName annotType:(enum FS_ANNOTTYPE)annotType;
+ (NSArray<NSString *> *)getAllIconLowercaseNames;

+(BOOL)isOwnerOfDoucment:(FSPDFDoc*)document;
+(BOOL)isDocumentSigned:(FSPDFDoc*)document;
+(BOOL)canAddAnnotToDocument:(FSPDFDoc*)document;
+(BOOL)canCopyTextInDocument:(FSPDFDoc*)document;
+(BOOL)canFillFormInDocument:(FSPDFDoc*)document;
+(BOOL)canAddSignToDocument:(FSPDFDoc*)document;
+(BOOL)canAssembleDocument:(FSPDFDoc*)document;
+(BOOL)canCopyForAssessInDocument:(FSPDFDoc*)document;
+ (BOOL)canModifyContentsInDocument:(FSPDFDoc*)document;
+ (BOOL)canExtractContentsInDocument:(FSPDFDoc*)document;
+ (int)getMDPDigitalSignPermissionInDocument:(FSPDFDoc*)document;

+ (void)assignImage:(UIImageView *)imageView rawFrame:(CGRect)frame image:(UIImage *)image;

+ (NSArray *)searchFilesWithFolder:(NSString *)folder recursive:(BOOL)recursive;

+ (void)tryLoadDocument:(FSPDFDoc*)document withPassword:(NSString*)password success:(void(^)(NSString* password))success error:(void(^)(NSString* description))error abort:(void(^)())abort;

@end
