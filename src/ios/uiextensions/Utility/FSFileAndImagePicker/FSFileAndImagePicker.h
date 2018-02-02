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

@class FSFileAndImagePicker;

NS_ASSUME_NONNULL_BEGIN

@protocol FSFileAndImagePickerDelegate

@optional
- (void)fileAndImagePicker:(FSFileAndImagePicker *)fileAndImagePicker didPickFileAtPath:(NSString *)filePath;
- (void)fileAndImagePicker:(FSFileAndImagePicker *)fileAndImagePicker didPickImage:(UIImage *)image;
- (void)fileAndImagePickerDidCancel:(FSFileAndImagePicker *)fileAndImagePicker;

@end

@interface FSFileAndImagePicker : NSObject

@property (nonatomic, weak) id<FSFileAndImagePickerDelegate> delegate;
@property (nonatomic, strong) NSArray<NSString *> *expectedFileTypes;

- (void)presentInRootViewController:(UIViewController *)rootViewController fromView:(UIView *_Nullable)view;

@end

NS_ASSUME_NONNULL_END
