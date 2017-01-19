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
#import "SettingBarController.h"
#import "SettingBar.h"
#import "UIExtensionsSharedHeader.h"

@implementation SettingBarController {
    UIView* _superView;
    UIControl* _maskView;
}

-(instancetype)initWithPDFViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl
{
    self = [super init];
    if (self) {
        _superView = pdfViewCtrl;
        
        _maskView = [[UIControl alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
        
        CGRect screenFrame = [UIScreen mainScreen].bounds;
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            screenFrame = CGRectMake(0, 0, screenFrame.size.height, screenFrame.size.width);
        }

        self.settingBar = [[[SettingBar alloc] initWithPDFViewCtrl:pdfViewCtrl moreSettingBarController:self] autorelease];
        self.settingBar.contentView.frame = CGRectMake(0, screenFrame.size.height-250, screenFrame.size.width, DEVICE_iPHONE ? 240 : 200);
        self.settingBar.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        [_superView addSubview:self.settingBar.contentView];
        self.hiddenSettingBar = YES;
    }
    return self;
}

- (void)dealloc
{
    [_settingBar release];
    
    [super dealloc];
}

-(void)onLayoutModeChanged:(PDF_LAYOUT_MODE)oldLayoutMode newLayoutMode:(PDF_LAYOUT_MODE)newLayoutMode
{
    if (DEVICE_iPHONE) {
        self.settingBar.singleView_iphone.selected = (newLayoutMode == PDF_LAYOUT_MODE_SINGLE?YES:NO);
    }
    else
    {
        self.settingBar.singleView_ipad.selected = (newLayoutMode == PDF_LAYOUT_MODE_SINGLE?YES:NO);
    }
    
    if (DEVICE_iPHONE) {
        self.settingBar.continueView_iphone.selected = (newLayoutMode == PDF_LAYOUT_MODE_CONTINUOUS?YES:NO);
    }
    else
    {
        self.settingBar.continueView_ipad.selected = (newLayoutMode == PDF_LAYOUT_MODE_CONTINUOUS?YES:NO);
    }
    
    self.settingBar.doubleView_ipad.selected = (newLayoutMode == PDF_LAYOUT_MODE_TWO?YES:NO);
    
    if (DEVICE_iPHONE) {
        self.settingBar.thumbnailView_iphone.selected = (newLayoutMode == PDF_LAYOUT_MODE_MULTIPLE?YES:NO);
    }
    else
    {
        self.settingBar.thumbnailView_ipad.selected = (newLayoutMode == PDF_LAYOUT_MODE_MULTIPLE?YES:NO);
    }
}

-(void)setHiddenSettingBar:(BOOL)hiddenSettingBar
{
    if (_hiddenSettingBar == hiddenSettingBar) {
        return;
    }
    _hiddenSettingBar = hiddenSettingBar;
    if (hiddenSettingBar)
    {
        [UIView animateWithDuration:0.4 animations:^{
            _maskView.alpha = 0.1f;
        } completion:^(BOOL finished) {
            
            [_maskView removeFromSuperview];
        }];
        
        CGRect newFrame = self.settingBar.contentView.frame;
        newFrame.origin.y = [UIScreen mainScreen].bounds.size.height;
        [UIView animateWithDuration:0.4 animations:^{
            self.settingBar.contentView.frame = newFrame;
            [self.settingBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(_superView.mas_bottom).offset(0);
                make.left.equalTo(_superView.mas_left).offset(0);
                make.right.equalTo(_superView.mas_right).offset(0);
                make.height.mas_equalTo(self.settingBar.contentView.frame.size.height);
            }];
        }];
    }
    else
    {
        _maskView.frame = [UIScreen mainScreen].bounds;
        _maskView.backgroundColor = [UIColor blackColor];
        _maskView.alpha = 0.3f;
        _maskView.tag = 203;
        [_maskView addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
        
        [_superView insertSubview:_maskView belowSubview:self.settingBar.contentView];
        [_maskView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_maskView.superview.mas_left).offset(0);
            make.right.equalTo(_maskView.superview.mas_right).offset(0);
            make.top.equalTo(_maskView.superview.mas_top).offset(0);
            make.bottom.equalTo(_maskView.superview.mas_bottom).offset(0);
        }];
        
        CGRect newFrame = self.settingBar.contentView.frame;
        newFrame.origin.y = [UIScreen mainScreen].bounds.size.height - newFrame.size.height;
        [UIView animateWithDuration:0.4 animations:^{
            self.settingBar.contentView.frame = newFrame;
            [self.settingBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(_superView.mas_bottom).offset(0);
                make.left.equalTo(_superView.mas_left).offset(0);
                make.right.equalTo(_superView.mas_right).offset(0);
                make.height.mas_equalTo(self.settingBar.contentView.frame.size.height);
            }];
        }];
    }
}

-(void)dismiss:(id)sender
{
    self.hiddenSettingBar = YES;
}


@end
