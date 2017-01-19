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
#import "NoteAnnot.h"
#import "iosrdk/FSPDFObjC.h"

@implementation NoteAnnot

+ (NoteAnnot *)createWithDefaultOptionForPageIndex:(int)pageIndex rect:(FSRectF *)rect contents:(NSString *)contents author:(NSString*)author
{
    NoteAnnot *annot = [[NoteAnnot alloc] initWithType:e_annotNote];
    annot.NM = [Utility getUUID];
    annot.pageIndex = pageIndex;
    annot.fsrect = rect;
    annot.author = author;
    annot.contents = @"";
    annot.color = 0;
    annot.opacity = 100;
    annot.lineWidth = 2;
    annot.icon = 0;
    return annot;
}

- (BOOL)isSame:(FSAnnot*)annot
{
    return (self.type == annot.type
            && self.rect.top == annot.rect.top
            && self.rect.bottom == annot.rect.bottom
            && self.rect.left == annot.rect.left
            && self.rect.right == annot.rect.right
            && [self.author compare:annot.author] == NSOrderedSame
            && [self.NM compare:annot.NM] == NSOrderedSame
            && [self.contents compare:annot.contents] == NSOrderedSame
            && self.color == annot.color
            && self.opacity == annot.opacity
            && self.lineWidth == annot.lineWidth);
}


@end
