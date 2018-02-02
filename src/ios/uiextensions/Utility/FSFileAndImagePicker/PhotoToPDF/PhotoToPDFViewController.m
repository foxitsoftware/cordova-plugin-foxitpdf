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

#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "PhotoToPDFViewController.h"

@interface PhotoToPDFViewController ()

@property (nonatomic, strong) UIImagePickerController *mediaController;

@end

@implementation PhotoToPDFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (id)initWithButton:(UIButton *)button {
    self = [super init];
    if (self) {
        self.mediaController = [[UIImagePickerController alloc] init];

        self.mediaController.delegate = self;
        if (button) {
            self.mediaController.popoverPresentationController.sourceRect = button.bounds;
            self.mediaController.popoverPresentationController.sourceView = button;
        }
    }
    return self;
}

- (void)openAlbum {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.mediaController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

        [self presentViewController:self.mediaController animated:NO completion:nil];
    } else {
        [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:NO completion:nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"This device doesn't support album." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)openCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.mediaController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.mediaController.showsCameraControls = YES;

        [self presentViewController:self.mediaController animated:NO completion:nil];
    } else {
        [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:NO completion:nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"This device doesn't support camera." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:NO completion:nil];
    if (self.delegate) {
        UIImage *uiImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
        [self.delegate photoToPDFViewController:self didSelectImage:uiImage];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:NO completion:nil];
    [self.delegate photoToPDFViewControllerDidCancel:self];
}

@end
