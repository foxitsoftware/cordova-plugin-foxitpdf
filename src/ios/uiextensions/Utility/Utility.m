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
#import <QuartzCore/QuartzCore.h>

#import <MobileCoreServices/MobileCoreServices.h>
#import <execinfo.h>
#import <MessageUI/MessageUI.h>


#import <ifaddrs.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import "Utility.h"
#import "Const.h"
#import "Masonry/MASConstraintMaker.h"
#import "Masonry/View+MASAdditions.h"
#import "TaskServer.h"

#import "FSAnnotExtent.h"
#import "ColorUtility.h"




void FoxitLog(NSString *format, ...)
{
#if DEBUG  
    if (FOXIT_LOG_ON)
    {
        va_list args;
        va_start(args, format);
        NSString * msg = [[NSString alloc] initWithFormat:format arguments:args];
        NSLog(@"%@", msg);
        [msg release];
        va_end(args);
    }
#endif
}

@implementation Utility

//get the xib name according to iPhone or iPad
+ (NSString *)getXibName:(NSString *)baseXibName
{
    NSString *xibName;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if ([baseXibName isEqualToString:@"FileManageListViewController"])
        {
            xibName = @"FileManageViewController_iPhone";
        }
        else
        {
            xibName = [NSString stringWithFormat:@"%@_%@", baseXibName, @"iPhone"];
        }
    }
    else
    {
        if ([baseXibName isEqualToString:@"PasswordInputViewController"])
        {
            xibName = @"PasswordInputViewController";
        }
        else if ([baseXibName isEqualToString:@"SettingViewController"])
        {
            xibName = @"SettingViewController";
        }
        else if ([baseXibName isEqualToString:@"ContentViewController"])
        {
            xibName = @"ContentViewController";
        }
        else if ([baseXibName isEqualToString:@"WifiSettingViewController"])
        {
            xibName = @"WifiSettingViewController";
        }
        else
        {
            xibName = [NSString stringWithFormat:@"%@_%@", baseXibName, @"iPad"];
        }
    }
    return xibName;
}

//display date in yyyy-MM-dd HH:mm formate
+ (NSString *)displayDateInYMDHM:(NSDate *)date
{
    return [Utility displayDateInYMDHM:date hasSymbol:YES];
}

+ (NSString *)displayDateInYMDHM:(NSDate *)date hasSymbol:(BOOL)hasSymbol
{
    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:hasSymbol ? @"yyyy-MM-dd HH:mm" : @"yyyyMMddHHmm"];
    return [dateFormatter stringFromDate:date];
}

//Verify if point in polygon
+ (BOOL)isPointInPolygon:(CGPoint)p polygonPoints:(NSArray*)polygonPoints
{
    CGMutablePathRef path = CGPathCreateMutable();
    [polygonPoints enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGPoint p = [obj CGPointValue];
        if (idx == 0)
        {
           CGPathMoveToPoint(path, NULL, p.x, p.y);
        }
        else
        {
            CGPathAddLineToPoint(path, NULL, p.x, p.y);
        }
    }];
    CGPathCloseSubpath(path);
    BOOL ret = CGPathContainsPoint(path, NULL, p, false);
    CGPathRelease(path);
    
    return ret;
}

+ (CGRect)convertToCGRect:(CGPoint)p1 p2:(CGPoint)p2
{
    return CGRectMake(MIN(p1.x, p2.x),
                      MIN(p1.y, p2.y),
                      fabs(p1.x - p2.x),
                      fabs(p1.y - p2.y));
}

//Get Rect by two points
+ (FSRectF *)convertToFSRect:(FSPointF *)p1 p2:(FSPointF *)p2
{
    FSRectF *rect = [[[FSRectF alloc] init] autorelease];
    rect.left = MIN([p1 getX], [p2 getX]);
    rect.right = MAX([p1 getX], [p2 getX]);
    rect.top = MAX([p1 getY], [p2 getY]);
    rect.bottom = MIN([p1 getY], [p2 getY]);
    return rect;
}

//Standard Rect
+ (CGRect)getStandardRect:(CGRect)rect
{
    rect.origin.x = (int)rect.origin.x;
    rect.origin.y = (int)rect.origin.y;
    rect.size.width = (int)(rect.size.width+0.5);
    rect.size.height = (int)(rect.size.height+0.5);
    return rect;
}

//Get UUID
+ (NSString *)getUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef strUUID = CFUUIDCreateString(NULL, uuid);
    NSString * ret = [[(NSString *)strUUID lowercaseString] retain];
    CFRelease(strUUID);
    CFRelease(uuid);
    return [ret autorelease];
}

+ (CGSize)getTextSize:(NSString*)text fontSize:(float)fontSize maxSize:(CGSize)maxSize
{
    if (nil == text) text = @""; //for getting correct text size as following.
    if (OS_ISVERSION7) {
        NSDictionary *attrs = @{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]};
        CGSize textSize  = [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
        textSize.width +=2;
        return textSize;
    }
    else
    {
        CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(MAXFLOAT, 0.0) lineBreakMode:NSLineBreakByWordWrapping];
        return textSize;
    }
}

// calculate Attributed String size
+ (CGSize)getAttributedTextSize:(NSAttributedString *)attributedString maxSize:(CGSize)maxSize
{
    CGRect stringRect = [attributedString boundingRectWithSize:maxSize options: NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
    stringRect.size.width += 4;
    return stringRect.size;
}

+ (CGFloat)realPX:(CGFloat)wantPX
{
    if ([UIScreen mainScreen].scale == 0) {
        return wantPX;
    }
    return wantPX / [UIScreen mainScreen].scale;
}

+ (NSArray *)getAnnots:(FSPDFPage*)page
{
    NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
    
    int count = [page getAnnotCount];
    
    for (int i = 0; i < count; i++)
    {
        FSAnnot *fsannot = [page getAnnot:i];
        if(!fsannot.NM)
            fsannot.NM = [Utility getUUID];
        if (!fsannot) {
            continue;
        }
        enum FS_ANNOTTYPE type = [fsannot getType];
        if (e_annotNote == type ||
            e_annotHighlight == type ||
            e_annotUnderline == type ||
            e_annotSquiggly == type ||
            e_annotStrikeOut == type ||
            e_annotSquare == type ||
            e_annotCircle == type ||
            e_annotFreeText == type ||
            e_annotStamp == type ||
            e_annotInk == type ||
            e_annotCaret == type ||
            e_annotLine == type
            )
        {
            [array addObject:fsannot];
        }
        
        
    }
    return array;
}

+ (BOOL)isReplaceText:(FSStrikeOut*)markup
{
    if (![markup isGrouped]) {
        return NO;
    }
    for (int i = 0; i < [markup getGroupElementCount]; i ++) {
        if ([markup getGroupElement:i].type == e_annotCaret) {
            return YES;
        }
    }
    return NO;
}

+ (FSRectF*)getCaretAnnotRect:(FSMarkup*)markup
{
    if (![markup isGrouped]) {
        return markup.fsrect;
    }
    CGRect unionRect;
    for (int i = 0; i < [markup getGroupElementCount]; i ++) {
        FSAnnot* annot = [markup getGroupElement:i];
        if (i == 0) {
            unionRect = [self FSRectF2CGRect:annot.fsrect];
        } else {
            unionRect = CGRectUnion(unionRect, [self FSRectF2CGRect:annot.fsrect]);
        }
    }
    return [self CGRect2FSRectF:unionRect];
}


//copied from TbBaseItem
+ (UIImage *)imageByApplyingAlpha:(UIImage*)image alpha:(CGFloat) alpha {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if(!ctx) return nil;
    
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

+ (FSPDFTextSelect*)getTextSelect:(FSPDFDoc*)doc pageIndex:(int)index;
{
    FSPDFTextSelect* textSelect = nil;
    FSPDFPage* page = [doc getPage:index];
    if (page)
        textSelect = [FSPDFTextSelect create:page];
    return textSelect;
}

//get word range of string, including space
+ (NSArray*)_getUnitWordBoundary:(NSString*)str
{
    NSMutableArray *array = [NSMutableArray array];
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault,
                                                             (CFStringRef)str,
                                                             CFRangeMake(0, [str length]),
                                                             kCFStringTokenizerUnitWordBoundary,
                                                             NULL);
    CFStringTokenizerTokenType tokenType = kCFStringTokenizerTokenNone;
    while ((tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)) != kCFStringTokenizerTokenNone)
    {
        CFRange tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
        NSRange range = NSMakeRange(tokenRange.location, tokenRange.length);
        [array addObject:[NSValue valueWithRange:range]];
    }
    if (tokenizer)
    {
        CFRelease(tokenizer);
    }
    return array;
}

+ (NSRange)getWordByTextIndex:(int)index textPage:(FSPDFTextSelect*)fstextPage
{
    __block NSRange retRange = NSMakeRange(index, 1);
    
    int pageTotalCharCount = 0;
    
    if (fstextPage != nil) {
        pageTotalCharCount = [fstextPage getCharCount];
    }
    
    int startIndex = MAX(0, index - 25);
    int endIndex = MIN(pageTotalCharCount-1, index + 25);
    index -= startIndex;
    
    NSString *str = [fstextPage getChars:MIN(startIndex,endIndex) count:ABS(endIndex-startIndex)+1];
    NSArray *array = [self _getUnitWordBoundary:str];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeValue];
        if (NSLocationInRange(index, range))
        {
            NSString *tmp = [str substringWithRange:range];
            if ([tmp isEqualToString:@" "])
            {
                NSUInteger nextIndex = idx + 1;
                if (nextIndex < array.count)
                {
                    range = [[array objectAtIndex:nextIndex] rangeValue];
                }
            }
            retRange = NSMakeRange(startIndex + range.location, range.length);
            *stop = YES;
        }
    }];
    return retRange;
}

+ (NSArray*)getTextRects:(FSPDFTextSelect*)fstextPage start:(int)start count:(int)count
{
    NSMutableArray *ret = [NSMutableArray array];
    
    if (fstextPage != nil)
    {
        int rectCount = [fstextPage getTextRectCount:start count:count];
        for (int i = 0; i < rectCount; i++)
        {
            FSRectF* dibRect = [fstextPage getTextRect:i];
            if (dibRect.getLeft == dibRect.getRight || dibRect.getTop == dibRect.getBottom)
            {
                continue;
            }
            
            int direction = [fstextPage getBaselineRotation:i];
            NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGRect:[Utility FSRectF2CGRect:dibRect]],[NSNumber numberWithInt:direction],nil];
            
            [ret addObject:array];
        }
        
        //merge rects if possible
        if (ret.count > 1)
        {
            int i = 0;
            while (i < ret.count-1)
            {
                int j = i + 1;
                while (j < ret.count)
                {
                    FSRectF* rect1 = [Utility CGRect2FSRectF:[[[ret objectAtIndex:i] objectAtIndex:0] CGRectValue]];
                    FSRectF* rect2 = [Utility CGRect2FSRectF:[[[ret objectAtIndex:j] objectAtIndex:0] CGRectValue]];
                    
                    int direction1 = [[[ret objectAtIndex:i] objectAtIndex:1] intValue];
                    int direction2 = [[[ret objectAtIndex:j] objectAtIndex:1] intValue];
                    BOOL adjcent = NO;
                    if (direction1 == direction2)
                    {
                        adjcent = NO;
                    }
                    if(adjcent)
                    {
                        FSRectF* rectResult = [[FSRectF alloc] init];
                        [rectResult set:MIN([rect1 getLeft], [rect2 getLeft]) bottom:MAX([rect1 getTop], [rect2 getTop]) right:MAX([rect1 getRight], [rect2 getRight]) top:MIN([rect1 getBottom], [rect2 getBottom])];
                        NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGRect:[Utility FSRectF2CGRect:rectResult]],[NSNumber numberWithInt:direction1],nil];
                        [ret replaceObjectAtIndex:i withObject:array];
                        [ret removeObjectAtIndex:j];
                        [rectResult release];
                    }
                    else
                    {
                        j++;
                    }
                }
                i++;
            }
        }
    }
    
    return ret;
}

+ (BOOL)isGivenPath:(NSString*)path type:(NSString*)type
{
    NSString *dotType =[NSString stringWithFormat:@".%@",type];
    if([path.pathExtension.lowercaseString isEqualToString:type.lowercaseString])
    {
        return YES;
    }
    else if([path.lowercaseString isEqualToString:dotType])
    {
        return YES;
    }
    return NO;
}

+ (BOOL)isGivenExtension:(NSString*)extension type:(NSString*)type
{
    return [extension.lowercaseString isEqualToString:type.lowercaseString];
}

#pragma mark - methods from DmUtil
#pragma mark Static method

static void _CGDataProviderReleaseDataCallback(void *info, const void *data, size_t size)
{
    free((void*)data);
}

+ (UIImage*)dib2img:(void*)pBuf size:(int)size dibWidth:(int)dibWidth dibHeight:(int)dibHeight withAlpha:(BOOL)withAlpha
{
    int bit = 3;
    if (withAlpha)
    {
        bit = 4;
    }
    unsigned char* buf = (unsigned char*)pBuf;
    int stride32 = dibWidth*bit;
    dispatch_apply(dibHeight, dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t ri) {
        dispatch_apply(dibWidth, dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t j) {
            long i = dibHeight - 1 - ri;
            unsigned char tmp = buf[i*stride32 + j*bit    ];
            buf[i*stride32 + j*bit    ] = buf[i*stride32 + j*bit + 2];
            buf[i*stride32 + j*bit + 2] = tmp;
        });
    });
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pBuf, size, _CGDataProviderReleaseDataCallback);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    if (withAlpha)
    {
        bitmapInfo = bitmapInfo | kCGImageAlphaLast;
    }
    CGImageRef image = CGImageCreate(dibWidth,dibHeight, 8, withAlpha?32:24, dibWidth * (withAlpha?4:3),
                                     colorSpace, bitmapInfo,
                                     provider, NULL, YES, kCGRenderingIntentDefault);
    UIImage *img = [UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    CGImageRelease(image);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    return img;
}

+ (BOOL)rectEqualToRect:(FSRectF *)rect rect:(FSRectF *)rect1
{
    if ([rect getLeft] == [rect1 getLeft] &&
        [rect getRight] == [rect1 getRight] &&
        [rect getTop] == [rect getTop] &&
        [rect getBottom] == [rect1 getBottom]) {
        return YES;
    }
    return NO;
}

+ (CGRect)FSRectF2CGRect:(FSRectF*)fsrect
{
    if (fsrect == nil) {
        return CGRectZero;
    }
    return CGRectMake(fsrect.getLeft, fsrect.getTop, (fsrect.getRight-fsrect.getLeft), (fsrect.getBottom - fsrect.getTop));
}

+ (FSRectF*)CGRect2FSRectF:(CGRect)rect
{
    FSRectF* fsrect = [[[FSRectF alloc] init] autorelease];
    [fsrect set:rect.origin.x bottom:rect.origin.y + rect.size.height right:rect.origin.x + rect.size.width top:rect.origin.y];
    return fsrect;
}

+ (NSDate*)convertFSDateTime2NSDate:(FSDateTime *)time
{
    if ([time getYear] > 10000 || [time getYear] == 0 ||
        [time getMonth] > 12 || [time getMonth] == 0 ||
        [time getDay] > 31 || [time getDay] == 0 ||
        [time getHour] > 24 ||
        [time getMinute] > 60 ||
        [time getSecond] > 60)
    {
        return nil;
    }
    
    unsigned short hour = [time getHour] + [time getUTHourOffset];
    unsigned short minute = [time getMinute] + [time getUTMinuteOffset];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:[time getYear]];
    [comps setMonth:[time getMonth]];
    [comps setDay:[time getDay]];
    [comps setHour:hour];
    [comps setMinute:minute];
    [comps setSecond:[time getSecond]];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *date = [gregorian dateFromComponents:comps];
    [gregorian release];
    [comps release];
    return date;
}

+ (FSDateTime *)convert2FSDateTime:(NSDate*)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ;
    NSDateComponents *comps = [gregorian components:unitFlags fromDate:date];
    FSDateTime *time = [[[FSDateTime alloc] init] autorelease];
    time.year = [comps year];
    time.month = [comps month];
    time.day = [comps day];
    time.hour = [comps hour];
    time.minute = [comps minute];
    time.second = [comps second];
    time.UTHourOffset = timezone / 3600 * -1;
    time.UTMinuteOffset = (abs(timezone) % 3600) / 60;
    [gregorian release];
    return time;
}

CGPDFDocumentRef GetPDFDocumentRef (const char *filename)
{
    CFStringRef path;
    CFURLRef url;
    CGPDFDocumentRef document;
    size_t count;
    
    path = CFStringCreateWithCString (NULL, filename, kCFStringEncodingUTF8);
    
    url = CFURLCreateWithFileSystemPath (NULL, path, kCFURLPOSIXPathStyle,0);
    
    CFRelease (path);
    
    document = CGPDFDocumentCreateWithURL (url);
    
    count = CGPDFDocumentGetNumberOfPages (document);
    if (count == 0) {
        printf("`%s' needs at least onepage!", filename);
        CFRelease(url);
        CGPDFDocumentRelease(document);
        return NULL;
    }
    
    CFRelease(url);
    return document;
}

+ (CGSize)getPDFPageSizeWithIndex:(NSUInteger)index pdfPath:(NSString *)path
{
    @synchronized(self)
    {
        CGPDFDocumentRef document = nil;
        CGPDFPageRef page;
        document = GetPDFDocumentRef ([path cStringUsingEncoding:NSUTF8StringEncoding]);
        if (document == nil)
        {
            return CGSizeMake(0, 0);
        }
        page = CGPDFDocumentGetPage (document, 1);
        CGRect pageRect = CGRectIntegral(CGPDFPageGetBoxRect(page, kCGPDFCropBox));
        CFRelease(document);
        return pageRect.size;
    }
}

+ (UIImage *)drawPageThumbnailWithPDFPath:(NSString *)pdfPath pageIndex:(int)pageIndex pageSize:(CGSize)size
{
    @synchronized(self)
    {
        CGPDFDocumentRef document;
        CGPDFPageRef page;
        document = GetPDFDocumentRef([pdfPath cStringUsingEncoding:NSUTF8StringEncoding]);
        if (document == nil)
        {
            return nil;
        }
        page = CGPDFDocumentGetPage (document, pageIndex + 1);
        UIGraphicsBeginImageContextWithOptions(size, NO, 4);
        CGContextSetRGBFillColor( UIGraphicsGetCurrentContext(), 1.0, 1.0, 1.0, 1.0 );
        CGContextFillRect( UIGraphicsGetCurrentContext(), CGContextGetClipBoundingBox(UIGraphicsGetCurrentContext()));
        CGContextSaveGState(UIGraphicsGetCurrentContext());
        
        CGContextTranslateCTM( UIGraphicsGetCurrentContext(), 0.0, size.height);
        CGContextScaleCTM( UIGraphicsGetCurrentContext(), 1.0, -1.0 );
        
        CGAffineTransform pdfXfm =
        CGPDFPageGetDrawingTransform(page, kCGPDFMediaBox, CGRectMake(0, 0, size.width, size.height), 0, true );
        CGContextConcatCTM( UIGraphicsGetCurrentContext(), pdfXfm );
        
        CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
        CGContextSetRenderingIntent(UIGraphicsGetCurrentContext(), kCGRenderingIntentDefault);
        CGContextDrawPDFPage( UIGraphicsGetCurrentContext(), page);
        CGContextRestoreGState(UIGraphicsGetCurrentContext());
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CFRelease(document);
        return image;
    }
}

+ (enum FS_ENCRYPTTYPE)getDocumentSecurityType:(NSString*)filePath taskServer:(TaskServer*)taskServer
{
    __block enum FS_ERRORCODE ret = e_encryptCustom;
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        enum FS_MODULERIGHT right = [FSLibrary getModuleRight:e_moduleNameStandard];
        if(right == e_moduleRightNone || right == e_moduleRightUnknown)
            return;
        FSPDFDoc* fspdfdoc = [FSPDFDoc createFromFilePath:filePath];
        ret = [fspdfdoc load:nil];
        if (ret != e_errSuccess && ret != e_errHandler) {
            return;
        }
    };
    if(!taskServer)
        taskServer = [[[TaskServer alloc] init] autorelease];
    [taskServer executeSync:task];
    
    if (ret == e_errSuccess) {
        return e_encryptNone;
    }
    else if (ret == e_errPassword)
    {
        return e_encryptPassword;
    }
    else if (ret == e_errHandler)
    {
        return e_encryptRMS;
    }
    else
    {
        return e_encryptCustom;
    }
}

+ (NSString*)convert2SysFontString:(NSString*)str
{
    NSString *ret = str;
    if ([str isEqualToString:@"Times-Roman"])
    {
        ret = @"TimesNewRomanPSMT";
    }
    else if ([str isEqualToString:@"Times-Bold"])
    {
        ret = @"TimesNewRomanPS-BoldMT";
    }
    else if ([str isEqualToString:@"Times-Italic"])
    {
        ret = @"TimesNewRomanPS-ItalicMT";
    }
    else if ([str isEqualToString:@"Times-BoldItalic"])
    {
        ret = @"TimesNewRomanPS-BoldItalicMT";
    }
    return ret;
}

//Get test size by font
+ (CGSize)getTestSize:(UIFont*)font
{
    return [@"WM" sizeWithFont:font];
}

+ (float)getAnnotMinXMarginInPDF:(FSPDFViewCtrl*)pdfViewCtrl pageIndex:(int)pageIndex
{
    CGRect pvRect = CGRectMake(0, 0, 10, 10);
    FSRectF* pdfRect = [pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:pageIndex];
    return pdfRect.right - pdfRect.left;
}

+ (float)getAnnotMinYMarginInPDF:(FSPDFViewCtrl*)pdfViewCtrl pageIndex:(int)pageIndex
{
    CGRect pvRect = CGRectMake(0, 0, 10, 10);
    FSRectF* pdfRect = [pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:pageIndex];
    return pdfRect.top - pdfRect.bottom;
}

+ (float)convertWidth:(float)width fromPageViewToPDF:(FSPDFViewCtrl*)pdfViewCtrl pageIndex:(int)pageIndex
{
    FSRectF *fsRect = [[[FSRectF alloc] init] autorelease];
    [fsRect set:0 bottom:width right:width top:0];
    CGRect pvRect = [pdfViewCtrl convertPdfRectToPageViewRect:fsRect pageIndex:pageIndex];
    return pvRect.size.width;
}

+ (CGRect)getAnnotRect:(FSAnnot*)annot pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl
{
    FSPDFPage* page = [pdfViewCtrl.currentDoc getPage:annot.pageIndex];
    if (page) {
        CGRect retRect = CGRectZero;
        FSMatrix* fsmatrix = [pdfViewCtrl getDisplayMatrix:annot.pageIndex];
        FSRectI *annotRect = [annot getDeviceRect:NO matrix:fsmatrix];
        retRect.origin.x = [annotRect getLeft];
        retRect.origin.y = [annotRect getTop];
        retRect.size.width = [annotRect getRight] - [annotRect getLeft];
        retRect.size.height = [annotRect getBottom] - [annotRect getTop];
        return retRect;
    }
    return CGRectZero;
}

//todo
#define UX_BG_COLOR_NIGHT_PAGEVIEW		0xFF00001b
#define UX_TEXT_COLOR_NIGHT			0xFF5d5b71

+ (UIImage*)getAnnotImage:(FSAnnot*)annot pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl
{
    FSPDFPage* page = [annot getPage];
    
    int pageIndex = annot.pageIndex;
    CGRect rect = [self getAnnotRect:annot pdfViewCtrl:pdfViewCtrl];
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();

    FSMatrix* fsmatrix = [page getDisplayMatrix:-rect.origin.x
                                           yPos:-rect.origin.y
                                          xSize:ceilf([pdfViewCtrl getPageViewWidth:pageIndex])
                                          ySize:ceilf([pdfViewCtrl getPageViewHeight:pageIndex])
                                         rotate:e_rotation0];
    FSRenderer* fsrenderer = [FSRenderer createFromContext:context deviceType:e_deviceTypeDisplay];
    [fsrenderer setTransformAnnotIcon:NO];
    if ([pdfViewCtrl isNightMode])
    {
        [fsrenderer setColorMode:e_colorModeMapping];
        [fsrenderer setMappingModeColors:UX_BG_COLOR_NIGHT_PAGEVIEW foreColor:UX_TEXT_COLOR_NIGHT];
    }
    [fsrenderer renderAnnot:annot matrix:fsmatrix];
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

static const char * s_StandardFontNames[] = {
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
    "ZapfDingbats"
};

+ (int)toStandardFontID:(NSString*)fontName
{
    for(int i=0; i<sizeof(s_StandardFontNames)/sizeof(const char*); i++)
    {
        NSString* stdFontName =[NSString stringWithUTF8String:s_StandardFontNames[i]];
        if ([fontName isEqualToString:stdFontName]) {
            return i;
        }
    }
    return -1;
}

+ (FSRectF*)normalizeFSRect:(FSRectF*)dibRect
{
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

+ (CGRect)normalizeCGRect:(CGRect)rect
{
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

+ (FSRectF*)makeFSRectWithLeft:(float)left top:(float)top right:(float)right bottom:(float)bottom
{
    FSRectF* rect = [[[FSRectF alloc] init] autorelease];
    [rect set:left bottom:bottom right:right top:top];
    return rect;
}

+ (NSString*)getErrorCodeDescription:(enum FS_ERRORCODE)error
{
    switch (error) {
        case e_errSecurityHandler:
            return NSLocalizedString(@"kInvalidSecurityHandler", nil);
        case e_errFile:
            return NSLocalizedString(@"kUnfoundOrCannotOpen", nil);
        case e_errFormat:
            return NSLocalizedString(@"kInvalidFormat", nil);
        case e_errPassword:
            return NSLocalizedString(@"kDocPasswordError", nil);
        case e_errHandler:
            return NSLocalizedString(@"kHandlerError", nil);
        case e_errCertificate:
            return NSLocalizedString(@"kWrongCertificate", nil);
        case e_errUnknown:
            return NSLocalizedString(@"kUnknownError", nil);
        case e_errInvalidLicense:
            return NSLocalizedString(@"kInvalidLibraryLicense", nil);
        case e_errParam:
            return NSLocalizedString(@"kInvalidParameter", nil);
        case e_errUnsupported:
            return NSLocalizedString(@"kUnsupportedType", nil);
        case e_errOutOfMemory:
            return NSLocalizedString(@"kOutOfMemory", nil);
        default:
            return @"";
    }
}

@end
