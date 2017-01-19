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
#import "AnnotationItem.h"

@class AnnotationListCell;
@class AnnotationListMore;
@class ReplyTableViewController;

#define  CELLWIDTH DEVICE_iPHONE?(STYLE_CELLHEIHGT_IPHONE - 20):0

#define  CELLWIDTHIPAD DEVICE_iPHONE?(STYLE_CELLWIDTH_IPHONE-71):100

#define  CELL_ANNOTATIONBUTTON  CGRectMake (10, 15, 16, 16)  //open close button

#define  CELL_ANNOTATIONIMAGEVIEW  CGRectMake(8, 21, 26, 26) //annot type

#define  CELL_ANNOTATIONUPDATEVIEW  CGRectMake(25, 12, 9, 9) //date tip

#define  CELL_ANNOTATIONREPLYTIP  CGRectMake (25, 15, 18, 18) //reply tip

#define  CELL_ANNOTATIONSELECTIMAGEVIEW  CGRectMake(10, 12, 26, 26) //select view

#define  CELL_ANNOTATIONAUTHOR  CGRectMake(50, 16, DEVICE_iPHONE?(STYLE_CELLWIDTH_IPHONE-90):210, 20) //author

#define  CELL_ANNOTATIONDATE  CGRectMake(50,35, DEVICE_iPHONE?(STYLE_CELLWIDTH_IPHONE-50):250, 20) //date

#define  CELL_ANNOTATIONCONTENTS  CGRectMake(20, 69, DEVICE_iPHONE? STYLE_CELLWIDTH_IPHONE - 40 : 260, 20) //content

#define  CELL_REPLYCONTENTS  CGRectMake(20, 69, DEVICE_iPHONE? STYLE_CELLWIDTH_IPHONE - 40 : 500, 20) //content

#define  CELL_ANNOTATIONEDITVIEW  CGRectMake(5, 69, DEVICE_iPHONE? STYLE_CELLWIDTH_IPHONE - 20 : 280, 20) //edittext

#define  CELL_ANNOTATIONSELECTTEXT  CGRectMake(20, 69, DEVICE_iPHONE?(STYLE_CELLWIDTH_IPHONE-10):290, 20) //selecttext

#define  CELL_ANNOTATIONREPLYCONTENT  CGRectMake(25, 69, DEVICE_iPHONE? STYLE_CELLWIDTH_IPHONE - 50 : 250, 24)  //reply content
@protocol  AnnotationListCellDelegate<NSObject>

- (void)dismissKeyboard;

@end

/**@brief A cell on the annotation list. */
@interface AnnotationListCell : UITableViewCell

@property (nonatomic, retain) id delegate;
@property (nonatomic, assign) AnnotationItem *item;
@property (nonatomic, assign) NSUInteger currentlevel;
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, assign) BOOL isInputText;
@property (nonatomic, retain) UIButton *detailButton;;
@property (nonatomic, retain) AnnotationListMore *belowView;
@property (nonatomic, assign) id<AnnotationListCellDelegate>cellDelegate;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier isMenu:(BOOL)isMenu superView:superView typeOf:(int)annotType;

- (void)setEditViewHiden;

- (void)addNoteToAnnotation;
- (void)replyToAnnotation;
- (void)deleteAnnotation;
@end
