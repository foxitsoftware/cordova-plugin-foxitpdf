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

/**
 * @name Macro Definitions for icon type.
 */
/**@{*/
/** @brief note icon type Check. */
#define FPDF_ICONTYPE_NOTE_CHECK			0
/** @brief note icon type Circle. */
#define FPDF_ICONTYPE_NOTE_CIRCLE			1
/** @brief note icon type Comment. */
#define FPDF_ICONTYPE_NOTE_COMMENT			2
/** @brief note icon type Cross. */
#define FPDF_ICONTYPE_NOTE_CROSS			3
/** @brief note icon type Help. */
#define FPDF_ICONTYPE_NOTE_HELP				4
/** @brief note icon type Insert. */
#define FPDF_ICONTYPE_NOTE_INSERT			5
/** @brief note icon type Key. */
#define FPDF_ICONTYPE_NOTE_KEY				6
/** @brief note icon type New Paragraph. */
#define FPDF_ICONTYPE_NOTE_NEWPARAGRAPH		7
/** @brief note icon type Note. */
#define FPDF_ICONTYPE_NOTE_NOTE				8
/** @brief note icon type Paragraph. */
#define FPDF_ICONTYPE_NOTE_PARAGRAPH		9
/** @brief note icon type Right Arrow. */
#define FPDF_ICONTYPE_NOTE_RIGHTARROW		10
/** @brief note icon type Right Pointer. */
#define FPDF_ICONTYPE_NOTE_RIGHTPOINTER		11
/** @brief note icon type Star. */
#define FPDF_ICONTYPE_NOTE_STAR				12
/** @brief note icon type Up Arrow. */
#define FPDF_ICONTYPE_NOTE_UPARROW			13
/** @brief note icon type Upleft Arrow. */
#define FPDF_ICONTYPE_NOTE_UPLEFTARROW		14

/** @brief Unknown icon type. */
#define FPDF_ICONTYPE_UNKNOWN				-1
/**@}*/


/** @brief Class extension for FSAnnot. Use properties for convenient. */
@interface FSAnnot(useProperties)

/** @brief The associated page index. */
@property (nonatomic, assign, readonly) int pageIndex;
/** @brief Readonly property for detail annotation type. */
@property (nonatomic, assign, readonly) enum FS_ANNOTTYPE type;

/** @brief The annotation rectangle. */
@property (nonatomic, assign) FSRectF *fsrect;
/** @brief The annotation border color. */
@property (nonatomic, assign) unsigned int color;
/** @brief Stands for "lineWidth" for line and arrow line, line_width for pencil and link, "borderWidth" for rectangle. */
@property (nonatomic, assign) int lineWidth;
/** @brief The annotation flags such as print.. and so on. */
@property (nonatomic, assign) int flags;
@property (nonatomic, assign) NSString *subject;
/** @brief The name of the annotation, which is the unique id. */
@property (nonatomic, assign) NSString *NM;
@property (nonatomic, assign) NSString *author;
@property (nonatomic, assign) NSString *contents;
@property (nonatomic, assign) NSDate *modifiedDate;
@property (nonatomic, assign) NSDate *createDate;
@property (nonatomic, assign) NSString *intent;
/** @brief The texts covered by the quadrilateral area of annotation. */
@property (nonatomic, assign, readonly) NSString *selectedText;
@property (nonatomic, assign) NSArray *quads;
@property (nonatomic, assign) int icon;
@property (nonatomic, assign) float opacity;
/** @brief The unique id of the annotation to which current annotation replied. */
@property (nonatomic, assign, readonly) NSString *replyTo;
@property (nonatomic, assign, readonly) BOOL canModify;
/** @brief Non markup annotations can't be replied. */
@property (nonatomic, assign, readonly) BOOL canReply;

@end

