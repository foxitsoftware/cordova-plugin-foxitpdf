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
#import <UIKit/UIKit.h>
#import "../Panel/PanelController.h"
#import <FoxitRDK/FSPDFViewControl.h>
@class AnnotationPanel;
@class AnnotationItem;
@class AnnotationButton;
@class UIExtensionsManager;

@interface AnnotationUpdateTip : NSObject


@property(nonatomic,strong)NSMutableDictionary* updateTotalDic;
@property(nonatomic,assign)id annotationList;

+(AnnotationUpdateTip*)getUpdateTip;
-(void)resetUpdateData;
-(NSString*)UpdateTotalsWithCommand:(BOOL)command operationType:(NSInteger)operation annotationUuid:(NSString*)annotationuuid;
@end

typedef void (^AnnotationGotoPageHandler)(int page, NSString* annotuuid);
typedef void (^AnnotationSelectionHandler)();

/** @brief The view controller for annotation list panel. */
@interface AnnotationListViewController : UITableViewController<UIAlertViewDelegate,UITextViewDelegate,UITableViewDelegate,IPanelChangedListener, IDocEventListener>
{
    BOOL _isLoading;
    int _currentLoadingIndex;
}
@property (nonatomic, retain) UILabel *annoupdatetipLB;
@property (nonatomic, copy) AnnotationGotoPageHandler annotationGotoPageHandler;
@property (nonatomic, copy) AnnotationSelectionHandler annotationSelectionHandler;
//a common way to do for bookmark and annotation

@property (nonatomic,retain)UILabel* newslabel;
@property (nonatomic,retain)NSMutableArray* selectannos;

@property (nonatomic,strong)NSMutableArray* nodekeys;
@property (retain,nonatomic)NSMutableDictionary* totalnodes;
@property (retain,nonatomic)NSMutableArray* allpageannos;
@property (nonatomic,strong)NSMutableDictionary* annostructdic;
@property (nonatomic,strong)AnnotationItem* replyanno;
@property (nonatomic,strong)NSMutableArray* allannotations;
@property (nonatomic,assign)NSMutableArray* updateAnnotations;

//cell for progress
@property (retain, nonatomic)UITableViewCell* cellProgress;
@property (retain, nonatomic)UIActivityIndicatorView* cellProgressIndicator;
@property (retain, nonatomic)UILabel* cellProgressLabel;
@property (nonatomic, assign)BOOL isContentEditing;
@property (nonatomic,assign)UIButton* targetbutton;
@property (nonatomic,retain)AnnotationItem *editAnnoItem;
@property (nonatomic,retain)NSIndexPath *indexPath;
@property (nonatomic,assign)BOOL isShowMore;
@property (nonatomic, retain) NSIndexPath *moreIndexPath;
@property (nonatomic, assign) BOOL allCanModify;

+ (void)setDirection:(BOOL)direction;
+ (BOOL)getDirection;
+ (NSMutableArray*)getUndoAnnotationDic;
+ (NSMutableArray*)getRedoAnnotationDic;
+ (void)setUndoAnnotationDicRootAnnotation:(AnnotationItem*)rootanno ChildsAnnotations:(NSArray*)childs;
+ (void)setRedoAnnotationDicRootAnnotation:(AnnotationItem*)rootanno ChildsAnnotations:(NSArray*)childs;

- (id)initWithStyle:(UITableViewStyle)style extensionsManager:(UIExtensionsManager*)extensionsManager module:(AnnotationPanel*)module;
- (void)checkAnnotationIsUpdate:(AnnotationItem*)rootannotation;
- (void)setIsContentEditing:(BOOL)isContentEditing Button:(UIButton*)targetbutton;
- (void)getDetailReply:(AnnotationButton *)button ClickAnnotation:(AnnotationItem*)clickanno;
- (void)checkUpdateAnnotations;
- (void)getallPageAnnos;
- (void)UpdateAnnotationsTotal:(NSNotification *)notification;

- (void)selectChildsWithRootAnnotations:(NSArray*)rootannos;
- (void)reloadAnnotationsForPages:(NSMutableArray *)annotations;
- (void)loadData:(BOOL)animated;
- (void)clearData;
- (void)clearAnnotations;
- (void)resetNeedLoad;
- (void)reloadTableView;
- (void)deleteSelectannos:(NSArray*)selectannos;
- (void)ResetAnnotationArray;
- (void)updateAnnotationTotals:(NSArray*)annotations;
- (void)switchSelectAll:(BOOL)isSelect;
- (void)GetStructFromAnnotationArray:(NSArray*)annoarray WithIndex:(NSUInteger)index;
- (void)reloadAnnotationForPages:(AnnotationItem *)annotation;
- (void)reloadAnnotationForAnnotation:(NSDictionary *)annotdic;

- (void)deleteAnnotation:(AnnotationItem *)item;
- (void)replyToAnnotation:(AnnotationItem *)item;
- (void)addNoteToAnnotation:(AnnotationItem *)item withIndexPath:(NSIndexPath *)indexPath;

- (NSMutableArray *)getallAnnotations;
- (NSInteger)getAnnotationsCount;
@end
