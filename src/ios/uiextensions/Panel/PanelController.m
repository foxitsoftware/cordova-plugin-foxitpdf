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

#import "PanelController.h"
#import "AnnotationPanel.h"
#import "AttachmentPanel.h"
#import "Masonry.h"
#import "NSSet+containsAnyObjectInArray.h"
#import "OutlinePanel.h"
#import "PanelController+private.h"
#import "PanelHost.h"
#import "ReadingBookmarkPanel.h"
#import "UIButton+EnlargeEdge.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>
#import <UIKit/UIKit.h>

@interface FSPanelController ()

@property (nonatomic, strong) UIButton *cancelButton;

@end

@implementation FSPanelController {
    UIControl *_maskView;
    UIView *_superView;
    FSPDFViewCtrl *_pdfViewCtrl;
    UIExtensionsManager *_extensionsManager;
    AnnotationPanel *annotationPanel;
    OutlinePanel *outlinePanel;
    ReadingBookmarkPanel *bookmarkPanel;
    AttachmentPanel *attachmentPanel;
}

- (instancetype)initWithExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _superView = extensionsManager.pdfViewCtrl;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _extensionsManager = extensionsManager;

        NSArray<NSNumber *> *panelTypes = ({
            UIExtensionsModulesConfig *config = _extensionsManager.modulesConfig;
            NSMutableArray<NSNumber *> *panelTypes = @[].mutableCopy;
            if (config.loadReadingBookmark) {
                [panelTypes addObject:@(FSPanelTypeReadingBookmark)];
            }
            if (config.loadOutline) {
                [panelTypes addObject:@(FSPanelTypeOutline)];
            }
            if ([config.tools containsAnyObjectNotInArray:@[ Tool_Select, Tool_Eraser ]]) {
                [panelTypes addObject:@(FSPanelTypeAnnotation)];
            }
            if (config.loadAttachment) {
                [panelTypes addObject:@(FSPanelTypeAttachment)];
            }
            panelTypes;
        });

        CGSize size = CGSizeMake(DEVICE_iPHONE ? _pdfViewCtrl.bounds.size.width : 300, _pdfViewCtrl.bounds.size.height);
        self.panel = [[PanelHost alloc] initWithSize:size panelTypes:panelTypes];
        self.panel.contentView.backgroundColor = [UIColor whiteColor];
        CGRect screenFrame = _pdfViewCtrl.bounds;
        if (DEVICE_iPHONE) {
            self.panel.contentView.frame = CGRectMake(0, 0, screenFrame.size.width, screenFrame.size.height);
        } else {
            self.panel.contentView.frame = CGRectMake(0, 0, 300, screenFrame.size.height);
        }

        self.panelListeners = [[NSMutableArray alloc] init];

        // mask view
        _maskView = [[UIControl alloc] initWithFrame:_pdfViewCtrl.bounds];
        _maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;

        [_superView addSubview:self.panel.contentView];
        self.panel.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        self.isHidden = YES;

        //load attachment panel
        if ([panelTypes containsObject:@(FSPanelTypeAttachment)]) {
            attachmentPanel = [[AttachmentPanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self];
            [attachmentPanel load];
        }

        //Load annotation panel
        if ([panelTypes containsObject:@(FSPanelTypeAnnotation)]) {
            annotationPanel = [[AnnotationPanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self];
            [annotationPanel load];
        }
        //load outline panel
        if ([panelTypes containsObject:@(FSPanelTypeOutline)]) {
            outlinePanel = [[OutlinePanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self];
            [outlinePanel load];
            
        }
        //load bookmark panel
        if ([panelTypes containsObject:@(FSPanelTypeReadingBookmark)]) {
            bookmarkPanel = [[ReadingBookmarkPanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self];
            [bookmarkPanel load];
        }
    }
    return self;
}

- (void)setPanelHidden:(BOOL)isHidden type:(FSPanelType)type {
    if (isHidden) {
        [self removePanelOfType:type];
    } else {
        [self addPanelOfType:type];
    }
    if (self.panel.spaces.count > 0) {
        if (_cancelButton) {
            [_cancelButton removeFromSuperview];
        }
    } else {
        if (DEVICE_iPHONE) {
            [self.panel.contentView addSubview:self.cancelButton];
        }
    }
}

- (void)removePanelOfType:(FSPanelType)type {
    id<IPanelSpec> thePanel = nil;
    switch (type) {
        case FSPanelTypeOutline:
            thePanel = outlinePanel;
            outlinePanel = nil;
            break;
        case FSPanelTypeAnnotation:
            thePanel = annotationPanel;
            annotationPanel = nil;
            break;
        case FSPanelTypeAttachment:
            thePanel = attachmentPanel;
            attachmentPanel = nil;
            break;
        case FSPanelTypeReadingBookmark:
            thePanel = bookmarkPanel;
            bookmarkPanel = nil;
            break;
        default:
            break;
    }
    if (!thePanel) {
        return;
    }
    [self.panel removeSpec:thePanel];
    [self.panel reloadSegmentView];
}

- (void)addPanelOfType:(FSPanelType)type {
    switch (type) {
        case FSPanelTypeOutline:
            if (_extensionsManager.modulesConfig.loadOutline) {
                outlinePanel = [[OutlinePanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self];
                [outlinePanel load];
            }
            break;
        case FSPanelTypeAnnotation:
            if (_extensionsManager.modulesConfig.tools.count > 0) {
                annotationPanel = [[AnnotationPanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self];
                [annotationPanel load];
            }
            break;
        case FSPanelTypeAttachment:
            if (_extensionsManager.modulesConfig.loadAttachment) {
                attachmentPanel = [[AttachmentPanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self];
                [attachmentPanel load];
            }
            break;
        case FSPanelTypeReadingBookmark:
            if (_extensionsManager.modulesConfig.loadReadingBookmark) {
                bookmarkPanel = [[ReadingBookmarkPanel alloc] initWithUIExtensionsManager:_extensionsManager panelController:self];
                [bookmarkPanel load];
            }
            break;
        default:
            break;
    }
    [self.panel reloadSegmentView];
}

- (void)setIsHidden:(BOOL)isHidden {
    if (_isHidden == isHidden) {
        return;
    }
    _isHidden = isHidden;
    if (_isHidden) {
        [UIView animateWithDuration:0.4
            animations:^{
                _maskView.alpha = 0.1f;
            }
            completion:^(BOOL finished) {

                [_maskView removeFromSuperview];
            }];

        CGRect newFrame = self.panel.contentView.frame;

        newFrame.origin.x = -self.panel.contentView.frame.size.width;

        [UIView animateWithDuration:0.4
            animations:^{
                self.panel.contentView.frame = newFrame;

                [self.panel.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(_superView.mas_top).offset(0);
                    make.bottom.equalTo(_superView.mas_bottom).offset(0);
                    if (DEVICE_iPHONE) {
                        make.right.equalTo(_superView.mas_left).offset(0);
                        make.width.mas_equalTo(-newFrame.origin.x);
                    } else {
                        make.right.equalTo(_superView.mas_left).offset(0);
                        make.width.mas_equalTo(300);
                    }
                }];

            }
            completion:^(BOOL finished) {
                self.panel.contentView.hidden = _isHidden;
            }];

    } else {
        _maskView.frame = _pdfViewCtrl.bounds;
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

        if (DEVICE_iPHONE) {
            newFrame.origin.x = 0;
        } else {
            if (!OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                newFrame.origin.x = _pdfViewCtrl.bounds.size.height - self.panel.contentView.frame.size.width;
            } else {
                newFrame.origin.x = _pdfViewCtrl.bounds.size.width - self.panel.contentView.frame.size.width;
            }
        }

        self.panel.contentView.hidden = _isHidden;
        [UIView animateWithDuration:0.4
                         animations:^{
                             self.panel.contentView.frame = newFrame;
                             [self.panel.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
                                 make.top.equalTo(_superView.mas_top).offset(0);
                                 make.bottom.equalTo(_superView.mas_bottom).offset(0);
                                 if (DEVICE_iPHONE) {
                                     make.left.equalTo(_superView.mas_left).offset(0);
                                     make.right.equalTo(_superView.mas_right).offset(0);
                                 } else {
                                     make.left.equalTo(_superView.mas_left).offset(0);
                                     make.width.mas_equalTo(300);
                                 }
                             }];
                         }
                         completion:^(BOOL finished){
                         }];
    }
    for (id<IPanelChangedListener> listener in self.panelListeners) {
        if ([listener respondsToSelector:@selector(onPanelChanged:)]) {
            [listener onPanelChanged:_isHidden];
        }
    }
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 32, 12, 12)];
        [_cancelButton addTarget:self action:@selector(canelPanel:) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [_cancelButton setBackgroundImage:[UIImage imageNamed:@"panel_cancel"] forState:UIControlStateNormal];
        [_cancelButton setEnlargedEdge:10];
        [self.panel.contentView addSubview:_cancelButton];
    }
    return _cancelButton;
}

- (void)canelPanel:(UIButton *)button {
    self.isHidden = YES;
}

- (void)dismiss:(id)sender {
    self.isHidden = YES;
}

- (void)registerPanelChangedListener:(id<IPanelChangedListener>)listener {
    if (self.panelListeners) {
        [self.panelListeners addObject:listener];
    }
}

- (void)unregisterPanelChangedListener:(id<IPanelChangedListener>)listener {
    if ([self.panelListeners containsObject:listener]) {
        [self.panelListeners removeObject:listener];
    }
}

- (void)reloadReadingBookmarkPanel {
    [bookmarkPanel reloadData];
}

@end
