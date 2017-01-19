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
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "AnnotationListCell.h"
typedef void (^GetAnnotationFoundHandler)(NSArray* array, int currentPageIndex, int totalPageIndex);

/**@brief Utility class for loading all the annotations on the document. */
@interface AnnotationStruct : NSObject

+ (void)setStopThreadFlag;
+ (BOOL)isThreadRunning;

+ (void)setViewControl:(FSPDFViewCtrl*)pdfViewControl;
+ (AnnotationStruct *)getSingle;
+ (void)getAnnotation:(GetAnnotationFoundHandler)getAnnotationFoundHandler CleanupIfFailed:(void (^)())cleanup;
- (NSString *)annotationImageName:(AnnotationItem *)annotation;
- (NSMutableDictionary *)getAnnotationStructWithAnnos:(NSArray *)annosarray;
- (NSArray *)getAllChildNodesWithSuperAnnotation:(AnnotationItem *)superanno andAnnoStruct:(NSDictionary *)annostruct;
- (NSInteger)getAnnotationLevel:(AnnotationItem *)annotation AnnoStruct:(NSDictionary *)annostruct rootAnnotation:(AnnotationItem *)rootanno;
- (void)getRootAnnotation:(AnnotationItem *)annotation TargetAnnotation:(AnnotationItem **)targetanno AnnoArray:(NSArray *)annoarrays;
- (BOOL)deleteAnnotationFromAnnoStruct:(NSMutableDictionary *)annostruct deleteAnnotation:(AnnotationItem *)deletenode rootAnnotation:(AnnotationItem *)rootanno;
- (BOOL)insertAnnotationToAnnoStruct:(NSDictionary *)annostruct insertAnnotation:(AnnotationItem *)insertnode SuperAnnotation:(AnnotationItem *)superanno;

@end
