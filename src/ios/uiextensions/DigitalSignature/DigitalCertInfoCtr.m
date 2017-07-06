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

#import "DigitalCertInfoCtr.h"
#import "Masonry.h"
#import "ColorUtility.h"

@interface DigitalCertInfoCell : UITableViewCell
@property (nonatomic, strong) UILabel *certInfoKey;
@property (nonatomic, strong) UILabel *certInfoValue;
@end

@implementation DigitalCertInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.certInfoKey = [[UILabel alloc] init];
        self.certInfoKey.textAlignment = NSTextAlignmentLeft;
        self.certInfoKey.font = [UIFont systemFontOfSize:14];
        self.certInfoValue = [[UILabel alloc] init];
        self.certInfoValue.textAlignment = NSTextAlignmentLeft;
        self.certInfoValue.font = [UIFont systemFontOfSize:14];
        self.certInfoValue.numberOfLines = 0;
        [self addSubview:self.certInfoKey];
        [self addSubview:self.certInfoValue];
        
        [self.certInfoKey mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.mas_left).offset(10);
            make.centerY.mas_equalTo(self.mas_centerY);
        }];
        
        [self.certInfoValue mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.mas_right).offset(-10);
            make.centerY.mas_equalTo(self.mas_centerY);
            make.left.mas_equalTo(self.certInfoKey.mas_right).offset(10);
        }];
        
        UIView *divideView = [[UIView alloc] init];
        divideView.backgroundColor = [UIColor colorWithRed:0xE2/255.0f green:0xE2/255.0f blue:0xE2/255.0f alpha:1];
        [self addSubview:divideView];
        [divideView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(divideView.superview.mas_left).offset(10);
            make.height.mas_equalTo(1);
            make.bottom.mas_equalTo(divideView.superview.mas_bottom);
            make.right.mas_equalTo(divideView.superview.mas_right).offset(-2);
        }];
    };
    return self;
}

@end

@interface DigitalCertInfoCtr ()
@property (nonatomic, copy) NSString *certSerialNum;
@property (nonatomic, copy) NSString *certPublisher;
@property (nonatomic, copy) NSString *certStartDate;
@property (nonatomic, copy) NSString *certEndDate;
@property (nonatomic, copy) NSString *certEmailInfo;
@property (nonatomic, assign) CGFloat maxKeyWidth;
@end

@implementation DigitalCertInfoCtr
- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"common_back_black"] style:UIBarButtonItemStyleBordered target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItem = leftButton;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.maxKeyWidth = [self caculateMaxKeyWidth];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (CGFloat)caculateMaxKeyWidth
{
    float maxWidth = 0;
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize size = [NSLocalizedStringFromTable(@"kCertSerialNum", @"FoxitLocalizable", nil) boundingRectWithSize:CGSizeMake(300, 64) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14], NSParagraphStyleAttributeName:paragraphStyle} context:nil].size;
    if (maxWidth < size.width + 1) {
        maxWidth = size.width + 1;
    }
    size = [NSLocalizedStringFromTable(@"kCertIssuer", @"FoxitLocalizable", nil) boundingRectWithSize:CGSizeMake(300, 64) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14], NSParagraphStyleAttributeName:paragraphStyle} context:nil].size;
    if (maxWidth < size.width + 1) {
        maxWidth = size.width + 1;
    }
    size = [NSLocalizedStringFromTable(@"kCertStartTime", @"FoxitLocalizable", nil) boundingRectWithSize:CGSizeMake(300, 64) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14], NSParagraphStyleAttributeName:paragraphStyle} context:nil].size;
    if (maxWidth < size.width + 1) {
        maxWidth = size.width + 1;
    }
    size = [NSLocalizedStringFromTable(@"kCertEndTime", @"FoxitLocalizable", nil) boundingRectWithSize:CGSizeMake(300, 64) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14], NSParagraphStyleAttributeName:paragraphStyle} context:nil].size;
    if (maxWidth < size.width + 1) {
        maxWidth = size.width + 1;
    }
    size = [NSLocalizedStringFromTable(@"kCertEmail", @"FoxitLocalizable", nil) boundingRectWithSize:CGSizeMake(300, 64) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14], NSParagraphStyleAttributeName:paragraphStyle} context:nil].size;
    if (maxWidth < size.width + 1) {
        maxWidth = size.width + 1;
    }
    return maxWidth;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *certInfoCellIndentifier = @"certInfoCellIndentifier";
    DigitalCertInfoCell *cell = [[DigitalCertInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:certInfoCellIndentifier];
    [cell.certInfoKey mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.maxKeyWidth);
    }];
    if (indexPath.row == 0) {
        cell.certInfoKey.text = NSLocalizedStringFromTable(@"kCertSerialNum", @"FoxitLocalizable", nil);
        cell.certInfoValue.text = self.certSerialNum;
    }else if (indexPath.row == 1){
        cell.certInfoKey.text = NSLocalizedStringFromTable(@"kCertIssuer", @"FoxitLocalizable", nil);
        cell.certInfoValue.text = self.certPublisher;
    }else if (indexPath.row == 2){
        cell.certInfoKey.text = NSLocalizedStringFromTable(@"kCertStartTime", @"FoxitLocalizable", nil);
        cell.certInfoValue.text = self.certStartDate;
    }else if (indexPath.row == 3){
        cell.certInfoKey.text = NSLocalizedStringFromTable(@"kCertEndTime", @"FoxitLocalizable", nil);
        cell.certInfoValue.text = self.certEndDate;
    }else if (indexPath.row == 4){
        cell.certInfoKey.text = NSLocalizedStringFromTable(@"kCertEmail", @"FoxitLocalizable", nil);
        cell.certInfoValue.text = self.certEmailInfo;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor colorWithRGBHex:0xEFEFF4];
    UILabel *sectionTitle = [[UILabel alloc] init];
    sectionTitle.text = NSLocalizedStringFromTable(@"kCertInfo", @"FoxitLocalizable", nil);
    sectionTitle.font = [UIFont boldSystemFontOfSize:16];
    sectionTitle.textColor = [UIColor blackColor];
    [headerView addSubview:sectionTitle];
    [sectionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(10);
        make.centerY.mas_equalTo(sectionTitle.superview.mas_centerY);
    }];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64.0;
}

- (void)setDigitalCertInfoData:(CERT_INFO *)cert_info
{
    self.certSerialNum = cert_info.certSerialNum;
    self.certPublisher = cert_info.certPublisher;
    self.certStartDate = cert_info.certStartDate;
    self.certEndDate = cert_info.certEndDate;
    self.certEmailInfo = cert_info.certEmailInfo;
}

- (void)dismissVC
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
