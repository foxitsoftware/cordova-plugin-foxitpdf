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

#import "FSAnnotAttributes.h"
#import "FSAnnotExtent.h"
#import "Utility.h"

static BOOL stringsEqual(NSString *str1, NSString *str2) {
    return (str1 == nil && str2 == nil) || [str1 isEqualToString:str2];
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
    BOOL (^isQuadsEqual)() = ^BOOL {
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

@end
