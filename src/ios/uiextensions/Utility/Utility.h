/**
 * Copyright (C) 2003-2016, Foxit Software Inc..
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

#import <FoxitRDK/FSPDFObjc.h>
#import <FoxitRDK/FSPDFViewControl.h>

typedef void(^CallBackInt)(long property,int value);

@class TaskServer;

#define FOXIT_LOG_ON YES

FOUNDATION_EXPORT void FoxitLog(NSString *format, ...);

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
+ (NSArray *)getAnnots:(FSPDFPage*)page;
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
/** @brief Compare the two rect. */
+ (BOOL)rectEqualToRect:(FSRectF *)rect rect:(FSRectF *)rect1;

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

+ (int)toStandardFontID:(NSString*)fontName;

+ (FSRectF*)normalizeFSRect:(FSRectF*)dibRect;
+ (CGRect)normalizeCGRect:(CGRect)rect;
+ (FSRectF*)makeFSRectWithLeft:(float)left top:(float)top right:(float)right bottom:(float)bottom;

+ (NSString*)getErrorCodeDescription:(enum FS_ERRORCODE)error;
@end
