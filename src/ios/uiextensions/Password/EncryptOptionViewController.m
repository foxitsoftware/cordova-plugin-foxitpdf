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

#import "EncryptOptionViewController.h"
#import "../Common/UIExtensionsSharedHeader.h"

@interface EncryptOptionViewController ()
@property (nonatomic, strong) UIButton *buttonDone;

- (void)buttonCancelClicked:(id)sender;
- (void)buttonDoneClicked:(id)sender;
- (void)initNavigationBar;
- (void)refreshInterface;

@end

@implementation EncryptOptionViewController

@synthesize cellOpenDoc;
@synthesize switchOpenDoc;
@synthesize cellPrintDoc;
@synthesize switchPrintDoc;
@synthesize cellCopyAccessibility;
@synthesize switchCopyAccessibility;
@synthesize cellOpenDocPassword;
@synthesize textboxOpenDocPassword;
@synthesize cellOtherPassword;
@synthesize textboxOtherPassword;
@synthesize cellEncryptRMS;
@synthesize buttonEncryptRMS;
@synthesize optionHandler = _optionHandler;
@synthesize rmsHandler = _rmsHandler;

#pragma mark - life cycle

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(StateOfDoneButton) name:UITextFieldTextDidChangeNotification object:nil];
    if (DEVICE_iPHONE) {
        [self.tableView setBackgroundColor:[UIColor colorWithRed:230.0 / 255.0 green:230.0 / 255.0 blue:230.0 / 255.0 alpha:1.0]];
        [self.tableView setBackgroundView:nil];
    }
    UIButton *buttonCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonCancel.frame = CGRectMake(0.0, 0.0, 55.0, 32);
    [buttonCancel setTitle:FSLocalizedString(@"kCancel") forState:UIControlStateNormal];
    buttonCancel.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    [buttonCancel setTitleColor:[UIColor colorWithRed:1.f / 255.f green:144.f / 255.f blue:210.f / 255.f alpha:1.f] forState:UIControlStateNormal];
    [buttonCancel setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [buttonCancel addTarget:self action:@selector(buttonCancelClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationItem addLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:buttonCancel]];

    self.buttonDone = [UIButton buttonWithType:UIButtonTypeCustom];
    _buttonDone.frame = CGRectMake(0.0, 0.0, 55.0, 32);
    [_buttonDone setTitle:FSLocalizedString(@"kDone") forState:UIControlStateNormal];
    _buttonDone.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];

    self.buttonDone.userInteractionEnabled = NO;
    [_buttonDone setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    self.buttonDone.alpha = 0.4;

    [_buttonDone setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [_buttonDone addTarget:self action:@selector(buttonDoneClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationItem addRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:_buttonDone]];

    [self refreshInterface];
}

- (void)viewDidUnload {
    [self setCellOpenDoc:nil];
    [self setSwitchOpenDoc:nil];
    [self setCellPrintDoc:nil];
    [self setSwitchPrintDoc:nil];
    [self setCellCopyAccessibility:nil];
    [self setSwitchCopyAccessibility:nil];
    [self setCellOpenDocPassword:nil];
    [self setTextboxOpenDocPassword:nil];
    [self setCellOtherPassword:nil];
    [self setTextboxOtherPassword:nil];
    [self setCellEncryptRMS:nil];
    [self setButtonEncryptRMS:nil];
    [self setCellAnnotDoc:nil];
    [self setSwitchAnnotDoc:nil];
    [self setCellAssembleDoc:nil];
    [self setSwitchAssembleDoc:nil];
    [self setCellFillForm:nil];
    [self setSwitchFillForm:nil];
    [self setCellAddLimitation:nil];
    [self setSwitchAddLimitation:nil];
    [self setCellEditDocument:nil];
    [self setSwitchEditDocument:nil];
    [self setCellExtractContent:nil];
    [self setSwitchExtractContent:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Table view data source
//TODO
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //disable RMS encrypt
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return FSLocalizedString(@"kEncryptionSectionTitle");
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return FSLocalizedString(@"kEncryptionSectionFooter");
    }
    return nil;
}

//TODO:
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        int rowCount = 2; //info cells
        if (switchOpenDoc.on) {
            rowCount++; //show open doc password
        }
        if (_switchAddLimitation.on) {
            rowCount += 8;
        }
        return rowCount;
    } else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

//TODO:
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSInteger row = indexPath.row;
        if (row == 0) {
            return cellOpenDoc;
        }
        if (switchOpenDoc.on) {
            row--;
        }
        if (row == 0) {
            return cellOpenDocPassword;
        }
        if (row == 1) {
            return _cellAddLimitation;
        }
        if (row == 2) {
            return cellPrintDoc;
        }
        if (row == 3) {
            return _cellFillForm;
        }
        if (row == 4) {
            return _cellAnnotDoc;
        }
        if (row == 5) {
            return _cellAssembleDoc;
        }
        if (row == 6) {
            return _cellEditDocument;
        }
        if (row == 7) {
            return cellCopyAccessibility;
        }
        if (row == 8) {
            return _cellExtractContent;
        }
        if (_switchAddLimitation.on && row == 9) {
            return cellOtherPassword;
        }
    } else {
        return cellEncryptRMS;
    }

    return nil;
}

#pragma mark - UITextField delegate handler

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)StateOfDoneButton {
    if (self.textboxOtherPassword.text.length == 0 && self.textboxOpenDocPassword.text.length == 0) {
        self.buttonDone.userInteractionEnabled = NO;
        [_buttonDone setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    } else {
        [self.buttonDone setTitleColor:[UIColor colorWithRed:1.f / 255.f green:144.f / 255.f blue:210.f / 255.f alpha:1.f] forState:UIControlStateNormal];
        self.buttonDone.userInteractionEnabled = YES;
        self.buttonDone.alpha = 1;
    }
}

#pragma mark - UINavigationController delegate handler

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    navigationController.navigationBar.tag = 1;
    navigationController.navigationBar.barTintColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    [self initNavigationBar];
}

#pragma mark - event handler

- (IBAction)switchOpenDocValueChanged:(id)sender {
    if (!((UISwitch *) sender).on) {
        self.textboxOpenDocPassword.text = nil;
    }
    [self StateOfDoneButton];
    [self.tableView reloadData];
}

- (IBAction)switchPrintDocValueChanged:(id)sender {
    [self.tableView reloadData];
}

- (IBAction)switchCopyAccessibilityValueChanged:(id)sender {
    if (!((UISwitch *) sender).on) {
        self.switchExtractContent.on = NO;
    }
    [self.tableView reloadData];
}

- (IBAction)switchAnnotDocValueChanged:(id)sender {
    if (((UISwitch *) sender).on) {
        self.switchFillForm.on = YES;
    }
    [self.tableView reloadData];
}

- (IBAction)switchAssembleDocValueChanged:(id)sender {
    if (!((UISwitch *) sender).on) {
        self.switchEditDocument.on = NO;
    }
    [self.tableView reloadData];
}

- (IBAction)encryptUsingRMS:(id)sender {
    if (self.rmsHandler != nil) {
        self.rmsHandler(self);
    }

    [self close];
}

- (IBAction)switchFillFormValueChanged:(id)sender {
    if (!((UISwitch *) sender).on) {
        self.switchAnnotDoc.on = NO;
        self.switchEditDocument.on = NO;
    }
    [self.tableView reloadData];
}

- (IBAction)switchEditDocumentValueChanged:(id)sender {
    if (((UISwitch *) sender).on) {
        self.switchAssembleDoc.on = YES;
        self.switchFillForm.on = YES;
    }
    [self.tableView reloadData];
}

- (IBAction)switchExtractContentValueChanged:(id)sender {
    if (((UISwitch *) sender).on) {
        self.switchCopyAccessibility.on = YES;
    }
    [self.tableView reloadData];
}

- (IBAction)switchAddLimitationValueChanged:(id)sender {
    if (!((UISwitch *) sender).on) {
        self.textboxOtherPassword.text = nil;
    }
    [self StateOfDoneButton];
    [self.tableView reloadData];
}

- (void)buttonCancelClicked:(id)sender {
    if (self.optionHandler != nil) {
        self.optionHandler(self, YES, nil, nil, NO, NO, NO, NO, NO, NO, NO, NO);
    }
    [self close];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)buttonDoneClicked:(id)sender {
    if (switchOpenDoc.on && textboxOpenDocPassword.text.length == 0) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kEncryptMissOpenDocPass" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
        self.currentVC = alertView;
        [alertView show];
        return;
    }
    if ((switchPrintDoc.on || switchCopyAccessibility.on || _switchAnnotDoc.on || _switchAssembleDoc.on || _switchExtractContent.on || _switchFillForm.on || _switchEditDocument.on) && textboxOtherPassword.text.length == 0 && textboxOpenDocPassword.text.length == 0) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kEncryptMissOtherPass" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
        self.currentVC = alertView;
        [alertView show];
        return;
    }
    if ([textboxOpenDocPassword.text isEqualToString:textboxOtherPassword.text]) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kPasswordNotSame" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
        self.currentVC = alertView;
        [alertView show];
        return;
    }
    if (self.optionHandler != nil) {
        NSString *openDocPass = (textboxOpenDocPassword.text.length == 0) ? nil : textboxOpenDocPassword.text;
        NSString *otherPass = (textboxOtherPassword.text.length == 0) ? nil : textboxOtherPassword.text;
        if (openDocPass == nil && otherPass == nil) //if none password is enter, tell user to give up
        {
            AlertViewButtonClickedHandler buttonClickedHandler = ^(UIView *alertView, NSInteger buttonIndex) {
                if (buttonIndex == 0) //not encrypt
                {
                    self.optionHandler(self, YES, nil, nil, NO, NO, NO, NO, NO, NO, NO, NO);
                    [self close];
                } else if (buttonIndex == 1) //yes, encrypt
                {
                    //nothing to do, the dialog is still open
                }
            };
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm" message:@"kEncryptionDoneNoPass" buttonClickHandler:buttonClickedHandler cancelButtonTitle:@"kNo" otherButtonTitles:@"kYes", nil];
            self.currentVC = alertView;
            [alertView show];
            return;
        }
        self.optionHandler(self, NO, openDocPass, otherPass, switchPrintDoc.on, NO, _switchFillForm.on, _switchAnnotDoc.on, _switchAssembleDoc.on, _switchEditDocument.on, switchCopyAccessibility.on, _switchExtractContent.on);
    }
    [self close];
}

#pragma mark - Private methods

- (void)initNavigationBar {
    if (!self.navigationItem.titleView) {
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 170.0f, 44.0f)];
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.frame = CGRectMake(00.0f, 0.0f, 170.0, 44.0f);
        titleLabel.text = FSLocalizedString(@"kEncryptionTitle");
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.autoresizesSubviews = YES;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.font = [UIFont systemFontOfSize:18.0f];
        titleLabel.tag = 2;
        [titleView addSubview:titleLabel];
        self.navigationItem.titleView = titleView;
    }
}

//TODO
- (void)refreshInterface {
    id labelTitle = [cellOpenDoc.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kCellEncryptOpenDocumentTitle");
    }
    labelTitle = [cellPrintDoc.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kCellEncryptPrintDocumentTitle");
    }
    labelTitle = [cellCopyAccessibility.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kCellEncryptCopyContentTitle");
    }
    labelTitle = [_cellAnnotDoc.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kRMSANNOTATE");
    }
    labelTitle = [_cellAssembleDoc.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kRMSASSEMBLE");
    }
    labelTitle = [cellOpenDocPassword.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kCellEncryptPasswordTitle");
    }
    labelTitle = [cellOtherPassword.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kCellEncryptPasswordTitle");
    }
    labelTitle = [_cellAddLimitation.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kPwdDocumentLimitation");
    }
    labelTitle = [_cellFillForm.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kPwdFillForm");
    }
    labelTitle = [_cellEditDocument.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kPwdEditDocument");
    }
    labelTitle = [_cellExtractContent.contentView viewWithTag:100];
    if ([labelTitle isMemberOfClass:[UILabel class]]) {
        ((UILabel *) labelTitle).text = FSLocalizedString(@"kPwdExtractContent");
    }
    textboxOpenDocPassword.placeholder = FSLocalizedString(@"kRequiredPlaceHolder");
    textboxOtherPassword.placeholder = FSLocalizedString(@"kRequiredPlaceHolder");
    [buttonEncryptRMS setTitle:FSLocalizedString(@"kRMSEncrypt") forState:UIControlStateNormal];
}

@end
