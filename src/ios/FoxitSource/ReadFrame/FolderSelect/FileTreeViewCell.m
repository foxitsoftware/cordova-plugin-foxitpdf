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

#import "FileTreeViewCell.h"
#import "Utility+Demo.h"

@implementation FileTreeViewCell
@synthesize delegate= _delegate;
@synthesize node= _node;
@synthesize buttonExpand= _buttonExpand;
@synthesize labelTitle= _labelTitle;
@synthesize imageFolder= _imageFolder;
@synthesize labelSize = _labelSize;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setNode:(FileTreeNode *)node
{
    [node retain];
    [_node release];
    _node= node;
    if (self.buttonExpand ==nil)
    {
        UIButton *buttonExpand= [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 30.0f, 30.0f)];
        self.buttonExpand= buttonExpand;
        [buttonExpand addTarget:self action:@selector(buttonExpandClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:buttonExpand];
        UIImage *imageButton= [UIImage imageNamed:@"Select_Triangle_MP.png"];
        [self.buttonExpand setImage:imageButton forState:UIControlStateNormal];
        [buttonExpand release];
        
        UIImage *imageFolder= [UIImage imageNamed:@"listmode_Folder.png"];
        UIImageView *imageViewFolder= [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 40.0f)];
        imageViewFolder.image= imageFolder;
        self.imageFolder= imageViewFolder;
        [self.contentView addSubview:imageViewFolder];
        [imageViewFolder release];
        
        UILabel *labelTitle= [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
        self.labelTitle= labelTitle;
        labelTitle.font= [UIFont systemFontOfSize:17.0];
        [labelTitle setBackgroundColor:[UIColor clearColor]];
        [self.contentView addSubview:labelTitle];
        [labelTitle release];
        
        UILabel *labelSize = [[UILabel alloc] initWithFrame:labelTitle.frame];
        self.labelSize = labelSize;
        labelSize.font = [UIFont systemFontOfSize:13.0];
        [labelSize setBackgroundColor:[UIColor clearColor]];
        [self.contentView addSubview:labelSize];
        [labelSize release];
    }
    CGRect cellFrame= self.frame;
    CGFloat yPoint= (CGRectGetHeight(cellFrame)- 30.0f)/2+30.0f/2;
    CGFloat xPoint=40.0f*node.deep+30.0f/2;
    [self.buttonExpand setCenter:CGPointMake(xPoint, yPoint)];
    CGRect imageFolderFrame= CGRectMake(CGRectGetMaxX(self.buttonExpand.frame)+ 15/2, 
                                        (CGRectGetHeight(self.frame)-CGRectGetHeight(self.imageFolder.frame)) / 2, 
                                        CGRectGetWidth(self.imageFolder.frame), 
                                        CGRectGetHeight(self.imageFolder.frame));
    self.imageFolder.frame= imageFolderFrame;
    CGRect labelTitleFrame=CGRectMake(CGRectGetMaxX(self.imageFolder.frame)+ 15/2, 
                                      0.0f, 
                                      CGRectGetWidth(cellFrame)-CGRectGetMaxX(self.imageFolder.frame), 
                                      CGRectGetHeight(cellFrame));
    self.labelSize.hidden = (node.data == nil);
    if (node.data != nil)
    {
        if ([node.data isKindOfClass:[NSNumber class]])
        {
            self.imageFolder.image = [UIImage imageNamed:[Utility getIconName:node.title]];
        }
        else
        {
            self.imageFolder.image = [UIImage imageNamed:@"list_newfolder"];
        }
        labelTitleFrame.size.height = CGRectGetHeight(cellFrame) / 2;
    }
    else
    {
        self.imageFolder.image = [UIImage imageNamed:@"list_newfolder"];
    }
    self.labelTitle.frame= labelTitleFrame;
    self.labelTitle.text= node.title;
    self.labelTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    if (!self.labelSize.hidden)
    {
        labelTitleFrame.origin.y = labelTitleFrame.origin.y + labelTitleFrame.size.height;
        self.labelSize.frame = labelTitleFrame;
        if ([node.data isKindOfClass:[NSNumber class]])
        {
            self.labelSize.text = [Utility displayFileSize:[node.data longLongValue]];
        }
        else if ([node.data isKindOfClass:[NSString class]])
        {
            self.labelSize.text = node.data;
        }
    }
    if (node.expanded)
    {
        self.buttonExpand.transform= CGAffineTransformMakeRotation(3.1415/2);
    }
    else
    {
        self.buttonExpand.transform= CGAffineTransformMakeRotation(0.0);
    }        
    [self.buttonExpand setHidden:!node.hasChildren];
}

- (void)dealloc
{
    self.node= nil;
    self.buttonExpand= nil;
    self.labelTitle= nil;
    self.imageFolder= nil;
    self.labelSize = nil;
    [super dealloc];
}

#pragma mark- event handler
- (void)buttonExpandClick:(id)sender
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(fileTreeViewCellExpand:node:)])
        {
            [self.delegate fileTreeViewCellExpand:self node:self.node];
        }
    }
}

@end
