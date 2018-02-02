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

#import "AnnotationStruct.h"

@interface AnnotationStruct ()
+ (void)recursionAnnostruct:(AnnotationItem *)currentnode childnodes:(NSArray *)childs collectarray:(NSMutableArray *)collectarray AnnoStruct:(NSDictionary *)annostruct;
+ (void)recursionAnnostruct:(AnnotationItem *)deleteanno childnodes:(NSArray *)childs currentAnnotation:(AnnotationItem *)currentanno AnnoStruct:(NSDictionary *)annostruct superAnnotation:(AnnotationItem **)superannotation;
@end

@implementation AnnotationStruct

+ (NSMutableDictionary *)getAnnotationStructWithAnnos:(NSArray *)annosarray {
    if (annosarray == nil) {
        return [NSMutableDictionary dictionary];
    }

    NSMutableDictionary *tempdic = [NSMutableDictionary dictionary];

    for (int i = 0; i < annosarray.count; i++) {
        AnnotationItem *searchanno = [annosarray objectAtIndex:i];

        NSString *annotionuuid = searchanno.annot.uuidWithPageIndex;

        NSMutableArray *onenoteannotempary = [NSMutableArray array];

        if ([searchanno.annot isMarkup]) {
            int countOfReplies = [(FSMarkup *) searchanno.annot getReplyCount];
            for (int r = 0; r < countOfReplies; r++) {
                FSNote *note = [(FSMarkup *) searchanno.annot getReply:r];
                if (!note)
                    continue;
                for (int a = 0; a < annosarray.count; a++) {
                    AnnotationItem *tempanno = [annosarray objectAtIndex:a];
                    if ([note isEqualToAnnot:tempanno.annot]) {
                        [onenoteannotempary addObject:tempanno];
                        break;
                    }
                }
            }
        }

        [tempdic setObject:onenoteannotempary forKey:annotionuuid];
    }
    return tempdic;
}

+ (NSArray *)getAllChildNodesWithSuperAnnotation:(AnnotationItem *)superanno annoStruct:(NSDictionary *)annostruct {
    if (superanno == nil || annostruct == nil) {
        return [NSArray array];
    }
    NSMutableArray *childsarray = [NSMutableArray array];
    [self recursionAnnostruct:superanno childnodes:[annostruct objectForKey:superanno.annot.uuidWithPageIndex] collectarray:childsarray AnnoStruct:annostruct];

    return childsarray;
}

+ (void)recursionAnnostruct:(AnnotationItem *)currentnode childnodes:(NSArray *)childs collectarray:(NSMutableArray *)collectarray AnnoStruct:(NSDictionary *)annostruct {
    if (childs.count == 0) {
        return;
    }

    [collectarray addObjectsFromArray:childs];

    for (AnnotationItem *annotation in childs) {
        [self recursionAnnostruct:annotation childnodes:[annostruct objectForKey:annotation.annot.uuidWithPageIndex] collectarray:collectarray AnnoStruct:annostruct];
    }
}

+ (NSInteger)getAnnotationLevel:(AnnotationItem *)annotation AnnoStruct:(NSDictionary *)annostruct rootAnnotation:(AnnotationItem *)rootanno {
    NSUInteger annlevel = 0;

    AnnotationItem *superannotation = nil;

    [self recursionAnnostruct:annotation childnodes:[annostruct objectForKey:rootanno.annot.uuidWithPageIndex] currentAnnotation:rootanno AnnoStruct:annostruct superAnnotation:&superannotation];

    while (superannotation) {
        AnnotationItem *tempanno = superannotation;
        superannotation = nil;
        annlevel++;
        [self recursionAnnostruct:tempanno childnodes:[annostruct objectForKey:rootanno.annot.uuidWithPageIndex] currentAnnotation:rootanno AnnoStruct:annostruct superAnnotation:&superannotation];
    }
    return annlevel;
}

+ (void)getRootAnnotation:(AnnotationItem *)annotation TargetAnnotation:(AnnotationItem **)targetanno AnnoArray:(NSArray *)annoarrays {
    for (AnnotationItem *checkanno in annoarrays) {
        if ([annotation.annot isReplyToAnnot:checkanno.annot]) {
            *targetanno = checkanno;
            [self getRootAnnotation:checkanno TargetAnnotation:targetanno AnnoArray:annoarrays];
        }
    }
}

+ (BOOL)deleteAnnotationFromAnnoStruct:(NSMutableDictionary *)annostruct deleteAnnotation:(AnnotationItem *)deletenode rootAnnotation:(AnnotationItem *)rootanno {
    if (deletenode == nil || annostruct == nil || rootanno == nil) {
        return NO;
    }

    AnnotationItem *superannotation = nil;

    [self recursionAnnostruct:deletenode childnodes:[annostruct objectForKey:rootanno.annot.uuidWithPageIndex] currentAnnotation:rootanno AnnoStruct:annostruct superAnnotation:&superannotation];

    if (superannotation && [annostruct objectForKey:superannotation.annot.uuidWithPageIndex]) {
        [[annostruct objectForKey:superannotation.annot.uuidWithPageIndex] removeObject:deletenode];
        [annostruct removeObjectForKey:deletenode.annot.uuidWithPageIndex];

        return YES;
    }

    return NO;
}

+ (void)recursionAnnostruct:(AnnotationItem *)deleteanno childnodes:(NSArray *)childs currentAnnotation:(AnnotationItem *)currentanno AnnoStruct:(NSDictionary *)annostruct superAnnotation:(AnnotationItem **)superannotation {
    if (childs.count == 0) {
        return;
    }
    for (AnnotationItem *anno in childs) {
        if ([anno.annot.uuidWithPageIndex isEqualToString:deleteanno.annot.uuidWithPageIndex]) {
            *superannotation = currentanno;

            break;

        } else {
            [self recursionAnnostruct:deleteanno childnodes:[annostruct objectForKey:anno.annot.uuidWithPageIndex] currentAnnotation:anno AnnoStruct:annostruct superAnnotation:superannotation];
        }
    }
}

+ (BOOL)insertAnnotationToAnnoStruct:(NSMutableDictionary *)annostruct insertAnnotation:(AnnotationItem *)insertnode SuperAnnotation:(AnnotationItem *)superanno {
    if (annostruct == nil || insertnode == nil || superanno == nil) {
        return NO;
    }

    NSMutableArray *nodes = [NSMutableArray array];
    [annostruct setObject:nodes forKey:insertnode.annot.uuidWithPageIndex];

    if ([annostruct objectForKey:superanno.annot.uuidWithPageIndex]) {
        [[annostruct objectForKey:superanno.annot.uuidWithPageIndex] addObject:insertnode];
    }

    return NO;
}

+ (NSString *)annotationImageName:(AnnotationItem *)annotation {
    NSString *resultString = nil;

    switch (annotation.annot.type) {
    case e_annotHighlight:
        resultString = @"panel_annotation_highlight.png";
        break;

    case e_annotUnderline:
        resultString = @"panel_annotation_underline.png";
        break;

    case e_annotStrikeOut:
        resultString = @"panel_annotation_strikeout.png";
        break;

    case e_annotSquiggly:
        resultString = @"panel_annotation_squiggly.png";
        break;

    case e_annotNote:
        resultString = @"panel_annotation_note.png";
        break;

    case e_annotSquare:
        resultString = @"panel_annotation_rectangle.png";
        break;

    case e_annotCircle:
        resultString = @"panel_annotation_circle.png";
        break;

    case e_annotLine: {
        FSLine *pLine = (FSLine *) annotation.annot;
        if (([[pLine getLineEndingStyle] isEqualToString:@"OpenArrow"] &&
             [[pLine getLineStartingStyle] isEqualToString:@"None"]) ||
            ([[pLine getLineStartingStyle] isEqualToString:@"OpenArrow"] &&
             [[pLine getLineEndingStyle] isEqualToString:@"None"])) {
            resultString = @"panel_annotation_arrow.png";
            break;
            } else if([[pLine getIntent] isEqualToString:@"LineDimension"]){
                resultString = @"panel_annotation_distance.png";
                break;
            } else {
            resultString = @"panel_annotation_line.png";
            break;
        }
    }
    case e_annotInk:
        resultString = @"panel_annotation_pencil.png";
        break;

    case e_annotFreeText: {
        BOOL isTextbox = (annotation.annot.intent == nil);
        resultString = isTextbox ? @"panel_annotation_textbox.png" : @"panel_annotation_freetext.png";
        break;
    }

    case e_annotStamp:
        resultString = @"panel_annotation_stamp.png";
        break;

    case e_annotCaret: {
        if ([annotation.annot.intent isEqualToString:@"Replace"]) {
            resultString = @"panel_annotation_replace.png";
        } else {
            resultString = @"panel_annotation_insert.png";
        }
    } break;

    case e_annotFileAttachment:
        resultString = @"panel_annotation_fileattachment.png";
        break;

    case e_annotScreen:
        resultString = @"panel_annotation_image.png";
        break;

    case e_annotPolygon: {
        FSPolygon *polygon = (FSPolygon *) annotation.annot;
        BOOL isCloud = ([[polygon getBorderInfo] getStyle] == e_borderStyleCloudy);
        resultString = isCloud ? @"panel_annotation_cloud.png" : @"panel_annotation_polygon.png";
    } break;

    default:
        break;
    }
    return resultString;
}

@end
