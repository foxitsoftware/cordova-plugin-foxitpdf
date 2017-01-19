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
#import "FontLayout.h"
#import "PropertyBar.h"
#import "ColorUtility.h"
#import "Utility.h"

#define FontNameType 1
#define FontSizeType 2

@interface FontLayout ()

@property (nonatomic, retain) UILabel *title;
@property (nonatomic, retain) NSString *currentFontName;
@property (nonatomic, assign) int currentFontSize;
@property (nonatomic, retain) id<IPropertyValueChangedListener> currentListener;

@property (nonatomic, retain) UIButton *backBtn;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIView *titleBar;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIButton *fontNameBtn;
@property (nonatomic, retain) UIButton *fontSizeBtn;
@property (nonatomic, retain) NSMutableArray *arrayFontNames;
@property (nonatomic, retain) NSDictionary *dictFontSizes;
@property (nonatomic, retain) NSArray *arrayFontSizes;
@property (nonatomic, assign) int currentFontType;

@end

@implementation FontLayout

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.title = [[[UILabel alloc] initWithFrame:CGRectMake(20, 3, frame.size.width, LAYOUTTITLEHEIGHT)] autorelease];
        self.title.text = NSLocalizedString(@"kFont", nil);
        self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
        self.title.font = [UIFont systemFontOfSize:11.0f];
        [self addSubview:self.title];
        
        self.fontNameBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect fontNameFrame = CGRectMake(ITEMLRSPACE, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, (frame.size.width - ITEMLRSPACE*3)*2/3, 30);
        self.fontNameBtn.frame = fontNameFrame;
        [self.fontNameBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.fontNameBtn.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
        self.fontNameBtn.backgroundColor = [UIColor whiteColor];
        self.fontNameBtn.contentMode = UIViewContentModeScaleToFill;
        self.fontNameBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        self.fontNameBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.fontNameBtn.layer.borderWidth = 1.0f;
        self.fontNameBtn.layer.cornerRadius = 3.0f;
        self.fontNameBtn.layer.borderColor = [[UIColor colorWithRGBHex:0x5c5c5c alpha:0.2] CGColor];
        self.fontSizeBtn.backgroundColor = [UIColor clearColor];
        
        [self.fontNameBtn addTarget:self action:@selector(showFontNameLayout) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.fontNameBtn];
        
        self.fontSizeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect fontSizeFrame = CGRectMake(ITEMLRSPACE*2 + self.fontNameBtn.frame.size.width, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, (frame.size.width - ITEMLRSPACE*3)/3, 30);
        self.fontSizeBtn.frame = fontSizeFrame;
        [self.fontSizeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.fontSizeBtn.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
        self.fontSizeBtn.contentMode = UIViewContentModeScaleToFill;
        self.fontSizeBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        self.fontSizeBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.fontSizeBtn.layer.borderWidth = 1.0f;
        self.fontSizeBtn.layer.cornerRadius = 3.0f;
        self.fontSizeBtn.layer.borderColor = [[UIColor colorWithRGBHex:0x5c5c5c alpha:0.2] CGColor];
        self.fontSizeBtn.backgroundColor = [UIColor clearColor];
        
        [self.fontSizeBtn addTarget:self action:@selector(showFontSizeLayout) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.fontSizeBtn];
        
        
        self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect backFrame = CGRectMake(20, 10, 26, 26);
        self.backBtn.frame = backFrame;
        [self.backBtn setImage:[UIImage imageNamed:@"common_back_black"] forState:UIControlStateNormal];
        [self.backBtn addTarget:self action:@selector(backPrivLayout) forControlEvents:UIControlEventTouchUpInside];
        
        self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2 - 40, 3, 100, 40)] autorelease];
        self.titleLabel.text = @"";
        self.titleLabel.textColor = [UIColor blackColor];
        self.titleLabel.font = [UIFont systemFontOfSize:15];
        
        self.titleBar = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 40)] autorelease];
        self.titleBar.backgroundColor = [UIColor whiteColor];
        
        self.arrayFontNames =[[[NSMutableArray alloc] initWithObjects:@"Courier",
                              @"Courier-Bold",
                              @"Courier-BoldOblique",
                              @"Courier-Oblique",
                              @"Helvetica",
                              @"Helvetica-Bold",
                              @"Helvetica-BoldOblique",
                              @"Helvetica-Oblique",
                              @"Times-Roman",
                              @"Times-Bold",
                              @"Times-Italic",
                              @"Times-BoldItalic",
                              nil] autorelease];
        self.dictFontSizes = [[[NSMutableDictionary alloc]
                               initWithObjectsAndKeys:[NSNumber numberWithInteger:6], @"6 pt",
                               [NSNumber numberWithInteger:8], @"8 pt",
                               [NSNumber numberWithInteger:10], @"10 pt",
                               [NSNumber numberWithInteger:12], @"12 pt",
                               [NSNumber numberWithInteger:14], @"14 pt",
                               [NSNumber numberWithInteger:18], @"18 pt",
                               [NSNumber numberWithInteger:24], @"24 pt",
                               [NSNumber numberWithInteger:36], @"36 pt",
                               [NSNumber numberWithInteger:48], @"48 pt",
                               [NSNumber numberWithInteger:64], @"64 pt",
                               [NSNumber numberWithInteger:72], @"72 pt",
                               [NSNumber numberWithInteger:96], @"96 pt",
                               [NSNumber numberWithInteger:144], @"144 pt",
                               nil] autorelease];
        self.arrayFontSizes =[[[NSMutableArray alloc] initWithObjects: @"6 pt",
                              @"8 pt",
                              @"10 pt",
                              @"12 pt",
                              @"14 pt",
                              @"18 pt",
                              @"24 pt",
                              @"36 pt",
                              @"48 pt",
                              @"64 pt",
                              @"72 pt",
                              @"96 pt",
                              @"144 pt",
                              nil] autorelease];
        self.tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 100) style:UITableViewStylePlain] autorelease];
        if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.tableView setSeparatorInset:UIEdgeInsetsMake(0,10,0,10)];
        }
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.layoutHeight = LAYOUTTITLEHEIGHT + 60;
        
        
    }
    return self;
}

-(long)supportProperty
{
    return PROPERTY_FONTNAME;
}

-(void)setCurrentFontName:(NSString *)fontName
{
    _currentFontName = fontName;
    [self.fontNameBtn setTitle:fontName forState:UIControlStateNormal];
    if (fontName && ![self.arrayFontNames containsObject:fontName]) {
        [self.arrayFontNames insertObject:fontName atIndex:0];
    }
}

-(void)setCurrentFontSize:(int)fontSize
{
    _currentFontSize = fontSize;
    [self.fontSizeBtn setTitle:[NSString stringWithFormat:@"%d px",fontSize] forState:UIControlStateNormal];
}

-(void)setCurrentListener:(id<IPropertyValueChangedListener>)currentListener
{
    _currentListener = currentListener;
}

-(void)showFontNameLayout
{
    _currentFontType = FontNameType;
    [self addSubview:self.tableView];
    [self addSubview:self.titleBar];
    [self addSubview:self.backBtn];
    [self addSubview:self.titleLabel];
    self.tableView.frame = CGRectMake(0, 40, self.frame.size.width, self.mainLayoutHeight - 40);
    [self.titleLabel setText:NSLocalizedString(@"kFontName", nil)];
    self.frame = CGRectMake(0, 0, self.frame.size.width, self.mainLayoutHeight);
    [self.tableView reloadData];
}

-(void)showFontSizeLayout
{
    _currentFontType = FontSizeType;
    [self addSubview:self.tableView];
    [self addSubview:self.titleBar];
    [self addSubview:self.backBtn];
    [self addSubview:self.titleLabel];
    self.tableView.frame = CGRectMake(0, 40, self.frame.size.width, self.mainLayoutHeight - 40);
    [self.titleLabel setText:NSLocalizedString(@"kFontSize", nil)];
    self.frame = CGRectMake(0, 0, self.frame.size.width, self.mainLayoutHeight);
    [self.tableView reloadData];
}

-(void)backPrivLayout
{
    [self.tableView removeFromSuperview];
    [self.titleBar removeFromSuperview];
    [self.backBtn removeFromSuperview];
    [self.titleLabel removeFromSuperview];
    self.frame = CGRectMake(0, 0, self.frame.size.width, self.layoutHeight);
}

-(void)addDivideView
{
    for (UIView *view in self.subviews) {
        if (view.tag == 1000) {
            [view removeFromSuperview];
        }
    }
    UIView *divide = [[[UIView alloc] initWithFrame:CGRectMake(20, self.frame.size.height - 1, self.frame.size.width - 40, [Utility realPX:1.0f])] autorelease];
    divide.tag = 1000;
    divide.backgroundColor = [UIColor colorWithRGBHex:0x5c5c5c];
    divide.alpha = 0.2f;
    [self addSubview:divide];
    
}

- (void)resetLayout
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    self.title = [[[UILabel alloc] initWithFrame:CGRectMake(20, 3, self.frame.size.width, LAYOUTTITLEHEIGHT)] autorelease];
    self.title.text = NSLocalizedString(@"kFont", nil);
    self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
    self.title.font = [UIFont systemFontOfSize:11.0f];
    [self addSubview:self.title];
    
    self.fontNameBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect fontNameFrame = CGRectMake(ITEMLRSPACE, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, (self.frame.size.width - ITEMLRSPACE*3)*2/3, 30);
    self.fontNameBtn.frame = fontNameFrame;
    [self.fontNameBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.fontNameBtn.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    self.fontNameBtn.backgroundColor = [UIColor whiteColor];
    self.fontNameBtn.contentMode = UIViewContentModeScaleToFill;
    self.fontNameBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.fontNameBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.fontNameBtn.layer.borderWidth = 1.0f;
    self.fontNameBtn.layer.cornerRadius = 3.0f;
    self.fontNameBtn.layer.borderColor = [[UIColor colorWithRGBHex:0x5c5c5c alpha:0.2] CGColor];
    self.fontSizeBtn.backgroundColor = [UIColor clearColor];
    
    [self.fontNameBtn addTarget:self action:@selector(showFontNameLayout) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.fontNameBtn];
    
    self.fontSizeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect fontSizeFrame = CGRectMake(ITEMLRSPACE*2 + self.fontNameBtn.frame.size.width, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, (self.frame.size.width - ITEMLRSPACE*3)/3, 30);
    self.fontSizeBtn.frame = fontSizeFrame;
    [self.fontSizeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.fontSizeBtn.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    self.fontSizeBtn.contentMode = UIViewContentModeScaleToFill;
    self.fontSizeBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.fontSizeBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.fontSizeBtn.layer.borderWidth = 1.0f;
    self.fontSizeBtn.layer.cornerRadius = 3.0f;
    self.fontSizeBtn.layer.borderColor = [[UIColor colorWithRGBHex:0x5c5c5c alpha:0.2] CGColor];
    self.fontSizeBtn.backgroundColor = [UIColor clearColor];
    
    [self.fontSizeBtn addTarget:self action:@selector(showFontSizeLayout) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.fontSizeBtn];
    
    
    self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect backFrame = CGRectMake(20, 10, 26, 26);
    self.backBtn.frame = backFrame;
    [self.backBtn setImage:[UIImage imageNamed:@"common_back_black"] forState:UIControlStateNormal];
    [self.backBtn addTarget:self action:@selector(backPrivLayout) forControlEvents:UIControlEventTouchUpInside];
    
    self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 40, 3, 100, 40)] autorelease];
    self.titleLabel.text = @"";
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.font = [UIFont systemFontOfSize:15];
    
    self.titleBar = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 40)] autorelease];
    self.titleBar.backgroundColor = [UIColor whiteColor];
    
    self.arrayFontNames =[[[NSMutableArray alloc] initWithObjects:@"Courier",
                          @"Courier-Bold",
                          @"Courier-BoldOblique",
                          @"Courier-Oblique",
                          @"Helvetica",
                          @"Helvetica-Bold",
                          @"Helvetica-BoldOblique",
                          @"Helvetica-Oblique",
                          @"Times-Roman",
                          @"Times-Bold",
                          @"Times-Italic",
                          @"Times-BoldItalic",
                          nil] autorelease];
    self.dictFontSizes = [[[NSMutableDictionary alloc]
                          initWithObjectsAndKeys:[NSNumber numberWithInteger:6], @"6 pt",
                          [NSNumber numberWithInteger:8], @"8 pt",
                          [NSNumber numberWithInteger:10], @"10 pt",
                          [NSNumber numberWithInteger:12], @"12 pt",
                          [NSNumber numberWithInteger:14], @"14 pt",
                          [NSNumber numberWithInteger:18], @"18 pt",
                          [NSNumber numberWithInteger:24], @"24 pt",
                          [NSNumber numberWithInteger:36], @"36 pt",
                          [NSNumber numberWithInteger:48], @"48 pt",
                          [NSNumber numberWithInteger:64], @"64 pt",
                          [NSNumber numberWithInteger:72], @"72 pt",
                          [NSNumber numberWithInteger:96], @"96 pt",
                          [NSNumber numberWithInteger:144], @"144 pt",
                          nil] autorelease];
    self.arrayFontSizes =[[[NSMutableArray alloc] initWithObjects: @"6 pt",
                          @"8 pt",
                          @"10 pt",
                          @"12 pt",
                          @"14 pt",
                          @"18 pt",
                          @"24 pt",
                          @"36 pt",
                          @"48 pt",
                          @"64 pt",
                          @"72 pt",
                          @"96 pt",
                          @"144 pt",
                          nil] autorelease];
    self.tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100) style:UITableViewStylePlain] autorelease];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0,10,0,10)];
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.layoutHeight = LAYOUTTITLEHEIGHT + 60;
    [self setCurrentFontName:_currentFontName];
    [self setCurrentFontSize:_currentFontSize];
}

#pragma mark -  table view delegate handler
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_currentFontType == FontNameType) {
        [_currentListener onStringValueChanged:PROPERTY_FONTNAME value:[self.arrayFontNames objectAtIndex:indexPath.row]];
         [self setCurrentFontName:[self.arrayFontNames objectAtIndex:indexPath.row]];
    }
    if (_currentFontType == FontSizeType) {
        if (_currentListener) {
            NSString *stSize = [self.arrayFontSizes objectAtIndex:indexPath.row];
            int value = [[self.dictFontSizes objectForKey:stSize] intValue];
            [_currentListener onFloatValueChanged:PROPERTY_FONTSIZE value:value];
            _currentFontSize = value;
            [self setCurrentFontSize:_currentFontSize];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [tableView reloadData];
}

#pragma mark -  table view datasource handler

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_currentFontType == FontNameType) {
        return self.arrayFontNames.count;
    }
    if (_currentFontType == FontSizeType) {
        return self.arrayFontSizes.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_currentFontType == FontNameType) {
        static NSString *CellIdentifier = @"CellFontName";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            UILabel *labelIconName = [[[UILabel alloc] initWithFrame:CGRectMake(ITEMLRSPACE, 0, cell.frame.size.width, cell.frame.size.height)] autorelease];
            labelIconName.textAlignment = NSTextAlignmentLeft;
            labelIconName.font = [UIFont systemFontOfSize:15];
            [cell.contentView addSubview:labelIconName];
        }
        UILabel *labelIconName = [cell.contentView.subviews objectAtIndex:0];
        labelIconName.text = [_arrayFontNames objectAtIndex:indexPath.row];
        if ([_arrayFontNames indexOfObject:_currentFontName] == indexPath.row)
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            labelIconName.textColor = [UIColor colorWithRGBHex:0x179cd8];
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            labelIconName.textColor = [UIColor blackColor];
        }
        return cell;
    }
    else if (_currentFontType == FontSizeType)
    {
        static NSString *CellIdentifier = @"CellFontSize";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            UILabel *labelIconName = [[[UILabel alloc] initWithFrame:CGRectMake(ITEMLRSPACE, 0, cell.frame.size.width, cell.frame.size.height)] autorelease];
            labelIconName.textAlignment = NSTextAlignmentLeft;
            labelIconName.font = [UIFont systemFontOfSize:15];
            [cell.contentView addSubview:labelIconName];
        }
        UILabel *labelIconName = [cell.contentView.subviews objectAtIndex:0];
        labelIconName.text = [_arrayFontSizes objectAtIndex:indexPath.row];
        __block NSString *sizeKey = nil;
        [_dictFontSizes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj intValue] == _currentFontSize) {
                sizeKey = key;
                *stop = YES;
            }
        }];
        if (sizeKey && [_arrayFontSizes indexOfObject:sizeKey] == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            labelIconName.textColor = [UIColor colorWithRGBHex:0x179cd8];
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            labelIconName.textColor = [UIColor blackColor];
        }
        return cell;
    }
    return nil;
}

- (void)scrollToCurrentIcon
{
    NSIndexPath *indexPath = nil;
    if (_currentFontType == FontNameType) {
        indexPath = [NSIndexPath indexPathForRow:[_arrayFontNames indexOfObject:_currentFontName] inSection:0];
    }
    else if (_currentFontType == FontSizeType)
    {
        __block NSString *sizeKey = nil;
        [_dictFontSizes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj intValue] == _currentFontSize) {
                sizeKey = key;
                *stop = YES;
            }
        }];
        if (sizeKey) {
            indexPath = [NSIndexPath indexPathForRow:[_arrayFontSizes indexOfObject:sizeKey] inSection:0];
        }
        else
        {
            indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        }
    }
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

@end
