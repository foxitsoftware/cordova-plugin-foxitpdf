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

#import <UIKit/UIKit.h>

typedef enum FileListMode {
    FileListMode_Select = 0,
    FileListMode_Import = 1,
    FileListMode_SaveTo = 2,
} FileListMode;

@interface FileViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *fileTypeImage;
@property (nonatomic, strong) UIImageView *previousImage;
@property (nonatomic, strong) UILabel *folderName;
@property (nonatomic, strong) UILabel *backName;
@property (nonatomic, strong) UIImageView *fileSelectImage;
@property (nonatomic, strong) UIView *separatorLine;

@end

@class FileSelectDestinationViewController;

typedef void (^FileDoneHandler)(FileSelectDestinationViewController *controller, NSArray *destinationFolder);
typedef void (^FileCallOffHandler)(void);

@interface FileSelectDestinationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *exceptFolderList;
@property (nonatomic, strong) UITableView *tableViewFolders;
@property (nonatomic, strong) NSArray *expectFileType;
@property (nonatomic, assign) FileListMode fileOperatingMode;
@property (nonatomic, strong) NSMutableArray *fileItemsArray;
@property (nonatomic, assign) BOOL isRootFileDirectory;
@property (nonatomic, strong) NSArray *operatingFiles;
@property (copy, nonatomic) FileDoneHandler operatingHandler;
@property (copy, nonatomic) FileCallOffHandler cancelHandler;
@property (nonatomic, strong) UIBarButtonItem *buttonDone;

- (void)loadFilesWithPath:(NSString *)filePath;
- (void)setNavigationTitle:(NSString *)title;
@end
