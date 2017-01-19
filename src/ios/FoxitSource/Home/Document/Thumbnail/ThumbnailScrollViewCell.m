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
#import "ThumbnailScrollViewCell.h"
#import "ThumbnailScrollView.h"


@interface ThumbnailScrollViewCell ()

- (void)layoutBadge;
// Gestures
- (void)swipeGestureHandler:(UISwipeGestureRecognizer *)swipeGesture;

@end

@implementation ThumbnailScrollViewCell
@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize contentView = _contentView;
@synthesize backgroundBadge = _backgroundBadge;
@synthesize labelBadge = _labelBadge;
@synthesize badgeValue = _badgeValue;
@synthesize editing = _editing;
@synthesize containerView = _containerView;
@synthesize scrollView = _scrollView;
@synthesize aloneEditing = _aloneEditing;
@synthesize reserveObj = _reserveObj;
@synthesize alwaysHideCheckBox = _alwaysHideCheckBox;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
        self.alwaysHideCheckBox = NO;
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.containerView];
      
        _badgeView = [[UIView alloc] init];
        [self.containerView addSubview:_badgeView];
        [_badgeView addSubview:self.backgroundBadge];
        [_badgeView addSubview:self.labelBadge];
        _badgeView.hidden = YES;
        _badgeView.backgroundColor = [UIColor clearColor];
        _swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureHandler:)];
        _swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:_swipeGestureRecognizer];
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandler:)];
        [self addGestureRecognizer:_tapGestureRecognizer];
        [self layoutBadge];
    }
    return self;
}

- (void)dealloc
{
    self.reuseIdentifier = nil;
    [_contentView release];
    [_containerView release];
    [_backgroundBadge release];
    [_labelBadge release];
    [_badgeValue release];
    [_badgeView release];
    [_swipeGestureRecognizer release];
    [_tapGestureRecognizer release];
    [_reserveObj release];
    [super dealloc];
}


#pragma mark - Properties getter/setter

- (UIView *)contentView
{
    if (_contentView == nil)
    {
        UIView *view = [[UIView alloc] init];
        view.frame = self.bounds;
        self.contentView = view;
        [view release];
    }
    return _contentView;
}

- (void)setContentView:(UIView *)contentView
{
    [_contentView removeFromSuperview];
    
    if (_contentView)
    {
        contentView.frame = _contentView.frame;
    }
    else
    {
        contentView.frame = self.bounds;
    }
    [contentView retain];
    [_contentView release];
    _contentView = contentView;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.containerView addSubview:contentView];
}

- (UIView *)containerView
{
    if (_containerView == nil)
    {
        UIView *view = [[UIView alloc] init];
        view.frame = self.bounds;
        view.backgroundColor = [UIColor clearColor];
        _containerView = view;
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _containerView;
}


- (UIImageView *)backgroundBadge
{
    if (_backgroundBadge == nil)
    {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.backgroundColor = [UIColor clearColor];
        _backgroundBadge = imageView;
    }
    return _backgroundBadge;
}

- (UILabel *)labelBadge
{
    if (_labelBadge == nil)
    {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:15];
        label.minimumFontSize = 10;
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        _labelBadge = label;
    }
    return _labelBadge;
}

- (void)setBadgeValue:(NSString *)badgeValue
{
    if ([_badgeValue isEqualToString:badgeValue])
    {
        return;
    }
    [badgeValue retain];
    [_badgeValue release];
    _badgeValue = badgeValue;
    self.labelBadge.text = _badgeValue;
    _badgeView.hidden = (_badgeValue == nil || _badgeValue.length == 0);
    [self layoutBadge];
}

#pragma mark - public methods

- (void)prepareForReuse
{
    self.tag = 0;
    self.alwaysHideCheckBox = NO;
    self.alpha = 1.0f;
    self.badgeValue = nil;
    self.backgroundColor = [UIColor clearColor];
    self.reserveObj = nil;
}

#pragma mark - private methods
- (void)layoutBadge
{
    [self.labelBadge sizeToFit];
    CGRect frame = self.labelBadge.frame;
    frame.size.width += 10;
    if (frame.size.width > 50)
    {
        frame.size.width = 50;
    }
    if (frame.size.width < 25)
    {
        frame.size.width = 25;
    }
    frame.size.height = 25;
    frame.origin.x = self.frame.size.width - floorf((float)frame.size.width / 2);
    frame.origin.y = - floorf((float)frame.size.height / 2);
    _badgeView.frame = frame;
    frame.size.width -= 10;
    self.labelBadge.frame = _badgeView.bounds;
    self.labelBadge.textAlignment = NSTextAlignmentCenter;
    self.backgroundBadge.frame = _badgeView.bounds;
    self.labelBadge.center = self.backgroundBadge.center;
    [self.containerView bringSubviewToFront:_badgeView];
}

- (UIImage *)cloneCellImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Gesture Handler
- (void)swipeGestureHandler:(UISwipeGestureRecognizer *)swipeGesture
{

}

-(void)tapGestureHandler:(UITapGestureRecognizer *)tapGesture
{

}

@end
