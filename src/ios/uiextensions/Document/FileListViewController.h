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

#import "../Common/UIExtensionsSharedHeader.h"
#import "../Thirdparties/DXPopover/DXPopover.h"

@class FileBrowser;

@protocol FSFileSelectDelegate <NSObject>
@required
- (void)didFileSelected:(NSString *)filePath;
@end

// Document module to manage the pdf file list in the home directory.
@interface FSFileListViewController : UIViewController <IDocEventListener>

@property (nonatomic, weak, nullable) id<FSFileSelectDelegate> delegate;

@end
