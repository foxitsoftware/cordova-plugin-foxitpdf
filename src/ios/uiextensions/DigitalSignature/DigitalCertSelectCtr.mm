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

#import "DigitalCertSelectCtr.h"
#import "Const.h"
#import "TSAlertView.h"
#import "Masonry.h"
#import "DigitalCertInfoCtr.h"
#import "SignatureOperator.h"
#import "DigitalSignatureCom.h"
#import "NSString+GetFileMD5.h"
#import "Defines.h"
#import "AlertView.h"
#import <openssl/evp.h>
#import "ColorUtility.h"

@interface DigitalCertCell : UITableViewCell
@property (nonatomic, strong) UIImageView *selectIcon;
@property (nonatomic, strong) UILabel *nameLabel;
@end

@implementation DigitalCertCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disSelectTrack"]];
        self.nameLabel = [[UILabel alloc] init];
        [self addSubview:self.selectIcon];
        [self addSubview:self.nameLabel];
        self.accessoryType = UITableViewCellAccessoryDetailButton;
        
        [self.selectIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.mas_left).offset(10);
            make.centerY.mas_equalTo(self.mas_centerY);
            make.width.mas_equalTo(26);
            make.height.mas_equalTo(26);
        }];
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.selectIcon.mas_right).offset(20);
            make.centerY.mas_equalTo(self.mas_centerY);
            make.right.mas_equalTo(self.mas_right).offset(-50);
            make.height.mas_equalTo(30);
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

@interface DigitalCertSelectCtr ()<UITableViewDelegate,UITableViewDataSource,TSAlertViewDelegate>
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, assign) NSInteger currentSelectIndexPathRow;
@property (nonatomic, assign) NSInteger showPromptTimes;
@property (nonatomic, strong) TSAlertView *currentAlertView;
@property (nonatomic, strong)   NSMutableDictionary *currentCertPasswordDic;
@property (nonatomic, copy)   void(^finishInputPassword)(NSString *);
@end

@implementation DigitalCertSelectCtr

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dataArray = [NSMutableArray array];
    self.currentCertPasswordDic = [[NSMutableDictionary alloc] init];
    self.currentSelectIndexPathRow = -1;
    [self loadCertInfo];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"kCancel", @"FoxitLocalizable", nil) style:UIBarButtonItemStylePlain target:self action:@selector(didCancel)];
    self.navigationItem.leftBarButtonItem = leftButton;
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"kOK", @"FoxitLocalizable", nil) style:UIBarButtonItemStylePlain target:self action:@selector(didOk)];
    self.navigationItem.rightBarButtonItem = rightButton;
    rightButton.enabled = NO;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRGBHex:0x179cd8];
    if (OS_ISVERSION9)
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    if (self.dataArray.count < 1) {
        UILabel *nonCertLabel = [[UILabel alloc] init];
        nonCertLabel.text = NSLocalizedStringFromTable(@"kNoCert", @"FoxitLocalizable", nil);
        nonCertLabel.font = [UIFont systemFontOfSize:20];
        [self.view addSubview:nonCertLabel];
        [nonCertLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(nonCertLabel.superview.mas_centerX);
            make.centerY.mas_equalTo(nonCertLabel.superview.mas_centerY);
        }];
    }
}

- (void)loadCertInfo
{
    NSString *path = DOCUMENT_PATH;
    NSFileManager *myFileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *myDirectoryEnumerator;
    
    myDirectoryEnumerator = [myFileManager enumeratorAtPath:path];
    
    while((path = [myDirectoryEnumerator nextObject]) != nil)
    {
        if ([[[path pathExtension] lowercaseString] isEqualToString:@"p12"] || [[[path pathExtension] lowercaseString] isEqualToString:@"pfx"]) {
            [self.dataArray addObject:path.copy];
        }
        
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *certCellIndentifier = @"certCellIndentifier";
    DigitalCertCell *cell = [[DigitalCertCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:certCellIndentifier];
    cell.nameLabel.text = [(NSString *)[self.dataArray objectAtIndex:indexPath.row] lastPathComponent];
    cell.nameLabel.font = [UIFont systemFontOfSize:16];
    if (self.currentSelectIndexPathRow == indexPath.row) {
        cell.selectIcon.image = [UIImage imageNamed:@"selectTrack"];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else
    {
        cell.selectIcon.image = [UIImage imageNamed:@"disSelectTrack"];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CERT_INFO *info = [[CERT_INFO alloc] init];
    NSString *path = [DOCUMENT_PATH stringByAppendingPathComponent:self.dataArray[indexPath.row]];
    NSString *md5 = [NSString getFileMD5WithPath:path];
    if ([self.currentCertPasswordDic objectForKey:md5]) {
        self.currentSelectIndexPathRow = indexPath.row;
        [self.tableView reloadData];
    }else
    {
        [self promptForPassword:^(NSString *password){
            if (password == nil) {
                self.showPromptTimes = 0;
                return;
            }
            
            int result = getCertInfo(path, password, info);
            if (result == P12FILESCANFERROR) {
                return;
            }else if (result == P12FILEPASSWDERROR)
            {
                [self tableView:tableView didSelectRowAtIndexPath:indexPath];
                return;
            }
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *endDate = [dateFormatter dateFromString:info.certEndDate];
            
            self.showPromptTimes = 0;
            if (endDate.timeIntervalSince1970 - [NSDate date].timeIntervalSince1970 < 0) {
                AlertView *alert = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kCertExpired" buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                    
                } cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
                [alert show];
            }else{
                [self.currentCertPasswordDic setObject:password forKey:md5];
                self.currentSelectIndexPathRow = indexPath.row;
            }
            [self.tableView reloadData];
        }];

    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(nonnull NSIndexPath *)indexPath
{
    CERT_INFO *info = [[CERT_INFO alloc] init];
    NSString *path = [DOCUMENT_PATH stringByAppendingPathComponent:self.dataArray[indexPath.row]];
    NSString *md5 = [NSString getFileMD5WithPath:path];
    if ([self.currentCertPasswordDic objectForKey:md5]) {
        int result = getCertInfo(path, [self.currentCertPasswordDic objectForKey:md5], info);
        if (result == P12FILESCANFERROR) {
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kCertFileError" buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                if (buttonIndex == 0) {
                    
                }
            } cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
            [alertView show];
            return;
        }else if (result == P12FILEPASSWDERROR)
        {
            [self.currentCertPasswordDic removeObjectForKey:md5];
            [self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
            return;
        }
        DigitalCertInfoCtr *certInfoCtr = [[DigitalCertInfoCtr alloc] init];
        [certInfoCtr setDigitalCertInfoData:info];
        certInfoCtr.title = NSLocalizedStringFromTable(@"kCertInfo", @"FoxitLocalizable", nil);
        [self.navigationController pushViewController:certInfoCtr animated:YES];
    }else
    {
        [self promptForPassword:^(NSString *password){
            if (password == nil) {
                self.showPromptTimes = 0;
                return;
            }
            
            int result = getCertInfo(path, password, info);
            if (result == P12FILESCANFERROR) {
                AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kCertFileError" buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                    if (buttonIndex == 0) {
                        
                    }
                } cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
                [alertView show];
                return;
            }else if (result == P12FILEPASSWDERROR)
            {
                [self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
                return;
            }
            
            self.showPromptTimes = 0;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *endDate = [dateFormatter dateFromString:info.certEndDate];
            
            if (endDate.timeIntervalSince1970 - [NSDate date].timeIntervalSince1970 < 0) {
                AlertView *alert = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kCertExpired" buttonClickHandler:^(UIView *alertView, int buttonIndex) {
                    
                } cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
                [alert show];
            }else{
                [self.currentCertPasswordDic setObject:password forKey:md5];
                self.currentSelectIndexPathRow = indexPath.row;
            }
            
            DigitalCertInfoCtr *certInfoCtr = [[DigitalCertInfoCtr alloc] init];
            [certInfoCtr setDigitalCertInfoData:info];
            certInfoCtr.title = NSLocalizedStringFromTable(@"kCertInfo", @"FoxitLocalizable", nil);
            [self.navigationController pushViewController:certInfoCtr animated:YES];
        }];

    }
}

- (void)didOk
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.currentSelectIndexPathRow != -1 && self.currentSelectIndexPathRow < self.dataArray.count) {
            NSString *path = [DOCUMENT_PATH stringByAppendingPathComponent:self.dataArray[self.currentSelectIndexPathRow]];
            NSString *md5 = [NSString getFileMD5WithPath:path];
            if ([self.currentCertPasswordDic objectForKey:md5]) {
                self.doneOperator(path,[self.currentCertPasswordDic objectForKey:md5],md5);
            }
        }
        
    }];
}

- (void)didCancel
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        self.cancelOperator(nil,nil,nil);
    }];
}

- (void)promptForPassword:(void(^)(NSString *))complete
{
    self.finishInputPassword = complete;
    TSAlertView* alertView = [[TSAlertView alloc] init];
    if (self.showPromptTimes == 0) {
        alertView.title = NSLocalizedStringFromTable(@"kOfflineCopyAlterTitle", @"FoxitLocalizable", nil);
    }else
    {
        alertView.title = NSLocalizedStringFromTable(@"kPassWordErrorAlterTitle", @"FoxitLocalizable", nil);
    }
    self.currentAlertView = alertView;
    [alertView addButtonWithTitle:NSLocalizedStringFromTable(@"kCancel", @"FoxitLocalizable", nil)];
    [alertView addButtonWithTitle:NSLocalizedStringFromTable(@"kOK", @"FoxitLocalizable", nil)];
    alertView.style = TSAlertViewStyleInputText;
    alertView.buttonLayout = TSAlertViewButtonLayoutNormal;
    alertView.usesMessageTextView = NO;
    alertView.inputTextField.secureTextEntry = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputTextFieldChange:) name:UITextFieldTextDidChangeNotification object:alertView.inputTextField];
    alertView.delegate = self;
    UIButton *sureBtn = alertView.buttons.lastObject;
    sureBtn.enabled = NO;
    [sureBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [alertView show];
    self.showPromptTimes++;
}

- (void)inputTextFieldChange:(NSNotification *)aNotification
{
    if ([self.currentAlertView.inputTextField isEqual:aNotification.object]) {
        UIButton *sureBtn = self.currentAlertView.buttons.lastObject;
        if (((UITextField *)aNotification.object).text.length != 0) {
            sureBtn.enabled = YES;
            [sureBtn setTitleColor:[UIColor colorWithRed:0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1] forState:UIControlStateNormal];
        }else
        {
            sureBtn.enabled = NO;
            [sureBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - TSAlertViewDelegate

- (void)alertView:(TSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    TSAlertView *tsAlertView = (TSAlertView *)alertView;
    double delayInSeconds = .1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    if (buttonIndex == 1) {
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            NSString *password = tsAlertView.inputTextField.text;
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            self.currentAlertView = nil;
            self.finishInputPassword(password);
        });
    } else {
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            self.currentAlertView = nil;
            self.finishInputPassword(nil);
        });
    }
}

@end
