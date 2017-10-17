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
#import <FoxitRDK/FSPDFViewControl.h>

@class UndoItem;
typedef void (^UndoBlock)(UndoItem *item);
typedef void (^RedoBlock)(UndoItem *item);

@interface UndoItem : NSObject
@property (nonatomic, copy) UndoBlock undo;
@property (nonatomic, copy) RedoBlock redo;
@property (nonatomic, assign) int pageIndex;
+ (instancetype)itemWithUndo:(UndoBlock)undo redo:(RedoBlock)redo pageIndex:(int)pageIndex;
+ (instancetype)itemByMergingUndoItemInArray:(NSArray<UndoItem *> *)undoItemArray;
@end

@protocol IAnnotHandler;

@interface UndoModifyAnnot : UndoItem
+ (instancetype)createWithOldAttributes:(FSAnnotAttributes *)oldAttributes newAttributes:(FSAnnotAttributes *)newAttributes pdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl page:(FSPDFPage *)page annotHandler:(id<IAnnotHandler>)annotHandler;
@end

@interface UndoAddAnnot : UndoItem
+ (instancetype)createWithAttributes:(FSAnnotAttributes *)attributes page:(FSPDFPage *)page annotHandler:(id<IAnnotHandler>)annotHandler;
@end

@interface UndoDeleteAnnot : UndoItem
+ (instancetype)createWithAttributes:(FSAnnotAttributes *)attributes page:(FSPDFPage *)page annotHandler:(id<IAnnotHandler>)annotHandler;
@end

