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

#import "AttachmentViewController.h"
#import "AnnotationItem.h"
#import "AnnotationListCell.h"
#import "AnnotationStruct.h"
#import "AnnotationListMore.h"
#import "AttachmentController.h"
#import "FileManageListViewController.h"
#import "PanelController.h"
#import "FSAnnotExtent.h"
#import "AttachmentPanel.h"
#import "Masonry.h"
#import "PanelHost.h"
#import "AnnotationItem.h"
#import "AlertView.h"
#import "FileSelectDestinationViewController.h"
#import "FSPDFReader.h"


@interface AttachmentViewController() <IPanelChangedListener>
@property (nonatomic, assign) BOOL isKeyboardShow;
@property (nonatomic, assign) BOOL dicrection;
@property (nonatomic, retain) UIDocumentInteractionController* documentPopoverController;

@property (nonatomic, strong) NSOperationQueue* loadAttachmentQueue;

@end

@implementation AttachmentViewController {
    FSPDFViewCtrl* __weak _pdfViewCtrl;
    UIExtensionsManager* __weak _extensionsManager;
    PanelController* __weak _panelController;
    AttachmentPanel* __weak _attachmentPanel;
}

- (id)initWithStyle:(UITableViewStyle)style extensionsManager:(UIExtensionsManager*)extensionsManager module:(AttachmentPanel*)attachmentPanel
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _panelController = attachmentPanel.panelController;
        _attachmentPanel = attachmentPanel;
        
        self.allAttachmentsSections = [NSMutableArray array];
        
        UIWindow*keywindow = [[UIApplication sharedApplication]keyWindow];
        self.dicrection = UIDeviceOrientationIsLandscape(keywindow.rootViewController.interfaceOrientation);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(UpdateDeleteAnnotationsTotal:) name:ANNOLIST_UPDADELETETOTAL object:nil];
        [_panelController registerPanelChangedListener:self];
        [_extensionsManager registerAnnotEventListener:self];
        [_pdfViewCtrl registerDocEventListener:self];
        [_pdfViewCtrl registerPageEventListener:self];
        self.moreIndexPath = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIView alloc] init];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    ((UIScrollView*)self.tableView).delegate = self;
    self.tableView.clipsToBounds = YES;
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)])
    {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)])
    {
        [self.tableView setLayoutMargins:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:view];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

-(void)deviceOrientationChange{
    
    UIDeviceOrientation currentOri= [[UIDevice currentDevice] orientation];
    
    if(UIDeviceOrientationIsLandscape(currentOri))
    {
        if (!self.dicrection) {
            self.dicrection = YES;
            [[NSNotificationCenter defaultCenter]postNotificationName:ORIENTATIONCHANGED object:nil];
            [NSObject cancelPreviousPerformRequestsWithTarget:self.tableView selector:@selector(reloadData) object:nil];
            [self.tableView reloadData];
            double delayInSeconds = 1.2;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self.tableView reloadData];
            });
        }
        
    }else if(UIInterfaceOrientationIsPortrait(currentOri) && currentOri != UIDeviceOrientationPortraitUpsideDown){
        
        if (self.dicrection) {
            self.dicrection = NO;
            [[NSNotificationCenter defaultCenter]postNotificationName:ORIENTATIONCHANGED object:nil];
            [NSObject cancelPreviousPerformRequestsWithTarget:self.tableView selector:@selector(reloadData) object:nil];
            [self.tableView reloadData];
            double delayInSeconds = 1.2;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                
                [self.tableView reloadData];
            });
        }
    }
}

-(void)UpdateDeleteAnnotationsTotal:(NSNotification*)noti{
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation));
}

#pragma mark - IAnnotEventListener

- (void)onAnnotAdded:(FSPDFPage*)page annot:(FSAnnot*)annot
{
    if (annot.type == e_annotFileAttachment) {
        [self updateAllAttachments:[AttachmentItem itemWithAttachmentAnnotation:(FSFileAttachment*)annot] operation:AnnotationOperation_Add];
    }
}

- (void)onAnnotDeleted:(FSPDFPage*)page annot:(FSAnnot*)annot
{
    if (annot.type == e_annotFileAttachment) {
        [self updateAllAttachments:[AttachmentItem itemWithAttachmentAnnotation:(FSFileAttachment*)annot] operation:AnnotationOperation_Delete];
    }
}

- (void)onAnnotModified:(FSPDFPage*)page annot:(FSAnnot*)annot
{
    if (annot.type == e_annotFileAttachment) {
        [self updateAllAttachments:[AttachmentItem itemWithAttachmentAnnotation:(FSFileAttachment*)annot] operation:AnnotationOperation_Modify];
    }
}

- (void)onDocumentAttachmentAdded:(AttachmentItem*)attachmentItem
{
    [self updateAllAttachments:attachmentItem operation:AnnotationOperation_Add];
}

- (void)onDocumentAttachmentDeleted:(AttachmentItem*)attachmentItem
{
    [self updateAllAttachments:attachmentItem operation:AnnotationOperation_Delete];
}

- (void)onDocumentAttachmentModified:(AttachmentItem*)attachmentItem
{
    [self updateAllAttachments:attachmentItem operation:AnnotationOperation_Modify];
}

#pragma mark - IPanelChangedListener

-(void)onPanelChanged:(BOOL)isHidden
{
    if (self.isShowMore && isHidden) {
        if (self.moreIndexPath) {
            AnnotationListCell *cell = (AnnotationListCell*)[self.tableView cellForRowAtIndexPath:self.moreIndexPath];
            [cell.belowView tapGuest:nil];
            self.moreIndexPath = nil;
        }
    }
    
    if (isHidden) {
        AnnotationListCell *cell = (AnnotationListCell*)[self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView* edittextview = (UITextView*)[cell.contentView viewWithTag:107];
        [edittextview resignFirstResponder];
    }
    
    if (self.editAnnoItem) {
        AnnotationListCell *cell = (AnnotationListCell*)[self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView* edittextview = (UITextView*)[cell.contentView viewWithTag:107];
        UILabel* labelContents = (UILabel*)[cell.contentView viewWithTag:104];
        [edittextview resignFirstResponder];
        // when text view resign first responder, textViewDidEndEditing will be called
        // to rename attachment, so following code is commented
        //        NSDate *now = [NSDate date];
        //        if (self.editAnnoItem) {
        //            self.editAnnoItem.annot.contents = edittextview.text;
        //            self.editAnnoItem.annot.modifiedDate = now;
        //            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:self.editAnnoItem.annot];
        //            [annotHandler modifyAnnot:self.editAnnoItem.annot];
        //            self.editAnnoItem = nil;
        //        }
        edittextview.hidden = YES;
        labelContents.hidden = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            
        });
        cell.isInputText = NO;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.allAttachmentsSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *array = [self.allAttachmentsSections objectAtIndex:section];
    return array.count;
}

#pragma mark -  UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    
    UIView *view = [[UIView alloc] init];
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.allAttachmentsSections.count == 0) {
        UIView *view = [[UIView alloc] init];
        return view;
    }
    NSArray *array = [self.allAttachmentsSections copy];
    
    AttachmentItem *attachmentItem = nil;
    if (section < [array count]){
        attachmentItem = [[array objectAtIndex:section] objectAtIndex:0];
    }
    
    UIView* subView = [[UIView alloc] init];
    subView.backgroundColor = [UIColor colorWithRed:204.f/255.f green:204.f/255.f blue:204.f/255.f alpha:1];
    UILabel* labelSection = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, tableView.bounds.size.width-20, 25)];
    labelSection.font = [UIFont systemFontOfSize:13];
    labelSection.backgroundColor = [UIColor clearColor];
    labelSection.textColor = [UIColor blackColor];
    NSString* sectionTitle = nil;
    if (attachmentItem && attachmentItem.isDocumentAttachment) {
        sectionTitle = NSLocalizedStringFromTable(@"kDocumentAttachmentTab", @"FoxitLocalizable", nil);
    }
    else
    {
        sectionTitle = [NSString stringWithFormat:@"%@ %d", NSLocalizedStringFromTable(@"kPage", @"FoxitLocalizable", nil), attachmentItem.pageIndex+1];
    }
    
    labelSection.text = sectionTitle;
    
    
    UILabel* labelTotal = [[UILabel alloc] initWithFrame:CGRectMake(tableView.bounds.size.width-120, 0, 100, 25)];
    labelTotal.font = [UIFont systemFontOfSize:13];
    labelTotal.textAlignment = NSTextAlignmentRight;
    labelTotal.backgroundColor = [UIColor clearColor];
    labelTotal.textColor = [UIColor colorWithRed:37.f/255.f green:157.f/255.f blue:214.f/255.f alpha:1];
    
    if(section < [array count]){
        labelTotal.text = [NSString stringWithFormat:@"%d",[[array objectAtIndex:section] count]];
    }
    
    
    [subView addSubview:labelSection];
    [subView addSubview:labelTotal];
    return subView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 25;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (self.allAttachmentsSections.count == 0) {
        return 0;
    }
    
    NSArray *sectionAttachments = [NSArray array];
    if (indexPath.section < [self.allAttachmentsSections count]) {
        sectionAttachments = [self.allAttachmentsSections objectAtIndex:[indexPath section]];
    }
    
    AttachmentItem *attachmentItem = nil;
    if (indexPath.row < [sectionAttachments count]){
       attachmentItem = [sectionAttachments objectAtIndex:[indexPath row]];
    }
    
    float cellHeight = 68;
    CGSize contentSize = CGSizeMake(0, 0);
    NSString *contents = nil;
    if (attachmentItem && [attachmentItem.description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length != 0) {
        contents = [attachmentItem.description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    if (contents == nil || contents.length == 0)
    {
        if (self.indexPath && self.indexPath.section == indexPath.section && self.indexPath.row == indexPath.row ) {
            contentSize.height = 25;
        }
    }
    else
    {
        contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact? SCREENWIDTH - 40 : 300 - 40, 2000)];
        if (contentSize.height < 25)
            contentSize.height = 25;
        else
            contentSize.height += 5;
    }
    return cellHeight + contentSize.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"annotationCellIdentifier";
    
    
    if (self.allAttachmentsSections.count == 0) {
        AnnotationListCell* cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[AnnotationListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier isMenu:NO superView:_panelController.panel.contentView typeOf:e_annotFileAttachment];
        }
        return cell;
    }

    NSArray *array = [self.allAttachmentsSections copy];
    NSArray *sectionAttachments = [NSArray array];
    if (indexPath.section < [array count]) {
        sectionAttachments = [array objectAtIndex:[indexPath section]];
    }
    
    AttachmentItem *attachmentItem = nil;
    if (indexPath.row < [sectionAttachments count]){
        attachmentItem = [sectionAttachments objectAtIndex:[indexPath row]];
    }
    
    AnnotationListCell* cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[AnnotationListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier isMenu:NO superView:_panelController.panel.contentView typeOf:e_annotFileAttachment];
        cell.delegate = self;
    }
    cell.delegate = self;
    cell.belowView.deleteButton.hidden = NO;
    cell.belowView.noteButton.hidden = NO;
    cell.belowView.saveButton.hidden = NO;
    UIImageView *annoimageView = (UIImageView*)[cell.contentView viewWithTag:99];
    annoimageView.frame = CGRectMake(8, 15, 40, 40);
    UIImageView *buttonViewLevel = (UIImageView*)[cell.contentView viewWithTag:100];
    buttonViewLevel.hidden = YES;
    UILabel* labelAuthor = (UILabel*)[cell.contentView viewWithTag:102];
    UILabel* labelDate = (UILabel*)[cell.contentView viewWithTag:103];
    UILabel* labelSize = (UILabel*)[cell.contentView viewWithTag:110];
    UILabel* labelContents = (UILabel*)[cell.contentView viewWithTag:104];
    labelContents.hidden = NO;
    labelSize.hidden = NO;
    labelContents.text = attachmentItem.description;
    UITextView* edittextview = (UITextView*)[cell.contentView viewWithTag:107];
    edittextview.returnKeyType = UIReturnKeyDone;
    UIImageView* annoupdatetip = (UIImageView*)[cell.contentView viewWithTag:108];
    annoupdatetip.hidden = YES;
    UIImageView* annouprepltip = (UIImageView*)[cell.contentView viewWithTag:109];
    cell.indexPath = indexPath;
    cell.item = attachmentItem;
    annoimageView.image = [UIImage imageNamed:[Utility getThumbnailName:attachmentItem.filePath]];
    attachmentItem.annosection = indexPath.section;
    attachmentItem.annorow = indexPath.row;
    
    labelAuthor.text = attachmentItem.fileName;
    [labelAuthor setFont:[UIFont systemFontOfSize:18]];
    
    labelDate.text = [Utility displayDateInYMDHM:attachmentItem.modifyDate];
    labelSize.text = [Utility displayFileSize:attachmentItem.fileSize];
    
    NSString *contents = [attachmentItem.description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (contents == nil || contents.length == 0)
    {
        labelContents.hidden = YES;
        
    }else{
        
        labelContents.hidden = NO;
        labelContents.text = contents;
        CGSize contentSize = CGSizeZero;
        labelContents.numberOfLines = 0;
        
        
        contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact? SCREENWIDTH - 40 : 300 - 40, 2000)];
        
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
    
    annoimageView.hidden = NO;
    [labelAuthor setTextAlignment:NSTextAlignmentLeft];
    annouprepltip.hidden = YES;
    
    [labelContents setTextColor:[UIColor darkGrayColor]];
    if (cell.isInputText) {
        edittextview.hidden = NO;
        labelContents.hidden = YES;
    }
    else
    {
        edittextview.hidden = YES;
        if (contents == nil || contents.length == 0) {
            labelContents.hidden = YES;
        }else{
            labelContents.hidden = NO;
        }
        
    }
    
    CGRect bottomViewFrame = cell.belowView.bottomView.superview.frame;
    cell.belowView.frame = CGRectMake(DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact ? SCREENWIDTH : 300, 0, DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact ? SCREENWIDTH : 300, 68);
    
    [cell.belowView.gestureView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(cell.belowView.gestureView.superview.mas_right).offset(0);
        make.top.equalTo(cell.belowView.gestureView.superview.mas_top).offset(64);
        make.bottom.equalTo(cell.belowView.gestureView.superview.mas_bottom).offset(0);
        float width;
        
        width = DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact ? SCREENWIDTH : 300;
        make.width.mas_equalTo(width);
    }];
    
    
    cell.detailButton.enabled = YES;
    
    BOOL canCopyForAssess = [Utility canCopyForAssessInDocument:_pdfViewCtrl.currentDoc];
    
    if (cell.item.annot) {
        
        if ([cell.item.annot canModify] && canCopyForAssess) {
            cell.belowView.deleteButton.hidden = NO;
            cell.belowView.noteButton.hidden = NO;
            cell.belowView.saveButton.hidden = NO;
            cell.belowView.bottomView.frame = CGRectMake(cell.belowView.bottomView.superview.frame.size.width - 150, 0, 150, bottomViewFrame.size.height);
            cell.belowView.saveButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 25,cell.belowView.bottomView.superview.center.y);
            cell.belowView.noteButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 75,cell.belowView.bottomView.superview.center.y);
            cell.belowView.deleteButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 125,cell.belowView.bottomView.superview.center.y);
            
        }
        else if (![cell.item.annot canModify] && canCopyForAssess)
        {
            cell.belowView.deleteButton.hidden = YES;
            cell.belowView.noteButton.hidden = YES;
            cell.belowView.saveButton.hidden = NO;
            
            cell.belowView.saveButton.hidden = NO;
            cell.belowView.bottomView.frame = CGRectMake(cell.belowView.bottomView.superview.frame.size.width - 50, 0, 50, bottomViewFrame.size.height);
            cell.belowView.saveButton.center = cell.belowView.bottomView.center;
        }
        else if ([cell.item.annot canModify] && !canCopyForAssess)
        {
            cell.belowView.deleteButton.hidden = NO;
            cell.belowView.noteButton.hidden = NO;
            cell.belowView.saveButton.hidden = YES;
            cell.belowView.bottomView.frame = CGRectMake(cell.belowView.bottomView.superview.frame.size.width - 100, 0, 100, bottomViewFrame.size.height);
            cell.belowView.noteButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 25,cell.belowView.bottomView.superview.center.y);
            cell.belowView.deleteButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 75,cell.belowView.bottomView.superview.center.y);
        }
        else
        {
            cell.belowView.deleteButton.hidden = YES;
            cell.belowView.noteButton.hidden = YES;
            cell.belowView.saveButton.hidden = YES;
            cell.belowView.bottomView.frame = CGRectMake(cell.belowView.bottomView.superview.frame.size.width, 0, 0,0);
            cell.detailButton.enabled = NO;
        }
    }
    else
    {
        BOOL canModify = [Utility canModifyContentsInDocument:_pdfViewCtrl.currentDoc];
        if (canModify && canCopyForAssess) {
            cell.belowView.deleteButton.hidden = NO;
            cell.belowView.noteButton.hidden = NO;
            cell.belowView.saveButton.hidden = NO;
            cell.belowView.bottomView.frame = CGRectMake(cell.belowView.bottomView.superview.frame.size.width - 150, 0, 150, bottomViewFrame.size.height);
            cell.belowView.saveButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 25,cell.belowView.bottomView.superview.center.y);
            cell.belowView.noteButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 75,cell.belowView.bottomView.superview.center.y);
            cell.belowView.deleteButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 125,cell.belowView.bottomView.superview.center.y);
            
        }
        
        else if (!canModify && canCopyForAssess)
        {
            cell.belowView.deleteButton.hidden = YES;
            cell.belowView.noteButton.hidden = YES;
            cell.belowView.saveButton.hidden = NO;
            
            cell.belowView.saveButton.hidden = NO;
            cell.belowView.bottomView.frame = CGRectMake(cell.belowView.bottomView.superview.frame.size.width - 50, 0, 50, bottomViewFrame.size.height);
            cell.belowView.saveButton.center = cell.belowView.bottomView.center;
        }
        else if (canModify && !canCopyForAssess)
        {
            cell.belowView.deleteButton.hidden = NO;
            cell.belowView.noteButton.hidden = NO;
            cell.belowView.saveButton.hidden = YES;
            cell.belowView.bottomView.frame = CGRectMake(cell.belowView.bottomView.superview.frame.size.width - 100, 0, 100, bottomViewFrame.size.height);
            cell.belowView.noteButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 25,cell.belowView.bottomView.superview.center.y);
            cell.belowView.deleteButton.center = CGPointMake(cell.belowView.bottomView.frame.origin.x + 75,cell.belowView.bottomView.superview.center.y);
        }
        else
        {
            cell.belowView.deleteButton.hidden = YES;
            cell.belowView.noteButton.hidden = YES;
            cell.belowView.saveButton.hidden = YES;
            cell.belowView.bottomView.frame = CGRectMake(cell.belowView.bottomView.superview.frame.size.width, 0, 0,0);
            cell.detailButton.enabled = NO;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSArray *sectionAttachments = [self.allAttachmentsSections objectAtIndex:[indexPath section]];
    AttachmentItem *attachmentItem = [sectionAttachments objectAtIndex:[indexPath row]];
    
    [self openAttachment:attachmentItem];
}

- (void)updateAllAttachments:(AttachmentItem *)attachmentItem operation:(int)operation
{
    @synchronized (self) {
        NSMutableArray *attachments = nil;
        for (NSMutableArray *array in self.allAttachmentsSections) {
            AttachmentItem *item = [array objectAtIndex:0];
            if (attachmentItem.pageIndex == item.pageIndex) {
                attachments = array;
                break;
            }
        }
        
        if (operation == AnnotationOperation_Add) {
            if (!attachments) {
                attachments = [NSMutableArray array];
                [self.allAttachmentsSections addObject:attachments];
            }
            [attachments addObject:attachmentItem];
        }
        else if (operation == AnnotationOperation_Modify)
        {
            int index = -1;
            for (AttachmentItem *tmpItem in attachments) {
                if (attachmentItem.annot) {
                    if ([tmpItem.annot.NM isEqualToString:attachmentItem.annot.NM]) {
                        index = [attachments indexOfObject:tmpItem];
                        break;
                    }
                }
                else
                {
                    if ([tmpItem.fileName isEqualToString:attachmentItem.fileName]) {
                        index = [attachments indexOfObject:tmpItem];
                        break;
                    }
                }
            }
            if (index != -1) {
                [attachments replaceObjectAtIndex:index withObject:attachmentItem];
            }
        }
        else if (operation == AnnotationOperation_Delete)
        {
            for (AttachmentItem *tmpItem in attachments) {
                if (attachmentItem.annot) {
                    if ([tmpItem.annot.NM isEqualToString:attachmentItem.annot.NM]) {
                        [attachments removeObject:tmpItem];
                        if (attachments.count == 0) {
                            [self.allAttachmentsSections removeObject:attachments];
                        }
                        break;
                    }
                }
                else
                {
                    if ([tmpItem.fileName isEqualToString:attachmentItem.fileName]) {
                        [attachments removeObject:tmpItem];
                        if (attachments.count == 0) {
                            [self.allAttachmentsSections removeObject:attachments];
                        }
                        break;
                    }
                }
                
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resortAllAttachments];
            [self.tableView reloadData];
        });
    }
}

- (void)openAttachment:(AttachmentItem*)attachmentItem
{
    if (!attachmentItem.fileSpec) {
        return;
    }
    if ([Utility isSupportFormat:attachmentItem.filePath]) {
        AttachmentController *attachmentCtr = [[AttachmentController alloc] init];
        
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:attachmentCtr animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                assert(attachmentItem.fileSpec);
                if (![Utility loadFileSpec:attachmentItem.fileSpec toPath:attachmentItem.filePath]) {
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [attachmentCtr openDocument:attachmentItem.filePath];
                });
            });
        }];
    }
    else
    {
        if (![Utility loadFileSpec:attachmentItem.fileSpec toPath:attachmentItem.filePath]) {
            return;
        }
        NSURL *urlFile = [NSURL fileURLWithPath:attachmentItem.filePath isDirectory:NO];
        self.documentPopoverController = [UIDocumentInteractionController interactionControllerWithURL:urlFile];
        self.documentPopoverController.delegate = self;
        if (DEVICE_iPHONE)
        {
            [self.documentPopoverController presentOpenInMenuFromRect:_pdfViewCtrl.frame inView:_pdfViewCtrl animated:YES];
        }
        else
        {
            CGRect dvRect = CGRectMake(SCREENWIDTH/2, SCREENHEIGHT/2, 20, 20);
            [self.documentPopoverController presentOpenInMenuFromRect:dvRect inView:_pdfViewCtrl animated:YES];
        }
    }
    
}

-(void)setIsShowMore:(BOOL)isShowMore
{
    _isShowMore = isShowMore;
}

-(void)loadAllAnnotAttachments:(NSArray*)annotAttachments
{
    NSMutableArray* attachmentItems = [NSMutableArray array];
    for (FSFileAttachment* annot in annotAttachments) {
        AttachmentItem* attachmentItem = [AttachmentItem itemWithAttachmentAnnotation:annot];
        attachmentItem.currentlevel = 1;
        attachmentItem.isSecondLevel = YES;
        [attachmentItems addObject:attachmentItem];
    }
    if (attachmentItems.count > 0) {
        [self.allAttachmentsSections addObject:attachmentItems];
    }
}

- (void)loadAllDocumentAttachments:(FSPDFDoc*)document
{
    NSMutableArray<AttachmentItem*>* attachmentItems = [NSMutableArray<AttachmentItem*> array];
    FSPDFNameTree* nameTree = [FSPDFNameTree create:document type:e_nameTreeEmbeddedFiles];
    for (int i = 0; i < [nameTree getCount]; i ++) {
        NSString* name = [nameTree getName:i];
        FSPDFObject* dict = [nameTree getObj:name];
        if (dict && dict.getType == e_objDictionary) {
            FSFileSpec* file = [FSFileSpec create:document pdfObject:dict];
            if (file) {
                AttachmentItem* attachmentItem = [AttachmentItem itemWithDocumentAttachment:name file:file PDFPath:_extensionsManager.pdfReader.filePath];
                attachmentItem.currentlevel = 1;
                attachmentItem.isSecondLevel = YES;
                [attachmentItems addObject:attachmentItem];
            }
        }
    }
    if (attachmentItems.count > 0) {
        [self.allAttachmentsSections addObject:attachmentItems];
    }
}

- (void)resortAllAttachments
{
    if (self.allAttachmentsSections.count > 1) {
        [self.allAttachmentsSections sortUsingComparator:^NSComparisonResult(NSArray *obj1, NSArray *obj2) {
            AttachmentItem *attachmentItem1 = [obj1 objectAtIndex:0];
            AttachmentItem *attachmentItem2 = [obj2 objectAtIndex:0];
            if (attachmentItem2.isDocumentAttachment) {
                return NSOrderedAscending;
            } else if (attachmentItem1.isDocumentAttachment) {
                return NSOrderedDescending;
            } else {
                return attachmentItem1.pageIndex > attachmentItem2.pageIndex;
            }
        }];
    }
}

#pragma mark - methods


- (void)clearData
{
    if (self.loadAttachmentQueue) {
        [self.loadAttachmentQueue cancelAllOperations];
        [self.loadAttachmentQueue waitUntilAllOperationsAreFinished];
    }
    [self.allAttachmentsSections removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    self.indexPath = nil;
}

- (void)loadData
{
    if (!self.loadAttachmentQueue) {
        self.loadAttachmentQueue = [[NSOperationQueue alloc] init];
        if(OS_ISVERSION8)
            self.loadAttachmentQueue.qualityOfService = QOS_CLASS_UTILITY;
    }
    
    //load attachment annotations
    int pageCount = [_pdfViewCtrl.currentDoc getPageCount];
    NSBlockOperation* op = [[NSBlockOperation alloc] init];
    if(_extensionsManager.modulesConfig.loadAnnotations) {
        typeof(op) __weak weakOp = op;
        const int pagesPerExecution = 100;
        for (int pageStart = 0; pageStart < pageCount; pageStart += pagesPerExecution) {
            [op addExecutionBlock:^{
                for (int pageIndex = pageStart; pageIndex < pageStart + pagesPerExecution && pageIndex < pageCount; pageIndex ++) {
                    if (weakOp.isCancelled) {
                        return;
                    }
                    FSPDFPage* page = nil;
                    @try{
                        page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
                    }@catch(NSException* exception)
                    {
                        continue;
                    }
                    NSArray* annots = [Utility getAnnotationsOfType:e_annotFileAttachment inPage:page];
                    if (annots.count > 0) {
                        [self loadAllAnnotAttachments:annots];
                    }
                }
            }];
        }
    }

    typeof(self) __weak weakSelf = self;
    FSPDFDoc* doc = _pdfViewCtrl.currentDoc;
    op.completionBlock = ^{
        //load document attachments
        [weakSelf loadAllDocumentAttachments:doc];
        
        [weakSelf resortAllAttachments];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    };
    [self.loadAttachmentQueue addOperation:op];
}

// attachment could be a attachment annotation or a document attachment
- (void)deleteAnnotation:(AttachmentItem *)item
{
    if (self.editAnnoItem) {
        AnnotationListCell *cell = (AnnotationListCell*)[self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView* edittextview = (UITextView*)[cell.contentView viewWithTag:107];
        UILabel* labelContents = (UILabel*)[cell.contentView viewWithTag:104];
        [self tryRenameAttachment:self.editAnnoItem newName:edittextview.text addUndo:!self.editAnnoItem.isDocumentAttachment];
        self.editAnnoItem = nil;
        
        edittextview.hidden = YES;
        labelContents.hidden = NO;
        [edittextview resignFirstResponder];
        cell.isInputText = NO;
    }
    
    if (item.isDocumentAttachment) {
        [self _deleteDocumentAttachment:item addUndo:NO];
    }
    else
    {
        assert(item.annot);
        id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:item.annot];
        [annotHandler removeAnnot:item.annot];
        _extensionsManager.currentAnnot = nil;
    }
}

- (void)_deleteDocumentAttachment:(AttachmentItem*)attachmentItem addUndo:(BOOL)addUndo
{
    FSPDFNameTree* nameTree = [FSPDFNameTree create:_pdfViewCtrl.currentDoc type:e_nameTreeEmbeddedFiles];
    NSString* name = attachmentItem.keyName;
    if ([nameTree hasName:name]) {
        [nameTree removeObj:name];
    } else {
        // should never reach here
        assert(NO);
        return;
    }
    [self onDocumentAttachmentDeleted:attachmentItem];
    
    if (addUndo) {
        [_extensionsManager addUndoItem:[UndoItem itemWithUndo:^(UndoItem *item) {
            if (![nameTree hasName:name]) {
                FSFileSpec* fileSpec = [FSFileSpec create:_extensionsManager.pdfViewCtrl.currentDoc];
                [fileSpec setFileName:attachmentItem.fileName];
                assert(attachmentItem.filePath);
                [fileSpec embed:attachmentItem.filePath];
                if ([nameTree add:name pdfObj:[fileSpec getDict]]) {
                    [self onDocumentAttachmentAdded:attachmentItem];
                }
            }
        } redo:^(UndoItem *item) {
            [self _deleteDocumentAttachment:attachmentItem addUndo:NO];
        } pageIndex:-1]];
    }
}

- (void)saveAttachment:(AttachmentItem*)item
{
    NSMutableArray *needCopyFiles = [NSMutableArray array];
    
    FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
    selectDestination.isRootFileDirectory = YES;
    selectDestination.fileOperatingMode = FileListMode_SaveTo;
    [selectDestination loadFilesWithPath:DOCUMENT_PATH];
    selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder)
    {
        controller.cancelHandler = ^{
            _moveFileAlertCheckType = MoveFileAlertCheckType_Cancel;
        };
        _moveFileAlertCheckType = MoveFileAlertCheckType_Ask;
        [self copyFile:item toFolder:[destinationFolder objectAtIndex:0]];
        [controller dismissViewControllerAnimated:YES completion:nil];
    };
    UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
    selectDestinationNavController.delegate = selectDestination;
    selectDestinationNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    selectDestinationNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_pdfViewCtrl.window.rootViewController presentViewController:selectDestinationNavController animated:YES completion:nil];
}

- (void)copyFile:(AttachmentItem *)item toFolder:(NSString *)toFolder
{
    if (!item.fileName) {
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"kFailedSaveAttachmentBadFileName", nil)];
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:msg delegate:self cancelButtonTitle:@"kCancel" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString* srcFilePath = item.filePath;
    BOOL isDir = YES;
    if (![fileManager fileExistsAtPath:toFolder isDirectory:&isDir] || !isDir) {
        return;
    }
    NSString *destFilePath = [toFolder stringByAppendingPathComponent:item.fileName];
    if ([fileManager fileExistsAtPath:destFilePath]) {
        NSString *msg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"kSureToReplaceFile", @"FoxitLocalizable", nil), item.fileName];
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kFileAlreadyExists" message:msg delegate:self cancelButtonTitle:@"kCancel" otherButtonTitles:@"kReplace",nil];
        alertView.tag = 201;
        [alertView show];
        while (!_alertViewFinished) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        if (_moveFileAlertCheckType == MoveFileAlertCheckType_Cancel) {
            return;
        }
    }
    
    [fileManager removeItemAtPath:destFilePath error:nil];
    
    NSError *error = nil;
    BOOL isOK = YES;
    if ([fileManager fileExistsAtPath:srcFilePath isDirectory:nil]) {
        isOK = [fileManager copyItemAtPath:srcFilePath toPath:destFilePath error:&error];
    } else {
        isOK = [Utility loadFileSpec:item.fileSpec toPath:destFilePath];
    }
    if (!isOK) {
        NSString *msg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"kCopyFileFailed", @"FoxitLocalizable", nil), item.fileName, error.localizedDescription];
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:msg buttonClickHandler:^(UIView *alertView, int buttonIndex) {
        } cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 201)
    {
        if (buttonIndex == 0)  //cancel
        {
            _moveFileAlertCheckType = MoveFileAlertCheckType_Cancel;
        }
        else if (buttonIndex == 1)  //replace
        {
            _moveFileAlertCheckType = MoveFileAlertCheckType_Replace;
        }
        _alertViewFinished = YES;
    }
}

- (void)addNoteToAnnotation:(AttachmentItem *)item withIndexPath:(NSIndexPath *)indexPath
{
    if (self.editAnnoItem) {
        AnnotationListCell *cell = (AnnotationListCell*)[self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView* edittextview = (UITextView*)[cell.contentView viewWithTag:107];
        UILabel* labelContents = (UILabel*)[cell.contentView viewWithTag:104];
        [self tryRenameAttachment:self.editAnnoItem newName:edittextview.text addUndo:!self.editAnnoItem.isDocumentAttachment];
        self.editAnnoItem = nil;
        edittextview.hidden = YES;
        labelContents.hidden = NO;
        [edittextview resignFirstResponder];
        cell.isInputText = NO;
    }
    
    self.editAnnoItem = item;
    self.indexPath = indexPath;
    [self.tableView reloadData];
    AnnotationListCell* selectcell = (AnnotationListCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    selectcell.isInputText = YES;
    UITextView* edittextview = (UITextView*)[selectcell.contentView viewWithTag:107];
    edittextview.delegate = self;
    edittextview.hidden = NO;
    CGRect recr = edittextview.frame;
    
    UILabel* labelContents = (UILabel*)[selectcell.contentView viewWithTag:104];
    labelContents.hidden = YES;
    
    edittextview.text = labelContents.text;
    [edittextview scrollsToTop];
    [edittextview performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.3];
    
}

#pragma mark --- TextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        
        if (self.editAnnoItem) {
            [self tryRenameAttachment:self.editAnnoItem newName:textView.text addUndo:!self.editAnnoItem.isDocumentAttachment];
            self.editAnnoItem = nil;
        }
        
        UITableViewCell* selectcell = [self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView* edittextview = (UITextView*)[selectcell.contentView viewWithTag:107];
        edittextview.hidden = YES;
        UILabel* labelContents = (UILabel*)[selectcell.contentView viewWithTag:104];
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
    if (self.editAnnoItem) {
        [self tryRenameAttachment:self.editAnnoItem newName:textView.text addUndo:!self.editAnnoItem.isDocumentAttachment];
        self.editAnnoItem = nil;
    }
    
    AnnotationListCell* selectcell = (AnnotationListCell*)[self.tableView cellForRowAtIndexPath:self.indexPath];
    UITextView* edittextview = (UITextView*)[selectcell.contentView viewWithTag:107];
    edittextview.hidden = YES;
    UILabel* labelContents = (UILabel*)[selectcell.contentView viewWithTag:104];
    labelContents.hidden = NO;
    self.indexPath = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    [textView resignFirstResponder];
    selectcell.isInputText = NO;
}

- (void)tryRenameAttachment:(AttachmentItem*)attachmentItem newName:(NSString*)newName addUndo:(BOOL)addUndo
{
    if (attachmentItem.annot) {
        FSFileAttachment* annot = (FSFileAttachment*)attachmentItem.annot;
        NSString* oldName = annot.contents;
        if (![newName isEqualToString:oldName]) {
            attachmentItem.annot.contents = newName;
            NSDate* oldModifiedDate = annot.modifiedDate;
            NSDate* newModifiedDate = [NSDate date];
            annot.modifiedDate = newModifiedDate;
            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
            [annotHandler modifyAnnot:annot addUndo:NO];
            
            //add undo item
            if (addUndo) {
                FSPDFPage* page = [annot getPage];
                NSString* NM = annot.NM;
                [_extensionsManager addUndoItem:[UndoItem itemWithUndo:^(UndoItem *item) {
                    FSFileAttachment* annot = (FSFileAttachment*)[Utility getAnnotByNM:NM inPage:page];
                    if (annot) {
                        annot.contents = oldName;
                        annot.modifiedDate = oldModifiedDate;
                        [annotHandler modifyAnnot:annot addUndo:NO];
                    }
                } redo:^(UndoItem *item) {
                    FSFileAttachment* annot = (FSFileAttachment*)[Utility getAnnotByNM:NM inPage:page];
                    if (annot) {
                        annot.contents = newName;
                        annot.modifiedDate = newModifiedDate;
                        [annotHandler modifyAnnot:annot addUndo:NO];
                    }
                } pageIndex:annot.pageIndex]];

            }
        }
    }
    else
    {
        NSString* oldDescription = attachmentItem.description;
        if ( newName && [newName length] && ![newName isEqualToString:oldDescription]) {
            NSDate* oldModifiedDate = attachmentItem.modifyDate;
            NSDate* newModifiedDate = [NSDate date];
            @try {
                [attachmentItem.fileSpec setDescription:newName];
            } @catch (NSException *exception) {
                NSString *msg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"kFailedChangeDocumentAttachmentDescription", @"FoxitLocalizable", nil), exception.description];
                AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:msg buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                } cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
                [alertView show];
                return;
            }
            attachmentItem.description = newName;
            [attachmentItem.fileSpec setModifiedDateTime:[Utility convert2FSDateTime:newModifiedDate]];
            [self onDocumentAttachmentModified:attachmentItem];
            
            if (addUndo) {
                [_extensionsManager addUndoItem:[UndoItem itemWithUndo:^(UndoItem *item) {
                    attachmentItem.description = oldDescription;
                    [attachmentItem.fileSpec setDescription:oldDescription];
                    [attachmentItem.fileSpec setModifiedDateTime:[Utility convert2FSDateTime:oldModifiedDate]];
                    [self onDocumentAttachmentModified:attachmentItem];
                } redo:^(UndoItem *item) {
                    attachmentItem.description = newName;
                    [attachmentItem.fileSpec setDescription:newName];
                    [attachmentItem.fileSpec setModifiedDateTime:[Utility convert2FSDateTime:newModifiedDate]];
                    [self onDocumentAttachmentModified:attachmentItem];
                } pageIndex:-1]];
            }
        }
    }
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

#pragma mark -- keyboard
- (void)keyboardDidShow:(NSNotification *)note{
    
    [self.tableView scrollToRowAtIndexPath:self.indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark - IDocEventListener

- (void)onDocOpened:(FSPDFDoc* )document error:(int)error
{
    self.indexPath = nil;
    [self loadData];
}

- (void)onDocClosed:(FSPDFDoc* )document error:(int)error
{
}

- (void)onDocWillClose:(FSPDFDoc* )document
{
    [self clearData];
    
    self.tableView.frame = CGRectMake(0, 0, self.tableView.superview.frame.size.width, self.tableView.superview.frame.size.height);
}

#pragma mark IPageEventListener

- (void)onPagesRemoved:(NSArray<NSNumber*>*)indexes
{
    [self clearData];
    [self loadData];
}

- (void)onPagesMoved:(NSArray<NSNumber*>*)indexes dstIndex:(int)dstIndex
{
    [self clearData];
    [self loadData];
}

- (void)onPagesInsertedAtRange:(NSRange)range
{
    if (self.loadAttachmentQueue) {
        [self.loadAttachmentQueue cancelAllOperations];
        [self.loadAttachmentQueue waitUntilAllOperationsAreFinished];
    }
    [self.allAttachmentsSections removeAllObjects];
    
    self.indexPath = nil;
    
    [self loadData];
}

@end
