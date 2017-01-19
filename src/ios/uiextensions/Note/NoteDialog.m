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
#import "NoteDialog.h"
#import "ColorUtility.h"
#import "UINavigationItem+IOS7PaddingAdditions.h"

@interface NoteDialog ()

@property (nonatomic, retain) UITextView *textViewNote;
@property (nonatomic, retain) FSAnnot *rootAnnot;
@property (nonatomic, retain) UIButton *buttonDone;
@property (nonatomic, assign) CGFloat difference;
@end

static FSPDFViewCtrl* _pdfViewCtrl = nil;

@implementation NoteDialog

+ (void)setViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl
{
    _pdfViewCtrl = pdfViewCtrl;
}

+(NoteDialog*)defaultNoteDialog
{
    static NoteDialog *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NoteDialog alloc] init];
    });
    return instance;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.difference = 0;
    self.view.backgroundColor = [UIColor colorWithRGBHex:0xfffbdb];
    if ([UIViewController instancesRespondToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    if ([UIViewController instancesRespondToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    self.textViewNote = [[[UITextView alloc] init] autorelease];
    self.textViewNote.font = [UIFont systemFontOfSize:15.0f];
    self.textViewNote.translatesAutoresizingMaskIntoConstraints = NO;
    [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(setFrame) userInfo:nil repeats:NO];
    self.textViewNote.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textViewNote.inputAccessoryView = nil;
    
    [self.view addSubview:self.textViewNote];
    if (OS_ISVERSION7) {
        self.textViewNote.delegate = self;
    }
    
    [self.textViewNote becomeFirstResponder];
}
- (void)setFrame{
    self.textViewNote.backgroundColor = [UIColor clearColor];
   
    if (DEVICE_iPHONE) {
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            self.textViewNote.frame = CGRectMake(0, 0, SCREENHEIGHT, SCREENWIDTH - 64);
          
        }else{
            self.textViewNote.frame = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT - 64);
                if([UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].bounds.size.height ==  414 * 736){
                    self.textViewNote.frame = self.view.bounds;
                }
        }
    }else{
        self.textViewNote.frame = self.view.bounds;
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasHidden:) name:UIKeyboardDidHideNotification object:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self adjustTextFrame];
}
-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    navigationController.navigationBar.tag = 1;
    navigationController.navigationBar.barTintColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    if (viewController == self) {
        [self viewWillAppear:NO];
        if (self.navigationItem.titleView != nil)
        {
            UIView *titleView = (UIView*)self.navigationItem.titleView;
            UILabel *titleLabel = (UILabel*)[titleView viewWithTag:2];
            if (titleLabel)
            {
                titleLabel.text = NSLocalizedString(@"kNote", nil);
            }
        }
    }
}

#pragma mark - Private methods
- (void)initNavigationBar
{
    UIButton *buttonCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonCancel.frame = CGRectMake(0.0f, 0.0f, 55.0f, 32.0f);
    [buttonCancel setTitle:NSLocalizedString(@"kCancel", nil) forState:UIControlStateNormal];
    buttonCancel.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    buttonCancel.titleLabel.textAlignment = NSTextAlignmentLeft;
    [buttonCancel setTitleColor:[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] forState:UIControlStateNormal];
    [buttonCancel setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [buttonCancel addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationItem addLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:buttonCancel] autorelease]];
    
    self.buttonDone = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonDone.frame = CGRectMake(0.0f, 0.0f, 55.0f, 32.0f);
    [self.buttonDone setTitle:NSLocalizedString(@"kSave", nil) forState:UIControlStateNormal];
    self.buttonDone.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    [self.buttonDone setTitleColor:[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] forState:UIControlStateNormal];
    self.buttonDone.titleLabel.textAlignment = NSTextAlignmentRight;
    [self.buttonDone setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.buttonDone setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.buttonDone addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barDone = [[[UIBarButtonItem alloc] initWithCustomView:self.buttonDone] autorelease];
    [self.navigationItem addRightBarButtonItem:barDone];
    
    if (!self.navigationItem.titleView)
    {
        CGRect titleViewFrame = CGRectMake(0.0, 0.0, 200.0, 44.0f);
        CGRect indicatorFrame = CGRectMake(180.f, 12.0f, 20.0f, 20.0f);
        CGRect titleFrame = CGRectMake(0.0f, 0.0f, 180.0f, 44.0f);
        UIFont *titleFont = [UIFont boldSystemFontOfSize:18.0f];
        if (DEVICE_iPHONE)
        {
            indicatorFrame = CGRectMake(160.f, 12.0f, 20.0f, 20.0f);
            titleFrame = CGRectMake(0.0f, 0.0f, 160.0f, 44.0f);
            titleFont = [UIFont boldSystemFontOfSize:15.0f];
        }
        UIView *titleView= [[UIView alloc] initWithFrame:titleViewFrame];
        UIActivityIndicatorView *actIndicatorView=[[UIActivityIndicatorView alloc] initWithFrame:indicatorFrame];
        actIndicatorView.tag= 1;
        [actIndicatorView setHidden:YES];
        UILabel *titleLabel= [[UILabel alloc] init];
        titleLabel.frame= titleFrame;
        titleLabel.text= self.title;
        titleLabel.textAlignment= NSTextAlignmentCenter;
        titleLabel.autoresizesSubviews= YES;
        titleLabel.backgroundColor= [UIColor clearColor];
        titleLabel.textColor= [UIColor colorWithRGBHex:0x3F3F3F];
        titleLabel.font= titleFont;
        titleLabel.tag =2;
        [titleView addSubview:titleLabel];
        [titleView addSubview:actIndicatorView];
        self.navigationItem.titleView= titleView;
        [titleView release];
        [titleLabel release];
        [actIndicatorView release];
    }
    
    if (self.navigationItem.titleView != nil)
    {
        UIView *titleView=(UIView *)self.navigationItem.titleView;
        UILabel *titleLabel= (UILabel *)[titleView viewWithTag:2];
        if (titleLabel)
        {
            titleLabel.text= NSLocalizedString(@"kNote", nil);
        }
    }
}

- (void)show:(FSAnnot*)rootAnnot replyAnnots:(NSArray*)replyAnnots;
{
    self.rootAnnot = rootAnnot;
    [self initNavigationBar];
    dispatch_async(dispatch_get_main_queue(), ^{
    self.buttonDone.enabled = NO;
    });
    
    _textViewNote.text = @"";
    [self.textViewNote becomeFirstResponder];
    
    UINavigationController *fileInfoNavCtr = [[[UINavigationController alloc] initWithRootViewController:self] autorelease];
    fileInfoNavCtr.delegate = self;
    fileInfoNavCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    fileInfoNavCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:fileInfoNavCtr animated:YES completion:^{
        
    }];
}

- (void)dismiss
{
    if ([self.textViewNote isFirstResponder]) {
       [self.textViewNote resignFirstResponder];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        self.noteEditCancel = nil;
        self.noteEditDelete = nil;
        self.noteEditDone = nil;
    }];
}

#pragma mark - event handlers

- (void)doneAction:(id)sender
{
    if (self.noteEditDone) {
        self.noteEditDone();
    }
    [self dismiss];
}

- (void)deleteAction:(id)sender
{
    if (self.noteEditDelete) {
        self.noteEditDelete();
    }
    [self dismiss];
}

- (void)cancelAction:(id)sender
{
    if (self.noteEditCancel) {
        self.noteEditCancel();
    }
    [self dismiss];
}

-(NSString *)getContent
{
    return _textViewNote.text;
}

- (void)adjustTextFrame
{
    
    if (DEVICE_iPHONE) {
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            self.textViewNote.frame = CGRectMake(0, 0, SCREENHEIGHT, SCREENWIDTH - 64);
        }else{
            self.textViewNote.frame = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT - 64);
            if ([UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].bounds.size.height ==  414 * 736) {
                self.textViewNote.frame = self.view.bounds;
            }
            
        }
    }
      if (!DEVICE_iPHONE) {
          CGRect textViewFrame = _textViewNote.frame;
          textViewFrame.origin.y = 40 + (OS_ISVERSION7 ? -40 : 0);
        textViewFrame.size.height = self.view.bounds.size.height;
        
        if ([UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeLeft||[UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeRight) {
            textViewFrame.size.height = self.view.bounds.size.height;
             _textViewNote.frame = textViewFrame;
        }
    }
   
}

-(void)scrollCaretToVisible
{
    CGRect caretRect = [self.textViewNote caretRectForPosition:self.textViewNote.selectedTextRange.end];
    if (CGRectEqualToRect(caretRect, _oldRect))
        return;
    
    _oldRect = caretRect;
    
    CGRect visibleRect = self.textViewNote.bounds;
    visibleRect.size.height -= self.textViewNote.contentInset.top + self.textViewNote.contentInset.bottom;
    visibleRect.origin.y = self.textViewNote.contentOffset.y;
    
    if (!CGRectContainsRect(visibleRect, caretRect)) {
        CGPoint newOffset = self.textViewNote.contentOffset;
        newOffset.y = MAX((caretRect.origin.y + caretRect.size.height) - visibleRect.size.height + 10, 0);
        [self.textViewNote setContentOffset:newOffset animated:YES];
    }
    
}

#pragma mark UITextViewDelegate

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    _oldRect = [self.textViewNote caretRectForPosition:self.textViewNote.selectedTextRange.end];
    _caretVisibilityTimer = [[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(scrollCaretToVisible) userInfo:nil repeats:YES] retain];
}

-(void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.buttonDone.enabled = YES;
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.buttonDone.enabled = NO;
        });
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    [_caretVisibilityTimer invalidate];
    [_caretVisibilityTimer release];
    _caretVisibilityTimer = nil;
}

#pragma mark - keyboard notification

- (void)keyboardWasShown:(NSNotification*)aNotification{
    
    NSDictionary *info = [aNotification userInfo];
    NSValue *frame = nil;
    frame = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrame = [frame CGRectValue];
    CGRect textViewFrame = _textViewNote.frame;
    
    if (DEVICE_iPHONE) {
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
              textViewFrame.size.height = [UIScreen mainScreen].bounds.size.width - keyboardFrame.size.width - 64 - 15;
            NSLog(@"%f", [UIScreen mainScreen].bounds.size.width);
              textViewFrame.size.width = [UIScreen mainScreen].bounds.size.height;
        }
        else
        {
             textViewFrame.size.height = [UIScreen mainScreen].bounds.size.height - keyboardFrame.size.height - 64 - 15;
             textViewFrame.size.width = [UIScreen mainScreen].bounds.size.width;
            if ([UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].bounds.size.height ==  414 * 736) {
                textViewFrame.size.height = self.view.frame.size.height - keyboardFrame.size.height  - 15;
                textViewFrame.size.width = self.view.frame.size.width;
            }
        }
    }
       if (!DEVICE_iPHONE) {
        CGFloat bottom = ([UIScreen mainScreen].bounds.size.height - self.view.frame.size.height)/2;
        CGFloat ySet = keyboardFrame.size.height - bottom;
        textViewFrame.size.height  = self.view.frame.size.height - ySet - 50;
        textViewFrame.size.width = self.view.frame.size.width;
        if ([UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeLeft||[UIApplication sharedApplication].statusBarOrientation ==UIInterfaceOrientationLandscapeRight) {
            textViewFrame.size.height  = self.view.frame.size.height - ySet;
        }
    }

    _textViewNote.frame = textViewFrame;
}
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    CGRect textViewFrame = _textViewNote.frame;
    if (DEVICE_iPHONE) {
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            textViewFrame.size.height = [UIScreen mainScreen].bounds.size.width - 64 ;
        }
        else
        {
            textViewFrame.size.height = [UIScreen mainScreen].bounds.size.height - 64;
        }

    }
       _difference = 45;
    if (!DEVICE_iPHONE) {
        textViewFrame.size.height = self.view.frame.size.height;
        _difference = 0;
    }
    _textViewNote.frame = textViewFrame;
    
    
}

-(void)dealloc
{
    self.textViewNote = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
