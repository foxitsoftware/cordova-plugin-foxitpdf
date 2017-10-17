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

#import "SignatureListViewController.h"
#import "AnnotationSignature.h"
#import "ColorUtility.h"
#import "Masonry.h"
#import "TbBaseBar.h"
#import "UIExtensionsManager+Private.h"
#import "UIExtensionsManager.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import <QuartzCore/QuartzCore.h>

static const float STYLE_CELL_HEIGHT = 120;
static const float STYLE_CELL_HEIGHT_IPHONE = 120;

#define DIGITALSIGNATUREGROUP 1
#define HANDWRITINGSIGNATUREGROP 0

@interface SignatureListCell : UITableViewCell
@property (nonatomic, strong) UIImageView *imageThumbnail;
@property (nonatomic, strong) UIButton *moreBtn;
@property (nonatomic, strong) UIView *moreContentView;
@property (nonatomic, strong) TbBaseItem *editItem;
@property (nonatomic, strong) TbBaseItem *deleteItem;
@property (nonatomic, assign) BOOL showMoreContentView;
@property (nonatomic, strong) UIImageView *selectImageView;
@property (nonatomic, copy) void (^moreShowClick)(SignatureListCell *cell);
@property (nonatomic, copy) void (^editItemClick)(SignatureListCell *cell);
@property (nonatomic, copy) void (^deleteItemClick)(SignatureListCell *cell);
@end

@implementation SignatureListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.clipsToBounds = YES;
        self.selectImageView = [[UIImageView alloc] init];
        self.selectImageView.image = [UIImage imageNamed:@"certSelect"];
        self.selectImageView.hidden = YES;
        [self addSubview:self.selectImageView];
        [self.selectImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.selectImageView.superview.mas_left).offset(10);
            make.centerY.mas_equalTo(self.selectImageView.superview.mas_centerY);
            make.width.mas_equalTo(26);
            make.height.mas_equalTo(26);
        }];

        UIImageView *imageThumbnail = [[UIImageView alloc] init];
        imageThumbnail.contentMode = UIViewContentModeScaleAspectFit;
        self.imageThumbnail = imageThumbnail;
        [self addSubview:imageThumbnail];
        [self.imageThumbnail mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.selectImageView.mas_right).offset(10);
            make.top.mas_equalTo(self.imageThumbnail.superview.mas_top).offset(10);
            make.bottom.mas_equalTo(self.imageThumbnail.superview.mas_bottom).offset(-10);
            make.right.mas_equalTo(self.imageThumbnail.superview.mas_centerX);
        }];

        self.moreBtn = [[UIButton alloc] init];
        [self.moreBtn setImage:[UIImage imageNamed:@"document_edit_more"] forState:UIControlStateNormal];
        [self.moreBtn addTarget:self action:@selector(moreClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.moreBtn];
        [self.moreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.moreBtn.superview.mas_right).offset(-10);
            make.centerY.mas_equalTo(self.moreBtn.superview.mas_centerY);
            make.height.mas_equalTo(26);
            make.width.mas_equalTo(self.moreBtn.mas_height);
        }];

        self.moreContentView = [[UIView alloc] init];
        self.moreContentView.backgroundColor = [UIColor colorWithRGBHex:0xEFEFEF];
        [self addSubview:self.moreContentView];
        [self.moreContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.moreContentView.superview.mas_right);
            make.width.equalTo(self.moreContentView.mas_height);
            make.top.equalTo(self.moreContentView.superview.mas_top);
            make.bottom.equalTo(self.moreContentView.superview.mas_bottom);
        }];

        __weak typeof(self) weakSelf = self;
        self.editItem = [TbBaseItem createItemWithImageAndTitle:FSLocalizedString(@"kEdit") imageNormal:[UIImage imageNamed:@"signEdit"] imageSelected:[UIImage imageNamed:@"signEdit"] imageDisable:[UIImage imageNamed:@"signEdit"] background:nil imageTextRelation:RELATION_BOTTOM];
        self.editItem.textColor = [UIColor blackColor];
        self.editItem.onTapClick = ^(TbBaseItem *item) {
            weakSelf.editItemClick(weakSelf);
        };
        [self.moreContentView addSubview:self.editItem.contentView];
        CGSize size = self.editItem.contentView.frame.size;
        [self.editItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.editItem.contentView.superview.mas_left).offset(10);
            make.centerY.mas_equalTo(self.editItem.contentView.superview.mas_centerY);
            make.width.mas_equalTo(size.width);
            make.height.mas_equalTo(size.height);
        }];

        self.deleteItem = [TbBaseItem createItemWithImageAndTitle:FSLocalizedString(@"kDelete") imageNormal:[UIImage imageNamed:@"signDelete"] imageSelected:[UIImage imageNamed:@"signDelete"] imageDisable:[UIImage imageNamed:@"signDelete"] background:nil imageTextRelation:RELATION_BOTTOM];
        self.deleteItem.textColor = [UIColor blackColor];
        self.deleteItem.onTapClick = ^(TbBaseItem *item) {
            weakSelf.deleteItemClick(weakSelf);
        };
        [self.moreContentView addSubview:self.deleteItem.contentView];
        size = self.deleteItem.contentView.frame.size;
        [self.deleteItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.deleteItem.contentView.superview.mas_right).offset(-10);
            make.centerY.mas_equalTo(self.deleteItem.contentView.superview.mas_centerY);
            make.width.mas_equalTo(size.width);
            make.height.mas_equalTo(size.height);
        }];

        UIView *divideView = [[UIView alloc] init];
        divideView.backgroundColor = [UIColor colorWithRed:0xE2 / 255.0f green:0xE2 / 255.0f blue:0xE2 / 255.0f alpha:1];
        [self addSubview:divideView];
        [divideView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(divideView.superview.mas_left).offset(10);
            make.height.mas_equalTo(1);
            make.bottom.mas_equalTo(divideView.superview.mas_bottom);
            make.right.mas_equalTo(divideView.superview.mas_right).offset(-2);
        }];
    }
    return self;
}

- (void)setShowMoreContentView:(BOOL)showMoreContentView {
    if (showMoreContentView) {
        self.moreBtn.hidden = YES;
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self.moreContentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.width.mas_equalTo(self.moreContentView.mas_height);
                                 make.right.mas_equalTo(self.moreContentView.superview.mas_right);
                                 make.top.mas_equalTo(self.moreContentView.superview.mas_top);
                                 make.bottom.mas_equalTo(self.moreContentView.superview.mas_bottom);
                             }];
                             self.moreContentView.superview.layoutIfNeeded;
                         }];
    } else {
        self.moreBtn.hidden = NO;
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self.moreContentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.left.mas_equalTo(self.moreContentView.superview.mas_right);
                                 make.width.mas_equalTo(self.moreContentView.mas_height);
                                 make.top.mas_equalTo(self.moreContentView.superview.mas_top);
                                 make.bottom.mas_equalTo(self.moreContentView.superview.mas_bottom);
                             }];
                         }];
        self.moreContentView.superview.layoutIfNeeded;
    }
}

- (void)moreClick {
    self.moreShowClick(self);
}

@end

@interface SignatureListViewController ()
@property (nonatomic, strong) TbBaseBar *topBar;
@property (nonatomic, strong) TbBaseItem *createItem;
@property (nonatomic, strong) TbBaseItem *cancelItem;
@property (nonatomic, strong) NSIndexPath *oldIndexPath;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UILongPressGestureRecognizer *longGesture;
@end

@implementation SignatureListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.signatureArray = [NSMutableArray array];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    self.view.backgroundColor = [UIColor clearColor];

    self.topBar = [[TbBaseBar alloc] init];
    self.topBar.contentView.backgroundColor = [UIColor colorWithRGBHex:0xF2FAFAFA];

    [self.view addSubview:self.topBar.contentView];
    [self.topBar.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.topBar.contentView.superview.mas_left);
        make.right.mas_equalTo(self.topBar.contentView.superview.mas_right);
        make.top.mas_equalTo(self.topBar.contentView.superview.mas_top);
        if (DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact) {
            make.height.mas_equalTo(64);
        } else {
            make.height.mas_equalTo(44);
        }
    }];

    if (DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact) {
        __weak typeof(self) weakSelf = self;
        self.cancelItem = [TbBaseItem createItemWithImage:[UIImage imageNamed:@"common_back_black"] imageSelected:[UIImage imageNamed:@"common_back_black"] imageDisable:[UIImage imageNamed:@"common_back_black"]];
        self.cancelItem.onTapClick = ^(TbBaseItem *item) {
            [weakSelf dismissViewControllerAnimated:YES
                                         completion:^() {
                                             if (weakSelf.delegate) {
                                                 [weakSelf.delegate cancelSignature];
                                             }
                                         }];
        };
        [self.topBar addItem:self.cancelItem displayPosition:Position_LT];
        CGSize size = self.cancelItem.contentView.frame.size;
        [self.cancelItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.cancelItem.contentView.superview.mas_left).offset(10);
            make.height.mas_equalTo(size.height);
            make.width.mas_equalTo(size.width);
            if (DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact) {
                make.centerY.mas_equalTo(self.cancelItem.contentView.superview.mas_centerY).offset(10);
            } else {
                make.centerY.mas_equalTo(self.cancelItem.contentView.superview.mas_centerY);
            }
        }];
    }

    TbBaseItem *titleItem = [TbBaseItem createItemWithTitle:FSLocalizedString(@"kSignatureTitle")];
    titleItem.textColor = [UIColor colorWithRGBHex:0x3F3F3F];
    [self.topBar.contentView addSubview:titleItem.contentView];
    CGSize size = titleItem.contentView.frame.size;
    [titleItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(titleItem.contentView.superview.mas_centerX);
        make.height.mas_equalTo(size.height);
        make.width.mas_equalTo(size.width);
        if (DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact) {
            make.centerY.mas_equalTo(titleItem.contentView.superview.mas_centerY).offset(10);
        } else {
            make.centerY.mas_equalTo(titleItem.contentView.superview.mas_centerY);
        }
    }];

    __weak typeof(self) weakSelf = self;
    self.createItem = [TbBaseItem createItemWithTitle:FSLocalizedString(@"kCreate")];
    self.createItem.onTapClick = ^(TbBaseItem *item) {
        [weakSelf addSignature];
    };
    self.createItem.textColor = [UIColor colorWithRGBHex:0x179cd8];
    self.createItem.textFont = [UIFont systemFontOfSize:15.0f];
    [self.topBar addItem:self.createItem displayPosition:Position_RB];
    size = self.createItem.contentView.frame.size;
    [self.createItem.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.createItem.contentView.superview.mas_right).offset(-10);
        make.height.mas_equalTo(size.height);
        make.width.mas_equalTo(size.width);
        if (DEVICE_iPHONE || SIZECLASS == UIUserInterfaceSizeClassCompact) {
            make.centerY.mas_equalTo(self.createItem.contentView.superview.mas_centerY).offset(10);
        } else {
            make.centerY.mas_equalTo(self.createItem.contentView.superview.mas_centerY);
        }
    }];

    self.tableView = [[UITableView alloc] init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelectionDuringEditing = NO;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.tableView.superview.mas_left);
        make.right.mas_equalTo(self.tableView.superview.mas_right);
        make.bottom.mas_equalTo(self.tableView.superview.mas_bottom);
        make.top.mas_equalTo(self.topBar.contentView.mas_bottom);
    }];

    if (self.isFieldSigList) {
        self.signatureArray = [AnnotationSignature getCertSignatureList];
    } else {
        self.signatureArray = (NSMutableArray *) [self groupSignatureListArray:[AnnotationSignature getSignatureList]];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeGesture];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
}

- (void)tapGuest:(UIGestureRecognizer *)recognizer {
    SignatureListCell *oldEditCell = [self.tableView cellForRowAtIndexPath:self.oldIndexPath];
    if (oldEditCell) {
        oldEditCell.showMoreContentView = NO;
    }
    [self removeGesture];
}

- (void)longGesture:(UILongPressGestureRecognizer *)recognizer {
    SignatureListCell *oldEditCell = [self.tableView cellForRowAtIndexPath:self.oldIndexPath];
    if (oldEditCell) {
        oldEditCell.showMoreContentView = NO;
    }
    [self removeGesture];
}

#pragma mark -  table view delegate handler
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DEVICE_iPHONE ? STYLE_CELL_HEIGHT_IPHONE : STYLE_CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name;
    if (self.isFieldSigList) {
        name = [self.signatureArray objectAtIndex:indexPath.row];
    } else {
        name = [[self.signatureArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    AnnotationSignature *sig = [AnnotationSignature getSignature:name];
    [AnnotationSignature setSignatureSelected:sig.name];
    [tableView reloadData];

    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 if (self.delegate) {
                                     [self.delegate signatureListViewController:self selectSignature:sig];
                                 }
                             }];
}

#pragma mark -  table view datasource handler

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.isFieldSigList) {
        return 1;
    }
    return self.signatureArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isFieldSigList) {
        return self.signatureArray.count;
    }
    return [self.signatureArray[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"signatureListCellID";
    SignatureListCell *cell = [[SignatureListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];

    typeof(self) __weak weakSelf = self;
    cell.moreShowClick = ^(SignatureListCell *editCell) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:weakSelf action:@selector(tapGuest:)];
        weakSelf.tapGesture = tapGesture;
        UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:weakSelf action:@selector(longGesture:)];
        weakSelf.longGesture = longGesture;
        [weakSelf.view addGestureRecognizer:longGesture];
        [weakSelf.view addGestureRecognizer:tapGesture];
        SignatureListCell *oldEditCell = [tableView cellForRowAtIndexPath:weakSelf.oldIndexPath];
        if (oldEditCell) {
            oldEditCell.showMoreContentView = NO;
        }
        editCell.showMoreContentView = YES;
        weakSelf.oldIndexPath = [tableView indexPathForCell:editCell];
    };
    cell.editItemClick = ^(SignatureListCell *editCell) {
        [weakSelf removeGesture];
        if (DEVICE_iPHONE) {
            [weakSelf dismissViewControllerAnimated:NO
                                         completion:^{
                                             NSString *name;
                                             if (weakSelf.isFieldSigList) {
                                                 name = [weakSelf.signatureArray objectAtIndex:[tableView indexPathForCell:editCell].row];
                                             } else {
                                                 name = [[weakSelf.signatureArray objectAtIndex:[tableView indexPathForCell:editCell].section] objectAtIndex:[tableView indexPathForCell:editCell].row];
                                             }
                                             AnnotationSignature *sig = [AnnotationSignature getSignature:name];
                                             [weakSelf.delegate signatureListViewController:weakSelf openSignature:sig];
                                         }];
        } else {
            NSString *name;
            if (weakSelf.isFieldSigList) {
                name = [weakSelf.signatureArray objectAtIndex:[tableView indexPathForCell:editCell].row];
            } else {
                name = [[weakSelf.signatureArray objectAtIndex:[tableView indexPathForCell:editCell].section] objectAtIndex:[tableView indexPathForCell:editCell].row];
            }
            AnnotationSignature *sig = [AnnotationSignature getSignature:name];
            [weakSelf.delegate signatureListViewController:weakSelf openSignature:sig];
        }

    };
    cell.deleteItemClick = ^(SignatureListCell *editCell) {
        [weakSelf removeGesture];
        NSString *name;
        if (weakSelf.isFieldSigList) {
            name = [weakSelf.signatureArray objectAtIndex:[tableView indexPathForCell:editCell].row];
        } else {
            name = [[weakSelf.signatureArray objectAtIndex:[tableView indexPathForCell:editCell].section] objectAtIndex:[tableView indexPathForCell:editCell].row];
        }
        AnnotationSignature *sig = [AnnotationSignature getSignature:name];
        [AnnotationSignature removeSignatureResource:sig.name];
        [sig remove];
        if (weakSelf.isFieldSigList) {
            weakSelf.signatureArray = [AnnotationSignature getCertSignatureList];
        } else {
            weakSelf.signatureArray = (NSMutableArray *) [weakSelf groupSignatureListArray:[AnnotationSignature getSignatureList]];
        }
        [weakSelf.tableView reloadData];
        if (weakSelf.delegate) {
            [weakSelf.delegate signatureListViewController:weakSelf deleteSignature:sig];
        }
    };

    UIImageView *imageThumbnail = cell.imageThumbnail;
    NSString *name;
    if (self.isFieldSigList) {
        name = [self.signatureArray objectAtIndex:indexPath.row];
    } else {
        name = [[self.signatureArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    UIImage *signImage = [AnnotationSignature getSignatureImage:name];
    CGSize imageThumbnailSize = CGSizeMake((signImage.size.width / signImage.size.height) * (STYLE_CELL_HEIGHT - 20), (STYLE_CELL_HEIGHT - 20));
    if (signImage.size.width >= imageThumbnailSize.width || signImage.size.height >= imageThumbnailSize.height) {
        imageThumbnail.image = [Utility scaleToSize:signImage size:imageThumbnailSize];
    } else {
        imageThumbnail.image = signImage;
    }

    NSString *selectedName = nil;
    selectedName = [AnnotationSignature getSignatureSelected];

    selectedName = [AnnotationSignature getSignatureSelected];
    if ([selectedName isEqualToString:name]) {
        cell.selectImageView.hidden = NO;
    } else {
        cell.selectImageView.hidden = YES;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.isFieldSigList) {
        return 1;
    }
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.isFieldSigList) {
        UIView *headerView = [[UIView alloc] init];
        headerView.backgroundColor = [UIColor colorWithRed:0xE2 / 255.0f green:0xE2 / 255.0f blue:0xE2 / 255.0f alpha:1];
        return headerView;
    }

    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor colorWithRGBHex:0xEFEFF4];
    UIView *topDivideView = [[UIView alloc] init];
    topDivideView.backgroundColor = [UIColor colorWithRed:0xE2 / 255.0f green:0xE2 / 255.0f blue:0xE2 / 255.0f alpha:1];
    [headerView addSubview:topDivideView];
    [topDivideView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(topDivideView.superview.mas_left);
        make.top.mas_equalTo(topDivideView.superview.mas_top);
        make.right.mas_equalTo(topDivideView.superview.mas_right);
        make.height.mas_equalTo(1);
    }];

    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:15];
    [headerView addSubview:label];
    if (section == DIGITALSIGNATUREGROUP) {
        label.text = FSLocalizedString(@"kSignListSectionHadCert");
    } else {
        label.text = FSLocalizedString(@"kSignListSectionWithoutCert");
    }

    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(label.superview.mas_left).offset(10);
        make.bottom.mas_equalTo(label.superview.mas_bottom).offset(-5);
    }];

    UIView *bottomDivideView = [[UIView alloc] init];
    bottomDivideView.backgroundColor = [UIColor colorWithRed:0xE2 / 255.0f green:0xE2 / 255.0f blue:0xE2 / 255.0f alpha:1];
    [headerView addSubview:bottomDivideView];
    [bottomDivideView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(topDivideView.superview.mas_left);
        make.bottom.mas_equalTo(topDivideView.superview.mas_bottom);
        make.right.mas_equalTo(topDivideView.superview.mas_right);
        make.height.mas_equalTo(1);
    }];
    return headerView;
}

#pragma mark - event handler

- (void)removeGesture {
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
    }
    if (self.longGesture) {
        [self.view removeGestureRecognizer:self.longGesture];
    }
}

- (void)addSignature {
    if (DEVICE_iPHONE) {
        [self dismissViewControllerAnimated:NO
                                 completion:^{
                                     if (self.delegate) {
                                         [self.delegate signatureListViewController:self openSignature:nil];
                                     }
                                 }];
    } else {
        if (self.delegate) {
            [self.delegate signatureListViewController:self openSignature:nil];
        }
    }
}

- (NSArray *)groupSignatureListArray:(NSArray *)listArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    NSMutableArray *certSignArray = [[NSMutableArray alloc] init];
    NSMutableArray *handleSignArray = [[NSMutableArray alloc] init];
    [mutableArray addObject:handleSignArray];
    [mutableArray addObject:certSignArray];

    for (NSString *sigName in listArray) {
        AnnotationSignature *sig = [AnnotationSignature getSignature:sigName];
        if (sig.certMD5 && sig.certPasswd && sig.certFileName) {
            [certSignArray addObject:sigName];
        } else {
            [handleSignArray addObject:sigName];
        }
    }
    return mutableArray;
}

@end
