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

#import "FSFileAndImagePicker.h"
#import "Const.h"
#import "Defines.h"
#import "FileSelectDestinationViewController.h"
#import "PhotoToPDF/PhotoToPDFViewController.h"

@interface FSFileAndImagePicker () <PhotoToPDFViewControllerDelegate>

@property (nonatomic, strong) NSArray<NSString *> *imageTypes;

@end

@implementation FSFileAndImagePicker

- (id)init {
    if (self = [super init]) {
        _imageTypes = @[ @"jbig2", @"jpx", @"tif", @"gif", @"png", @"jpg", @"bmp", @"jpeg" ]; // image types by default
        _expectedFileTypes = _imageTypes;
    }
    return self;
}

- (void)presentInRootViewController:(UIViewController *)rootViewController fromView:(UIView *_Nullable)view {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:DEVICE_iPHONE ? UIAlertControllerStyleActionSheet : UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [self.delegate fileAndImagePickerDidCancel:self];
                                                         }];

    UIAlertAction *fileAction = [UIAlertAction actionWithTitle:@"From Document"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [alert dismissViewControllerAnimated:NO completion:nil];

                                                           FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
                                                           selectDestination.isRootFileDirectory = YES;
                                                           selectDestination.fileOperatingMode = FileListMode_Import;
                                                           selectDestination.expectFileType = self.expectedFileTypes;
                                                           [selectDestination loadFilesWithPath:DOCUMENT_PATH];
                                                           selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder) {
                                                               [controller dismissViewControllerAnimated:YES completion:nil];
                                                               if (destinationFolder.count > 0) {
                                                                   NSString *srcPath = destinationFolder[0];
                                                                   if ([self.imageTypes containsObject:srcPath.pathExtension.lowercaseString]) {
                                                                       UIImage *image = [UIImage imageWithContentsOfFile:srcPath];
                                                                       if (image) {
                                                                           [self.delegate fileAndImagePicker:self didPickImage:image];
                                                                       }
                                                                   } else {
                                                                       [self.delegate fileAndImagePicker:self didPickFileAtPath:srcPath];
                                                                   }
                                                               }
                                                           };
                                                           selectDestination.cancelHandler = ^(FileSelectDestinationViewController *controller) {
                                                               [controller dismissViewControllerAnimated:YES completion:nil];
                                                               [self.delegate fileAndImagePickerDidCancel:self];
                                                           };
                                                           UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
                                                           selectDestinationNavController.modalPresentationStyle = UIModalPresentationFormSheet;
                                                           selectDestinationNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                                                           [rootViewController presentViewController:selectDestinationNavController animated:YES completion:nil];
                                                       }];

    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"From Album"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                                            [alert dismissViewControllerAnimated:NO completion:nil];
                                                            PhotoToPDFViewController *photoController = [[PhotoToPDFViewController alloc] initWithButton:(UIButton*)view];
                                                            photoController.delegate = self;
                                                            [rootViewController presentViewController:photoController animated:NO completion:nil];
                                                            [photoController openAlbum];
                                                        }];

    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"From Camera"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [alert dismissViewControllerAnimated:NO completion:nil];
                                                             PhotoToPDFViewController *photoController = [[PhotoToPDFViewController alloc] initWithButton:(UIButton*)view];
                                                             photoController.delegate = self;
                                                             [rootViewController presentViewController:photoController animated:NO completion:nil];
                                                             [photoController openCamera];
                                                         }];

    [alert addAction:cancelAction];
    [alert addAction:fileAction];
    [alert addAction:photoAction];
    [alert addAction:cameraAction];

    if (view) {
        alert.popoverPresentationController.sourceView = view;
        alert.popoverPresentationController.sourceRect = view.bounds;
    }
    [rootViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark <PhotoToPDFViewControllerDelegate>

- (void)photoToPDFViewController:(PhotoToPDFViewController *)photoToPDFViewController didSelectImage:(UIImage *)image {
    [self.delegate fileAndImagePicker:self didPickImage:image];
}

- (void)photoToPDFViewControllerDidCancel:(PhotoToPDFViewController *)photoToPDFViewController {
    [self.delegate fileAndImagePickerDidCancel:self];
}

@end
