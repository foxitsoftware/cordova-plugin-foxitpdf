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

#import "SignatureModule.h"
#import "../Common/UIExtensionsSharedHeader.h"
#import "DigitalSignatureAnnotHandler.h"
#import "SignToolHandler.h"
#import "Utility.h"
#import "UIButton+EnlargeEdge.h"

@interface SignatureModule ()
@property (nonatomic, strong) TbBaseItem *signItem;

@property (nonatomic, strong) SignToolHandler *toolHandler;
@property (nonatomic, strong) UIView *topToolBar;
@property (nonatomic, strong) UIView *bottomToolBar;
@property (nonatomic, assign) int oldState;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) TbBaseItem *listItem;
@property (nonatomic, strong) UIButton *signatureButton;
@end

@implementation SignatureModule {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
}

- (NSString *)getName {
    return @"Signature";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [self loadModule];
        SignToolHandler* toolHandler = [[SignToolHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_extensionsManager registerToolHandler:toolHandler];
        [_extensionsManager registerRotateChangedListener:toolHandler];
        [_extensionsManager.pdfViewCtrl registerDocEventListener:toolHandler];
        
        DigitalSignatureAnnotHandler* annotHandler = [[DigitalSignatureAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_pdfViewCtrl registerScrollViewEventListener:annotHandler];
        [_extensionsManager registerRotateChangedListener:annotHandler];
        [_extensionsManager registerAnnotHandler:annotHandler];
        self.toolHandler = (SignToolHandler *) [_extensionsManager getToolHandlerByName:Tool_Signature];
        [_pdfViewCtrl registerDocEventListener:self];
    }
    return self;
}

- (void)loadModule {
    [self initToolBar];
    [_extensionsManager registerToolEventListener:self];
    [_extensionsManager registerStateChangeListener:self];
    
    NSMutableArray<UIBarButtonItem *> *tmpArray = _extensionsManager.bottomToolbar.items.mutableCopy;
    
    if (_extensionsManager.modulesConfig.loadSignature) {
        self.signatureButton = [self createButtonWithTitle:FSLocalizedString(@"kSignatureTitle") image:[UIImage imageNamed:@"signature"]];
        self.signatureButton.contentEdgeInsets = UIEdgeInsetsMake((49-CGRectGetHeight(self.signatureButton.frame))/2, 0, 0, 0);
        self.signatureButton.tag = FS_BOTTOMBAR_ITEM_SIGNATURE_TAG;
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.signatureButton];
        item.tag = FS_BOTTOMBAR_ITEM_SIGNATURE_TAG;
        [tmpArray addObject:item];
        
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tmpArray addObject:flexibleSpace];
        
        [self.signatureButton addTarget:self action:@selector(onTapSignatureButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    _extensionsManager.bottomToolbar.items = tmpArray;
}

- (void)onTapSignatureButton:(UIButton *)button {
    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }
    [_extensionsManager setCurrentToolHandler:self.toolHandler];
    [self.toolHandler openCreateSign];
}

- (void)initToolBar {
    UIView *superView = _pdfViewCtrl;
    _topToolBar = [[UIView alloc] init];
    _topToolBar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];

    _cancelBtn = [[UIButton alloc] init];
    [_cancelBtn setImage:[UIImage imageNamed:@"common_back_black"] forState:UIControlStateNormal];
    [_cancelBtn addTarget:self action:@selector(cancelSignature) forControlEvents:UIControlEventTouchUpInside];
    [_topToolBar addSubview:_cancelBtn];

    TbBaseItem *titleItem = [TbBaseItem createItemWithTitle:FSLocalizedString(@"kSignatureTitle")];
    titleItem.textColor = [UIColor colorWithRGBHex:0x3F3F3F];
    [_topToolBar addSubview:titleItem.contentView];
    CGSize size = titleItem.contentView.frame.size;
    [titleItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(_topToolBar.mas_centerX);
        make.centerY.mas_equalTo(_topToolBar.mas_centerY).offset(10);
        make.width.mas_equalTo(size.width);
        make.height.mas_equalTo(size.height);
    }];

    UIView *divideView = [[UIView alloc] init];
    divideView.backgroundColor = [UIColor colorWithRed:0xE2 / 255.0f green:0xE2 / 255.0f blue:0xE2 / 255.0f alpha:1];
    [_topToolBar addSubview:divideView];
    [divideView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(divideView.superview.mas_left);
        make.height.mas_equalTo(1);
        make.bottom.mas_equalTo(divideView.superview.mas_bottom);
        make.right.mas_equalTo(divideView.superview.mas_right);
    }];

    _bottomToolBar = [[UIView alloc] init];
    _bottomToolBar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    _listItem = [TbBaseItem createItemWithImageAndTitle:FSLocalizedString(@"kSignListIconTitle") imageNormal:[UIImage imageNamed:@"sign_list"] imageSelected:[UIImage imageNamed:@"sign_list"] imageDisable:[UIImage imageNamed:@"sign_list"] background:nil imageTextRelation:RELATION_BOTTOM];
    _listItem.textColor = [UIColor blackColor];
    _listItem.textFont = [UIFont systemFontOfSize:12.f];

    __weak typeof(self) weakSelf = self;
    _listItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf.toolHandler delete];
        [weakSelf.toolHandler signList];
    };

    [_bottomToolBar addSubview:_listItem.contentView];

    [_cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(26);
        make.left.mas_equalTo(_cancelBtn.superview.mas_left).offset(10);
        make.centerY.mas_equalTo(_cancelBtn.superview.mas_centerY).offset(10);
    }];

    float width = _listItem.contentView.frame.size.width;
    float height = _listItem.contentView.frame.size.height;
    [_listItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width);
        make.height.mas_equalTo(height);
        make.centerY.mas_equalTo(_listItem.contentView.superview.mas_centerY);
        make.centerX.mas_equalTo(_listItem.contentView.superview.mas_centerX).offset(0);
    }];

    UIView *divideView1 = [[UIView alloc] init];
    divideView1.backgroundColor = [UIColor colorWithRed:0xE2 / 255.0f green:0xE2 / 255.0f blue:0xE2 / 255.0f alpha:1];
    [_bottomToolBar addSubview:divideView1];
    [divideView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(divideView1.superview.mas_left);
        make.height.mas_equalTo(1);
        make.top.mas_equalTo(divideView1.superview.mas_top);
        make.right.mas_equalTo(divideView1.superview.mas_right);
    }];

    _topToolBar.hidden = YES;
    _bottomToolBar.hidden = YES;
    [superView addSubview:_topToolBar];
    [superView addSubview:_bottomToolBar];

    [_topToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_topToolBar.superview.mas_top).offset(-64);
        make.left.mas_equalTo(_topToolBar.superview.mas_left);
        make.right.mas_equalTo(_topToolBar.superview.mas_right);
        make.height.mas_equalTo(64);
    }];

    [_bottomToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(_bottomToolBar.superview.mas_bottom).offset(49);
        make.left.mas_equalTo(_bottomToolBar.superview.mas_left);
        make.right.mas_equalTo(_bottomToolBar.superview.mas_right);
        make.height.mas_equalTo(49);
    }];
}

- (void)cancelSignature {
    [self.toolHandler delete];
    [_extensionsManager setCurrentToolHandler:nil];
    [_extensionsManager changeState:STATE_NORMAL];
}

- (void)setToolBarHiden:(BOOL)toolBarHiden {
    if (toolBarHiden) {
        CGRect topToolbarFrame = _topToolBar.frame;
        topToolbarFrame.origin.y -= 64;
        CGRect bottomToolBarFrame = _bottomToolBar.frame;
        bottomToolBarFrame.origin.y += 49;
        [UIView animateWithDuration:0.3
                         animations:^{
                             _topToolBar.frame = topToolbarFrame;
                             _bottomToolBar.frame = bottomToolBarFrame;
                             [_topToolBar mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.top.mas_equalTo(_topToolBar.superview.mas_top).offset(-64);
                                 make.left.mas_equalTo(_topToolBar.superview.mas_left);
                                 make.right.mas_equalTo(_topToolBar.superview.mas_right);
                                 make.height.mas_equalTo(64);
                             }];

                             [_bottomToolBar mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.bottom.mas_equalTo(_bottomToolBar.superview.mas_bottom).offset(49);
                                 make.left.mas_equalTo(_bottomToolBar.superview.mas_left);
                                 make.right.mas_equalTo(_bottomToolBar.superview.mas_right);
                                 make.height.mas_equalTo(49);
                             }];
                         }];
        _topToolBar.hidden = YES;
        _bottomToolBar.hidden = YES;
    } else {
        _topToolBar.hidden = NO;
        _bottomToolBar.hidden = NO;
        CGRect topToolbarFrame = _topToolBar.frame;
        topToolbarFrame.origin.y += 64;
        CGRect bottomToolBarFrame = _bottomToolBar.frame;
        bottomToolBarFrame.origin.y -= 49;
        [UIView animateWithDuration:0.3
                         animations:^{
                             _topToolBar.frame = topToolbarFrame;
                             _bottomToolBar.frame = bottomToolBarFrame;
                             [_topToolBar mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.top.mas_equalTo(_topToolBar.superview.mas_top);
                                 make.left.mas_equalTo(_topToolBar.superview.mas_left);
                                 make.right.mas_equalTo(_topToolBar.superview.mas_right);
                                 make.height.mas_equalTo(64);
                             }];

                             [_bottomToolBar mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.bottom.mas_equalTo(_bottomToolBar.superview.mas_bottom);
                                 make.left.mas_equalTo(_bottomToolBar.superview.mas_left);
                                 make.right.mas_equalTo(_bottomToolBar.superview.mas_right);
                                 make.height.mas_equalTo(49);
                             }];
                         }];
    }
}

#pragma mark IHandlerEventListener

- (void)onToolChanged:(NSString *)lastToolName CurrentToolName:(NSString *)toolName {
    if ([toolName isEqualToString:Tool_Signature]) {
        [self annotItemClicked];
    } else if ([lastToolName isEqualToString:Tool_Signature]) {
        [self setToolBarHiden:YES];
        if (toolName == nil) {
            [_extensionsManager changeState:STATE_NORMAL];
        }
    }
}

- (void)annotItemClicked {
    [_extensionsManager.toolSetBar removeAllItems];
    [_extensionsManager changeState:STATE_SIGNATURE];
}

- (void)setToolBarItemHidden:(BOOL)toolBarItemHidden {
    if (toolBarItemHidden && self.signItem) {
        [_extensionsManager.toolSetBar removeItem:self.signItem];
    } else {
        if (!self.signItem) {
            self.signItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"sign_list"] imageSelected:[UIImage imageNamed:@"sign_list"] imageDisable:[UIImage imageNamed:@"sign_list"] background:[UIImage imageNamed:@"annotation_toolitembg"]];
            self.signItem.tag = 3;
            UIExtensionsManager *extensionsManager = _extensionsManager; // avoid strong-reference to self
            self.signItem.onTapClick = ^(TbBaseItem *item) {
                SignToolHandler *signToolHandler = (SignToolHandler *) [extensionsManager getToolHandlerByName:Tool_Signature];
                [signToolHandler signList];
            };
        }
        [_extensionsManager.toolSetBar addItem:self.signItem displayPosition:Position_CENTER];
    }
}

#pragma mark - IStateChangeListener

- (void)onStateChanged:(int)state {
    if (state == STATE_SIGNATURE) {
        [self setToolBarHiden:NO];
    } else {
        [self setToolBarHiden:YES];
    }
}

#pragma mark <IDocEventListener>
- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    if (document) {
        self.signatureButton.enabled = [Utility canAddSignToDocument:document];
    }
}

#pragma mark create button
- (UIButton *)createButtonWithTitle:(NSString *)title image:(UIImage *)image {
    UIFont *textFont = [UIFont systemFontOfSize:9.f];
    CGSize titleSize = [Utility getTextSize:title fontSize:textFont.pointSize maxSize:CGSizeMake(400, 100)];
    float width = image.size.width;
    float height = image.size.height;
    CGRect frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width : width, titleSize.height + height);
    
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [button setEnlargedEdge:ENLARGE_EDGE];
    
    [button setTitle:title forState:UIControlStateNormal];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, -height, 0);
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = textFont;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    [button setImage:image forState:UIControlStateNormal];
    UIImage *translucentImage = [Utility imageByApplyingAlpha:image alpha:0.5];
    [button setImage:translucentImage forState:UIControlStateHighlighted];
    [button setImage:translucentImage forState:UIControlStateDisabled];
    button.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width);
    
    return button;
}


@end
