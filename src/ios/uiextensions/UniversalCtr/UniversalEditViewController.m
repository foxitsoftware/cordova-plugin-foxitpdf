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

#import "Const.h"
#import "UniversalEditViewController.h"
#import "ColorUtility.h"
#import "AlertView.h"
@interface UniversalEditViewController ()

- (void)initNavigationBar;

@end

@implementation UniversalEditViewController
@synthesize editStyle = _editStyle;
@synthesize autoIntoEditing = _autoIntoEditing;
@synthesize textField = _textField;
@synthesize textView = _textView;
@synthesize cellSingle = _cellSingle;
@synthesize cellMutliple = _cellMutliple;

@synthesize placeholderText = _placeholderText;
@synthesize footTipText = _footTipText;
@synthesize textContent = _textContent;

@synthesize editingDoneHandler = _editingDoneHandler;
@synthesize editingCancelHandler = _editingCancelHandler;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (APPLICATION_ISFULLSCREEN)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    [self initNavigationBar];
    self.tableView.backgroundColor = [UIColor colorWithHexString:@"E0E0E2"];
    [self.tableView reloadData];
    self.textField.delegate = self;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (_autoIntoEditing)
    {
        if (_editStyle == UNIVERSAL_EDIT_STYLE_SINGLE)
        {
            [_textField becomeFirstResponder];
        }
        else
        {
            [_textView becomeFirstResponder];
        }
    }
    self.navigationController.navigationBar.tag = 1;
    if ([self.navigationController.navigationBar respondsToSelector:@selector(titleTextAttributes)])
    {
        self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor], UITextAttributeTextColor, nil];
    }
    if (OS_ISVERSION7)
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.translucent = YES;
    }
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRGBHex:0x179cd8];
}

- (void)dealloc
{
    self.textField = nil;
    self.textView = nil;
    self.cellSingle = nil;
    self.cellMutliple = nil;
    self.placeholderText = nil;
    self.footTipText = nil;
    self.textContent = nil;
    self.editingDoneHandler = nil;
    self.editingCancelHandler = nil;
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.textField = nil;
    self.textView = nil;
    self.cellSingle = nil;
    self.cellMutliple = nil;  
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; //(interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_editStyle == UNIVERSAL_EDIT_STYLE_SINGLE)
    {
        return 44;
    }
    else
    {
        return 95;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _footTipText;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (_editStyle == UNIVERSAL_EDIT_STYLE_SINGLE)
    {
        cell = _cellSingle;
        _textField.text = _textContent;
        _textField.placeholder = _placeholderText;
    }
    else
    {
        cell = _cellMutliple;
        _textView.text = _textContent;
    }
    // Configure the cell...
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"/"]) {
        
        return YES;
    }
    return YES;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"Nib name" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

#pragma mark - properties
- (void)setEditStyle:(UNIVERSAL_EDIT_STYLE)editStyle
{
    if (_editStyle == editStyle)
    {
        return;
    }
    _editStyle = editStyle;
    [self.tableView reloadData];
}

- (void)setTextContent:(NSString *)textContent
{
    if ([_textContent isEqualToString:textContent])
    {
        return;
    }
    [textContent retain];
    [_textContent release];
    _textContent = textContent;
    [self.tableView reloadData];
}

- (void)setPlaceholderText:(NSString *)placeholderText
{
    if ([_placeholderText isEqualToString:placeholderText])
    {
        return;
    }
    [placeholderText retain];
    [_placeholderText release];
    _placeholderText = placeholderText;
    [self.tableView reloadData];
}

- (void)setFootTipText:(NSString *)footTipText
{
    if ([_footTipText isEqualToString:footTipText])
    {
        return;
    }
    [footTipText retain];
    [_footTipText release];
    _footTipText = footTipText;
    [self.tableView reloadData];
}

#pragma mark - UITextView delegate

- (void)textViewDidChange:(UITextView *)textView
{
    [_textContent release];
    _textContent = [textView.text retain];
}

#pragma mark - UITextField event

- (IBAction)editingChanged:(UITextField *)sender
{
    [_textContent release];
    _textContent = [sender.text retain];
}

#pragma mark - event handler
- (void)doneAction:(id)sender
{
    if (_textContent == nil || _textContent.length == 0)
    {
        AlertView *alertView = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"kWarning",nil) message:NSLocalizedString(@"kInputNewFileName",nil) buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil] autorelease];
        [alertView show];
        return;
    }
    else if ([_textContent rangeOfString:@"/"].location != NSNotFound)
    {
        AlertView *alertView = [[AlertView alloc] initWithTitle:NSLocalizedString(@"kWarning",nil) message:NSLocalizedString(@"kIllegalNameWarning",nil) buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    //Avi - in Case of foldername starting from . show error
    else if ([[[_textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"."]) {
        
        AlertView *alertView = [[AlertView alloc] initWithTitle:NSLocalizedString(@"kWarning",nil) message:NSLocalizedString(@"kIllegalNameWarning",nil) buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil];
        [alertView show];
        return;
        
    }

    if (_editingDoneHandler)
    {
        _editingDoneHandler(_textContent);
    }
}

- (void)cancelAction:(id)sender
{
    if (_editingCancelHandler)
    {
        _editingCancelHandler();
    }
}


#pragma mark - private methods

- (void)initNavigationBar
{
    UIButton *buttonCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonCancel.frame = CGRectMake(0.0, 0.0, 55.0, 32);
    [buttonCancel setTitle:NSLocalizedString(@"kCancel", nil) forState:UIControlStateNormal];
    buttonCancel.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    [buttonCancel setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [buttonCancel addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationItem addLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:buttonCancel] autorelease]];

    UIButton *buttonDone = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonDone.frame = CGRectMake(0.0, 0.0, 55.0, 32);
    [buttonDone setTitle:NSLocalizedString(@"kDone", nil) forState:UIControlStateNormal];
    buttonDone.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    [buttonDone setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [buttonDone addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationItem addRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:buttonDone] autorelease]];
}
@end
