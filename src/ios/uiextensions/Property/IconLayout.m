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
#import "IconLayout.h"
#import "PropertyBar.h"
#import "Utility.h"
#import "ColorUtility.h"

@interface IconLayout ()

@property (nonatomic, assign) int currentIconType;
@property (nonatomic, strong) id<IPropertyValueChangedListener> currentListener;

@property (nonatomic, strong) NSArray *arrayNames;
@property (nonatomic, strong) NSArray *arrayImages;
@property (nonatomic, assign) long currentShowIconType;

@end

@implementation IconLayout


- (instancetype)initWithFrame:(CGRect)frame iconType:(long)iconType
{
    self = [super initWithFrame:frame];
    if (self) {
        self.currentShowIconType = iconType;
        if (iconType & PROPERTY_ICONTYPE) {
            self.arrayNames = [[NSArray alloc] initWithObjects:NSLocalizedStringFromTable(@"kIconCheck", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconCircle", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconComment", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconCross", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconHelp", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconInsert", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconKey", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconNewParagraph", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconNote", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconParagraph", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconRightArrow", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconRightPointer", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconStar", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconUpArrow", @"FoxitLocalizable", nil),
                               NSLocalizedStringFromTable(@"kIconUpLeftArrow", @"FoxitLocalizable", nil), nil];
            self.arrayImages = [[NSArray alloc] initWithObjects:@"Check.png", @"ISCircle.png", @"Comment.png", @"Cross.png", @"Help.png", @"Insert.png", @"Key.png", @"New Paragraph.png", @"Note.png", @"Paragraph.png", @"Right Arrow.png", @"Right Pointer.png", @"Star.png", @"Up Arrow.png", @"Up-left Arrow.png", nil];
        }
        
        if (iconType & PROPERTY_ATTACHMENT_ICONTYPE) {
            self.arrayNames = [[NSArray alloc] initWithObjects:NSLocalizedStringFromTable(@"kGraph", @"FoxitLocalizable", nil),
                              NSLocalizedStringFromTable(@"kPushpin", @"FoxitLocalizable", nil),
                              NSLocalizedStringFromTable(@"kPaperclip", @"FoxitLocalizable", nil),
                              NSLocalizedStringFromTable(@"kTag", @"FoxitLocalizable", nil), nil];
            self.arrayImages = [[NSArray alloc] initWithObjects:@"Graph.png", @"Pushpin.png", @"Paperclip.png", @"Tag.png", nil];
        }

        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 100) style:UITableViewStylePlain];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.layoutHeight = 100;
        [self addSubview:self.tableView];
    }
    return self;
}

- (long)supportProperty
{
    return PROPERTY_ICONTYPE;
}

-(void)setCurrentIconType:(int)type
{
    _currentIconType = type;
    [self scrollToCurrentIcon];
}

-(void)setCurrentListener:(id<IPropertyValueChangedListener>)currentListener
{
    _currentListener = currentListener;
}

-(void)addDivideView
{
    for (UIView *view in self.subviews) {
        if (view.tag == 1000) {
            [view removeFromSuperview];
        }
    }
    UIView *divide = [[UIView alloc] initWithFrame:CGRectMake(20, self.frame.size.height - 1, self.frame.size.width - 40, [Utility realPX:1.0f])];
    divide.tag = 1000;
    divide.backgroundColor = [UIColor colorWithRGBHex:0x5c5c5c];
    divide.alpha = 0.2f;
    [self addSubview:divide];
    
}

-(void)resetLayout
{
    
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    if (self.currentShowIconType & PROPERTY_ICONTYPE) {
        self.arrayNames = [[NSArray alloc] initWithObjects:NSLocalizedStringFromTable(@"kIconCheck", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconCircle", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconComment", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconCross", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconHelp", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconInsert", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconKey", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconNewParagraph", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconNote", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconParagraph", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconRightArrow", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconRightPointer", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconStar", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconUpArrow", @"FoxitLocalizable", nil),
                           NSLocalizedStringFromTable(@"kIconUpLeftArrow", @"FoxitLocalizable", nil), nil];
        self.arrayImages = [[NSArray alloc] initWithObjects:@"Check.png", @"ISCircle.png", @"Comment.png", @"Cross.png", @"Help.png", @"Insert.png", @"Key.png", @"New Paragraph.png", @"Note.png", @"Paragraph.png", @"Right Arrow.png", @"Right Pointer.png", @"Star.png", @"Up Arrow.png", @"Up-left Arrow.png", nil];
    }
    if (self.currentShowIconType & PROPERTY_ATTACHMENT_ICONTYPE) {
        self.arrayNames = [[NSArray alloc] initWithObjects:NSLocalizedStringFromTable(@"kGraph", @"FoxitLocalizable", nil),
                          NSLocalizedStringFromTable(@"kPushpin", @"FoxitLocalizable", nil),
                          NSLocalizedStringFromTable(@"kPaperclip", @"FoxitLocalizable", nil),
                          NSLocalizedStringFromTable(@"kTag", @"FoxitLocalizable", nil), nil];
        self.arrayImages = [[NSArray alloc] initWithObjects:@"Graph.png", @"Pushpin.png", @"Paperclip.png", @"Tag.png", nil];
    }

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.layoutHeight = 100;
    [self addSubview:self.tableView];
    [self setCurrentIconType:_currentIconType];
    
}

#pragma mark -  table view delegate handler
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int newIconType = (int)indexPath.row;
    if (_currentListener) {
        if (self.currentShowIconType & PROPERTY_ICONTYPE) {
            [_currentListener onProperty:PROPERTY_ICONTYPE changedFrom:[NSNumber numberWithInt:_currentIconType] to:[NSNumber numberWithInt:newIconType]];
        }
        if (self.currentShowIconType & PROPERTY_ATTACHMENT_ICONTYPE) {
            [_currentListener onProperty:PROPERTY_ATTACHMENT_ICONTYPE changedFrom:[NSNumber numberWithInt:_currentIconType] to:[NSNumber numberWithInt:newIconType]];
        }

    }
    _currentIconType = newIconType;
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [tableView reloadData];
}

#pragma mark -  table view datasource handler

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arrayNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"CellIcon";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        //1. icon
        UIImageView *imageViewIcon = [[UIImageView alloc] initWithFrame:CGRectMake(ITEMLRSPACE,(cell.frame.size.height - 26) / 2,26,26)];
        [cell.contentView addSubview:imageViewIcon];
        //2. label
        UILabel *labelIconName = [[UILabel alloc] initWithFrame:CGRectMake(ITEMLRSPACE + imageViewIcon.frame.size.width + 20, 0, cell.frame.size.width - ITEMLRSPACE - imageViewIcon.frame.size.width - 20, cell.frame.size.height)];
        labelIconName.textAlignment = NSTextAlignmentLeft;
        labelIconName.font = [UIFont systemFontOfSize:15];
        [cell.contentView addSubview:labelIconName];
    }
    UIImageView *imageViewIcon = [cell.contentView.subviews objectAtIndex:0];
    UILabel *labelIconName = [cell.contentView.subviews objectAtIndex:1];
    imageViewIcon.image = [UIImage imageNamed:[_arrayImages objectAtIndex:indexPath.row]];
    labelIconName.text = [_arrayNames objectAtIndex:indexPath.row];
    
    if (_currentIconType == (int)indexPath.row)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)scrollToCurrentIcon
{
    NSIndexPath *indexPath = nil;
    indexPath = [NSIndexPath indexPathForRow:_currentIconType inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

@end
