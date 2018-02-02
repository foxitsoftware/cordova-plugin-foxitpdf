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

#import "../Common/UIExtensionsSharedHeader.h"
#import <UIKit/UIKit.h>

typedef void (^CropViewClosedHandler)(void);

@interface CropViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *viewBackground;
@property (strong, nonatomic) IBOutlet UIView *viewStatusBar;

@property (strong, nonatomic) IBOutlet UIToolbar *topToolbar;
@property (strong, nonatomic) IBOutlet UIButton *buttonNoCrop;
@property (strong, nonatomic) IBOutlet UIButton *buttonCrop;

@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (strong, nonatomic) IBOutlet UIButton *buttonSmartCrop;
@property (strong, nonatomic) IBOutlet UIButton *buttonDetect;
@property (strong, nonatomic) IBOutlet UIButton *buttonFull;

@property (strong, nonatomic) IBOutlet UIButton *buttonPrevPage;
@property (strong, nonatomic) IBOutlet UIButton *buttonNextPage;
@property (strong, nonatomic) IBOutlet UIButton *buttonPageIndex;
@property (strong, nonatomic) IBOutlet UIButton *buttonApply2All;
@property (strong, nonatomic) IBOutlet UIButton *buttonApply2OddEven;

@property (nonatomic, copy) CropViewClosedHandler cropViewClosedHandler;

- (IBAction)noCropClicked:(id)sender;
- (IBAction)smartCropClicked:(id)sender;
- (IBAction)doneClicked:(id)sender;
- (IBAction)autoCropClicked:(id)sender;
- (IBAction)fullCropClicked:(id)sender;
- (IBAction)apply2allClicked:(id)sender;
- (IBAction)apply2oddevenClicked:(id)sender;
- (IBAction)prevPageClicked:(id)sender;
- (IBAction)nextPageClicked:(id)sender;

- (void)setExtension:(UIExtensionsManager *)extensionsManager;
@end
