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

#import "FSAnnotAttributes.h"
#import "FSAnnotExtent.h"
#import "Utility.h"

static inline BOOL CGFloatEqual(CGFloat v1, CGFloat v2) {
    return fabs(v1 - v2) < 1e-4;
}

static BOOL stringsEqual(NSString *str1, NSString *str2) {
    return (str1 == nil && str2 == nil) || [str1 isEqualToString:str2];
}

static BOOL pointEqual(FSPointF *pt1, FSPointF *pt2) {
    return CGFloatEqual(pt1.x, pt2.x) && CGFloatEqual(pt1.y, pt2.y);
}

static BOOL pointsEqual(NSArray<FSPointF *> *array1, NSArray<FSPointF *> *array2) {
    if (array1.count != array2.count) {
        return NO;
    }
    for (NSUInteger i = 0; i < array1.count; i++) {
        if (!pointEqual(array1[i], array2[i])) {
            return NO;
        }
    }
    return YES;
}

static BOOL borderInfoEqual(FSBorderInfo *border1, FSBorderInfo *border2) {
    if (border1 == nil && border1 == nil) {
        return YES;
    }
    return border1 && border2 &&
           [border1 getStyle] == [border2 getStyle] &&
           CGFloatEqual([border1 getWidth], [border2 getWidth]);
}

@implementation FSAnnotAttributes

+ (instancetype)attributesWithAnnot:(FSAnnot *)annot {
    switch (annot.type) {
    case e_annotNote:
        return [[FSNoteAttributes alloc] initWithAnnot:(FSNote *) annot];
    case e_annotCaret:
        return [[FSCaretAttributes alloc] initWithAnnot:(FSCaret *) annot];
    case e_annotStrikeOut:
    case e_annotHighlight:
    case e_annotSquiggly:
    case e_annotUnderline:
        return [[FSTextMarkupAttributes alloc] initWithAnnot:(FSTextMarkup *) annot];
    case e_annotLine:
        return [[FSLineAttributes alloc] initWithAnnot:(FSLine *) annot];
    case e_annotInk:
        return [[FSInkAttributes alloc] initWithAnnot:(FSInk *) annot];
    case e_annotStamp:
        return [[FSStampAttributes alloc] initWithAnnot:(FSStamp *) annot];
    case e_annotCircle:
    case e_annotSquare:
        return [[FSShapeAttributes alloc] initWithAnnot:annot];
    case e_annotFreeText:
        return [[FSFreeTextAttributes alloc] initWithAnnot:annot];
    case e_annotFileAttachment:
        return [[FSFileAttachmentAttributes alloc] initWithAnnot:annot];
    case e_annotScreen:
        return [[FSScreenAttributes alloc] initWithAnnot:annot];
    case e_annotPolygon:
        return [[FSPolygonAttributes alloc] initWithAnnot:annot];
    default:
        return [[FSAnnotAttributes alloc] initWithAnnot:annot];
    }
}

- (instancetype)initWithAnnot:(FSAnnot *)annot {
    if (self = [super init]) {
        self.pageIndex = annot.pageIndex;
        self.type = annot.type;
        self.NM = annot.NM;
        self.author = annot.author;
        self.rect = annot.fsrect;
        self.color = annot.color;
        self.opacity = annot.opacity;
        self.creationDate = annot.createDate;
        self.modificationDate = annot.modifiedDate;
        self.flags = annot.flags;
    }
    return self;
}

- (void)resetAnnot:(FSAnnot *)annot {
    annot.NM = self.NM;
    annot.author = self.author;
    annot.fsrect = self.rect;
    annot.color = self.color;
    annot.opacity = self.opacity;
    annot.createDate = self.creationDate;
    annot.modifiedDate = self.modificationDate;
    annot.flags = self.flags;
}

- (BOOL)isEqualToAttributes:(FSAnnotAttributes *)attributes {
    return self.type == attributes.type &&
           [Utility rectEqualToRect:self.rect
                               rect:attributes.rect] &&
           stringsEqual(self.author, attributes.author) &&
           self.color == attributes.color &&
           self.opacity == attributes.opacity &&
           [self.creationDate compare:attributes.creationDate] == NSOrderedSame &&
           [self.modificationDate compare:attributes.modificationDate] == NSOrderedSame &&
           self.flags == attributes.flags;
}

@end

@implementation FSNoteAttributes

- (instancetype)initWithAnnot:(FSNote *)note {
    assert(note.type == e_annotNote);
    if (self = [super initWithAnnot:note]) {
        self.icon = note.icon;
        self.replyTo = [note getReplyTo].NM;
        self.contents = note.contents;
    }
    return self;
}

- (void)resetAnnot:(FSNote *)annot {
    assert(annot.type == e_annotNote);
    [super resetAnnot:annot];
    annot.icon = self.icon;
    annot.contents = self.contents;
    [annot resetAppearanceStream];
}

- (BOOL)isEqualToAttributes:(FSNoteAttributes *)attributes {
    return [attributes class] == [self class] &&
           self.icon == attributes.icon &&
           stringsEqual(self.contents, attributes.contents) &&
           [super isEqualToAttributes:attributes];
}

@end

@implementation FSCaretAttributes

- (instancetype)initWithAnnot:(FSCaret *)caret {
    assert(caret.type == e_annotCaret);
    if (self = [super initWithAnnot:caret]) {
        self.contents = caret.contents;
        self.subject = caret.subject;
        self.intent = caret.intent;
        self.innerRect = [caret getInnerRect];
        FSPDFDictionary *dict = [caret getDict];
        self.rotation = [dict hasKey:@"Rotate"] ? [[dict getElement:@"Rotate"] getInteger] : 0;
    }
    return self;
}

- (void)resetAnnot:(FSCaret *)annot {
    assert(annot.type == e_annotCaret);
    annot.contents = self.contents;
    annot.subject = self.subject;
    annot.intent = self.intent;
    [annot setInnerRect:self.innerRect];
    if (self.rotation != 0) {
        [[annot getDict] setAt:@"Rotate" object:[FSPDFObject createFromInteger:self.rotation]];
    }
    [super resetAnnot:annot];
    [annot resetAppearanceStream]; // neccessary?
}

- (BOOL)isEqualToAttributes:(FSCaretAttributes *)attributes {
    return [attributes class] == [self class] &&
           self.rotation == attributes.rotation &&
           [super isEqualToAttributes:attributes] &&
           stringsEqual(self.contents, attributes.contents) &&
           stringsEqual(self.intent, attributes.intent) &&
           stringsEqual(self.subject, attributes.subject);
}

@end

@implementation FSTextMarkupAttributes

- (instancetype)initWithAnnot:(FSTextMarkup *)markup {
    if (self = [super initWithAnnot:markup]) {
        self.quads = markup.quads;
        self.subject = markup.subject;
        self.contents = markup.contents;
    }
    return self;
}

- (void)resetAnnot:(FSTextMarkup *)annot {
    [super resetAnnot:annot];
    annot.quads = self.quads;
    annot.subject = self.subject;
    annot.contents = self.contents;
    [annot resetAppearanceStream];
}

- (BOOL)isEqualToAttributes:(FSTextMarkupAttributes *)attributes {
    BOOL (^isQuadsEqual)(void) = ^BOOL {
        if (self.quads.count != attributes.quads.count) {
            return NO;
        }
        for (int i = 0; i < self.quads.count; i++) {
            if (![Utility quadsEqualToQuads:self.quads[i] quads:attributes.quads[i]]) {
                return NO;
            }
        }
        return YES;
    };
    return [super isEqualToAttributes:attributes] &&
           stringsEqual(self.contents, attributes.contents) &&
           stringsEqual(self.subject, attributes.subject) &&
           isQuadsEqual();
}

@end

@implementation FSLineAttributes

- (instancetype)initWithAnnot:(FSLine *)line {
    if (self = [super initWithAnnot:line]) {
        self.lineWidth = line.lineWidth;
        self.subject = line.subject;
        self.intent = line.intent;
        self.startPoint = [line getStartPoint];
        self.endPoint = [line getEndPoint];
        self.startPointStyle = [line getLineStartingStyle];
        self.endPointStyle = [line getLineEndingStyle];
        self.captionStyle = [line getCaptionPositionType];
        self.captionOffset = [line getCaptionOffset];
        self.fillColor = [line getStyleFillColor];
        self.contents = line.contents;
        
        if ([[line getIntent] isEqualToString:@"LineDimension"]){
            self.measureUnit = [line getMeasureUnit:0];
            self.measureRatio = [line getMeasureRatio];
            self.measureConversionFactor = [line getMeasureConversionFactor:0];
        }
    }
    return self;
}

- (void)resetAnnot:(FSLine *)annot {
    [super resetAnnot:annot];

    annot.lineWidth = self.lineWidth;
    annot.subject = self.subject;
    annot.contents = self.contents;
    if (self.intent) {
        annot.intent = self.intent;
    }
    [annot setStartPoint:self.startPoint];
    [annot setEndPoint:self.endPoint];
    [annot setLineStartingStyle:self.startPointStyle];
    [annot setLineEndingStyle:self.endPointStyle];
    [annot setCaptionOffset:self.captionOffset];
    if (self.captionStyle) {
        [annot setCaptionPositionType:self.captionStyle];
    }
    [annot setStyleFillColor:self.fillColor];
    
    if ([self.intent isEqualToString:@"LineDimension"]){
        [annot setMeasureUnit:0 unit:self.measureUnit];
        [annot setMeasureRatio:self.measureRatio];
        [annot setMeasureConversionFactor:0 factor:self.measureConversionFactor];
    }
    
    [annot resetAppearanceStream];
}

- (BOOL)isEqualToAttributes:(FSLineAttributes *)attributes {
    return self.class == attributes.class &&
           stringsEqual(self.contents, attributes.contents) &&
           fabsf(self.lineWidth - attributes.lineWidth) < 1e-4 &&
           [Utility pointEqualToPoint:self.startPoint
                                point:attributes.startPoint] &&
           [Utility pointEqualToPoint:self.endPoint
                                point:attributes.endPoint] &&
           stringsEqual(self.startPointStyle, attributes.startPointStyle) &&
           stringsEqual(self.endPointStyle, attributes.endPointStyle) &&
           self.fillColor == attributes.fillColor &&
           [Utility pointEqualToPoint:self.captionOffset
                                point:attributes.captionOffset] &&
           stringsEqual(self.intent, attributes.intent) &&
           [super isEqualToAttributes:attributes];
}

@end

@implementation FSInkAttributes

- (instancetype)initWithAnnot:(FSInk *)ink {
    if (self = [super initWithAnnot:ink]) {
        self.lineWidth = ink.lineWidth;
        self.inkList = [Utility cloneInkList:[ink getInkList]];
        if(!self.inkList)
            return nil;
        self.contents = ink.contents;
    }
    return self;
}

- (void)resetAnnot:(FSInk *)annot {
    [super resetAnnot:annot];
    annot.lineWidth = self.lineWidth;
    [annot setInkList:self.inkList];
    annot.contents = self.contents;
    [annot resetAppearanceStream];
}

- (BOOL)isEqualToAttributes:(FSInkAttributes *)attributes {
    return self.class == attributes.class &&
           fabsf(self.lineWidth - attributes.lineWidth) < 1e-4 &&
           stringsEqual(self.contents, attributes.contents) &&
           [super isEqualToAttributes:attributes] &&
           [Utility inkListEqualToInkList:self.inkList
                                  inkList:attributes.inkList];
}

@end

@implementation FSStampAttributes

- (instancetype)initWithAnnot:(FSStamp *)stamp {
    if (self = [super initWithAnnot:stamp]) {
        self.iconName = [stamp getIconName];
        self.contents = stamp.contents;
    }
    return self;
}

- (void)resetAnnot:(FSStamp *)annot {
    [super resetAnnot:annot];
    if ([Utility isValidIconName:self.iconName annotType:self.type]) {
        [annot setIconName:self.iconName];
    } else {
        annot.icon = 0; // default icon type
    }
    annot.contents = self.contents;

    [annot resetAppearanceStream];
}

- (BOOL)isEqualToAttributes:(FSStampAttributes *)attributes {
    return stringsEqual(self.iconName, attributes.iconName) &&
           stringsEqual(self.contents, attributes.contents) &&
           [super isEqualToAttributes:attributes];
}

@end

@implementation FSShapeAttributes

- (instancetype)initWithAnnot:(FSAnnot *)annot {
    if (self = [super initWithAnnot:annot]) {
        self.lineWidth = annot.lineWidth;
        self.subject = annot.subject;
        self.contents = annot.contents;
    }
    return self;
}

- (void)resetAnnot:(FSAnnot *)annot {
    [super resetAnnot:annot];
    annot.lineWidth = self.lineWidth;
    annot.subject = self.subject;
    annot.contents = self.contents;
    [annot resetAppearanceStream];
}

- (BOOL)isEqualToAttributes:(FSShapeAttributes *)attributes {
    return fabsf(self.lineWidth - attributes.lineWidth) < 1e-4 &&
           stringsEqual(self.contents, attributes.contents) &&
           stringsEqual(self.subject, attributes.subject) &&
           [super isEqualToAttributes:attributes];
}

@end

@implementation FSFreeTextAttributes

- (instancetype)initWithAnnot:(FSFreeText *)annot {
    if (self = [super initWithAnnot:annot]) {
        self.contents = annot.contents;
        self.subject = annot.subject;
        self.intent = annot.intent;
        FSDefaultAppearance *ap = [annot getDefaultAppearance];
        self.fontName = [ap.font getName];
        self.defaultAppearanceFlags = ap.flags;
        self.fontSize = ap.fontSize;
        self.textColor = ap.textColor; // & 0xffffff; // to filter out alpha channel
    }
    return self;
}

- (void)resetAnnot:(FSFreeText *)annot {
    [super resetAnnot:annot];
    annot.contents = self.contents;
    annot.subject = self.subject;
    annot.intent = self.intent;
    {
        FSDefaultAppearance *ap = [(FSFreeText *) annot getDefaultAppearance];
        ap.flags = self.defaultAppearanceFlags;
        int fontID = [Utility toStandardFontID:self.fontName];
        if (fontID == -1) {
            ap.font = [[FSFont alloc] initWithFontName:self.fontName fontStyles:0 weight:0 charset:e_fontCharsetDefault];
        } else {
            ap.font = [[FSFont alloc] initWithStandardFontID:fontID];
        }
        ap.fontSize = self.fontSize;
        ap.textColor = self.textColor;
        [annot setDefaultAppearance:ap];
    }
    [annot resetAppearanceStream];
}

- (BOOL)isEqualToAttributes:(FSFreeTextAttributes *)attributes {
    return self.class == attributes.class &&
           self.textColor == attributes.textColor &&
           self.fontSize == attributes.fontSize &&
           self.defaultAppearanceFlags == attributes.defaultAppearanceFlags &&
           stringsEqual(self.fontName, attributes.fontName) &&
           stringsEqual(self.contents, attributes.contents) &&
           [super isEqualToAttributes:attributes];
}

@end

@implementation FSFileAttachmentAttributes

- (instancetype)initWithAnnot:(FSFileAttachment *)annot {
    if (self = [super initWithAnnot:annot]) {
        self.iconName = [annot getIconName];
        self.fileName = [[annot getFileSpec] getFileName];
        self.attachmentPath = [Utility getAttachmentTempFilePath:annot];
        self.contents = annot.contents;
        self.fileCreationTime = [[annot getFileSpec] getCreationDateTime];
        self.fileModificationTime = [[annot getFileSpec] getModifiedDateTime];
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.attachmentPath]) {
            [Utility loadAttachment:annot toPath:self.attachmentPath];
        }
    }
    return self;
}

- (void)resetAnnot:(FSFileAttachment *)annot {
    [super resetAnnot:annot];
    [annot setIconName:self.iconName];
    annot.contents = self.contents;

    if ([[NSFileManager defaultManager] fileExistsAtPath:self.attachmentPath]) {
        FSFileSpec *attachFile = [[FSFileSpec alloc] initWithPDFDoc:[[annot getPage] getDocument]];
        if (self.fileName) {
            [attachFile setFileName:self.fileName];
        }
        if (attachFile && [attachFile embed:self.attachmentPath]) {
            [attachFile setCreationDateTime:self.fileCreationTime];
            [attachFile setModifiedDateTime:self.fileModificationTime];
            [annot setFileSpec:attachFile];
        }
    }
    [annot resetAppearanceStream];
}

// todo wei - (BOOL)isEqualToAttributes:

@end

@implementation FSScreenAttributes

- (instancetype)initWithAnnot:(FSScreen *)annot {
    if (self = [super initWithAnnot:annot]) {
        self.intent = [annot getIntent];
        self.contents = [annot getContent];
        self.rotation = [annot getRotation];
        self.markupDict = [annot getMKDict];
    }
    return self;
}

- (void)resetAnnot:(FSScreen *)annot {
    [super resetAnnot:annot];
    if (self.intent != nil) {
        [annot setIntent:self.intent];
    }
    [annot setContent:self.contents ?: @""];
    [annot setRotation:self.rotation];
    if (self.markupDict) {
        [annot setMKDict:(FSPDFDictionary*)[self.markupDict cloneObject]]; // use a clone because when annot's markup dict is overwritten the old value is released, use a clone won't affect markupDict property of FSScreenAttributes
    }
    [annot resetAppearanceStream];
}

- (BOOL)isEqualToAttributes:(FSScreenAttributes *)attributes {
    return self.class == attributes.class &&
           stringsEqual(self.intent, attributes.intent) &&
           stringsEqual(self.contents, attributes.contents) &&
           self.rotation == attributes.rotation &&
           [super isEqualToAttributes:attributes];
}

@end

@implementation FSPolygonAttributes

- (instancetype)initWithAnnot:(FSPolygon *)annot {
    if (self = [super initWithAnnot:annot]) {
        self.borderInfo = [annot getBorderInfo];
        self.fillColor = [annot getFillColor];
        self.vertexes = [Utility getPolygonVertexes:annot];
        self.contents = [annot getContent];
    }
    return self;
}

- (void)resetAnnot:(FSPolygon *)annot {
    [super resetAnnot:annot];
    if (self.borderInfo) {
        [annot setBorderInfo:self.borderInfo];
    }
    if ((0xff000000 & self.fillColor) != 0) {
        [annot setFillColor:self.fillColor];
    }
    [annot setVertexes:self.vertexes];
    if (self.contents) {
        [annot setContent:self.contents];
    }
    [annot resetAppearanceStream];
}

- (BOOL)isEqualToAttributes:(FSPolygonAttributes *)attributes {
    return self.class == attributes.class &&
           borderInfoEqual(self.borderInfo, attributes.borderInfo) &&
           self.fillColor == attributes.fillColor &&
           pointsEqual(self.vertexes, attributes.vertexes) &&
           stringsEqual(self.contents, attributes.contents) &&
           [super isEqualToAttributes:attributes];
}

@end
