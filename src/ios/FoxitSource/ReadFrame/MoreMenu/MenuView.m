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
#import "MenuView.h"
#import "ReadFrame.h"

@interface MenuView ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,retain)UITableViewController *tableView;
@property(nonatomic,retain)UINavigationController *navi;
@property(nonatomic,retain)NSMutableDictionary *groupDic;
@property(nonatomic,retain)NSMutableArray *groupTags;
@end


@implementation MenuView

- (id)init
{
    if (self = [super init])
    {
        _tableView = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _tableView.tableView.delegate = self;
        _tableView.tableView.dataSource = self;
        _groupDic = [[NSMutableDictionary alloc] init];
        _groupTags = [[NSMutableArray alloc] init];
        
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[cancelButton addTarget:self action:@selector(clickCancel) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"common_back_black.png"] forState:UIControlStateNormal];
        cancelButton.frame = CGRectMake(10, 9, 26, 26);
        self.navi = [[[UINavigationController alloc] initWithRootViewController:_tableView] autorelease];
        if (DEVICE_iPHONE)
        {
           [self.navi.navigationBar addSubview:cancelButton];
        }
    }
    return self;
}

- (void)clickCancel {
	if (self.onCancelClicked != nil) {
		self.onCancelClicked();
		return;
	}
	[self dismissViewController];
}

- (void)dismissViewController
{
    [[ReadFrame sharedInstance] setHiddenMoreMenu:YES];
}

- (void)dealloc
{
    self.tableView = nil;
    self.groupDic = nil;
    self.groupTags = nil;
    self.navi = nil;
    [super dealloc];
}

- (void)reloadData
{
    [_tableView.tableView reloadData];
}

- (void)setMenuTitle:(NSString *)title
{
    _tableView.title = title;
}

- (void)cancel
{
    [[ReadFrame sharedInstance] setHiddenMoreMenu:YES];
}


- (UIView *)getContentView
{
    return self.navi.view;
}

- (void)addGroup:(MenuGroup *)group
{
    [self.groupDic setObject:group forKey:[NSString stringWithFormat:@"%lu", (unsigned long)group.tag]];
    [_groupTags removeAllObjects];
    [_groupTags addObjectsFromArray:[self.groupDic allKeys]];
    [self.groupTags sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        NSComparisonResult result = [[NSNumber numberWithInt:[obj1 intValue]] compare:[NSNumber numberWithInt:[obj2 intValue]]];
        return result;
    }];
}

- (void)addMenuItem:(NSUInteger)groupTag withItem:(MvMenuItem *)item
{
    MenuGroup *group = [self.groupDic objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)groupTag]];
    [[group getItems] addObject:item];
    [[group getItems] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
       
        MvMenuItem *item1 = (MvMenuItem *)obj1;
        MvMenuItem *item2 = (MvMenuItem *)obj2;
        NSComparisonResult result = [[NSNumber numberWithLong:(long)item1.tag] compare:[NSNumber numberWithLong:(long)item2.tag]];
        return result;
    }];
}

- (void)removeMenuItem:(NSUInteger)groupTag WithItemTag:(NSUInteger)itemTag
{
    if ([self.groupDic objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)groupTag]])
    {
        MenuGroup *group = [self.groupDic objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)groupTag]];
        NSMutableArray *items = [group getItems];
        for (int i = 0; i< [items count]; i++)
        {
            MvMenuItem *item = [items objectAtIndex:i];
            if (item.tag == itemTag)
            {
                [items removeObject:item];
                break;
            }
        }
        [[group getItems] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            
            MvMenuItem *item1 = (MvMenuItem *)obj1;
            MvMenuItem *item2 = (MvMenuItem *)obj2;
            NSComparisonResult result = [[NSNumber numberWithLong:(long)item1.tag] compare:[NSNumber numberWithLong:(long)item2.tag]];
            return result;
        }];
        [self.tableView.tableView reloadData];
    }
}

- (void)removeGroup:(NSUInteger)tag
{
    if ([self.groupDic objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)tag]])
    {
        [self.groupDic removeObjectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)tag]];
        [_groupTags removeAllObjects];
        [_groupTags addObjectsFromArray:[self.groupDic allKeys]];
        [self.groupTags sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            
            NSComparisonResult result = [[NSNumber numberWithInt:[obj1 intValue]] compare:[NSNumber numberWithInt:[obj2 intValue]]];
            return result;
        }];
        [self.tableView.tableView reloadData];
    }
}

- (MenuGroup *)getGroup:(NSUInteger)tag
{
    return [self.groupDic objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)tag]];
}

#pragma mak UITableViewDataSource UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.groupDic allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MenuGroup *group = [self.groupDic objectForKey:[self.groupTags objectAtIndex:section]];
    return [[group getItems] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MenuGroup *group = [self.groupDic objectForKey:[self.groupTags objectAtIndex:section]];
    return group.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [[tableView dequeueReusableCellWithIdentifier:cellIdentifier] autorelease];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    MenuGroup *group = [self.groupDic objectForKey:[self.groupTags objectAtIndex:indexPath.section]];
    MvMenuItem *item = [[group getItems] objectAtIndex:indexPath.row];
    cell.textLabel.text = item.text;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{  
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MenuGroup *group = [self.groupDic objectForKey:[self.groupTags objectAtIndex:indexPath.section]];
    MvMenuItem *item = [[group getItems] objectAtIndex:indexPath.row];
    if ([item.callBack respondsToSelector:@selector(onClick:)])
    {
        [item.callBack onClick:item];
    }
}

@end
