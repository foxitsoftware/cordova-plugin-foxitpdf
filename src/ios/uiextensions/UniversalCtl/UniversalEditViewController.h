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

#import "Defines.h"
#import <UIKit/UIKit.h>

typedef enum {
    UNIVERSAL_EDIT_STYLE_SINGLE,
    UNIVERSAL_EDIT_STYLE_MULTIPLE
} UNIVERSAL_EDIT_STYLE;

typedef void (^UniversalEditingDone)(NSString *text);
typedef void (^UniversalEditingCancel)(void);

@interface UniversalEditViewController : UITableViewController <UITextViewDelegate, UITextFieldDelegate>

@property (assign, nonatomic) UNIVERSAL_EDIT_STYLE editStyle;
@property (assign, nonatomic) BOOL autoIntoEditing;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellSingle;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellMutliple;
@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) NSString *placeholderText;
@property (strong, nonatomic) NSString *footTipText;
@property (strong, nonatomic) NSString *textContent;

@property (copy, nonatomic) UniversalEditingDone editingDoneHandler;
@property (copy, nonatomic) UniversalEditingCancel editingCancelHandler;

- (IBAction)editingChanged:(UITextField *)sender;
- (void)doneAction:(id)sender;
- (void)cancelAction:(id)sender;
@end
