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
#import "UIExtensionsManager+Private.h"
#import "PanelController.h"
#import "PanelHost.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import "Masonry.h"
#import "AnnotationPanel.h"
#import "OutlinePanel.h"
#import "ReadingBookmarkPanel.h"

static PanelController* currentPanelController = nil;

PanelController* getCurrentPanelController()
{
    return currentPanelController;
}

@implementation PanelController {
    UIControl* _maskView;
    UIView* _superView;
    FSPDFViewCtrl* _pdfViewControl;
    UIExtensionsManager* _extensionsManager;
    AnnotationPanel* annotationPanel;
    OutlinePanel* outlinePanel;
    ReadingBookmarkPanel* bookmarkPanel;
}

-(void)dealloc
{
    [_panel release];
    [super dealloc];
}

-(instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        currentPanelController = self;
        _superView = extensionsManager.pdfViewCtrl;
        _pdfViewControl = extensionsManager.pdfViewCtrl;
        _extensionsManager = extensionsManager;
        self.panel = [[[PanelHost alloc] init] autorelease];
        self.panel.contentView.backgroundColor = [UIColor whiteColor];
        CGRect screenFrame = [UIScreen mainScreen].bounds;
        if (DEVICE_iPHONE)
        {
            self.panel.contentView.frame = CGRectMake(0, 0, screenFrame.size.width, screenFrame.size.height);
        }
        else
        {
            self.panel.contentView.frame = CGRectMake(0, 0, 300, screenFrame.size.height);
        }
        
        self.panelListeners = [[[NSMutableArray alloc] init] autorelease];
        
        // mask view
        _maskView = [[UIControl alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
        
        [_superView addSubview:self.panel.contentView];
        self.panel.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        self.isHidden = YES;
        
        
        //Load annotation panel
        annotationPanel = [[[AnnotationPanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self] autorelease];
        [annotationPanel load];

        //load outline panel
        outlinePanel = [[[OutlinePanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self] autorelease];
        [outlinePanel load];
        
        //load bookmark panel
        bookmarkPanel = [[[ReadingBookmarkPanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self] autorelease];
        [bookmarkPanel load];

    }
    return self;
}

-(void)setIsHidden:(BOOL)isHidden
{
    if (_isHidden == isHidden) {
        return;
    }
    _isHidden = isHidden;
    if (_isHidden)
    {
        [UIView animateWithDuration:0.4 animations:^{
            _maskView.alpha = 0.1f;
        } completion:^(BOOL finished) {
            
            [_maskView removeFromSuperview];
        }];
        
        CGRect newFrame = self.panel.contentView.frame;
        
        newFrame.origin.x = -self.panel.contentView.frame.size.width;
        
        [UIView animateWithDuration:0.4 animations:^{
            self.panel.contentView.frame = newFrame;
            
            [self.panel.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(_superView.mas_top).offset(0);
                make.bottom.equalTo(_superView.mas_bottom).offset(0);
                if (DEVICE_iPHONE) {
                    make.right.equalTo(_superView.mas_left).offset(0);
                    make.width.mas_equalTo(-newFrame.origin.x);
                }
                else
                {
                    make.right.equalTo(_superView.mas_left).offset(0);
                    make.width.mas_equalTo(300);
                }
            }];
            
        } completion:^(BOOL finished) {
            self.panel.contentView.hidden = _isHidden;
        }];
        
    }
    else
    {
        _maskView.frame = [UIScreen mainScreen].bounds;
        _maskView.backgroundColor = [UIColor blackColor];
        _maskView.alpha = 0.3f;
        [_maskView addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
        [_superView insertSubview:_maskView belowSubview:self.panel.contentView];
        
        [_maskView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_maskView.superview.mas_left).offset(0);
            make.right.equalTo(_maskView.superview.mas_right).offset(0);
            make.top.equalTo(_maskView.superview.mas_top).offset(0);
            make.bottom.equalTo(_maskView.superview.mas_bottom).offset(0);
        }];
        
        CGRect newFrame = self.panel.contentView.frame;
        
        if (DEVICE_iPHONE)
        {
            newFrame.origin.x = 0;
        }
        else
        {
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                newFrame.origin.x = [UIScreen mainScreen].bounds.size.height - self.panel.contentView.frame.size.width;
            }
            else
            {
                newFrame.origin.x = [UIScreen mainScreen].bounds.size.width - self.panel.contentView.frame.size.width;
            }
        }
        
        self.panel.contentView.hidden = _isHidden;
        [UIView animateWithDuration:0.4 animations:^{
            self.panel.contentView.frame = newFrame;
            [self.panel.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(_superView.mas_top).offset(0);
                make.bottom.equalTo(_superView.mas_bottom).offset(0);
                if (DEVICE_iPHONE) {
                    make.left.equalTo(_superView.mas_left).offset(0);
                    make.right.equalTo(_superView.mas_right).offset(0);
                }
                else
                {
                    make.left.equalTo(_superView.mas_left).offset(0);
                    make.width.mas_equalTo(300);
                }
            }];
        } completion:^(BOOL finished) {
        }];
    }
    for (id<IPanelChangedListener> listener in self.panelListeners) {
        if ([listener respondsToSelector:@selector(onPanelChanged:)]) {
            [listener onPanelChanged:_isHidden];
        }
    }
}


-(void)dismiss:(id)sender
{
    self.isHidden = YES;
}

-(void)registerPanelChangedListener:(id<IPanelChangedListener>)listener
{
    if (self.panelListeners) {
        [self.panelListeners addObject:listener];
    }
}

-(void)unregisterPanelChangedListener:(id<IPanelChangedListener>)listener
{
    if ([self.panelListeners containsObject:listener]) {
        [self.panelListeners removeObject:listener];
    }
}

-(void)reloadReadingBookmarkPanel
{
    [bookmarkPanel reloadData];
}

@end
