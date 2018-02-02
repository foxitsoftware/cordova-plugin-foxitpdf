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

#import "MenuView.h"
#import "../../Common/Const.h"
#import "../../Common/Defines.h"

@interface MenuView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableViewController *tableView;
@property (nonatomic, strong) UINavigationController *navi;
@property (nonatomic, strong) NSMutableDictionary *groupDic;
@property (nonatomic, strong) NSMutableArray *groupTags;
@property (nonatomic, strong) NSMutableDictionary *moreViewRemoveGropDic;
@property (nonatomic, strong) NSMutableDictionary *moreViewCopyDic;
@end

@implementation MenuView

- (id)init {
    if (self = [super init]) {
        _tableView = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _tableView.tableView.delegate = self;
        _tableView.tableView.dataSource = self;
        _groupDic = [[NSMutableDictionary alloc] init];
        _groupTags = [[NSMutableArray alloc] init];

        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelButton addTarget:self action:@selector(clickCancel) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"common_back_black.png"] forState:UIControlStateNormal];
        cancelButton.frame = CGRectMake(10, 9, 26, 26);
        self.navi = [[UINavigationController alloc] initWithRootViewController:_tableView];
        if (DEVICE_iPHONE) {
            [self.navi.navigationBar addSubview:cancelButton];
        }
    }
    return self;
}

- (void)clickCancel {
    if (self.onCancelClicked) {
        self.onCancelClicked();
    }
}

- (void)reloadData {
    [_groupTags removeAllObjects];
    [_groupTags addObjectsFromArray:[self.groupDic allKeys]];
    [self.groupTags sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {

        NSComparisonResult result = [obj1 compare:obj2];
        return result;
    }];

    [_tableView.tableView reloadData];
}

- (void)setMenuTitle:(NSString *)title {
    _tableView.title = title;
}

- (UIView *)getContentView {
    return self.navi.view;
}

- (void)getDeepCopyDataSource {
    if (!_moreViewCopyDic) {
        NSMutableDictionary *groupDicArr = [[NSMutableDictionary alloc] init];
        for (id key in _groupDic) {
            MenuGroup *group = [_groupDic objectForKey:key];

            NSMutableArray *mvMenuItemArr = [[NSMutableArray alloc] init];

            for (MvMenuItem *item in [group getItems]) {
                [mvMenuItemArr addObject:item];
            }

            [groupDicArr setObject:mvMenuItemArr forKey:key];
        }

        _moreViewCopyDic = [groupDicArr mutableCopy];
    }
}

- (void)resetViewData {
    [self getDeepCopyDataSource];
    NSMutableDictionary *groupDicArr = [[NSMutableDictionary alloc] init];
    for (id key in _moreViewCopyDic) {
        NSMutableArray *groupArr = [_moreViewCopyDic objectForKey:key];
        MenuGroup *group = [[MenuGroup alloc] init];
        group.tag = [key integerValue];
        switch ([key integerValue]) {
        case TAG_GROUP_FILE:
            group.title = FSLocalizedString(@"kOtherDocumentsFile");
            break;
        case TAG_GROUP_PROTECT:
            group.title = FSLocalizedString(@"kSecurity");
            break;
        case TAG_GROUP_FORM:
            group.title = FSLocalizedString(@"kForm");
            break;
        default:
            break;
        }
        [group setItems:[groupArr mutableCopy]];
        [groupDicArr setObject:group forKey:key];
    }

    _groupDic = groupDicArr;
    [self reloadData];
}

#pragma mark - more view group item element hide/show
- (void)setMoreViewItemHiddenWithGroup:(NSUInteger)groupTag andItemTag:(NSUInteger)itemTag hidden:(BOOL)isHidden {
    [self getDeepCopyDataSource];

    if (isHidden) {
        [self removeMenuItem:groupTag WithItemTag:itemTag];
    } else {
        if ([[_moreViewCopyDic allKeys] containsObject:@(groupTag)]) {
            NSArray *groupArr = [_moreViewCopyDic objectForKey:@(groupTag)];

            MvMenuItem *waitAddItem = [[MvMenuItem alloc] init];
            for (MvMenuItem *item in groupArr) {
                if (item.tag == itemTag) {
                    waitAddItem = item;
                    break;
                }
            }

            MenuGroup *group = [_groupDic objectForKey:@(groupTag)];
            if (!group) {
                group = [[MenuGroup alloc] init];
                group.tag = groupTag;
                switch (groupTag) {
                case TAG_GROUP_FILE:
                    group.title = FSLocalizedString(@"kOtherDocumentsFile");
                    break;
                case TAG_GROUP_PROTECT:
                    group.title = FSLocalizedString(@"kSecurity");
                    break;
                case TAG_GROUP_FORM:
                    group.title = FSLocalizedString(@"kForm");
                    break;
                default:
                    break;
                }
                [self addGroup:group];
            }
            if (![[group getItems] containsObject:waitAddItem]) {
                [self addMenuItem:groupTag withItem:waitAddItem];
            }
        }
    }
}

#pragma mark - more view group element hide/show
- (void)setMoreViewItemHiddenWithGroup:(NSUInteger)groupTag hidden:(BOOL)isHidden {
    if (!_moreViewRemoveGropDic) {
        _moreViewRemoveGropDic = [_groupDic mutableCopy];
    }

    if (isHidden) {
        [self removeGroup:groupTag];
    } else {
        if ([[_moreViewRemoveGropDic allKeys] containsObject:@(groupTag)]) {
            if (![[_groupDic allKeys] containsObject:@(groupTag)]) {
                MenuGroup *group = [_moreViewRemoveGropDic objectForKey:@(groupTag)];
                [self addGroup:group];
            }
        }
    }
}

- (void)addGroup:(MenuGroup *)group {
    [self.groupDic setObject:group forKey:@(group.tag)];
    [_groupTags removeAllObjects];
    [_groupTags addObjectsFromArray:[self.groupDic allKeys]];
    [self.groupTags sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {

        NSComparisonResult result = [obj1 compare:obj2];
        return result;
    }];
}

- (void)addMenuItem:(NSUInteger)groupTag withItem:(MvMenuItem *)item {
    MenuGroup *group = [self.groupDic objectForKey:@(groupTag)];
    [[group getItems] addObject:item];
    [[group getItems] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {

        MvMenuItem *item1 = (MvMenuItem *) obj1;
        MvMenuItem *item2 = (MvMenuItem *) obj2;
        NSComparisonResult result = [@(item1.tag) compare:@(item2.tag)];
        return result;
    }];
}

- (void)removeMenuItem:(NSUInteger)groupTag WithItemTag:(NSUInteger)itemTag {
    if ([self.groupDic objectForKey:@(groupTag)]) {
        MenuGroup *group = [self.groupDic objectForKey:@(groupTag)];
        NSMutableArray *items = [group getItems];
        for (int i = 0; i < [items count]; i++) {
            MvMenuItem *item = [items objectAtIndex:i];
            if (item.tag == itemTag) {
                [items removeObject:item];
                break;
            }
        }
        [[group getItems] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {

            MvMenuItem *item1 = (MvMenuItem *) obj1;
            MvMenuItem *item2 = (MvMenuItem *) obj2;
            NSComparisonResult result = [@(item1.tag) compare:@(item2.tag)];
            return result;
        }];

        if ([group getItems].count == 0) {
            [self removeGroup:groupTag];
            return;
        }

        [self reloadData];
    }
}

- (void)removeGroup:(NSUInteger)tag {
    if ([self.groupDic objectForKey:@(tag)]) {
        [self.groupDic removeObjectForKey:@(tag)];
        [_groupTags removeAllObjects];
        [_groupTags addObjectsFromArray:[self.groupDic allKeys]];
        [self.groupTags sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {

            NSComparisonResult result = [obj1 compare:obj2];
            return result;
        }];
        [self.tableView.tableView reloadData];
    }
}

- (MenuGroup *)getGroup:(NSUInteger)tag {
    return [self.groupDic objectForKey:@(tag)];
}

#pragma mak UITableViewDataSource UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.groupDic allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    MenuGroup *group = [self.groupDic objectForKey:[self.groupTags objectAtIndex:section]];
    return [[group getItems] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    MenuGroup *group = [self.groupDic objectForKey:[self.groupTags objectAtIndex:section]];
    return group.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"readFrameMoreMenuTableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    MenuGroup *group = [self.groupDic objectForKey:[self.groupTags objectAtIndex:indexPath.section]];
    MvMenuItem *item = [[group getItems] objectAtIndex:indexPath.row];
    cell.textLabel.text = item.text;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MenuGroup *group = [self.groupDic objectForKey:[self.groupTags objectAtIndex:indexPath.section]];
    MvMenuItem *item = [[group getItems] objectAtIndex:indexPath.row];
    if ([item.callBack respondsToSelector:@selector(onClick:)]) {
        [item.callBack onClick:item];
    }
}

@end
