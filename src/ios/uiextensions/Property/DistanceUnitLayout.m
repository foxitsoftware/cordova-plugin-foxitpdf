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

#import "DistanceUnitLayout.h"
#import "ColorUtility.h"
#import "PropertyBar.h"
#import "Utility.h"
#import "AlertView.h"

#define Knum @"^[0-9]*$"

@interface DistanceUnitLayout ()

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) NSString *currentDistanceUnitName;
@property (nonatomic, strong) NSString *currentDistanceCustomUnitName;
@property (nonatomic, strong) id<IPropertyValueChangedListener> currentListener;

@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *titleBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *distanceUnitBtn;
@property (nonatomic, strong) UITextField *unitTextField;
@property (nonatomic, strong) UITextField *customTextField;
@property (nonatomic, strong) UIButton *customUnitBtn;

@property (nonatomic, strong) NSMutableArray *arrayDistanceUnit;

@property (nonatomic, assign) BOOL isFirstUnitButtonClicked;
@property (nonatomic, strong) NSString *oldUnitValue;

@end

@implementation DistanceUnitLayout

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        [self buildUI];
        self.isFirstUnitButtonClicked = YES;
    }
    return self;
}
-(void)buildUI {
    // first screen
    self.title = [[UILabel alloc] initWithFrame:CGRectMake(20, 3, self.frame.size.width, LAYOUTTITLEHEIGHT)];
    self.title.text = FSLocalizedString(@"kUnit");
    self.title.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
    self.title.font = [UIFont systemFontOfSize:11.0f];
    [self addSubview:self.title];
    
    float itemWidth = (self.frame.size.width - ITEMLRSPACE *2 - 10 *5)/4 ;
    
    self.unitTextField = [[UITextField alloc]initWithFrame:CGRectMake(ITEMLRSPACE, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, 30)];
    self.unitTextField.text = @"1";
    self.unitTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.unitTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self addSubview:self.unitTextField];
    self.unitTextField.delegate = self;
    self.unitTextField.tag = 1000001;
    
    self.distanceUnitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    float distanceUnitX = self.unitTextField.frame.origin.x + self.unitTextField.frame.size.width + 10;
    self.distanceUnitBtn.frame = CGRectMake(distanceUnitX , LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, 30);
    [self.distanceUnitBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.distanceUnitBtn.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    self.distanceUnitBtn.backgroundColor = [UIColor whiteColor];
    self.distanceUnitBtn.contentMode = UIViewContentModeScaleToFill;
    self.distanceUnitBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.distanceUnitBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.distanceUnitBtn.layer.borderWidth = 1.0f;
    self.distanceUnitBtn.layer.cornerRadius = 3.0f;
    self.distanceUnitBtn.layer.borderColor = [[UIColor colorWithRGBHex:0x5c5c5c alpha:0.2] CGColor];
    [self addSubview:self.distanceUnitBtn];
    [self.distanceUnitBtn addTarget:self action:@selector(showUnitLayout) forControlEvents:UIControlEventTouchUpInside];
    
    float tempx = self.distanceUnitBtn.frame.origin.x + self.distanceUnitBtn.frame.size.width +10;
    UILabel *equalLabel = [[UILabel alloc] initWithFrame:CGRectMake(tempx, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, 10, 30)];
    equalLabel.text = @"=";
    [self addSubview:equalLabel];
    
    float customTextFieldX = equalLabel.frame.origin.x + equalLabel.frame.size.width + 10 ;
    self.customTextField = [[UITextField alloc]initWithFrame:CGRectMake(customTextFieldX, LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, 30)];
    self.customTextField.text = @"1";
    self.customTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.customTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self addSubview:self.customTextField];
    self.customTextField.delegate = self;
    self.customTextField.tag = 1000002;
    
    float customUnitBtnX = self.customTextField.frame.origin.x + self.customTextField.frame.size.width + 10;
    self.customUnitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.customUnitBtn.frame = CGRectMake(customUnitBtnX , LAYOUTTITLEHEIGHT + LAYOUTTBSPACE, itemWidth, 30);
    [self.customUnitBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.customUnitBtn.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    self.customUnitBtn.backgroundColor = [UIColor whiteColor];
    self.customUnitBtn.contentMode = UIViewContentModeScaleToFill;
    self.customUnitBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.customUnitBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.customUnitBtn.layer.borderWidth = 1.0f;
    self.customUnitBtn.layer.cornerRadius = 3.0f;
    self.customUnitBtn.layer.borderColor = [[UIColor colorWithRGBHex:0x5c5c5c alpha:0.2] CGColor];
    [self addSubview:self.customUnitBtn];
    [self.customUnitBtn addTarget:self action:@selector(showCustomUnitLayout) forControlEvents:UIControlEventTouchUpInside];
    
    self.unitTextField.userInteractionEnabled = YES;
    self.customTextField.userInteractionEnabled = YES;
    self.distanceUnitBtn.userInteractionEnabled = YES;
    self.customUnitBtn.userInteractionEnabled = YES;
    
    // secrond screen
    self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect backFrame = CGRectMake(20, 10, 26, 26);
    self.backBtn.frame = backFrame;
    [self.backBtn setImage:[UIImage imageNamed:@"common_back_black"] forState:UIControlStateNormal];
    [self.backBtn addTarget:self action:@selector(backPrivLayout) forControlEvents:UIControlEventTouchUpInside];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 40, 3, 100, 40)];
    self.titleLabel.text = @"";
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.font = [UIFont systemFontOfSize:15];
    
    self.titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 40)];
    self.titleBar.backgroundColor = [UIColor whiteColor];
    
    self.arrayDistanceUnit = [[NSMutableArray alloc] initWithObjects:
                              @"pt",
                              @"inch",
                              @"ft",
                              @"yd",
                              @"p",
                              @"mm",
                              @"cm",
                              @"m",
                           nil];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100) style:UITableViewStylePlain];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 10)];
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.layoutHeight = LAYOUTTITLEHEIGHT + 60;
    
    [self.unitTextField addTarget:self action:@selector(textChange:) forControlEvents:UIControlEventEditingChanged];
    [self.customTextField addTarget:self action:@selector(textChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self.unitTextField addTarget:self action:@selector(textEditingEnd:) forControlEvents:UIControlEventEditingDidEnd];
    [self.customTextField addTarget:self action:@selector(textEditingEnd:) forControlEvents:UIControlEventEditingDidEnd];
}

- (void)forbidUnit {
    self.unitTextField.userInteractionEnabled = NO;
    self.customTextField.userInteractionEnabled = NO;
    self.distanceUnitBtn.userInteractionEnabled = NO;
    self.customUnitBtn.userInteractionEnabled = NO;
}

- (long)supportProperty {
    return PROPERTY_DISTANCE_UNIT;
}

- (void)setCurrentUnitName:(NSString *)UnitName {
    _oldUnitValue = UnitName;
    NSArray *array = [Utility getDistanceUnitInfo:UnitName];
    
    NSString *string0 = [array objectAtIndex:0];
    NSString *string1 = [array objectAtIndex:1];
    NSString *string2 = [array objectAtIndex:2];
    NSString *string3 = [array objectAtIndex:3];
    
    self.unitTextField.text = string0;
    self.customTextField.text = string2;
    
    _currentDistanceUnitName = string1;
    _currentDistanceCustomUnitName = string3;
    
    [self.distanceUnitBtn setTitle:_currentDistanceUnitName forState:UIControlStateNormal];
    [self.customUnitBtn setTitle:_currentDistanceCustomUnitName forState:UIControlStateNormal];
}

- (void)setCurrentListener:(id<IPropertyValueChangedListener>)currentListener {
    _currentListener = currentListener;
}

-(void) showUnitLayout {
    _isFirstUnitButtonClicked = YES;
    [self showTableLayout];
}
;
-(void) showCustomUnitLayout {
    _isFirstUnitButtonClicked = NO;
    [self showTableLayout];
}

- (void)showTableLayout {
    [self addSubview:self.tableView];
    [self addSubview:self.titleBar];
    [self addSubview:self.backBtn];
    [self addSubview:self.titleLabel];
    self.tableView.frame = CGRectMake(0, 40, self.frame.size.width, self.mainLayoutHeight - 40);
    [self.titleLabel setText:FSLocalizedString(@"kUnit")];
    self.frame = CGRectMake(0, 0, self.frame.size.width, self.mainLayoutHeight);
    [self.tableView reloadData];
    
    [self.unitTextField resignFirstResponder];
    [self.customTextField resignFirstResponder];
}

- (void)backPrivLayout {
    [self.tableView removeFromSuperview];
    [self.titleBar removeFromSuperview];
    [self.backBtn removeFromSuperview];
    [self.titleLabel removeFromSuperview];
    self.frame = CGRectMake(0, 0, self.frame.size.width, self.layoutHeight);
}

- (void)addDivideView {
    for (UIView *view in self.subviews) {
        if (view.tag == 1000) {
            [view removeFromSuperview];
        }
    }
    UIView *divide = [[UIView alloc] initWithFrame:CGRectMake(20, self.frame.size.height - 1, self.frame.size.width - 40, [Utility realPX:1.0f])];
    divide.tag = 1000;
    divide.backgroundColor = [UIColor colorWithRGBHex:0x5c5c5c];
    divide.alpha = 0.2f;
    [self addSubview:divide];
}

- (void)resetLayout {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }

    [self buildUI];
    
    [self setCurrentUnitName:_currentDistanceUnitName];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self writeDataToDistance];
    
    [self endEditing:YES];
}

-(void)textEditingEnd:(UITextField *)textField {
    if (textField.text.length == 0) {
        [textField resignFirstResponder];
        textField.text = @"0";
        
        [self writeDataToDistance];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kDistanceLengthError" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
            [alertView show];
        });
        
        return;
    }
}

-(void)textChange:(UITextField *)textField {
    if (textField.text.length > 6) {
        textField.text = [textField.text substringToIndex:6];
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kDistanceLengthError" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
        [alertView show];
        return;
    }
    
    NSString* number = Knum;
    NSPredicate *numberPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",number];
    if(![numberPre evaluateWithObject:textField.text]){
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kDistanceNumberError" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
        [alertView show];
        return;
    }
    
    [self writeDataToDistance];
}

-(void)writeDataToDistance {
    NSString *newUnitValue = [NSString stringWithFormat:@"%@ %@ = %@ %@",self.unitTextField.text,_currentDistanceUnitName,self.customTextField.text,_currentDistanceCustomUnitName];
    [_currentListener onProperty:PROPERTY_DISTANCE_UNIT changedFrom:[NSValue valueWithNonretainedObject:_oldUnitValue] to:[NSValue valueWithNonretainedObject:newUnitValue]];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if(textField.tag == 1000001){
        [self.customTextField resignFirstResponder];
    }else{
        [self.unitTextField resignFirstResponder];
    }
}

#pragma mark -  table view delegate handler
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *newUnitName = [self.arrayDistanceUnit objectAtIndex:indexPath.row];
    if (_isFirstUnitButtonClicked) {
        _currentDistanceUnitName = newUnitName;
    }else{
        _currentDistanceCustomUnitName = newUnitName;
    }
    
    NSString *newUnitValue = [NSString stringWithFormat:@"%@ %@ = %@ %@",self.unitTextField.text,_currentDistanceUnitName,self.customTextField.text,_currentDistanceCustomUnitName];
    [self setCurrentUnitName:newUnitValue];
    
    [_currentListener onProperty:PROPERTY_DISTANCE_UNIT changedFrom:[NSValue valueWithNonretainedObject:_oldUnitValue] to:[NSValue valueWithNonretainedObject:newUnitValue]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

#pragma mark -  table view datasource handler

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrayDistanceUnit.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellUnitName";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UILabel *labelIconName = [[UILabel alloc] initWithFrame:CGRectMake(ITEMLRSPACE, 0, cell.frame.size.width, cell.frame.size.height)];
        labelIconName.textAlignment = NSTextAlignmentLeft;
        labelIconName.font = [UIFont systemFontOfSize:15];
        [cell.contentView addSubview:labelIconName];
    }
    UILabel *labelIconName = [cell.contentView.subviews objectAtIndex:0];
    labelIconName.text = [self.arrayDistanceUnit objectAtIndex:indexPath.row];
    
    if (_isFirstUnitButtonClicked) {
        if ([self.arrayDistanceUnit indexOfObject:_currentDistanceUnitName] == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            labelIconName.textColor = [UIColor colorWithRGBHex:0x179cd8];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            labelIconName.textColor = [UIColor blackColor];
        }
    } else {
        if ([self.arrayDistanceUnit indexOfObject:_currentDistanceCustomUnitName] == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            labelIconName.textColor = [UIColor colorWithRGBHex:0x179cd8];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            labelIconName.textColor = [UIColor blackColor];
        }
    }
    
    return cell;
}

@end
