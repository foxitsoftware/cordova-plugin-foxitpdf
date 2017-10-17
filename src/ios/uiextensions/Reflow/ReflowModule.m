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

#import "ReflowModule.h"
#import "PanelController+private.h"
#import "SettingBar+private.h"
#import "UIExtensionsManager+Private.h"
#import "Utility.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface ReflowModule ()

@property (nonatomic, strong) TbBaseBar *topToolbar;
@property (nonatomic, strong) TbBaseItem *backItem;
@property (nonatomic, strong) TbBaseItem *titleItem;

@property (strong, nonatomic) UIView *viewTopReflow;
@property (strong, nonatomic) IBOutlet UIToolbar *toolBarBottomReflow;
@property (strong, nonatomic) IBOutlet UIButton *bookmark;
@property (strong, nonatomic) IBOutlet UIButton *bigger;
@property (strong, nonatomic) IBOutlet UIButton *smaller;
@property (strong, nonatomic) IBOutlet UIButton *showGraph;
@property (strong, nonatomic) IBOutlet UIButton *previousPage;
@property (strong, nonatomic) IBOutlet UIButton *nextPage;

@property (assign, nonatomic) BOOL needShowImageForReflow;
@property (assign, nonatomic) BOOL isReflowBarShowing;
@property (assign, nonatomic) BOOL isReflowByClick;

@end

@implementation ReflowModule {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;

    PDF_LAYOUT_MODE currentPageLayoutMode;
    PDF_LAYOUT_MODE oldPageLayoutMode;
}

- (NSString *)getName {
    return @"Reflow";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;

        [self loadModule];
    }
    return self;
}

- (void)loadModule {
    [_pdfViewCtrl registerGestureEventListener:self];
    [_extensionsManager registerStateChangeListener:self];
    [_pdfViewCtrl registerDocEventListener:self];
    [_pdfViewCtrl registerPageEventListener:self];
}

- (void)enterReflowMode:(BOOL)flag {
    if (flag) {
        currentPageLayoutMode = [_pdfViewCtrl getPageLayoutMode];
        oldPageLayoutMode = currentPageLayoutMode;
        [_extensionsManager changeState:STATE_REFLOW];
        [_pdfViewCtrl setPageLayoutMode:PDF_LAYOUT_MODE_REFLOW];
        _isReflowByClick = YES;
        if (!self.needShowImageForReflow) {
            [self.showGraph setImage:[UIImage imageNamed:@"reflow_graphD.png"] forState:UIControlStateNormal];
            [_pdfViewCtrl setReflowMode:PDF_REFLOW_ONLYTEXT];
        } else {
            [self.showGraph setImage:[UIImage imageNamed:@"reflow_graph.png"] forState:UIControlStateNormal];
            [_pdfViewCtrl setReflowMode:PDF_REFLOW_WITHIMAGE];
        }
    } else {
        [self showReflowBar:NO animation:YES];
        [_extensionsManager changeState:STATE_NORMAL];
        ((UIButton *) [_extensionsManager.settingBar getItemView:REFLOW]).selected = NO;
        currentPageLayoutMode = oldPageLayoutMode;
        if (currentPageLayoutMode == PDF_LAYOUT_MODE_UNKNOWN) {
            currentPageLayoutMode = PDF_LAYOUT_MODE_SINGLE;
        }
        if (!_isReflowByClick) {
            currentPageLayoutMode = PDF_LAYOUT_MODE_SINGLE;
        }
        [_pdfViewCtrl setPageLayoutMode:currentPageLayoutMode];
    }
    self.bigger.enabled = ([_pdfViewCtrl getZoom] < 5.0f);
    self.smaller.enabled = ([_pdfViewCtrl getZoom] > 1.0f);
    [self setPreviousAndNextBtnEnable];
}

- (UIView *)viewTopReflow {
    if (!_viewTopReflow) {
        self.topToolbar = [[TbBaseBar alloc] init];
        self.topToolbar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];

        self.backItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"common_back_black"] imageSelected:[UIImage imageNamed:@"common_back_black"] imageDisable:[UIImage imageNamed:@"common_back_black"]]; // assign to var to keep a strong reference, can't directly assign to weak property of self
        [self.topToolbar.contentView addSubview:self.backItem.contentView];
        CGSize size = self.backItem.contentView.frame.size;
        [self.backItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.backItem.contentView.superview.mas_left).offset(10);
            make.centerY.mas_equalTo(self.backItem.contentView.superview.mas_centerY).offset(10);
            make.width.mas_equalTo(size.width);
            make.height.mas_equalTo(size.height);
        }];
        __weak typeof(self) weakSelf = self;
        self.backItem.onTapClick = ^(TbBaseItem *item) {
            [weakSelf cancelButtonClicked];
        };

        self.titleItem = [TbBaseItem createItemWithTitle:FSLocalizedString(@"kReflow")]; // assign to var to keep a strong reference, can't directly assign to weak property of self
        self.titleItem.textColor = [UIColor colorWithRGBHex:0xff3f3f3f];
        self.titleItem.enable = NO;
        [self.topToolbar.contentView addSubview:self.titleItem.contentView];
        size = self.titleItem.contentView.frame.size;
        [self.titleItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(self.titleItem.contentView.superview.mas_centerX);
            make.centerY.mas_equalTo(self.titleItem.contentView.superview.mas_centerY).offset(10);
            make.width.mas_equalTo(size.width);
            make.height.mas_equalTo(size.height);
        }];

        self.viewTopReflow = _topToolbar.contentView;

        [_pdfViewCtrl insertSubview:_viewTopReflow aboveSubview:[_pdfViewCtrl getDisplayView]];
        [self.topToolbar.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(_viewTopReflow.superview.mas_left);
            make.right.mas_equalTo(_viewTopReflow.superview.mas_right);
            make.top.mas_equalTo(_viewTopReflow.superview.mas_top);
            make.height.mas_equalTo(64);
        }];
        _viewTopReflow.hidden = YES;
    }
    return _viewTopReflow;
}

- (UIToolbar *)toolBarBottomReflow {
    if (!_toolBarBottomReflow) {
        NSArray *nib1 = [[NSBundle mainBundle] loadNibNamed:@"ToolbarBottomReflow" owner:self options:nil];
        UIView *tmpCustomView1 = [nib1 objectAtIndex:0];
        self.toolBarBottomReflow = (UIToolbar *) tmpCustomView1;
        [self.bookmark setImage:[UIImage imageNamed:@"reflow_bookmark.png"] forState:UIControlStateNormal];
        if (_extensionsManager.panelController.panel.spaces.count == 0) {
            self.bookmark.enabled = NO;
        }
        [self.bigger setImage:[UIImage imageNamed:@"reflow_bigger.png"] forState:UIControlStateNormal];
        [self.bigger setImage:[UIImage imageNamed:@"reflow_biggerD.png"] forState:UIControlStateDisabled];
        [self.smaller setImage:[UIImage imageNamed:@"reflow_smaller.png"] forState:UIControlStateNormal];
        [self.smaller setImage:[UIImage imageNamed:@"reflow_smallerD.png"] forState:UIControlStateDisabled];
        [self.showGraph setImage:[UIImage imageNamed:@"reflow_graph.png"] forState:UIControlStateNormal];
        [self.previousPage setImage:[UIImage imageNamed:@"reflow_pre.png"] forState:UIControlStateNormal];
        [self.previousPage setImage:[UIImage imageNamed:@"reflow_preD.png"] forState:UIControlStateDisabled];
        [self.nextPage setImage:[UIImage imageNamed:@"reflow_next.png"] forState:UIControlStateNormal];
        [self.nextPage setImage:[UIImage imageNamed:@"reflow_nextD.png"] forState:UIControlStateDisabled];

        self.needShowImageForReflow = YES;

        [_pdfViewCtrl insertSubview:_toolBarBottomReflow aboveSubview:[_pdfViewCtrl getDisplayView]];
        [_toolBarBottomReflow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(_toolBarBottomReflow.superview.mas_left);
            make.right.mas_equalTo(_toolBarBottomReflow.superview.mas_right);
            make.bottom.mas_equalTo(_toolBarBottomReflow.superview.mas_bottom);
            make.height.mas_equalTo(44);
        }];
        self.toolBarBottomReflow.hidden = YES;
    }
    return _toolBarBottomReflow;
}

- (void)showReflowBar:(BOOL)isShow animation:(BOOL)animation {
    if (self.viewTopReflow.hidden != isShow) {
        return;
    }
    self.viewTopReflow.hidden = !isShow;
    self.toolBarBottomReflow.hidden = !isShow;
    if (animation) {
        [Utility addAnimation:_viewTopReflow.layer type:_viewTopReflow.hidden ? kCATransitionReveal : kCATransitionMoveIn subType:_viewTopReflow.hidden ? kCATransitionFromTop : kCATransitionFromBottom timeFunction:kCAMediaTimingFunctionEaseInEaseOut duration:0.3];
        [Utility addAnimation:_toolBarBottomReflow.layer type:_toolBarBottomReflow.hidden ? kCATransitionReveal : kCATransitionMoveIn subType:_toolBarBottomReflow.hidden ? kCATransitionFromBottom : kCATransitionFromTop timeFunction:kCAMediaTimingFunctionEaseInEaseOut duration:0.3];
    }
}

#pragma buttonClickEvent-- - Click on the button below
- (IBAction)bookmarkClicked:(id)sender {
    _extensionsManager.hiddenPanel = NO;
}

- (IBAction)biggerClicked:(id)sender {
    [_pdfViewCtrl setZoom:[_pdfViewCtrl getZoom] * 1.5f];
    self.bigger.enabled = ([_pdfViewCtrl getZoom] < 5.0f);
    self.smaller.enabled = YES;
}

- (IBAction)smallerClicked:(id)sender {
    [_pdfViewCtrl setZoom:[_pdfViewCtrl getZoom] * 0.75f];
    self.smaller.enabled = ([_pdfViewCtrl getZoom] > 1.0f);
    self.bigger.enabled = YES;
}

- (IBAction)showGraphClicked:(id)sender {
    if (self.needShowImageForReflow) {
        [self.showGraph setImage:[UIImage imageNamed:@"reflow_graphD.png"] forState:UIControlStateNormal];
        [_pdfViewCtrl setReflowMode:PDF_REFLOW_ONLYTEXT];
    } else {
        [self.showGraph setImage:[UIImage imageNamed:@"reflow_graph.png"] forState:UIControlStateNormal];
        [_pdfViewCtrl setReflowMode:PDF_REFLOW_WITHIMAGE];
    }
    self.needShowImageForReflow = !self.needShowImageForReflow;
}

- (IBAction)previousPageClicked:(id)sender {
    [_pdfViewCtrl gotoPrevPage:NO];
    [self setPreviousAndNextBtnEnable];
}

- (IBAction)nextPageClicked:(id)sender {
    [_pdfViewCtrl gotoNextPage:NO];
    [self setPreviousAndNextBtnEnable];
}

- (void)cancelButtonClicked {
    [self enterReflowMode:NO];
}

- (void)setPreviousAndNextBtnEnable {
    if ([_pdfViewCtrl getCurrentPage] <= 0) {
        self.previousPage.enabled = NO;
    } else {
        self.previousPage.enabled = YES;
    }

    if ([_pdfViewCtrl getCurrentPage] >= [_pdfViewCtrl getPageCount] - 1) {
        self.nextPage.enabled = NO;
    } else {
        self.nextPage.enabled = YES;
    }
}

#pragma mark IDocEventListener

- (void)onDocWillOpen {
    _isReflowByClick = NO;
}

#pragma IGestureEventListener

- (BOOL)onTap:(UITapGestureRecognizer *)recognizer {
    if ([_extensionsManager getState] == STATE_REFLOW) {
        if (self.viewTopReflow.hidden) {
            [self showReflowBar:YES animation:YES];
            _extensionsManager.isFullScreen = NO;
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
        } else {
            [self showReflowBar:NO animation:YES];
            _extensionsManager.isFullScreen = YES;
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
        }
        return YES;
    }
    return NO;
}

- (BOOL)onLongPress:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

#pragma IStateChangeListener

- (void)onStateChanged:(int)state {
    if (state == STATE_REFLOW) {
        [self showReflowBar:YES animation:YES];
        self.bigger.enabled = ([_pdfViewCtrl getZoom] < 5.0f);
        self.smaller.enabled = ([_pdfViewCtrl getZoom] > 1.0f);
        [self setPreviousAndNextBtnEnable];
    }
}

#pragma IPageEventListener

- (void)onPageChanged:(int)oldIndex currentIndex:(int)currentIndex {
    [self setPreviousAndNextBtnEnable];
}

@end
