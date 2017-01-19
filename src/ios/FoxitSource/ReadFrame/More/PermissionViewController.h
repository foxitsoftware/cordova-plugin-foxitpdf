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

@interface PessmissionCell : UITableViewCell

@end

// a table listing all pdf permissions
@interface PermissionViewController : UITableViewController

@property (nonatomic, assign) BOOL allowOwner;
@property (nonatomic, assign) BOOL allowPrint;
@property (nonatomic, assign) BOOL allowFillForm;
@property (nonatomic, assign) BOOL allowAssemble;
@property (nonatomic, assign) BOOL allowAnnotate;
@property (nonatomic, assign) BOOL allowEdit;
@property (nonatomic, assign) BOOL allowExtractAccess;
@property (nonatomic, assign) BOOL allowExtract;

- (void)buttonDoneClicked:(id)sender;

@end
