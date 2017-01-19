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
#import <FoxitRDK/FSPDFObjC.h>
#import <UIKit/UIKit.h>
#import "Utility.h"
#import "Const.h"
#import "FSAnnotExtent.h"


NSDate* convertFSDateTime2NSDate(FSDateTime *time)
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
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:[time getYear]];
    [comps setMonth:[time getMonth]];
    [comps setDay:[time getDay]];
    [comps setHour:[time getHour]];
    [comps setMinute:[time getMinute]];
    [comps setSecond:[time getSecond]];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *date = [gregorian dateFromComponents:comps];
    [gregorian release];
    [comps release];
    return date;
}

FSDateTime* convert2FSDateTime(NSDate* date)
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
    time.UTHourOffset = 0;
    time.UTMinuteOffset = 0;
    [gregorian release];
    return time;
}

FSRectF* convertToFSRect(FSPointF *p1, FSPointF *p2)
{
    FSRectF *rect = [[FSRectF alloc] init];
    rect.left = MIN([p1 getX], [p2 getX]);
    rect.right = MAX([p1 getX], [p2 getX]);
    rect.top = MAX([p1 getY], [p2 getY]);
    rect.bottom = MIN([p1 getY], [p2 getY]);
    return [rect autorelease];
}

int convertIconStringType2IntType(NSString* newType)
{
    newType = [newType lowercaseString];
    if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_CHECK lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_CHECK;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_CIRCLE lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_CIRCLE;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_COMMENT lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_COMMENT;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_CROSS lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_CROSS;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_HELP lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_HELP;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_INSERT lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_INSERT;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_KEY lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_KEY;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_NEWPARAGRAPH lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_NEWPARAGRAPH;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_NOTE lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_NOTE;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_PARAGRAPH lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_PARAGRAPH;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_RIGHTARROW lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_RIGHTARROW;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_RIGHTPOINTER lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_RIGHTPOINTER;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_STAR lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_STAR;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_UPARROW lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_UPARROW;
    }
    else if ([newType isEqualToString:[@FS_ANNOT_ICONNAME_TEXT_UPLEFTARROW lowercaseString]])
    {
        return FPDF_ICONTYPE_NOTE_UPLEFTARROW;
    }
    
    return FPDF_ICONTYPE_UNKNOWN;
}

NSString* convertIconIntType2StringType(int oldType, BOOL isNote)
{
    if (isNote)
    {
        if (oldType == FPDF_ICONTYPE_NOTE_CHECK)
        {
            return @FS_ANNOT_ICONNAME_TEXT_CHECK;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_CIRCLE)
        {
            return @FS_ANNOT_ICONNAME_TEXT_CIRCLE;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_COMMENT)
        {
            return @FS_ANNOT_ICONNAME_TEXT_COMMENT;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_CROSS)
        {
            return @FS_ANNOT_ICONNAME_TEXT_CROSS;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_HELP)
        {
            return @FS_ANNOT_ICONNAME_TEXT_HELP;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_INSERT)
        {
            return @FS_ANNOT_ICONNAME_TEXT_INSERT;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_KEY)
        {
            return @FS_ANNOT_ICONNAME_TEXT_KEY;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_NEWPARAGRAPH)
        {
            return @FS_ANNOT_ICONNAME_TEXT_NEWPARAGRAPH;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_NOTE)
        {
            return @FS_ANNOT_ICONNAME_TEXT_NOTE;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_PARAGRAPH)
        {
            return @FS_ANNOT_ICONNAME_TEXT_PARAGRAPH;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_RIGHTARROW)
        {
            return @FS_ANNOT_ICONNAME_TEXT_RIGHTARROW;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_RIGHTPOINTER)
        {
            return @FS_ANNOT_ICONNAME_TEXT_RIGHTPOINTER;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_STAR)
        {
            return @FS_ANNOT_ICONNAME_TEXT_STAR;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_UPARROW)
        {
            return @FS_ANNOT_ICONNAME_TEXT_UPARROW;
        }
        else if (oldType == FPDF_ICONTYPE_NOTE_UPLEFTARROW)
        {
            return @FS_ANNOT_ICONNAME_TEXT_UPLEFTARROW;
        }
    }
    
    return nil;
}

NSString* convertStampIconIndex2String(int index)
{
    switch (index) {
        case 0:
            return @"Approved";
        case 1:
            return @"Completed";
            
        case 2:
            return @"Confidential";
            
        case 3:
            return @"Draft";
            
        case 4:
            return @"Emergency";
            
        case 5:
            return @"Expired";
            
        case 6:
            return @"Final";
            
        case 7:
            return @"Received";
            
        case 8:
            return @"Reviewed";
            
        case 9:
            return @"Revised";
            
        case 10:
            return @"Verified";
            
        case 11:
            return @"Void";
            
        case 12:
            return @"Accepted";
            
        case 13:
            return @"Initial";
            
        case 14:
            return @"Rejected";
            
        case 15:
            return @"Sign Here";
            
        case 16:
            return @"Witness";
            
        case 17:
            return @"DynaApproved";
            
        case 18:
            return @"DynaConfidential";
            
        case 19:
            return @"DynaReceived";
            
        case 20:
            return @"DynaReviewed";
            
        case 21:
            return @"DynaRevised";
            
        default:
            break;
    }
    
    return nil;
}


@implementation FSAnnot(useProperties)

-(int)pageIndex
{
    return [[self getPage] getIndex];
}

-(enum FS_ANNOTTYPE)type
{
    return [self getType];
}

-(FSRectF*)fsrect
{
    return [self getRect];
}

-(void)setFsrect:(FSRectF *)fsrect
{
    [self move:fsrect];
}

-(unsigned int)color
{
    if (self.type == e_annotFreeText) {
        FSFreeText* annot = (FSFreeText*)self;
        FSDefaultAppearance* ap = [annot getDefaultAppearance];
        return ap.textColor;
    } else {
        return [self getBorderColor];
    }
}

-(void)setColor:(unsigned int)color
{
    if (self.type == e_annotFreeText) {
        FSFreeText* annot = (FSFreeText*)self;
        FSDefaultAppearance* ap = [annot getDefaultAppearance];
        ap.textColor = color;
        [annot setDefaultAppearance:ap];
    }
    else {
        [self setBorderColor:color];
    }
}

-(int)lineWidth
{
    return [[self getBorderInfo] getWidth];
}
-(void)setLineWidth:(int)lineWidth
{
    FSBorderInfo* borderInfo = [[FSBorderInfo alloc] init];
    [borderInfo setStyle:e_borderStyleSolid];
    [borderInfo setWidth:lineWidth];
    [self setBorderInfo:borderInfo];
    [borderInfo release];
}
-(int)flags
{
    return [self getFlags];
}

-(NSString*)subject
{
    if(![self isMarkup]) return nil;
    return [(FSMarkup*)self getSubject];
}

-(void)setSubject:(NSString *)subject
{
    if(![self isMarkup]) return;
    return [(FSMarkup*)self setSubject:subject];
}

-(NSString*)NM
{
    return [self getUniqueID];
}
-(void)setNM:(NSString *)NM
{
    [self setUniqueID:NM];
}
-(NSString *)replyTo
{
    if (e_annotNote != self.type) {
        return nil;
    }
    
    FSMarkup* markup = [(FSNote*)self getReplyTo];
    if(!markup)
        return nil;
    return markup.NM;
}
-(NSString*)author
{
    if(![self isMarkup]) return nil;
    FSMarkup* mk = (FSMarkup*)self;
    return [mk getTitle];
}
-(void)setAuthor:(NSString *)author
{
    FSMarkup* mk = (FSMarkup*)self;
    return [mk setTitle:author];
}
-(NSString*)contents
{
    return [self getContent];
}

-(void)setContents:(NSString*)contents
{
    [self setContent:contents];
}

-(NSDate*)modifiedDate
{
    FSDateTime* dt = [self getModifiedDateTime];
    return convertFSDateTime2NSDate(dt);
}
-(void)setModifiedDate:(NSDate *)modifiedDate
{
    FSDateTime* dt = convert2FSDateTime(modifiedDate);
    [self setModifiedDateTime:dt];
}
-(NSDate*)createDate
{
    if(![self isMarkup]) return nil;
    FSMarkup* mk = (FSMarkup*)self;
    FSDateTime* dt = [mk getCreationDateTime];
    return convertFSDateTime2NSDate(dt);
}
-(void)setCreateDate:(NSDate *)createDate
{
    if(![self isMarkup]) return;
    FSMarkup* mk = (FSMarkup*)self;
    FSDateTime* dt = convert2FSDateTime(createDate);
    [mk setCreationDateTime:dt];
}
-(NSString*)intent
{
    if(![self isMarkup]) return nil;
    FSMarkup* mk = (FSMarkup*)self;
    return [mk getIntent];
}
-(void)setIntent:(NSString *)intent
{
    if(![self isMarkup]) return;
    FSMarkup* mk = (FSMarkup*)self;
    return [mk setIntent:intent];
}
-(NSString*)selectedText
{
    FSPDFPage* _fspage = [self getPage];
    FSPDFTextSelect* textPage = nil;
    BOOL parseSuccess = YES;
    enum FS_PROGRESSSTATE state = [_fspage startParse:e_parsePageTextOnly pause:nil isReparse:NO];
    if (e_progressError == state)
    {
        parseSuccess = NO;
    }
    else if (e_progressToBeContinued == state)
    {
        while (e_progressToBeContinued == state)
        {
            state = [_fspage continueParse];
        }
        if (e_progressFinished != state)
        {
            parseSuccess = NO;
        }
    }
    
    if (parseSuccess)
    {
        textPage = [FSPDFTextSelect create:_fspage];
    }
    
    NSString* selectedText = @"";
    if (textPage)
    {
        NSArray *array = self.quads;
        for (int i = 0; i < array.count; i++)
        {
            FSQuadPoints *arrayQuad = [array objectAtIndex:i];
            FSRectF *rect = convertToFSRect(arrayQuad.getFirst, arrayQuad.getFourth);
            NSString *tmp = [textPage getTextInRect:rect];
            if (tmp) {
                selectedText = [selectedText stringByAppendingString:tmp];
            }
        }
    }
    return selectedText;
}
-(NSArray*)quads
{
    NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
    if(e_annotHighlight != [self getType] && e_annotUnderline != [self getType] && e_annotStrikeOut != [self getType] && e_annotSquiggly != [self getType] && e_annotLink != [self getType]) return nil;
    
    int count = [(id)self getQuadPointsCount];
    for (int i  = 0; i < count; i++) {
        FSQuadPoints *quadPoint = [(id)self getQuadPoints:i];
        [array addObject:quadPoint];
    }
    return array;
}
-(void)setQuads:(NSArray *)quads
{
    if (nil == quads) return;
    
    if(e_annotHighlight != [self getType] && e_annotUnderline != [self getType] && e_annotStrikeOut != [self getType] && e_annotSquiggly != [self getType] && e_annotLink != [self getType]) return;
    
    [(FSTextMarkup*)self setQuadPoints:quads];
}

-(BOOL)canReply
{
    if(![self isMarkup])
        return NO;
    
    if (self.type == e_annotFreeText) {
        return NO;
    }
    return YES;
}

-(BOOL)canModify
{
    return YES;
}

-(float)opacity
{
    if(![self isMarkup]) return 1.0;
    FSMarkup* mk = (FSMarkup*)self;
    return [mk getOpacity];
}

-(void)setOpacity:(float)opacity
{
    if(![self isMarkup]) return;
    FSMarkup* mk = (FSMarkup*)self;
    [mk setOpacity:opacity];
}

-(void)setIcon:(int)icon
{
    if (e_annotNote == self.type)
        [(FSNote*)self setIconName:convertIconIntType2StringType(icon, YES)];
    else if (e_annotStamp == self.type)
        [(FSStamp*)self setIconName:convertStampIconIndex2String(icon)];
    else if (e_annotFileAttachment == self.type)
        ;//todo
}

-(int)icon
{
    if (e_annotNote == self.type || e_annotStamp == self.type || e_annotFileAttachment == self.type)
        return convertIconStringType2IntType([(FSNote*)self getIconName]);
        return FPDF_ICONTYPE_UNKNOWN;
}

@end

