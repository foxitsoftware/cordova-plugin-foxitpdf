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

#import <FoxitRDK/FSPDFObjC.h>

@interface FSAnnotAttributes : NSObject
@property (nonatomic, assign) int pageIndex;
@property (nonatomic, assign) enum FS_ANNOTTYPE type;
@property (nonatomic, strong) NSString *NM;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) FSRectF* rect;
@property (nonatomic, assign) unsigned int color;
@property (nonatomic, assign) float opacity;
@property (nonatomic, strong) NSDate *modificationDate;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, assign) unsigned int flags;
+ (instancetype)attributesWithAnnot:(FSAnnot*)annot;
- (instancetype)initWithAnnot:(FSAnnot*)annot;
- (void)resetAnnot:(FSAnnot*)annot;
- (BOOL)isEqualToAttributes:(FSAnnotAttributes*)attributes;
@end

@interface FSNoteAttributes : FSAnnotAttributes
@property (nonatomic, assign) int icon;
@property (nonatomic, strong) NSString* replyTo;
@property (nonatomic, strong) NSString* contents;
@end

@interface FSCaretAttributes : FSAnnotAttributes
@property (nonatomic, strong) NSString* contents;
@property (nonatomic, strong) NSString* subject;
@property (nonatomic, strong) NSString* intent;
@property (nonatomic, assign) int rotation;
@property (nonatomic, strong) FSRectF* innerRect;
@end

@interface FSTextMarkupAttributes : FSAnnotAttributes
@property (nonatomic, strong) NSArray<FSQuadPoints*>* quads;
@property (nonatomic, strong) NSString* contents;
@property (nonatomic, strong) NSString* subject;
@end

@interface FSLineAttributes : FSAnnotAttributes
@property (nonatomic, assign) float lineWidth;
@property (nonatomic, strong) NSString* subject;
@property (nonatomic, strong) NSString* intent;
@property (nonatomic, strong) FSPointF* startPoint;
@property (nonatomic, strong) FSPointF* endPoint;
@property (nonatomic, strong) NSString* startPointStyle;
@property (nonatomic, strong) NSString* endPointStyle;
@property (nonatomic, strong) FSOffset* captionOffset;
@property (nonatomic, strong) NSString* captionStyle;
@property (nonatomic, assign) unsigned int fillColor;
@property (nonatomic, strong) NSString* contents;
@end

@interface FSInkAttributes : FSAnnotAttributes
@property (nonatomic, assign) float lineWidth;
@property (nonatomic, strong) FSPDFPath* inkList;
@property (nonatomic, strong) NSString* contents;
@end

@interface FSStampAttributes : FSAnnotAttributes
@property (nonatomic, strong) NSString* iconName;
@property (nonatomic, strong) NSString* contents;
@end

@interface FSShapeAttributes : FSAnnotAttributes
@property (nonatomic, assign) float lineWidth;
@property (nonatomic, strong) NSString* subject;
@property (nonatomic, strong) NSString* contents;
@end

@interface FSFreeTextAttributes : FSAnnotAttributes
@property (nonatomic, strong) NSString* contents;
@property (nonatomic, strong) NSString* intent;
@property (nonatomic, strong) NSString* subject;
// default appearance
@property (nonatomic, strong) NSString* fontName;
@property (nonatomic, assign) int defaultAppearanceFlags;
@property (nonatomic, assign) float fontSize;
@property (nonatomic, assign) unsigned int textColor;
@end

@interface FSFileAttachmentAttributes : FSAnnotAttributes
@property (nonatomic, strong) NSString* iconName;
@property (nonatomic, strong) NSString* fileName;
@property (nonatomic, strong) NSString* attachmentPath;
@property (nonatomic, strong) NSString* contents;
@property (nonatomic, strong) FSDateTime* fileCreationTime;
@property (nonatomic, strong) FSDateTime* fileModificationTime;
@end
