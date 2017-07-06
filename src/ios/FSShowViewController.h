//
//  FSviewControllerViewController.h
//  HelloCordova
//
//  Created by huang_niu on 2017/7/6.
//
//

#import <UIKit/UIKit.h>
#import <FoxitRDK/FSPDFViewControl.h>
#import "uiextensions/UIExtensionsManager.h"

@interface FSShowViewController : UIViewController

@property (nonatomic, strong) FSPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, strong) UIExtensionsManager *extensionMgr;
@property (nonatomic, strong) FSPDFReader *pdfReader;
@property (nonatomic, strong) UINavigationController *stackRootNavVC;

@end
