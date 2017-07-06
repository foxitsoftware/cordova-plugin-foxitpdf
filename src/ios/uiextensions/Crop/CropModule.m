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

#import "CropModule.h"
#import "CropViewController.h"

@interface CropModule ()
@property (nonatomic ,strong) CropViewController *cropVC;
@end

@implementation CropModule
{
    FSPDFViewCtrl* __weak _pdfViewCtrl;
    UIExtensionsManager* __weak _extensionsManager;
    FSPDFReader* __weak _pdfReader;
}

-(NSString*)getName
{
    return @"Crop";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager pdfReader:(FSPDFReader*)pdfReader
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _pdfReader = pdfReader;
        
        [self loadModule];
    }
    return self;
}

- (void)setCropMode
{
	CropViewController *cropViewController = [[CropViewController alloc] initWithNibName:@"CropViewController" bundle:nil];
    [cropViewController setExtension:_extensionsManager pdfReader:_pdfReader];
	cropViewController.cropViewClosedHandler = ^() {
	};
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:cropViewController];
	navController.navigationBarHidden = YES;
    self.cropVC = cropViewController;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[_pdfViewCtrl.window.rootViewController presentViewController:navController animated:YES completion:nil];
	});
}

#pragma IAppModule methods

-(void)loadModule
{
	__weak typeof(self) weakSelf = self;
	_pdfReader.settingBarController.settingBar.cropage = ^(BOOL flag) {
		[weakSelf setCropMode];
		_pdfReader.hiddenSettingBar = YES;
		[_pdfReader.settingBarController.settingBar setItemState:YES value:0 itemType:CROPPAGE];
	};
}

@end
