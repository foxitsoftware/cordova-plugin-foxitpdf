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
#import <FoxitRDK/FSPDFViewControl.h>

#import "AlertView.h"

@implementation AlertView

@synthesize buttonClickedHandler = _buttonClickedHandler;

- (id)init
{
    if (self = [super init])
    {
        self.delegate = self;
        self.outerDelegate = nil;
    }
    return self;
}

-(void)show
{
    [super show];
}

-(void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonClickHandler:(AlertViewButtonClickedHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... 
{
    if (self = [super initWithTitle:title==nil?nil:NSLocalizedString(title, nil) message:message==nil?nil:NSLocalizedString(message, nil) delegate:self cancelButtonTitle:cancelButtonTitle==nil?nil:NSLocalizedString(cancelButtonTitle, nil) otherButtonTitles:nil])
    {
        if (otherButtonTitles != nil)
        {
            [self addButtonWithTitle:NSLocalizedString(otherButtonTitles, nil)];
            va_list args;
            va_start(args, otherButtonTitles);
            NSString *otherButton = va_arg(args, NSString*);
            while (otherButton != nil)
            {
                [self addButtonWithTitle:otherButton];
                otherButton = va_arg(args, NSString*);
            }
            va_end(args);
        }
        
        _buttonClickedHandler = [handler copy];
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message style:(UIAlertViewStyle)style buttonClickHandler:(AlertViewButtonClickedHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    if (self = [super initWithTitle:title==nil?nil:NSLocalizedString(title, nil) message:message==nil?nil:NSLocalizedString(message, nil) delegate:self cancelButtonTitle:cancelButtonTitle==nil?nil:NSLocalizedString(cancelButtonTitle, nil) otherButtonTitles:nil])
    {
        if (style == UIAlertViewStylePlainTextInput)
            [self setAlertViewStyle:style];
        
        if (otherButtonTitles != nil)
        {
            [self addButtonWithTitle:NSLocalizedString(otherButtonTitles, nil)];
            va_list args;
            va_start(args, otherButtonTitles);
            NSString *otherButton = va_arg(args, NSString*);
            while (otherButton != nil)
            {
                [self addButtonWithTitle:otherButton];
                otherButton = va_arg(args, NSString*);
            }
            va_end(args);
        }
        
        _buttonClickedHandler = [handler copy];
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    if (self = [super initWithTitle:title==nil?nil:NSLocalizedString(title, nil) message:message==nil?nil:NSLocalizedString(message, nil) delegate:self cancelButtonTitle:cancelButtonTitle==nil?nil:NSLocalizedString(cancelButtonTitle, nil) otherButtonTitles:nil])
    {
        if (otherButtonTitles != nil)
        {
            [self addButtonWithTitle:NSLocalizedString(otherButtonTitles, nil)];
            va_list args;
            va_start(args, otherButtonTitles);
            NSString *otherButton = va_arg(args, NSString*);
            while (otherButton != nil)
            {
                [self addButtonWithTitle:otherButton];
                otherButton = va_arg(args, NSString*);
            }
            va_end(args);
        }
        
        self.outerDelegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [_buttonClickedHandler release];
    self.delegate = nil;
    self.outerDelegate = nil;
    [super dealloc];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_buttonClickedHandler)
    {
        _buttonClickedHandler(self, (int)buttonIndex);
    }
    if (self.outerDelegate)
    {
        [self.outerDelegate alertView:alertView clickedButtonAtIndex:buttonIndex];
    }
}

- (void)setTitle:(NSString *)title
{
    super.title = title==nil?nil:NSLocalizedString(title, nil);
}

- (void)setMessage:(NSString *)message
{
    super.message = message==nil?nil:NSLocalizedString(message, nil);
}

- (NSInteger)addButtonWithTitle:(NSString *)title
{
    return [super addButtonWithTitle:title==nil?nil:NSLocalizedString(title, nil)];
}

@end

@implementation InputAlertView

@synthesize buttonClickedHandler = _buttonClickedHandler;

- (id)init
{
    if (self = [super init])
    {
        self.delegate = self;
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonClickHandler:(AlertViewButtonClickedHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    if (self = [super initWithTitle:title==nil?nil:NSLocalizedString(title, nil) message:message==nil?nil:NSLocalizedString(message, nil) delegate:self cancelButtonTitle:cancelButtonTitle==nil?nil:NSLocalizedString(cancelButtonTitle, nil) otherButtonTitles:nil])
    {
        //APPDELEGATE.alertveiw = self;
        if (otherButtonTitles != nil)
        {
            [self addButtonWithTitle:NSLocalizedString(otherButtonTitles, nil)];
            va_list args;
            va_start(args, otherButtonTitles);
            NSString *otherButton = va_arg(args, NSString*);
            while (otherButton != nil)
            {
                [self addButtonWithTitle:otherButton];
                otherButton = va_arg(args, NSString*);
            }
            va_end(args);
        }
        
        _buttonClickedHandler = [handler copy];
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    NSAssert(NO, @"InputAlert MUST not call this. Use above instead.");
    return nil;
}

- (void)dealloc
{
    [_buttonClickedHandler release];
    self.delegate = nil;
    [super dealloc];
}

- (void)alertView:(TSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_buttonClickedHandler != nil)
    {
        _buttonClickedHandler(self, buttonIndex);
    }
}

- (void)setTitle:(NSString *)title
{
    super.title = title==nil?nil:NSLocalizedString(title, nil);
}

- (void)setMessage:(NSString *)message
{
    super.message = message==nil?nil:NSLocalizedString(message, nil);
}

- (NSInteger)addButtonWithTitle:(NSString *)title
{
    return [super addButtonWithTitle:title==nil?nil:NSLocalizedString(title, nil)];
}

@end
