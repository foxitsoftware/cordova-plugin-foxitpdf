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

#import "SearchModule.h"
#import "ColorUtility.h"
#import "Const.h"
#import "Masonry.h"
#import "RTLabel.h"
#import "SearchResult.h"
#import "SearchViewController.h"
#import "StringDrawUtil.h"
#import "TaskServer.h"
#import "TbBaseBar.h"
#import "UIExtensionsManager+Private.h"
#import "UIExtensionsManager.h"
#import "Utility.h"
#import <FoxitRDK/FSPDFObjC.h>
#import <QuartzCore/QuartzCore.h>

#define STYLE_CELL_WIDTH (OS_ISVERSION7 ? 300 : 280)
#define STYLE_PAGE_SUMMARY_HEIGHT 25
#define STYLE_PAGE_SUMMARY_LEFT 15
#define STYLE_PAGE_SUMMARY_TOP 6
#define STYLE_PAGE_SUMMARY_WIDTH 200
#define STYLE_PAGE_SUMMARY_WIDTH_IPHONE 260
#define STYLE_PAGE_SUMMARY_LABEL_HEIGHT (STYLE_PAGE_SUMMARY_HEIGHT - 2 * STYLE_PAGE_SUMMARY_TOP)
#define STYLE_PAGE_SUMMARY_RIGHT_LEFT (OS_ISVERSION7 ? 107 : 90)
#define STYLE_PAGE_SUMMARY_RIGHT_LEFT_IPHONE 47
#define STYLE_PAGE_SUMMARY_FONT [UIFont boldSystemFontOfSize:18.0]
#define STYLE_INFO_LEFT 15
#define STYLE_INFO_TOP 5
#define STYLE_INFO_FONT [UIFont systemFontOfSize:13.0]

#define SEARCH_BAR_TEXT [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] //remove prefixed and suffixed whitespace

static SearchResult *searchPage(FSPDFTextSearch *fstextSearch, FSPDFPage *page, NSString *keyword, StringDrawUtil *util, float width, TaskServer *taskServer);

@interface SearchModule ()

@property (nonatomic, weak) FSPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, weak) UIExtensionsManager *extensionsManager;

@property (nonatomic, strong) TbBaseBar *topBar;
@property (nonatomic, strong) TbBaseItem *filterItem;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) TbBaseItem *cancelItem;

@property (nonatomic, strong) TbBaseBar *bottomBar;
@property (nonatomic, strong) TbBaseItem *previousItem;
@property (nonatomic, strong) TbBaseItem *nextItem;
@property (nonatomic, strong) TbBaseItem *showListItem;

@property (nonatomic, strong) UIControl *maskView;
@property (nonatomic, strong) UILabel *foundLable;
@property (nonatomic, strong) UIView *totalView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, assign) BOOL topbarHidden;
@property (nonatomic, assign) BOOL bottomBarHidden;
@property (nonatomic, assign) BOOL tableviewHidden;
@property (nonatomic, assign) BOOL foundLabelHidden;

@property (nonatomic, strong) NSMutableArray *arraySearch;

@property (nonatomic, strong) UIPopoverController *searchbyPopoverCtrl;

@property (nonatomic, strong) NSOperationQueue *searchOPQueue;

@property (nonatomic, strong) NSArray *needDrawRects;
@property (nonatomic, assign) int needPageIndex;
@property (nonatomic, assign) CGRect cleanDrawRect;
@property (nonatomic, assign) int cleanPageIndex;

@property (nonatomic, strong) SearchInfo *selectedSearchInfo;
@property (nonatomic, strong) SearchResult *selectedSearchResult;
@property (nonatomic, assign) BOOL isKeyboardShowing;

@property (nonatomic, assign) BOOL onSearchState;
@end

@implementation SearchModule {
}

- (NSString *)getName {
    return @"Search";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _extensionsManager = extensionsManager;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotate) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    }

    if ([UIBarButtonItem respondsToSelector:@selector(appearanceWhenContainedIn:)]) {
        if (OS_ISVERSION7) {
            [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor whiteColor]];
        } else {
            [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor lightGrayColor]];
        }
    }
    [self loadModule];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadModule {
    [_pdfViewCtrl registerDrawEventListener:self];
    [_pdfViewCtrl registerScrollViewEventListener:self];
    [_pdfViewCtrl registerGestureEventListener:self];
    [_pdfViewCtrl registerDocEventListener:self];

    self.arraySearch = [NSMutableArray array];
    self.searchOPQueue = [[NSOperationQueue alloc] init];
    _selectedSearchInfo = nil;
    _selectedSearchResult = nil;

    self.maskView = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_pdfViewCtrl.bounds), CGRectGetHeight(_pdfViewCtrl.bounds))];
    self.maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;

    self.topBar = [[TbBaseBar alloc] init];
    self.topBar.contentView.frame = CGRectMake(0, -64, CGRectGetWidth(_pdfViewCtrl.bounds), 64);
    self.topBar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    self.topBar.top = YES;
    [_pdfViewCtrl addSubview:self.topBar.contentView];
    [self.topBar.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBar.contentView.superview.mas_top).offset(-64);
        make.left.equalTo(self.topBar.contentView.superview.mas_left).offset(0);
        make.right.equalTo(self.topBar.contentView.superview.mas_right).offset(0);
        make.height.mas_equalTo(64);
    }];

    __weak typeof(self) weakSelf = self;
    self.filterItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"search_filter"] imageSelected:[UIImage imageNamed:@"search_filter"] imageDisable:[UIImage imageNamed:@"search_filter"]];
    self.filterItem.onTapClick = ^(TbBaseItem *item) {
        if (weakSelf.searchbyPopoverCtrl.isPopoverVisible) {
            [weakSelf.searchbyPopoverCtrl dismissPopoverAnimated:YES];
        } else {
            CGRect rect = [weakSelf.filterItem.contentView convertRect:weakSelf.filterItem.contentView.bounds toView:weakSelf.pdfViewCtrl];
            [weakSelf.searchbyPopoverCtrl presentPopoverFromRect:rect inView:weakSelf.pdfViewCtrl permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        }
    };
    if (!DEVICE_iPHONE) {
        [self.topBar addItem:self.filterItem displayPosition:Position_LT];
    }

    self.cancelItem = [TbBaseItem createItemWithTitle:FSLocalizedString(@"kCancel")];
    self.cancelItem.textColor = [UIColor colorWithRed:0.15 green:0.62 blue:0.84 alpha:1];
    self.cancelItem.textFont = [UIFont systemFontOfSize:15.0f];
    [self.topBar addItem:self.cancelItem displayPosition:Position_RB];
    self.cancelItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf cancelSearch];
    };

    CGSize cancelSize = [Utility getTextSize:FSLocalizedString(@"kCancel") fontSize:15.0f maxSize:CGSizeMake(200, 100)];

    CGRect searchFrame;
    if (DEVICE_iPHONE) {
        searchFrame = CGRectMake(10, 25, CGRectGetWidth(_pdfViewCtrl.bounds) - cancelSize.width - 5 - 25, 30);
    } else {
        searchFrame = CGRectMake(46, 25, CGRectGetWidth(_pdfViewCtrl.bounds) - cancelSize.width - 5 - 65, 30);
    }

    self.searchBar = [[UISearchBar alloc] initWithFrame:searchFrame];
    self.searchBar.placeholder = @"Head and tail whitespace trimed!";

    [self.topBar.contentView addSubview:self.searchBar];
    if (DEVICE_iPHONE) {
        [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topBar.contentView.mas_top).offset(25);
            make.left.equalTo(self.topBar.contentView.mas_left).offset(10);
            make.right.equalTo(self.topBar.contentView.mas_right).offset(-(cancelSize.width + 5 + 15));
            make.height.mas_equalTo(30);
        }];
    } else {
        [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topBar.contentView.mas_top).offset(25);
            make.left.equalTo(self.topBar.contentView.mas_left).offset(46);
            make.right.equalTo(self.topBar.contentView.mas_right).offset(-(cancelSize.width + 5 + 19));
            make.height.mas_equalTo(30);
        }];
    }

    self.searchBar.delegate = self;
    if ([self.searchBar respondsToSelector:@selector(barTintColor)]) {
        UIImage *image = [UIImage imageNamed:@"search_edit_bg"];
        UIEdgeInsets insets = UIEdgeInsetsMake(10, 15, 10, 15);
        image = [image resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        self.searchBar.backgroundImage = image;
    } else {
        [[self.searchBar.subviews objectAtIndex:0] removeFromSuperview];
        [self.searchBar setBackgroundColor:[UIColor clearColor]];
    }

    self.bottomBar = [[TbBaseBar alloc] init];
    self.bottomBar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];
    self.bottomBar.top = NO;
    self.bottomBar.contentView.frame = CGRectMake(0, CGRectGetHeight(_pdfViewCtrl.bounds), CGRectGetWidth(_pdfViewCtrl.bounds), 49);
    if (DEVICE_iPHONE) {
        self.bottomBar.intervalWidth = 50;
    } else {
        self.bottomBar.intervalWidth = 100;
    }
    [_pdfViewCtrl addSubview:self.bottomBar.contentView];
    [self.bottomBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(@49);
        make.right.equalTo(self.bottomBar.contentView.superview.mas_right).offset(0);
        make.left.equalTo(self.bottomBar.contentView.superview.mas_left).offset(0);
        make.top.equalTo(self.bottomBar.contentView.superview.mas_bottom).offset(0);
    }];

    self.previousItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"search_previous"] imageSelected:[UIImage imageNamed:@"search_previous"] imageDisable:[UIImage imageNamed:@"search_previous_disable"]];
    self.previousItem.tag = 0;
    [self.bottomBar addItem:self.previousItem displayPosition:Position_CENTER];
    self.previousItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf previousKeyLocation];
    };

    self.showListItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"search_showlist"] imageSelected:[UIImage imageNamed:@"search_showlist_selected"] imageDisable:[UIImage imageNamed:@"search_showlist_disable"]];
    self.showListItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf setTableViewHidden:NO];
        [weakSelf setfoundLabelHidden:NO];
        [weakSelf setBottombarHidden:YES];
    };
    [self.bottomBar addItem:self.showListItem displayPosition:Position_CENTER];

    self.nextItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"search_next"] imageSelected:[UIImage imageNamed:@"search_next"] imageDisable:[UIImage imageNamed:@"search_next_disable"]];
    [self.bottomBar addItem:self.nextItem displayPosition:Position_CENTER];
    self.nextItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf nextKeyLocation];
    };

    self.foundLable = [[UILabel alloc] initWithFrame:CGRectMake(STYLE_PAGE_SUMMARY_LEFT, 0, 300, 30)];
    self.foundLable.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    self.foundLable.backgroundColor = [UIColor whiteColor];
    self.foundLable.textColor = [UIColor blackColor];
    self.foundLable.font = [UIFont systemFontOfSize:12.0f];
    self.foundLable.textAlignment = NSTextAlignmentLeft;

    self.totalView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, 300, 30)];
    self.totalView.backgroundColor = [UIColor whiteColor];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(CGRectGetWidth(_pdfViewCtrl.bounds) - 300, 94, 300, CGRectGetHeight(_pdfViewCtrl.bounds) - 94) style:UITableViewStylePlain];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
    }

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [_pdfViewCtrl addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tableView.superview.mas_top).offset(94);
        make.bottom.equalTo(self.tableView.superview.mas_bottom).offset(0);
        make.left.equalTo(self.tableView.superview.mas_right).offset(0);
        make.width.mas_equalTo(@300);
    }];
    [_pdfViewCtrl addSubview:self.totalView];
    [self.totalView addSubview:self.foundLable];
    [self.totalView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.totalView.superview.mas_top).offset(64);
        make.height.mas_equalTo(@30);
        make.left.equalTo(self.totalView.superview.mas_right).offset(0);
        make.width.mas_equalTo(@300);
    }];

    self.topbarHidden = YES;
    self.bottomBarHidden = YES;
    self.tableviewHidden = YES;
    self.foundLabelHidden = YES;

    //search button.
    UIButton *searchButton = [Utility createButtonWithImage:[UIImage imageNamed:@"search.png"]];
    searchButton.tag = FS_TOPBAR_ITEM_SEARCH_TAG;
    [searchButton addTarget:self action:@selector(onClickSearchButton:) forControlEvents:UIControlEventTouchUpInside];
    _extensionsManager.topToolbar.items = ({
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:searchButton];
        item.tag = FS_TOPBAR_ITEM_SEARCH_TAG;
        NSMutableArray *items = (_extensionsManager.topToolbar.items ?: @[]).mutableCopy;
        [items addObject:item];
        items;
    });
}

- (void)unload {
}

- (void)onClickSearchButton:(UIButton *)button {
    if (self.extensionsManager.currentAnnot) {
        [self.extensionsManager setCurrentAnnot:nil];
    }
    [self.extensionsManager showSearchBar:YES];
}

- (void)willRotate {
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
}

- (UIPopoverController *)searchbyPopoverCtrl {
    if (_searchbyPopoverCtrl == nil) {
        SearchbyViewController *searchByCtr = [[SearchbyViewController alloc] initWithStyle:UITableViewStylePlain];
        searchByCtr.searchbyClickedHandler = ^(int type) {
            if (type == 1) {
                [self buttonSearchGoogleClick:nil];
            } else if (type == 2) {
                [self buttonSearchWikiClick:nil];
            }
        };
        UINavigationController *searchByNavCtrl = [[UINavigationController alloc] initWithRootViewController:searchByCtr];
        searchByNavCtrl.navigationBarHidden = YES;
        UIPopoverController *searchByPopoverCtrl = [[UIPopoverController alloc] initWithContentViewController:searchByNavCtrl];
        searchByPopoverCtrl.popoverContentSize = CGSizeMake(250, 86);
        self.searchbyPopoverCtrl = searchByPopoverCtrl;
    }
    return _searchbyPopoverCtrl;
}

- (void)showSearchBar:(BOOL)show {
    if (show) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasHidden:) name:UIKeyboardWillHideNotification object:nil];

        [self setTopbarHidden:NO];
        [self.searchBar becomeFirstResponder];
        self.onSearchState = YES;

        [_extensionsManager onSearchStarted];
    } else {
        [self setTopbarHidden:YES];
        [self.searchBar resignFirstResponder];
        [self setBottombarHidden:YES];
        [self setTableViewHidden:YES];
        [self setfoundLabelHidden:YES];
        self.onSearchState = NO;

        [_extensionsManager onSearchCanceled];
    }
}

- (void)setTopbarHidden:(BOOL)hidden {
    if (_topbarHidden == hidden) {
        return;
    }
    _topbarHidden = hidden;

    if (hidden) {
        CGRect newFrame = self.topBar.contentView.frame;
        newFrame.origin.y = -self.topBar.contentView.frame.size.height;
        [UIView animateWithDuration:0.3
                         animations:^{

                             self.topBar.contentView.frame = newFrame;
                             [self.topBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.top.equalTo(self.topBar.contentView.superview.mas_top).offset(-64);
                                 make.left.equalTo(self.topBar.contentView.superview.mas_left).offset(0);
                                 make.right.equalTo(self.topBar.contentView.superview.mas_right).offset(0);
                                 make.height.mas_equalTo(64);
                             }];

                         }
                         completion:^(BOOL finished){
                         }];
    } else {
        CGRect newFrame = self.topBar.contentView.frame;
        newFrame.origin.y = 0;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.topBar.contentView.frame = newFrame;
                             [self.topBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.top.equalTo(self.topBar.contentView.superview.mas_top).offset(0);
                                 make.left.equalTo(self.topBar.contentView.superview.mas_left).offset(0);
                                 make.right.equalTo(self.topBar.contentView.superview.mas_right).offset(0);
                                 make.height.mas_equalTo(64);
                             }];
                         }
                         completion:^(BOOL finished){

                         }];
    }
}

- (void)setBottombarHidden:(BOOL)hidden {
    if (_bottomBarHidden == hidden) {
        return;
    }
    _bottomBarHidden = hidden;
    if (hidden) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self.bottomBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.height.mas_equalTo(@49);
                                 make.right.equalTo(self.bottomBar.contentView.superview.mas_right).offset(0);
                                 make.left.equalTo(self.bottomBar.contentView.superview.mas_left).offset(0);
                                 make.top.equalTo(self.bottomBar.contentView.superview.mas_bottom).offset(0);
                             }];
                             [self.bottomBar.contentView layoutIfNeeded];
                         }];
    } else {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self.bottomBar.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.height.mas_equalTo(@49);
                                 make.right.equalTo(self.bottomBar.contentView.superview.mas_right).offset(0);
                                 make.left.equalTo(self.bottomBar.contentView.superview.mas_left).offset(0);
                                 make.bottom.equalTo(self.bottomBar.contentView.superview.mas_bottom).offset(0);
                             }];
                             [self.bottomBar.contentView layoutIfNeeded];
                         }];
    }
}

- (void)setfoundLabelHidden:(BOOL)foundLabelHidden {
    if (_foundLabelHidden == foundLabelHidden) {
        return;
    }
    _foundLabelHidden = foundLabelHidden;
    if (foundLabelHidden) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self.totalView mas_updateConstraints:^(MASConstraintMaker *make) {
                                 make.left.equalTo(self.totalView.superview.mas_right).offset(0);
                             }];
                             [self.totalView layoutIfNeeded];
                         }];
    } else {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self.totalView mas_updateConstraints:^(MASConstraintMaker *make) {
                                 make.left.equalTo(self.totalView.superview.mas_right).offset(-300);
                             }];
                             [self.totalView layoutIfNeeded];
                         }];
    }
}

- (void)setTableViewHidden:(BOOL)hidden {
    if (_tableviewHidden == hidden) {
        return;
    }
    _tableviewHidden = hidden;
    if (hidden) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
                                 make.left.equalTo(self.tableView.superview.mas_right).offset(0);
                             }];
                             [self.tableView layoutIfNeeded];
                         }];

        [UIView animateWithDuration:0.4
            animations:^{
                self.maskView.alpha = 0.1f;
            }
            completion:^(BOOL finished) {

                [self.maskView removeFromSuperview];
            }];
    } else {
        self.maskView.backgroundColor = [UIColor blackColor];
        self.maskView.alpha = 0.3f;
        self.maskView.tag = 300;
        [self.maskView addTarget:self action:@selector(dissmiss:) forControlEvents:UIControlEventTouchUpInside];
        [_pdfViewCtrl insertSubview:self.maskView belowSubview:self.topBar.contentView];
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
                                 make.left.equalTo(self.tableView.superview.mas_right).offset(-300);
                             }];
                             [self.tableView layoutIfNeeded];
                         }];
    }
}

- (void)dissmiss:(id)sender {
    UIControl *control = (UIControl *) sender;
    if (control.tag == 300) {
        [self setTableViewHidden:YES];
        [self setfoundLabelHidden:YES];
        [self setBottombarHidden:NO];
    }
}

- (void)buttonSearchGoogleClick:(id)sender {
    [self.searchbyPopoverCtrl dismissPopoverAnimated:YES];
    NSString *keyword = SEARCH_BAR_TEXT;
    NSString *url;
    if (keyword.length > 0) {
        url = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", [keyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    } else {
        url = @"http://www.google.com";
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)buttonSearchWikiClick:(id)sender {
    [self.searchbyPopoverCtrl dismissPopoverAnimated:YES];
    NSString *keyword = SEARCH_BAR_TEXT;
    NSString *url;
    if (keyword.length > 0) {
        url = [NSString stringWithFormat:@"http://www.wikipedia.org/wiki/%@", [keyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    } else {
        url = @"http://www.wikipedia.org";
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)previousKeyLocation {
    if (_selectedSearchResult == nil) {
        if (self.arraySearch.count == 0) {
            return;
        } else {
            self.selectedSearchResult = [self.arraySearch objectAtIndex:0];
        }
    }
    if (_selectedSearchInfo == nil) {
        self.selectedSearchInfo = [self.selectedSearchResult.infos objectAtIndex:self.selectedSearchResult.infos.count - 1];
        [self gotoPage:self.selectedSearchResult.index rects:self.selectedSearchInfo.rects];
    } else {
        NSUInteger infoIndex = [self.selectedSearchResult.infos indexOfObject:self.selectedSearchInfo];
        if (infoIndex == 0) {
            if (self.arraySearch.count < 1)
                return;
            NSUInteger resultIndex = [self.arraySearch indexOfObject:self.selectedSearchResult];
            if (resultIndex == 0) {
                self.selectedSearchResult = [self.arraySearch lastObject];
            } else {
                self.selectedSearchResult = [self.arraySearch objectAtIndex:resultIndex - 1];
            }
            self.selectedSearchInfo = [self.selectedSearchResult.infos lastObject];
        } else {
            self.selectedSearchInfo = [self.selectedSearchResult.infos objectAtIndex:infoIndex - 1];
        }
        [self gotoPage:self.selectedSearchResult.index rects:self.selectedSearchInfo.rects];
    }
}

- (void)nextKeyLocation {
    if (_selectedSearchResult == nil) {
        if (self.arraySearch.count != 0) {
            self.selectedSearchResult = [self.arraySearch objectAtIndex:0];
        } else {
            return;
        }
    }

    if (_selectedSearchInfo == nil) {
        self.selectedSearchInfo = [self.selectedSearchResult.infos objectAtIndex:0];
        [self gotoPage:_selectedSearchResult.index rects:self.selectedSearchInfo.rects];
    } else {
        NSUInteger infoIndex = [self.selectedSearchResult.infos indexOfObject:self.selectedSearchInfo];
        if (infoIndex == self.selectedSearchResult.infos.count - 1) {
            if (self.arraySearch.count < 1)
                return;
            NSUInteger resultIndex = [self.arraySearch indexOfObject:self.selectedSearchResult];
            if (resultIndex == self.arraySearch.count - 1) {
                self.selectedSearchResult = [self.arraySearch objectAtIndex:0];
            } else {
                self.selectedSearchResult = [self.arraySearch objectAtIndex:resultIndex + 1];
            }
            self.selectedSearchInfo = [self.selectedSearchResult.infos objectAtIndex:0];
        } else {
            self.selectedSearchInfo = [self.selectedSearchResult.infos objectAtIndex:infoIndex + 1];
        }
        [self gotoPage:self.selectedSearchResult.index rects:self.selectedSearchInfo.rects];
    }
}

- (void)gotoPage:(int)index rects:(NSArray *)rects {
    if ([self gotoPage:index animated:YES]) {
        if (rects && rects.count > 0) {
            self.needDrawRects = rects;
            CGRect firstNeedDrawRect = [[rects objectAtIndex:0] CGRectValue];
            CGRect unionNeedDrawRect = CGRectZero;
            for (id obj in rects) {
                CGRect rect = [obj CGRectValue];
                unionNeedDrawRect = CGRectUnion(unionNeedDrawRect, rect);
            }
            self.needPageIndex = index;
            if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_CONTINUOUS) {
                FSPointF *point = [[FSPointF alloc] init];
                [point set:CGRectGetMidX(firstNeedDrawRect) - 80 y:CGRectGetMidY(firstNeedDrawRect) + 150];
                [_pdfViewCtrl gotoPage:index withDocPoint:point animated:YES];
            } else {
                FSPointF *point = [[FSPointF alloc] init];
                [point set:CGRectGetMidX(firstNeedDrawRect) y:CGRectGetMidY(firstNeedDrawRect)];

                UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
                if (DEVICE_iPHONE && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
                    //Avoid the search highlight to be sheltered from top bar. To do, need to check page rotation.
                    [point setY:[point getY] + 64];
                }

                [_pdfViewCtrl gotoPage:index withDocPoint:point animated:YES];
            }

            FSRectF *docRectIva = [Utility CGRect2FSRectF:unionNeedDrawRect];
            FSRectF *oldRectIva = [Utility CGRect2FSRectF:self.cleanDrawRect];
            CGRect pvRectIna = [_pdfViewCtrl convertPdfRectToPageViewRect:docRectIva pageIndex:self.needPageIndex];
            CGRect oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:oldRectIva pageIndex:self.cleanPageIndex];
            [_pdfViewCtrl refresh:pvRectIna pageIndex:self.needPageIndex];
            [_pdfViewCtrl refresh:oldRect pageIndex:self.cleanPageIndex];
            self.cleanDrawRect = unionNeedDrawRect;
            self.cleanPageIndex = index;
            [self setTableViewHidden:YES];
            [self setfoundLabelHidden:YES];
            [self setBottombarHidden:NO];
        }
    }
}

- (BOOL)gotoPage:(int)index animated:(BOOL)animated {
    if (index >= 0 && index < [_pdfViewCtrl.currentDoc getPageCount]) {
        [_pdfViewCtrl gotoPage:index animated:animated];
        return YES;
    }
    return NO;
}

- (void)clearSearch {
    [self.searchBar setText:nil];
    [self.arraySearch removeAllObjects];
    [self.searchOPQueue cancelAllOperations];
    self.needDrawRects = nil;
}

- (void)cancelSearch {
    [self showSearchBar:NO];
    [self clearSearch];

    FSRectF *oldRectIva = [Utility CGRect2FSRectF:self.cleanDrawRect];
    CGRect oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:oldRectIva pageIndex:self.cleanPageIndex];
    [_pdfViewCtrl refresh:oldRect pageIndex:self.cleanPageIndex];

    [self.searchBar resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    //If there is still in searching, wait for finishing.
    Task *task = [[Task alloc] init];
    task.run = ^() {

    };
    [self.extensionsManager.taskServer executeSync:task];
}

- (void)searchTextInPDF:(NSString *)str currentPage:(NSArray *)pages {
    [self.searchOPQueue cancelAllOperations];
    if (str.length == 0 || str == nil) {
        return;
    }
    if (pages == nil || pages.count == 0) {
        return;
    }

    [self setTableViewHidden:NO];
    [self setfoundLabelHidden:NO];
    __block NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self searchStart];
        });

        FSPDFTextSearch *fstextSearch = [[FSPDFTextSearch alloc] initWithPDFDoc:_pdfViewCtrl.currentDoc pause:nil];
        [fstextSearch setFlag:e_searchNormal];
        [fstextSearch setKeyWords:str];

        for (int i = 0; i < pages.count; i++) {
            if (op.isCancelled) {
                break;
            }
            int page = [[pages objectAtIndex:i] intValue];
            @autoreleasepool {
                StringDrawUtil *util = [[StringDrawUtil alloc] initWithFont:STYLE_INFO_FONT];
                SearchResult *ret = searchPage(fstextSearch, [_pdfViewCtrl.currentDoc getPage:page], str, util, 300, self.extensionsManager.taskServer);
                if (ret.infos.count > 0) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self searchFound:ret];
                    });
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self searchOnePageProcessed];
                });
            }
            [NSThread sleepForTimeInterval:.001];
        }
        if (self.arraySearch.count == 0) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.foundLable.text = [NSString stringWithFormat:@"%@  %d", FSLocalizedString(@"kTotalFound"), 0];
                [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
                [self.tableView reloadData];
                self.previousItem.enable = NO;
                self.nextItem.enable = NO;
            });
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self searchStoped];
        });
    }];
    [self.searchOPQueue addOperation:op];
}

- (void)searchOnePageProcessed {
}

- (void)searchStart {
}

- (void)searchStoped {
}

- (void)searchFound:(SearchResult *)result {
    [self.arraySearch addObject:result];
    int totalCount = 0;
    for (SearchResult *result in self.arraySearch) {
        totalCount += result.infos.count;
    }
    self.foundLable.text = [NSString stringWithFormat:@"%@  %d", FSLocalizedString(@"kTotalFound"), totalCount];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [self.tableView reloadData];
    self.previousItem.enable = YES;
    self.showListItem.enable = YES;
    self.nextItem.enable = YES;
}

- (NSString *)generateRText:(NSString *)content searchKeyword:(NSString *)keyword realLocation:(int)realIndex {
    //Replace multi whitespace with one.
    for (int index = 0; index < keyword.length; index++) {
        if ([keyword characterAtIndex:index] == 32) {
            int j = index;
            for (; [keyword characterAtIndex:j] == 32; j++)
                ;
            NSRange replaceWhitespace = {index, j - index};
            keyword = [keyword stringByReplacingCharactersInRange:replaceWhitespace withString:@" "];
        }
    }

    NSArray *contentArray = [StringDrawUtil seperateString:content bySeparator:keyword];
    NSString *rtText = @"";
    int highlightIndex = 0;
    for (NSString *str in contentArray) {
        if ([str compare:keyword options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            if (highlightIndex == realIndex) {
                rtText = [rtText stringByAppendingFormat:@"<font face='%@' size=%d color='#dd1100'><b>%@</b></font>", STYLE_INFO_FONT.fontName, (int) STYLE_INFO_FONT.pointSize, str];
            } else {
                rtText = [rtText stringByAppendingFormat:@"<font face='%@' size=%d color='#dd1100'>%@</font>", STYLE_INFO_FONT.fontName, (int) STYLE_INFO_FONT.pointSize, str];
            }
            highlightIndex++;
        } else {
            rtText = [rtText stringByAppendingFormat:@"<font face='%@' size=%d color='#000000'>%@</font>", STYLE_INFO_FONT.fontName, (int) STYLE_INFO_FONT.pointSize, str];
        }
    }
    return rtText;
}

#pragma mark - UISearchBar delegate handler

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (SEARCH_BAR_TEXT.length > 0) {
        [self.searchBar resignFirstResponder];
        NSString *searchKey = SEARCH_BAR_TEXT;

        NSMutableArray *pages = [NSMutableArray array];
        for (int i = 0; i < [_pdfViewCtrl.currentDoc getPageCount]; i++) {
            [pages addObject:@(i)];
        }
        self.selectedSearchResult = nil;
        self.selectedSearchInfo = nil;
        [self.arraySearch removeAllObjects];
        [self.tableView reloadData];
        self.foundLable.text = @"Searching...";

        @try {
            [self searchTextInPDF:searchKey currentPage:pages];
        }
        @catch (NSException *exception) {
            if ([[exception name] isEqualToString:@"OutOfMemory"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [FSPDFViewCtrl recoverForOOM];
                });
                return;
            }
        }

        [self setBottombarHidden:YES];
    } else {
        [self setfoundLabelHidden:YES];
        [self setTableViewHidden:YES];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    //if (SEARCH_BAR_TEXT == nil || SEARCH_BAR_TEXT == 0) {
    //    [self clearSearch];
    //}
    return YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //if (SEARCH_BAR_TEXT == nil || SEARCH_BAR_TEXT.length == 0) {
    //    [self clearSearch];
    //}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.arraySearch.count > 0) {
        return self.arraySearch.count; //: arraySearch.count+1/*show total match count*/;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SearchResult *oneResult = [self.arraySearch objectAtIndex:section];
    return oneResult.infos.count + 1 /*first line is page summary*/;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchResult *oneResult = [self.arraySearch objectAtIndex:indexPath.section];
    if (indexPath.row == 0) //page summary
    {
        return STYLE_PAGE_SUMMARY_HEIGHT;
    } else {
        SearchInfo *oneInfo = [oneResult.infos objectAtIndex:indexPath.row - 1];
        if (oneInfo.rtHeight == 0) {
            if (oneInfo.rtText.length == 0) {
                oneInfo.rtText = [self generateRText:oneInfo.snippet searchKeyword:SEARCH_BAR_TEXT realLocation:oneInfo.keywordLocation];
            }
            RTLabel *label = [[RTLabel alloc] initWithFrame:CGRectMake(STYLE_INFO_LEFT, STYLE_INFO_TOP, 300 - STYLE_INFO_LEFT, 1000 /*large enough*/)];
            [label setParagraphReplacement:@""];
            [label setText:oneInfo.rtText];
            oneInfo.rtHeight = label.optimumSize.height;
        }
        return oneInfo.rtHeight + 2 * STYLE_INFO_TOP;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) //page summary or show total match count
    {
        static NSString *CellIdentifier = @"PageSummaryCellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
            cell.backgroundColor = [UIColor whiteColor];

            UILabel *labelLeft = [[UILabel alloc] initWithFrame:CGRectMake(STYLE_PAGE_SUMMARY_LEFT, STYLE_PAGE_SUMMARY_TOP, STYLE_PAGE_SUMMARY_WIDTH, STYLE_PAGE_SUMMARY_LABEL_HEIGHT)];
            labelLeft.textAlignment = NSTextAlignmentLeft;
            labelLeft.font = [UIFont systemFontOfSize:12]; //STYLE_PAGE_SUMMARY_FONT;
            labelLeft.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
            labelLeft.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:labelLeft];
            UILabel *labelRight = [[UILabel alloc] initWithFrame:CGRectMake((DEVICE_iPHONE ? STYLE_PAGE_SUMMARY_RIGHT_LEFT_IPHONE : STYLE_PAGE_SUMMARY_RIGHT_LEFT), STYLE_PAGE_SUMMARY_TOP,
                                                                            (DEVICE_iPHONE ? STYLE_PAGE_SUMMARY_WIDTH_IPHONE : STYLE_PAGE_SUMMARY_WIDTH), STYLE_PAGE_SUMMARY_LABEL_HEIGHT)];
            labelRight.textAlignment = NSTextAlignmentRight;
            labelRight.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            labelRight.font = [UIFont systemFontOfSize:12];
            labelRight.textColor = [UIColor colorWithRGBHex:0x5c5c5c];
            labelRight.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:labelRight];
        }
        UILabel *labelLeft = [cell.contentView.subviews objectAtIndex:0];
        UILabel *labelRight = [cell.contentView.subviews objectAtIndex:1];
        SearchResult *oneResult = [self.arraySearch objectAtIndex:indexPath.section];
        labelLeft.text = [NSString stringWithFormat:@"%@ %d", FSLocalizedString(@"kPage"), oneResult.index + 1 /*page index start from 0*/];
        labelRight.text = [NSString stringWithFormat:@"%lu", (unsigned long) oneResult.infos.count];

        return cell;
    } else {
        if ([self.arraySearch count] == 0)
            return nil;
        static NSString *CellIdentifier = @"searchCellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
            RTLabel *labelContent = [[RTLabel alloc] initWithFrame:CGRectMake(STYLE_INFO_LEFT, STYLE_INFO_TOP, 300 - STYLE_INFO_LEFT, 10 /*will be adjust later*/)];
            labelContent.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:labelContent];
        }
        RTLabel *labelContent = [cell.contentView.subviews objectAtIndex:0];
        SearchResult *oneResult = [self.arraySearch objectAtIndex:indexPath.section];

        SearchInfo *oneInfo = [oneResult.infos objectAtIndex:indexPath.row - 1];
        if (oneInfo.rtText.length == 0) {
            oneInfo.rtText = [self generateRText:oneInfo.snippet searchKeyword:SEARCH_BAR_TEXT realLocation:oneInfo.keywordLocation];
        }
        [labelContent setText:oneInfo.rtText];
        labelContent.text = [labelContent.text stringByReplacingOccurrencesOfString:@"#dd1100" withString:@"#179cd8"];
        labelContent.frame = CGRectMake(STYLE_INFO_LEFT, STYLE_INFO_TOP, 300 - STYLE_INFO_LEFT, labelContent.optimumSize.height);
        oneInfo.rtHeight = labelContent.optimumSize.height;
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= 0 && indexPath.section < [self.arraySearch count]) {
        SearchResult *oneResult = [self.arraySearch objectAtIndex:indexPath.section];
        if (indexPath.row != 0) //page summary
        {
            SearchInfo *oneInfo = [oneResult.infos objectAtIndex:indexPath.row - 1];
            CGRect firstNeedDrawRect = [oneInfo.rects count] ? [[oneInfo.rects objectAtIndex:0] CGRectValue] : CGRectZero;
            self.needDrawRects = oneInfo.rects;
            CGRect unionNeedDrawRect = CGRectZero;
            for (id obj in oneInfo.rects) {
                CGRect rect = [obj CGRectValue];
                unionNeedDrawRect = CGRectUnion(unionNeedDrawRect, rect);
            }

            self.needPageIndex = oneResult.index;

            if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_CONTINUOUS) {
                FSPointF *point = [[FSPointF alloc] init];
                [point set:CGRectGetMidX(firstNeedDrawRect) - 80 y:CGRectGetMidY(firstNeedDrawRect) + 150];
                [_pdfViewCtrl gotoPage:oneResult.index withDocPoint:point animated:YES];
            } else {
                FSPointF *point = [[FSPointF alloc] init];
                [point set:CGRectGetMidX(firstNeedDrawRect) y:CGRectGetMidY(firstNeedDrawRect)];
                [_pdfViewCtrl gotoPage:oneResult.index withDocPoint:point animated:YES];
            }

            FSRectF *docRectIva = [Utility CGRect2FSRectF:unionNeedDrawRect];
            FSRectF *oldRectIva = [Utility CGRect2FSRectF:self.cleanDrawRect];
            CGRect pvRectIna = [_pdfViewCtrl convertPdfRectToPageViewRect:docRectIva pageIndex:self.needPageIndex];
            CGRect oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:oldRectIva pageIndex:self.cleanPageIndex];
            [_pdfViewCtrl refresh:pvRectIna pageIndex:self.needPageIndex];
            [_pdfViewCtrl refresh:oldRect pageIndex:self.cleanPageIndex];

            self.cleanDrawRect = unionNeedDrawRect;
            self.cleanPageIndex = oneResult.index;
            [self setTableViewHidden:YES];
            [self setfoundLabelHidden:YES];
            [self setBottombarHidden:NO];
            self.selectedSearchResult = oneResult;
            self.selectedSearchInfo = oneInfo;
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

#pragma mark IDrawEventListener

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
    if (self.onSearchState && pageIndex == self.needPageIndex) {
        for (id obj in self.needDrawRects) {
            CGRect rect = [obj CGRectValue];
            FSRectF *docRectIva = [Utility CGRect2FSRectF:rect];
            CGRect pvRectIna = [_pdfViewCtrl convertPdfRectToPageViewRect:docRectIva pageIndex:pageIndex];
            UIColor *color = [UIColor colorWithRGBHex:0x179cd8 alpha:0.8];
            CGContextSetFillColorWithColor(context, [color CGColor]);
            CGContextFillRect(context, pvRectIna);
        }
    }
}

#pragma mark IGestureEventListener

- (BOOL)onTap:(UITapGestureRecognizer *)recognizer {
    if (self.onSearchState) {
        if (_isKeyboardShowing) {
            [self.searchBar resignFirstResponder];
        }
    }
    return NO;
}

- (BOOL)onLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (self.onSearchState) {
        if (_isKeyboardShowing) {
            [self.searchBar resignFirstResponder];
        }
    }
    return NO;
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
    if (self.onSearchState) {
        _isKeyboardShowing = YES;
    }
}

- (void)keyboardWasHidden:(NSNotification *)aNotification {
    if (self.onSearchState) {
        _isKeyboardShowing = NO;
    }
}

#pragma mark-- IDocEventListener
- (void)onDocWillOpen {
}

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
}

- (void)onDocWillClose:(FSPDFDoc *)document {
    if (!DEVICE_iPHONE && self.searchbyPopoverCtrl.isPopoverVisible) {
        [self.searchbyPopoverCtrl dismissPopoverAnimated:YES];
    }
    [self cancelSearch];
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
}

- (void)onDocWillSave:(FSPDFDoc *)document {
}
@end

static SearchResult *searchPage(FSPDFTextSearch *fstextSearch, FSPDFPage *page, NSString *keyword, StringDrawUtil *util, float width, TaskServer *taskServer) {
    __block SearchResult *result = [[SearchResult alloc] init];
    result.index = [page getIndex];
    result.infos = [NSMutableArray array];
    __block int count = 0;

    Task *task = [[Task alloc] init];
    task.run = ^() {
        if (!page) {
            return;
        }

        BOOL parseSuccess = [Utility parsePage:page flag:e_parsePageTextOnly pause:nil];
        if (!parseSuccess) {
            return;
        }

        FSPDFTextSelect *fstextPage = [[FSPDFTextSelect alloc] initWithPDFPage:page];
        if (fstextPage) {
            int pageTotalCharCount = [fstextPage getCharCount];
            int searchLineNumber = 2;
            if (fstextSearch) {
                [fstextSearch setStartPage:[page getIndex]];
                BOOL isFind = [fstextSearch findNext];
                while (isFind) {
                    if ([page getIndex] != [fstextSearch getMatchPageIndex])
                        return;
                    @autoreleasepool {
                        count++;
                        SearchInfo *info = [[SearchInfo alloc] init];
                        info.rects = [NSMutableArray array];
                        int pos = -1;
                        int selectionCount = [fstextSearch getMatchRectCount];
                        if (selectionCount > 0) {
                            pos = [fstextSearch getMatchStartCharIndex];
                        }
                        if (pos != -1) //find one match, try to fill forward and afterward to get reasonable content.
                        {
                            info.keywordLocation = 0; //start by this keyword is the first one met in return string.
                            //search forward till meet sentence end
                            int startPos = pos;
                            int tempPos = startPos - 1;
                            NSString *tempStr;
                            int commaNumber = 0; //total comma no more than 2
                            BOOL startNeedPrefix = false;
                            while (tempPos >= 0) {
                                NSString *tempStr = [fstextPage getChars:tempPos count:1];
                                if ([StringDrawUtil isSentenceBreakSymbol:tempStr]) {
                                    //meet sentence break
                                    break;
                                }
                                if ([tempStr isEqualToString:@","] || [tempStr isEqualToString:@"，"]) {
                                    commaNumber++;
                                    if (commaNumber > 2) {
                                        break;
                                    }
                                }
                                if (startPos - tempPos > 50) {
                                    //already has long character
                                    startNeedPrefix = YES;
                                    break;
                                }
                                tempPos--;
                            }
                            //stop forward only because: 1. found a sentence break; 2. meet page start. No matter in which case, start pos is tempPos+1 3. already found 2 comma 4. already has 50 characters.
                            startPos = tempPos + 1;
                            //searching forward may introduce more keyword found
                            if (startPos < pos) {
                                tempStr = [fstextPage getChars:startPos count:(pos - startPos)];
                                tempStr = [StringDrawUtil removeBlankBetweenKeyword:tempStr keyword:keyword];
                                if (startNeedPrefix) {
                                    NSString *startOneWord = [StringDrawUtil startOneWord:tempStr];
                                    tempStr = [tempStr substringFromIndex:startOneWord.length];
                                    tempStr = [NSString stringWithFormat:@"...%@", tempStr];
                                }
                                //check is keyword in this newly appended part? if yes, need to increase real search keywordLocation
                                int found = 0;
                                NSRange foundRange = [tempStr rangeOfString:keyword options:NSCaseInsensitiveSearch];
                                while (foundRange.length > 0) {
                                    found++;
                                    foundRange = [tempStr rangeOfString:keyword options:NSCaseInsensitiveSearch range:NSMakeRange(foundRange.location + foundRange.length, tempStr.length - foundRange.location - foundRange.length)];
                                }
                                info.keywordLocation += found;
                            }
                            int mustKeepWord = pos - startPos + (startNeedPrefix ? 3 : 0); //this length is must keep. It's used in later truncate endPos in rectangel. If the mustKeepWord length is inside, no need to add one line.
                            //OK, now forward part is done. Just append enough afterword so we can deal
                            int endPos = (pos + 300 < pageTotalCharCount) ? (pos + 300) : pageTotalCharCount - 1;
                            tempStr = [fstextPage getChars:MIN(startPos, endPos) count:(endPos - startPos) + 1];
                            //it contains format line break. remove it.
                            tempStr = [tempStr stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
                            tempStr = [tempStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                            tempStr = [StringDrawUtil removeBlankBetweenKeyword:tempStr keyword:keyword];
                            //check the real keyword is in which line number
                            int found = 0;
                            NSRange foundRange = [tempStr rangeOfString:keyword options:NSCaseInsensitiveSearch];
                            NSRange previousFoundRange = foundRange;
                            while (found < info.keywordLocation) {
                                foundRange = [tempStr rangeOfString:keyword options:NSCaseInsensitiveSearch range:NSMakeRange(foundRange.location + foundRange.length, tempStr.length - foundRange.location - foundRange.length)];
                                if (foundRange.length > 0) {
                                    previousFoundRange = foundRange;
                                    found++;
                                } else {
                                    break;
                                }
                            }

                            int lineNumber;
                            if (previousFoundRange.length > 0) {
                                lineNumber = [util heightOfContent:[tempStr substringToIndex:previousFoundRange.location + previousFoundRange.length] withinWidth:width] / [util singleLineHeight];
                            } else {
                                lineNumber = 0;
                            }
                            if (lineNumber < searchLineNumber) {
                                endPos = [util stringIndex:tempStr insideSize:CGSizeMake(width, [util singleLineHeight] * searchLineNumber) needSufix:YES];
                            } else {
                                endPos = [util stringIndex:tempStr insideSize:CGSizeMake(width, [util singleLineHeight] * (lineNumber /*do not add 1 here. If it's long enough, do not need to add one line*/)) needSufix:YES];
                                if (endPos <= mustKeepWord) {
                                    endPos = [util stringIndex:tempStr insideSize:CGSizeMake(width, [util singleLineHeight] * (lineNumber + 1 /*must+1 otherwise if the keyword in in end, it will dismiss by ...*/)) needSufix:YES];
                                }
                            }
                            tempStr = [[tempStr substringToIndex:endPos + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                            if (![StringDrawUtil isSentenceBreakSymbol:[tempStr substringFromIndex:tempStr.length - 1]]) {
                                tempStr = [NSString stringWithFormat:@"%@...", tempStr];
                            }
                            info.snippet = tempStr;
                        }
                        int rectCount = [fstextSearch getMatchRectCount];
                        for (int i = 0; i < rectCount; i++) {
                            FSRectF *fsrect = [fstextSearch getMatchRect:i];
                            //@#$ may need rotation here
                            [info.rects addObject:[NSValue valueWithCGRect:[Utility FSRectF2CGRect:fsrect]]];
                        }

                        [result.infos addObject:info];

                        isFind = [fstextSearch findNext];
                    }
                }
            }
        }
    };
    [taskServer executeSync:task];
    return result;
}
