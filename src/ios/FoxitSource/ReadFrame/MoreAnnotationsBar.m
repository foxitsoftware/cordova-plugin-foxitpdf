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
#import "MoreAnnotationsBar.h"
#import <FoxitRDK/FSPDFViewControl.h>


@interface MoreAnnotationsBar ()

//TextMarkup
@property (nonatomic,retain) UILabel *textLabel;

@property (nonatomic,retain) UIButton *highlightBtn;
@property (nonatomic,retain) UIButton *underlineBtn;
@property (nonatomic,retain) UIButton *breaklineBtn;
@property (nonatomic,retain) UIButton *strokeoutBtn;
@property (nonatomic,strong) UIButton *insertBtn;
@property (nonatomic,strong) UIButton *replaceBtn;

@property (nonatomic,retain) UIView *divideView1;

//Draw
@property (nonatomic,retain) UILabel *drawLabel;

@property (nonatomic,retain) UIButton *lineBtn;
@property (nonatomic,retain) UIButton *rectBtn;
@property (nonatomic,retain) UIButton *circleBtn;
@property (nonatomic,retain) UIButton *arrowsBtn;
@property (nonatomic,retain) UIButton *pencileBtn;
@property (nonatomic,retain) UIButton *eraserBtn;

@property (nonatomic,retain) UIView *divideView2;

//Others
@property (nonatomic,retain) UILabel *othersLabel;

@property (nonatomic,retain) UIButton *typewriterBtn;
@property (nonatomic,retain) UIButton *noteBtn;
@property (nonatomic,retain) UIButton *stampBtn;

@end

@implementation MoreAnnotationsBar


-(MoreAnnotationsBar*)init:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.contentView = [[[UIView alloc] initWithFrame:frame] autorelease];
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        //TextMarkup
        self.textLabel = [[[UILabel alloc] init] autorelease];
        self.textLabel.text = NSLocalizedString(@"kMoreTextMarkup", nil);
        self.textLabel.font = [UIFont systemFontOfSize:16.0f];
        self.textLabel.textColor = [UIColor darkGrayColor];
        [self.contentView addSubview:self.textLabel];
        
        
        UIImage *hightImage = [UIImage imageNamed:@"annot_hight"];
        UIImage *underlineImage = [UIImage imageNamed:@"annot_underline"];
        UIImage *breaklineImage = [UIImage imageNamed:@"annot_breakline"];
        UIImage *strokeoutImage = [UIImage imageNamed:@"annot_strokeout"];
        UIImage *replaceImage = [UIImage imageNamed:@"annot_replace"];
        UIImage *insertImage = [UIImage imageNamed:@"annot_insert"];
        
        self.highlightBtn = [MoreAnnotationsBar createItemWithImage:hightImage];
        self.underlineBtn = [MoreAnnotationsBar createItemWithImage:underlineImage];
        self.breaklineBtn = [MoreAnnotationsBar createItemWithImage:breaklineImage];
        self.strokeoutBtn = [MoreAnnotationsBar createItemWithImage:strokeoutImage];
        self.replaceBtn = [MoreAnnotationsBar createItemWithImage:replaceImage];
        self.insertBtn = [MoreAnnotationsBar createItemWithImage:insertImage];
        
        self.highlightBtn.frame = CGRectMake(0, 100, hightImage.size.width, hightImage.size.height);
        self.underlineBtn.frame = CGRectMake(0, 100, underlineImage.size.width, underlineImage.size.height);
        self.breaklineBtn.frame = CGRectMake(0, 100, breaklineImage.size.width, breaklineImage.size.height);
        self.strokeoutBtn.frame = CGRectMake(0, 100, strokeoutImage.size.width, strokeoutImage.size.height);
        self.insertBtn.frame = CGRectMake(0, 100, insertImage.size.width, insertImage.size.height);
        self.replaceBtn.frame = CGRectMake(0, 100, replaceImage.size.width, replaceImage.size.height);
        
        [self.contentView addSubview:self.highlightBtn];
        [self.contentView addSubview:self.underlineBtn];
        [self.contentView addSubview:self.breaklineBtn];
        [self.contentView addSubview:self.strokeoutBtn];
        [self.contentView addSubview:self.insertBtn];
        [self.contentView addSubview:self.replaceBtn];
        
        self.divideView1 = [[[UIView alloc] init] autorelease];
        self.divideView1.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
        [self.contentView addSubview:self.divideView1];
        
        //Drawing
        self.drawLabel = [[[UILabel alloc] init] autorelease];
        self.drawLabel.text = NSLocalizedString(@"kMoreDrawing", nil);
        self.drawLabel.font = [UIFont systemFontOfSize:16.0f];
        self.drawLabel.textColor = [UIColor darkGrayColor];
        [self.contentView addSubview:self.drawLabel];
        
        UIImage *lineImage = [UIImage imageNamed:@"annot_line"];
        UIImage *rectImage = [UIImage imageNamed:@"annot_rect"];
        UIImage *circleImage = [UIImage imageNamed:@"annot_circle"];
        UIImage *arrowsImage = [UIImage imageNamed:@"annot_arrows"];
        UIImage *pencileImage = [UIImage imageNamed:@"annot_pencile"];
        UIImage *eraserImage = [UIImage imageNamed:@"annot_eraser"];
        self.lineBtn = [MoreAnnotationsBar createItemWithImage:lineImage];
        self.rectBtn = [MoreAnnotationsBar createItemWithImage:rectImage];
        self.circleBtn = [MoreAnnotationsBar createItemWithImage:circleImage];
        self.arrowsBtn = [MoreAnnotationsBar createItemWithImage:arrowsImage];
        self.pencileBtn = [MoreAnnotationsBar createItemWithImage:pencileImage];
        self.eraserBtn = [MoreAnnotationsBar createItemWithImage:eraserImage];
        
        self.lineBtn.frame = CGRectMake(0, 100, lineImage.size.width, lineImage.size.height);
        self.rectBtn.frame = CGRectMake(0, 100, rectImage.size.width, rectImage.size.height);
        self.circleBtn.frame = CGRectMake(0, 100, circleImage.size.width, circleImage.size.height);
        self.arrowsBtn.frame = CGRectMake(0, 100, arrowsImage.size.width, arrowsImage.size.height);
        self.pencileBtn.frame = CGRectMake(0, 100, pencileImage.size.width, pencileImage.size.height);
        self.eraserBtn.frame = CGRectMake(0, 100, eraserImage.size.width, eraserImage.size.height);
        
        [self.contentView addSubview:self.lineBtn];
        [self.contentView addSubview:self.rectBtn];
        [self.contentView addSubview:self.circleBtn];
        [self.contentView addSubview:self.arrowsBtn];
        [self.contentView addSubview:self.pencileBtn];
        [self.contentView addSubview:self.eraserBtn];
        
        self.divideView2 = [[[UIView alloc] init] autorelease];
        self.divideView2.backgroundColor = [UIColor colorWithRGBHex:0xe6e6e6];
        [self.contentView addSubview:self.divideView2];
        
        
        self.rectBtn.center = CGPointMake((frame.size.width-20)/12, 120);
        self.circleBtn.center = CGPointMake((frame.size.width-20)/12*3, 120);
        self.lineBtn.center = CGPointMake((frame.size.width-20)/12*5, 120);
        self.arrowsBtn.center = CGPointMake((frame.size.width-20)/12*7, 120);
        self.pencileBtn.center = CGPointMake((frame.size.width-20)/12*9, 120);
        self.eraserBtn.center = CGPointMake((frame.size.width-20)/12*11, 120);


        //Others
        self.othersLabel = [[[UILabel alloc] init] autorelease];
        self.othersLabel.text = NSLocalizedString(@"kMoreOthers", nil);
        self.othersLabel.font = [UIFont systemFontOfSize:16.0f];
        self.othersLabel.textColor = [UIColor darkGrayColor];
        [self.contentView addSubview:self.othersLabel];
        

        UIImage *typeriterImage = [UIImage imageNamed:@"annot_typewriter_more"];
        UIImage *noteImage = [UIImage imageNamed:@"annot_note_more"];
        UIImage *stampImage = [UIImage imageNamed:@"annot_stamp_more"];
        
        self.typewriterBtn = [MoreAnnotationsBar createItemWithImageAndTitle:NSLocalizedString(@"kTypewriter", nil) imageNormal:typeriterImage];
        self.noteBtn = [MoreAnnotationsBar createItemWithImageAndTitle:NSLocalizedString(@"kNote", nil) imageNormal:noteImage];
        self.stampBtn = [MoreAnnotationsBar createItemWithImageAndTitle:NSLocalizedString(@"kPropertyStamps", nil) imageNormal:stampImage];
        
        self.typewriterBtn.frame = CGRectMake(0, 230, self.typewriterBtn.bounds.size.width,self.typewriterBtn.bounds.size.height);
        self.noteBtn.frame = CGRectMake(0, 230, self.noteBtn.bounds.size.width,self.noteBtn.bounds.size.height);
        self.stampBtn.frame = CGRectMake(0, 230, self.stampBtn.bounds.size.width,self.stampBtn.bounds.size.height);
        
        self.typewriterBtn.center = CGPointMake((frame.size.width-20)/8, 210);
        self.noteBtn.center = CGPointMake((frame.size.width-20)/8*3, 210);
                self.stampBtn.center = CGPointMake((frame.size.width-20)/8*5, 210);
        
        [self.contentView addSubview:self.typewriterBtn];
        [self.contentView addSubview:self.noteBtn];
        [self.contentView addSubview:self.stampBtn];

        [self buildLayout];
        [self onItemOnClicked];
        
    }
    return self;
}

- (void)dealloc
{
    [_contentView release];
    [_highLightClicked release];
    [_underLineClicked release];
    [_strikeOutClicked release];
    [_breakLineClicked release];
    [_replaceClicked release];
    [_insertClicked release];
    [_rectClicked release];
    [_lineClicked release];
    [_circleClicked release];
    [_arrowsClicked release];
    [_pencileClicked release];
    [_eraserClicked release];
    [_typerwriterClicked release];
    [_noteClicked release];
    [_textLabel release];
    [_highlightBtn release];
    [_underlineBtn release];
    [_breaklineBtn release];
    [_strokeoutBtn release];
    [_insertBtn release];
    [_replaceBtn release];
    [_divideView1 release];
    [_drawLabel release];
    [_lineBtn release];
    [_rectBtn release];
    [_circleBtn release];
    [_arrowsBtn release];
    [_pencileBtn release];
    [_eraserBtn release];
    [_divideView2 release];
    [_othersLabel release];
    [_typewriterBtn release];
    [_noteBtn release];
    [_stampBtn release];
    
    [super dealloc];
}

-(void)buildLayout
{
    [self.textLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.rectBtn.mas_left).offset(0);
        make.top.equalTo(self.contentView.mas_top).offset(10);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(20);
    }];
    
    [self.drawLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.rectBtn.mas_left).offset(0);
        make.top.equalTo(self.contentView.mas_top).offset(80);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(20);
    }];
    
    [self.othersLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.rectBtn.mas_left).offset(0);
        make.top.equalTo(self.contentView.mas_top).offset(160);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(20);
    }];
    
    
    [self.highlightBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.rectBtn.mas_left).offset(0);
        make.top.equalTo(self.textLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(self.highlightBtn.bounds.size.width);
        make.height.mas_equalTo(self.highlightBtn.bounds.size.height);
    }];
    [self.underlineBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.circleBtn.mas_left).offset(0);
        make.top.equalTo(self.textLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(self.underlineBtn.bounds.size.width);
        make.height.mas_equalTo(self.underlineBtn.bounds.size.height);
    }];
    [self.breaklineBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.lineBtn.mas_left).offset(0);
        make.top.equalTo(self.textLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(self.breaklineBtn.bounds.size.width);
        make.height.mas_equalTo(self.breaklineBtn.bounds.size.height);
    }];
    [self.strokeoutBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.arrowsBtn.mas_left).offset(0);
        make.top.equalTo(self.textLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(self.strokeoutBtn.bounds.size.width);
        make.height.mas_equalTo(self.strokeoutBtn.bounds.size.height);
    }];
    [self.replaceBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.pencileBtn.mas_left).offset(0);
        make.top.equalTo(self.textLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(self.replaceBtn.bounds.size.width);
        make.height.mas_equalTo(self.replaceBtn.bounds.size.height);
    }];
    [self.insertBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.eraserBtn.mas_left).offset(0);
        make.top.equalTo(self.textLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(self.insertBtn.bounds.size.width);
        make.height.mas_equalTo(self.insertBtn.bounds.size.height);
    }];
    
    
    [self.divideView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(5);
        make.right.equalTo(self.contentView.mas_right).offset(-5);
        make.top.equalTo(self.contentView.mas_top).offset(75);
        make.height.mas_equalTo([Utility realPX:1.0f]);
    }];
    
    [self.divideView2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(5);
        make.right.equalTo(self.contentView.mas_right).offset(-5);
        make.top.equalTo(self.contentView.mas_top).offset(150);
        make.height.mas_equalTo([Utility realPX:1.0f]);
    }];
    
}


-(void)onItemOnClicked
{
    [self.highlightBtn addTarget:self action:@selector(onHighLightClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.underlineBtn addTarget:self action:@selector(onUnderLineClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.breaklineBtn addTarget:self action:@selector(onBreakLineClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.strokeoutBtn addTarget:self action:@selector(onStrikeOutClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.replaceBtn addTarget:self action:@selector(onReplaceClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.insertBtn addTarget:self action:@selector(onInsertClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [self.lineBtn addTarget:self action:@selector(onLineClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.rectBtn addTarget:self action:@selector(onRectClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.circleBtn addTarget:self action:@selector(onCircleClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.arrowsBtn addTarget:self action:@selector(onArrowsClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.pencileBtn addTarget:self action:@selector(onPencilClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.eraserBtn addTarget:self action:@selector(onEraserClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [self.typewriterBtn addTarget:self action:@selector(onTyperwriterClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [self.noteBtn addTarget:self action:@selector(onNoteClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.stampBtn addTarget:self action:@selector(onStampClicked) forControlEvents:UIControlEventTouchUpInside];
}

-(void)onHighLightClicked
{
    if (self.highLightClicked) {
        self.highLightClicked();
    }
}

-(void)onUnderLineClicked
{
    if (self.underLineClicked) {
        self.underLineClicked();
    }
}

-(void)onStrikeOutClicked
{
    if (self.strikeOutClicked) {
        self.strikeOutClicked();
    }
}

-(void)onBreakLineClicked
{
    if (self.breakLineClicked) {
        self.breakLineClicked();
    }
}

-(void)onLineClicked
{
    if (self.lineClicked) {
        self.lineClicked();
    }
}

-(void)onRectClicked
{
    if (self.rectClicked) {
        self.rectClicked();
    }
}

-(void)onCircleClicked
{
    if (self.circleClicked) {
        self.circleClicked();
    }
}

-(void)onArrowsClicked
{
    if (self.arrowsClicked) {
        self.arrowsClicked();
    }
}

-(void)onPencilClicked
{
    if (self.pencileClicked) {
        self.pencileClicked();
    }
}

-(void)onEraserClicked
{
    if (self.eraserClicked) {
        self.eraserClicked();
    }
}

-(void)onTyperwriterClicked
{
    if (self.typerwriterClicked) {
        self.typerwriterClicked();
    }
}

-(void)onNoteClicked
{
    if (self.noteClicked) {
        self.noteClicked();
    }
}


-(void)onStampClicked
{
    if (self.stampClicked) {
        self.stampClicked();
    }
}

-(void)onInsertClicked
{
    if (self.insertClicked)
        self.insertClicked();
}

-(void)onReplaceClicked
{
    if (self.replaceClicked)
        self.replaceClicked();
}

//create button with image.
+(UIButton*)createItemWithImage:(UIImage*)imageNormal
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.contentMode = UIViewContentModeScaleToFill;
    [button setImage:imageNormal forState:UIControlStateNormal];
    [button setImage:[MoreAnnotationsBar imageByApplyingAlpha:imageNormal alpha:0.5] forState:UIControlStateHighlighted];
    [button setImage:[MoreAnnotationsBar imageByApplyingAlpha:imageNormal alpha:0.5] forState:UIControlStateSelected];
    return button;
}

+ (UIButton*)createItemWithImageAndTitle:(NSString*)title
                             imageNormal:(UIImage*)imageNormal
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    CGSize titleSize = [Utility getTextSize:title fontSize:12.0f maxSize:CGSizeMake(300, 200)];
    
    float width = imageNormal.size.width ;
    float height = imageNormal.size.height ;
    button.contentMode = UIViewContentModeScaleToFill;
    [button setImage:imageNormal forState:UIControlStateNormal];
    [button setImage:[MoreAnnotationsBar imageByApplyingAlpha:imageNormal alpha:0.5] forState:UIControlStateHighlighted];
    [button setImage:[MoreAnnotationsBar imageByApplyingAlpha:imageNormal alpha:0.5] forState:UIControlStateSelected];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    button.titleLabel.font = [UIFont systemFontOfSize:12.0f];
    
    button.titleEdgeInsets = UIEdgeInsetsMake(0, -width, -height, 0);
    button.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width);
    button.frame = CGRectMake(0, 0, titleSize.width > width ? titleSize.width + 2: width,  titleSize.height + height);
    
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

@end
