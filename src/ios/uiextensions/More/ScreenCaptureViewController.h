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

#import <UIKit/UIKit.h>

typedef void (^ScreenCaptureClosedHandler)(void);
typedef void (^ScreenCaptureCompelementHandler)(CGRect area);

@class ScreenCaptureView;

@interface ScreenCaptureViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *imgView;
@property (strong, nonatomic) IBOutlet ScreenCaptureView *screenCaptureView;
@property (strong, nonatomic) IBOutlet UIButton *buttonClose;

@property (strong, nonatomic) UIImage *img;
@property (nonatomic,copy) ScreenCaptureClosedHandler screenCaptureClosedHandler;
@property (nonatomic, copy) ScreenCaptureCompelementHandler screenCaptureCompelementHandler;
@property (nonatomic,strong) UIPopoverController *popController;
@property (nonatomic, strong) UIActivityViewController *activityController;

- (IBAction)buttonClose:(id)sender;

@end
