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

typedef enum FileListMode
{
    FileListMode_Copy = 0,
    FileListMode_Move = 1,
    FileListMode_Upload = 2,
    FileListMode_Select = 3,
    FileListMode_Browse = 4,
    FileListMode_Import = 5,
    FileListMode_SaveTo = 6,
} FileListMode;

@interface FileItem : NSObject

@property (nonatomic,strong) NSString *title;
@property (nonatomic,assign) BOOL isFolder;
@property (nonatomic,strong) NSString *filekey;
@property(nonatomic,assign)BOOL selected;

@end


@interface FileViewCell : UITableViewCell

@property(nonatomic,strong)UIImageView* fileTypeImage;
@property(nonatomic,strong)UIImageView* previousImage;
@property(nonatomic,strong)UILabel* folderName;
@property(nonatomic,strong)UILabel* backName;
@property(nonatomic,strong)UIImageView* fileSelectImage;
@property(nonatomic,strong)UIView * separatorLine;

@end

@class FileSelectDestinationViewController;

typedef void (^FileDoneHandler)(FileSelectDestinationViewController *controller, NSArray *destinationFolder);
typedef void (^FileCallOffHandler)(void);

@interface FileSelectDestinationViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) NSArray            *exceptFolderList;
@property (nonatomic,strong ) UITableView        *tableViewFolders;
@property (nonatomic,strong ) NSArray            *expectFileType;
@property (nonatomic,assign ) FileListMode       fileOperatingMode;
@property (nonatomic,strong ) NSMutableArray     * fileItemsArray;
@property (nonatomic,assign ) BOOL               isRootFileDirectory;
@property (nonatomic, strong) NSArray            *operatingFiles;
@property (copy, nonatomic  ) FileDoneHandler    operatingHandler;
@property (copy, nonatomic  ) FileCallOffHandler cancelHandler;
@property (nonatomic,strong ) UIBarButtonItem    *buttonDone;

- (void)loadFilesWithPath:(NSString *)filePath;
- (void)setNavigationTitle:(NSString *)title;
@end
