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

#import "FSAnnotAttributes.h"
#import <FoxitRDK/FSPDFViewControl.h>

@class UndoItem;
@protocol IAnnotHandler;

typedef void (^UndoBlock)(UndoItem *item);
typedef void (^RedoBlock)(UndoItem *item);

@interface UndoItem : NSObject

@property (nonatomic, copy) UndoBlock undo;
@property (nonatomic, copy) RedoBlock redo;
@property (nonatomic, assign) int pageIndex;

+ (instancetype)itemWithUndo:(UndoBlock)undo redo:(RedoBlock)redo pageIndex:(int)pageIndex;

+ (instancetype)itemByMergingItems:(NSArray<UndoItem *> *)items;

+ (instancetype)itemForUndoModifyAnnotWithOldAttributes:(FSAnnotAttributes *)oldAttributes newAttributes:(FSAnnotAttributes *)newAttributes pdfViewCtrl:(FSPDFViewCtrl *)pdfViewCtrl page:(FSPDFPage *)page annotHandler:(id<IAnnotHandler>)annotHandler;

+ (instancetype)itemForUndoAddAnnotWithAttributes:(FSAnnotAttributes *)attributes page:(FSPDFPage *)page annotHandler:(id<IAnnotHandler>)annotHandler;

+ (instancetype)itemForUndoDeleteAnnotWithAttributes:(FSAnnotAttributes *)attributes page:(FSPDFPage *)page annotHandler:(id<IAnnotHandler>)annotHandler;

@end

