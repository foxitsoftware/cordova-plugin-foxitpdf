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

#import "SettingBar.h"
#import "../Thirdparties/ColorUtility/ColorUtility.h"
#import "../Thirdparties/Masonry/Masonry.h"
#import "SettingBar+private.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

typedef NS_ENUM(NSUInteger, KDividLineType) {
    KDividLineTypeHorizontal,
    KDividLineTypeVertical
};

@interface SettingBar () <IDocEventListener>

@property (nonatomic, weak) FSPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, weak) UIExtensionsManager *extensionsManager;

@property (nonatomic, strong) UISlider *brightnessControl;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UILabel *brightnessLabel;
@property (nonatomic, strong) UIImageView *brightnessBigger;
@property (nonatomic, strong) UIImageView *brightnessSmaller;

@property (nonatomic, assign) float tempSysBrightness;
@property (nonatomic, assign) BOOL isEnterBg;
@property (nonatomic, assign) BOOL isActive;

@property (nonatomic, assign) BOOL isBrightnessManual;
@property (nonatomic, assign) BOOL isNightMode;
@property (nonatomic, assign) BOOL isScreenLocked;

@property (nonatomic, strong) NSMutableArray *bottomButtonArr;
@property (nonatomic, strong) UIView *levelTopView;
@property (nonatomic, strong) UIView *levelSecondView;
@property (nonatomic, strong) UIView *levelThirdView;
@property (nonatomic, strong) UIView *levelBottomView;
@property (nonatomic, strong) NSMutableArray *tempTopButtonArr;

@property (nonatomic, strong) UIView *ipadTopView;
@property (nonatomic, strong) UIView *brightnessSwitchView;
@property (nonatomic, strong) UIView *brightnessSliderView;
@property (nonatomic, strong) UIView *nightButtonView;
@property (nonatomic, strong) NSMutableArray *ipadTopButtonArr;
@property (nonatomic, assign) CGRect contentViewFrame;

@property (nonatomic, strong) UISwitch *brightnessSwitch;
@end

@implementation SettingBar

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        self.pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [self.pdfViewCtrl registerDocEventListener:self];
        self.extensionsManager = extensionsManager;
        _isBrightnessManual = NO;
        self.isEnterBg = NO;
        self.isActive = NO;
        
        self.tempSysBrightness = [UIScreen mainScreen].brightness;
        
        UIDevice *device = [UIDevice currentDevice];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:device];
        
        CGRect screenFrame = _pdfViewCtrl.bounds;
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            screenFrame = CGRectMake(0, 0, screenFrame.size.height, screenFrame.size.width);
        }
        
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, screenFrame.size.height - 250, screenFrame.size.width, DEVICE_iPHONE ? 240 : 200)];
        self.contentView.backgroundColor = [UIColor whiteColor];
        _contentViewFrame = self.contentView.frame;
        
        self.reflowBtn = [SettingBar createItemWithImageAndTitle:FSLocalizedString(@"kReflow") imageNormal:[UIImage imageNamed:@"readview_reflow_normal"] imageSelected:[UIImage imageNamed:@"readview_reflow_selected"] imageDisable:[UIImage imageNamed:@"readview_reflow_selected"]];
        
        self.cropBtn = [SettingBar createItemWithImageAndTitle:FSLocalizedString(@"kCropMode") imageNormal:[UIImage imageNamed:@"readview_crop_normal"] imageSelected:[UIImage imageNamed:@"readview_crop_selected"] imageDisable:[UIImage imageNamed:@"readview_crop_selected"]];
        
        self.screenLockBtn = [SettingBar createItemWithImageAndTitle:FSLocalizedString(@"kScreenLock") imageNormal:[UIImage imageNamed:@"readview_screen_lock_normal"] imageSelected:[UIImage imageNamed:@"readview_screen_lock_selected"] imageDisable:[UIImage imageNamed:@"readview_screen_lock_selected"]];
        
        NSString *kAutoBrightness = FSLocalizedString(@"kAutoBrightness");
        CGSize titleSize = [Utility getTextSize:kAutoBrightness fontSize:15.0f maxSize:CGSizeMake(200, 100)];
        
        self.brightnessLabel = [[UILabel alloc] init];
        self.brightnessLabel.text = kAutoBrightness;
        self.brightnessLabel.font = [UIFont systemFontOfSize:15.0f];
        
        self.brightnessSwitch = [[UISwitch alloc] init];
   
        UIImage *smaller = [UIImage imageNamed:@"readview_brightness_smaller"];
        UIImage *bigger = [UIImage imageNamed:@"readview_brightness_bigger"];
        
        self.brightnessSmaller = [[UIImageView alloc] initWithImage:smaller];
        self.brightnessBigger = [[UIImageView alloc] initWithImage:bigger];

        self.brightnessControl = [[UISlider alloc] init];
        [self.brightnessControl setThumbImage:[UIImage imageNamed:@"property_linewidth_slider.png"] forState:UIControlStateNormal];
        [self.brightnessControl setThumbImage:[UIImage imageNamed:@"property_linewidth_slider.png"] forState:UIControlStateDisabled];
        self.brightnessControl.minimumValue = 0.2f;
        self.brightnessControl.enabled = !self.brightnessSwitch.on;
   
        UIImage *nightImageNormal = [UIImage imageNamed:@"readview_night_normal"];
        self.nightViewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.nightViewBtn setImage:[UIImage imageNamed:@"readview_night_normal"] forState:UIControlStateNormal];
        [self.nightViewBtn setImage:[UIImage imageNamed:@"readview_night_selected"] forState:UIControlStateHighlighted];
        [self.nightViewBtn setImage:[UIImage imageNamed:@"readview_night_selected"] forState:UIControlStateSelected];
        
        self.doubleViewBtn = [[UIButton alloc] init];
  
        if (DEVICE_iPHONE) {
            _levelTopView = [[UIView alloc] init];
            [self.contentView addSubview:_levelTopView];
            
            NSDictionary *singleViewBtnInfo = @{@"type" : @0,
                                                  @"normalImage" :@"readview_mode_bg_normal",
                                                  @"selectedImage" :@"readview_mode_bg_selected",
                                                  @"title" : @"kViewModeSingle",
                                                  @"normalTitleColor" : @0x000000,
                                                  @"higinlightTitleColor" : @0xffffff,
                                                  @"selectTitleColor" : @0xffffff,
                                                  @"titleFont" : @12.f,
                                                  @"isIphone" : DEVICE_iPHONE ? @"y" : @"n"};
            
            NSDictionary *continueViewBtninfo = @{@"type" : @0,
                                                     @"normalImage" :@"readview_mode_bg_normal",
                                                     @"selectedImage" :@"readview_mode_bg_selected",
                                                     @"title" : @"kViewModeContinuous",
                                                     @"normalTitleColor" : @0x000000,
                                                     @"higinlightTitleColor" : @0xffffff,
                                                     @"selectTitleColor" : @0xffffff,
                                                     @"titleFont" : @12.f,
                                                     @"isIphone" : DEVICE_iPHONE ? @"y" : @"n"};
            
            NSDictionary *thumbnailViewBtnInfo = @{@"type" : @0,
                                                      @"normalImage" :@"readview_mode_bg_normal",
                                                      @"selectedImage" :@"readview_mode_bg_selected",
                                                      @"title" : @"kViewModeThumbnail",
                                                      @"normalTitleColor" : @0x000000,
                                                      @"higinlightTitleColor" : @0xffffff,
                                                      @"selectTitleColor" : @0xffffff,
                                                      @"titleFont" : @12.f,
                                                      @"isIphone" : DEVICE_iPHONE ? @"y" : @"n"};
            NSArray *levelTopArr = [NSArray array];

            if (self.extensionsManager.modulesConfig.loadThumbnail) {
                levelTopArr = @[singleViewBtnInfo,continueViewBtninfo,thumbnailViewBtnInfo];
            }else{
                levelTopArr = @[singleViewBtnInfo,continueViewBtninfo];
            }
            
            _tempTopButtonArr = [[NSMutableArray alloc] init];
            int i = 0;
            for (i; i < levelTopArr.count; i++ ) {
                NSDictionary *buttoninfo = [levelTopArr objectAtIndex:i];
                
                UIButton *button = [self createButtonWith:buttoninfo];
                [_tempTopButtonArr addObject:button];
            }
            
            self.singleViewBtn = (UIButton *)[_tempTopButtonArr objectAtIndex:0];
            self.continueViewBtn = (UIButton *)[_tempTopButtonArr objectAtIndex:1];
            
            if (self.extensionsManager.modulesConfig.loadThumbnail) {
                self.thumbnailViewBtn = (UIButton *)[_tempTopButtonArr objectAtIndex:2];
                [_levelTopView addSubview:self.thumbnailViewBtn];
            }
            
            [_levelTopView addSubview:self.singleViewBtn];
            [_levelTopView addSubview:self.continueViewBtn];
            
            _levelBottomView = [[UIView alloc] init];
            [self.contentView addSubview:_levelBottomView];
    
            [_levelBottomView addSubview:self.reflowBtn];
            [_levelBottomView addSubview:self.screenLockBtn];
            [_levelBottomView addSubview:self.cropBtn];
            
            _levelSecondView = [[UIView alloc] init];
            [self.contentView addSubview:_levelSecondView];
            
            [_levelSecondView addSubview:self.brightnessLabel];
            [_levelSecondView addSubview:self.brightnessSwitch];
            
            _levelThirdView = [[UIView alloc] init];
            [self.contentView addSubview:_levelThirdView];
            
            [_levelThirdView addSubview:self.brightnessSmaller];
            [_levelThirdView addSubview:self.brightnessBigger];
            [_levelThirdView addSubview:self.brightnessControl];
            
            [self.contentView addSubview:self.nightViewBtn];
            
            UIView *divideView = [self makeDividLine:CGRectMake(0, 0, CGRectGetWidth(_pdfViewCtrl.bounds), [Utility realPX:1.0f]) withColor:0xe6e6e6 andDirection:KDividLineTypeHorizontal];
            [_levelTopView addSubview:divideView];
            [divideView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(divideView.superview);
                make.right.mas_equalTo(divideView.superview);
                make.height.mas_equalTo([Utility realPX:1.0f]);
                make.bottom.mas_equalTo(divideView.superview).offset([Utility realPX:1.0f]);
            }];
            
            UIView *divideView1 = [self makeDividLine:CGRectMake(0, 0, CGRectGetWidth(_pdfViewCtrl.bounds), [Utility realPX:1.0f]) withColor:0xe6e6e6 andDirection:KDividLineTypeHorizontal];
            [_levelThirdView addSubview:divideView1];
            [divideView1 mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(divideView1.superview);
                make.right.mas_equalTo(self.contentView);
                make.height.mas_equalTo([Utility realPX:1.0f]);
                make.bottom.mas_equalTo(divideView1.superview).offset([Utility realPX:1.0f]);
            }];
            
            UIView *divideView2 = [self makeDividLine:CGRectMake(0, 0, [Utility realPX:1.0f], 30) withColor:0xe6e6e6 andDirection:KDividLineTypeVertical];
            divideView2.center = CGPointMake(divideView2.center.x, 140);
            [_levelThirdView addSubview:divideView2];
            
            [divideView2 mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(divideView2.superview).offset(10);
                make.height.mas_equalTo(40);
                make.width.mas_equalTo([Utility realPX:1.0f]);
                make.right.mas_equalTo(divideView2.superview).offset(20);
            }];
        } else {
            self.singleViewBtn = [SettingBar createItemWithImageAndTitle:FSLocalizedString(@"kViewModeSingle") imageNormal:[UIImage imageNamed:@"readview_single_normal"] imageSelected:[UIImage imageNamed:@"readview_single_selected"] imageDisable:[UIImage imageNamed:@"readview_single_selected"]];
            
            self.continueViewBtn = [SettingBar createItemWithImageAndTitle:FSLocalizedString(@"kViewModeContinuous") imageNormal:[UIImage imageNamed:@"readview_continue_normal"] imageSelected:[UIImage imageNamed:@"readview_continue_selected"] imageDisable:[UIImage imageNamed:@"readview_continue_selected"]];
            
            self.doubleViewBtn = [SettingBar createItemWithImageAndTitle:FSLocalizedString(@"kViewModeTwo") imageNormal:[UIImage imageNamed:@"readview_double_normal"] imageSelected:[UIImage imageNamed:@"readview_double_selected"] imageDisable:[UIImage imageNamed:@"readview_double_selected"]];
            
            if (self.extensionsManager.modulesConfig.loadThumbnail) {
                self.thumbnailViewBtn = [SettingBar createItemWithImageAndTitle:FSLocalizedString(@"kViewModeThumbnail") imageNormal:[UIImage imageNamed:@"readview_thumail_normal"] imageSelected:[UIImage imageNamed:@"readview_thumail_selected"] imageDisable:[UIImage imageNamed:@"readview_thumail_selected"]];
            }

            _ipadTopView = [[UIView alloc] init];
            [self.contentView addSubview:_ipadTopView];
            
            [_ipadTopView addSubview:self.singleViewBtn];
            [_ipadTopView addSubview:self.continueViewBtn];
            [_ipadTopView addSubview:self.doubleViewBtn];
            if (self.extensionsManager.modulesConfig.loadThumbnail)
                [_ipadTopView addSubview:self.thumbnailViewBtn];
            [_ipadTopView addSubview:self.reflowBtn];
            [_ipadTopView addSubview:self.screenLockBtn];
            [_ipadTopView addSubview:self.cropBtn];
    
            if (self.extensionsManager.modulesConfig.loadThumbnail){
                _ipadTopButtonArr = [@[self.singleViewBtn,self.continueViewBtn,self.doubleViewBtn,self.thumbnailViewBtn,self.reflowBtn,self.screenLockBtn,self.cropBtn] mutableCopy];
            }else{
                _ipadTopButtonArr = [@[self.singleViewBtn,self.continueViewBtn,self.doubleViewBtn,self.reflowBtn,self.screenLockBtn,self.cropBtn] mutableCopy];
            }
            _brightnessSwitchView = [[UIView alloc] init];
            _brightnessSwitchView.clipsToBounds = YES;
            [self.contentView addSubview:_brightnessSwitchView];
            
            _brightnessSliderView = [[UIView alloc] init];
            _brightnessSliderView.clipsToBounds = YES;
            [self.contentView addSubview:_brightnessSliderView];
            
            _nightButtonView = [[UIView alloc] init];
            [self.contentView addSubview:_nightButtonView];
            
            [_brightnessSwitchView addSubview:self.brightnessLabel];
            [_brightnessSwitchView addSubview:self.brightnessSwitch];
            [_brightnessSliderView addSubview:self.brightnessSmaller];
            [_brightnessSliderView addSubview:self.brightnessBigger];
            [_brightnessSliderView addSubview:self.brightnessControl];
            [_nightButtonView addSubview:self.nightViewBtn];
            
            UIView *divideView = [self makeDividLine:CGRectMake(0, 0, CGRectGetWidth(_pdfViewCtrl.bounds) - 60, [Utility realPX:1.0f]) withColor:0xe6e6e6 andDirection:KDividLineTypeHorizontal];
            [_ipadTopView addSubview:divideView];
            [divideView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(divideView.superview).offset(30);
                make.right.mas_equalTo(divideView.superview).offset(-30);
                make.height.mas_equalTo([Utility realPX:1.0f]);
                make.bottom.mas_equalTo(divideView.superview);
            }];
            
            UIView *verticalView1 = [self makeDividLine:CGRectMake(0, 0, [Utility realPX:1.0f], 40) withColor:0xe6e6e6 andDirection:KDividLineTypeVertical];
            [_brightnessSwitchView addSubview:verticalView1];
            [verticalView1 mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(verticalView1.superview).offset(30);
                make.height.mas_equalTo(40);
                make.width.mas_equalTo([Utility realPX:1.0f]);
                make.right.mas_equalTo(verticalView1.superview).offset([Utility realPX:1.0f]);
            }];
            
            UIView *verticalView2 = [self makeDividLine:CGRectMake(0, 0, [Utility realPX:1.0f], 40) withColor:0xe6e6e6 andDirection:KDividLineTypeVertical];
            [_brightnessSliderView addSubview:verticalView2];
            [verticalView2 mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(verticalView2.superview).offset(30);
                make.height.mas_equalTo(40);
                make.width.mas_equalTo([Utility realPX:1.0f]);
                make.right.mas_equalTo(verticalView2.superview).offset([Utility realPX:1.0f]);
            }];
        }
        
        [self addBtnTarget];
        [self updateBtnLayout];
    }
    return self;
}

-(UIView *)makeDividLine:(CGRect)frame withColor:(UInt32)colorValue andDirection:(KDividLineType)direction{
    UIView *divideView = [[UIView alloc] initWithFrame:frame];
    divideView.backgroundColor = [UIColor colorWithRGBHex:colorValue];
    if (direction == KDividLineTypeHorizontal){
        divideView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    }else{
        divideView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    }
    return divideView;
}

-(NSMutableArray *)getShowBtnFromArray:(NSMutableArray *)sourceArray {
    NSMutableArray *_tempArr = [NSMutableArray array];
    for (int i = 0; i < sourceArray.count; i++) {
        UIButton *button = [sourceArray objectAtIndex:i];
        if (!button.hidden) {
            [_tempArr addObject:button];
        }
    }
    
    return _tempArr;
}

-(void)updateBtnLayout {
    self.contentView.frame = _contentViewFrame;
    NSString *kAutoBrightness = FSLocalizedString(@"kAutoBrightness");
    CGSize titleSize = [Utility getTextSize:kAutoBrightness fontSize:15.0f maxSize:CGSizeMake(200, 100)];
    
    UIImage *smaller = [UIImage imageNamed:@"readview_brightness_smaller"];
    UIImage *bigger = [UIImage imageNamed:@"readview_brightness_bigger"];
    UIImage *nightImageNormal = [UIImage imageNamed:@"readview_night_normal"];
    
    if(DEVICE_iPHONE) {
        self.bottomButtonArr = [@[self.reflowBtn,self.screenLockBtn,self.cropBtn] mutableCopy];
        
        NSMutableArray *topBtnArr =[self getShowBtnFromArray:_tempTopButtonArr];
        if (topBtnArr.count == 0) {
            CGRect frame = self.contentView.frame;
            frame.size.height -= 50;
            self.contentView.frame = frame;
            
            _levelTopView.clipsToBounds = YES;
            [_levelTopView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.left.right.mas_equalTo(self.contentView);
                make.height.mas_equalTo(0);
            }];
        }else{
            [_levelTopView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.left.right.mas_equalTo(self.contentView);
                make.height.mas_equalTo(50);
            }];
            
            UIButton __block *toplastButton = nil;
            [topBtnArr enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
                [button mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo(10);
                    make.height.mas_equalTo(30);
                    make.left.mas_equalTo(toplastButton ? toplastButton.mas_right : button.superview.mas_left).with.offset(20.f);
                    
                    if (topBtnArr.count < 2){
                        make.right.mas_equalTo(self.contentView).with.offset(-20.f);
                    }else{
                        make.width.mas_equalTo(self.contentView).dividedBy(topBtnArr.count).with.offset(-30);
                    }
                    
                    toplastButton = button;
                }];
            }];
        }
        
        [self.brightnessLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(titleSize.width);
            make.left.mas_equalTo(20);
            make.centerY.mas_equalTo(self.brightnessLabel.superview.mas_centerY);
        }];
        
        [self.brightnessSwitch mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.brightnessSwitch.superview.mas_right).with.offset(-20);
            make.centerY.mas_equalTo(self.brightnessLabel.superview.mas_centerY);
        }];
        
        [_levelThirdView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_levelSecondView.mas_bottom);
            make.left.mas_equalTo(self.contentView);
            make.height.mas_equalTo(60);
            
            MASConstraint *widthConstraint = make.width.mas_equalTo(self.contentView).multipliedBy((float)2/3);
        }];
        
        [self.brightnessSmaller mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(smaller.size.width);
            make.left.mas_equalTo(20);
            make.centerY.mas_equalTo(self.brightnessSmaller.superview.mas_centerY);
        }];
        
        [self.brightnessBigger mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(bigger.size.width);
            make.right.mas_equalTo(self.brightnessBigger.superview.mas_right);
            make.centerY.mas_equalTo(self.brightnessBigger.superview.mas_centerY);
        }];
        
        [self.brightnessControl mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.brightnessSmaller.mas_right).offset(10);
            make.right.equalTo(self.brightnessBigger.mas_left).offset(-10);
            make.centerY.equalTo(self.brightnessBigger.mas_centerY);
            make.height.mas_equalTo(40);
        }];
        
        if (self.brightnessControl.hidden && self.nightViewBtn.hidden) {
            _levelThirdView.clipsToBounds = YES;
            [_levelThirdView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(0);
            }];
            
            CGRect frame = self.contentView.frame;
            frame.size.height -= 60;
            self.contentView.frame = frame;
        }
        
        NSMutableArray *bottomBtnArr = [self getShowBtnFromArray:self.bottomButtonArr];
        
        if (bottomBtnArr.count == 0) {
            CGRect frame = self.contentView.frame;
            frame.size.height -= 80;
            self.contentView.frame = frame;
            
            _levelBottomView.clipsToBounds = YES;
            [_levelBottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.left.right.mas_equalTo(self.contentView);
                make.height.mas_equalTo(0);
            }];
        }else{
            [_levelBottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.left.right.mas_equalTo(self.contentView);
                make.height.mas_equalTo(80);
            }];
            
            UIView __block *lastButton = nil;
            [bottomBtnArr enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
                [button mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(button.frame.size.width);
                    make.height.mas_equalTo(button.frame.size.height);
                    make.left.mas_equalTo(lastButton ? lastButton.mas_right : button.superview.mas_left).with.offset(lastButton ? 30 : 20);
                    make.bottom.mas_equalTo(button.superview.mas_bottom).offset(-10);
                    lastButton = button;
                }];
            }];
        }
        
        if (self.brightnessControl.hidden){
            _levelThirdView.clipsToBounds = YES;
            [_levelThirdView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(0);
            }];
            
            CGRect frame = self.contentView.frame;
            frame.size.height -= 50;
            self.contentView.frame = frame;
            
            _levelSecondView.clipsToBounds = YES;
            [_levelSecondView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(_levelTopView.mas_bottom);
                make.left.right.mas_equalTo(self.contentView);
                make.height.mas_equalTo(0);
            }];
            
            [self.nightViewBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(self.nightViewBtn.superview).with.offset(20);
                make.width.mas_equalTo(nightImageNormal.size.width);
                
                if (bottomBtnArr.count == 0){
                    make.bottom.mas_equalTo(self.nightViewBtn.superview).with.offset(-10);
                }else {
                    make.bottom.mas_equalTo(self.nightViewBtn.superview).with.offset(-80-10);
                }
            }];
        }else{
            [_levelSecondView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(_levelTopView.mas_bottom);
                make.left.right.mas_equalTo(self.contentView);
                make.height.mas_equalTo(50);
            }];
            
            [self.nightViewBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.mas_equalTo(self.nightViewBtn.superview.mas_right).with.offset(-20);
                make.centerY.mas_equalTo(_levelThirdView.mas_centerY);
                
                make.width.mas_equalTo(nightImageNormal.size.width);
            }];
        }
    }else{
        [_ipadTopView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(100);
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.top.equalTo(self.contentView.mas_top).offset(0);
            make.width.mas_equalTo(self.contentView);
        }];
        
        NSMutableArray *tempIpadTopBtnArr =[self getShowBtnFromArray:_ipadTopButtonArr];
        if (tempIpadTopBtnArr.count == 0) {
            _ipadTopView.clipsToBounds = YES;
            [_ipadTopView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(0);
            }];
            CGRect frame = self.contentView.frame;
            frame.size.height -= 100;
            self.contentView.frame = frame;
        }else{
            UIButton __block *lastButton = nil;
            [tempIpadTopBtnArr enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
                [button mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.width.equalTo(@(button.frame.size.width));
                    make.height.equalTo(@(button.frame.size.height));
                    make.left.mas_equalTo(lastButton ? lastButton.mas_right : button.superview.mas_left).with.offset(lastButton ? 44 : 30);
                    make.centerY.equalTo(button.superview.mas_centerY);
                    
                    lastButton = button;
                }];
            }];
        }
        
        NSMutableArray *ipadBottomViewArr = [[NSMutableArray alloc] init];

        self.brightnessLabel.hidden = YES;
        if (!self.brightnessControl.hidden){
            self.brightnessLabel.hidden = NO;
            [ipadBottomViewArr addObject:_brightnessSwitchView];
            
            [ipadBottomViewArr addObject:_brightnessSliderView];
        }
        
        if (!self.nightViewBtn.hidden){
            [ipadBottomViewArr addObject:_nightButtonView];
        }
        
        if (ipadBottomViewArr.count == 0) {
            CGRect frame = self.contentView.frame;
            frame.size.height -= 100;
            self.contentView.frame = frame;
            
            [@[_brightnessSwitchView,_brightnessSliderView,_nightButtonView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(0);
            }];
        }else{
            if(self.nightViewBtn.hidden){
                [_nightButtonView mas_remakeConstraints:^(MASConstraintMaker *make) {
                }];
            }
            UIView __block *lastView = nil;
            NSUInteger bottomArrayCount = ipadBottomViewArr.count;
            [ipadBottomViewArr enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                [view mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(100);
                    make.bottom.mas_equalTo(self.contentView.mas_bottom);
                    make.left.mas_equalTo(lastView ? lastView.mas_right : self.contentView.mas_left);
                    if (lastView) {
                        make.width.mas_equalTo(lastView);
                    }
                    if (idx == bottomArrayCount - 1) {
                        make.right.equalTo(self.contentView.mas_right);
                    }
                }];
                lastView = view;
            }];
        }
        
        [self.brightnessSwitch mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.brightnessSwitch.superview.mas_centerY);
            make.centerX.mas_equalTo(self.brightnessLabel.superview.mas_centerX).offset(50);
        }];
        
        [self.brightnessLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(titleSize.width);
            make.height.mas_equalTo(titleSize.height);
            make.centerY.mas_equalTo(self.brightnessLabel.superview.mas_centerY);
            make.centerX.mas_equalTo(self.brightnessLabel.superview.mas_centerX).offset(-50);
        }];
        
        if (self.brightnessControl.hidden) {
            NSArray *tempSliderArr = @[self.brightnessSmaller,self.brightnessBigger,self.brightnessControl];
            [tempSliderArr mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(0);
            }];
        }else{
            [self.brightnessSmaller mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(smaller.size.width);
                make.left.mas_equalTo(self.brightnessSmaller.superview.mas_left).offset(20);
                make.centerY.mas_equalTo(self.brightnessSmaller.superview.mas_centerY);
            }];
            
            [self.brightnessBigger mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(bigger.size.width);
                make.right.mas_equalTo(self.brightnessBigger.superview.mas_right).offset(-20);
                make.centerY.mas_equalTo(self.brightnessBigger.superview.mas_centerY);
            }];
            [self.brightnessControl mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.brightnessSmaller.mas_right).offset(10);
                make.right.equalTo(self.brightnessBigger.mas_left).offset(-10);
                make.centerY.equalTo(self.brightnessBigger.mas_centerY).offset(0);
                make.height.mas_equalTo(40);
            }];
        }
        
        [self.nightViewBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(nightImageNormal.size.width);
            make.centerY.mas_equalTo(self.nightViewBtn.superview.mas_centerY);
            make.centerX.mas_equalTo(self.nightViewBtn.superview.mas_centerX);
        }];
    }
}

-(void)addBtnTarget {
    [self.singleViewBtn addTarget:self action:@selector(singleClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.continueViewBtn addTarget:self action:@selector(continueClicked) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.extensionsManager.modulesConfig.loadThumbnail) {
        [self.thumbnailViewBtn addTarget:self action:@selector(thumbnailClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.reflowBtn addTarget:self action:@selector(reflowClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.cropBtn addTarget:self action:@selector(cropClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.screenLockBtn addTarget:self action:@selector(screenClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [self.brightnessSwitch addTarget:self action:@selector(onSwitchClicked) forControlEvents:UIControlEventValueChanged];
    
    [self.brightnessControl addTarget:self action:@selector(sliderChangedValue) forControlEvents:UIControlEventValueChanged];
    [self.brightnessControl addTarget:self action:@selector(sliderChangedEndValue) forControlEvents:UIControlEventTouchUpInside];
    
    [self.nightViewBtn addTarget:self action:@selector(nightModeClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [self.doubleViewBtn addTarget:self action:@selector(doubleClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (UIButton *)createButtonWith:(NSDictionary *)buttoninfo {
    UIButton *button = [UIButton buttonWithType:[buttoninfo[@"type"] intValue]];
    UIImage *viewbgNormal = [[UIImage imageNamed:[NSString stringWithFormat:buttoninfo[@"normalImage"]]] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 19, 14, 19)];
    UIImage *viewSelected = [[UIImage imageNamed:[NSString stringWithFormat:buttoninfo[@"selectedImage"]]] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 19, 14, 19)];
    
    [button setBackgroundImage:viewbgNormal forState:UIControlStateNormal];
    [button setBackgroundImage:viewSelected forState:UIControlStateHighlighted];
    [button setBackgroundImage:viewSelected forState:UIControlStateSelected];
    
    [button setTitle:FSLocalizedString(buttoninfo[@"title"]) forState:UIControlStateNormal];
    
    [button setTitleColor:[UIColor colorWithRGBHex:buttoninfo[@"normalTitleColor"]] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRGBHex:buttoninfo[@"higinlightTitleColor"]] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor colorWithRGBHex:buttoninfo[@"selectTitleColor"]] forState:UIControlStateSelected];
    
    button.titleLabel.font = [UIFont systemFontOfSize:[buttoninfo[@"titleFont"] floatValue]];
    return button;
}

- (void)setTempSysBrightness:(float)tempSysBrightness {
    _tempSysBrightness = tempSysBrightness;
}

- (void)onSwitchClicked {
    self.brightnessControl.enabled = !self.brightnessSwitch.on;

    if (self.brightnessSwitch.on) {
        [self.brightnessSmaller setImage:[SettingBar imageByApplyingAlpha:[UIImage imageNamed:@"readview_brightness_smaller"] alpha:0.5]];
        [self.brightnessBigger setImage:[SettingBar imageByApplyingAlpha:[UIImage imageNamed:@"readview_brightness_bigger"] alpha:0.5]];
        [UIScreen mainScreen].brightness = self.tempSysBrightness;

    } else {
        [self.brightnessSmaller setImage:[UIImage imageNamed:@"readview_brightness_smaller"]];
        [self.brightnessBigger setImage:[UIImage imageNamed:@"readview_brightness_bigger"]];
        {
            self.brightnessControl.value = [UIScreen mainScreen].brightness;
        }
    }
    _isBrightnessManual = !self.brightnessSwitch.on;
}

- (void)sliderChangedValue {
    [UIScreen mainScreen].brightness = self.brightnessControl.value;
}

- (void)sliderChangedEndValue {
}

- (void)singleClicked {
    [self updateLayoutButtonsWithLayout:PDF_LAYOUT_MODE_SINGLE];
    if ([self.delegate respondsToSelector:@selector(settingBarSinglePageLayout:)]) {
        [self.delegate settingBarSinglePageLayout:self];
    }
}

- (void)continueClicked {
    [self updateLayoutButtonsWithLayout:PDF_LAYOUT_MODE_CONTINUOUS];
    if ([self.delegate respondsToSelector:@selector(settingBarContinuousLayout:)]) {
        [self.delegate settingBarContinuousLayout:self];
    }
}

- (void)doubleClicked {
    [self updateLayoutButtonsWithLayout:PDF_LAYOUT_MODE_TWO];
    if ([self.delegate respondsToSelector:@selector(settingBarDoublePageLayout:)]) {
        [self.delegate settingBarDoublePageLayout:self];
    }
}

- (void)thumbnailClicked {
    self.singleViewBtn.selected = NO;
    self.continueViewBtn.selected = NO;
    self.doubleViewBtn.selected = NO;
    self.thumbnailViewBtn.selected = YES;
    if ([self.delegate respondsToSelector:@selector(settingBarThumbnail:)]) {
        [self.delegate settingBarThumbnail:self];
    }
}

- (void)reflowClicked {
    [self updateLayoutButtonsWithLayout:PDF_LAYOUT_MODE_REFLOW];
    if ([self.delegate respondsToSelector:@selector(settingBarReflow:)]) {
        [self.delegate settingBarReflow:self];
    }
}

- (void)cropClicked {
    ((UIButton *) [self getItemView:CROPPAGE]).selected = YES;
    if ([self.delegate respondsToSelector:@selector(settingBarCrop:)]) {
        [self.delegate settingBarCrop:self];
    }
}

- (void)screenClicked {
    self.screenLockBtn.selected = !self.screenLockBtn.selected;
    if ([self.delegate respondsToSelector:@selector(settingBar:setLockScreen:)]) {
        [self.delegate settingBar:self setLockScreen:self.screenLockBtn.selected];
    }
}

- (void)nightModeClicked {
    self.nightViewBtn.selected = !self.nightViewBtn.selected;
    if ([self.delegate respondsToSelector:@selector(settingBar:setNightMode:)]) {
        [self.delegate settingBar:self setNightMode:self.nightViewBtn.selected];
    }
}

- (void)setItem:(SettingItemType)itemType hidden:(BOOL)hidden {
    UIView *itemView = [self getItemView:itemType];
    itemView.hidden = hidden;
}

- (UIView *_Nullable)getItemView:(SettingItemType)itemType {
    switch (itemType) {
        case SINGLE:
            return self.singleViewBtn;
        case CONTINUOUS:
            return self.continueViewBtn;
        case DOUBLEPAGE:
            return self.doubleViewBtn;
        case THUMBNAIL:
            return self.thumbnailViewBtn;
        case REFLOW:
            return self.reflowBtn;
        case CROPPAGE:
            return self.cropBtn;
        case LOCKSCREEN:
            return self.screenLockBtn;
        case NIGHTMODE:
            return self.nightViewBtn;
        case BRIGHTNESS:
            return self.brightnessControl;
        default:
            return nil;
    }
}

- (void)updateLayoutButtonsWithLayout:(PDF_LAYOUT_MODE)layout {
    self.singleViewBtn.selected = layout == PDF_LAYOUT_MODE_SINGLE;
    self.continueViewBtn.selected = layout == PDF_LAYOUT_MODE_CONTINUOUS;
    self.doubleViewBtn.selected = layout == PDF_LAYOUT_MODE_TWO;
    self.reflowBtn.selected = layout == PDF_LAYOUT_MODE_REFLOW;
    self.thumbnailViewBtn.selected = NO;
}

+ (UIButton *)createItemWithImageAndTitle:(NSString *)title
                              imageNormal:(UIImage *)imageNormal
                            imageSelected:(UIImage *)imageSelected
                             imageDisable:(UIImage *)imageDisabled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    CGSize titleSize = [Utility getTextSize:title fontSize:12.0f maxSize:CGSizeMake(300, 200)];

    float width = imageNormal.size.width;
    float height = imageNormal.size.height;
    button.contentMode = UIViewContentModeScaleToFill;
    [button setImage:imageNormal forState:UIControlStateNormal];
    [button setImage:imageSelected forState:UIControlStateHighlighted];
    [button setImage:imageSelected forState:UIControlStateSelected];

    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor colorWithRGBHex:0x179cd8] forState:UIControlStateSelected];
    button.titleLabel.font = [UIFont systemFontOfSize:12.0f];

    button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, -height, 0);
    button.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width);
    button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width + 2 : width, titleSize.height + height);
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    return button;
}

+ (UIImage *)imageByApplyingAlpha:(UIImage *)image alpha:(CGFloat)alpha {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);

    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);

    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);

    CGContextSetAlpha(ctx, alpha);

    CGContextDrawImage(ctx, area, image.CGImage);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return newImage;
}

#pragma mark IAppLifecycleListener

- (void)applicationWillResignActive:(UIApplication *)application {
    if (!self.isEnterBg) {
        if (_pdfViewCtrl.currentDoc) {
            [UIScreen mainScreen].brightness = self.tempSysBrightness;
            self.isActive = YES;
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (!self.isActive) {
        if (_pdfViewCtrl.currentDoc) {
            [UIScreen mainScreen].brightness = self.tempSysBrightness;
            self.isEnterBg = YES;
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (self.isEnterBg) {
        self.tempSysBrightness = [UIScreen mainScreen].brightness;
        if (_pdfViewCtrl.currentDoc) {
            self.brightnessSwitch.on = !_isBrightnessManual;
            [self onSwitchClicked];
            self.isEnterBg = NO;
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (self.isActive) {
        self.tempSysBrightness = [UIScreen mainScreen].brightness;
        if (_pdfViewCtrl.currentDoc) {
            self.brightnessSwitch.on = !_isBrightnessManual;
            [self onSwitchClicked];
            self.isActive = NO;
        }
    }
}

#pragma mark IDocEventListener

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    [self updateLayoutButtonsWithLayout:[_pdfViewCtrl getPageLayoutMode]];
}

// todo
- (void)readStarted {
    self.brightnessSwitch.on = !_isBrightnessManual;
    self.tempSysBrightness = [UIScreen mainScreen].brightness;
    [self onSwitchClicked];
}

- (void)readDestroy {
    [UIScreen mainScreen].brightness = self.tempSysBrightness;
}

- (void)orientationChanged:(NSNotification *)note {
}
@end
