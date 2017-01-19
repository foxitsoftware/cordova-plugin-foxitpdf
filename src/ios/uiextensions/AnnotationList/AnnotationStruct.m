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
#import "AnnotationStruct.h"

static AnnotationStruct* annostru=nil;
static FSPDFViewCtrl* _pdfViewControl=nil;
static BOOL needStopThread = NO;
static BOOL isThreadRuning = NO;

@interface AnnotationStruct ()
- (void)recursionAnnostruct:(AnnotationItem*)currentnode  childnodes:(NSArray*)childs collectarray:(NSMutableArray*)collectarray AnnoStruct:(NSDictionary*)annostruct;
- (void)recursionAnnostruct:(AnnotationItem*)deleteanno childnodes:(NSArray*)childs  currentAnnotation:(AnnotationItem*)currentanno AnnoStruct:(NSDictionary*)annostruct superAnnotation:(AnnotationItem**)superannotation;
@end


@implementation AnnotationStruct

+ (void)setStopThreadFlag
{
    needStopThread = YES;
}

+ (BOOL)isThreadRunning
{
    return isThreadRuning;
}

+ (AnnotationStruct*)getSingle
{
    @synchronized(self){
    
        if (!annostru) {
            
            annostru=[[AnnotationStruct alloc]init];
        }
    }
    return annostru;
}

+ (void)setViewControl:(FSPDFViewCtrl*)pdfViewControl
{
    _pdfViewControl = pdfViewControl;
}

- (NSMutableDictionary*)getAnnotationStructWithAnnos:(NSArray*)annosarray
{
    
    if (annosarray == nil) {
        return [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary* tempdic = [NSMutableDictionary dictionary];
    
    for (int i = 0; i< annosarray.count; i++) {
        
        AnnotationItem* searchanno = [annosarray objectAtIndex:i];
        
        NSString* annotionuuid = searchanno.annot.NM;
        
        if (!annotionuuid.length) {
            continue;
        }
        
        NSMutableArray* onenoteannotempary=[NSMutableArray array];
        
        for (int a=0; a< annosarray.count; a++) {
            
            AnnotationItem* tempanno = [annosarray objectAtIndex:a];
            if(![searchanno.annot isMarkup])
                break;
            int countOfReplies = [(FSMarkup*)searchanno.annot getReplyCount];
            for(int r=0; r<countOfReplies; r++)
            {
                FSNote* note = [(FSMarkup*)searchanno.annot getReply:r];
                if(!note) continue;
                if([note.NM isEqualToString:tempanno.annot.NM])
                {
                    [onenoteannotempary addObject:tempanno];
                    break;
                }
            }
        }
        
        [tempdic setObject:onenoteannotempary forKey:annotionuuid];
    }
    return tempdic;
}

- (NSArray*)getAllChildNodesWithSuperAnnotation:(AnnotationItem *)superanno andAnnoStruct:(NSDictionary*)annostruct
{
    if (superanno == nil || annostruct == nil)
    {
        return [NSArray array];
    }
    NSMutableArray* childsarray=[NSMutableArray array];
    [self recursionAnnostruct:superanno childnodes:[annostruct objectForKey:superanno.annot.NM] collectarray:childsarray AnnoStruct:annostruct];
    
    return childsarray;
}

- (void)recursionAnnostruct:(AnnotationItem*)currentnode  childnodes:(NSArray*)childs collectarray:(NSMutableArray*)collectarray AnnoStruct:(NSDictionary*)annostruct
{

    if (childs.count == 0) {
        return;
    }
    
    [collectarray addObjectsFromArray:childs];
    
    for (AnnotationItem* annotation in childs) {
        
        [self recursionAnnostruct:annotation childnodes:[annostruct objectForKey:annotation.annot.NM] collectarray:collectarray AnnoStruct:annostruct];
        
    }
    
}

- (NSInteger)getAnnotationLevel:(AnnotationItem *)annotation AnnoStruct:(NSDictionary*)annostruct rootAnnotation:(AnnotationItem*)rootanno
{
    NSUInteger annlevel= 0;
    
    AnnotationItem* superannotation= nil;
    
    [self recursionAnnostruct:annotation childnodes:[annostruct objectForKey:rootanno.annot.NM] currentAnnotation:rootanno AnnoStruct:annostruct superAnnotation:&superannotation];
    
    while (superannotation) {
        
        AnnotationItem* tempanno = superannotation;
        superannotation = nil;
        annlevel++;
        [self recursionAnnostruct:tempanno childnodes:[annostruct objectForKey:rootanno.annot.NM] currentAnnotation:rootanno AnnoStruct:annostruct superAnnotation:&superannotation];
    }
    return annlevel;
}

- (void)getRootAnnotation:(AnnotationItem *)annotation TargetAnnotation:(AnnotationItem**)targetanno AnnoArray:(NSArray*)annoarrays
{
    
    for (AnnotationItem* checkanno in annoarrays) {
        
        if (annotation.annot.replyTo != nil && annotation.annot.replyTo.length > 0 && [annotation.annot.replyTo isEqualToString:checkanno.annot.NM]) {
            
            *targetanno=checkanno;
            [self getRootAnnotation:checkanno TargetAnnotation:targetanno AnnoArray:annoarrays];
            
        }
    }
}


- (BOOL)deleteAnnotationFromAnnoStruct:(NSMutableDictionary *)annostruct deleteAnnotation:(AnnotationItem*)deletenode rootAnnotation:(AnnotationItem*)rootanno
{
    
    if (deletenode == nil || annostruct== nil || rootanno == nil)
    {
        return NO;
    }
    
    AnnotationItem* superannotation=nil;
    
    [self recursionAnnostruct:deletenode childnodes:[annostruct objectForKey:rootanno.annot.NM] currentAnnotation:rootanno AnnoStruct:annostruct superAnnotation:&superannotation];
    
    if (superannotation && [annostruct objectForKey:superannotation.annot.NM]) {
        
        [[annostruct objectForKey:superannotation.annot.NM]removeObject:deletenode];
        [annostruct removeObjectForKey:deletenode.annot.NM];
        
        return YES;
    }
    
    return NO;
}


- (void)recursionAnnostruct:(AnnotationItem*)deleteanno childnodes:(NSArray*)childs  currentAnnotation:(AnnotationItem*)currentanno AnnoStruct:(NSDictionary*)annostruct superAnnotation:(AnnotationItem**)superannotation
{
    
    if (childs.count == 0) {
        return;
    }
    for (AnnotationItem* anno in childs) {
        
        if ([anno.annot.NM isEqualToString:deleteanno.annot.NM]) {
            
            *superannotation=currentanno;
            
            break;
            
        }else{
            
            [self recursionAnnostruct:deleteanno childnodes:[annostruct objectForKey:anno.annot.NM] currentAnnotation:anno AnnoStruct:annostruct superAnnotation:superannotation];
        }
    }
}


- (BOOL)insertAnnotationToAnnoStruct:(NSMutableDictionary *)annostruct insertAnnotation:(AnnotationItem *)insertnode SuperAnnotation:(AnnotationItem*)superanno
{
    
    if (annostruct == nil || insertnode == nil || superanno == nil) {
        return NO;
    }
    
    NSMutableArray* nodes=[NSMutableArray array];
    [annostruct setObject:nodes forKey:insertnode.annot.NM];
    
    if ([annostruct objectForKey:superanno.annot.NM]) {
        
        [[annostruct objectForKey:superanno.annot.NM]addObject:insertnode];
    }

    return NO;
}


- (NSString *)annotationImageName:(AnnotationItem *)annotation
{
    NSString *resultString = nil;

    switch (annotation.annot.type)
    {
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
            
        case e_annotLine:
        {
            FSLine * pLine = (FSLine *)annotation.annot;
            if ( ([[pLine getLineEndingStyle] isEqualToString:@"OpenArrow"] &&
                  [[pLine getLineStartingStyle] isEqualToString:@"None"]) ||
                ([[pLine getLineStartingStyle] isEqualToString:@"OpenArrow"] &&
                 [[pLine getLineEndingStyle] isEqualToString:@"None"]) ){
                resultString = @"panel_annotation_arrow.png";
                break;
            }else{
                resultString = @"panel_annotation_line.png";
                break;
            }
        }
        case e_annotInk:
            resultString = @"panel_annotation_pencil.png";
            break;
            
        case e_annotFreeText:
            resultString = @"panel_annotation_freetext.png";
            break;
            
        case e_annotStamp:
            resultString = @"panel_annotation_stamp.png";
            break;
            
        case e_annotCaret:
        {
            if ([annotation.annot.intent isEqualToString:@"Replace"]){
                resultString = @"panel_annotation_replace.png";
            }else{
                resultString = @"panel_annotation_insert.png";
            }
        }
            break;
            
        default:
            break;
    }
    return resultString;
}

+ (void)getAnnotation:(GetAnnotationFoundHandler)getAnnotationFoundHandler CleanupIfFailed:(void (^)())cleanup
{
    getAnnotationFoundHandler = [getAnnotationFoundHandler copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       isThreadRuning = YES;
                       needStopThread = NO;
                       
                       int totalPage = [_pdfViewControl.currentDoc getPageCount];
                       if (totalPage == 0)
                       {
                           if (getAnnotationFoundHandler)
                           {
                               dispatch_sync(dispatch_get_main_queue(), ^{
                                   getAnnotationFoundHandler(nil, 0, 0);
                               });
                           }
                       }
                       else
                       {
                           for (int i = 0; i < totalPage; i++)
                           {
                               if(needStopThread)
                               {
                                   cleanup();
                                   break ;
                               }
                               
                               if (getAnnotationFoundHandler)
                               {
                                   dispatch_sync(dispatch_get_main_queue(), ^{
                                       
                                       if(needStopThread)
                                           return ;
                                       
                                       FSPDFPage* page = [_pdfViewControl.currentDoc getPage:i];
                                       NSArray *array = [Utility getAnnots:page];
                                       NSMutableArray *itemArray = [NSMutableArray array];
                                       for (FSAnnot* annot in array)
                                       {
                                           AnnotationItem *annoItem = [[[AnnotationItem alloc] init] autorelease];
                                           annoItem.annot = annot;
                                           if (annot.type != e_annotWidget &&
                                               (!(annot.type == e_annotStrikeOut && [Utility isReplaceText:(FSStrikeOut*)annot]))
                                               ) {
                                               //Callout,Textbox will be filtered out.
                                               if(annot.type == e_annotFreeText)
                                               {
                                                   NSString* intent = [((FSMarkup*)annot) getIntent];
                                                   if(!intent || [intent caseInsensitiveCompare:@"FreeTextTypeWriter"] != NSOrderedSame)
                                                       continue;
                                               }
                                               [itemArray addObject:annoItem];
                                           }
                                       }
                                       getAnnotationFoundHandler(itemArray, i, totalPage);
                                   });
                               }
                           }
                       }
                       [getAnnotationFoundHandler release];
                       needStopThread = NO;
                       isThreadRuning = NO;
                   });
}


@end
