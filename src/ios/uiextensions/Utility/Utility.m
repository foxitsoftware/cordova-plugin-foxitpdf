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

#import <QuartzCore/QuartzCore.h>

#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <execinfo.h>

#import "Const.h"
#import "Masonry/MASConstraintMaker.h"
#import "Masonry/View+MASAdditions.h"
#import "TaskServer.h"
#import "Utility.h"
#import <ifaddrs.h>
#import <netinet/in.h>
#import <sys/socket.h>

#import "AlertView.h"
#import "ColorUtility.h"
#import "FSAnnotExtent.h"
#import "PrintRenderer.h"
#import "UIButton+EnlargeEdge.h"

#import <CommonCrypto/CommonDigest.h>
#import <FoxitRDK/FSPDFObjC.h>

#define DOCUMENT_PATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

void FoxitLog(NSString *format, ...) {
#if DEBUG
    if (FOXIT_LOG_ON) {
        va_list args;
        va_start(args, format);
        NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
        NSLog(@"%@", msg);
        va_end(args);
    }
#endif
}

typedef BOOL (^NeedPauseBlock)(void);

@interface FSPause : FSPauseCallback

@property (nonatomic, copy) NeedPauseBlock needPause;

@end

@implementation FSPause

+ (FSPause *)pauseWithBlock:(NeedPauseBlock)needPause {
    FSPause *pause = [[FSPause alloc] init];
    pause.needPause = needPause;
    return pause;
}

- (BOOL)needPauseNow {
    if (self.needPause) {
        return self.needPause();
    }
    return NO;
}

@end

@implementation Utility

//get the xib name according to iPhone or iPad
+ (NSString *)getXibName:(NSString *)baseXibName {
    NSString *xibName;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([baseXibName isEqualToString:@"FileManageListViewController"]) {
            xibName = @"FileManageViewController_iPhone";
        } else {
            xibName = [NSString stringWithFormat:@"%@_%@", baseXibName, @"iPhone"];
        }
    } else {
        if ([baseXibName isEqualToString:@"PasswordInputViewController"]) {
            xibName = @"PasswordInputViewController";
        } else if ([baseXibName isEqualToString:@"SettingViewController"]) {
            xibName = @"SettingViewController";
        } else if ([baseXibName isEqualToString:@"ContentViewController"]) {
            xibName = @"ContentViewController";
        } else if ([baseXibName isEqualToString:@"WifiSettingViewController"]) {
            xibName = @"WifiSettingViewController";
        } else {
            xibName = [NSString stringWithFormat:@"%@_%@", baseXibName, @"iPad"];
        }
    }
    return xibName;
}

//display date in yyyy-MM-dd HH:mm formate
+ (NSString *)displayDateInYMDHM:(NSDate *)date {
    return [Utility displayDateInYMDHM:date hasSymbol:YES];
}

+ (NSString *)displayDateInYMDHM:(NSDate *)date hasSymbol:(BOOL)hasSymbol {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:hasSymbol ? @"yyyy-MM-dd HH:mm" : @"yyyyMMddHHmm"];
    return [dateFormatter stringFromDate:date];
}

//Verify if point in polygon
+ (BOOL)isPointInPolygon:(CGPoint)p polygonPoints:(NSArray *)polygonPoints {
    CGMutablePathRef path = CGPathCreateMutable();
    [polygonPoints enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGPoint p = [obj CGPointValue];
        if (idx == 0) {
            CGPathMoveToPoint(path, NULL, p.x, p.y);
        } else {
            CGPathAddLineToPoint(path, NULL, p.x, p.y);
        }
    }];
    CGPathCloseSubpath(path);
    BOOL ret = CGPathContainsPoint(path, NULL, p, false);
    CGPathRelease(path);

    return ret;
}

+ (CGRect)convertToCGRect:(CGPoint)p1 p2:(CGPoint)p2 {
    return CGRectMake(MIN(p1.x, p2.x),
                      MIN(p1.y, p2.y),
                      fabs(p1.x - p2.x),
                      fabs(p1.y - p2.y));
}

+ (UIEdgeInsets)convertCGRect2Insets:(CGRect)rect size:(CGSize)size {
    return UIEdgeInsetsMake(rect.origin.y,
                            rect.origin.x,
                            size.height - rect.origin.y - rect.size.height,
                            size.width - rect.origin.x - rect.size.width);
}

+ (CGRect)convertCGRectWithMargin:(CGRect)rect size:(CGSize)size margin:(int)margin {
    CGRect newRect = rect;
    newRect.origin.x = MAX(0, rect.origin.x - margin);
    newRect.origin.y = MAX(0, rect.origin.y - margin);
    newRect.size.width = MIN(rect.origin.x + rect.size.width + margin, size.width) - newRect.origin.x;
    newRect.size.height = MIN(rect.origin.y + rect.size.height + margin, size.height) - newRect.origin.y;
    return newRect;
}

//Get Rect by two points
+ (FSRectF *)convertToFSRect:(FSPointF *)p1 p2:(FSPointF *)p2 {
    FSRectF *rect = [[FSRectF alloc] init];
    rect.left = MIN([p1 getX], [p2 getX]);
    rect.right = MAX([p1 getX], [p2 getX]);
    rect.top = MAX([p1 getY], [p2 getY]);
    rect.bottom = MIN([p1 getY], [p2 getY]);
    return rect;
}

+ (FSRectF *)inflateFSRect:(FSRectF *)rect width:(float)width height:(float)height
{
    if(!rect) return nil;
    FSRectF *innerRect = [[FSRectF alloc] init];
    innerRect.left = rect.left - width; innerRect.right = rect.right + width;
    innerRect.bottom = rect.bottom - height; innerRect.top = rect.top + height;
    return innerRect;
}

+ (BOOL)isPointInFSRect:(FSRectF *)rect point:(FSPointF*)point
{
    return point.x <= rect.right && point.x >= rect.left && point.y <= rect.top && point.y >= rect.bottom;
}

//Standard Rect
+ (CGRect)getStandardRect:(CGRect)rect {
    rect.origin.x = (int) rect.origin.x;
    rect.origin.y = (int) rect.origin.y;
    rect.size.width = (int) (rect.size.width + 0.5);
    rect.size.height = (int) (rect.size.height + 0.5);
    return rect;
}

//Get UUID
+ (NSString *)getUUID {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef strUUID = CFUUIDCreateString(NULL, uuid);
    NSString *ret = [(__bridge NSString *) strUUID lowercaseString];
    CFRelease(strUUID);
    CFRelease(uuid);
    return ret;
}

+ (CGSize)getTextSize:(NSString *)text fontSize:(float)fontSize maxSize:(CGSize)maxSize {
    if (nil == text)
        text = @""; //for getting correct text size as following.
    if (OS_ISVERSION7) {
        NSDictionary *attrs = @{NSFontAttributeName : [UIFont systemFontOfSize:fontSize]};
        CGSize textSize = [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
        textSize.width += 2;
        return textSize;
    } else {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        CGSize textSize = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:fontSize], NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;
        return textSize;
    }
}

// calculate Attributed String size
+ (CGSize)getAttributedTextSize:(NSAttributedString *)attributedString maxSize:(CGSize)maxSize {
    CGRect stringRect = [attributedString boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    stringRect.size.width += 4;
    return stringRect.size;
}

+ (CGFloat)realPX:(CGFloat)wantPX {
    if ([UIScreen mainScreen].scale == 0) {
        return wantPX;
    }
    return wantPX / [UIScreen mainScreen].scale;
}

+ (NSArray<FSAnnot *> *)getAnnotsInPage:(FSPDFPage *)page predicateBlock:(BOOL (^)(FSAnnot *_Nonnull))predicateBlock {
    NSMutableArray<FSAnnot *> *array = [NSMutableArray<FSAnnot *> array];
    int count = [page getAnnotCount];
    for (int i = 0; i < count; i++) {
        FSAnnot *fsannot = [page getAnnot:i];
        if (!fsannot.NM)
            fsannot.NM = [Utility getUUID];
        if (!fsannot) {
            continue;
        }
        if (predicateBlock && !predicateBlock(fsannot)) {
            continue;
        }
        [array addObject:fsannot];
    }
    return array;
}

+ (NSArray<FSAnnot *> *)getAnnotationsOfType:(FSAnnotType)type inPage:(FSPDFPage *)page {
    NSMutableArray<FSAnnot *> *array = [NSMutableArray<FSAnnot *> array];
    int count = [page getAnnotCount];
    for (int i = 0; i < count; i++) {
        FSAnnot *annot = [page getAnnot:i];
        if (annot && annot.type == type) {
            [array addObject:annot];
        }
    }
    return array;
}

+ (BOOL)isReplaceText:(FSMarkup *)annot {
    if (![annot isGrouped]) {
        return NO;
    }
    if (annot.type == e_annotStrikeOut) {
        for (int i = 0; i < [annot getGroupElementCount]; i++) {
            if ([annot getGroupElement:i].type == e_annotCaret) {
                return YES;
            }
        }
    } else if (annot.type == e_annotCaret) {
        for (int i = 0; i < [annot getGroupElementCount]; i++) {
            if ([annot getGroupElement:i].type == e_annotStrikeOut) {
                return YES;
            }
        }
    }
    return NO;
}

+ (FSRectF *)getCaretAnnotRect:(FSMarkup *)markup {
    if (![markup isGrouped]) {
        return markup.fsrect;
    }
    CGRect unionRect = CGRectZero;
    for (int i = 0; i < [markup getGroupElementCount]; i++) {
        FSAnnot *annot = [markup getGroupElement:i];
        if (i == 0) {
            unionRect = [self FSRectF2CGRect:annot.fsrect];
        } else {
            unionRect = CGRectUnion(unionRect, [self FSRectF2CGRect:annot.fsrect]);
        }
    }
    return [self CGRect2FSRectF:unionRect];
}

//copied from TbBaseItem
+ (UIImage *)imageByApplyingAlpha:(UIImage *)image alpha:(CGFloat)alpha {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx)
        return nil;

    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);

    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);

    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);

    CGContextSetAlpha(ctx, alpha);

    CGContextDrawImage(ctx, area, image.CGImage);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return newImage;
}

+ (FSPDFTextSelect *)getTextSelect:(FSPDFDoc *)doc pageIndex:(int)index;
{
    FSPDFTextSelect *textSelect = nil;
    FSPDFPage *page = [doc getPage:index];
    if (page)
        textSelect = [[FSPDFTextSelect alloc] initWithPDFPage:page];
    return textSelect;
}

//get word range of string, including space
+ (NSArray *)_getUnitWordBoundary:(NSString *)str {
    NSMutableArray *array = [NSMutableArray array];
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault,
                                                             (CFStringRef) str,
                                                             CFRangeMake(0, [str length]),
                                                             kCFStringTokenizerUnitWordBoundary,
                                                             NULL);
    CFStringTokenizerTokenType tokenType = kCFStringTokenizerTokenNone;
    while ((tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)) != kCFStringTokenizerTokenNone) {
        CFRange tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
        NSRange range = NSMakeRange(tokenRange.location, tokenRange.length);
        [array addObject:[NSValue valueWithRange:range]];
    }
    if (tokenizer) {
        CFRelease(tokenizer);
    }
    return array;
}

+ (NSRange)getWordByTextIndex:(int)index textPage:(FSPDFTextSelect *)fstextPage {
    __block NSRange retRange = NSMakeRange(index, 1);

    int pageTotalCharCount = 0;

    if (fstextPage != nil) {
        pageTotalCharCount = [fstextPage getCharCount];
    }

    int startIndex = MAX(0, index - 25);
    int endIndex = MIN(pageTotalCharCount - 1, index + 25);
    index -= startIndex;

    NSString *str = [fstextPage getChars:MIN(startIndex, endIndex) count:ABS(endIndex - startIndex) + 1];
    NSArray *array = [self _getUnitWordBoundary:str];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeValue];
        if (NSLocationInRange(index, range)) {
            NSString *tmp = [str substringWithRange:range];
            if ([tmp isEqualToString:@" "]) {
                NSUInteger nextIndex = idx + 1;
                if (nextIndex < array.count) {
                    range = [[array objectAtIndex:nextIndex] rangeValue];
                }
            }
            retRange = NSMakeRange(startIndex + range.location, range.length);
            *stop = YES;
        }
    }];
    return retRange;
}

+ (NSArray *)getTextRects:(FSPDFTextSelect *)fstextPage start:(int)start count:(int)count {
    NSMutableArray *ret = [NSMutableArray array];

    if (fstextPage != nil) {
        int rectCount = [fstextPage getTextRectCount:start count:count];
        for (int i = 0; i < rectCount; i++) {
            FSRectF *dibRect = [fstextPage getTextRect:i];
            if (dibRect.getLeft == dibRect.getRight || dibRect.getTop == dibRect.getBottom) {
                continue;
            }

            int direction = [fstextPage getBaselineRotation:i];
            NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGRect:[Utility FSRectF2CGRect:dibRect]], @(direction), nil];

            [ret addObject:array];
        }

        //merge rects if possible
        if (ret.count > 1) {
            int i = 0;
            while (i < ret.count - 1) {
                int j = i + 1;
                while (j < ret.count) {
                    FSRectF *rect1 = [Utility CGRect2FSRectF:[[[ret objectAtIndex:i] objectAtIndex:0] CGRectValue]];
                    FSRectF *rect2 = [Utility CGRect2FSRectF:[[[ret objectAtIndex:j] objectAtIndex:0] CGRectValue]];

                    int direction1 = [[[ret objectAtIndex:i] objectAtIndex:1] intValue];
                    int direction2 = [[[ret objectAtIndex:j] objectAtIndex:1] intValue];
                    BOOL adjcent = NO;
                    if (direction1 == direction2) {
                        adjcent = NO;
                    }
                    if (adjcent) {
                        FSRectF *rectResult = [[FSRectF alloc] init];
                        [rectResult set:MIN([rect1 getLeft], [rect2 getLeft]) bottom:MAX([rect1 getTop], [rect2 getTop]) right:MAX([rect1 getRight], [rect2 getRight]) top:MIN([rect1 getBottom], [rect2 getBottom])];
                        NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGRect:[Utility FSRectF2CGRect:rectResult]], @(direction1), nil];
                        [ret replaceObjectAtIndex:i withObject:array];
                        [ret removeObjectAtIndex:j];
                    } else {
                        j++;
                    }
                }
                i++;
            }
        }
    }

    return ret;
}

+ (BOOL)isGivenPath:(NSString *)path type:(NSString *)type {
    if ([type isEqualToString:@"*"]) {
        return YES;
    }
    NSString *dotType = [NSString stringWithFormat:@".%@", type];
    if ([path.pathExtension.lowercaseString isEqualToString:type.lowercaseString]) {
        return YES;
    } else if ([path.lowercaseString isEqualToString:dotType]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isGivenExtension:(NSString *)extension type:(NSString *)type {
    if ([type isEqualToString:@"*"]) {
        return YES;
    }
    return [extension.lowercaseString isEqualToString:type.lowercaseString];
}

#pragma mark - methods from DmUtil
#pragma mark Static method

static void _CGDataProviderReleaseDataCallback(void *info, const void *data, size_t size) {
    free((void *) data);
}

+ (UIImage *)dib2img:(void *)pBuf size:(int)size dibWidth:(int)dibWidth dibHeight:(int)dibHeight withAlpha:(BOOL)withAlpha {
    int bit = 3;
    if (withAlpha) {
        bit = 4;
    }
    unsigned char *buf = (unsigned char *) pBuf;
    int stride32 = dibWidth * bit;
    dispatch_apply(dibHeight, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t ri) {
        dispatch_apply(dibWidth, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t j) {
            long i = dibHeight - 1 - ri;
            unsigned char tmp = buf[i * stride32 + j * bit];
            buf[i * stride32 + j * bit] = buf[i * stride32 + j * bit + 2];
            buf[i * stride32 + j * bit + 2] = tmp;
        });
    });

    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pBuf, size, _CGDataProviderReleaseDataCallback);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    if (withAlpha) {
        bitmapInfo = bitmapInfo | kCGImageAlphaLast;
    }
    CGImageRef image = CGImageCreate(dibWidth, dibHeight, 8, withAlpha ? 32 : 24, dibWidth * (withAlpha ? 4 : 3),
                                     colorSpace, bitmapInfo,
                                     provider, NULL, YES, kCGRenderingIntentDefault);
    UIImage *img = [UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    CGImageRelease(image);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    return img;
}

+ (UIImage *)rgbDib2img:(const void *)pBuf size:(int)size dibWidth:(int)dibWidth dibHeight:(int)dibHeight withAlpha:(BOOL)withAlpha freeWhenDone:(BOOL)b {
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pBuf, size, b ? _CGDataProviderReleaseDataCallback : nil);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    if (withAlpha) {
        bitmapInfo = bitmapInfo | kCGImageAlphaLast;
    }
    CGImageRef image = CGImageCreate(dibWidth, dibHeight, 8, withAlpha ? 32 : 24, dibWidth * (withAlpha ? 4 : 3),
                                     colorSpace, bitmapInfo,
                                     provider, NULL, YES, kCGRenderingIntentDefault);
    UIImage *img = [UIImage imageWithCGImage:image
                                       scale:
                                           //                    1.0f
                                           [UIScreen mainScreen].scale
                                 orientation:UIImageOrientationUp];
    CGImageRelease(image);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    return img;
}

+ (BOOL)rectEqualToRect:(FSRectF *)rect rect:(FSRectF *)rect1 {
    if ([rect getLeft] == [rect1 getLeft] &&
        [rect getRight] == [rect1 getRight] &&
        [rect getTop] == [rect getTop] &&
        [rect getBottom] == [rect1 getBottom]) {
        return YES;
    }
    return NO;
}

+ (BOOL)quadsEqualToQuads:(FSQuadPoints *)quads1 quads:(FSQuadPoints *)quads2 {
    return [Utility pointEqualToPoint:[quads1 getFirst] point:[quads2 getFirst]] &&
           [Utility pointEqualToPoint:[quads1 getSecond]
                                point:[quads2 getSecond]] &&
           [Utility pointEqualToPoint:[quads1 getThird]
                                point:[quads2 getThird]] &&
           [Utility pointEqualToPoint:[quads1 getFourth]
                                point:[quads2 getFourth]];
}

+ (BOOL)pointEqualToPoint:(FSPointF *)point1 point:(FSPointF *)point2 {
    return fabsf(point1.x - point2.x) < 1e-4 &&
           fabsf(point1.y - point2.y) < 1e-4;
}

+ (BOOL)inkListEqualToInkList:(FSPDFPath *)inkList1 inkList:(FSPDFPath *)inkList2 {
    int count = [inkList1 getPointCount];
    if (count != [inkList2 getPointCount]) {
        return NO;
    }
    for (int i = 0; i < count; i++) {
        if (![Utility pointEqualToPoint:[inkList2 getPoint:i] point:[inkList2 getPoint:i]]) {
            return NO;
        }
        if ([inkList1 getPointType:i] != [inkList2 getPointType:i]) {
            return NO;
        }
    }
    return YES;
}

+ (CGRect)FSRectF2CGRect:(FSRectF *)fsrect {
    if (fsrect == nil) {
        return CGRectZero;
    }
    return CGRectMake(fsrect.getLeft, fsrect.getTop, (fsrect.getRight - fsrect.getLeft), (fsrect.getBottom - fsrect.getTop));
}

+ (FSRectF *)CGRect2FSRectF:(CGRect)rect {
    FSRectF *fsrect = [[FSRectF alloc] init];
    [fsrect set:rect.origin.x bottom:rect.origin.y + rect.size.height right:rect.origin.x + rect.size.width top:rect.origin.y];
    return fsrect;
}

+ (NSDate *)convertFSDateTime2NSDate:(FSDateTime *)time {
    if ([time getYear] > 10000 || [time getYear] == 0 ||
        [time getMonth] > 12 || [time getMonth] == 0 ||
        [time getDay] > 31 || [time getDay] == 0 ||
        [time getHour] > 24 ||
        [time getMinute] > 60 ||
        [time getSecond] > 60) {
        return nil;
    }

    unsigned short hour = [time getHour];
    unsigned short minute = [time getMinute];

    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:[time getYear]];
    [comps setMonth:[time getMonth]];
    [comps setDay:[time getDay]];
    [comps setHour:hour];
    [comps setMinute:minute];
    [comps setSecond:[time getSecond]];
    [comps setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:[time getUTHourOffset] * 3600 + [time getUTMinuteOffset] * 60]];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *date = [gregorian dateFromComponents:comps];
    return date;
}

+ (FSDateTime *)convert2FSDateTime:(NSDate *)date {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *comps = [gregorian components:unitFlags fromDate:date];
    FSDateTime *time = [[FSDateTime alloc] init];
    time.year = [comps year];
    time.month = [comps month];
    time.day = [comps day];
    time.hour = [comps hour];
    time.minute = [comps minute];
    time.second = [comps second];
    time.UTHourOffset = timezone / 3600 * -1;
    time.UTMinuteOffset = (labs(timezone) % 3600) / 60;
    return time;
}

CGPDFDocumentRef GetPDFDocumentRef(const char *filename) {
    CFStringRef path;
    CFURLRef url;
    CGPDFDocumentRef document;

    path = CFStringCreateWithCString(NULL, filename, kCFStringEncodingUTF8);

    url = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, 0);

    CFRelease(path);

    document = CGPDFDocumentCreateWithURL(url);

    if (document) {
        if (CGPDFDocumentGetNumberOfPages(document) == 0) {
            CGPDFDocumentRelease(document);
            document = nil;
            printf("`%s' needs at least onepage!\n", filename);
        }
    } else {
        printf("`%s' is corrupted.\n", filename);
    }

    CFRelease(url);
    return document;
}

+ (CGSize)getPDFPageSizeWithIndex:(NSUInteger)index pdfPath:(NSString *)path {
    @autoreleasepool {
        @synchronized(self) {
            @try {
                FSPDFDoc *fspdfdoc = [[FSPDFDoc alloc] initWithFilePath:path];
                FSErrorCode ret = [fspdfdoc load:nil];
                if(!ret)
                {
                    FSPDFPage* page = [fspdfdoc getPage:0];
                    return CGSizeMake([page getWidth], [page getHeight]);
                }
                return CGSizeMake(0, 0);
            }
            @catch(NSException* e)
            {
                return CGSizeMake(0, 0);
            }
        }
    }
}

+ (UIImage *)drawPageThumbnailWithPDFPath:(NSString *)pdfPath pageIndex:(int)pageIndex pageSize:(CGSize)size {
    @autoreleasepool {
        @synchronized(self) {
            @try {
                FSPDFDoc *fspdfdoc = [[FSPDFDoc alloc] initWithFilePath:pdfPath];
                FSErrorCode ret = [fspdfdoc load:nil];
                if(!ret)
                {
                    FSPDFPage* page = [fspdfdoc getPage:pageIndex];
                    return [Utility drawPage:page targetSize:size shouldDrawAnnotation:YES needPause:nil];
                }
                return nil;
            }
            @catch(NSException* e)
            {
                return nil;
            }
        }
    }
}

+ (FSEncryptType)getDocumentSecurityType:(NSString *)filePath taskServer:(TaskServer *_Nullable)taskServer {
    __block FSErrorCode ret = e_errUnknown;
    Task *task = [[Task alloc] init];
    task.run = ^() {
        FSModuleRight right = [FSLibrary getModuleRight:e_moduleNameStandard];
        if (right == e_moduleRightNone || right == e_moduleRightUnknown)
            return;
        @autoreleasepool {
            FSPDFDoc *fspdfdoc = [[FSPDFDoc alloc] initWithFilePath:filePath];
            ret = [fspdfdoc load:nil];
        }
    };
    if (!taskServer)
        taskServer = [[TaskServer alloc] init];
    [taskServer executeSync:task];

    if (ret == e_errSuccess) {
        return e_encryptNone;
    } else if (ret == e_errPassword) {
        return e_encryptPassword;
    } else if (ret == e_errHandler) {
        return e_encryptRMS;
    } else {
        return e_encryptCustom;
    }
}

+ (NSString *)convert2SysFontString:(NSString *)str {
    NSString *ret = str;
    if ([str isEqualToString:@"Times-Roman"]) {
        ret = @"TimesNewRomanPSMT";
    } else if ([str isEqualToString:@"Times-Bold"]) {
        ret = @"TimesNewRomanPS-BoldMT";
    } else if ([str isEqualToString:@"Times-Italic"]) {
        ret = @"TimesNewRomanPS-ItalicMT";
    } else if ([str isEqualToString:@"Times-BoldItalic"]) {
        ret = @"TimesNewRomanPS-BoldItalicMT";
    }
    return ret;
}

//Get test size by font
+ (CGSize)getTestSize:(UIFont *)font {
    return [@"WM" sizeWithAttributes:@{NSFontAttributeName : font}];
}

+ (float)getAnnotMinXMarginInPDF:(FSPDFViewCtrl *)pdfViewCtrl pageIndex:(int)pageIndex {
    CGRect pvRect = CGRectMake(0, 0, 10, 10);
    FSRectF *pdfRect = [pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:pageIndex];
    return pdfRect.right - pdfRect.left;
}

+ (float)getAnnotMinYMarginInPDF:(FSPDFViewCtrl *)pdfViewCtrl pageIndex:(int)pageIndex {
    CGRect pvRect = CGRectMake(0, 0, 10, 10);
    FSRectF *pdfRect = [pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:pageIndex];
    return pdfRect.top - pdfRect.bottom;
}

+ (float)convertWidth:(float)width fromPageViewToPDF:(FSPDFViewCtrl *)pdfViewCtrl pageIndex:(int)pageIndex {
    FSRectF *fsRect = [[FSRectF alloc] init];
    [fsRect set:0 bottom:width right:width top:0];
    CGRect pvRect = [pdfViewCtrl convertPdfRectToPageViewRect:fsRect pageIndex:pageIndex];
    return pvRect.size.width;
}

+ (CGRect)getAnnotRect:(FSAnnot *)annot pdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl {
    FSPDFPage *page = [pdfViewCtrl.currentDoc getPage:annot.pageIndex];
    if (page) {
        CGRect retRect = CGRectZero;
        FSMatrix *fsmatrix = [pdfViewCtrl getDisplayMatrix:annot.pageIndex];
        FSRectI *annotRect = [annot getDeviceRect:NO matrix:fsmatrix];
        retRect.origin.x = [annotRect getLeft];
        retRect.origin.y = [annotRect getTop];
        retRect.size.width = [annotRect getRight] - [annotRect getLeft];
        retRect.size.height = [annotRect getBottom] - [annotRect getTop];
        return retRect;
    }
    return CGRectZero;
}

+ (UIImage *)getAnnotImage:(FSAnnot *)annot pdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl {
    int pageIndex = annot.pageIndex;
    CGRect rect = [self getAnnotRect:annot pdfViewCtrl:pdfViewCtrl];
    if (annot.type == e_annotFreeText && [annot.subject isEqualToString:@"Textbox"]) {
        rect = CGRectInset(rect, -1, -1);
    }
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();

    FSMatrix *fsmatrix = [pdfViewCtrl getDisplayMatrix:pageIndex fromOrigin:CGPointMake(-rect.origin.x, -rect.origin.y)];
    FSRenderer *fsrenderer = nil;
    @try {
        fsrenderer = [FSRenderer createFromContext:context deviceType:e_deviceTypeDisplay];
    } @catch (NSException *exception) {
        UIGraphicsEndImageContext();
        return nil;
    }

    [fsrenderer setTransformAnnotIcon:NO];
    if (pdfViewCtrl.colorMode == e_colorModeMapping) {
        [fsrenderer setColorMode:e_colorModeMapping];
        [fsrenderer setMappingModeColors:pdfViewCtrl.mappingModeBackgroundColor.argbHex foreColor:pdfViewCtrl.mappingModeForegroundColor.argbHex];
    }
    [fsrenderer renderAnnot:annot matrix:fsmatrix];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

static const char *s_StandardFontNames[] = {
    "Courier",
    "Courier-Bold",
    "Courier-BoldOblique",
    "Courier-Oblique",
    "Helvetica",
    "Helvetica-Bold",
    "Helvetica-BoldOblique",
    "Helvetica-Oblique",
    "Times-Roman",
    "Times-Bold",
    "Times-BoldItalic",
    "Times-Italic",
    "Symbol",
    "ZapfDingbats"};

+ (int)toStandardFontID:(NSString *)fontName {
    for (int i = 0; i < sizeof(s_StandardFontNames) / sizeof(const char *); i++) {
        NSString *stdFontName = [NSString stringWithUTF8String:s_StandardFontNames[i]];
        if ([fontName isEqualToString:stdFontName]) {
            return i;
        }
    }
    return -1;
}

+ (FSRectF *)normalizeFSRect:(FSRectF *)dibRect {
    if (dibRect.left > dibRect.right) {
        float tmp = dibRect.left;
        dibRect.left = dibRect.right;
        dibRect.right = tmp;
    }
    if (dibRect.bottom > dibRect.top) {
        float tmp = dibRect.top;
        dibRect.top = dibRect.bottom;
        dibRect.bottom = tmp;
    }
    return dibRect;
}

+ (CGRect)normalizeCGRect:(CGRect)rect {
    if (rect.size.width < 0) {
        rect.origin.x += rect.size.width;
        rect.size.width = -rect.size.width;
    }
    if (rect.size.height < 0) {
        rect.origin.y += rect.size.height;
        rect.size.height = -rect.size.height;
    }
    return rect;
}

+ (FSRectF *)makeFSRectWithLeft:(float)left top:(float)top right:(float)right bottom:(float)bottom {
    FSRectF *rect = [[FSRectF alloc] init];
    [rect set:left bottom:bottom right:right top:top];
    return rect;
}

+ (FSPointF *)makeFSPointWithX:(float)x y:(float)y {
    FSPointF *point = [[FSPointF alloc] init];
    [point set:x y:y];
    return point;
}

+ (NSString *)getErrorCodeDescription:(FSErrorCode)error {
    switch (error) {
    case e_errSecurityHandler:
        return FSLocalizedString(@"kInvalidSecurityHandler");
    case e_errFile:
        return FSLocalizedString(@"kUnfoundOrCannotOpen");
    case e_errFormat:
        return FSLocalizedString(@"kInvalidFormat");
    case e_errPassword:
        return FSLocalizedString(@"kDocPasswordError");
    case e_errHandler:
        return FSLocalizedString(@"kHandlerError");
    case e_errCertificate:
        return FSLocalizedString(@"kWrongCertificate");
    case e_errUnknown:
        return FSLocalizedString(@"kUnknownError");
    case e_errInvalidLicense:
        return FSLocalizedString(@"kInvalidLibraryLicense");
    case e_errParam:
        return FSLocalizedString(@"kInvalidParameter");
    case e_errUnsupported:
        return FSLocalizedString(@"kUnsupportedType");
    case e_errOutOfMemory:
        return FSLocalizedString(@"kOutOfMemory");
    default:
        return @"";
    }
}

+ (FSAnnot *)getAnnotByNM:(NSString *)nm inPage:(FSPDFPage *)page {
    for (int i = 0; i < [page getAnnotCount]; i++) {
        FSAnnot *annot = [page getAnnot:i];
        if ([annot.NM isEqualToString:nm]) {
            return annot;
        }
    }
    return nil;
}

+ (FSRectF *)cloneRect:(FSRectF *)rect {
    FSRectF *clone = [[FSRectF alloc] init];
    [clone set:rect.left bottom:rect.bottom right:rect.right top:rect.top];
    return clone;
}

+ (FSPointF *)clonePoint:(FSPointF *)point {
    FSPointF *clone = [[FSPointF alloc] init];
    [clone set:point.x y:point.y];
    return clone;
}

+ (FSPDFPath *)cloneInkList:(FSPDFPath *)inkList {
    if (!inkList) {
        return nil;
    }
    int count = [inkList getPointCount];
    FSPDFPath *clone = [[FSPDFPath alloc] init];
    if (count > 0) {
        [clone moveTo:[inkList getPoint:0]];
    }
    FSPointF *pointZero = [Utility makeFSPointWithX:0 y:0];
    for (int i = 1; i < count; i++) {
        [clone lineTo:pointZero];
    }
    for (int i = 0; i < count; i++) {
        [clone setPoint:i point:[inkList getPoint:i] pointType:[inkList getPointType:i]];
    }
    return clone;
}

+ (UIImage *)scaleToSize:(UIImage *)oriImage size:(CGSize)size {
    CGFloat width = CGImageGetWidth(oriImage.CGImage);
    CGFloat height = CGImageGetHeight(oriImage.CGImage);

    float verticalRadio = size.height * 1.0 / height;
    float horizontalRadio = size.width * 1.0 / width;

    float radio = 1;
    if (verticalRadio > 1 && horizontalRadio > 1) {
        radio = verticalRadio > horizontalRadio ? horizontalRadio : verticalRadio;
    } else {
        radio = verticalRadio < horizontalRadio ? verticalRadio : horizontalRadio;
    }

    width = width * radio;
    height = height * radio;

    int xPos = (size.width - width) / 2;
    int yPos = (size.height - height) / 2;

    UIGraphicsBeginImageContext(size);

    [oriImage drawInRect:CGRectMake(xPos, yPos, width, height)];

    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return scaledImage;
}

//Get file type thumbnail name
+ (NSString *)getThumbnailName:(NSString *)path {
    NSString *ret = DEVICE_iPHONE ? @"thumbnail_none_iphone" : @"thumbnail_none_ipad";
    if ([self isPDFPath:path]) {
        ret = DEVICE_iPHONE ? @"thumbnail_pdf_iphone" : @"thumbnail_pdf_ipad";
    }
    return ret;
}

#pragma mark file related

//Verify file type
+ (BOOL)isPDFPath:(NSString *)path {
    if ([path.pathExtension.lowercaseString isEqualToString:@"pdf"]) {
        return YES;
    } else if ([path.lowercaseString isEqualToString:@".pdf"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isPDFExtension:(NSString *)extension {
    return [extension.lowercaseString isEqualToString:@"pdf"];
}

+ (BOOL)isSupportFormat:(NSString *)path {
    if ([Utility isPDFPath:path] ||
        [Utility isGivenPath:path
                        type:@"txt"] ||
        [Utility isGivenPath:path
                        type:@"doc"] ||
        [Utility isGivenPath:path
                        type:@"docx"] ||
        [Utility isGivenPath:path
                        type:@"xls"] ||
        [Utility isGivenPath:path
                        type:@"xlsx"] ||
        [Utility isGivenPath:path
                        type:@"ppt"] ||
        [Utility isGivenPath:path
                        type:@"pptx"] ||
        [Utility isGivenPath:path
                        type:@"png"] ||
        [Utility isGivenPath:path
                        type:@"jpg"] ||
        [Utility isGivenPath:path
                        type:@"jpeg"] ||
        [Utility isGivenPath:path
                        type:@"zip"] ||
        [Utility isGivenPath:path
                        type:@"xml"] ||
        [Utility isGivenPath:path
                        type:@"html"] ||
        [Utility isGivenPath:path
                        type:@"htm"] ||
        [Utility isGivenPath:path
                        type:@"bmp"] ||
        [Utility isGivenPath:path
                        type:@"tif"] ||
        [Utility isGivenPath:path
                        type:@"tiff"] ||
        [Utility isGivenPath:path
                        type:@"gif"]) {
        return YES;
    }
    return NO;
}

//Get filetype icon name
+ (NSString *)getIconName:(NSString *)path {
    NSString *ret = @"list_none";
    if ([Utility isPDFPath:path]) {
        ret = @"list_pdf";
    }
    return ret;
}

//display the file size string
+ (NSString *)displayFileSize:(unsigned long long)byte {
    if (byte < 1024) {
        return [NSString stringWithFormat:@"%lld B", byte];
    } else if (byte < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.2f KB", byte / 1024.0];
    } else if (byte < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.2f MB", byte / (1024 * 1024.0)];
    } else {
        return [NSString stringWithFormat:@"%.2f GB", byte / (1024 * 1024 * 1024.0)];
    }
}

+ (ScreenSizeMode)getScreenSizeMode {
    const NSInteger screenWidth = SCREENWIDTH;
    const NSInteger screenHeight = SCREENHEIGHT;
    if (screenWidth == 480 || screenHeight == 480) {
        return ScreenSizeMode_35;
    } else if (screenWidth == 568 || screenHeight == 568) {
        return ScreenSizeMode_40;
    } else if (screenWidth == 667 || screenHeight == 667) {
        return ScreenSizeMode_47;
    } else if (screenWidth == 736 || screenHeight == 736) {
        return ScreenSizeMode_55;
    } else if (screenWidth == 1024 || screenHeight == 1024) {
        return ScreenSizeMode_97;
    }
    return ScreenSizeMode_35;
}

#define LIBRARY_PATH [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define DATA_FOLDER_NAME @"Data"
#define INTERNAL_FOLDER_NAME @"Internal"
#define ATTACHMENT_FOLDER_NAME @"Attachment"
#define DATA_PATH [LIBRARY_PATH stringByAppendingPathComponent:DATA_FOLDER_NAME]
#define INTERNAL_PATH [DATA_PATH stringByAppendingPathComponent:INTERNAL_FOLDER_NAME]
#define ATTACHMENT_PATH [INTERNAL_PATH stringByAppendingPathComponent:ATTACHMENT_FOLDER_NAME]

+ (NSString *)getAttachmentTempFilePath:(FSFileAttachment *)attachment {
    NSString *attachmentFileName = [[attachment getFileSpec] getFileName];
    return [ATTACHMENT_PATH stringByAppendingString:[NSString stringWithFormat:@"/%@_%i.%@", attachment.NM, attachment.pageIndex, [attachmentFileName pathExtension]]];
}
+ (NSString *)getDocumentAttachmentTempFilePath:(FSFileSpec *)attachmentFile PDFPath:(NSString *)PDFPath {
    NSString *attachmentFileName = [attachmentFile getFileName];
    return [ATTACHMENT_PATH stringByAppendingString:[NSString stringWithFormat:@"/%@_%@.%@", [Utility getStringMD5:PDFPath], [Utility getStringMD5:attachmentFileName], [attachmentFileName pathExtension]]];
}

// get 32 bytes md5 hash string
+ (NSString *)getStringMD5:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t md5[CC_MD5_DIGEST_LENGTH];

    CC_MD5(data.bytes, (CC_LONG) data.length, md5);

    NSMutableString *hashString = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hashString appendFormat:@"%02x", md5[i]];
    }
    return hashString;
}

+ (BOOL)loadAttachment:(FSFileAttachment *)annot toPath:(NSString *)attachmentPath {
    return [Utility loadFileSpec:[annot getFileSpec] toPath:attachmentPath];
}

+ (BOOL)loadFileSpec:(FSFileSpec *)fileSpec toPath:(NSString *)path {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if ([defaultManager fileExistsAtPath:path]) {
        return YES;
    }
    if (!fileSpec) {
        return NO;
    }
    if (![defaultManager createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil]) {
        return NO;
    }
    id<FSFileReadCallback> fileRead = [fileSpec getFileData];
    unsigned long long fileSize = [fileSpec getFileSize];
    @autoreleasepool {
        NSMutableData *data = [NSMutableData data];
        unsigned long long offset = 0;
        unsigned long long bufferSize = 2048000;
        while (1) {
            @autoreleasepool {
                NSData *dataBlock = [fileRead readBlock:offset size:MIN(bufferSize, fileSize - offset)];
                if (dataBlock.length > 0) {
                    offset += dataBlock.length;
                    [data appendData:dataBlock];
                } else {
                    break;
                }
            }
        }
        return [data writeToFile:path atomically:YES];
    } // autorelease pool
}

+ (FSBitmap *)imgDataToBitmap:(NSData *)imgData {
#if true
    UIImage *image = [UIImage imageWithData:imgData];
    if (image) {
        return [[FSBitmap alloc] initWithUIImage:image];
    } else {
        return nil;
    }
#else
    UIImage *image = [UIImage imageWithData:imgData];
    CGImageRef cgImg = [image CGImage];
    CGDataProviderRef provider = CGImageGetDataProvider(cgImg);
    CFDataRef data = CGDataProviderCopyData(provider);
    int width = (int) CGImageGetWidth(cgImg);
    int height = (int) CGImageGetHeight(cgImg);
    size_t bPP = CGImageGetBitsPerPixel(cgImg);
    if (bPP != 32) {
        return nil;
    }
    //Reverse bgr format to rgb
    const unsigned char *buffer = CFDataGetBytePtr(data);
    unsigned char *buf = (unsigned char *) buffer;
    int Bpp = (int) bPP / 8;
    int stride32 = width * Bpp;
    dispatch_apply(height, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t ri) {
        dispatch_apply(width, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t j) {
            long i = height - 1 - ri;
            unsigned char tmp = buf[i * stride32 + j * Bpp];
            buf[i * stride32 + j * Bpp] = buf[i * stride32 + j * Bpp + 2];
            buf[i * stride32 + j * Bpp + 2] = tmp;
        });
    });

    FSBitmap *bitmap = [[FSBitmap alloc] initWithWidth:width height:height format:e_dibArgb buffer:(unsigned char *) buf pitch:0];
    return bitmap;
#endif
}

+ (NSDictionary<NSString *, FSPDFObject *> *)getNSDictionaryFromPDFDictionary:(FSPDFDictionary *)pdfDict {
    NSMutableDictionary<NSString *, FSPDFObject *> *dict = [NSMutableDictionary<NSString *, FSPDFObject *> dictionary];
    void *pos = nil;
    while (1) {
        pos = [pdfDict moveNext:pos];
        NSString *key = [pdfDict getKey:pos];
        if (key.length == 0) {
            break;
        }
        FSPDFObject *obj = [pdfDict getValue:pos];
        if (!obj) {
            continue;
        }
        [dict setObject:obj forKey:key];
    }
    return dict;
}

#pragma mark icon string name to int

static NSDictionary<NSString *, NSNumber *> *g_noteIconNameToType = nil;
static NSDictionary<NSString *, NSNumber *> *g_attachmentIconNameToType = nil;
static NSDictionary<NSString *, NSNumber *> *g_stampIconNameToType = nil;

+ (void)setupIconNameAndTypes {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // note
        g_noteIconNameToType = @{
            @FS_ANNOT_ICONNAME_TEXT_CHECK : @FPDF_ICONTYPE_NOTE_CHECK,
            @FS_ANNOT_ICONNAME_TEXT_CIRCLE : @FPDF_ICONTYPE_NOTE_CIRCLE,
            @FS_ANNOT_ICONNAME_TEXT_COMMENT : @FPDF_ICONTYPE_NOTE_COMMENT,
            @FS_ANNOT_ICONNAME_TEXT_CROSS : @FPDF_ICONTYPE_NOTE_CROSS,
            @FS_ANNOT_ICONNAME_TEXT_HELP : @FPDF_ICONTYPE_NOTE_HELP,
            @FS_ANNOT_ICONNAME_TEXT_INSERT : @FPDF_ICONTYPE_NOTE_INSERT,
            @FS_ANNOT_ICONNAME_TEXT_KEY : @FPDF_ICONTYPE_NOTE_KEY,
            @FS_ANNOT_ICONNAME_TEXT_NEWPARAGRAPH : @FPDF_ICONTYPE_NOTE_NEWPARAGRAPH,
            @FS_ANNOT_ICONNAME_TEXT_NOTE : @FPDF_ICONTYPE_NOTE_NOTE,
            @FS_ANNOT_ICONNAME_TEXT_PARAGRAPH : @FPDF_ICONTYPE_NOTE_PARAGRAPH,
            @FS_ANNOT_ICONNAME_TEXT_RIGHTARROW : @FPDF_ICONTYPE_NOTE_RIGHTARROW,
            @FS_ANNOT_ICONNAME_TEXT_RIGHTPOINTER : @FPDF_ICONTYPE_NOTE_RIGHTPOINTER,
            @FS_ANNOT_ICONNAME_TEXT_STAR : @FPDF_ICONTYPE_NOTE_STAR,
            @FS_ANNOT_ICONNAME_TEXT_UPARROW : @FPDF_ICONTYPE_NOTE_UPARROW,
            @FS_ANNOT_ICONNAME_TEXT_UPLEFTARROW : @FPDF_ICONTYPE_NOTE_UPLEFTARROW,
        };
        // attachment
        g_attachmentIconNameToType = @{
            @FS_ANNOT_ICONNAME_FILEATTACH_GRAPH : @FPDF_ICONTYPE_FILEATTACH_GRAPH,
            @FS_ANNOT_ICONNAME_FILEATTACH_PAPERCLIP : @FPDF_ICONTYPE_FILEATTACH_PAPERCLIP,
            @FS_ANNOT_ICONNAME_FILEATTACH_PUSHPIN : @FPDF_ICONTYPE_FILEATTACH_PUSHPIN,
            @FS_ANNOT_ICONNAME_FILEATTACH_TAG : @FPDF_ICONTYPE_FILEATTACH_TAG,
        };
        // stamp
        g_stampIconNameToType = @{
            @"Approved" : @0,
            @"Completed" : @1,
            @"Confidential" : @2,
            @"Draft" : @3,
            @"Emergency" : @4,
            @"Expired" : @5,
            @"Final" : @6,
            @"Received" : @7,
            @"Reviewed" : @8,
            @"Revised" : @9,
            @"Verified" : @10,
            @"Void" : @11,
            @"Accepted" : @12,
            @"Initial" : @13,
            @"Rejected" : @14,
            @"Sign Here" : @15,
            @"Witness" : @16,
            @"DynaApproved" : @17,
            @"DynaConfidential" : @18,
            @"DynaReceived" : @19,
            @"DynaReviewed" : @20,
            @"DynaRevised" : @21,
        };
    });
}

+ (int)getIconTypeWithIconName:(NSString *)iconName annotType:(FSAnnotType)annotType {
    [Utility setupIconNameAndTypes];
    NSDictionary<NSString *, NSNumber *> *nameToType = nil;
    switch (annotType) {
    case e_annotNote:
        nameToType = g_noteIconNameToType;
        break;
    case e_annotFileAttachment:
        nameToType = g_attachmentIconNameToType;
        break;
    case e_annotStamp:
        nameToType = g_stampIconNameToType;
        break;
    default:
        break;
    }
    __block int iconType = FPDF_ICONTYPE_UNKNOWN;
    [nameToType enumerateKeysAndObjectsUsingBlock:^(NSString *_iconName, NSNumber *_iconType, BOOL *stop) {
        if ([_iconName caseInsensitiveCompare:iconName] == NSOrderedSame) {
            iconType = [_iconType intValue];
            *stop = YES;
        }
    }];
    return iconType;
}

+ (NSString *)getIconNameWithIconType:(int)iconType annotType:(FSAnnotType)annotType {
    [Utility setupIconNameAndTypes];
    NSDictionary<NSString *, NSNumber *> *nameToType = nil;
    switch (annotType) {
    case e_annotNote:
        nameToType = g_noteIconNameToType;
        break;
    case e_annotFileAttachment:
        nameToType = g_attachmentIconNameToType;
        break;
    case e_annotStamp:
        nameToType = g_stampIconNameToType;
        break;
    default:
        break;
    }

    __block NSString *iconName = nil;
    [nameToType enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull _iconName, NSNumber *_Nonnull _iconType, BOOL *_Nonnull stop) {
        if ([_iconType intValue] == iconType) {
            iconName = _iconName;
            *stop = YES;
        }
    }];
    return iconName;
}

+ (BOOL)isValidIconName:(NSString *)iconName annotType:(FSAnnotType)annotType {
    return [Utility getIconTypeWithIconName:iconName annotType:annotType] != FPDF_ICONTYPE_UNKNOWN;
}

+ (NSArray<NSString *> *)getAllIconLowercaseNames {
    [Utility setupIconNameAndTypes];
    NSMutableArray<NSString *> *iconNames = [NSMutableArray<NSString *> array];
    for (NSDictionary *dict in @[ g_noteIconNameToType, g_stampIconNameToType, g_attachmentIconNameToType ]) {
        for (NSString *key in dict.allKeys) {
            [iconNames addObject:key.lowercaseString];
        }
    }
    return iconNames;
}

+ (BOOL)hasSignatureInDocument:(FSPDFDoc *)document {
    FSPDFDictionary* root = [document getCatalog];
    if(!root) return NO;
    FSPDFObject* acroForm = [root getElement:@"AcroForm"];
    if(!acroForm) return NO;
    if([acroForm getType] == e_objReference)
        acroForm = [acroForm getDirectObject];
    if(!acroForm || [acroForm getType] != e_objDictionary)
        return NO;
    FSPDFObject* flag = [(FSPDFDictionary*)acroForm getElement:@"SigFlags"];
    int sigFlags = flag?[flag getInteger]:0;
    if(sigFlags & 0x01)
        return YES;
    return NO;
}

+ (BOOL)isOwnerOfDoucment:(FSPDFDoc *)document {
    int mdpPermission = [Utility getMDPDigitalSignPermissionInDocument:document];
    if (mdpPermission != 0) {
        return NO;
    }
    FSPasswordType passwordType = [document getPasswordType];
    return (passwordType == e_pwdNoPassword || passwordType == e_pwdOwner);
}

+ (BOOL)isDocumentSigned:(FSPDFDoc *)document {
    if(![Utility hasSignatureInDocument:document]) return NO;
    int count = [document getSignatureCount];
    for (int i = 0; i < count; i++) {
        if ([[document getSignature:i] isSigned])
            return YES;
    }
    return NO;
}

+ (BOOL)canAddAnnotToDocument:(FSPDFDoc *)document {
    if ([Utility isOwnerOfDoucment:document])
        return YES;
    int mdpPermission = [Utility getMDPDigitalSignPermissionInDocument:document];
    if (mdpPermission == 1 || mdpPermission == 2) {
        return NO;
    }
    return ([document getUserPermissions] & e_permAnnotForm) > 0;
}

+ (BOOL)canCopyTextInDocument:(FSPDFDoc *)document {
    if ([Utility isOwnerOfDoucment:document])
        return YES;
    return ([document getUserPermissions] & e_permExtract) > 0;
}

+ (BOOL)canFillFormInDocument:(FSPDFDoc *)document {
    if ([Utility isOwnerOfDoucment:document])
        return YES;
    int mdpPermission = [Utility getMDPDigitalSignPermissionInDocument:document];
    if (mdpPermission == 1) {
        return NO;
    }
    return ([document getUserPermissions] & e_permFillForm) > 0;
}

+ (BOOL)canAddSignToDocument:(FSPDFDoc *)document {
    if ([Utility isOwnerOfDoucment:document])
        return YES;
    int mdpPermission = [Utility getMDPDigitalSignPermissionInDocument:document];
    if (mdpPermission != 0) {
        return NO;
    }
    // e_permFillForm means you may sign the existing signature, but not create one.
    unsigned int perm = [document getUserPermissions];
    return ((perm & e_permAnnotForm) != 0u && (perm & e_permModify) != 0u);
}

+ (BOOL)canAssembleDocument:(FSPDFDoc *)document {
    if ([Utility isDocumentSigned:document])
        return NO;
    unsigned int perm = [document getUserPermissions];
    return [Utility isOwnerOfDoucment:document] || ((perm & e_permAssemble) != 0u);
}

+ (BOOL)canCopyForAssessInDocument:(FSPDFDoc *)document {
    if ([Utility isOwnerOfDoucment:document])
        return YES;

    unsigned long allPermission = [document getUserPermissions];
    return (allPermission & e_permExtractAccess) != 0u || (allPermission & e_permExtract) != 0u;
}

+ (BOOL)canModifyContentsInDocument:(FSPDFDoc *)document {
    if ([Utility isDocumentSigned:document])
        return NO;

    if ([Utility isOwnerOfDoucment:document])
        return YES;

    unsigned long allPermission = [document getUserPermissions];
    return (allPermission & e_permModify) != 0u;
}

+ (BOOL)canExtractContentsInDocument:(FSPDFDoc *)document {
    if ([Utility isOwnerOfDoucment:document])
        return YES;
    unsigned long allPermission = [document getUserPermissions];
    return (allPermission & e_permExtract) != 0u;
}

+ (BOOL)canPrintDocument:(FSPDFDoc *)document {
    if ([Utility isOwnerOfDoucment:document])
        return YES;
    unsigned long allPermission = [document getUserPermissions];
    return (allPermission & e_permPrint) != 0u;
}

+ (int)getMDPDigitalSignPermissionInDocument:(FSPDFDoc *)document {
    FSPDFDictionary *catalog = [document getCatalog];
    FSPDFDictionary *perms = (FSPDFDictionary *) [[catalog getElement:@"Perms"] getDirectObject];
    if (!perms || ![perms isKindOfClass:[FSPDFDictionary class]]) {
        return 0;
    }
    FSPDFDictionary *docMDP = (FSPDFDictionary *) [[perms getElement:@"DocMDP"] getDirectObject];
    if (!docMDP || ![docMDP isKindOfClass:[FSPDFDictionary class]]) {
        return 0;
    }
    FSPDFArray *reference = (FSPDFArray *) [[docMDP getElement:@"Reference"] getDirectObject];
    if (!reference || ![reference isKindOfClass:[FSPDFArray class]]) {
        return 0;
    }
    for (int i = 0; i < reference.getElementCount; i++) {
        FSPDFDictionary *tmpDict = (FSPDFDictionary *) [[reference getElement:i] getDirectObject];
        if (!tmpDict || ![tmpDict isKindOfClass:[FSPDFDictionary class]]) {
            return 0;
        }
        NSString *transformMethod = [[[tmpDict getElement:@"TransformMethod"] getDirectObject] getString];
        if (![transformMethod isEqualToString:@"DocMDP"]) {
            continue;
        }
        FSPDFDictionary *transformParams = (FSPDFDictionary *) [[tmpDict getElement:@"TransformParams"] getDirectObject];
        if (!transformParams || ![transformParams isKindOfClass:[FSPDFDictionary class]] || [transformParams getCptr] == [tmpDict getCptr]) {
            return 0;
        }
        int permisson = [[[transformParams getElement:@"P"] getDirectObject] getInteger];
        return permisson;
    }
}

+ (void)assignImage:(UIImageView *)imageView rawFrame:(CGRect)frame image:(UIImage *)image {
    if (image.size.width / image.size.height == frame.size.width / frame.size.height) {
        imageView.frame = [Utility getStandardRect:frame];
    } else if (image.size.width / image.size.height < frame.size.width / frame.size.height) {
        float realHeight = frame.size.height;
        float realWidth = image.size.width / image.size.height * realHeight;
        imageView.frame = [Utility getStandardRect:CGRectMake(frame.origin.x + (frame.size.width - realWidth) / 2, frame.origin.y, realWidth, realHeight)];
    } else {
        float realWidth = frame.size.width;
        float realHeight = image.size.height / image.size.width * realWidth;
        imageView.frame = [Utility getStandardRect:CGRectMake(frame.origin.x, frame.origin.y + (frame.size.height - realHeight) / 2, realWidth, realHeight)];
    }
    imageView.image = image;
}

+ (NSArray *)searchFilesWithFolder:(NSString *)folder recursive:(BOOL)recursive {
    NSMutableArray *fileList = [NSMutableArray array];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *fileAndFolderList = [fileManager contentsOfDirectoryAtPath:folder error:nil];
    for (NSString *file in fileAndFolderList) {
        if ([file.lowercaseString isEqualToString:@".DS_Store".lowercaseString]) {
            continue;
        }
        NSString *thisFile = [folder stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        if ([fileManager fileExistsAtPath:thisFile isDirectory:&isDir] && isDir) {
            if (recursive) {
                [fileList addObjectsFromArray:[[self class] searchFilesWithFolder:thisFile recursive:recursive]];
            }
        } else {
            [fileList addObject:thisFile];
        }
    }
    return (NSArray *) fileList;
}

+ (FSRectF*)getPageBoundary:(FSPDFPage*)page
{
    FSRectF* pageBox = [page GetBox:e_pageCropBox];
    if(!pageBox)
        pageBox = [page GetBox:e_pageMediaBox];
    if(!pageBox)
    {
        pageBox = [[FSRectF alloc] init];
        [pageBox set:0 bottom:0 right:612 top:792];
    }
    return pageBox;
}

+ (BOOL)parsePage:(FSPDFPage *)page flag:(unsigned int)flag pause:(FSPauseCallback *_Nullable)pause {
    FSProgressive *progress = [page startParse:flag pause:pause isReparse:NO];
    if (!progress) {
        return YES;
    }
    while (YES) {
        int rate = [progress getRateOfProgress];
        if (rate < 0) {
            return NO;
        } else if (rate == 100) {
            return YES;
        }
        if ([pause needPauseNow]) {
            return NO;
        }
        [progress resume];
    }
}

+ (BOOL)parsePage:(FSPDFPage *)page {
    return [Utility parsePage:page flag:e_parsePageNormal pause:nil];
}

+ (UIImage *)drawPage:(FSPDFPage *)page dibWidth:(int)dibWidth dibHeight:(int)dibHeight shouldDrawAnnotation:(BOOL)shouldDrawAnnotation needPause:(BOOL (^__nullable)(void))needPause {
    UIImage *img = nil;

    CGFloat scale = [UIScreen mainScreen].scale;
#ifdef CONTEXT_DRAW
    scale = 1;
#endif
    int newDibWidth = dibWidth * scale;
    int newDibHeight = dibHeight * scale;
    int newPdfX = 0;
    int newPdfY = 0;
    int newPdfWidth = dibWidth * scale;
    int newPdfHeight = dibHeight * scale;

    {
        if (!page) {
            return img;
        }

#ifdef CONTEXT_DRAW
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newDibWidth, newDibHeight), YES, [[UIScreen mainScreen] scale]);
        CGContextRef context = UIGraphicsGetCurrentContext();
#else
        //create a 24bit bitmap
        int size = newDibWidth * newDibHeight * 3;
        void *pBuf = malloc(size);
        FSBitmap *fsbitmap = [[FSBitmap alloc] initWithWidth:newDibWidth height:newDibHeight format:e_dibRgb buffer:(unsigned char *) pBuf pitch:newDibWidth * 3];
#endif

//render page, must have
#ifdef CONTEXT_DRAW
        FSRenderer *fsrenderer = [FSRenderer createFromContext:context deviceType:e_deviceTypeDisplay];
#else
        FSRenderer *fsrenderer = [[FSRenderer alloc] initWithBitmap:fsbitmap rgbOrder:YES];
#endif
        [fsrenderer setTransformAnnotIcon:NO];
        FSMatrix *fsmatrix = [page getDisplayMatrix:newPdfX yPos:newPdfY xSize:newPdfWidth ySize:newPdfHeight rotate:e_rotation0];
        //        if (isNightMode) {
        //#ifndef CONTEXT_DRAW
        //            //set background color of bitmap to black
        //            memset(pBuf, 0x00, size);
        //#endif
        //            [fsrenderer setColorMode:e_colorModeMapping];
        //            [fsrenderer setMappingModeColors:pdfViewCtrl.mappingModeBackgroundColor.argbHex foreColor:pdfViewCtrl.mappingModeForegroundColor.argbHex];
        //        } else
        {
#ifdef CONTEXT_DRAW
            CGContextSetRGBFillColor(context, 1, 1, 1, 1);
            CGContextFillRect(context, CGRectMake(0, 0, newDibWidth, newDibHeight));
#else
            //set background color of bitmap to white
            memset(pBuf, 0xff, size);
#endif
        }

        void (^releaseRender)(BOOL freepBuf) = ^(BOOL freepBuf) {
#ifdef CONTEXT_DRAW
            UIGraphicsEndImageContext();
#else
            if (freepBuf) {
                free(pBuf);
            }
#endif
        };
        int contextFlag = shouldDrawAnnotation ? (e_renderAnnot | e_renderPage) : e_renderPage;
        [fsrenderer setRenderContent:contextFlag];

        FSPause *pause = [FSPause pauseWithBlock:needPause];
        FSProgressive *ret = [fsrenderer startRender:page matrix:fsmatrix pause:pause];

        if (ret != nil) {
            FSProgressState state;
            while (true) {
                state = [ret resume];
                if (state != e_progressToBeContinued) {
                    break;
                }
            }
            if (e_progressFinished != state) {
                releaseRender(YES);
                return nil;
            }
        }

#ifdef CONTEXT_DRAW
        img = UIGraphicsGetImageFromCurrentImageContext();
#else
        img = [Utility rgbDib2img:pBuf size:size dibWidth:newDibWidth dibHeight:newDibHeight withAlpha:NO freeWhenDone:YES];
#endif
        releaseRender(img == nil);
    }
    return img;
}

+ (UIImage *)drawPage:(FSPDFPage *)page targetSize:(CGSize)targetSize shouldDrawAnnotation:(BOOL)shouldDrawAnnotation needPause:(BOOL (^__nullable)(void))needPause {
    BOOL isOK = [Utility parsePage:page];
    if (!isOK || ![page isParsed]) {
        return nil;
    }
    return [Utility drawPage:page dibWidth:targetSize.width dibHeight:targetSize.height shouldDrawAnnotation:shouldDrawAnnotation needPause:needPause];

#if 0
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    FSRenderer* fsrenderer = [FSRenderer createFromContext:context deviceType:e_deviceTypeDisplay];
    if (isNightMode) {
        [fsrenderer setColorMode:e_colorModeMapping];
        [fsrenderer setMappingModeColors:pdfViewCtrl.mappingModeBackgroundColor.argbHex foreColor:pdfViewCtrl.mappingModeForegroundColor.argbHex];
    } else {
        CGContextSetRGBFillColor(context, 1, 1, 1, 1);
        CGContextFillRect(context, CGRectMake(0, 0, targetSize.width, targetSize.height));
    }
    [fsrenderer setTransformAnnotIcon:NO];
    [fsrenderer setRenderContent:shouldDrawAnnotation ? (e_renderAnnot|e_renderPage) : e_renderPage];
    UIImage* image = nil;
    @try {
        FSMatrix* fsmatrix = [page getDisplayMatrix:0
                                               yPos:0
                                              xSize:ceilf(targetSize.width)
                                              ySize:ceilf(targetSize.height)
                                             rotate:e_rotation0];
        FSProgressState state = [fsrenderer startRender:page matrix:fsmatrix pause:nil];
        while (e_progressToBeContinued == state) {
            state = [fsrenderer continueRender];
        }
        if (e_progressFinished == state) {
            image = UIGraphicsGetImageFromCurrentImageContext();
        }
    } @catch (NSException *exception) {
        UIGraphicsEndImageContext();
        return nil;
    }
    
    UIGraphicsEndImageContext();
    return image;
#endif
}

+ (void)printPage:(FSPDFPage *)page inContext:(CGContextRef)context inRect:(CGRect)rect shouldDrawAnnotation:(BOOL)shouldDrawAnnotation {
#if 0
    BOOL parseSuccess = [Utility parsePage:page flag:e_parsePageNormal pause:nil];
    if (!parseSuccess) {
        return;
    }
    FSRenderer *fsrenderer = [FSRenderer createFromContext:context deviceType:e_deviceTypePrinter];
    FSMatrix *fsmatrix = [page getDisplayMatrix:rect.origin.x yPos:rect.origin.y xSize:rect.size.width ySize:rect.size.height rotate:e_rotation0];
    [fsrenderer setRenderContent:(shouldDrawAnnotation ? (e_renderPage | e_renderAnnot) : e_renderPage)];
    FSProgressive *progressive = [fsrenderer startRender:page matrix:fsmatrix pause:nil];
    if (progressive != nil) {
        while (true) {
            if ([progressive resume] != e_progressToBeContinued) {
                break;
            }
        }
    }
#else
    UIImage *image = [Utility drawPage:page targetSize:rect.size shouldDrawAnnotation:YES needPause:nil];
    if (image) {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0.0, 2 * rect.origin.y + rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, rect, image.CGImage);
        CGContextRestoreGState(context);
    }
#endif
}

+ (void)tryLoadDocument:(FSPDFDoc *)document withPassword:(NSString *)password success:(void (^)(NSString *password))success error:(void (^_Nullable)(NSString *description))error abort:(void (^_Nullable)(void))abort {
    FSErrorCode errorCode = [document load:password];
    switch (errorCode) {
    case e_errSuccess: {
        if (success) {
            success(password);
        }
    } break;
    case e_errPassword: {
        NSString *title = password.length > 0 ? @"kDocPasswordError" : @"kDocNeedPassword";
        AlertView *alertView = [[AlertView alloc] initWithTitle:title
                                                        message:nil
                                                          style:UIAlertViewStyleSecureTextInput
                                             buttonClickHandler:^(UIView *alertView, NSInteger buttonIndex) {
                                                 if (buttonIndex == 1) {
                                                     NSString *guessPassword = [(AlertView *) alertView textFieldAtIndex:0].text;
                                                     [Utility tryLoadDocument:document withPassword:guessPassword success:success error:error abort:abort];
                                                 } else {
                                                     if (abort) {
                                                         abort();
                                                     }
                                                 }
                                             }
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];
        [alertView show];
    } break;
    default: {
        if (error) {
            error([Utility getErrorCodeDescription:errorCode]);
        }
    } break;
    }
}

//File/Folder existance
+ (BOOL)isFileOrFolderExistAtPath:(NSString *)path fileOrFolderName:(NSString *)fileOrFolderName {
    BOOL isAlreadyFileOrFolderExist = NO;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *subFolder = [fileManager contentsOfDirectoryAtPath:path error:nil];
    for (NSString *thisFolder in subFolder) {
        if ([thisFolder caseInsensitiveCompare:fileOrFolderName] == NSOrderedSame) {
            isAlreadyFileOrFolderExist = YES;
            break;
        }
    }
    return isAlreadyFileOrFolderExist;
}

+ (BOOL)showAnnotationContinue:(BOOL)isContinue pdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl siblingSubview:(UIView *)siblingSubview {
    [self dismissAnnotationContinue:pdfViewCtrl];
    NSString *textString = nil;
    if (isContinue) {
        textString = FSLocalizedString(@"kAnnotContinue");
    } else {
        textString = FSLocalizedString(@"kAnnotSingle");
    }

    CGSize titleSize = [Utility getTextSize:textString fontSize:15.0f maxSize:CGSizeMake(300, 100)];

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(pdfViewCtrl.bounds) / 2, CGRectGetHeight(pdfViewCtrl.bounds) - 120, titleSize.width + 10, 30)];
    view.center = CGPointMake(CGRectGetWidth(pdfViewCtrl.bounds) / 2, CGRectGetHeight(pdfViewCtrl.bounds) - 105);
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0.8;
    view.layer.cornerRadius = 10.0f;
    view.tag = 2112;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleSize.width, 30)];
    label.center = CGPointMake(view.frame.size.width / 2, view.frame.size.height / 2);
    label.backgroundColor = [UIColor clearColor];
    label.text = textString;

    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15];
    [view addSubview:label];
    [pdfViewCtrl insertSubview:view belowSubview:siblingSubview];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(view.superview.mas_centerX).offset(0);
        make.top.equalTo(view.superview.mas_bottom).offset(-120);
        make.width.mas_equalTo(titleSize.width + 10);
        make.height.mas_equalTo(@30);
    }];
    return YES;
}

+ (void)dismissAnnotationContinue:(UIView *)superView {
    for (UIView *view in superView.subviews) {
        if (view.tag == 2112) {
            [view removeFromSuperview];
        }
    }
}

+ (BOOL)showAnnotationType:(NSString *)annotType type:(FSAnnotType)type pdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl belowSubview:(UIView *)siblingSubview {
    for (UIView *view in pdfViewCtrl.subviews) {
        if (view.tag == 2113) {
            [view removeFromSuperview];
        }
    }

    CGSize titleSize = [Utility getTextSize:annotType fontSize:13.0f maxSize:CGSizeMake(100, 100)];

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(pdfViewCtrl.bounds) / 2, CGRectGetHeight(pdfViewCtrl.bounds) - 80, titleSize.width + 20 + 10, 20)];
    view.center = CGPointMake(CGRectGetWidth(pdfViewCtrl.bounds) / 2, CGRectGetHeight(pdfViewCtrl.bounds) - 70);
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0.8;
    view.layer.cornerRadius = 5.0f;
    view.tag = 2113;

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(5, 2, 16, 16);
    switch (type) {
    case e_annotHighlight:
        imageView.image = [UIImage imageNamed:@"property_type_highlight"];
        break;
    case e_annotLink:
        break;
    case e_annotNote:
        imageView.image = [UIImage imageNamed:@"property_type_note"];
        break;
    case e_annotStrikeOut:
        imageView.image = [UIImage imageNamed:@"property_type_strikeout"];
        break;
    case e_annotUnderline:
        imageView.image = [UIImage imageNamed:@"property_type_underline"];
        break;
    case e_annotSquiggly:
        imageView.image = [UIImage imageNamed:@"property_type_squiggly"];
        break;
    case e_annotSquare:
        imageView.image = [UIImage imageNamed:@"property_type_rectangle"];
        break;
    case e_annotCircle:
        imageView.image = [UIImage imageNamed:@"property_type_circle"];
        break;
    case e_annotLine:
        if ([annotType isEqualToString:FSLocalizedString(@"kArrowLine")]) {
            imageView.image = [UIImage imageNamed:@"property_type_arrowline"];
        }
        else if ([annotType isEqualToString:FSLocalizedString(@"kDistance")]) {
            imageView.image = [UIImage imageNamed:@"property_type_distance"];
        }
        else {
            imageView.image = [UIImage imageNamed:@"property_type_line"];
        }
        break;
    case e_annotFreeText:
        if ([annotType isEqualToString:FSLocalizedString(@"kTextbox")]) {
            imageView.image = [UIImage imageNamed:@"property_type_textbox"];
        } else {
            imageView.image = [UIImage imageNamed:@"property_type_freetext"];
        }
        break;
    case e_annotInk:
        if ([annotType isEqualToString:FSLocalizedString(@"kErase")]) {
            imageView.image = [UIImage imageNamed:@"property_type_erase"];
        } else {
            imageView.image = [UIImage imageNamed:@"property_type_pencil"];
        }
        break;
    case e_annotStamp:
        imageView.image = [UIImage imageNamed:@"property_type_stamp"];
        break;
    case e_annotCaret:
        if ([annotType isEqualToString:FSLocalizedString(@"kReplaceText")]) {
            imageView.image = [UIImage imageNamed:@"property_type_replace"];
        } else
            imageView.image = [UIImage imageNamed:@"property_type_caret"];
        break;
    case e_annotScreen:
        imageView.image = [UIImage imageNamed:@"property_type_image"];
        break;
    case e_annotFileAttachment:
        imageView.image = [UIImage imageNamed:@"property_type_attachment"];
        break;
    case e_annotPolygon:
        if ([annotType isEqualToString:FSLocalizedString(@"kCloud")]) {
            imageView.image = [UIImage imageNamed:@"property_type_cloud"];
        } else {
            imageView.image = [UIImage imageNamed:@"property_type_polygon"];
        }
        break;
    default:
        break;
    }

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleSize.width, 20)];
    label.center = CGPointMake(view.frame.size.width / 2 + 10, view.frame.size.height / 2);
    label.backgroundColor = [UIColor clearColor];
    label.text = annotType;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:12];
    [view addSubview:imageView];
    [view addSubview:label];
    [pdfViewCtrl insertSubview:view belowSubview:siblingSubview];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(view.superview.mas_centerX).offset(0);
        make.top.equalTo(view.superview.mas_bottom).offset(-80);
        make.width.mas_equalTo(titleSize.width + 20 + 10);
        make.height.mas_equalTo(@20);
    }];
    [UIView animateWithDuration:3
        animations:^{
            view.alpha = 0;
        }
        completion:^(BOOL finished) {
            [view removeFromSuperview];
        }];
    return YES;
}

//Add animation
+ (void)addAnimation:(CALayer *)layer type:(NSString *)type subType:(NSString *)subType timeFunction:(NSString *)timeFunction duration:(float)duration {
    CATransition *animation = [CATransition animation];
    [animation setType:type];
    [animation setSubtype:subType];
    [animation setDuration:duration];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:timeFunction]];
    [layer addAnimation:animation forKey:nil];
}

+ (FSReadingBookmark *)getReadingBookMarkAtPage:(FSPDFDoc *)doc page:(int)page {
    int count;
    @try {
        count = [doc getReadingBookmarkCount];
    } @catch (NSException *exception) {
        return nil;
    }
    for (int i = 0; i < count; i++) {
        FSReadingBookmark *bookmark = [doc getReadingBookmark:i];
        if ([bookmark getPageIndex] == page)
            return bookmark;
    }
    return nil;
}

+ (UIButton *)createButtonWithImage:(UIImage *)image {
    UIButton *button = [[UIButton alloc] initWithFrame:(CGRect){CGPointZero, image.size}];
    [button setEnlargedEdge:3.f];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
    button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;

    [button setImage:image forState:UIControlStateNormal];
    UIImage *translucentImage = [Utility imageByApplyingAlpha:image alpha:0.5];
    [button setImage:translucentImage forState:UIControlStateHighlighted];
    [button setImage:translucentImage forState:UIControlStateDisabled];

    return button;
}

+ (CGFloat)getUIToolbarPaddingX {
    return 20.f;
}

+ (BOOL)isSinceiOS:(const NSString *)requiredVersion {
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    return ([currSysVer compare:(NSString *) requiredVersion options:NSNumericSearch] != NSOrderedAscending);
}

#pragma mark print methods

+ (UIPrintInteractionController *)createPrintInteractionControolerForDoc:(FSPDFDoc *)doc jobName:(nullable NSString *)jobName {
    if (![Utility isSinceiOS:@"4.2"]) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kAirPrintVersion" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
        [alertView show];
        return nil;
    }

    if (![UIPrintInteractionController isPrintingAvailable]) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kAirPrintNotAvailable" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
        [alertView show];
        return nil;
    }

    if (![Utility canPrintDocument:doc]) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kRMSNoAccess" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
        [alertView show];
        return nil;
    }

    //save editing first? todo

    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
    printController.showsPageRange = YES;

    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = jobName;
    if ([doc getPageCount] > 0) {
        FSPDFPage *page = [doc getPage:0];
        if ([page getWidth] > [page getHeight]) {
            printInfo.orientation = UIPrintInfoOrientationLandscape;
        }
    }
    printController.printInfo = printInfo;
    printController.printPageRenderer = [[PrintRenderer alloc] initWithDocument:doc];
    return printController;
}

+ (void)printDoc:(FSPDFDoc *)doc animated:(BOOL)animated jobName:(nullable NSString *)jobName delegate:(nullable id<UIPrintInteractionControllerDelegate>)delegate completionHandler:(nullable UIPrintInteractionCompletionHandler)completion {
    UIPrintInteractionController *printController = [self.class createPrintInteractionControolerForDoc:doc jobName:jobName];
    printController.delegate = delegate;
    [printController presentAnimated:animated completionHandler:completion];
}

+ (void)printDoc:(FSPDFDoc *)doc fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated jobName:(nullable NSString *)jobName delegate:(nullable id<UIPrintInteractionControllerDelegate>)delegate completionHandler:(nullable UIPrintInteractionCompletionHandler)completion {
    UIPrintInteractionController *printController = [self.class createPrintInteractionControolerForDoc:doc jobName:jobName];
    printController.delegate = delegate;
    [printController presentFromRect:rect inView:view animated:animated completionHandler:completion];
}

////Take screen shot
+ (UIImage *)screenShot:(UIView *)view {
    // Create a graphics context with the target size
    CGSize imageSize = view.bounds.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, YES, [UIScreen mainScreen].scale);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

//remove all gesture
+ (void)removeAllGestureRecognizer:(UIView *)view {
    for (UIGestureRecognizer *ges in view.gestureRecognizers) {
        [view removeGestureRecognizer:ges];
    }
}

//Crop image
+ (UIImage*)cropImage:(UIImage*)img rect:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [img scale]);
    [img drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y)];
    UIImage *cropped_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return cropped_image;
}

#pragma mark

+ (NSArray *)getTextRects:(FSPDFTextSelect *)fstextPage startCharIndex:(int)startCharIndex endCharIndex:(int)endCharIndex {
    NSMutableArray *ret = [NSMutableArray array];
    if (fstextPage == nil) {
        return ret;
    }
    int count = ABS(endCharIndex - startCharIndex) + 1;
    startCharIndex = MIN(startCharIndex, endCharIndex);
    int rectCount = [fstextPage getTextRectCount:startCharIndex count:count];
    for (int i = 0; i < rectCount; i++) {
        FSRectF *dibRect = [fstextPage getTextRect:i];
        if (dibRect.getLeft == dibRect.getRight || dibRect.getTop == dibRect.getBottom) {
            continue;
        }

        FSRotation direction = [fstextPage getBaselineRotation:i];
        NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGRect:[Utility FSRectF2CGRect:dibRect]], @(direction), nil];

        [ret addObject:array];
    }

    //merge rects if possible
    if (ret.count > 1) {
        int i = 0;
        while (i < ret.count - 1) {
            int j = i + 1;
            while (j < ret.count) {
                FSRectF *rect1 = [Utility CGRect2FSRectF:[[[ret objectAtIndex:i] objectAtIndex:0] CGRectValue]];
                FSRectF *rect2 = [Utility CGRect2FSRectF:[[[ret objectAtIndex:j] objectAtIndex:0] CGRectValue]];

                int direction1 = [[[ret objectAtIndex:i] objectAtIndex:1] intValue];
                int direction2 = [[[ret objectAtIndex:j] objectAtIndex:1] intValue];
                BOOL adjcent = NO;
                if (direction1 == direction2) {
                    adjcent = NO;
                }
                if (adjcent) {
                    FSRectF *rectResult = [[FSRectF alloc] init];
                    [rectResult set:MIN([rect1 getLeft], [rect2 getLeft]) bottom:MAX([rect1 getTop], [rect2 getTop]) right:MAX([rect1 getRight], [rect2 getRight]) top:MIN([rect1 getBottom], [rect2 getBottom])];
                    NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGRect:[Utility FSRectF2CGRect:rectResult]], @(direction1), nil];
                    [ret replaceObjectAtIndex:i withObject:array];
                    [ret removeObjectAtIndex:j];
                } else {
                    j++;
                }
            }
            i++;
        }
    }
    return ret;
}

// get distance unit info
+ (NSArray *)getDistanceUnitInfo:(NSString *)measureRatio {
    measureRatio = [measureRatio stringByReplacingOccurrencesOfString:@"= "withString:@""];
    NSArray *result = [measureRatio componentsSeparatedByString:@" "];
    return  result;
}

// get distance between to cgpoint
+ (float)getDistanceFromX:(FSPointF *)start toY:(FSPointF *)end{
    float distance;
    CGFloat xDist = (end.x - start.x);
    CGFloat yDist = (end.y - start.y);
    distance = sqrt((xDist * xDist) + (yDist * yDist));
    return distance;
}

// get distance between to cgpoint with unit
+ (float)getDistanceFromX:(FSPointF *)start toY:(FSPointF *)end withUnit:(NSString *)measureRatio{
    NSArray *distancInfo = [Utility getDistanceUnitInfo:measureRatio];
    
    NSString *distanceUnit = [distancInfo objectAtIndex:1];
    float scale = 0.0;
    if ([[distancInfo objectAtIndex:0] floatValue] != 0) {
        scale = [[distancInfo objectAtIndex:2] floatValue]/[[distancInfo objectAtIndex:0] floatValue];
    }
    
    float distance = [Utility getDistanceFromX:start toY:end]; // pt
    NSMutableDictionary *unitDict = @{
                                      @"pt":[NSNumber numberWithFloat:1.0 ],
                                      @"inch":[NSNumber numberWithFloat:1.0/72 ],
                                      @"ft":[NSNumber numberWithFloat:1.0/(72 *12) ],
                                      @"yd":[NSNumber numberWithFloat:1.0/(72 *36) ],
                                      @"p":[NSNumber numberWithFloat:1.0/(12) ],
                                      @"mm":[NSNumber numberWithFloat:25.4/72 ],
                                      @"cm":[NSNumber numberWithFloat:2.54/72 ],
                                      @"m":[NSNumber numberWithFloat:0.0254/72 ],
                                      }.mutableCopy;
    
    float transParams = [[unitDict objectForKey:distanceUnit] floatValue];
    return distance * transParams * scale;
}

+ (FSImage *)createFSImageWithUIImage:(UIImage *)image {
    NSData *data = UIImagePNGRepresentation(image);
    if (data) {
        FSImage *fsImage = [[FSImage alloc] initWithBuffer:data];
        return fsImage;
    }
    return nil;
}

+ (CGRect)boundedRectForRect:(CGRect)rect containerRect:(CGRect)containerRect {
    rect.origin.x = MAX(CGRectGetMinX(rect), CGRectGetMinX(containerRect));
    rect.origin.x = MIN(CGRectGetMinX(rect), CGRectGetMaxX(containerRect) - CGRectGetWidth(rect));
    rect.origin.y = MAX(CGRectGetMinY(rect), CGRectGetMinY(containerRect));
    rect.origin.y = MIN(CGRectGetMinY(rect), CGRectGetMaxY(containerRect) - CGRectGetHeight(rect));
    return rect;
}

+ (FSRotation)rotationForValue:(NSValue *)value {
    switch ([(NSNumber *) value intValue]) {
    case 0:
        return e_rotation0;
    case 90:
        return e_rotation90;
    case 180:
        return e_rotation180;
    case 270:
        return e_rotation270;
    default:
        return e_rotation0;
    }
}

+ (int)valueForRotation:(FSRotation)rotation {
    switch (rotation) {
    case e_rotation0:
        return 0;
    case e_rotation90:
        return 90;
    case e_rotation180:
        return 180;
    case e_rotation270:
        return 270;
    default:
        return 0;
    }
}

+ (UIImageOrientation)imageOrientationForRotation:(FSRotation)rotation {
    switch (rotation) {
    case e_rotation0:
        return UIImageOrientationUp;
    case e_rotation90:
        return UIImageOrientationLeft;
    case e_rotation180:
        return UIImageOrientationDown;
    case e_rotation270:
        return UIImageOrientationRight;
    default:
        return UIImageOrientationUp;
    }
}

+ (NSArray<FSPointF *> *)getPolygonVertexes:(FSPolygon *)polygon {
    NSMutableArray<FSPointF *> *vertexes = @[].mutableCopy;
    for (int i = 0; i < [polygon getVertexCount]; i++) {
        FSPointF *vertex = [polygon getVertex:i];
        if (vertex) {
            [vertexes addObject:vertex];
        }
    }
    return vertexes;
}

@end
