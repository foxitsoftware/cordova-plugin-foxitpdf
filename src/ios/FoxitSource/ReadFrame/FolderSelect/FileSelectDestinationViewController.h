/**
 * Copyright (C) 2003-2016, Foxit Software Inc..
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
#import "FoxitRDK/FSPDFViewControl.h"

typedef enum FileListMode
{
    FileListMode_Copy = 0,
    FileListMode_Move = 1,
    FileListMode_Upload = 2,
    FileListMode_Select = 3,
    FileListMode_Browse = 4,
    FileListMode_Import = 5,

} FileListMode;

@interface FileItem : NSObject

@property (nonatomic,retain) NSString *title;
@property (nonatomic,assign) BOOL isFolder;
@property (nonatomic,retain) NSString *filekey;
@property(nonatomic,assign)BOOL selected;

@end


@interface FileViewCell : UITableViewCell

@property(nonatomic,retain)UIImageView* fileTypeImage;
@property(nonatomic,retain)UIImageView* previousImage;
@property(nonatomic,retain)UILabel* folderName;
@property(nonatomic,retain)UILabel* backName;
@property(nonatomic,retain)UIImageView* fileSelectImage;
@property(nonatomic,retain)UIView * separatorLine;

@end

@class FileSelectDestinationViewController;

typedef void (^FileDoneHandler)(FileSelectDestinationViewController *controller, NSArray *destinationFolder);
typedef void (^FileCallOffHandler)(void);

@interface FileSelectDestinationViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (retain, nonatomic) NSArray            *exceptFolderList;
@property (nonatomic,retain ) UITableView        *tableViewFolders;
@property (nonatomic,retain ) NSArray            *expectFileType;
@property (nonatomic,assign ) FileListMode       fileOperatingMode;
@property (nonatomic,retain ) NSMutableArray     * fileItemsArray;
@property (nonatomic,assign ) BOOL               isRootFileDirectory;
@property (nonatomic, retain) NSArray            *operatingFiles;
@property (copy, nonatomic  ) FileDoneHandler    operatingHandler;
@property (copy, nonatomic  ) FileCallOffHandler cancelHandler;
@property (nonatomic,retain ) UIBarButtonItem    *buttonDone;

- (void)loadFilesWithPath:(NSString *)filePath;
- (void)setNavigationTitle:(NSString *)title;
@end
