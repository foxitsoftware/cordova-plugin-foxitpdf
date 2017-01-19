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
#import "ReadingBookmarkListCell.h"
#import "ReadingBookmarkViewController.h"
#import "PanelHost.h"
@implementation ReadingBookmarkButton

@end
@implementation ReadingBookmarkListCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        CGRect contentFrame = CGRectMake(self.frame.size.width-54, (self.frame.size.height - 32) / 2, 32, 32);
        contentFrame = CGRectMake(10, (self.frame.size.height - 30) / 2, 300, 30);
        self.pageLabel = [[[UILabel alloc] initWithFrame:contentFrame] autorelease];
        _pageLabel.textAlignment = UITextAlignmentLeft;
        _pageLabel.lineBreakMode = UILineBreakModeTailTruncation;
        _pageLabel.font = [UIFont systemFontOfSize:17];
        _pageLabel.textColor = [UIColor blackColor];
        [self.contentView addSubview:_pageLabel];
        
        self.detailButton = [ReadingBookmarkButton buttonWithType:UIButtonTypeCustom];
        [_detailButton setImage:[UIImage imageNamed:@"document_cellmore_more"] forState:UIControlStateNormal];
        [_detailButton addTarget:self action:@selector(setEditViewHiden:) forControlEvents:UIControlEventTouchUpInside];
        _detailButton.frame = CGRectMake(self.bounds.size.width - 50, 0, 50, 50);
        _detailButton.center = CGPointMake(_detailButton.center.x, self.bounds.size.height/2);
        _detailButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [self.contentView addSubview:_detailButton];
        
        //Global panel controller.
        PanelController* panelController = getCurrentPanelController();
        self.editView = [[AnnotationListMore alloc] initWithFrame:CGRectMake(DEVICE_iPHONE ? SCREENWIDTH : 300, 0, DEVICE_iPHONE ? SCREENWIDTH : 300, self.bounds.size.height) superView:panelController.panel.contentView delegate:self isBookMark:YES isMenu:NO];
        if (DEVICE_iPHONE) {
            _editView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        }
        [self.contentView addSubview:self.editView];
        [_editView release];
    }
    return self;
}
- (void)setEditViewHiden:(ReadingBookmarkButton *)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(setViewHidden:)]) {
        [self.delegate setViewHidden:sender.object];
    }
}

- (void)dealloc{
    [_detailButton release];
    [_editView release];
    [_pageLabel release];
    [_indexPath release];
    [super dealloc];
}
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
