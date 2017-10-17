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

#import "ReplyTableViewController.h"
#import "AnnotationListMore.h"
#import "AnnotationListViewController.h"
#import "ColorUtility.h"
#import "FSUndo.h"
#import "Masonry/Masonry.h"
#import "UINavigationItem+IOS7PaddingAdditions.h"

@interface ReplyTableViewController () <AnnotationListCellDelegate>

@property (nonatomic, strong) NSMutableArray *rootAnnos;
@property (nonatomic, strong) NSMutableDictionary *annoStruct;
@property (nonatomic, strong) NSMutableDictionary *nodeAnnos;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@end

@implementation ReplyTableViewController {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
    FSPDFDoc *_document;
}

- (id)initWithStyle:(UITableViewStyle)style {
    assert(0);
}

- (id)initWithStyle:(UITableViewStyle)style extensionsManager:(UIExtensionsManager *)extensionsManager {
    _extensionsManager = extensionsManager;
    _pdfViewCtrl = extensionsManager.pdfViewCtrl;
    _document = _pdfViewCtrl.currentDoc;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanges:) name:UIDeviceOrientationDidChangeNotification object:nil];

    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _rootAnnos = [[NSMutableArray alloc] init];
        _annoStruct = [[NSMutableDictionary alloc] init];
        _nodeAnnos = [[NSMutableDictionary alloc] init];

        self.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                     UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
                                     UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = [[UIView alloc] init];

        if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
        }

        if (OS_ISVERSION7) {
            self.tableView.separatorInset = UIEdgeInsetsZero;
        }

        if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [self.tableView setLayoutMargins:UIEdgeInsetsMake(0, 10, 0, 0)];
        }

        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor clearColor];
        [self.tableView setTableFooterView:view];

        [self.tableView setBackgroundColor:[UIColor colorWithRGBHex:0xfffbdb]];
        //        self.tableView.superview.backgroundColor = [UIColor colorWithRGBHex:0xfffbdb];

        self.indexPath = nil;
        self.moreIndexPath = nil;
        self.isShowMore = NO;
        self.tapGesture = nil;
    }
    return self;
}

- (void)setTableViewAnnotations:(NSArray *)annotatios {
    if (annotatios.count == 0)
        return;

    NSMutableArray *itemArray = [NSMutableArray array];

    for (FSAnnot *anno in annotatios) {
        AnnotationItem *item = [[AnnotationItem alloc] init];
        item.annot = anno;
        item.currentlevelshow = NO;
        item.currentlevel = 1;

        if (item.annot.replyTo.length == 0) {
            item.isSecondLevel = YES;
            [self.rootAnnos addObject:item];
        }

        [itemArray addObject:item];
    }

    [self.annoStruct addEntriesFromDictionary:[AnnotationStruct getAnnotationStructWithAnnos:itemArray]];

    for (AnnotationItem *anno in self.rootAnnos) {
        NSMutableArray *tempArray = [NSMutableArray array];
        [tempArray addObject:anno];
        NSString *nm = [anno.annot NM];

        if (1 > nm.length)
            return;
        [self.nodeAnnos setObject:tempArray forKey:nm];

        if (self.navigationItem.titleView != nil) {
            UIView *titleView = (UIView *) self.navigationItem.titleView;
            UILabel *titleLabel = (UILabel *) [titleView viewWithTag:2];
            titleLabel.text = anno.annot.author;
        }
    }

    [self.tableView reloadData];
}

- (void)clearData {
    [_rootAnnos removeAllObjects];
    [_nodeAnnos removeAllObjects];
    [_annoStruct removeAllObjects];
}

- (void)dealloc {
    self.editingCancelHandler = nil;
    self.editingDoneHandler = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initNavigationBar];
    self.tableView.superview.backgroundColor = [UIColor colorWithRGBHex:0xfffbdb];

    [self performSelector:@selector(openFirstLevel) withObject:nil afterDelay:0.3];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void)orientationChanges:(NSNotification *)note {
    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
    if (DEVICE_iPHONE) {
        if (((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) >= (375 * 667)) && (o == UIDeviceOrientationLandscapeLeft || o == UIDeviceOrientationLandscapeRight)) {
            NSArray *arr = self.tableView.visibleCells;

            for (AnnotationListCell *cell in arr) {
                UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
                doneView.backgroundColor = [UIColor clearColor];

                UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
                edittextview.inputAccessoryView = doneView;

                self.isShowMore = NO;
                [self.tableView reloadData];
            }
        } else if (((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) >= (375 * 667)) && (o == UIDeviceOrientationPortrait || o == UIDeviceOrientationPortraitUpsideDown)) {
            NSArray *arr = self.tableView.visibleCells;

            for (AnnotationListCell *cell in arr) {
                UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
                doneView.backgroundColor = [UIColor clearColor];

                UIButton *doneBT = [UIButton buttonWithType:UIButtonTypeCustom];
                [doneBT setBackgroundImage:[UIImage imageNamed:@"common_keyboard_done"] forState:UIControlStateNormal];
                [doneBT addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
                [doneView addSubview:doneBT];

                [doneBT mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(doneView.mas_right).offset(0);
                    make.top.equalTo(doneView.mas_top).offset(0);
                    make.size.mas_equalTo(CGSizeMake(40, 40));
                }];

                UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
                edittextview.inputAccessoryView = doneView;

                self.isShowMore = NO;
                [self.tableView reloadData];
            }
        }

        [NSObject cancelPreviousPerformRequestsWithTarget:self.tableView selector:@selector(reloadData) object:nil];

        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            self.isShowMore = NO;
            [self.tableView reloadData];
        });
    }
}

- (void)openFirstLevel {
    UITableViewCell *firstcell = (UITableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    UIButton *levelbutton = (UIButton *) [firstcell.contentView viewWithTag:100];

    [levelbutton sendActionsForControlEvents:UIControlEventTouchUpInside];

    if (self.isNeedReply) {
        AnnotationListCell *cell = (AnnotationListCell *) firstcell;
        [self replyToAnnotation:cell.item];
    }
}

- (void)initNavigationBar {
    self.buttonLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    _buttonLeft.frame = CGRectMake(0.0, 0.0, 55.0, 32);
    _buttonLeft.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    [_buttonLeft setTitleColor:[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] forState:UIControlStateNormal];
    [_buttonLeft setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [_buttonLeft setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [_buttonLeft setTitle:FSLocalizedString(@"kDelete") forState:UIControlStateNormal];
    [_buttonLeft addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];

    UIButton *buttonDone = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonDone.frame = CGRectMake(0.0, 0.0, 55.0, 32);
    [buttonDone setTitle:FSLocalizedString(@"kDone") forState:UIControlStateNormal];
    buttonDone.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    [buttonDone setTitleColor:[UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1] forState:UIControlStateNormal];
    [buttonDone setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [buttonDone setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [buttonDone addTarget:self action:@selector(doneAction) forControlEvents:UIControlEventTouchUpInside];

    [self.navigationItem addLeftBarButtonItem:_buttonLeft ? [[UIBarButtonItem alloc] initWithCustomView:_buttonLeft] : nil];
    [self.navigationItem addRightBarButtonItem:buttonDone ? [[UIBarButtonItem alloc] initWithCustomView:buttonDone] : nil];

    if (!_extensionsManager.currentAnnot.canModify) {
        [self.buttonLeft setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        self.buttonLeft.alpha = 0.6;
        self.buttonLeft.userInteractionEnabled = NO;
    }

    if (!self.navigationItem.titleView) {
        CGRect titleViewFrame = CGRectMake(0.0, 0.0, 200.0, 44.0f);
        CGRect indicatorFrame = CGRectMake(180.f, 12.0f, 20.0f, 20.0f);
        CGRect titleFrame = CGRectMake(0.0f, 0.0f, 180.0f, 44.0f);
        UIFont *titleFont = [UIFont boldSystemFontOfSize:18.0f];

        if (DEVICE_iPHONE) {
            indicatorFrame = CGRectMake(160.f, 12.0f, 20.0f, 20.0f);
            titleFrame = CGRectMake(0.0f, 0.0f, 160.0f, 44.0f);
            titleFont = [UIFont boldSystemFontOfSize:15.0f];
        }

        UIActivityIndicatorView *actIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:indicatorFrame];
        actIndicatorView.tag = 1;
        [actIndicatorView setHidden:YES];

        UIView *titleView = [[UIView alloc] initWithFrame:titleViewFrame];
        [titleView addSubview:actIndicatorView];
        titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        titleView.autoresizesSubviews = YES;
        titleView.backgroundColor = [UIColor clearColor];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.frame = titleFrame;
        titleLabel.text = self.title;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = titleFont;
        titleLabel.tag = 2;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = [UIColor colorWithRGBHex:0x3F3F3F];
        titleLabel.lineBreakMode = NSLineBreakByClipping;
        titleLabel.autoresizingMask = titleView.autoresizingMask;

        CGRect leftViewbounds = self.navigationItem.leftBarButtonItem.customView.bounds;
        CGRect rightViewbounds = self.navigationItem.rightBarButtonItem.customView.bounds;
        CGFloat maxWidth = leftViewbounds.size.width > rightViewbounds.size.width ? leftViewbounds.size.width : rightViewbounds.size.width;
        maxWidth += 15;

        CGRect frame;

        frame = titleLabel.frame;
        frame.size.width = 320 - maxWidth * 2;
        titleLabel.frame = frame;

        frame = titleView.frame;
        frame.size.width = 320 - maxWidth * 2;
        titleView.frame = frame;

        // Add as the nav bar's titleview

        [titleView addSubview:titleLabel];
        self.navigationItem.titleView = titleView;
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    navigationController.navigationBar.tag = 1;
    navigationController.navigationBar.barTintColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    if (viewController == self) {
        [self viewWillAppear:NO];
    }
}

- (void)deleteAction {
    AnnotationItem *rootItem = [self.rootAnnos objectAtIndex:0];
    [self deleteAnnotation:rootItem];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self clearData];
}

- (void)doneAction {
    AnnotationListCell *cell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.indexPath];

    [self hideCellEditView];

    if (self.editAnnoItem || (_replyanno && _replyanno.isReply == YES)) {
        UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
        UILabel *labelContents = (UILabel *) [cell.contentView viewWithTag:104];

        if (self.editAnnoItem) {
            FSAnnot *annot = self.editAnnoItem.annot;
            if (![edittextview.text isEqualToString:annot.contents] && !(edittextview.text.length == 0 && annot.contents.length == 0)) {
                [self modifyAnnot:annot withContents:edittextview.text];
            }
            self.editAnnoItem = nil;
            _extensionsManager.currentAnnot = nil;
        }

        if (_replyanno && _replyanno.isReply == YES) {
            _replyanno.annot.contents = edittextview.text;
            _replyanno.isReply = NO;

            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:_replyanno.annot];
            [annotHandler addAnnot:_replyanno.annot];
        }

        edittextview.hidden = YES;
        labelContents.hidden = NO;
        [edittextview resignFirstResponder];
        cell.isInputText = NO;
    }

    [_extensionsManager setCurrentAnnot:nil];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];

    [self clearData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.rootAnnos.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section >= self.rootAnnos.count) {
        return 0;
    }
    AnnotationItem *item = [self.rootAnnos objectAtIndex:section];
    if (item.isDeleted)
        return 0;
    return [[self.nodeAnnos objectForKey:[[item annot] NM]] count];
}

- (AttachmentItem *)getAnnotationItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= self.rootAnnos.count) {
        return nil;
    }
    AnnotationItem *item = (AnnotationItem *) self.rootAnnos[indexPath.section];
    NSArray *itemArray = self.nodeAnnos[item.annot.NM];
    if (indexPath.row >= itemArray.count) {
        return nil;
    }
    return itemArray[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellidentifier = @"Cell";
    AnnotationListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidentifier];
    if (cell == nil) {
        cell = [[AnnotationListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellidentifier isMenu:YES];
        cell.backgroundColor = [UIColor clearColor];
    }

    AnnotationItem *annoItem = [self getAnnotationItemAtIndexPath:indexPath];
    if (!annoItem) {
        return cell;
    }
    cell.item = annoItem;
    cell.cellDelegate = self;

    UIImageView *annoimageView = (UIImageView *) [cell.contentView viewWithTag:99];
    annoimageView.image = [UIImage imageNamed:[AnnotationStruct annotationImageName:annoItem]];

    AnnotationButton *annolevelimageView = (AnnotationButton *) [cell.contentView viewWithTag:100];
    UILabel *labelAuthor = (UILabel *) [cell.contentView viewWithTag:102];
    UILabel *labelDate = (UILabel *) [cell.contentView viewWithTag:103];
    UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
    UIImageView *annoupdatetip = (UIImageView *) [cell.contentView viewWithTag:108];
    UIImageView *annouprepltip = (UIImageView *) [cell.contentView viewWithTag:109];

    UILabel *labelContents = (UILabel *) [cell.contentView viewWithTag:104];
    labelContents.numberOfLines = 0;
    labelContents.text = @"";

    edittextview.frame = CGRectMake(edittextview.frame.origin.x, edittextview.frame.origin.y, cell.contentView.frame.size.width, edittextview.frame.size.height);

    annoItem.currentlevelbutton = annolevelimageView;
    annoItem.annosection = indexPath.section;
    annoItem.annorow = indexPath.row;

    if (annoItem.isSecondLevel) {
        if ([[self.annoStruct objectForKey:annoItem.annot.uuidWithPageIndex] count] > 0) {
            annolevelimageView.hidden = NO;

            if (annoItem.currentlevelshow) {
                [annolevelimageView setImage:[UIImage imageNamed:@"panel_annotation_close"] forState:UIControlStateNormal];
            } else {
                [annolevelimageView setImage:[UIImage imageNamed:@"panel_annotation_open"] forState:UIControlStateNormal];
            }
        } else {
            annolevelimageView.hidden = YES;
            [annolevelimageView setImage:[UIImage imageNamed:@"panel_annotation_close"] forState:UIControlStateNormal];
        }

        if (annoItem.annot.replyTo == nil) {
            annolevelimageView.hidden = YES;
        }
    } else {
        annolevelimageView.hidden = YES;
    }

    annolevelimageView.buttonannotag = annoItem;
    annolevelimageView.currentsection = indexPath.section;
    annolevelimageView.currentrow = indexPath.row;
    [annolevelimageView addTarget:self action:@selector(getDetailReply:) forControlEvents:UIControlEventTouchUpInside];

    labelAuthor.text = annoItem.annot.author;
    if (annoItem.annot.replyTo != nil) {
        labelAuthor.text = [NSString stringWithFormat:@"%@ to %@", annoItem.annot.author ? annoItem.annot.author : @"", annoItem.replytoauthor ? annoItem.replytoauthor : @""];
    }

    labelDate.text = [Utility displayDateInYMDHM:annoItem.annot.modifiedDate];

    NSString *contents = [annoItem.annot.contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (contents == nil || contents.length == 0) {
        labelContents.hidden = YES;
    } else {
        labelContents.hidden = NO;
        labelContents.text = contents;
        CGSize contentSize = CGSizeZero;

        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetHeight(_pdfViewCtrl.bounds) - 40 : 500, 2000)];
        } else {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetWidth(_pdfViewCtrl.bounds) - 40 : 500, 2000)];
        }

        [labelContents mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(labelContents.superview.mas_top).offset(69);
            make.left.equalTo(labelContents.superview.mas_left).offset(20);
            make.right.equalTo(labelContents.superview.mas_right).offset(-20);
        }];

        [edittextview mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(edittextview.superview.mas_top).offset(69);
            make.left.equalTo(edittextview.superview.mas_left).offset(5);
            make.right.equalTo(edittextview.superview.mas_right).offset(-15);
            make.height.mas_equalTo(contentSize.height);
        }];

        if (CGRectGetWidth(_pdfViewCtrl.bounds) * CGRectGetHeight(_pdfViewCtrl.bounds) == 414 * 736) {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(414 - 40, 2000)];

            [labelContents mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(labelContents.superview.mas_top).offset(69);
                make.left.equalTo(labelContents.superview.mas_left).offset(20);
                make.width.mas_equalTo(414 - 40);
            }];
            [edittextview mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(edittextview.superview.mas_top).offset(69);
                make.left.equalTo(edittextview.superview.mas_left).offset(5);
                make.width.mas_equalTo(414 - 20);
                make.height.mas_equalTo(contentSize.height);
            }];
        }
    }

    NSString *selectedText = [annoItem.annot.selectedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ((selectedText == nil || selectedText.length == 0) && contents.length == 0) {
        labelContents.hidden = YES;
    } else if (labelContents.hidden == YES) {
        labelContents.hidden = NO;

        if (contents.length != 0) {
            labelContents.text = selectedText;
        }

        CGSize contentSize = CGSizeZero;

        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            contentSize = [Utility getTextSize:selectedText fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetHeight(_pdfViewCtrl.bounds) - 40 : 500, 2000)];
        } else {
            contentSize = [Utility getTextSize:selectedText fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetWidth(_pdfViewCtrl.bounds) - 40 : 500, 2000)];
        }

        [labelContents mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(labelContents.superview.mas_top).offset(69);
            make.left.equalTo(labelContents.superview.mas_left).offset(20);
            make.right.equalTo(labelContents.superview.mas_right).offset(-20);
        }];

        [edittextview mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(edittextview.superview.mas_top).offset(69);
            make.left.equalTo(edittextview.superview.mas_left).offset(5);
            make.right.equalTo(edittextview.superview.mas_right).offset(-15);
            make.height.mas_equalTo(contentSize.height);
        }];

        if (CGRectGetWidth(_pdfViewCtrl.bounds) * CGRectGetHeight(_pdfViewCtrl.bounds) == 414 * 736) {
            contentSize = [Utility getTextSize:selectedText fontSize:13.0 maxSize:CGSizeMake(414 - 40, 2000)];
            labelContents.numberOfLines = 0;

            [labelContents mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(labelContents.superview.mas_top).offset(69);
                make.left.equalTo(labelContents.superview.mas_left).offset(20);
                make.width.mas_equalTo(414 - 40);
            }];

            [edittextview mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(labelContents.superview.mas_top).offset(69);
                make.left.equalTo(labelContents.superview.mas_left).offset(5);
                make.width.mas_equalTo(414 - 20);
                make.height.mas_equalTo(contentSize.height);
            }];
        }
    }

    if (annolevelimageView.buttonannotag.annot.replyTo != nil) {
        annoimageView.hidden = YES;
        annoupdatetip.hidden = YES;
        annouprepltip.hidden = NO;
        CGSize contentSize = CGSizeZero;

        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetHeight(_pdfViewCtrl.bounds) - 40 : 500, 2000)];
        } else {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetWidth(_pdfViewCtrl.bounds) - 40 : 500, 2000)];
        }

        [labelContents mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(labelContents.superview.mas_top).offset(69);
            make.left.equalTo(labelContents.superview.mas_left).offset(25);
            make.right.equalTo(labelContents.superview.mas_right).offset(-10);
        }];

        [edittextview mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(edittextview.superview.mas_top).offset(69);
            make.left.equalTo(edittextview.superview.mas_left).offset(10);
            make.right.equalTo(edittextview.superview.mas_right).offset(-10);
            make.height.mas_equalTo(contentSize.height);
        }];

    } else {
        annoimageView.hidden = NO;
        [labelAuthor setTextAlignment:NSTextAlignmentLeft];
        if (annolevelimageView.buttonannotag.isShowUpdateTip) {
            annoupdatetip.hidden = NO;
        } else {
            annoupdatetip.hidden = YES;
        }
        annouprepltip.hidden = YES;
    }

    if (annolevelimageView.buttonannotag.isUpdate) {
        labelContents.textColor = [UIColor colorWithRed:252 / 255.0f green:130 / 255.0f blue:0 / 255.0f alpha:1.0];
    } else {
        [labelContents setTextColor:[UIColor darkGrayColor]];
    }

    if (cell.isInputText) {
        edittextview.hidden = NO;
        labelContents.hidden = YES;
    } else {
        edittextview.hidden = YES;
        if (((contents == nil || contents.length == 0) && ((selectedText == nil || selectedText.length == 0) && contents.length == 0))) {
            labelContents.hidden = YES;
        } else {
            labelContents.hidden = NO;
        }
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    const float cellHeight = 68;

    AnnotationItem *annotationItem = [self getAnnotationItemAtIndexPath:indexPath];
    if (!annotationItem) {
        return cellHeight;
    }

    CGSize contentSize = CGSizeZero;
    NSString *contents = nil;

    // the height of the cell should be determined based on what is currently displayed
    contents = [annotationItem.annot.contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (contents == nil || contents.length == 0) {
        if (self.indexPath.section == indexPath.section && self.indexPath.row == indexPath.row) {
            contentSize.height = 25;
        }
    } else {
        if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetHeight(_pdfViewCtrl.bounds) - 40 : 500, 2000)];
        } else {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(DEVICE_iPHONE ? CGRectGetWidth(_pdfViewCtrl.bounds) - 40 : 500, 2000)];
        }

        if (CGRectGetWidth(_pdfViewCtrl.bounds) * CGRectGetHeight(_pdfViewCtrl.bounds) == 414 * 736) {
            contentSize = [Utility getTextSize:contents fontSize:13.0 maxSize:CGSizeMake(414 - 40, 2000)];
        }

        if (contentSize.height < 25) {
            contentSize.height = 25;
        } else {
            contentSize.height += 5;
        }
    }

    return cellHeight + contentSize.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editAnnoItem || (_replyanno && _replyanno.isReply == YES)) {
        AnnotationListCell *cell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
        UILabel *labelContents = (UILabel *) [cell.contentView viewWithTag:104];

        if (self.editAnnoItem) {
            if (![edittextview.text isEqualToString:self.editAnnoItem.annot.contents] && !(edittextview.text.length == 0 && self.editAnnoItem.annot.contents.length == 0)) {
                [self modifyAnnot:self.editAnnoItem.annot withContents:edittextview.text];
            }

            self.editAnnoItem = nil;
            _extensionsManager.currentAnnot = nil;
        }

        if (_replyanno && _replyanno.isReply == YES) {
            _replyanno.annot.contents = edittextview.text;
            _replyanno.isReply = NO;

            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:_replyanno.annot];
            [annotHandler addAnnot:_replyanno.annot];
            _replyanno = nil;
        }

        edittextview.hidden = YES;
        labelContents.hidden = NO;
        [self.tableView reloadData];
        [edittextview resignFirstResponder];
        cell.isInputText = NO;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    AnnotationItem *selectanno = [[self.nodeAnnos objectForKey:[[[self.rootAnnos lastObject] annot] NM]] objectAtIndex:indexPath.row];

    if (self.replyanno && self.replyanno == selectanno) {
        return;
    }

    if (![selectanno.annot canModify]) {
        return;
    }

    selectanno.isEdited = YES;

    AnnotationListCell *selectcell = (AnnotationListCell *) [tableView cellForRowAtIndexPath:indexPath];

    self.editAnnoItem = selectcell.item;
    _extensionsManager.currentAnnot = self.editAnnoItem.annot;
    self.indexPath = indexPath;
    selectcell.isInputText = YES;

    UILabel *labelContents = (UILabel *) [selectcell.contentView viewWithTag:104];
    labelContents.hidden = YES;

    UITextView *editetextview = (UITextView *) [selectcell.contentView viewWithTag:107];
    editetextview.delegate = self;
    editetextview.hidden = NO;
    editetextview.text = labelContents.text;
    [editetextview scrollsToTop];

    [self.tableView reloadData];
    [editetextview performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.3];
}

#pragma mark <AnnotationListCellDelegate>

- (void)annotationListCellWillShowEditView:(AnnotationListCell *)cell {
    [self hideCellEditView];
}

- (void)annotationListCellDidShowEditView:(AnnotationListCell *)cell {
    self.isShowMore = YES;
    self.moreIndexPath = [self.tableView indexPathForCell:cell];
    if (!self.tapGesture) {
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self.view addGestureRecognizer:self.tapGesture];
    }
    self.tapGesture.enabled = YES;
}

- (BOOL)annotationListCellCanDelete:(AnnotationListCell *)cell {
    AnnotationItem *item = cell.item; // ?: [self getAnnotationItemAtIndexPath:indexPath];
    assert(item);
    return item.annot.canModify;
}

- (BOOL)annotationListCellCanReply:(AnnotationListCell *)cell {
    AnnotationItem *item = cell.item; // ?: [self getAnnotationItemAtIndexPath:[self.tableView indexPathForCell:cell]];
    assert(item);
    return item.annot.canReply;
}

- (void)annotationListCellDelete:(AnnotationListCell *)cell {
    [self hideCellEditView];
    [self deleteAnnotation:cell.item];
}

- (void)annotationListCellReply:(AnnotationListCell *)cell {
    [self hideCellEditView];
    [self replyToAnnotation:cell.item];
}

#pragma mark

- (void)handleTap:(UITapGestureRecognizer *)tapGesture {
    assert(self.isShowMore);
    assert(self.moreIndexPath);
    [self hideCellEditView];
}

- (void)hideCellEditView {
    if (self.isShowMore) {
        assert(self.moreIndexPath);
        AnnotationListCell *cell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.moreIndexPath];
        [cell setEditViewHidden:YES];
        self.isShowMore = NO;
        self.moreIndexPath = nil;
        self.tapGesture.enabled = NO;
    }
}

#pragma mark Spread TableView

- (void)getDetailReply:(AnnotationButton *)button {
    NSUInteger currentsection = button.currentsection;
    NSUInteger currentrow = button.currentrow;
    AnnotationItem *currentanno = button.buttonannotag;
    NSMutableArray *currentarray = [self.nodeAnnos objectForKey:[[[self.rootAnnos objectAtIndex:0] annot] NM]];
    NSMutableArray *addannoarray = [self.annoStruct objectForKey:currentanno.annot.uuidWithPageIndex];

    [addannoarray makeObjectsPerformSelector:@selector(addCurrentlevel:) withObject:[NSNumber numberWithLong:(currentanno.annot.replyTo == nil ? (currentanno.currentlevel + 1) : (currentanno.currentlevel))]];

    [addannoarray makeObjectsPerformSelector:@selector(setReplytoauthor:) withObject:currentanno.annot.author];

    [addannoarray makeObjectsPerformSelector:@selector(setcurrentlevelshow:) withObject:[NSNumber numberWithBool:NO]];

    if (currentanno.annot.replyTo == nil) {
        [addannoarray makeObjectsPerformSelector:@selector(setSecondLevel:) withObject:[NSNumber numberWithBool:YES]];
    }

    if (!currentanno.currentlevelshow) {
        currentanno.currentlevelshow = YES;

        NSUInteger insertrowindex = [currentarray indexOfObject:currentanno];

        [currentarray insertObjects:addannoarray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertrowindex + 1, addannoarray.count)]];

        NSMutableArray *arCells = [NSMutableArray array];

        for (int i = 0; i < addannoarray.count; i++) {
            currentrow = currentrow + 1;
            [arCells addObject:[NSIndexPath indexPathForRow:currentrow inSection:currentsection]];
        }

        [self.tableView insertRowsAtIndexPaths:arCells withRowAnimation:UITableViewRowAnimationTop];

        if (currentanno.annot.replyTo != nil) {
            for (AnnotationItem *sendOpen in addannoarray) {
                [sendOpen.currentlevelbutton sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
        }

        if (currentanno.isSecondLevel) {
            currentanno.currentlevelshow = YES;
            [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.2];
        }
    } else {
        NSMutableArray *deleteannos = [NSMutableArray array];

        [self getAboutAnnotatios:currentanno Annoarray:currentarray deleteArray:deleteannos];

        currentanno.currentlevelshow = NO;

        NSUInteger insertrowindex = [currentarray indexOfObject:currentanno];

        [currentarray removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertrowindex + 1, deleteannos.count)]];

        NSMutableArray *arCells = [NSMutableArray array];

        for (int i = 0; i < deleteannos.count; i++) {
            currentrow = currentrow + 1;
            [arCells addObject:[NSIndexPath indexPathForRow:currentrow inSection:currentsection]];
        }

        [self.tableView deleteRowsAtIndexPaths:arCells withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
    }
}

- (void)getAboutAnnotatios:(AnnotationItem *)searchanno Annoarray:(NSArray *)annoarray deleteArray:(NSMutableArray *)deletearray {
    NSArray *searcharray = [AnnotationStruct getAllChildNodesWithSuperAnnotation:searchanno annoStruct:self.annoStruct];

    for (AnnotationItem *annannotationo in searcharray) {
        if ([annoarray containsObject:annannotationo]) {
            [deletearray addObject:annannotationo];
        }
    }
}

- (void)showKeyBoard:(NSIndexPath *)indexpath {
    UITableViewCell *selectcell = (UITableViewCell *) [self.tableView cellForRowAtIndexPath:indexpath];
    UITextView *edittextview = (UITextView *) [selectcell.contentView viewWithTag:107];
    edittextview.text = @"";
    [edittextview becomeFirstResponder];
}

#pragma mark AddandUpdateAnnotaion

- (void)deletaAnnotatios:(NSArray *)annos {
    if (annos.count == 0) {
        return;
    }

    NSMutableSet *readydeletes = [NSMutableSet set];

    for (AnnotationItem *childanno in annos) {
        [readydeletes addObject:childanno];
        [readydeletes addObjectsFromArray:[self.annoStruct objectForKey:childanno.annot.uuidWithPageIndex]];
    }

    for (AnnotationItem *deleteanno in readydeletes) {
        [AnnotationStruct deleteAnnotationFromAnnoStruct:self.annoStruct deleteAnnotation:deleteanno rootAnnotation:[self.rootAnnos lastObject]];

        [[self.nodeAnnos objectForKey:[[[self.rootAnnos lastObject] annot] NM]] removeObject:deleteanno];

        if (_replyanno == deleteanno)
            _replyanno = nil;
    }

    if (self.nodeAnnos.count == 0) {
        [self.rootAnnos removeAllObjects];
    }

    [self.tableView reloadData];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.editAnnoItem) {
        [self modifyAnnot:self.editAnnoItem.annot withContents:textView.text];
        self.editAnnoItem = nil;
        _extensionsManager.currentAnnot = nil;
    }

    if (_replyanno && _replyanno.isReply) {
        _replyanno.annot.contents = textView.text;
        _replyanno.isReply = NO;

        id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:_replyanno.annot];
        [annotHandler addAnnot:_replyanno.annot];

        _replyanno = nil;
    }

    AnnotationListCell *selectcell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.indexPath];
    selectcell.isInputText = NO;

    UITextView *edittextview = (UITextView *) [selectcell.contentView viewWithTag:107];
    edittextview.hidden = YES;

    UILabel *labelContents = (UILabel *) [selectcell.contentView viewWithTag:104];
    labelContents.text = edittextview.text;
    labelContents.hidden = NO;

    [textView resignFirstResponder];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation));
}

- (void)deleteAnnotation:(AnnotationItem *)item {
    if (item.isDeleted) {
        return;
    }

    // restore to original contents if annot being edited
    {
        AnnotationListCell *cell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
        if (edittextview.isFirstResponder) {
            edittextview.text = item.annot.contents;
        }
    }

    AnnotationItem *replytoannotation = item;

    NSMutableArray *deletearray = [NSMutableArray arrayWithObject:replytoannotation];

    [deletearray addObjectsFromArray:[AnnotationStruct getAllChildNodesWithSuperAnnotation:replytoannotation annoStruct:self.annoStruct]];

    [self deletaAnnotatios:deletearray];

    id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:replytoannotation.annot];
    [annotHandler removeAnnot:replytoannotation.annot];

    if (_extensionsManager.currentAnnot) {
        [_extensionsManager setCurrentAnnot:nil];
    }

    item.isDeleted = YES;
}

- (void)replyToAnnotation:(AnnotationItem *)item {
    if (self.editAnnoItem || (_replyanno && _replyanno.isReply == YES)) {
        AnnotationListCell *cell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:self.indexPath];
        UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
        UILabel *labelContents = (UILabel *) [cell.contentView viewWithTag:104];

        if (self.editAnnoItem) {
            [self modifyAnnot:self.editAnnoItem.annot withContents:edittextview.text];
            self.editAnnoItem = nil;
            _extensionsManager.currentAnnot = nil;
        }

        if (_replyanno && _replyanno.isReply == YES) {
            _replyanno.annot.contents = edittextview.text;
            _replyanno.isReply = NO;

            id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:_replyanno.annot];
            [annotHandler addAnnot:_replyanno.annot];

            _replyanno = nil;
        }

        edittextview.hidden = YES;
        labelContents.hidden = NO;

        [edittextview resignFirstResponder];
        [self.tableView reloadData];

        cell.isInputText = NO;
    }

    AnnotationItem *replytoannotation = item;
    NSUInteger currentsection = 0;

    NSMutableArray *currentarray = [self.nodeAnnos objectForKey:[[[self.rootAnnos objectAtIndex:0] annot] NM]];

    if (replytoannotation.currentlevelshow == NO) {
        [replytoannotation.currentlevelbutton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }

    self.pageIndex = replytoannotation.annot.pageIndex;
    self.replyanno = [[AnnotationItem alloc] init];

    FSPDFPage *page = [_document getPage:(int) self.pageIndex];
    if (!page)
        return;

    NSDate *now = [NSDate date];
    _replyanno.annot = [(FSMarkup *) replytoannotation.annot addReply];
    _replyanno.annot.fsrect = replytoannotation.annot.fsrect;
    _replyanno.annot.NM = [Utility getUUID];
    _replyanno.annot.author = [SettingPreference getAnnotationAuthor];
    _replyanno.annot.contents = @"";
    _replyanno.annot.color = 0;
    _replyanno.annot.opacity = 1;
    _replyanno.annot.lineWidth = 2;
    _replyanno.annot.icon = 0;
    _replyanno.isReply = YES;
    _replyanno.annot.modifiedDate = now;
    _replyanno.annot.createDate = now;
    _replyanno.rootannotation = replytoannotation.rootannotation;

    if (replytoannotation.annot.replyTo == nil) {
        _replyanno.isSecondLevel = YES;
    } else {
        _replyanno.isSecondLevel = NO;
    }

    [AnnotationStruct insertAnnotationToAnnoStruct:self.annoStruct insertAnnotation:_replyanno SuperAnnotation:replytoannotation];

    NSMutableArray *addannoarray = [NSMutableArray arrayWithObject:_replyanno];

    [addannoarray makeObjectsPerformSelector:@selector(addCurrentlevel:) withObject:[NSNumber numberWithLong:(replytoannotation.annot.replyTo == nil ? (replytoannotation.currentlevel + 1) : (replytoannotation.currentlevel))]];

    [addannoarray makeObjectsPerformSelector:@selector(setReplytoauthor:) withObject:replytoannotation.annot.author];

    NSUInteger insertrowindex = [currentarray indexOfObject:replytoannotation];

    NSMutableArray *arCells = [NSMutableArray array];

    if (replytoannotation.annot.replyTo == nil) {
        [currentarray insertObjects:addannoarray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange((insertrowindex + [[self.nodeAnnos objectForKey:[[[self.rootAnnos lastObject] annot] NM]] count]), addannoarray.count)]];

        [arCells addObject:[NSIndexPath indexPathForRow:(insertrowindex + [[self.nodeAnnos objectForKey:[[[self.rootAnnos lastObject] annot] NM]] count] - 1) inSection:currentsection]];
    } else {
        [currentarray insertObjects:addannoarray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertrowindex + [[self.annoStruct objectForKey:replytoannotation.annot.uuidWithPageIndex] count], addannoarray.count)]];

        [arCells addObject:[NSIndexPath indexPathForRow:insertrowindex + [[self.annoStruct objectForKey:replytoannotation.annot.uuidWithPageIndex] count] inSection:currentsection]];
    }

    self.indexPath = [arCells lastObject];

    [self.tableView insertRowsAtIndexPaths:arCells withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView scrollToRowAtIndexPath:self.indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];

    double delayInSeconds = 0.3;
    //after scrollToRowAtIndexPath, To determine the current cell
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        AnnotationListCell *selectcell = (AnnotationListCell *) [self.tableView cellForRowAtIndexPath:[arCells lastObject]];

        selectcell.isInputText = YES;

        UILabel *labelContents = (UILabel *) [selectcell.contentView viewWithTag:104];
        labelContents.hidden = YES;

        UITextView *edittextview = (UITextView *) [selectcell.contentView viewWithTag:107];
        edittextview.delegate = self;
        edittextview.hidden = NO;
        edittextview.text = labelContents.text;

        [edittextview becomeFirstResponder];
    });

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });

    dispatch_async(dispatch_get_main_queue(), ^{
        [_extensionsManager onAnnotAdded:page annot:_replyanno.annot];
    });
}

- (void)dismissKeyboard {
    NSArray *arr = self.tableView.visibleCells;

    for (AnnotationListCell *cell in arr) {
        UITextView *edittextview = (UITextView *) [cell.contentView viewWithTag:107];
        if (edittextview.isFirstResponder) {
            [edittextview resignFirstResponder];
        }
    }
}

- (void)keyboardDidShow:(NSNotification *)note {
    [self.tableView scrollToRowAtIndexPath:self.indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)modifyAnnot:(FSAnnot *)annot withContents:(NSString *)contents {
    annot.contents = contents;
}

@end
