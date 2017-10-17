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

@class EncryptOptionViewController;
typedef void (^EncryptOptionHandler)(EncryptOptionViewController *ctrl, BOOL isCancel, NSString *openPassword, NSString *permissionPassword, BOOL print, BOOL printHigh, BOOL fillForm, BOOL addAnnot, BOOL assemble, BOOL modify, BOOL copyForAccess, BOOL copy);
typedef void (^EncryptRMSHandler)(EncryptOptionViewController *ctrl);

@interface EncryptOptionViewController : UITableViewController <UITextFieldDelegate, UINavigationControllerDelegate> {
}

@property (strong, nonatomic) IBOutlet UITableViewCell *cellEncryptRMS;
@property (strong, nonatomic) IBOutlet UIButton *buttonEncryptRMS;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellOpenDoc;
@property (strong, nonatomic) IBOutlet UISwitch *switchOpenDoc;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellOpenDocPassword;
@property (strong, nonatomic) IBOutlet UITextField *textboxOpenDocPassword;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellAddLimitation;
@property (strong, nonatomic) IBOutlet UISwitch *switchAddLimitation;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPrintDoc;
@property (strong, nonatomic) IBOutlet UISwitch *switchPrintDoc;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellFillForm;
@property (strong, nonatomic) IBOutlet UISwitch *switchFillForm;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellAnnotDoc;
@property (strong, nonatomic) IBOutlet UISwitch *switchAnnotDoc;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellAssembleDoc;
@property (strong, nonatomic) IBOutlet UISwitch *switchAssembleDoc;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellEditDocument;
@property (strong, nonatomic) IBOutlet UISwitch *switchEditDocument;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellCopyAccessibility;
@property (strong, nonatomic) IBOutlet UISwitch *switchCopyAccessibility;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellExtractContent;
@property (strong, nonatomic) IBOutlet UISwitch *switchExtractContent;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellOtherPassword;
@property (strong, nonatomic) IBOutlet UITextField *textboxOtherPassword;

@property (copy, nonatomic) EncryptOptionHandler optionHandler;
@property (copy, nonatomic) EncryptRMSHandler rmsHandler;
@property (nonatomic, strong) NSObject *currentVC;

- (IBAction)switchOpenDocValueChanged:(id)sender;
- (IBAction)switchPrintDocValueChanged:(id)sender;
- (IBAction)switchCopyAccessibilityValueChanged:(id)sender;
- (IBAction)switchAnnotDocValueChanged:(id)sender;
- (IBAction)switchAssembleDocValueChanged:(id)sender;
- (IBAction)encryptUsingRMS:(id)sender;
- (IBAction)switchFillFormValueChanged:(id)sender;
- (IBAction)switchEditDocumentValueChanged:(id)sender;
- (IBAction)switchExtractContentValueChanged:(id)sender;
- (IBAction)switchAddLimitationValueChanged:(id)sender;

@end
