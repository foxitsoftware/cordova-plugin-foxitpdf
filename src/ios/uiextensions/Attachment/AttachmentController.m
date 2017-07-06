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

#import "AttachmentController.h"
#import "Utility.h"
#import "TbBaseBar.h"
#import "Masonry.h"
#import "ColorUtility.h"

#define UX_BG_COLOR_TOOLBAR_LIGHT			0xF5F5F5

@interface AttachmentController()
@property (nonatomic, strong) UIWebView* webView;
@property (nonatomic, strong) TbBaseBar* topToolbar;
@property (nonatomic, strong) TbBaseItem* backItem;
@property (nonatomic, strong) TbBaseItem* titleItem;

@end

@implementation AttachmentController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.view.frame = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT);
        
        // init top toolbar
        self.topToolbar = [[TbBaseBar alloc] init];
        self.topToolbar.contentView.frame = CGRectMake(0, 0, SCREENWIDTH, 64);
        self.topToolbar.contentView.backgroundColor = [UIColor colorWithRGBHex:UX_BG_COLOR_TOOLBAR_LIGHT];
        self.topToolbar.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        
        self.backItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"common_back_black"] imageSelected:[UIImage imageNamed:@"common_back_black"]imageDisable:[UIImage imageNamed:@"common_back_black"]];
        [self.topToolbar addItem:self.backItem displayPosition:Position_LT];
        
        self.titleItem = [TbBaseItem createItemWithTitle:@"-"];
        self.titleItem.textColor = [UIColor colorWithRGBHex:0xff3f3f3f];
        self.titleItem.enable = NO;
        if (!DEVICE_iPHONE) {
            [self.topToolbar addItem:self.titleItem displayPosition:Position_CENTER];
        }
        
        // add view to view controller
        [self.view addSubview:self.topToolbar.contentView];
        
        // set button callback
        __weak typeof(self) weakSelf = self;
        self.backItem.onTapClick = ^(TbBaseItem *item) {
            [weakSelf.webView removeFromSuperview];
            weakSelf.webView = nil;
            [weakSelf dismissViewControllerAnimated:YES completion:^{
                weakSelf.isShowing = NO;
            }];
        };
        
        self.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        if (self.webView == nil) {
            self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
            self.webView.scalesPageToFit = YES;
            self.webView.delegate = self;
            if (OS_ISVERSION9) {
                self.webView.allowsLinkPreview = YES;
            }
            [self.view insertSubview:self.webView atIndex:0];
            [self.webView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.view.mas_left).offset(0);
                make.top.equalTo(self.view.mas_top).offset(64);
                make.right.equalTo(self.view.mas_right).offset(0);
                make.bottom.equalTo(self.view.mas_bottom).offset(0);
            }];
        }
    }
    return self;
}

-(void)viewDidLoad
{
    self.webView.backgroundColor = [UIColor whiteColor];
    self.isShowing = YES;
}

- (BOOL)openDocument:(NSString*)filePath
{
	[_topToolbar removeItem:_titleItem];
    
    NSString *title = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSUInteger prefixLocation = [title rangeOfString:@"_"].location;
    title = [title substringFromIndex:prefixLocation + 1]; // remove prefix
    
	_titleItem.text = title;
    
	if (_titleItem.text.length > 20) {
		_titleItem.text = [NSString stringWithFormat:@"%@..%@", [_titleItem.text substringToIndex:10], [_titleItem.text substringFromIndex:_titleItem.text.length - 10]];
	}
    [_topToolbar addItem:_titleItem displayPosition:Position_CENTER];
	
	BOOL willLoadRequest = YES;
	NSURL *url = [NSURL fileURLWithPath:filePath isDirectory:NO];
    if ([Utility isGivenPath:filePath type:@"pdf"]) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [_webView loadRequest:request];
        willLoadRequest = NO;
    } else if ([Utility isGivenPath:filePath type:@"txt"]
		|| [Utility isGivenPath:filePath type:@"htm"]
		|| [Utility isGivenPath:filePath type:@"html"] ) {
		NSStringEncoding encoding;
		NSError * error = nil;
		NSString * temp = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&error];
		if (!error) {
			if (encoding != NSUTF8StringEncoding) {
				willLoadRequest = NO;
				[self.webView loadHTMLString:temp baseURL:[url URLByDeletingLastPathComponent]];
			}
		} else {
			willLoadRequest = NO;
			NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
			[self.webView loadData:data MIMEType:@"text/html" textEncodingName:@"GBK" baseURL:[url URLByDeletingLastPathComponent]];
		}
	} else if ([Utility isGivenPath:filePath type:@"jpg"]
			   || [Utility isGivenPath:filePath type:@"jpeg"]
			   || [Utility isGivenPath:filePath type:@"png"]
			   || [Utility isGivenPath:filePath type:@"bmp"]
			   || [Utility isGivenPath:filePath type:@"gif"]
			   || [Utility isGivenPath:filePath type:@"tiff"]
			   || [Utility isGivenPath:filePath type:@"tif"]) {
		willLoadRequest = NO;
        
        if ([filePath rangeOfString:@"file://"].location != NSNotFound) {
            //iCloud
            NSString *htmString = [NSString stringWithFormat:@"<!DOCTYPE html><html><body><img src=\"%@\" width=\"100%%\" height=\"100%%\"/></body></html>", filePath];
            [self.webView loadHTMLString:htmString baseURL:nil];

        }
        else
        {
            //Document
            NSString *htmString = [NSString stringWithFormat:@"<!DOCTYPE html><html><body><img src=\"%@\" width=\"100%%\" height=\"100%%\"/></body></html>", [url absoluteString]];
            [self.webView loadHTMLString:htmString baseURL:nil];
        }
        
	}
	
	if (willLoadRequest) {
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		[self.webView loadRequest:request];
	}
	
	return 0;
}
@end
