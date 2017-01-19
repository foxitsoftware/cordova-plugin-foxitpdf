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
#import "PermissionViewController.h"
#import "UIExtensionsSharedHeader.h"

@implementation PessmissionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        UILabel *permission=[[[UILabel alloc]init]autorelease];
        permission.tag=100;
        permission.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        permission.font =[UIFont systemFontOfSize:14.0f];
        permission.backgroundColor=[UIColor clearColor];
        permission.frame=CGRectMake(20, 10, self.bounds.size.width - 120, 40);
        permission.center = CGPointMake(permission.center.x, 22);
        
        UILabel *allow=[[[UILabel alloc]init]autorelease];
        allow.tag=101;
        allow.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        allow.font =[UIFont systemFontOfSize:14.0f];
        allow.backgroundColor=[UIColor clearColor];
        allow.frame=CGRectMake(self.bounds.size.width - 100, 10, 100, 40);
        allow.center = CGPointMake(allow.center.x, 22);
        [self.contentView addSubview:permission];
        [self.contentView addSubview:allow];
    }
    return self;
}

@end

@interface PermissionViewController ()

@end

@implementation PermissionViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *imageBackButtonImage = [UIImage imageNamed:@"common_back_black.png"];
    UIButton *buttonBack = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [buttonBack addTarget:self action:@selector(buttonBackClicked:) forControlEvents:UIControlEventTouchUpInside];
    buttonBack.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [buttonBack setImage:imageBackButtonImage forState:UIControlStateNormal];
    [buttonBack setTitleColor:[UIColor colorWithRGBHex:0x179CD8] forState:UIControlStateNormal];
    buttonBack.autoresizesSubviews = YES;
    [buttonBack sizeToFit];
    CGRect frameButtonBack = buttonBack.frame;
    frameButtonBack.size.width = frameButtonBack.size.width ;

    buttonBack.frame = frameButtonBack;
    [buttonBack setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    UIBarButtonItem *barButtonBack = [[UIBarButtonItem alloc] initWithCustomView:buttonBack];
    [self.navigationItem addLeftBarButtonItem:barButtonBack];
    [buttonBack release];
    [barButtonBack release];
    
    if (!self.navigationItem.titleView)
    {
        CGRect titleViewFrame = CGRectMake(0.0, 0.0, 200.0, 44.0f);
        CGRect indicatorFrame = CGRectMake(180.f, 12.0f, 20.0f, 20.0f);
        CGRect titleFrame = CGRectMake(0.0f, 0.0f, 180.0f, 44.0f);
        UIFont *titleFont = [UIFont boldSystemFontOfSize:18.0f];
        if (DEVICE_iPHONE)
        {
            indicatorFrame = CGRectMake(160.f, 12.0f, 20.0f, 20.0f);
            titleFrame = CGRectMake(0.0f, 0.0f, 160.0f, 44.0f);
            titleFont = [UIFont boldSystemFontOfSize:18.0f];
        }
        UIView *titleView= [[UIView alloc] initWithFrame:titleViewFrame];
        UIActivityIndicatorView *actIndicatorView=[[UIActivityIndicatorView alloc] initWithFrame:indicatorFrame];
        actIndicatorView.tag= 1;
        [actIndicatorView setHidden:YES];
        UILabel *titleLabel= [[UILabel alloc] init];
        titleLabel.frame= titleFrame;
        titleLabel.text= self.title;
        titleLabel.textAlignment= NSTextAlignmentCenter;
        titleLabel.autoresizesSubviews= YES;
        titleLabel.textColor= [UIColor colorWithRGBHex:0x3F3F3F];
        titleLabel.font= titleFont;
        titleLabel.tag =2;
        [titleView addSubview:titleLabel];
        [titleView addSubview:actIndicatorView];
        titleLabel.center = titleView.center;
        self.navigationItem.titleView.backgroundColor = [UIColor cyanColor];
        titleView.center = CGPointMake(self.view.frame.size.width/2, titleView.center.y);
        self.navigationItem.titleView = titleView;
        [titleView release];
        [titleLabel release];
        [actIndicatorView release];
    }
    
    if (OS_ISVERSION7)
    {

    }
    if (self.navigationItem.titleView != nil)
    {
        UIView *titleView=(UIView *)self.navigationItem.titleView;
        UILabel *titleLabel= (UILabel *)[titleView viewWithTag:2];
        if (titleLabel)
        {
            titleLabel.text= NSLocalizedString(@"kPermission", nil);
        }
    }
    
    
    [self.tableView setBackgroundView:nil];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
    |UIViewAutoresizingFlexibleLeftMargin;
    
    UIButton *buttonDone = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonDone.frame = CGRectMake(0.0, 0.0, 55.0, 32);
    [buttonDone setTitle:NSLocalizedString(@"kDone", nil) forState:UIControlStateNormal];
    buttonDone.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
     [buttonDone setTitleColor:[UIColor colorWithRGBHex:0x179CD8] forState:UIControlStateNormal];
    [buttonDone addTarget:self action:@selector(buttonDoneClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationItem addRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:buttonDone] autorelease]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    if ([self.navigationController.navigationBar respondsToSelector:@selector(titleTextAttributes)])
    {
        self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor], UITextAttributeTextColor, nil];
    }
    if (OS_ISVERSION7)
    {
    }
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)buttonBackClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)buttonDoneClicked:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{

}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellPermission";
    PessmissionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[PessmissionCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    UILabel *permission = (UILabel*)[cell.contentView viewWithTag:100];
    UILabel *allow = (UILabel*)[cell.contentView viewWithTag:101];
    switch (indexPath.row) {
        case 0:
            permission.text = NSLocalizedString(@"kPermissionPrint", nil);
            if (self.allowPrint || self.allowOwner) {
                allow.text = NSLocalizedString(@"kEnable", nil);
            }
            else
            {
                allow.text = NSLocalizedString(@"kDisable", nil);
            }
            break;
        case 1:
            permission.text = NSLocalizedString(@"kRMSFILLFORM", nil);
            if (self.allowFillForm || self.allowOwner) {
                allow.text = NSLocalizedString(@"kEnable", nil);
            }
            else
            {
                allow.text = NSLocalizedString(@"kDisable", nil);
            }
            break;
        case 2:
            permission.text = NSLocalizedString(@"kRMSASSEMBLE", nil);
            if (self.allowAssemble || self.allowOwner) {
                allow.text = NSLocalizedString(@"kEnable", nil);
            }
            else
            {
                allow.text = NSLocalizedString(@"kDisable", nil);
            }
            break;
        case 3:
            permission.text = NSLocalizedString(@"kRMSANNOTATE", nil);
            if (self.allowAnnotate || self.allowOwner) {
                allow.text = NSLocalizedString(@"kEnable", nil);
            }
            else
            {
                allow.text = NSLocalizedString(@"kDisable", nil);
            }
            break;
        case 4:
            permission.text = NSLocalizedString(@"kRMSEDIT", nil);
            if (self.allowEdit || self.allowOwner) {
                allow.text = NSLocalizedString(@"kEnable", nil);
            }
            else
            {
                allow.text = NSLocalizedString(@"kDisable", nil);
            }
            break;
        case 5:
            permission.text = NSLocalizedString(@"kRMSEXTRACTACCESS", nil);
            if (self.allowExtractAccess || self.allowOwner) {
                allow.text = NSLocalizedString(@"kEnable", nil);
            }
            else
            {
                allow.text = NSLocalizedString(@"kDisable", nil);
            }
            break;
        case 6:
            permission.text = NSLocalizedString(@"kRMSEXTRACT", nil);
            if (self.allowExtract || self.allowOwner) {
                allow.text = NSLocalizedString(@"kEnable", nil);
            }
            else
            {
                allow.text = NSLocalizedString(@"kDisable", nil);
            }
            break;
        default:
            break;
    }
    
    CGSize textSize = [Utility getTextSize:allow.text fontSize:14.0f maxSize:CGSizeMake(100, 20)];
    allow.frame = CGRectMake(cell.contentView.frame.size.width - textSize.width - 10, allow.frame.origin.y, textSize.width + 1, 40);
    
    return cell;
}

@end
