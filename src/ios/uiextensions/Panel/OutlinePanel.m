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

#import <FoxitRDK/FSPDFViewControl.h>

#import "OutlinePanel.h"
#import "PanelHost.h"
#import "IPanelSpec.h"
#import "UIExtensionsManager+Private.h"
#import "OutlineViewController.h"
#import "UIView+EnlargeEdge.h"
#import "UIButton+EnlargeEdge.h"
#import "ColorUtility.h"

@interface OutlinePanel () {
    PanelController* _panelController;
    FSPDFViewCtrl* _pdfViewControl;
    UIExtensionsManager* _extensionsManager;
}

@property (nonatomic, strong) UIView* toolbar;
@property (nonatomic, strong) UIView* contentView;
@property (nonatomic, strong) PanelButton* button;
@property (nonatomic, strong) OutlineViewController *outlineCtrl;
@property (nonatomic, strong) UINavigationController* navCtrl;

@end

@implementation OutlinePanel

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager panelController:(PanelController*)panelController
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewControl = extensionsManager.pdfViewCtrl;
        _panelController = panelController;
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 100, 25)];
        title.backgroundColor = [UIColor clearColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        title.text = NSLocalizedStringFromTable(@"kOutline", @"FoxitLocalizable", nil);
        title.textColor = [UIColor blackColor];
        self.toolbar = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64)];
        self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.toolbar.backgroundColor = [UIColor whiteColor];
        self.contentView = [[UIView alloc]initWithFrame:CGRectMake(0, 107, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 107)];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.button = [PanelButton buttonWithType:UIButtonTypeCustom];
        self.button.spec = self;
        self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [self.button setImage:[UIImage imageNamed:@"outline_VP"] forState:UIControlStateNormal];
        
        _outlineCtrl = [[OutlineViewController alloc] initWithStyle:UITableViewStylePlain pdfViewCtrl:_pdfViewControl panelController:_panelController];
        _outlineCtrl.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _outlineCtrl.view.backgroundColor = [UIColor clearColor];
        _outlineCtrl.hasParentOutline = NO;
        _outlineCtrl.outlineGotoPageHandler = ^(int page) {
        };
        
        self.navCtrl = [[UINavigationController alloc] initWithRootViewController:_outlineCtrl];
        self.navCtrl.view.frame = self.contentView.bounds;
        self.navCtrl.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        self.navCtrl.navigationBarHidden = YES;
        [self.contentView addSubview:self.navCtrl.view];
        title.center = CGPointMake(self.toolbar.bounds.size.width/2, title.center.y);
        
        UIView *divideView = [[UIView alloc] initWithFrame:CGRectMake(0, 106, [UIScreen mainScreen].bounds.size.width, [Utility realPX:1.0f])];
        divideView.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
        divideView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin;
        [self.toolbar addSubview:divideView];
        [self.toolbar addSubview:title];
        if (DEVICE_iPHONE) {
            UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 32, 12, 12)];
            [cancelButton addTarget:self action:@selector(cancelBookmark) forControlEvents:UIControlEventTouchUpInside];
            cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            [cancelButton setBackgroundImage:[UIImage imageNamed:@"panel_cancel"] forState:UIControlStateNormal];
            [cancelButton setEnlargedEdge:10];
            [self.toolbar addSubview:cancelButton];
        }
    }
    return self;
}

- (void)load
{
    [_pdfViewControl registerDocEventListener:self];
    [_pdfViewControl registerPageEventListener:self];
    [_panelController.panel addSpec:self];
    _panelController.panel.currentSpace = self;
}

- (void)cancelBookmark
{
    _panelController.isHidden = YES;
}

- (void)onDocWillOpen
{
}

- (void)onDocOpened:(FSPDFDoc* )document error:(int)error
{
   [_outlineCtrl loadData:nil];
}

- (void)onDocWillClose:(FSPDFDoc* )document
{
}

- (void)onDocClosed:(FSPDFDoc* )document error:(int)error
{
    [_outlineCtrl clearData];
    
}

-(void)onDocWillSave:(FSPDFDoc* )document
{
}

-(int)getTag
{
    return 2;
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

#pragma mark IPageEventListener
- (void)onPagesWillRemove:(NSArray<NSNumber*>*)indexes
{
}

- (void)onPagesWillMove:(NSArray<NSNumber*>*)indexes dstIndex:(int)dstIndex
{
}

- (void)onPagesWillRotate:(NSArray<NSNumber*>*)indexes rotation:(int)rotation
{
}

- (void)onPagesRemoved:(NSArray<NSNumber*>*)indexes
{
    [_outlineCtrl clearData];
    [_outlineCtrl loadData:nil];
}

- (void)onPagesMoved:(NSArray<NSNumber*>*)indexes dstIndex:(int)dstIndex
{
    [_outlineCtrl clearData];
    [_outlineCtrl loadData:nil];
}

- (void)onPagesRotated:(NSArray<NSNumber*>*)indexes rotation:(int)rotation
{
}

@end
