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

#import "AnnotationListViewController.h"
#import "AnnotationListCell.h"
#import "AnnotationListMore.h"
#import "AnnotationPanel.h"
#import "AnnotationStruct.h"
#import "ColorUtility.h"
#import "FSUndo.h"
#import "MASConstraintMaker.h"
#import "PanelController.h"
#import "PanelHost.h"
#import "UIExtensionsManager+Private.h"
#import "UIExtensionsModulesConfig+private.h"
#import "View+MASAdditions.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface AnnotationListViewController () <IAnnotEventListener, AnnotationListCellDelegate>

@property (nonatomic, assign) BOOL isKeyboardShow;
@property (nonatomic, strong) NSOperationQueue *loadAnnotsQueue;
@property (nonatomic, assign) BOOL isShowViewList;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

- (void)refreshInterface;
- (void)setProgressInformationHidden:(NSNumber *)isHidden;
- (void)handleOOM;

@end

@implementation AnnotationListViewController {
    FSPDFViewCtrl *_pdfViewCtrl;
    UIExtensionsManager *_extensionsManager;
    FSPanelController *_panelController;
    AnnotationPanel *_annotPanel;
}

@synthesize annotationGotoPageHandler = _annotationGotoPageHandler;
@synthesize annotationSelectionHandler = _annotationSelectionHandler;
@synthesize cellProgress = _cellProgress;
@synthesize cellProgressIndicator = _cellProgressIndicator;
@synthesize cellProgressLabel = _cellProgressLabel;

- (id)initWithStyle:(UITableViewStyle)style extensionsManager:(UIExtensionsManager *)extensionsManager module:(AnnotationPanel *)annotPanel {
    self = [super initWithStyle:style];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _panelController = annotPanel.panelController;
        _annotPanel = annotPanel;
        _isShowViewList = NO;
        self.selectannos = [[NSMutableArray alloc] init];
        self.annostructdic = [[NSMutableDictionary alloc] init];
        self.allpageannos = [[NSMutableArray alloc] init];
        self.totalnodes = [[NSMutableDictionary alloc] init];
        self.nodekeys = [[NSMutableArray alloc] init];
        self.allannotations = [[NSMutableArray alloc] init];
        self.updateAnnotations = [[NSMutableArray alloc] init];
        self.cellProgress = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellProgress"];
        _cellProgress.backgroundColor = [UIColor clearColor];
        self.cellProgress.backgroundView = [[UIView alloc] init];
        _cellProgress.selectionStyle = UITableViewCellSelectionStyleNone;
        self.cellProgressLabel = [[UILabel alloc] init];
        _cellProgressLabel.backgroundColor = [UIColor clearColor];
        _cellProgressLabel.frame = CGRectMake(0, 0, 200, 20);
        _cellProgressLabel.font = [UIFont systemFontOfSize:17.0];
        _cellProgressLabel.textColor = DEVICE_iPHONE ? [UIColor whiteColor] : [UIColor darkTextColor];
        self.cellProgressIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _cellProgressIndicator.frame = CGRectMake(0, 0, 20, 20);
        [_cellProgress.contentView addSubview:_cellProgressIndicator];
        [_cellProgress.contentView addSubview:_cellProgressLabel];
        _isLoading = NO;
        _currentLoadingIndex = -1;
        _annotationGotoPageHandler = nil;
        _annotationSelectionHandler = nil;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
        [_extensionsManager registerAnnotEventListener:self];
        [annotPanel.panelController registerPanelChangedListener:self];
        [_pdfViewCtrl registerDocEventListener:self];
        self.moreIndexPath = nil;
        self.loadAnnotsQueue = nil;
        self.isClearingAllAnnots = NO;
        self.tapGesture = nil;
    }
    return self;
}

#pragma mark - IDocEventListener
- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
}

- (void)onDocWillClose:(FSPDFDoc *)document {
    [self hideCellEditView];

    [self.loadAnnotsQueue cancelAllOperations];
    [self.loadAnnotsQueue waitUntilAllOperationsAreFinished];
    [_annostructdic removeAllObjects];
    [_allpageannos removeAllObjects];
    [_totalnodes removeAllObjects];
    [_nodekeys removeAllObjects];
    [self.selectannos removeAllObjects];
    [self.allannotations removeAllObjects];
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
}

- (void)onDocWillSave:(FSPDFDoc *)document {
}

- (void)onDocSaved:(FSPDFDoc *)document error:(int)error {
}

#pragma mark - IPanelChangedListener
- (void)onPanelChanged:(BOOL)isHidden {
    if (isHidden) {
        [self hideCellEditView];
    }

    if (isHidden) {
        AnnotationListCell *cell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
        [edittextview resignFirstResponder];
    }

    [self endEditing];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    Block_release(_annotationGotoPageHandler);
    Block_release(_annotationSelectionHandler);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshInterface];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void)UpdateAnnotationsTotal:(NSNotification *)notification {
    NSString *updatetip = [notification object];
    if (updatetip.length != 0) {
        self.annoupdatetipLB.hidden = NO;
        self.annoupdatetipLB.text = updatetip;
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(20);
            make.left.equalTo(self.tableView.superview.mas_left);
            make.right.equalTo(self.tableView.superview.mas_right);
            make.bottom.equalTo(self.tableView.superview.mas_bottom);
        }];
    } else {
        self.annoupdatetipLB.hidden = YES;
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.left.equalTo(self.tableView.superview.mas_left);
            make.right.equalTo(self.tableView.superview.mas_right);
            make.bottom.equalTo(self.tableView.superview.mas_bottom);
        }];
    }
}

- (void)deviceOrientationChange {
    UIDeviceOrientation currentOri = [[UIDevice currentDevice] orientation];

    if (UIDeviceOrientationIsLandscape(currentOri)) {
        [self.tableView reloadData];
        self.isShowMore = FALSE;
    } else if (UIInterfaceOrientationIsPortrait(currentOri) && currentOri != UIDeviceOrientationPortraitUpsideDown) {
        [self.tableView reloadData];
        self.isShowMore = FALSE;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIENTATIONCHANGED object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.tableView selector:@selector(reloadData) object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation));
}

- (void)checkAnnotationIsUpdate:(AnnotationItem *)rootannotation {
    BOOL searchupdate = NO;

    NSArray *childannotations = [AnnotationStruct getAllChildNodesWithSuperAnnotation:rootannotation annoStruct:self.annostructdic];

    for (AnnotationItem *checkupdateanno in childannotations) {
        if (checkupdateanno.isUpdate) {
            searchupdate = YES;
            break;
        }
    }

    if (!searchupdate && !rootannotation.isUpdate) {
        rootannotation.isShowUpdateTip = NO;
    }
}

- (void)checkUpdateAnnotations {
    for (int i = 0; i < _updateAnnotations.count; i++) {
        AnnotationItem *annotation = [_updateAnnotations objectAtIndex:i];
        AnnotationItem *rootanno = nil;
        [AnnotationStruct getRootAnnotation:annotation TargetAnnotation:&rootanno AnnoArray:_updateAnnotations];
        if (rootanno) {
            [self performSelector:@selector(addAnnotation:) withObject:rootanno afterDelay:0.1];
            [_updateAnnotations removeObject:rootanno];
        } else {
            [self performSelector:@selector(addAnnotation:) withObject:annotation afterDelay:0.1];
            [_updateAnnotations removeObject:annotation];
        }
        i = -1;
    }
}

- (void)addAnnotation:(AnnotationItem *)annotation {
    [self addNoteAnnotation:annotation];
}

- (void)ResetAnnotationArray {
    [_annostructdic removeAllObjects];
    [_allpageannos removeAllObjects];
    [_totalnodes removeAllObjects];
    [_nodekeys removeAllObjects];
    [self.selectannos removeAllObjects];
    [self.allannotations removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.tableView reloadData];

    });
}

#pragma mark - IAnnotEventListener

- (void)onAnnotAdded:(FSPDFPage *)page annot:(FSAnnot *)annot {
    if (annot.type == e_annotStrikeOut && [Utility isReplaceText:(FSStrikeOut *) annot]) {
        return;
    }
    AnnotationItem *annoItem = [[AnnotationItem alloc] init];
    annoItem.annot = annot;
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                           annoItem, @"Annotation",
                                           @(AnnotationOperation_Add), @"Operation",
                                           nil];
    [self reloadAnnotationForAnnotation:dict];
}

- (void)onAnnotWillDelete:(FSPDFPage *)page annot:(FSAnnot *)annot {
    //If currently is clearing all the annotations, then we don't reload the data here for better performance.
    if (_isClearingAllAnnots)
        return;
    if (annot.type == e_annotStrikeOut && [Utility isReplaceText:(FSStrikeOut *) annot]) {
        return;
    }
    AnnotationItem *annoItem = [[AnnotationItem alloc] init];
    annoItem.annot = annot;
    if (!annot.canModify) {
        self.allCanModify = YES;
    }

    [self reloadAnnotationsForPages:[NSMutableArray arrayWithObjects:annoItem, nil]];
}

- (void)onAnnotModified:(FSPDFPage *)page annot:(FSAnnot *)annot {
    if (annot.type == e_annotStrikeOut && [Utility isReplaceText:(FSStrikeOut *) annot]) {
        return;
    }
    AnnotationItem *annoItem = [[AnnotationItem alloc] init];
    annoItem.annot = annot;
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                           annoItem, @"Annotation",
                                           @(AnnotationOperation_Modify), @"Operation",
                                           nil];
    [self reloadAnnotationForAnnotation:dict];
}

- (void)onCurrentAnnotChanged:(FSAnnot *)lastAnnot currentAnnot:(FSAnnot *)currentAnnot {
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.allpageannos.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int rowtotals = 0;
    NSArray *nodearray = [self.allpageannos objectAtIndex:section];
    for (AnnotationItem *tempnodeanno in nodearray) {
        rowtotals += (int) [[self.totalnodes objectForKey:tempnodeanno.annot.uuidWithPageIndex] count];
    }
    return rowtotals;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.allpageannos.count == 0 || !self.allpageannos) {
        UIView *view = [[UIView alloc] init];
        return view;
    }
    AnnotationItem *annotation = [[self.allpageannos objectAtIndex:section] objectAtIndex:0];
    UIView *subView = [[UIView alloc] init];
    subView.backgroundColor = [UIColor colorWithRed:204.f / 255.f green:204.f / 255.f blue:204.f / 255.f alpha:1];
    UILabel *labelSection = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, tableView.bounds.size.width - 20, 25)];
    labelSection.font = [UIFont systemFontOfSize:13];
    labelSection.backgroundColor = [UIColor clearColor];
    labelSection.textColor = [UIColor blackColor];

    UILabel *labelTotal = [[UILabel alloc] initWithFrame:CGRectMake(tableView.bounds.size.width - 120, 0, 100, 25)];
    labelTotal.font = [UIFont systemFontOfSize:13];
    labelTotal.textAlignment = NSTextAlignmentRight;
    labelTotal.backgroundColor = [UIColor clearColor];
    labelTotal.textColor = [UIColor colorWithRed:37.f / 255.f green:157.f / 255.f blue:214.f / 255.f alpha:1];
    labelTotal.text = [NSString stringWithFormat:@"%d", (int) [[self.allpageannos objectAtIndex:section] count]];

    NSString *sectionTitle = [NSString stringWithFormat:@"%@ %d", FSLocalizedString(@"kPage"), annotation.annot.pageIndex + 1];

    labelSection.text = sectionTitle;
    [subView addSubview:labelSection];
    [subView addSubview:labelTotal];
    return subView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (void)setIsShowMore:(BOOL)isShowMore {
    _isShowMore = isShowMore;
}

- (AnnotationItem *)getAnnotationItemAtIndexPath:(NSIndexPath *)indexPath {
    AnnotationItem *annoItem = nil;
    if (indexPath.section >= self.allpageannos.count) {
        return nil;
    }
    NSArray *nodearray = [self.allpageannos objectAtIndex:[indexPath section]];
    NSUInteger annotationindex = 0;

    for (AnnotationItem *tempnodeanno in nodearray) {
        if (annoItem)
            break;

        for (AnnotationItem *selectanno in [self.totalnodes objectForKey:tempnodeanno.annot.uuidWithPageIndex]) {
            if (annotationindex == [indexPath row]) {
                annoItem = selectanno;

                break;
            }

            annotationindex++;
        }
    }
    return annoItem;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"annotationCellIdentifier";

    if (self.allpageannos.count == 0 || !self.allpageannos || indexPath.section >= self.allpageannos.count) {
        AnnotationListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[AnnotationListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier isMenu:NO];
        }
        return cell;
    }

    AnnotationItem *annoItem = [self getAnnotationItemAtIndexPath:indexPath];
    if (!annoItem) {
        AnnotationListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[AnnotationListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier isMenu:NO];
        }
        return cell;
    }
    if (!annoItem.annot.canModify) {
        if (self.allCanModify) {
            self.allCanModify = NO;
        }
    }
    AnnotationListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[AnnotationListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier isMenu:NO];
    }
    cell.cellDelegate = self;

    UIImageView *annoimageView = (UIImageView *) [cell.contentView viewWithTag:99];
    AnnotationButton *annolevelimageView = (AnnotationButton *) [cell.contentView viewWithTag:100];
    UILabel *labelAuthor = (UILabel *) [cell.contentView viewWithTag:102];
    UILabel *labelDate = (UILabel *) [cell.contentView viewWithTag:103];
    UILabel *labelContents = (UILabel *) [cell.contentView viewWithTag:104];
    labelContents.hidden = NO;
    labelContents.text = @"";
    UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
    edittextview.returnKeyType = UIReturnKeyDone;
    UIImageView *annoupdatetip = (UIImageView *) [cell.contentView viewWithTag:108];
    UIImageView *annouprepltip = (UIImageView *) [cell.contentView viewWithTag:109];
    //        cell.indexPath = indexPath;
    cell.item = annoItem;
    annoimageView.image = [UIImage imageNamed:[AnnotationStruct annotationImageName:annoItem]];
    annoItem.currentlevelbutton = annolevelimageView;
    annoItem.annosection = indexPath.section;
    annoItem.annorow = indexPath.row;
    if (annoItem.isSecondLevel) {
        annolevelimageView.hidden = [self isContentEditing] ? YES : NO;
        if ([[self.annostructdic objectForKey:annoItem.annot.uuidWithPageIndex] count] > 0) {
            annolevelimageView.hidden = NO;
            if (annoItem.currentlevelshow) {
                annolevelimageView.selected = YES;
            } else {
                annolevelimageView.selected = NO;
            }
        } else {
            annolevelimageView.hidden = YES;
            annolevelimageView.selected = YES;
        }

        if (annoItem.annot.replyTo == nil) {
            annolevelimageView.hidden = YES;
        }

    } else {
        annolevelimageView.hidden = YES;
    }

    annolevelimageView.buttonannotag = annoItem;
    annolevelimageView.currentsection = indexPath.section;
    annolevelimageView.currentrow = indexPath.row;

    [annolevelimageView addTarget:self action:@selector(getDetailButton:) forControlEvents:UIControlEventTouchUpInside];

    labelAuthor.text = annoItem.annot.author;

    if (annoItem.annot.replyTo != nil) {
        labelAuthor.text = [NSString stringWithFormat:@"%@ to %@", annoItem.annot.author ? annoItem.annot.author : @"", annoItem.replytoauthor ? annoItem.replytoauthor : @""];
    }
    labelDate.text = [Utility displayDateInYMDHM:annoItem.annot.modifiedDate];

    NSString *contents = [annoItem.annot.contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (contents == nil || contents.length == 0) {
        labelContents.hidden = YES;

    } else {
        labelContents.hidden = NO;

        labelContents.text = contents;
        CGSize contentSize = CGSizeZero;
        labelContents.numberOfLines = 0;

        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetHeight(_pdfViewCtrl.bounds) - 40 : 300 - 40, 2000)];

            [labelContents mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(labelContents.superview.mas_top).offset(69);
                make.left.equalTo(labelContents.superview.mas_left).offset(20);
                make.right.equalTo(labelContents.superview.mas_right).offset(-20);
            }];
            [edittextview mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(labelContents.superview.mas_top).offset(69);
                make.left.equalTo(labelContents.superview.mas_left).offset(20);
                make.right.equalTo(labelContents.superview.mas_right).offset(-20);
                make.height.mas_equalTo(contentSize.height);
            }];
        } else {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetWidth(_pdfViewCtrl.bounds) - 40 : 300 - 40, 2000)];

            [labelContents mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(labelContents.superview.mas_top).offset(69);
                make.left.equalTo(labelContents.superview.mas_left).offset(20);
                make.right.equalTo(labelContents.superview.mas_right).offset(-20);
            }];
            [edittextview mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(labelContents.superview.mas_top).offset(69);
                make.left.equalTo(labelContents.superview.mas_left).offset(20);
                make.right.equalTo(labelContents.superview.mas_right).offset(-20);
                make.height.mas_equalTo(contentSize.height);
            }];
        }
    }

    if (annolevelimageView.buttonannotag.annot.replyTo != nil) {
        annoimageView.hidden = YES;
        annoupdatetip.hidden = YES;
        annouprepltip.hidden = NO;
        CGSize contentSize = CGSizeZero;
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetHeight(_pdfViewCtrl.bounds) - 40 : 300 - 40, 2000)];
        } else {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetWidth(_pdfViewCtrl.bounds) - 40 : 300 - 40, 2000)];
        }
        [labelContents mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(labelContents.superview.mas_top).offset(69);
            make.left.equalTo(labelContents.superview.mas_left).offset(25);
            make.right.equalTo(labelContents.superview.mas_right).offset(-10);
        }];
        [edittextview mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(edittextview.superview.mas_top).offset(69);
            make.left.equalTo(edittextview.superview.mas_left).offset(10);
            make.right.equalTo(edittextview.superview.mas_right).offset(-10);
            make.height.mas_equalTo(contentSize.height);
        }];

    } else {
        annoimageView.hidden = NO;
        [labelAuthor setTextAlignment:NSTextAlignmentLeft];
        if (annolevelimageView.buttonannotag.isShowUpdateTip) {
            annoupdatetip.hidden = NO;
        } else {
            annoupdatetip.hidden = YES;
        }
        annouprepltip.hidden = YES;
    }

    if (annolevelimageView.buttonannotag.isUpdate) {
        labelContents.textColor = [UIColor colorWithRed:252 / 255.0f green:130 / 255.0f blue:0 / 255.0f alpha:1.0];
    } else {
        [labelContents setTextColor:[UIColor darkGrayColor]];
    }
    if (cell.isInputText) {
        edittextview.hidden = NO;
        labelContents.hidden = YES;
    } else {
        edittextview.hidden = YES;
        if ((contents == nil || contents.length == 0)) {
            labelContents.hidden = YES;
        } else {
            labelContents.hidden = NO;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    NSMutableArray *nodeannos = [NSMutableArray array];

    NSArray *nodes = [self.allpageannos objectAtIndex:indexPath.section];

    for (AnnotationItem *annotation in nodes) {
        [nodeannos addObjectsFromArray:[self.totalnodes objectForKey:annotation.annot.uuidWithPageIndex]];
    }

    AnnotationItem *annotationItem = [nodeannos objectAtIndex:indexPath.row];

    if (self.isContentEditing) {
        annotationItem.isSelected = !annotationItem.isSelected;

        if (![self.selectannos containsObject:annotationItem] && annotationItem.isSelected == YES) {
            [self.selectannos addObject:annotationItem];
        }
        if (annotationItem.isSelected == NO && [self.selectannos containsObject:annotationItem]) {
            [self.selectannos removeObject:annotationItem];
        }

        if (self.annotationSelectionHandler) {
            self.annotationSelectionHandler();
        }

        UITableViewCell *selectcell = (UITableViewCell *) [tableView cellForRowAtIndexPath:indexPath];
        UIImageView *selectimageview = (UIImageView *) [selectcell.contentView viewWithTag:101];
        selectimageview.image = annotationItem.isSelected ? [UIImage imageNamed:@"common_redio_selected"] : [UIImage imageNamed:@"common_redio_blank"];

    } else {
        if (self.annotationGotoPageHandler && annotationItem.annot.replyTo == nil) {
            [self performSelector:@selector(afterDelayGotoPage:) withObject:annotationItem afterDelay:0.2];
        }
    }

    if (annotationItem.isUpdate) {
        annotationItem.isUpdate = NO;

        [self checkAnnotationIsUpdate:annotationItem.rootannotation];

        UITableViewCell *selectcell = (UITableViewCell *) [tableView cellForRowAtIndexPath:indexPath];

        UILabel *labelContents = (UILabel *) [selectcell.contentView viewWithTag:104];

        labelContents.textColor = [UIColor colorWithHexString:@"333333"];

        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)afterDelayGotoPage:(AnnotationItem *)annotationItem {
    _panelController.isHidden = YES;
    [_pdfViewCtrl gotoPage:annotationItem.annot.pageIndex animated:YES];
    [self performSelector:@selector(setCurrentAnnotionItem:) withObject:annotationItem afterDelay:0.8];
}

- (void)setCurrentAnnotionItem:(AnnotationItem *)annotationItem {
    if ([_pdfViewCtrl getPageLayoutMode] != PDF_LAYOUT_MODE_REFLOW) {
        [_extensionsManager setCurrentAnnot:annotationItem.annot];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    AnnotationItem *annotationItem = nil;
    if (self.allpageannos.count == 0 || !self.allpageannos || indexPath.section >= self.allpageannos.count) {
        return 0;
    }
    NSArray *nodearray = [self.allpageannos objectAtIndex:[indexPath section]];

    NSUInteger annotationindex = 0;

    for (AnnotationItem *tempnodeanno in nodearray) {
        if (annotationItem)
            break;

        for (AnnotationItem *selectanno in self.totalnodes[tempnodeanno.annot.uuidWithPageIndex]) {
            if (annotationindex == [indexPath row]) {
                annotationItem = selectanno;

                break;
            }

            annotationindex++;
        }
    }

    float cellHeight = 68;

    CGSize contentSize = CGSizeMake(0, 0);
    NSString *contents = nil;

    if ([annotationItem.annot.contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length != 0) {
        contents = [annotationItem.annot.contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    if (contents == nil || contents.length == 0) {
        if (self.indexPath && self.indexPath.section == indexPath.section && self.indexPath.row == indexPath.row) {
            contentSize.height = 25;
        }
    } else {
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetHeight(_pdfViewCtrl.bounds) - 40 : 300 - 40, 2000)];
        } else {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetWidth(_pdfViewCtrl.bounds) - 40 : 300 - 40, 2000)];
        }

        if (contentSize.height < 25) {
            contentSize.height = 25;
        } else {
            contentSize.height += 5;
        }
    }
    return cellHeight + contentSize.height;
}

#pragma mark <AnnotationListCellDelegate>

- (void)annotationListCellWillShowEditView:(AnnotationListCell *)cell {
    [self hideCellEditView];
}

- (void)annotationListCellDidShowEditView:(AnnotationListCell *)cell {
    self.isShowMore = YES;
    self.moreIndexPath = [self.tableView indexPathForCell:cell];
    if (!self.tapGesture) {
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self.view addGestureRecognizer:self.tapGesture];
    }
    self.tapGesture.enabled = YES;
}

- (BOOL)annotationListCellCanEdit:(AnnotationListCell *)cell {
    AnnotationItem *item = cell.item; // ?: [self getAnnotationItemAtIndexPath:[self.tableView indexPathForCell:cell]];
    assert(item);
    return item.annot.canModify && item.annot.type != e_annotFreeText;
}

- (BOOL)annotationListCellCanReply:(AnnotationListCell *)cell {
    AnnotationItem *item = cell.item; // ?: [self getAnnotationItemAtIndexPath:[self.tableView indexPathForCell:cell]];
    assert(item);
    return item.annot.canReply;
}

- (BOOL)annotationListCellCanDelete:(AnnotationListCell *)cell {
    AnnotationItem *item = cell.item; // ?: [self getAnnotationItemAtIndexPath:[self.tableView indexPathForCell:cell]];
    assert(item);
    return item.annot.canModify;
}

- (void)annotationListCellEdit:(AnnotationListCell *)cell {
    [self hideCellEditView];
    [self addNoteToAnnotation:cell.item withIndexPath:[self.tableView indexPathForCell:cell]];
}

- (void)annotationListCellReply:(AnnotationListCell *)cell {
    [self hideCellEditView];
    [self replyToAnnotation:cell.item];
}

- (void)annotationListCellDelete:(AnnotationListCell *)cell {
    [self hideCellEditView];
    [self deleteAnnotation:cell.item];
}

#pragma mark

- (void)handleTap:(UITapGestureRecognizer *)tapGesture {
    assert(self.isShowMore);
    assert(self.moreIndexPath);
    [self hideCellEditView];
}

- (void)hideCellEditView {
    if (self.isShowMore) {
        assert(self.moreIndexPath);
        AnnotationListCell *cell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.moreIndexPath];
        [cell setEditViewHidden:YES];
        self.isShowMore = NO;
        self.moreIndexPath = nil;
        self.tapGesture.enabled = NO;
    }
}

#pragma mark AnnoStrtct

- (void)getDetailButton:(AnnotationButton *)button {
    [self getDetailReply:nil ClickAnnotation:button.buttonannotag];
    button.selected = !button.selected;
}

- (void)getDetailReply:(AnnotationButton *)button ClickAnnotation:(AnnotationItem *)clickanno {
    NSUInteger currentsection = 0;
    NSUInteger currentrow = 0;
    AnnotationItem *currentanno = nil;
    if (button) {
        currentanno = button.buttonannotag;

    } else {
        currentanno = clickanno;
    }

    currentsection = clickanno.rootannotation.annosection;

    NSArray *currentpagenode = [self.allpageannos objectAtIndex:currentsection];

    NSMutableArray *currentlevel = [NSMutableArray array];

    for (AnnotationItem *rootnode in currentpagenode) {
        [currentlevel addObjectsFromArray:[self.totalnodes objectForKey:rootnode.annot.uuidWithPageIndex]];
    }

    currentrow = [currentlevel indexOfObject:clickanno];

    NSMutableArray *currentarray = [self checkIndexFromAnnotation:currentanno.rootannotation Annoarray:currentpagenode];

    NSMutableArray *addannoarray = [self.annostructdic objectForKey:currentanno.annot.uuidWithPageIndex];

    [addannoarray makeObjectsPerformSelector:@selector(addCurrentlevel:) withObject:[NSNumber numberWithInteger:(currentanno.annot.replyTo == nil ? (currentanno.currentlevel + 1) : (currentanno.currentlevel))]];

    [addannoarray makeObjectsPerformSelector:@selector(setReplytoauthor:) withObject:currentanno.annot.author];

    [addannoarray makeObjectsPerformSelector:@selector(setcurrentlevelshow:) withObject:[NSNumber numberWithBool:NO]];

    if (currentanno.annot.replyTo == nil) {
        [addannoarray makeObjectsPerformSelector:@selector(setSecondLevel:) withObject:[NSNumber numberWithBool:YES]];
    }

    if (currentanno.annot.type != e_annotNote) {
        [addannoarray makeObjectsPerformSelector:@selector(setRootannotation:) withObject:currentanno];

    } else {
        [addannoarray makeObjectsPerformSelector:@selector(setRootannotation:) withObject:currentanno.rootannotation];
    }

    if (!currentanno.currentlevelshow) {
        NSUInteger insertrowindex = [currentarray indexOfObject:currentanno];

        [currentarray insertObjects:addannoarray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertrowindex + 1, addannoarray.count)]];

        if (self.isShowViewList) {
            NSMutableArray *arCells = [NSMutableArray array];

            for (int i = 0; i < addannoarray.count; i++) {
                currentrow = currentrow + 1;
                [arCells addObject:[NSIndexPath indexPathForRow:currentrow inSection:currentsection]];
            }

            if (arCells.count > 0)
                [self.tableView insertRowsAtIndexPaths:arCells withRowAnimation:UITableViewRowAnimationNone];
        }

        if (currentanno.annot.replyTo != nil) {
            for (AnnotationItem *sendOpen in addannoarray) {
                [self getDetailReply:nil ClickAnnotation:sendOpen];
            }
        }
        if (currentanno.isSecondLevel) {
            currentanno.currentlevelshow = YES;
        }

    } else {
        currentanno.currentlevelshow = NO;

        NSMutableArray *deletearray = [NSMutableArray array];

        [self getAboutAnnotatios:currentanno Annoarray:currentarray deleteArray:deletearray];

        NSArray *removeannos = deletearray;

        NSUInteger insertrowindex = [currentarray indexOfObject:currentanno];

        NSMutableArray *arCells = [NSMutableArray array];

        for (int i = 0; i < removeannos.count; i++) {
            currentrow = currentrow + 1;
            [arCells addObject:[NSIndexPath indexPathForRow:currentrow inSection:currentsection]];
        }

        [currentarray removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertrowindex + 1, removeannos.count)]];

        [self.tableView deleteRowsAtIndexPaths:arCells withRowAnimation:UITableViewRowAnimationBottom];
    }
}

- (NSMutableArray *)checkIndexFromAnnotation:(AnnotationItem *)searchanno Annoarray:(NSArray *)annoarray {
    NSMutableArray *nodearray = nil;

    BOOL searchannoFromNode = NO;

    for (int i = 0; i < annoarray.count; i++) {
        nodearray = [self.totalnodes objectForKey:[[annoarray objectAtIndex:i] annot].uuidWithPageIndex];

        if ([nodearray containsObject:searchanno]) {
            searchannoFromNode = YES;
            break;
        }
    }
    if (searchannoFromNode) {
        return nodearray;
    }

    return nil;
}

- (void)getAboutAnnotatios:(AnnotationItem *)searchanno Annoarray:(NSArray *)annoarray deleteArray:(NSMutableArray *)deletearray {
    NSArray *searcharray = [AnnotationStruct getAllChildNodesWithSuperAnnotation:searchanno annoStruct:self.annostructdic];

    for (AnnotationItem *annannotationo in searcharray) {
        if ([annoarray containsObject:annannotationo]) {
            [deletearray addObject:annannotationo];
        }
    }
}

- (void)GetStructFromAnnotationArray:(NSArray *)annoarray WithIndex:(NSUInteger)index {
    NSMutableArray *temppageannnos = [NSMutableArray array];

    NSMutableArray *noteannos = [NSMutableArray array];

    for (AnnotationItem *annotation in annoarray) {
        if (annotation.annot.replyTo == nil) {
            annotation.currentlevel = 1;
            annotation.annosection = [self.allpageannos count];
            annotation.isSecondLevel = YES;
            annotation.rootannotation = annotation;
            [temppageannnos addObject:annotation];
        } else {
            [noteannos addObject:annotation];
        }
    }
    [self.annostructdic addEntriesFromDictionary:[AnnotationStruct getAnnotationStructWithAnnos:annoarray]];
    [self.allpageannos addObject:temppageannnos];

    for (AnnotationItem *annotation in temppageannnos) {
        NSMutableArray *nodearray = [NSMutableArray array];

        [nodearray addObject:annotation];

        [self.totalnodes setObject:nodearray forKey:annotation.annot.uuidWithPageIndex];

        [self.nodekeys addObject:[annotation description]];
    }

    for (AnnotationItem *rootnodeanno in temppageannnos) {
        for (AnnotationItem *childannotation in [AnnotationStruct getAllChildNodesWithSuperAnnotation:rootnodeanno annoStruct:self.annostructdic]) {
            childannotation.rootannotation = rootnodeanno;
        }
    }
}

#pragma mark - methods

- (void)setIsContentEditing:(BOOL)isContentEditing Button:(UIButton *)targetbutton {
    if (_isContentEditing != isContentEditing) {
        self.targetbutton = targetbutton;

        _isContentEditing = isContentEditing;
        if (!_isContentEditing) {
            [self switchSelectAll:NO];

        } else {
            [self getallPageAnnos];
            [self switchSelectAll:NO];
            dispatch_async(dispatch_get_main_queue(), ^{

                [self.tableView reloadData];

            });
        }
    }
}

- (void)getallPageAnnos {
    [self.selectannos removeAllObjects];
    [self.selectannos addObjectsFromArray:self.allannotations];
}

- (void)handleOOM {
}

- (NSArray<AnnotationItem *> *)getAnnotationItemsForPageAtIndex:(int)pageIndex {
    FSPDFPage *page = nil;
    @try {
        page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    }
    @catch (NSException *exception) {
        return nil;
    }
    NSArray *array = [Utility getAnnotsInPage:page
                               predicateBlock:^BOOL(FSAnnot *_Nonnull annot) {
                                   if (![_extensionsManager.modulesConfig canInteractWithAnnot:annot]) {
                                       return NO;
                                   }
                                   FSAnnotType type = [annot getType];
                                   if (type == e_annotWidget || type == e_annotSound || type == e_annotMovie) {
                                       return NO;
                                   }
                                   // 'replace text' consist of caret and strikeout annotation, add former only
                                   if ((type == e_annotStrikeOut && [Utility isReplaceText:(FSStrikeOut *) annot])) {
                                       return NO;
                                   }
                                   //State annot is not supported.
                                   if (type == e_annotNote && [(FSNote *) annot getState] != 0)
                                       return NO;

                                   if (type == e_annotFreeText) {
                                       NSString *intent = [((FSMarkup *) annot) getIntent];
                                       if (intent && [intent caseInsensitiveCompare:@"FreeTextCallout"] == NSOrderedSame) {
                                           return NO;
                                       }
                                   }
                                   if ((annot.flags & e_annotFlagHidden) != 0)
                                       return NO;
                                   return YES;
                               }];
    NSMutableArray<AnnotationItem *> *itemsArray = [NSMutableArray<AnnotationItem *> arrayWithCapacity:array.count];
    for (FSAnnot *annot in array) {
        AnnotationItem *annoItem = [[AnnotationItem alloc] init];
        annoItem.annot = annot;
        [itemsArray addObject:annoItem];
    }
    return itemsArray;
}

- (void)loadAnnotationsForPageAtIndex:(int)pageIndex {
    NSArray<AnnotationItem *> *itemsArray = [self getAnnotationItemsForPageAtIndex:pageIndex];
    if (itemsArray.count == 0) {
        return;
    }
    [_allannotations addObjectsFromArray:itemsArray];
    [self GetStructFromAnnotationArray:itemsArray WithIndex:pageIndex];
}

- (void)cancelLoadAnnotations {
    [self.loadAnnotsQueue cancelAllOperations];
    typeof(self) __weak weakSelf = self;
    [self.loadAnnotsQueue addOperationWithBlock:^{
        [weakSelf ResetAnnotationArray];
    }];
    [self.loadAnnotsQueue waitUntilAllOperationsAreFinished];
}

- (void)loadData:(BOOL)animated {
    @synchronized(self) {
        [_annostructdic removeAllObjects];
        [_allpageannos removeAllObjects];
        [_totalnodes removeAllObjects];
        [_nodekeys removeAllObjects];
        [self.selectannos removeAllObjects];
        [self.allannotations removeAllObjects];
        [self refreshInterface];

        [[NSNotificationCenter defaultCenter] postNotificationName:ANNOLIST_UPDATETOTAL object:@""];

        [self setProgressInformationHidden:nil];
        [self performSelector:@selector(setProgressInformationHidden:) withObject:[NSNumber numberWithBool:NO] afterDelay:1.0];

        self.isShowViewList = NO;
        if (!self.loadAnnotsQueue) {
            self.loadAnnotsQueue = [[NSOperationQueue alloc] init];
            self.loadAnnotsQueue.name = @"load annotations";
            self.loadAnnotsQueue.maxConcurrentOperationCount = 1;
        } else {
            [self cancelLoadAnnotations];
        }
        NSBlockOperation *op = [[NSBlockOperation alloc] init];
        NSBlockOperation *__weak weakOp = op;
        typeof(self) __weak weakSelf = self;
        [op addExecutionBlock:^{
            @autoreleasepool {
                for (int i = 0; i < [_pdfViewCtrl.currentDoc getPageCount]; i++) {
                    if (weakOp.isCancelled) {
                        return;
                    }
                    [weakSelf loadAnnotationsForPageAtIndex:i];
                }
            }
            if (weakOp.isCancelled) {
                return;
            }
            [weakSelf reloadTableView];
        }];
        [self.loadAnnotsQueue addOperation:op];
    }
}

- (void)reloadTableView {
    if (self.isShowViewList) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSArray *pageannos in self.allpageannos) {
            for (AnnotationItem *selectanno in pageannos) {
                if (!selectanno.currentlevelshow && selectanno.annot.replyTo == nil) {
                    [self getDetailReply:nil ClickAnnotation:selectanno];
                }
            }
        }

        [self.tableView reloadData];
        self.isShowViewList = YES;

    });
}

- (void)clearData {
    [self ResetAnnotationArray];
    [self refreshInterface];
}

- (void)clearAnnotations {
    [self hideCellEditView];

    [self.loadAnnotsQueue waitUntilAllOperationsAreFinished];

    NSMutableArray *tempAnnotations = [NSMutableArray arrayWithArray:self.allannotations];

    [self endEditing];

    _isClearingAllAnnots = YES;
    for (int i = 0; i < [tempAnnotations count]; i++) {
        AnnotationItem *item = [tempAnnotations objectAtIndex:i];
        if (!item.isDeleted) {
            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:item.annot];
            [annotHandler removeAnnot:item.annot addUndo:(item.rootannotation == item)]; // don't add undo for child annotation when clearing
            item.isDeleted = YES;
        }
    }
    _isClearingAllAnnots = NO;
    [self clearData];

    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
}

- (void)resetNeedLoad {
    _isLoading = NO;
}

- (void)selectChildsWithRootAnnotations:(NSArray *)rootannos {
    for (AnnotationItem *rootannotation in rootannos) {
        for (AnnotationItem *childanno in [AnnotationStruct getAllChildNodesWithSuperAnnotation:rootannotation annoStruct:self.annostructdic]) {
            childanno.isSelected = YES;
        }
    }

    [self getallPageAnnos];

    dispatch_async(dispatch_get_main_queue(), ^{

        [self.tableView reloadData];

    });
}

- (void)switchSelectAll:(BOOL)isSelect {
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.tableView reloadData];

    });

    [self.selectannos removeAllObjects];

    for (AnnotationItem *selectanno in self.allannotations) {
        selectanno.isSelected = isSelect;
    }
    [self.selectannos addObjectsFromArray:self.allannotations];

    if (self.annotationSelectionHandler) {
        self.annotationSelectionHandler();
    }
}

#pragma mark AddAnnotationAndUpdteAnnotation

- (void)updateAnnotationTotals:(NSArray *)annotations {
    for (AnnotationItem *updateanno in annotations) {
        if (updateanno.isUpdate) {
            updateanno.isUpdate = NO;
        }

        NSArray *childsanno = [AnnotationStruct getAllChildNodesWithSuperAnnotation:updateanno annoStruct:self.annostructdic];

        for (AnnotationItem *childanno in childsanno) {
            if (childanno.isUpdate) {
                childanno.isUpdate = NO;
            }
        }
    }
}

//delete annotations
- (void)reloadAnnotationsForPages:(NSMutableArray *)annotations {
    [self updateAnnotationTotals:annotations];

    NSMutableSet *deletetotal = [NSMutableSet set];

    for (AnnotationItem *selection in annotations) {
        [deletetotal addObjectsFromArray:[AnnotationStruct getAllChildNodesWithSuperAnnotation:selection annoStruct:self.annostructdic]];
        [deletetotal addObject:selection];
    }

    NSMutableSet *readydelete = [NSMutableSet set];

    NSMutableArray *allnodes = [NSMutableArray array];

    [allnodes addObjectsFromArray:annotations];

    for (AnnotationItem *annotation in allnodes) {
        [readydelete addObject:annotation];
        [readydelete addObjectsFromArray:[AnnotationStruct getAllChildNodesWithSuperAnnotation:annotation annoStruct:self.annostructdic]];
    }

    for (AnnotationItem *deleteanno in readydelete) {
        AnnotationItem *replytoanno = nil;

        AnnotationItem *readydeleteannotation = nil;

        for (AnnotationItem *annotation in self.allannotations) {
            if (replytoanno && readydeleteannotation) {
                break;
            }

            if (deleteanno.annot.replyTo == nil || [deleteanno.annot isReplyToAnnot:annotation.annot]) {
                replytoanno = annotation;
            }

            if ([deleteanno.annot isEqualToAnnot:annotation.annot]) {
                readydeleteannotation = annotation;
            }
        }

        if ([[self.totalnodes objectForKey:replytoanno.rootannotation.annot.uuidWithPageIndex] containsObject:readydeleteannotation]) {
            [[self.totalnodes objectForKey:replytoanno.rootannotation.annot.uuidWithPageIndex] removeObject:readydeleteannotation];
        }

        if (![self.annostructdic objectForKey:replytoanno.annot.uuidWithPageIndex] || replytoanno.rootannotation == nil) {
            [self.annostructdic removeObjectForKey:deleteanno.annot.uuidWithPageIndex];

        } else {
            BOOL deleteresult = [AnnotationStruct deleteAnnotationFromAnnoStruct:self.annostructdic deleteAnnotation:readydeleteannotation rootAnnotation:replytoanno.rootannotation];

            if (!deleteresult) {
                [self.annostructdic removeObjectForKey:deleteanno.annot.uuidWithPageIndex];
            }
        }
    }

    for (AnnotationItem *deleteanno in readydelete) {
        if (deleteanno.annot.replyTo == nil || [deleteanno.annot.replyTo isEqualToString:@""]) {
            [self checkAnnotationWithuuid:deleteanno isremove:YES];
        }
    }

    for (AnnotationItem *clearanno in annotations) {
        [readydelete removeObject:clearanno];
    }

    [self deleteSelectannos:[deletetotal allObjects]];

    NSMutableSet *temparrays = [NSMutableSet set];

    for (AnnotationItem *annotation in [deletetotal allObjects]) {
        AnnotationItem *rootanno = nil;

        [AnnotationStruct getRootAnnotation:annotation TargetAnnotation:&rootanno AnnoArray:[deletetotal allObjects]];

        if (rootanno == nil) {
            [temparrays addObject:annotation];

        } else {
            [temparrays addObject:rootanno];
        }
    }

    for (AnnotationItem *checkupdate in [temparrays allObjects]) {
        [self checkAnnotationIsUpdate:checkupdate.rootannotation];
    }

    for (AnnotationItem *deleteanno in readydelete) {
        id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:deleteanno.annot];
        if ([annotHandler respondsToSelector:@selector(removeAnnot:addUndo:)]) {
            [annotHandler removeAnnot:deleteanno.annot addUndo:NO];
        } else {
            [annotHandler removeAnnot:deleteanno.annot];
        }
        if (_extensionsManager.currentAnnot) {
            [_extensionsManager setCurrentAnnot:nil];
        }
        deleteanno.isDeleted = YES;
    }

    if (self.isShowViewList) {
        dispatch_async(dispatch_get_main_queue(), ^{

            [self.tableView reloadData];

        });
    }
}

//delete annotation
- (void)reloadAnnotationForPages:(AnnotationItem *)annotation {
    for (AnnotationItem *readyexist in self.allannotations) {
        if ([annotation.annot isEqualToAnnot:readyexist.annot]) {
            annotation = readyexist;

            break;
        }
    }

    [self updateAnnotationTotals:[NSArray arrayWithObject:annotation]];

    NSMutableArray *deletetotal = [NSMutableArray arrayWithArray:[AnnotationStruct getAllChildNodesWithSuperAnnotation:annotation annoStruct:self.annostructdic]];
    [deletetotal addObject:annotation];

    NSMutableArray *childannos = [NSMutableArray arrayWithArray:[AnnotationStruct getAllChildNodesWithSuperAnnotation:annotation annoStruct:self.annostructdic]];
    [childannos addObject:annotation];

    for (AnnotationItem *deleteanno in childannos) {
        id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:deleteanno.annot];
        [annotHandler removeAnnot:deleteanno.annot];
        if (_extensionsManager.currentAnnot) {
            [_extensionsManager setCurrentAnnot:nil];
        }

        AnnotationItem *replytoanno = nil;

        AnnotationItem *readydeleteannotation = nil;

        for (AnnotationItem *annotation in self.allannotations) {
            if (replytoanno && readydeleteannotation) {
                break;
            }

            if (deleteanno.annot.replyTo == nil || [deleteanno.annot isReplyToAnnot:annotation.annot]) {
                replytoanno = annotation;
            }

            if ([deleteanno.annot isEqualToAnnot:annotation.annot]) {
                readydeleteannotation = annotation;
            }
        }

        if ([[self.totalnodes objectForKey:replytoanno.rootannotation.annot.uuidWithPageIndex] containsObject:readydeleteannotation]) {
            [[self.totalnodes objectForKey:replytoanno.rootannotation.annot.uuidWithPageIndex] removeObject:readydeleteannotation];
        }

        if (![self.annostructdic objectForKey:replytoanno.annot.uuidWithPageIndex] || replytoanno.rootannotation == nil) {
            [self.annostructdic removeObjectForKey:deleteanno.annot.uuidWithPageIndex];

        } else {
            BOOL deleteresult = [AnnotationStruct deleteAnnotationFromAnnoStruct:self.annostructdic deleteAnnotation:readydeleteannotation rootAnnotation:replytoanno.rootannotation];

            if (!deleteresult) {
                [self.annostructdic removeObjectForKey:deleteanno.annot.uuidWithPageIndex];
            }
        }
    }

    [self checkAnnotationWithuuid:annotation isremove:YES];

    [self deleteSelectannos:deletetotal];

    [self checkAnnotationIsUpdate:annotation.rootannotation];

    if (self.isShowViewList) {
        dispatch_async(dispatch_get_main_queue(), ^{

            [self.tableView reloadData];

        });
    }
}

- (void)deleteSelectannos:(NSArray *)selectannos {
    NSMutableArray *toDelete = [NSMutableArray array];
    for (AnnotationItem *selectanno in selectannos) {
        selectanno.isSelected = NO;
        selectanno.isUpdate = NO;

        for (AnnotationItem *annotItem in self.allannotations) {
            if ([annotItem.annot isEqualToAnnot:selectanno.annot])
                [toDelete addObject:annotItem];
        }
    }
    for (AnnotationItem *item in toDelete) {
        [self.allannotations removeObject:item];
    }

    [self.selectannos removeAllObjects];
}

//add|modify annotation
- (void)reloadAnnotationForAnnotation:(NSDictionary *)annotdic {
    AnnotationItem *annot = [annotdic objectForKey:@"Annotation"];

    if (![self checkAnnotationWithuuid:annot isremove:NO] && annot.annot.replyTo == nil) {
        annot.isSecondLevel = YES;
        if (annot.isUpdate && !annot.isMyAnnotation) {
            annot.isShowUpdateTip = YES;
        }

        NSMutableArray *pagearray = [self checkAddAnnotation:annot];
        if (pagearray) {
            [pagearray addObject:annot];
            annot.annosection = [self.allpageannos indexOfObject:pagearray];

        } else {
            BOOL searchtag = YES;
            NSUInteger insertindex = 0;
            for (NSArray *annoarray in self.allpageannos) {
                AnnotationItem *annotation = [annoarray objectAtIndex:0];

                if (annot.annot.pageIndex < annotation.annot.pageIndex) {
                    insertindex = [self.allpageannos indexOfObject:annoarray];
                    searchtag = NO;
                    break;
                }
            }

            if (searchtag == YES) {
                [self.allpageannos addObject:[NSMutableArray array]];

                NSMutableArray *sectionarray = [self.allpageannos lastObject];
                [sectionarray addObject:annot];

                annot.annosection = ([self.allpageannos count] - 1);

            } else {
                [self.allpageannos insertObject:[NSMutableArray array] atIndex:insertindex];

                NSMutableArray *sectionarray = [self.allpageannos objectAtIndex:insertindex];
                [sectionarray addObject:annot];

                annot.annosection = insertindex;

                for (long i = (insertindex + 1); i < self.allpageannos.count; i++) {
                    if ([[self.allpageannos objectAtIndex:i] count] > 0) {
                        AnnotationItem *oldannotation = [[self.allpageannos objectAtIndex:i] firstObject];

                        [[self.allpageannos objectAtIndex:i] makeObjectsPerformSelector:@selector(setAnnotationSection:) withObject:[NSNumber numberWithLong:(oldannotation.annosection + 1)]];
                    }
                }
            }
        }

        NSMutableArray *temparray = [NSMutableArray array];

        [temparray addObject:annot];

        [self.totalnodes setObject:temparray forKey:annot.annot.uuidWithPageIndex];

        [self.annostructdic setObject:[NSMutableArray array] forKey:annot.annot.uuidWithPageIndex];

        annot.rootannotation = annot;

        [self.allannotations addObject:annot];

    } else if (annot.annot.replyTo == nil) {
        annot.isSecondLevel = YES;
        NSMutableArray *pagearray = [self checkAddAnnotation:annot];

        for (AnnotationItem *annotation in pagearray) {
            if ([annotation.annot isEqualToAnnot:annot.annot]) {
                if (![annot.annot canModify]) {
                    annotation.isUpdate = YES;
                    annotation.isShowUpdateTip = YES;
                }
            }
        }

    } else {
        [self addNoteAnnotation:annot];
    }

    if (self.isShowViewList) {
        dispatch_async(dispatch_get_main_queue(), ^{

            [self.tableView reloadData];

        });
    }

    annot.isMyAnnotation = YES;
}

- (BOOL)checkAnnotationWithuuid:(AnnotationItem *)targetannotation isremove:(BOOL)remoetag {
    BOOL searchtag = NO;

    for (int i = 0; i < self.allpageannos.count; i++) {
        NSMutableArray *pageannos = [self.allpageannos objectAtIndex:i];
        if (searchtag) {
            break;
        }

        for (AnnotationItem *annotation in pageannos) {
            if ([annotation.annot isEqualToAnnot:targetannotation.annot]) {
                if (remoetag) {
                    [self.totalnodes removeObjectForKey:annotation.annot.uuidWithPageIndex];
                    [self.annostructdic removeObjectForKey:annotation.annot.uuidWithPageIndex];
                    [pageannos removeObject:annotation];
                }
                if (pageannos.count == 0) {
                    NSInteger oldindex = [self.allpageannos indexOfObject:pageannos];

                    [self.allpageannos removeObject:pageannos];

                    for (long i = oldindex; i < self.allpageannos.count; i++) {
                        if ([[self.allpageannos objectAtIndex:i] count] > 0) {
                            AnnotationItem *oldannotation = [[self.allpageannos objectAtIndex:i] firstObject];

                            [[self.allpageannos objectAtIndex:i] makeObjectsPerformSelector:@selector(setAnnotationSection:) withObject:[NSNumber numberWithLong:(oldannotation.annosection - 1)]];
                        }
                    }
                }
                searchtag = YES;

                break;
            }
        }
    }

    return searchtag;
}

- (NSMutableArray *)checkAddAnnotation:(AnnotationItem *)annotation {
    NSMutableArray *searchindex = nil;

    for (NSMutableArray *pageannotations in self.allpageannos) {
        BOOL tag = [self searchannoWithArray:pageannotations Annotation:annotation];
        if (tag == YES) {
            searchindex = pageannotations;
            break;
        }
    }

    return searchindex;
}

- (BOOL)searchannoWithArray:(NSArray *)array Annotation:(AnnotationItem *)annotation {
    if (array.count > 0) {
        for (AnnotationItem *anno in array) {
            if (annotation.annot.pageIndex == anno.annot.pageIndex) {
                return YES;

            } else {
                if ([self searchannoWithArray:[self.annostructdic objectForKey:anno.annot.uuidWithPageIndex] Annotation:annotation]) {
                    return YES;
                }
            }
        }
    }

    return NO;
}

- (void)addNoteAnnotation:(AnnotationItem *)annot {
    if ([self.annostructdic objectForKey:annot.annot.uuidWithPageIndex]) {
        for (AnnotationItem *annotation in self.allannotations) {
            if ([annot.annot isEqualToAnnot:annotation.annot]) {
                if (annot.isUpdate) {
                    annotation.isUpdate = YES;
                    annotation.rootannotation.isShowUpdateTip = YES;
                }

                annotation.annot.modifiedDate = annot.annot.modifiedDate;
                annotation.annot.contents = annot.annot.contents;
                break;
            }
        }
        return;
    }

    AnnotationItem *replytoanno = nil;

    for (AnnotationItem *annotation in self.allannotations) {
        if ([annot.annot isReplyToAnnot:annotation.annot]) {
            replytoanno = annotation;
            if (annot.isUpdate && !annot.isMyAnnotation) {
                replytoanno.rootannotation.isShowUpdateTip = YES;
            }

            break;
        }
    }

    if (replytoanno == nil) {
        [_updateAnnotations addObject:annot];

        return;
    }

    if (!self.isShowViewList) {
        [AnnotationStruct insertAnnotationToAnnoStruct:self.annostructdic insertAnnotation:annot SuperAnnotation:replytoanno];

        [self.allannotations addObject:annot];

        [self getallPageAnnos];

        return;
    }

    BOOL searchtag = NO;

    for (NSString *pageannokey in [self.totalnodes allKeys]) {
        if ([[self.totalnodes objectForKey:pageannokey] containsObject:replytoanno]) {
            searchtag = YES;
            break;
        }
    }

    if (replytoanno.currentlevelshow == NO && (replytoanno.isSecondLevel || replytoanno.annot.replyTo == nil)) {
        [self getDetailReply:nil ClickAnnotation:replytoanno];
        searchtag = YES;
    }

    if (searchtag == NO) {
        [AnnotationStruct insertAnnotationToAnnoStruct:self.annostructdic insertAnnotation:annot SuperAnnotation:replytoanno];

        [self.allannotations addObject:annot];

        [self getallPageAnnos];

        return;
    }

    NSArray *currentpagenode = [self.allpageannos objectAtIndex:replytoanno.annosection];

    NSMutableArray *currentarray = [self checkIndexFromAnnotation:replytoanno.rootannotation Annoarray:currentpagenode];

    if (replytoanno.annot.replyTo == nil) {
        annot.isSecondLevel = YES;
    }

    annot.rootannotation = replytoanno.rootannotation;
    annot.annosection = replytoanno.annosection;

    [AnnotationStruct insertAnnotationToAnnoStruct:self.annostructdic insertAnnotation:annot SuperAnnotation:replytoanno];

    NSMutableArray *addannoarray = [NSMutableArray arrayWithObject:annot];

    [addannoarray makeObjectsPerformSelector:@selector(addCurrentlevel:) withObject:[NSNumber numberWithLong:(replytoanno.annot.replyTo == nil ? (replytoanno.currentlevel + 1) : (replytoanno.currentlevel))]];

    [addannoarray makeObjectsPerformSelector:@selector(setReplytoauthor:) withObject:replytoanno.annot.author];

    NSUInteger insertrowindex = [currentarray indexOfObject:replytoanno];

    NSMutableArray *arCells = [NSMutableArray array];

    NSUInteger currentrow = 0;

    NSUInteger cuurentsection = replytoanno.annosection;

    NSMutableArray *currentlevel = [NSMutableArray array];

    for (AnnotationItem *rootnode in currentpagenode) {
        [currentlevel addObjectsFromArray:[self.totalnodes objectForKey:rootnode.annot.uuidWithPageIndex]];
    }

    currentrow = [currentlevel indexOfObject:replytoanno];

    if (replytoanno.annot.replyTo == nil) {
        currentrow = currentrow + [[self.totalnodes objectForKey:replytoanno.annot.uuidWithPageIndex] count];

        [arCells addObject:[NSIndexPath indexPathForRow:currentrow inSection:cuurentsection]];

        [currentarray insertObjects:addannoarray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([[self.totalnodes objectForKey:replytoanno.annot.uuidWithPageIndex] count], addannoarray.count)]];

    } else {
        currentrow = currentrow + [[self.annostructdic objectForKey:replytoanno.annot.uuidWithPageIndex] count];

        [arCells addObject:[NSIndexPath indexPathForRow:currentrow inSection:cuurentsection]];

        [currentarray insertObjects:addannoarray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertrowindex + [[self.annostructdic objectForKey:replytoanno.annot.uuidWithPageIndex] count], addannoarray.count)]];
    }
    // this is error    crash on some special pdf
    [self.tableView insertRowsAtIndexPaths:arCells withRowAnimation:UITableViewRowAnimationNone];

    [self getallPageAnnos];
    [self.allannotations addObject:annot];
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.tableView reloadData];

    });
}

- (void)deleteAnnotation:(AnnotationItem *)item {
    [self endEditing];

    if (!item.isDeleted) {
        id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:item.annot];
        [annotHandler removeAnnot:item.annot];
        item.isDeleted = YES;
    }
    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
}

//reply
- (void)replyToAnnotation:(AnnotationItem *)item {
    [self endEditing];

    AnnotationItem *replytoanno = item;
    if (replytoanno == nil) {
        return;
    }
    if (replytoanno.currentlevelshow == NO && (replytoanno.isSecondLevel || replytoanno.annot.replyTo == nil)) {
        [self getDetailReply:nil ClickAnnotation:replytoanno];
    }
    //Nodes of the current page
    NSArray *currentpagenode = [self.allpageannos objectAtIndex:replytoanno.annosection];

    //array of the current nodes
    NSMutableArray *currentarray = [self checkIndexFromAnnotation:replytoanno Annoarray:currentpagenode];

    //creat a new antationitem
    _replyanno = [[AnnotationItem alloc] init];
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:item.annot.pageIndex];

    if (!page)
        return;
    FSNote *note = [(FSMarkup *) replytoanno.annot addReply];
    note.NM = [Utility getUUID];
    note.fsrect = replytoanno.annot.fsrect;
    note.author = [SettingPreference getAnnotationAuthor];
    note.contents = @"";
    note.color = 0;
    note.opacity = 1.0;
    note.lineWidth = 2;
    note.icon = 0;
    _replyanno.annot = note;
    NSDate *now = [NSDate date];
    _replyanno.annot.modifiedDate = now;
    _replyanno.annot.createDate = now;
    _replyanno.rootannotation = replytoanno.rootannotation;
    _replyanno.isReply = YES;
    if (replytoanno.annot.replyTo == nil) {
        _replyanno.isSecondLevel = YES;

    } else {
        _replyanno.isSecondLevel = NO;
    }

    //add to dictionary
    [AnnotationStruct insertAnnotationToAnnoStruct:self.annostructdic insertAnnotation:_replyanno SuperAnnotation:replytoanno];

    NSMutableArray *addannoarray = [NSMutableArray arrayWithObject:_replyanno];

    //level
    [addannoarray makeObjectsPerformSelector:@selector(addCurrentlevel:) withObject:[NSNumber numberWithLong:(replytoanno.annot.replyTo == nil ? (replytoanno.currentlevel + 1) : (replytoanno.currentlevel))]];

    //reply to author
    [addannoarray makeObjectsPerformSelector:@selector(setReplytoauthor:) withObject:replytoanno.annot.author];

    //Reply to the comments in the subscript in the current node
    NSUInteger insertrowindex = [currentarray indexOfObject:replytoanno];

    __block NSIndexPath *indexpath = [[NSIndexPath alloc] init];

    //Reply to the comments of the current page rows
    NSUInteger currentrow = replytoanno.annorow;

    if (replytoanno.annot.replyTo == nil) {
        //Reply to the comments of the current page rows + The number of the current node in the all comments
        currentrow += [[self.totalnodes objectForKey:replytoanno.annot.uuidWithPageIndex] count];

        //The indexpath add to the arCells
        indexpath = [NSIndexPath indexPathForRow:currentrow inSection:replytoanno.annosection];
        // [arCells addObject:indexpath];

        //The addannoarray insert to currentarray
        //Insert data source
        [currentarray insertObjects:addannoarray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([[self.totalnodes objectForKey:replytoanno.annot.uuidWithPageIndex] count], addannoarray.count)]];

    } else {
        currentrow = currentrow + [[self.annostructdic objectForKey:replytoanno.annot.uuidWithPageIndex] count];
        indexpath = [NSIndexPath indexPathForRow:currentrow inSection:replytoanno.annosection];

        [currentarray insertObjects:addannoarray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertrowindex + [[self.annostructdic objectForKey:replytoanno.annot.uuidWithPageIndex] count], addannoarray.count)]];
    }
    self.indexPath = indexpath;

    //Insert a cell
    [self.tableView insertRowsAtIndexPaths:@[ indexpath ] withRowAnimation:UITableViewRowAnimationNone];

    //update  the  allannotations
    [self getallPageAnnos];
    [_allannotations addObject:_replyanno];

    [self.tableView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];

    double delayInSeconds = .3;
    //after scrollToRowAtIndexPath, To determine the current cell
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {

        AnnotationListCell *selectcell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:indexpath]; // returns nil if cell is not visible or index path is out of range
        selectcell.isInputText = YES;

        UITextView *edittextview = (UITextView *) [selectcell.contentView viewWithTag:107];
        edittextview.delegate = self;
        edittextview.hidden = NO;

        UILabel *labelContents = (UILabel *) [selectcell.contentView viewWithTag:104];
        labelContents.hidden = YES;

        edittextview.text = labelContents.text;
        [edittextview becomeFirstResponder];
    });
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.tableView reloadData];

    });
}

- (void)addNoteToAnnotation:(AnnotationItem *)item withIndexPath:(NSIndexPath *)indexPath {
    [self endEditing];

    self.editAnnoItem = item;
    self.indexPath = indexPath;
    AnnotationListCell *selectcell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    selectcell.isInputText = YES;
    UITextView *edittextview = (UITextView *) [selectcell.contentView viewWithTag:107];
    edittextview.delegate = self;
    edittextview.hidden = NO;

    UILabel *labelContents = (UILabel *) [selectcell.contentView viewWithTag:104];
    labelContents.hidden = YES;

    edittextview.text = labelContents.text;
    [edittextview scrollsToTop];
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.tableView reloadData];

    });
    [edittextview performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.3];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (self.editAnnoItem) {
            [self modifyAnnot:self.editAnnoItem.annot withContents:textView.text];
            self.editAnnoItem = nil;
        }

        UITableViewCell *selectcell = [self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView *edittextview = (UITextView *) [selectcell.contentView viewWithTag:107];
        edittextview.hidden = YES;
        UILabel *labelContents = (UILabel *) [selectcell.contentView viewWithTag:104];
        labelContents.hidden = NO;
        dispatch_async(dispatch_get_main_queue(), ^{

            [self.tableView reloadData];

        });
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    AnnotationListCell *selectcell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.indexPath];
    UITextView *edittextview = (UITextView *) [selectcell.contentView viewWithTag:107];
    if (edittextview != textView) {
        return;
    }

    if (self.editAnnoItem) {
        [self modifyAnnot:self.editAnnoItem.annot withContents:textView.text];
        self.editAnnoItem = nil;
    }
    if (_replyanno && _replyanno.isReply) {
        if (_replyanno == selectcell.item) {
            _replyanno.annot.contents = textView.text;
            _replyanno.isReply = NO;
            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:_replyanno.annot];
            [annotHandler addAnnot:_replyanno.annot];
        }
        _replyanno = nil;
    }

    edittextview.hidden = YES;
    UILabel *labelContents = (UILabel *) [selectcell.contentView viewWithTag:104];
    labelContents.hidden = NO;
    self.indexPath = nil;
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.tableView reloadData];

    });
    [textView resignFirstResponder];
    selectcell.isInputText = NO;
}

#pragma mark - Private methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath

{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSMutableArray *)getallAnnotations {
    return self.allpageannos;
}

- (NSInteger)getAnnotationsCount {
    return self.allpageannos.count;
}

- (void)refreshInterface {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIView alloc] init];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    ((UIScrollView *) self.tableView).delegate = self;
    self.tableView.clipsToBounds = YES;

    CGRect tableViewFrame = self.tableView.frame;

    self.annoupdatetipLB = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, tableViewFrame.size.width, 20)];
    [_annoupdatetipLB setFont:[UIFont systemFontOfSize:13]];
    _annoupdatetipLB.backgroundColor = [UIColor clearColor];
    _annoupdatetipLB.textColor = [UIColor colorWithRed:23.f / 255.f green:156.f / 255.f blue:216.f / 255.f alpha:1];
    UIView *backView = self.tableView.superview;
    [backView addSubview:_annoupdatetipLB];
    _annoupdatetipLB.hidden = YES;
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:view];
}

- (void)setProgressInformationHidden:(NSNumber *)isHidden {
    if (isHidden == nil || isHidden.boolValue) {
        [_cellProgressIndicator stopAnimating];
        _cellProgressIndicator.hidden = YES;
        _cellProgressLabel.hidden = YES;
    } else {
        if (_isLoading) {
            [_cellProgressIndicator startAnimating];
            _cellProgressIndicator.hidden = isHidden.boolValue;
            _cellProgressLabel.hidden = isHidden.boolValue;
        }
    }
}

- (void)modifyAnnot:(FSAnnot *)annot withContents:(NSString *)contents {
    NSString *oldContents = annot.contents;
    if ([oldContents isEqualToString:contents]) {
        return;
    }

    NSDate *oldDate = annot.modifiedDate;
    NSDate *now = [NSDate date];
    NSString *NM = annot.NM;
    FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:annot.pageIndex];
    id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
    [_extensionsManager addUndoItem:[UndoItem itemWithUndo:^(UndoItem *item) {
                            FSAnnot *annot = [Utility getAnnotByNM:NM inPage:page];
                            annot.contents = oldContents;
                            annot.modifiedDate = oldDate;
                            if ([annotHandler respondsToSelector:@selector(modifyAnnot:addUndo:)]) {
                                [annotHandler modifyAnnot:annot addUndo:NO];
                            } else {
                                [annotHandler modifyAnnot:annot];
                            }
                        }
                                        redo:^(UndoItem *item) {
                                            FSAnnot *annot = [Utility getAnnotByNM:NM inPage:page];
                                            annot.contents = contents;
                                            annot.modifiedDate = now;
                                            if ([annotHandler respondsToSelector:@selector(modifyAnnot:addUndo:)]) {
                                                [annotHandler modifyAnnot:annot addUndo:NO];
                                            } else {
                                                [annotHandler modifyAnnot:annot];
                                            }
                                        }
                                        pageIndex:annot.pageIndex]];

    annot.contents = contents;
    annot.modifiedDate = now;
    if ([annotHandler respondsToSelector:@selector(modifyAnnot:addUndo:)]) {
        [annotHandler modifyAnnot:self.editAnnoItem.annot addUndo:NO];
    } else {
        [annotHandler modifyAnnot:self.editAnnoItem.annot];
    }
}

- (void)endEditing {
    if (self.editAnnoItem || (_replyanno && _replyanno.isReply == YES)) {
        AnnotationListCell *cell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
        UILabel *labelContents = (UILabel *) [cell.contentView viewWithTag:104];

        if (self.editAnnoItem) {
            [self modifyAnnot:self.editAnnoItem.annot withContents:edittextview.text];
            self.editAnnoItem = nil;
        }
        if (_replyanno && _replyanno.isReply == YES) {
            _replyanno.annot.contents = edittextview.text;
            _replyanno.isReply = NO;
            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:_replyanno.annot];
            [annotHandler addAnnot:_replyanno.annot];
            _replyanno = nil;
        }
        
        edittextview.hidden = YES;
        labelContents.hidden = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        [edittextview resignFirstResponder];
        cell.isInputText = NO;
    }
}

#pragma mark-- keyboard
- (void)keyboardDidShow:(NSNotification *)note {
    [self.tableView scrollToRowAtIndexPath:self.indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

@end
