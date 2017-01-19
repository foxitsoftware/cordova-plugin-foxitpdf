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
#import "AnnotationPanel.h"
#import "UIExtensionsManager+Private.h"
#import "PanelHost.h"
#import "Masonry.h"
#import "AnnotationPanel.h"
#import "AnnotationListViewController.h"
#import "AnnotationStruct.h"
#import "UIView+EnlargeEdge.h"
#import "UIButton+EnlargeEdge.h"

#define ENLARGE_EDGE 3


@interface AnnotationPanel ()<IPageEventListener> {
    FSPDFViewCtrl* _pdfViewControl;
    UIExtensionsManager* _extensionsManager;
}

@property (nonatomic, strong) UIView* toolbar;
@property (nonatomic, strong) UIView* contentView;
@property (nonatomic, strong) PanelButton* button;


@end

@implementation AnnotationPanel

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager panelController:(PanelController*)panelController
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewControl = extensionsManager.pdfViewCtrl;
        _panelController = panelController;
        [AnnotationStruct setViewControl:_pdfViewControl];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 100, 25)];
        title.backgroundColor = [UIColor clearColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        title.text = NSLocalizedString(@"kAnnotation", nil);
        title.textColor = [UIColor blackColor];
        
       
        self.toolbar = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64)];
        self.toolbar.backgroundColor = [UIColor whiteColor];
        self.contentView = [[UIView alloc]init];
        self.button = [PanelButton buttonWithType:UIButtonTypeCustom];
        self.button.spec = self;
        self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [self.button setImage:[UIImage imageNamed:@"Annotation_VP"] forState:UIControlStateNormal];
        
        self.annotationCtrl = [[AnnotationListViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:extensionsManager module:self];
        [panelController registerPanelChangedListener:self.annotationCtrl];
        _annotationCtrl.annotationGotoPageHandler = ^(int page, NSString *annotuuid)
        {
            
        };
        _annotationCtrl.annotationSelectionHandler = ^()
        {
            
        };
        
        UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 32, 12, 12)];
        [cancelButton addTarget:self action:@selector(cancelBookmark) forControlEvents:UIControlEventTouchUpInside];
        cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        UIImage *bcakgrdImg = [UIImage imageNamed:@"panel_cancel.png"];
        [cancelButton setBackgroundImage:bcakgrdImg forState:UIControlStateNormal];
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelBookmark)];
        backgroundView.userInteractionEnabled = YES;
        [backgroundView addGestureRecognizer:tapG];
        [self.toolbar addSubview:backgroundView];
        
        self.editButton = [[UIButton alloc] initWithFrame:CGRectMake(self.toolbar.frame.size.width -65, 20, 55, 35)];
        [_editButton addTarget:self action:@selector(clearAnnotations) forControlEvents:UIControlEventTouchUpInside];
        [_editButton setTitleColor:[UIColor colorWithRed:0/255.f green:150.f/255.f blue:212.f/255.f alpha:1] forState:UIControlStateNormal];
        [_editButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        [_editButton setTitle:NSLocalizedString(@"kClear", nil) forState:UIControlStateNormal];
        _editButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [_editButton setEnlargedEdge:ENLARGE_EDGE];
       [self.contentView addSubview:_annotationCtrl.view];
        [_annotationCtrl.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView.mas_left).offset(0);
            make.right.equalTo(self.contentView.mas_right).offset(0);
            make.top.equalTo(self.contentView.mas_top).offset(0);
            make.bottom.equalTo(self.contentView.mas_bottom).offset(0);
        }];
        title.center = CGPointMake(self.toolbar.bounds.size.width/2, title.center.y);
       [self.toolbar addSubview:title];
       [self.toolbar addSubview:_editButton];
        if (DEVICE_iPHONE) {
            [backgroundView addSubview:cancelButton];
        }
    }
    return self;
}

- (void)load
{
    [_pdfViewControl registerDocEventListener:self];
    [_pdfViewControl registerPageEventListener:self];
    [_panelController.panel addSpec:self];
}

- (void)cancelBookmark
{
    _panelController.isHidden = YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex

{
    switch (buttonIndex) {
        case 0:
            [_annotationCtrl clearAnnotations];
            break;
        case 1:
            break;
    }
}

- (void)clearAnnotations
{
    if ([_annotationCtrl getAnnotationsCount] > 0)
    {
        UIAlertView* alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"kConfirm",nil) message:NSLocalizedString(@"kClearAnnotations",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"kYes",nil) otherButtonTitles:NSLocalizedString(@"kNo",nil),nil];
        [alert show];
        [alert release];
    }
}

- (void)onDocWillOpen
{
}

- (void)onDocOpened:(FSPDFDoc* )document error:(int)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_annotationCtrl viewWillAppear:YES];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:_annotationCtrl selector:@selector(UpdateAnnotationsTotal:) name:ANNOLIST_UPDATETOTAL object:nil];
        _annotationCtrl.allCanModify = YES;
        _annotationCtrl.indexPath = nil;
        [_annotationCtrl clearData];
        [_annotationCtrl loadData:YES];
    });
}

- (void)onDocWillClose:(FSPDFDoc* )document
{
    if([AnnotationStruct isThreadRunning])
        [AnnotationStruct setStopThreadFlag];
    [_annotationCtrl ResetAnnotationArray];
}

- (void)onDocClosed:(FSPDFDoc* )document error:(int)error
{
    _annotationCtrl.allCanModify = YES;
    _annotationCtrl.annoupdatetipLB.hidden = YES;
    _annotationCtrl.tableView.frame = CGRectMake(0, 0, _annotationCtrl.tableView.superview.frame.size.width, _annotationCtrl.tableView.superview.frame.size.height);

    [[NSNotificationCenter defaultCenter] removeObserver:_annotationCtrl name:ANNOLIST_UPDATETOTAL object:nil];
    
}


- (void)onDocWillSave:(FSPDFDoc* )document
{
    
}

-(int)getTag
{
    return 3;
}

-(PanelButton*)getButton
{
    return self.button;
}
-(UIView*)getTopToolbar
{
    return self.toolbar;
}
-(UIView*)getContentView
{
    return self.contentView;
}

-(void)onActivated
{
    
}

-(void)onDeactivated
{
    
}

@end
