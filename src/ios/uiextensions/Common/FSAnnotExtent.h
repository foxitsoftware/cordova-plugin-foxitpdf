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

#import "../Undo/FSAnnotAttributes.h"
#import <FoxitRDK/FSPDFObjC.h>

/** @brief Class category for FSAnnot. Use properties for convenience. */
@interface FSAnnot (useProperties)

/** @brief The associated page index. */
@property (nonatomic, assign, readonly) int pageIndex;
/** @brief Readonly property for detail annotation type. */
@property (nonatomic, assign, readonly) FSAnnotType type;

/** @brief The annotation rectangle. */
@property (nonatomic, strong) FSRectF *fsrect;
/** @brief The annotation border color. */
@property (nonatomic, assign) unsigned int color;
/** @brief Stands for "lineWidth" for line and arrow line, line_width for pencil and link, "borderWidth" for rectangle. */
@property (nonatomic, assign) float lineWidth;
/** @brief The annotation flags such as print.. and so on. */
@property (nonatomic, assign) unsigned int flags;
@property (nonatomic, strong) NSString *subject;
/** @brief The name of the annotation, which is the unique id. */
@property (nonatomic, strong) NSString *NM;
@property (nonatomic, readonly) NSString *uuidWithPageIndex;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *contents;
@property (nonatomic, strong) NSDate *modifiedDate;
@property (nonatomic, strong) NSDate *createDate;
@property (nonatomic, strong) NSString *intent;
/** @brief The texts covered by the quadrilateral area of annotation. */
@property (nonatomic, assign, readonly) NSString *selectedText;
@property (nonatomic, strong) NSArray *quads;
@property (nonatomic, assign) int icon;
@property (nonatomic, assign) float opacity;
/** @brief The unique id of the annotation to which current annotation replied. */
@property (nonatomic, assign, readonly) NSString *replyTo;
@property (nonatomic, assign, readonly) BOOL canModify;
@property (nonatomic, assign, readonly) BOOL canCopyText;
/** @brief Non markup annotations can't be replied. */
@property (nonatomic, assign, readonly) BOOL canReply;

- (void)applyAttributes:(FSAnnotAttributes *)attributes;
- (BOOL)isEqualToAnnot:(FSAnnot *)annot;
- (BOOL)isReplyToAnnot:(FSAnnot *)annot;

@end
