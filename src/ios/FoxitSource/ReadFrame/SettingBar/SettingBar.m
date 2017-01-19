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
#import "SettingBar.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import "SettingBarController.h"
#import "UIExtensionsSharedHeader.h"
#import "AppDelegate.h"

@interface SettingBar ()

@property (nonatomic, retain) UIScrollView *scrollView;

@property (nonatomic, retain) UILabel *brightnessLabel;
@property (nonatomic, retain) UISwitch *brightnessSwitch;
@property (nonatomic, retain) UISlider *brightnessSlider;
@property (nonatomic, retain) UIImageView *brightnessBigger;
@property (nonatomic, retain) UIImageView *brightnessSmaller;

@property (nonatomic, retain) UIButton *nightView;
@property (nonatomic, assign) float tempSysBrightness;
@property (nonatomic, assign) BOOL isEnterBg;
@property (nonatomic, assign) BOOL isActive;

@end

@implementation SettingBar {
    SettingBarController* _moreSettingBarController;
    BOOL isBrightnessManual;
    BOOL isNightMode;
    BOOL isScreenLocked;
}


- (instancetype)initWithPDFViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl moreSettingBarController:(SettingBarController*)moreSettingBarController
{
    self = [super init];
    if (self) {
        _moreSettingBarController = moreSettingBarController;
        self.pdfViewCtrl = pdfViewCtrl;
        isBrightnessManual = NO;
        isNightMode = NO;
        isScreenLocked = NO;
        self.isEnterBg = NO;
        self.isActive = NO;
        
        // copied from application:didFinishLaunchingWithOptions:
        self.tempSysBrightness = [UIScreen mainScreen].brightness;
        
        UIDevice *device = [UIDevice currentDevice];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
        self.contentView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, 150)] autorelease];
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        if (DEVICE_iPHONE) {
            self.contentView.frame = CGRectMake(0, 0, SCREENWIDTH, 240);
        }
        
        self.singleView_iphone = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *viewbgNormal = [[UIImage imageNamed:@"readview_mode_bg_normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 19, 14, 19)];
        UIImage *viewSelected = [[UIImage imageNamed:@"readview_mode_bg_selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 19, 14, 19)];
        
        
        [self.singleView_iphone setBackgroundImage:viewbgNormal forState:UIControlStateNormal];
        [self.singleView_iphone setBackgroundImage:viewSelected forState:UIControlStateHighlighted];
        [self.singleView_iphone setBackgroundImage:viewSelected forState:UIControlStateSelected];
        [self.singleView_iphone setTitle:NSLocalizedString(@"kViewModeSingle", nil) forState:UIControlStateNormal];
        [self.singleView_iphone setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.singleView_iphone setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.singleView_iphone setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        self.singleView_iphone.titleLabel.font = [UIFont systemFontOfSize:12.0f];
        self.singleView_iphone.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin| UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [self.singleView_iphone addTarget:self action:@selector(singleClicked) forControlEvents:UIControlEventTouchUpInside];
        
        self.continueView_iphone = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.continueView_iphone setBackgroundImage:viewbgNormal forState:UIControlStateNormal];
        [self.continueView_iphone setBackgroundImage:viewSelected forState:UIControlStateHighlighted];
        [self.continueView_iphone setBackgroundImage:viewSelected forState:UIControlStateSelected];
        [self.continueView_iphone setTitle:NSLocalizedString(@"kViewModeContinuous", nil) forState:UIControlStateNormal];
        [self.continueView_iphone setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.continueView_iphone setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.continueView_iphone setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        self.continueView_iphone.titleLabel.font = [UIFont systemFontOfSize:12.0f];
        self.continueView_iphone.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin| UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [self.continueView_iphone addTarget:self action:@selector(continueClicked) forControlEvents:UIControlEventTouchUpInside];
        
        self.thumbnailView_iphone = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.thumbnailView_iphone setBackgroundImage:viewbgNormal forState:UIControlStateNormal];
        [self.thumbnailView_iphone setBackgroundImage:viewSelected forState:UIControlStateHighlighted];
        [self.thumbnailView_iphone setBackgroundImage:viewSelected forState:UIControlStateSelected];
        [self.thumbnailView_iphone setTitle:NSLocalizedString(@"kViewModeThumbnail", nil) forState:UIControlStateNormal];
        self.thumbnailView_iphone.titleLabel.font = [UIFont systemFontOfSize:12.0f];
        [self.thumbnailView_iphone setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.thumbnailView_iphone setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.thumbnailView_iphone setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        self.thumbnailView_iphone.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin| UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [self.thumbnailView_iphone addTarget:self action:@selector(thumbnailClicked) forControlEvents:UIControlEventTouchUpInside];
        
        
        self.singleView_ipad = [SettingBar createItemWithImageAndTitle:NSLocalizedString(@"kViewModeSingle", nil) imageNormal:[UIImage imageNamed:@"readview_single_normal"] imageSelected:[UIImage imageNamed:@"readview_single_selected"] imageDisable:[UIImage imageNamed:@"readview_single_selected"]];
        [self.singleView_ipad addTarget:self action:@selector(singleClicked) forControlEvents:UIControlEventTouchUpInside];
        
        
        self.continueView_ipad = [SettingBar createItemWithImageAndTitle:NSLocalizedString(@"kViewModeContinuous", nil) imageNormal:[UIImage imageNamed:@"readview_continue_normal"] imageSelected:[UIImage imageNamed:@"readview_continue_selected"] imageDisable:[UIImage imageNamed:@"readview_continue_selected"]];
        [self.continueView_ipad addTarget:self action:@selector(continueClicked) forControlEvents:UIControlEventTouchUpInside];
        
        self.doubleView_ipad = [SettingBar createItemWithImageAndTitle:NSLocalizedString(@"kViewModeTwo", nil) imageNormal:[UIImage imageNamed:@"readview_double_normal"] imageSelected:[UIImage imageNamed:@"readview_double_selected"] imageDisable:[UIImage imageNamed:@"readview_double_selected"]];
        [self.doubleView_ipad addTarget:self action:@selector(doubleClicked) forControlEvents:UIControlEventTouchUpInside];
        
        self.thumbnailView_ipad = [SettingBar createItemWithImageAndTitle:NSLocalizedString(@"kViewModeThumbnail", nil) imageNormal:[UIImage imageNamed:@"readview_thumail_normal"] imageSelected:[UIImage imageNamed:@"readview_thumail_selected"] imageDisable:[UIImage imageNamed:@"readview_thumail_selected"]];
        [self.thumbnailView_ipad addTarget:self action:@selector(thumbnailClicked) forControlEvents:UIControlEventTouchUpInside];
        
        self.screenLockBtn = [SettingBar createItemWithImageAndTitle:NSLocalizedString(@"kScreenLock", nil) imageNormal:[UIImage imageNamed:@"readview_screen_lock_normal"] imageSelected:[UIImage imageNamed:@"readview_screen_lock_selected"] imageDisable:[UIImage imageNamed:@"readview_screen_lock_selected"]];
        [self.screenLockBtn addTarget:self action:@selector(screenClicked) forControlEvents:UIControlEventTouchUpInside];
        
        if (!DEVICE_iPHONE) {
            self.singleView_ipad.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            self.doubleView_ipad.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            self.thumbnailView_ipad.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            self.continueView_ipad.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            self.screenLockBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        if (DEVICE_iPHONE) {
            float viewModeWidth = (SCREENWIDTH - 15*4)/3;
            self.singleView_iphone.frame = CGRectMake(20, 10, viewModeWidth, 30);
            self.continueView_iphone.frame = CGRectMake(15 + viewModeWidth + 15, 10, viewModeWidth, 30);
            self.thumbnailView_iphone.frame = CGRectMake(10 + (viewModeWidth + 15)*2, 10, viewModeWidth, 30);
            [self.contentView addSubview:self.singleView_iphone];
            [self.contentView addSubview:self.continueView_iphone];
            [self.contentView addSubview:self.thumbnailView_iphone];
            
            UIView *divideView = [[[UIView alloc] initWithFrame:CGRectMake(0, 50, SCREENWIDTH, [Utility realPX:1.0f])] autorelease];
            divideView.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
            divideView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            [self.contentView addSubview:divideView];
            
            UIView *divideView1 = [[[UIView alloc] initWithFrame:CGRectMake(0, 170, SCREENWIDTH, [Utility realPX:1.0f])] autorelease];
            divideView1.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
            divideView1.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            [self.contentView addSubview:divideView1];
            
            UIView *divideView2 = [[[UIView alloc] initWithFrame:CGRectMake(SCREENWIDTH - 80, 160, [Utility realPX:1.0f], 30)] autorelease];
            divideView2.center = CGPointMake(divideView2.center.x, 140);
            divideView2.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
            divideView2.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            [self.contentView addSubview:divideView2];
            
            if ([UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeLeft||[UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeRight) {
                float tempWidth = 0;
                self.screenLockBtn.frame = CGRectMake(20 + tempWidth, 180, self.screenLockBtn.frame.size.width, self.screenLockBtn.frame.size.height);
                self.screenLockBtn.center = CGPointMake((SCREENWIDTH-20)/12, self.screenLockBtn.center.y);
                
                [self.contentView addSubview:self.screenLockBtn];
            }
            else
            {
                self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 180, SCREENWIDTH, 80)] autorelease];
                self.scrollView.scrollEnabled = YES;
                self.scrollView.directionalLockEnabled = NO;
                float scrollWidth = 520;
                float tempWidth = 0;
                self.screenLockBtn.frame = CGRectMake(20 + tempWidth, 5, self.screenLockBtn.frame.size.width, self.screenLockBtn.frame.size.height);
                self.screenLockBtn.center = CGPointMake((scrollWidth-20)/12, self.screenLockBtn.center.y);
                
                [self.contentView addSubview:self.scrollView];
                [self.scrollView addSubview:self.screenLockBtn];
            }
            
        }
        else
        {
            float spaceWidth = 30;
            if ([UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeLeft||[UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeRight) {
                spaceWidth = 60;
                float tempWidth = 0;
                self.singleView_ipad.frame = CGRectMake(20, 20, self.singleView_ipad.frame.size.width, self.singleView_ipad.frame.size.height);
                self.singleView_ipad.center = CGPointMake(10 + (SCREENWIDTH - 20)/20, self.singleView_ipad.center.y);
                
                tempWidth += self.singleView_ipad.frame.size.width + spaceWidth;
                self.continueView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.continueView_ipad.frame.size.width, self.continueView_ipad.frame.size.height);
                self.continueView_ipad.center = CGPointMake(10 + (SCREENWIDTH - 20)/20 * 3, self.continueView_ipad.center.y);
                
                tempWidth += self.continueView_ipad.frame.size.width + spaceWidth;
                self.doubleView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.doubleView_ipad.frame.size.width, self.doubleView_ipad.frame.size.height);
                self.doubleView_ipad.center = CGPointMake(10 + (SCREENWIDTH - 20)/20 * 5, self.doubleView_ipad.center.y);
                
                tempWidth += self.doubleView_ipad.frame.size.width + spaceWidth;
                self.thumbnailView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.thumbnailView_ipad.frame.size.width, self.thumbnailView_ipad.frame.size.height);
                self.thumbnailView_ipad.center = CGPointMake(10 + (SCREENWIDTH - 20)/20 * 7, self.thumbnailView_ipad.center.y);
                
                tempWidth += self.thumbnailView_ipad.frame.size.width + spaceWidth;
                self.screenLockBtn.frame = CGRectMake(20 + tempWidth, 20, self.screenLockBtn.frame.size.width, self.screenLockBtn.frame.size.height);
                self.screenLockBtn.center = CGPointMake(10 + (SCREENWIDTH - 20)/20 * 9, self.screenLockBtn.center.y);
                
                
                [self.contentView addSubview:self.singleView_ipad];
                [self.contentView addSubview:self.continueView_ipad];
                [self.contentView addSubview:self.doubleView_ipad];
                [self.contentView addSubview:self.thumbnailView_ipad];
                [self.contentView addSubview:self.screenLockBtn];
            }else{
                float spaceWidth = 44;
                self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 20, SCREENWIDTH, 80)] autorelease];
                self.scrollView.scrollEnabled = YES;
                _scrollView.backgroundColor = [UIColor whiteColor];
                self.scrollView.directionalLockEnabled = NO;
                _scrollView.showsHorizontalScrollIndicator = NO;
                _scrollView.bounces = NO;
                float scrollWidth = 1020;
                float tempWidth = 0;
                
                
                self.singleView_ipad.frame = CGRectMake(20, 20, self.singleView_ipad.frame.size.width, self.singleView_ipad.frame.size.height);
                self.singleView_ipad.center = CGPointMake(10 + (scrollWidth - 20)/20, self.singleView_ipad.center.y);
                
                tempWidth += self.singleView_ipad.frame.size.width + spaceWidth;
                self.continueView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.continueView_ipad.frame.size.width, self.continueView_ipad.frame.size.height);
                self.continueView_ipad.center = CGPointMake(10 + (scrollWidth - 20)/20 * 3, self.continueView_ipad.center.y);
                
                tempWidth += self.continueView_ipad.frame.size.width + spaceWidth;
                self.doubleView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.doubleView_ipad.frame.size.width, self.doubleView_ipad.frame.size.height);
                self.doubleView_ipad.center = CGPointMake(10 + (scrollWidth - 20)/20 * 5, self.doubleView_ipad.center.y);
                
                tempWidth += self.doubleView_ipad.frame.size.width + spaceWidth;
                self.thumbnailView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.thumbnailView_ipad.frame.size.width, self.thumbnailView_ipad.frame.size.height);
                self.thumbnailView_ipad.center = CGPointMake(10 + (scrollWidth - 20)/20 * 7, self.thumbnailView_ipad.center.y);
                
                tempWidth += self.thumbnailView_ipad.frame.size.width + spaceWidth;
                self.screenLockBtn.frame = CGRectMake(20 + tempWidth, 20, self.screenLockBtn.frame.size.width, self.screenLockBtn.frame.size.height);
                self.screenLockBtn.center = CGPointMake(10 + (scrollWidth - 20)/20 * 9, self.screenLockBtn.center.y);
                
                [self.contentView addSubview:self.scrollView];
                [self.scrollView addSubview:self.singleView_ipad];
                [self.scrollView addSubview:self.continueView_ipad];
                [self.scrollView addSubview:self.doubleView_ipad];
                [self.scrollView addSubview:self.thumbnailView_ipad];
                [self.scrollView addSubview:self.screenLockBtn];
                
            }
           
            
            UIView *divideView = [[[UIView alloc] initWithFrame:CGRectMake(30, 100, SCREENWIDTH - 60, [Utility realPX:1.0f])] autorelease];
            divideView.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
            divideView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            [self.contentView addSubview:divideView];
            
            UIView *verticalView1 = [[[UIView alloc] initWithFrame:CGRectMake(SCREENWIDTH/3 + 40, 130, [Utility realPX:1.0f], 40)] autorelease];
            verticalView1.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
            verticalView1.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleRightMargin;;
            [self.contentView addSubview:verticalView1];
            
            UIView *verticalView2 = [[[UIView alloc] initWithFrame:CGRectMake(SCREENWIDTH/3*2 + 40, 130, [Utility realPX:1.0f], 40)] autorelease];
            verticalView2.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
            verticalView2.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleRightMargin;
            [self.contentView addSubview:verticalView2];
        }
        
        CGSize titleSize  = [Utility getTextSize:NSLocalizedString(@"kAutoBrightness", nil) fontSize:15.0f maxSize:CGSizeMake(200, 100)];
        
        self.brightnessLabel = [[[UILabel alloc] initWithFrame:CGRectMake(90, 120, titleSize.width + 10 , 40)] autorelease];
        if (DEVICE_iPHONE) {
            self.brightnessLabel.frame = CGRectMake(20, 90, 200, 40);
        }
        
        self.brightnessLabel.center = CGPointMake(self.brightnessLabel.center.x, DEVICE_iPHONE ? 80 : 150);
        self.brightnessLabel.text = NSLocalizedString(@"kAutoBrightness", nil);
        self.brightnessLabel.font = [UIFont systemFontOfSize:15.0f];
        [self.contentView addSubview:self.brightnessLabel];
        
        self.brightnessSwitch = [[[UISwitch alloc] initWithFrame:CGRectMake(80 + titleSize.width + 20, 125, 100, 40)] autorelease];
        if (DEVICE_iPHONE) {
            self.brightnessSwitch.frame = CGRectMake(SCREENWIDTH - 80, 90, 80, 40);
            self.brightnessSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  |UIViewAutoresizingFlexibleRightMargin;
        }
        self.brightnessSwitch.center = CGPointMake(self.brightnessSwitch.center.x, DEVICE_iPHONE ? 80 : 150);
        
        
        [self.brightnessSwitch addTarget:self action:@selector(onSwitchClicked) forControlEvents:UIControlEventValueChanged];
        
        [self.contentView addSubview:self.brightnessSwitch];
        
        
        UIImage *smaller = [UIImage imageNamed:@"readview_brightness_smaller"];
        self.brightnessSmaller = [[[UIImageView alloc] initWithImage:smaller] autorelease];
        self.brightnessSmaller.frame = CGRectMake(SCREENWIDTH/3 + 50, 130, smaller.size.width, smaller.size.height);
        if (DEVICE_iPHONE) {
            self.brightnessSmaller.frame = CGRectMake(20, 130, smaller.size.width, smaller.size.height);
        }
        self.brightnessSmaller.center = CGPointMake(self.brightnessSmaller.center.x,  DEVICE_iPHONE ? 140 : 150);
        self.brightnessSmaller.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.contentView addSubview:self.brightnessSmaller];
        
        UIImage *bigger = [UIImage imageNamed:@"readview_brightness_bigger"];
        self.brightnessBigger = [[[UIImageView alloc] initWithImage:bigger] autorelease];
        self.brightnessBigger.frame = CGRectMake(SCREENWIDTH/3 + 240, 120, bigger.size.width, bigger.size.height);
        if (DEVICE_iPHONE) {
            self.brightnessBigger.frame = CGRectMake(SCREENWIDTH -40 - bigger.size.width - 80 + 10, 130, bigger.size.width, bigger.size.height);
        }
        self.brightnessBigger.center = CGPointMake(self.brightnessBigger.center.x, DEVICE_iPHONE ? 140 : 150);
        self.brightnessBigger.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleRightMargin;
        [self.contentView addSubview:self.brightnessBigger];
        
        self.brightnessSlider = [[[UISlider alloc] init] autorelease];
        [self.contentView addSubview:self.brightnessSlider];
        [self.brightnessSlider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.brightnessSmaller.mas_right).offset(10);
            make.right.equalTo(self.brightnessBigger.mas_left).offset(-10);
            make.centerY.equalTo(self.brightnessBigger.mas_centerY).offset(0);
            make.height.mas_equalTo(40);
        }];
        [self.brightnessSlider setThumbImage:[UIImage imageNamed:@"property_linewidth_slider.png"] forState:UIControlStateNormal];
        [self.brightnessSlider setThumbImage:[UIImage imageNamed:@"property_linewidth_slider.png"] forState:UIControlStateDisabled];
        self.brightnessSlider.minimumValue = 0.2f;
        
        [self.brightnessSlider addTarget:self action:@selector(sliderChangedValue) forControlEvents:UIControlEventValueChanged];
        [self.brightnessSlider addTarget:self action:@selector(sliderChangedEndValue) forControlEvents:UIControlEventTouchUpInside];
        self.brightnessSlider.enabled = !self.brightnessSwitch.on;
        
        
        self.nightView = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.nightView setImage:[UIImage imageNamed:@"readview_night_normal"] forState:UIControlStateNormal];
        [self.nightView setImage:[UIImage imageNamed:@"readview_night_selected"] forState:UIControlStateHighlighted];
        [self.nightView setImage:[UIImage imageNamed:@"readview_night_selected"] forState:UIControlStateSelected];
        self.nightView.frame = CGRectMake(SCREENWIDTH/3*2 + 80, 120, [UIImage imageNamed:@"readview_night_normal"].size.width, [UIImage imageNamed:@"readview_night_normal"].size.height);
        if (DEVICE_iPHONE) {
            self.nightView.frame = CGRectMake(SCREENWIDTH - 80 + 20, 180, self.nightView.frame.size.width, self.nightView.frame.size.height);
        }
        
        self.nightView.center = CGPointMake(self.nightView.center.x, DEVICE_iPHONE ? 140 : 150);
        self.nightView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleRightMargin;
        [self.nightView addTarget:self action:@selector(nightModeClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.nightView];
        
        [self initValuesAndActions];
    }
    return self;
}

// copied from commonFunc module
-(void)initValuesAndActions
{
    SettingBar* me = self;
    self.single = ^ (BOOL selected) {
        [_pdfViewCtrl setPageLayoutMode:PDF_LAYOUT_MODE_SINGLE];
        _moreSettingBarController.hiddenSettingBar = YES;
    };
    
    self.continuous = ^ (BOOL selected) {
        [_pdfViewCtrl setPageLayoutMode:PDF_LAYOUT_MODE_CONTINUOUS];
        _moreSettingBarController.hiddenSettingBar = YES;
    };
    
    self.doublepage = ^ (BOOL selected) {
        [_pdfViewCtrl setPageLayoutMode:PDF_LAYOUT_MODE_TWO];
        _moreSettingBarController.hiddenSettingBar = YES;
    };
    
    self.thumbnail = ^ (BOOL selected) {
        [_pdfViewCtrl setPageLayoutMode:PDF_LAYOUT_MODE_MULTIPLE];
        _moreSettingBarController.hiddenSettingBar = YES;
    };
    
    self.lockscreen = ^ (BOOL selected) {
        isScreenLocked = !selected;
        _moreSettingBarController.hiddenSettingBar = YES;
        [me setItemState:isScreenLocked value:0 itemType:LOCKSCREEN];
        DEMO_APPDELEGATE.isScreenLocked = isScreenLocked;
    };
    
    self.nightmodel = ^(BOOL selected) {
        isNightMode = !selected;
        [_pdfViewCtrl setIsNightMode:isNightMode];
        _moreSettingBarController.hiddenSettingBar = YES;
        [me setItemState:isNightMode value:0  itemType:NIGHTMODEL];
    };

    [me setItemState:isScreenLocked value:0  itemType:LOCKSCREEN];
    [me setItemState:isNightMode value:0 itemType:NIGHTMODEL];

}

-(void)setTempSysBrightness:(float)tempSysBrightness
{
    _tempSysBrightness = tempSysBrightness;
}

-(void)onSwitchClicked
{
    self.brightnessSlider.enabled = !self.brightnessSwitch.on;
    
    if (self.brightnessSwitch.on) {//开
        [self.brightnessSmaller setImage:[SettingBar imageByApplyingAlpha:[UIImage imageNamed:@"readview_brightness_smaller"] alpha:0.5]];
        [self.brightnessBigger setImage:[SettingBar imageByApplyingAlpha:[UIImage imageNamed:@"readview_brightness_bigger"] alpha:0.5]];
        [UIScreen mainScreen].brightness = self.tempSysBrightness;
        
    }
    else
    {
        [self.brightnessSmaller setImage:[UIImage imageNamed:@"readview_brightness_smaller"]];
        [self.brightnessBigger setImage:[UIImage imageNamed:@"readview_brightness_bigger"]];
        {
            self.brightnessSlider.value = [UIScreen mainScreen].brightness;
        }
    }
    isBrightnessManual = !self.brightnessSwitch.on;
}

-(void)sliderChangedValue
{
    [UIScreen mainScreen].brightness = self.brightnessSlider.value;
}

-(void)sliderChangedEndValue
{
    
}

-(void)singleClicked
{
    if (self.single) {
        self.single(DEVICE_iPHONE ? self.singleView_iphone.selected : self.singleView_ipad.selected);
    }
}

-(void)continueClicked
{
    if (self.continuous) {
        self.continuous(DEVICE_iPHONE ? self.continueView_iphone.selected : self.continueView_ipad.selected);
    }
}

-(void)doubleClicked
{
    if (self.doublepage) {
        self.doublepage(self.doubleView_ipad.selected);
    }
}

-(void)thumbnailClicked
{
    if (self.thumbnail) {
        self.thumbnail(DEVICE_iPHONE ? self.thumbnailView_iphone.selected : self.thumbnailView_ipad.selected);
    }
}

-(void)screenClicked
{
    if (self.lockscreen) {
        self.lockscreen(self.screenLockBtn.selected);
    }
}

-(void)nightModeClicked
{
    if (self.nightmodel) {
        self.nightmodel(self.nightView.selected);
    }
}


- (void)setItemState:(BOOL)state value:(float)value itemType:(SettingItemType)itemType
{
    switch (itemType)
    {
        case SINGLE:
        {
            if (DEVICE_iPHONE) {
                self.singleView_iphone.selected = state;
            }
            else
            {
                self.singleView_ipad.selected = state;
            }
            
            
        }
            break;
        case CONTINUOUS:
        {
            if (DEVICE_iPHONE) {
                self.continueView_iphone.selected = state;
            }
            else
            {
                self.continueView_ipad.selected = state;
            }
            
            
        }
            break;
        case DOUBLEPAGE:
        {
            self.doubleView_ipad.selected = state;
        }
            break;
        case THUMBNAIL:
        {
            if (DEVICE_iPHONE) {
                self.thumbnailView_iphone.selected = state;
            }
            else
            {
                self.thumbnailView_ipad.selected = state;
            }
            
        }
            break;
        case ONLYTEXT:
        {
            
        }
            break;
        case READ:
        {
            
        }
            break;
        case CUTWHITEEDGE:
        {
            
        }
            break;
        case LOCKSCREEN:
        {
            self.screenLockBtn.selected = state;
            
        }
            break;
        case LOCKZOOM:
        {
            
        }
            break;
        case LOCKDRAGDIRECTION:
        {
            
        }
            break;
        case NIGHTMODEL:
        {
            self.nightView.selected = state;
        }
        default:
            break;
    }
}
+ (UIButton*)createItemWithImageAndTitle:(NSString*)title
                             imageNormal:(UIImage*)imageNormal
                           imageSelected:(UIImage*)imageSelected
                            imageDisable:(UIImage*)imageDisabled
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    CGSize titleSize = [Utility getTextSize:title fontSize:12.0f maxSize:CGSizeMake(300, 200)];
    
    float width = imageNormal.size.width ;
    float height = imageNormal.size.height ;
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
    button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width + 2: width,  titleSize.height + height);
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    return button;
}

+ (UIImage *)imageByApplyingAlpha:(UIImage*)image alpha:(CGFloat) alpha {
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

- (void)applicationWillResignActive:(UIApplication *)application
{
    if (!self.isEnterBg) {
        if (_pdfViewCtrl.currentDoc) {
            [UIScreen mainScreen].brightness = self.tempSysBrightness;
            self.isActive = YES;
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if (!self.isActive) {
        if (_pdfViewCtrl.currentDoc) {
            [UIScreen mainScreen].brightness = self.tempSysBrightness;
            self.isEnterBg = YES;
        }
    }
   
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if (self.isEnterBg) {
        self.tempSysBrightness = [UIScreen mainScreen].brightness;
        if (_pdfViewCtrl.currentDoc) {
            self.brightnessSwitch.on = !isBrightnessManual;
            [self onSwitchClicked];
            self.isEnterBg = NO;
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.isActive) {
        self.tempSysBrightness = [UIScreen mainScreen].brightness;
        if (_pdfViewCtrl.currentDoc) {
            self.brightnessSwitch.on = !isBrightnessManual;
            [self onSwitchClicked];
            self.isActive = NO;
        }
    }
}

#pragma mark IDocEventListener

- (void)readStarted
{
    self.brightnessSwitch.on = !isBrightnessManual;
    self.tempSysBrightness = [UIScreen mainScreen].brightness;
    [self onSwitchClicked];
}

- (void)readDestroy
{
    [UIScreen mainScreen].brightness = self.tempSysBrightness;
}

- (void)orientationChanged:(NSNotification *)note  {
    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
    
    CGFloat a =  SCREENWIDTH > SCREENHEIGHT ? SCREENWIDTH : SCREENHEIGHT;
    
    if (DEVICE_iPHONE) {
        if (o == UIDeviceOrientationLandscapeLeft||o == UIDeviceOrientationLandscapeRight) {
            [self.screenLockBtn removeFromSuperview];
            [self.scrollView removeFromSuperview];
            float tempWidth = 0;
            self.screenLockBtn.frame = CGRectMake(20 + tempWidth, 180, self.screenLockBtn.frame.size.width, self.screenLockBtn.frame.size.height);
            self.screenLockBtn.center = CGPointMake((a-20)/12, self.screenLockBtn.center.y);
            
            [self.contentView addSubview:self.screenLockBtn];
        }
        else if(o ==  UIDeviceOrientationPortrait || o == UIDeviceOrientationPortraitUpsideDown)
        {
            [self.screenLockBtn removeFromSuperview];
            [self.scrollView removeFromSuperview];
            self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 180, STYLE_CELLWIDTH_IPHONE, 80)] autorelease];
            [self.contentView addSubview:self.scrollView];
            
            self.scrollView.scrollEnabled = YES;
            self.scrollView.directionalLockEnabled = NO;
            float scrollWidth = 520;
            float tempWidth = 0;
            self.screenLockBtn.frame = CGRectMake(20 + tempWidth, 5, self.screenLockBtn.frame.size.width, self.screenLockBtn.frame.size.height);
            self.screenLockBtn.center = CGPointMake((scrollWidth-20)/12, self.screenLockBtn.center.y);
            
            [self.scrollView addSubview:self.screenLockBtn];
        }
        
    }else{
        CGSize titleSize  = [Utility getTextSize:NSLocalizedString(@"kAutoBrightness", nil) fontSize:15.0f maxSize:CGSizeMake(200, 100)];
        self.brightnessLabel.frame = CGRectMake(90, 120, titleSize.width + 10 , 40);
        self.brightnessLabel.center = CGPointMake(self.brightnessLabel.center.x, 150);
        self.brightnessSwitch.frame = CGRectMake(80 + titleSize.width + 20, 125, 100, 40);
        self.brightnessSwitch.center = CGPointMake(self.brightnessSwitch.center.x, 150);
        float spaceWidth = 0;
        if (o == UIDeviceOrientationLandscapeLeft||o == UIDeviceOrientationLandscapeRight)
        {
            [self.singleView_ipad removeFromSuperview];
            [self.continueView_ipad removeFromSuperview];
            [self.doubleView_ipad removeFromSuperview];
            [self.thumbnailView_ipad removeFromSuperview];
            [self.screenLockBtn removeFromSuperview];
            [self.scrollView removeFromSuperview];
            spaceWidth = 60;
            float tempWidth = 0;
            self.singleView_ipad.frame = CGRectMake(20, 20, self.singleView_ipad.frame.size.width, self.singleView_ipad.frame.size.height);
            self.singleView_ipad.center = CGPointMake(10 + (SCREENWIDTH - 20)/20, self.singleView_ipad.center.y);
            
            tempWidth += self.singleView_ipad.frame.size.width + spaceWidth;
            self.continueView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.continueView_ipad.frame.size.width, self.continueView_ipad.frame.size.height);
            self.continueView_ipad.center = CGPointMake(10 + (SCREENWIDTH - 20)/20 * 3, self.continueView_ipad.center.y);
            
            tempWidth += self.continueView_ipad.frame.size.width + spaceWidth;
            self.doubleView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.doubleView_ipad.frame.size.width, self.doubleView_ipad.frame.size.height);
            self.doubleView_ipad.center = CGPointMake(10 + (SCREENWIDTH - 20)/20 * 5, self.doubleView_ipad.center.y);
            
            tempWidth += self.doubleView_ipad.frame.size.width + spaceWidth;
            self.thumbnailView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.thumbnailView_ipad.frame.size.width, self.thumbnailView_ipad.frame.size.height);
            self.thumbnailView_ipad.center = CGPointMake(10 + (SCREENWIDTH - 20)/20 * 7, self.thumbnailView_ipad.center.y);
            
            tempWidth += self.thumbnailView_ipad.frame.size.width + spaceWidth;
            self.screenLockBtn.frame = CGRectMake(20 + tempWidth, 20, self.screenLockBtn.frame.size.width, self.screenLockBtn.frame.size.height);
            self.screenLockBtn.center = CGPointMake(10 + (SCREENWIDTH - 20)/20 * 9, self.screenLockBtn.center.y);
            
            [self.contentView addSubview:self.singleView_ipad];
            [self.contentView addSubview:self.continueView_ipad];
            [self.contentView addSubview:self.doubleView_ipad];
            [self.contentView addSubview:self.thumbnailView_ipad];
            [self.contentView addSubview:self.screenLockBtn];

            
        }else if(o ==  UIDeviceOrientationPortrait || o == UIDeviceOrientationPortraitUpsideDown)
        {
            [self.singleView_ipad removeFromSuperview];
            [self.continueView_ipad removeFromSuperview];
            [self.doubleView_ipad removeFromSuperview];
            [self.thumbnailView_ipad removeFromSuperview];
            [self.screenLockBtn removeFromSuperview];
            [self.scrollView removeFromSuperview];

            float spaceWidth = 44;
            self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, STYLE_CELLWIDTH_IPHONE, 80)] autorelease];
            self.scrollView.scrollEnabled = YES;
            _scrollView.backgroundColor = [UIColor whiteColor];
            self.scrollView.directionalLockEnabled = NO;
            _scrollView.showsHorizontalScrollIndicator = NO;
            _scrollView.bounces = NO;
            float scrollWidth = 1020;
            float tempWidth = 0;
            
            self.singleView_ipad.frame = CGRectMake(20, 20, self.singleView_ipad.frame.size.width, self.singleView_ipad.frame.size.height);
            self.singleView_ipad.center = CGPointMake(10 + (scrollWidth - 20)/20, self.singleView_ipad.center.y);
            
            tempWidth += self.singleView_ipad.frame.size.width + spaceWidth;
            self.continueView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.continueView_ipad.frame.size.width, self.continueView_ipad.frame.size.height);
            self.continueView_ipad.center = CGPointMake(10 + (scrollWidth - 20)/20 * 3, self.continueView_ipad.center.y);
            
            tempWidth += self.continueView_ipad.frame.size.width + spaceWidth;
            self.doubleView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.doubleView_ipad.frame.size.width, self.doubleView_ipad.frame.size.height);
            self.doubleView_ipad.center = CGPointMake(10 + (scrollWidth - 20)/20 * 5, self.doubleView_ipad.center.y);
            
            tempWidth += self.doubleView_ipad.frame.size.width + spaceWidth;
            self.thumbnailView_ipad.frame = CGRectMake(20 + tempWidth, 20, self.thumbnailView_ipad.frame.size.width, self.thumbnailView_ipad.frame.size.height);
            self.thumbnailView_ipad.center = CGPointMake(10 + (scrollWidth - 20)/20 * 7, self.thumbnailView_ipad.center.y);
            
            tempWidth += self.thumbnailView_ipad.frame.size.width + spaceWidth;
            self.screenLockBtn.frame = CGRectMake(20 + tempWidth, 20, self.screenLockBtn.frame.size.width, self.screenLockBtn.frame.size.height);
            self.screenLockBtn.center = CGPointMake(10 + (scrollWidth - 20)/20 * 9, self.screenLockBtn.center.y);
            
            [self.contentView addSubview:self.scrollView];
            [self.scrollView addSubview:self.singleView_ipad];
            [self.scrollView addSubview:self.continueView_ipad];
            [self.scrollView addSubview:self.doubleView_ipad];
            [self.scrollView addSubview:self.thumbnailView_ipad];
            [self.scrollView addSubview:self.screenLockBtn];
         }
    }
}

- (void)dealloc{    
    [_contentView release];
    [_single release];
    [_continuous release];
    [_doublepage release];
    [_thumbnail release];
    [_lockscreen release];
    [_nightmodel release];
    [_singleView_iphone release];
    [_continueView_iphone release];
    [_thumbnailView_iphone release];
    [_singleView_ipad release];
    [_continueView_ipad release];
    [_thumbnailView_ipad release];
    [_doubleView_ipad release];
    [_screenLockBtn_ipad release];
    [_brightnessLabel release];
    [_brightnessSwitch release];
    [_brightnessSlider release];
    [_brightnessBigger release];
    [_brightnessSmaller release];
    [_nightView release];
    
    [super dealloc];
}
@end
