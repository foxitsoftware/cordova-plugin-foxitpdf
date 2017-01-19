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
#import "rdk_other_headers.h"
#import "rdk_other_headers.h" //#import "FSAnnot.h"

#define NOTE_ANNOTATION_WIDTH 36

@interface NoteAnnot : FSAnnot

+ (NoteAnnot *)createWithDefaultOptionForPageIndex:(int)pageIndex rect:(FSRectF *)rect contents:(NSString *)contents author:(NSString*)author;

@end
