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
#import <UIKit/UIKit.h>
#import "IconLayout.h"
#import "PropertyBar.h"
#import "Utility.h"
#import "ColorUtility.h"

@interface IconLayout ()

@property (nonatomic, assign) int currentIconType;
@property (nonatomic, retain) id<IPropertyValueChangedListener> currentListener;

@property (nonatomic, retain) NSArray *arrayNames;
@property (nonatomic, retain) NSArray *arrayImages;

@end

@implementation IconLayout


- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.arrayNames =[[[NSArray alloc] initWithObjects:NSLocalizedString(@"kIconCheck", nil),
                          NSLocalizedString(@"kIconCircle", nil),
                          NSLocalizedString(@"kIconComment", nil),
                          NSLocalizedString(@"kIconCross", nil),
                          NSLocalizedString(@"kIconHelp", nil),
                          NSLocalizedString(@"kIconInsert", nil),
                          NSLocalizedString(@"kIconKey", nil),
                          NSLocalizedString(@"kIconNewParagraph", nil),
                          NSLocalizedString(@"kIconNote", nil),
                          NSLocalizedString(@"kIconParagraph", nil),
                          NSLocalizedString(@"kIconRightArrow", nil),
                          NSLocalizedString(@"kIconRightPointer", nil),
                          NSLocalizedString(@"kIconStar", nil),
                          NSLocalizedString(@"kIconUpArrow", nil),
                          NSLocalizedString(@"kIconUpLeftArrow", nil), nil] autorelease];
        self.arrayImages = [[[NSArray alloc] initWithObjects:@"Check.png", @"ISCircle.png", @"Comment.png", @"Cross.png", @"Help.png", @"Insert.png", @"Key.png", @"New Paragraph.png", @"Note.png", @"Paragraph.png", @"Right Arrow.png", @"Right Pointer.png", @"Star.png", @"Up Arrow.png", @"Up-left Arrow.png", nil] autorelease];
        
        self.tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 100) style:UITableViewStylePlain] autorelease];
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
    UIView *divide = [[[UIView alloc] initWithFrame:CGRectMake(20, self.frame.size.height - 1, self.frame.size.width - 40, [Utility realPX:1.0f])] autorelease];
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
    
    self.arrayNames =[[[NSArray alloc] initWithObjects:NSLocalizedString(@"kIconCheck", nil),
                      NSLocalizedString(@"kIconCircle", nil),
                      NSLocalizedString(@"kIconComment", nil),
                      NSLocalizedString(@"kIconCross", nil),
                      NSLocalizedString(@"kIconHelp", nil),
                      NSLocalizedString(@"kIconInsert", nil),
                      NSLocalizedString(@"kIconKey", nil),
                      NSLocalizedString(@"kIconNewParagraph", nil),
                      NSLocalizedString(@"kIconNote", nil),
                      NSLocalizedString(@"kIconParagraph", nil),
                      NSLocalizedString(@"kIconRightArrow", nil),
                      NSLocalizedString(@"kIconRightPointer", nil),
                      NSLocalizedString(@"kIconStar", nil),
                      NSLocalizedString(@"kIconUpArrow", nil),
                      NSLocalizedString(@"kIconUpLeftArrow", nil), nil] autorelease];
    self.arrayImages = [[[NSArray alloc] initWithObjects:@"Check.png", @"ISCircle.png", @"Comment.png", @"Cross.png", @"Help.png", @"Insert.png", @"Key.png", @"New Paragraph.png", @"Note.png", @"Paragraph.png", @"Right Arrow.png", @"Right Pointer.png", @"Star.png", @"Up Arrow.png", @"Up-left Arrow.png", nil] autorelease];
    
    self.tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100) style:UITableViewStylePlain] autorelease];
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
    if (_currentListener) {
        [_currentListener onIntValueChanged:PROPERTY_ICONTYPE value:(int)indexPath.row];
    }
    _currentIconType = (int)indexPath.row;
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        //1. icon
        UIImageView *imageViewIcon = [[[UIImageView alloc] initWithFrame:CGRectMake(ITEMLRSPACE,(cell.frame.size.height - 26) / 2,26,26)] autorelease];
        [cell.contentView addSubview:imageViewIcon];
        //2. label
        UILabel *labelIconName = [[[UILabel alloc] initWithFrame:CGRectMake(ITEMLRSPACE + imageViewIcon.frame.size.width + 20, 0, cell.frame.size.width - ITEMLRSPACE - imageViewIcon.frame.size.width - 20, cell.frame.size.height)] autorelease];
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
