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
#import "StampIconController.h"
#import "Utility.h"
#import "ColorUtility.h"
#import "Const.h"
#import "SegmentView.h"
#import "UIExtensionsManager+Private.h"

@implementation StampButton

@end

@implementation StampCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        float stampWidth = 130;
        
        float divideWidth = (DEVICE_iPHONE ? (SCREENWIDTH - stampWidth*2): (300 - stampWidth*2)) - 20*2;
        
        StampButton *left = [[StampButton alloc] initWithFrame:CGRectMake(15, 15, stampWidth, 42)];
        left.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        left.tag = 100;
        
        StampButton *right = [[StampButton alloc] initWithFrame:CGRectMake(15 + stampWidth + divideWidth , 15, stampWidth, 42)];
        right.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        right.tag = 101;
        
        StampButton *center = [[StampButton alloc] init];
        center.tag = 102;
        
        [self.contentView addSubview:left];
        [self.contentView addSubview:right];
        [self.contentView addSubview:center];
    }
    return self;
    
}

@end

#define STAMP_TYPE_STANDER 1
#define STAMP_TYPE_SIGNHERE 2
#define STAMP_TYPE_DYNAMIC 3

@interface StampIconController ()

@property (nonatomic, assign) CGPDFDocumentRef pdfDocumentRef;
@property (nonatomic, retain) UIView *toolbar;
@property (nonatomic, retain) UIButton *backBtn;
@property (nonatomic, retain) UITableView *stampLayout;
@property (nonatomic, assign) int currentStampType;
@property (nonatomic, assign) BOOL isiPhoneLandscape;
@property (nonatomic, retain) SegmentView *segmengView;
@property (nonatomic, retain) UILabel *titleLabel;


@end

@implementation StampIconController {
    UIExtensionsManager* _extensionManager;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionManager = extensionsManager;
        self.currentIcon = extensionsManager.stampIcon;
        
        self.isiPhoneLandscape = NO;
        self.pdfDocumentRef = nil;
        NSURL *pdfURL = [[NSBundle mainBundle] URLForResource:@"icon" withExtension:@"pdf"];
        self.pdfDocumentRef = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)itemClickWithItem:(SegmentItem *)item;
{
    if (item.tag == 1) {
        _currentStampType = STAMP_TYPE_STANDER;
    }
    else if (item.tag == 2)
    {
        _currentStampType = STAMP_TYPE_SIGNHERE;
    }
    else if (item.tag == 3)
    {
        _currentStampType = STAMP_TYPE_DYNAMIC;
    }
    [self.stampLayout reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isiPhoneLandscape = NO;
    if (DEVICE_iPHONE && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
        self.isiPhoneLandscape = YES;
    }
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    self.toolbar = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 104)] autorelease];
    self.toolbar.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    [self.view addSubview:self.toolbar];
    
    self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backBtn.frame = CGRectMake(20, 30, 26, 26);
    [self.backBtn setImage:[UIImage imageNamed:@"panel_cancel"] forState:UIControlStateNormal];
    [self.backBtn addTarget:self action:@selector(backClicked) forControlEvents:UIControlEventTouchUpInside];
    if (DEVICE_iPHONE) {
        [self.toolbar addSubview:self.backBtn];
    }
    
    UILabel *title = [[[UILabel alloc] initWithFrame:CGRectMake(self.toolbar.frame.size.width/2 - 40, DEVICE_iPHONE ? 30 : 10, 80, 30)] autorelease];
    title.text = NSLocalizedString(@"kPropertyStamps", nil);
    title.textColor = [UIColor blackColor];
    title.font = [UIFont systemFontOfSize:18.0f];
    title.textAlignment = NSTextAlignmentCenter;
    self.titleLabel = title;
    [self.toolbar addSubview:title];
    
    SegmentItem *standItem = [[[SegmentItem alloc] init] autorelease];
    standItem.image = [UIImage imageNamed:@"annot_stamp_standard"];
    standItem.selectImage = [UIImage imageNamed:@"annot_stamp_standard_selected"];
    standItem.tag = 1;
    
    SegmentItem *signHereItem = [[[SegmentItem alloc] init] autorelease];
    signHereItem.image = [UIImage imageNamed:@"annot_stamp_sign"];
    signHereItem.selectImage = [UIImage imageNamed:@"annot_stamp_sign_selected"];
    signHereItem.tag = 2;
    
    SegmentItem *dynamicItem = [[[SegmentItem alloc] init] autorelease];
    dynamicItem.image = [UIImage imageNamed:@"annot_stamp_dynamic"];
    dynamicItem.selectImage = [UIImage imageNamed:@"annot_stamp_dynamic_selected"];
    dynamicItem.tag = 3;
    
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:standItem];
    [array addObject:signHereItem];
    [array addObject:dynamicItem];
    
    SegmentView *segmentView = [[SegmentView alloc] initWithFrame:CGRectMake(20, DEVICE_iPHONE ? 65 : 45, self.view.frame.size.width - 40, 32) segmentItems:array];
    segmentView.delegate = self;
    self.segmengView = segmentView;
    
    if (self.currentIcon >= 0 && self.currentIcon <= 11) {
        [segmentView setSelectItem:standItem];
        _currentStampType = STAMP_TYPE_STANDER;
    }else if (self.currentIcon >= 12 && self.currentIcon <= 16){
        [segmentView setSelectItem:signHereItem];
        _currentStampType = STAMP_TYPE_SIGNHERE;
    }else if (self.currentIcon >= 17 && self.currentIcon <= 21)
    {
        [segmentView setSelectItem:dynamicItem];
        _currentStampType = STAMP_TYPE_DYNAMIC;
    }else{
        [segmentView setSelectItem:standItem];
        _currentStampType = STAMP_TYPE_STANDER;
    }

    [self.view addSubview:segmentView];
    
    UIView *divide = [[UIView alloc] initWithFrame:CGRectMake(20, DEVICE_iPHONE ? 105 : 85, self.view.frame.size.width-40, [Utility realPX:1.0f])];
    divide.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
    [self.view addSubview:divide];
    
    CGRect layoutFrame;
    if (DEVICE_iPHONE) {
        layoutFrame = CGRectMake(0, 110, self.view.frame.size.width, self.view.frame.size.height - 110);
    }
    else
    {
        layoutFrame = CGRectMake(0,  90, self.view.frame.size.width, self.view.frame.size.height - 90);
    }
    self.stampLayout = [[UITableView alloc] initWithFrame:layoutFrame];
    self.stampLayout.backgroundColor = [UIColor whiteColor];
    self.stampLayout.delegate = self;
    self.stampLayout.dataSource = self;
    [self.stampLayout setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.view addSubview:self.stampLayout];
}


-(void)backClicked
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)dealloc
{
    self.selectHandler = nil;
    if (self.pdfDocumentRef)
    {
        CGPDFDocumentRelease(self.pdfDocumentRef);
    }
    [super dealloc];
}

#pragma mark - Properties

- (void)setCurrentIcon:(int)currentIcon
{
    _currentIcon = currentIcon;
}

#pragma mark -  table view delegate handler
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


#pragma mark -  table view datasource handler

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_currentStampType == STAMP_TYPE_STANDER) {
        if (self.isiPhoneLandscape) {
            return 4;
        }else
        {
           return 6;
        }
    }
    else if (_currentStampType == STAMP_TYPE_SIGNHERE)
    {
        if (self.isiPhoneLandscape) {
            return 2;
        }else
        {
            return 3;
        }
    }
    else if (_currentStampType == STAMP_TYPE_DYNAMIC)
    {
        if (self.isiPhoneLandscape) {
            return 2;
        }else
        {
            return 3;
        }
    }
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellidentifer=@"CellIdentifer";
    StampCell* cell=[tableView dequeueReusableCellWithIdentifier:cellidentifer];
    
    if (cell == nil) {
        
        cell=[[[StampCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellidentifer]autorelease];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
    StampButton *left = (StampButton*)[cell.contentView viewWithTag:100];
    StampButton *right = (StampButton*)[cell.contentView viewWithTag:101];
    StampButton *center = (StampButton *)[cell.contentView viewWithTag:102];
    self.isiPhoneLandscape = NO;
    CGRect frame = [UIScreen mainScreen].bounds;
    if (DEVICE_iPHONE) {
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            self.isiPhoneLandscape = YES;
            center.hidden = NO;
            if(!OS_ISVERSION8){
                frame = CGRectMake(0, 0, frame.size.height, frame.size.width);
            }
            center.frame = CGRectMake(frame.size.width * 0.5 - 130 * 0.5, 15, 130, 42);
            center.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        }else
        {
            center.hidden = YES;
        }
        right.frame = CGRectMake(frame.size.width - 15 - 130, 15, 130, 42);
    }
    int index = 20;
    if (_currentStampType == STAMP_TYPE_STANDER) {
        index = 20;
        if (self.isiPhoneLandscape) {
            left.stampIcon = indexPath.row * 3;
            center.stampIcon = indexPath.row * 3 + 1;
            right.stampIcon = indexPath.row * 3 + 2;
        }else
        {
            left.stampIcon = indexPath.row * 2;
            right.stampIcon = indexPath.row * 2 + 1;
        }
    }
    else if (_currentStampType == STAMP_TYPE_SIGNHERE)
    {
        index = 32;
        if (self.isiPhoneLandscape) {
            left.stampIcon = 12 + indexPath.row * 3;
            center.stampIcon = 12 + indexPath.row * 3 + 1;
            right.stampIcon = 12 + indexPath.row * 3 + 2;
        }else
        {
            left.stampIcon = 12 + indexPath.row * 2;
            right.stampIcon = 12 + indexPath.row * 2 + 1;
        }
    }
    else if (_currentStampType == STAMP_TYPE_DYNAMIC)
    {
        index = 37;
        if (self.isiPhoneLandscape) {
            left.stampIcon = 17 + indexPath.row * 3;
            center.stampIcon = 17 + indexPath.row * 3 + 1;
            right.stampIcon = 17 + indexPath.row * 3 + 2;
        }else
        {
            left.stampIcon = 17 + indexPath.row * 2;
            right.stampIcon = 17 + indexPath.row * 2 + 1;
        }
    }
    
    if (self.isiPhoneLandscape) {
        index += indexPath.row * 3;
    }else
    {
        index += indexPath.row * 2;
    }
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(200, 60), YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPDFPageRef page = CGPDFDocumentGetPage(_pdfDocumentRef, index);
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, 60);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextScaleCTM(context, 2.0, 2.0);
    CGContextDrawPDFPage(context, page);
    CGContextRestoreGState(context);
    [left setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
    UIGraphicsEndImageContext();
    [left addTarget:self action:@selector(onClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if (index - 20 == self.currentIcon) {
        left.layer.borderWidth = 2.0f;
        left.layer.borderColor = [[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] CGColor];
        left.layer.cornerRadius = 5.0f;
        left.backgroundColor = [UIColor clearColor];
    }
    else{
        left.layer.borderWidth = 0.0f;
    }
    
    if (self.isiPhoneLandscape) {
        index++;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(200, 60), YES, [UIScreen mainScreen].scale);
        CGContextRef context3 = UIGraphicsGetCurrentContext();
        CGPDFPageRef page3 = CGPDFDocumentGetPage(_pdfDocumentRef, index);
        CGContextSaveGState(context3);
        CGContextTranslateCTM(context3, 0.0, 60);
        CGContextScaleCTM(context3, 1.0, -1.0);
        CGContextScaleCTM(context3, 2.0, 2.0);
        CGContextDrawPDFPage(context3, page3);
        CGContextRestoreGState(context3);
        [center setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
        
        UIGraphicsEndImageContext();
        [center addTarget:self action:@selector(onClicked:) forControlEvents:UIControlEventTouchUpInside];
        if (index - 20 == self.currentIcon) {
            center.layer.borderWidth = 2.0f;
            center.layer.borderColor = [[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] CGColor];
            center.layer.cornerRadius = 5.0f;
            center.backgroundColor = [UIColor clearColor];
        }
        else{
            center.layer.borderWidth = 0.0f;
        }
    }
    
    index++;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(200, 60), YES, [UIScreen mainScreen].scale);
    CGContextRef context1 = UIGraphicsGetCurrentContext();
    CGPDFPageRef page1 = CGPDFDocumentGetPage(_pdfDocumentRef, index);
    CGContextSaveGState(context1);
    CGContextTranslateCTM(context1, 0.0, 60);
    CGContextScaleCTM(context1, 1.0, -1.0);
    CGContextScaleCTM(context1, 2.0, 2.0);
    CGContextDrawPDFPage(context1, page1);
    CGContextRestoreGState(context1);
    [right setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
    if (index == 42 || index == 37) {
        right.hidden = YES;
    }
    else
    {
        right.hidden = NO;
    }
    UIGraphicsEndImageContext();
    [right addTarget:self action:@selector(onClicked:) forControlEvents:UIControlEventTouchUpInside];
    if (index - 20 == self.currentIcon) {
        right.layer.borderWidth = 2.0f;
        right.layer.borderColor = [[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] CGColor];
        right.layer.cornerRadius = 5.0f;
        right.backgroundColor = [UIColor clearColor];
    }
    else{
        right.layer.borderWidth = 0.0f;
    }
    return cell;
}

-(void)onClicked:(id)sender
{
    StampButton *button = (StampButton*)sender;
    self.currentIcon = button.stampIcon;
    _extensionManager.stampIcon = self.currentIcon;
    [self.stampLayout reloadData];
    if (_selectHandler) {
        _selectHandler(button.stampIcon);
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)resizeView
{
    if (DEVICE_iPHONE) {
        CGRect frame = [UIScreen mainScreen].bounds;
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            frame = CGRectMake(0, 0, frame.size.height, frame.size.width);
        }
        self.toolbar.frame = CGRectMake(0, 0, frame.size.width, 104);
        self.titleLabel.frame = CGRectMake(self.toolbar.frame.size.width/2 - 40, 30, 80, 30);
        self.segmengView.frame = CGRectMake(20, 65, frame.size.width - 40, 32);
        self.stampLayout.frame = CGRectMake(0, 110, frame.size.width, frame.size.height);
        [self.stampLayout reloadData];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.isiPhoneLandscape = NO;
    if (DEVICE_iPHONE && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
        self.isiPhoneLandscape = YES;
    }else
    {
        self.isiPhoneLandscape = NO;
    }
    [self resizeView];
}
@end
