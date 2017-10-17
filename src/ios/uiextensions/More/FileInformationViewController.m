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

#import "FileInformationViewController.h"
#import "../Common/UINavigationItem+IOS7PaddingAdditions.h"
#import "../Thirdparties/ColorUtility/ColorUtility.h"
#import "PermissionViewController.h"
#import "Utility.h"

#define LABLEHIGHT 20
#define LABLEWIDTH 100
#define LABLEVALUEWIDTH 300
#define LEFTMARGEN 20
#define TOPMARGEN 20

@interface FileInformationViewController ()

@property (nonatomic, weak) FSPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, weak) UIExtensionsManager *extensionsManager;
@end

@implementation FileInformationViewController

- (void)setUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    _extensionsManager = extensionsManager;
    _pdfViewCtrl = extensionsManager.pdfViewCtrl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    CGRect tableRect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.tableView = [[UITableView alloc] initWithFrame:tableRect style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    if (OS_ISVERSION7) {
        self.tableView.separatorInset = UIEdgeInsetsZero;
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

    [self initNavigationBar];
}

- (void)viewDidUnload {
    [self.tableView removeFromSuperview];
    [super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    navigationController.navigationBar.tag = 1;
    navigationController.navigationBar.barTintColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    if (self.navigationItem.titleView != nil) {
        UIView *titleView = (UIView *) self.navigationItem.titleView;
        UILabel *titleLabel = (UILabel *) [titleView viewWithTag:2];
        if (titleLabel) {
            titleLabel.text = FSLocalizedString(@"kDocinfo");
        }
    }
}

- (void)okAction:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:^{

                             }];
}

#pragma mark - Private methods
- (void)initNavigationBar {
    CGRect frameButton = CGRectMake(0.0f, 0.0f, 55, self.navigationController.navigationBar.frame.size.height - 14);
    UIButton *buttonInnerOperationButton = [[UIButton alloc] initWithFrame:frameButton];
    self.buttonOK = buttonInnerOperationButton;
    [buttonInnerOperationButton setImage:[UIImage imageNamed:@"property_backselected"] forState:UIControlStateNormal];
    [buttonInnerOperationButton setImageEdgeInsets:UIEdgeInsetsMake(0, -15, 0, 15)];
    buttonInnerOperationButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                                  UIViewAutoresizingFlexibleBottomMargin |
                                                  UIViewAutoresizingFlexibleHeight;
    [buttonInnerOperationButton addTarget:self action:@selector(okAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *buttonOperatingItem = [[UIBarButtonItem alloc] initWithCustomView:buttonInnerOperationButton];
    [self.navigationItem addLeftBarButtonItem:buttonOperatingItem];

    if (!self.navigationItem.titleView) {
        CGRect titleViewFrame = CGRectMake(0.0, 0.0, 200.0, 44.0f);
        CGRect indicatorFrame = CGRectMake(180.f, 12.0f, 20.0f, 20.0f);
        CGRect titleFrame = CGRectMake(0.0f, 0.0f, 180.0f, 44.0f);

        UIFont *titleFont = [UIFont boldSystemFontOfSize:18.0f];
        if (DEVICE_iPHONE) {
            indicatorFrame = CGRectMake(160.f, 12.0f, 20.0f, 20.0f);
            titleFrame = CGRectMake(22.0f, 0.0f, 160.0f, 44.0f);
            titleFont = [UIFont boldSystemFontOfSize:18.0f];
        }
        UIView *titleView = [[UIView alloc] initWithFrame:titleViewFrame];
        UIActivityIndicatorView *actIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:indicatorFrame];
        actIndicatorView.tag = 1;
        [actIndicatorView setHidden:YES];
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.frame = titleFrame;
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        titleLabel.text = self.title;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.autoresizesSubviews = YES;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor colorWithRGBHex:0x3F3F3F];
        titleLabel.font = titleFont;
        titleLabel.tag = 2;
        [titleView addSubview:titleLabel];
        [titleView addSubview:actIndicatorView];
        titleView.center = CGPointMake(self.view.frame.size.width / 2, titleView.center.y);
        self.navigationItem.titleView = titleView;
    }

    if (self.navigationItem.titleView != nil) {
        UIView *titleView = (UIView *) self.navigationItem.titleView;
        UILabel *titleLabel = (UILabel *) [titleView viewWithTag:2];
        if (titleLabel) {
            titleLabel.text = FSLocalizedString(@"kDocinfo");
        }
    }
}

- (void)setNavigationProgressState:(BOOL)isProgressing {
    if (self.navigationItem.titleView != nil) {
        UIView *titleView = (UIView *) self.navigationItem.titleView;
        UIActivityIndicatorView *actIndicatorView = (UIActivityIndicatorView *) [titleView viewWithTag:1];
        if (actIndicatorView) {
            [actIndicatorView setHidden:!isProgressing];
            if (isProgressing) {
                [actIndicatorView startAnimating];
            } else {
                [actIndicatorView stopAnimating];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 7;
    }
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, TOPMARGEN, LABLEWIDTH + 300, LABLEHIGHT)];
    label.font = [UIFont systemFontOfSize:15.0f];

    if (section == 0) {
        label.text = FSLocalizedString(@"kFileInformation");
    } else if (section == 1) {
        label.text = FSLocalizedString(@"kSecurity");
    }
    [view addSubview:label];
    return view;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

static NSString *getRelativePathFromAbsolutePath(NSString *absolutePath) {
    NSString *docPath = DOCUMENT_PATH;
    NSString *parentPath = [docPath stringByDeletingLastPathComponent];
    NSString *appID = [parentPath lastPathComponent];
    NSRange foundRange = [absolutePath rangeOfString:appID];
    if (foundRange.location != NSNotFound) {
        return [absolutePath substringFromIndex:foundRange.location + foundRange.length];
    } else {
        //icloud drive outside file
        return absolutePath;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellidentifer = @"CellIdentifer";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidentifer];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellidentifer];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0) {
        UILabel *leftLabel = [[UILabel alloc] init];
        leftLabel.font = [UIFont systemFontOfSize:15.0f];
        leftLabel.backgroundColor = [UIColor clearColor];
        leftLabel.frame = CGRectMake(LEFTMARGEN, 5, 100, 30);

        UILabel *rightLabel = [[UILabel alloc] init];
        rightLabel.font = [UIFont systemFontOfSize:15.0f];
        rightLabel.backgroundColor = [UIColor clearColor];
        rightLabel.frame = CGRectMake(LEFTMARGEN + 100, 5, self.view.bounds.size.width - LEFTMARGEN - 110, 30);

        FSPDFDoc *document = _pdfViewCtrl.currentDoc;
        FSPDFMetadata* metadata = [[FSPDFMetadata alloc] initWithDocument:document];

        if (indexPath.row == 0) {
            leftLabel.text = [NSString stringWithFormat:@"%@:", FSLocalizedString(@"kByFileName")];
            rightLabel.text = [self.extensionsManager.pdfViewCtrl.filePath lastPathComponent];
        } else if (indexPath.row == 1) {
            leftLabel.text = [NSString stringWithFormat:@"%@:", FSLocalizedString(@"kFilePath")];
            rightLabel.text = getRelativePathFromAbsolutePath([self.extensionsManager.pdfViewCtrl.filePath stringByDeletingLastPathComponent]);
        } else if (indexPath.row == 2) {
            leftLabel.text = [NSString stringWithFormat:@"%@:", FSLocalizedString(@"kSize")];

            unsigned long long fileSize = 0;
            NSFileManager *manager = [NSFileManager defaultManager];
            if ([manager fileExistsAtPath:self.extensionsManager.pdfViewCtrl.filePath]) {
                fileSize = [[manager attributesOfItemAtPath:self.extensionsManager.pdfViewCtrl.filePath error:nil] fileSize];
            }
            rightLabel.text = [Utility displayFileSize:fileSize];

        } else if (indexPath.row == 3) {
            leftLabel.text = [NSString stringWithFormat:@"%@:", FSLocalizedString(@"kFileAuthor")];
            rightLabel.text = [metadata getValue:@"Author"];
        } else if (indexPath.row == 4) {
            leftLabel.text = [NSString stringWithFormat:@"%@:", FSLocalizedString(@"kFileSubject")];
            rightLabel.text = [metadata getValue:@"Subject"];
        } else if (indexPath.row == 5) {
            leftLabel.text = [NSString stringWithFormat:@"%@:", FSLocalizedString(@"kCreateDate")];
            rightLabel.text = [Utility displayDateInYMDHM:[Utility convertFSDateTime2NSDate:[metadata getCreationDateTime]]];
        } else if (indexPath.row == 6) {
            leftLabel.text = [NSString stringWithFormat:@"%@:", FSLocalizedString(@"kModifyDate")];
            rightLabel.text = [Utility displayDateInYMDHM:[Utility convertFSDateTime2NSDate:[metadata getModifiedDateTime]]];
        }
        [cell addSubview:leftLabel];
        [cell addSubview:rightLabel];
    } else if (indexPath.section == 1) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:15.0f];
        label.backgroundColor = [UIColor clearColor];
        label.frame = CGRectMake(LEFTMARGEN, 5, 200, 30);

        FSEncryptType type = [_pdfViewCtrl.currentDoc getEncryptionType];
        BOOL isStdEncrypted = (e_encryptPassword == type);

        if (isStdEncrypted) {
            label.text = [NSString stringWithFormat:@"%@", FSLocalizedString(@"kPasswordEncryption")];
        } else {
            label.text = [NSString stringWithFormat:@"%@", FSLocalizedString(@"kNoEncryption")];
        }
        [cell addSubview:label];
    } else if (indexPath.section == 2) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:15.0f];
        label.backgroundColor = [UIColor clearColor];
        label.frame = CGRectMake(LEFTMARGEN, 5, 200, 30);
        [cell addSubview:label];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
    } else if (indexPath.section == 1) {
        [self viewSecurityPermission];
    } else if (indexPath.section == 2) {
    }
}

- (void)viewSecurityPermission {
    FSPDFDoc *document = _pdfViewCtrl.currentDoc;
    PermissionViewController *permissionCtrl = [[PermissionViewController alloc] initWithStyle:UITableViewStyleGrouped];
    BOOL docHasSignature = [Utility isDocumentSigned:document];
    unsigned long allPermission = [document getUserPermissions];
    permissionCtrl.allowOwner = [Utility isOwnerOfDoucment:document];
    if (permissionCtrl.allowOwner) {
        permissionCtrl.allowPrint = YES;
        permissionCtrl.allowFillForm = YES;
        permissionCtrl.allowAssemble = docHasSignature ? NO : YES;
        permissionCtrl.allowAnnotate = YES;
        permissionCtrl.allowEdit = docHasSignature ? NO : YES;
        permissionCtrl.allowExtractAccess = YES;
        permissionCtrl.allowExtract = YES;
    } else {
        permissionCtrl.allowPrint = (allPermission & e_permPrint) > 0;
        permissionCtrl.allowFillForm = [Utility canFillFormInDocument:document];
        permissionCtrl.allowAssemble = docHasSignature ? NO : [Utility canAssembleDocument:document];
        permissionCtrl.allowAnnotate = [Utility canAddAnnotToDocument:document];
        permissionCtrl.allowEdit = docHasSignature ? NO : (allPermission & e_permModify) > 0;
        permissionCtrl.allowExtractAccess = (allPermission & e_permExtractAccess) > 0 || (allPermission & e_permExtract) > 0;
        permissionCtrl.allowExtract = (allPermission & e_permExtract) > 0;
    }

    [permissionCtrl.tableView reloadData];
    [self.navigationController pushViewController:permissionCtrl animated:YES];
}

@end
