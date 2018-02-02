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

#import "ScreenCaptureViewController.h"
#import "ScreenCaptureView.h"
#import "Const.h"
#import "Utility.h"

@interface ScreenCaptureViewController () <UIPopoverControllerDelegate>



@end

@implementation ScreenCaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.imgView.contentMode = UIViewContentModeScaleAspectFit;
    self.imgView.image = self.img;
    
    __weak __typeof__(self) weakSelf = self;
    
    self.screenCaptureView.rectSelectedHandler = ^(CGRect rect)
    {
        UIImage * img = [Utility screenShot:weakSelf.view];
        UIImage *image = [Utility cropImage:img rect:UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(2, 2, 2, 2))];
        
        if (image)
        {
            NSMutableArray *activities = [NSMutableArray array];
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:activities];

            weakSelf.activityController = activityController;
            activityController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError)
            {
                if(weakSelf.screenCaptureCompelementHandler)
                {
                    weakSelf.screenCaptureCompelementHandler(weakSelf.screenCaptureView.captureRect);
                }
                [weakSelf.screenCaptureView reset];
            };
            if (DEVICE_iPHONE)
            {
                [weakSelf presentViewController:activityController animated:YES completion:nil];
            }
            else
            {
                weakSelf.popController = [[UIPopoverController alloc] initWithContentViewController:activityController];
                weakSelf.popController.delegate = weakSelf;
                [weakSelf.popController presentPopoverFromRect:CGRectMake(weakSelf.view.bounds.size.width/2, weakSelf.view.bounds.size.height/2, 100, 100) inView:weakSelf.screenCaptureView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        }
    };
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
//    [_imgView release];
//    [_screenCaptureView release];
//    [_buttonClose release];
    
    self.img = nil;
    self.popController = nil;
    self.screenCaptureClosedHandler = nil;
    
    //[super dealloc];
}

- (void)viewDidUnload
{
    [self setImgView:nil];
    [self setScreenCaptureView:nil];
    [self setButtonClose:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)buttonClose:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (self.screenCaptureClosedHandler)
    {
        self.screenCaptureClosedHandler();
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self.screenCaptureView reset];
}

@end
