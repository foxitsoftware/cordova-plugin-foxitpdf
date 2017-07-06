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

#import "MenuControl.h"
#import <UIKit/UIKit.h>
#import "MenuItem.h"
#import "ReplyTableViewController.h"

@interface MenuControl()
@property (nonatomic,strong)UIMenuController * menuControl;
@end

@implementation MenuControl {
    FSPDFViewCtrl* _pdfViewCtrl;
    UIExtensionsManager* _extensionsManager;
    UILongPressGestureRecognizer *_longpressGesture;
    UIPanGestureRecognizer* _panGesture;
    UITapGestureRecognizer* _tapGesture;

}


- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    [_extensionsManager onPan:recognizer];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer
{
    if (recognizer == _tapGesture || recognizer == _longpressGesture)
        return YES;
    if (recognizer == _panGesture) {
        return [_extensionsManager onShouldBegin:recognizer];
    }
    return [super gestureRecognizerShouldBegin:recognizer];
}

- (void)willHideMenu {

}

- (id)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self)
    {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = _extensionsManager.pdfViewCtrl;
        self.menuControl = [UIMenuController sharedMenuController];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willHideMenu)
                                                     name:UIMenuControllerWillHideMenuNotification
                                                   object:nil];

        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        [self addGestureRecognizer:_panGesture];
    }
    return self;
}

- (void)setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated
{
    if (menuVisible != [self isMenuVisible]) {
        [self.menuControl setMenuVisible:menuVisible animated:animated];
    }
    if (!menuVisible) {
        self.frame = CGRectZero;
        [self resignFirstResponder];
    }
}

- (void)update
{
    [self.menuControl update];
}

- (BOOL)isMenuVisible
{
    return self.menuControl.isMenuVisible || !CGRectEqualToRect(self.frame, CGRectZero);
}

- (void)hideMenu
{
    [self setMenuVisible:NO animated:YES];
}

- (void)setRect:(CGRect)rect
{
    [self setRect:rect margin:10];
}

- (void)setRect:(CGRect)rect margin:(float)margin
{
    self.frame = CGRectInset(rect, -35, -35);
    [[_pdfViewCtrl getDisplayView] insertSubview:self atIndex:0];
    [self.menuControl setTargetRect:CGRectInset(self.bounds, 35-margin, 35-margin) inView:self];
}

- (void)showMenu
{
    FSAnnot *annot = _extensionsManager.currentAnnot;
    if (annot) {
        CGRect pvRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
        CGRect dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:pvRect pageIndex:annot.pageIndex];
        if ((dvRect.origin.x + dvRect.size.width) <= 0
            || dvRect.origin.y + dvRect.size.height <= 0
            || dvRect.origin.x > SCREENWIDTH
            || dvRect.origin.y > SCREENHEIGHT) {
            return;
        }
    }
    
    if (![[self topViewController] isKindOfClass:[ReplyTableViewController class]] && ![[self topViewController] isKindOfClass:[UIActivityViewController class]])
    {
        [self becomeFirstResponder];
        
        NSMutableArray* menuArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.menuItems.count; i ++) {
            MenuItem* mcItem = [self.menuItems objectAtIndex:i];
            UIMenuItem* menuItem = [[UIMenuItem alloc] initWithTitle:mcItem.title action:NSSelectorFromString([NSString stringWithFormat:@"magic_clicked_%i", i])];
            [menuArray addObject:menuItem];
                    }
        [self.menuControl setMenuItems:menuArray];
        [self.menuControl setMenuVisible:YES animated:YES];
        
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    NSString* actionName = NSStringFromSelector(action);
    NSRange match = [actionName rangeOfString:@"magic_clicked_"];
    if (match.location == 0) {
        return YES;
    }
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    if ([super methodSignatureForSelector:sel]) {
        return [super methodSignatureForSelector:sel];
    }
    NSString* selName = NSStringFromSelector(sel);
    NSRange match = [selName rangeOfString:@"magic_clicked_"];
    if (match.location == 0) {
        return [super methodSignatureForSelector:@selector(onClickedAtIndex:)];
    }
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSString* selName = NSStringFromSelector([anInvocation selector]);
    NSString* prefix = @"magic_clicked_";
    NSRange match = [selName rangeOfString:prefix];
    if (match.location == 0) {
        [self onClickedAtIndex:[[selName substringFromIndex:prefix.length] intValue]];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (void)onClickedAtIndex:(int)index
{
    [self hideMenu];
    if (self.menuItems.count < index + 1) return;
    MenuItem* mcItem = [self.menuItems objectAtIndex:index];
    [mcItem.object performSelector:mcItem.action withObject:nil];
}


- (UIViewController*)topViewController
{
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController
{
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* nav = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:nav.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

@end
