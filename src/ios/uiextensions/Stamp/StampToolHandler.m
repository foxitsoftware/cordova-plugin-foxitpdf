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

#import "StampToolHandler.h"
#import "UIExtensionsManager+Private.h"

#define STANDARD_STAMP_WIDTH 200
#define STANDARD_STAMP_HEIGHT 60

@interface StampToolHandler ()
@property (nonatomic, strong) FSStamp *annot;
@property (nonatomic, strong) FSRectF *currentRect;

@end

@implementation StampToolHandler {
    UIExtensionsManager* _extensionsManager;
    FSPDFViewCtrl*  _pdfViewCtrl;
    TaskServer* _taskServer;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager
{
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        [_extensionsManager registerToolHandler:self];
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        _type = e_annotStamp;
    }
    return self;
}

-(NSString*)getName
{
    return Tool_Stamp;
}

-(BOOL)isEnabled
{
    return YES;
}

-(void)onActivate
{
}

-(void)onDeactivate
{
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer
{
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer
{
    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer
{
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
    {
        return YES;
    }
    return NO;
    
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet*)touches withEvent:(UIEvent*)event
{
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    CGRect pageRect = [pageView frame];
    CGSize size = pageRect.size;
    if(point.x > size.width || point.y > size.height || point.x < 0 || point.y < 0)
        return NO;
    CGRect tmpRect = pageView.frame;
    float scale = tmpRect.size.width/1000;
    float width = STANDARD_STAMP_WIDTH*scale;
    float height = STANDARD_STAMP_HEIGHT*scale;
    
    CGRect rect = CGRectMake(point.x - width/2.0, point.y - height/2.0, width, height);
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page) return NO;
    float pageWidth = [_pdfViewCtrl getPageViewWidth:pageIndex];
    float pageHeight = [_pdfViewCtrl getPageViewHeight:pageIndex];
    
    if (pageHeight - (rect.origin.y + rect.size.height) < 0) {
        rect.origin.y = pageHeight - height;
    }
    if (rect.origin.y < 0) {
        rect.origin.y = 0;
    }
    if (pageWidth - (rect.origin.x + rect.size.width) < 0) {
        rect.origin.x = pageWidth - width;
    }
    if (rect.origin.x < 0) {
        rect.origin.x = 0;
    }
    FSRectF* pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:rect pageIndex:pageIndex];
    self.currentRect = pdfRect;
    FSAnnot* annot = (FSAnnot*)[page addAnnot:e_annotStamp rect:pdfRect];
    if (!annot) {
        return NO;
    }
    self.annot = (FSStamp*)annot;
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    annot.flags = e_annotFlagPrint;
    annot.icon = _extensionsManager.stampIcon;
    annot.opacity = 0.5;
    [annot resetAppearanceStream];

    CGRect rect1 = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    [_pdfViewCtrl refresh:rect1 pageIndex:pageIndex];
    return YES;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (pageIndex != self.annot.pageIndex) {
        return NO;
    }
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    CGRect tmpRect = pageView.frame;
    float scale = tmpRect.size.width/1000;
    float width = STANDARD_STAMP_WIDTH*scale;
    float height = STANDARD_STAMP_HEIGHT*scale;
    CGRect rect = CGRectMake(point.x - width/2.0, point.y - height/2.0, width, height);
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page) return;
    float pageWidth = [_pdfViewCtrl getPageViewWidth:pageIndex];
    float pageHeight = [_pdfViewCtrl getPageViewHeight:pageIndex];
    
    if (pageHeight - (rect.origin.y + rect.size.height) <= 0) {
        rect.origin.y = pageHeight - height;
    }
    if (rect.origin.y < 0) {
        rect.origin.y = 0;
    }
    if (pageWidth - (rect.origin.x + rect.size.width) <= 0) {
        rect.origin.x = pageWidth - width;
    }
    if (rect.origin.x < 0) {
        rect.origin.x = 0;
    }
    FSRectF* pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:rect pageIndex:pageIndex];
    self.currentRect = pdfRect;
    self.annot.fsrect = pdfRect;
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:pdfRect pageIndex:pageIndex];
    [_pdfViewCtrl refresh:newRect pageIndex:pageIndex];
    return YES;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return [self onTouchEndOrCancelled:pageIndex];
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return [self onTouchEndOrCancelled:pageIndex];
}

- (BOOL)onTouchEndOrCancelled:(int)pageIndex
{
    self.annot.opacity = 1;
    self.annot.fsrect = _currentRect;
    [self.annot resetAppearanceStream];
    id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByType:self.type];
    [annotHandler addAnnot:self.annot addUndo:YES];
    return  YES;
}

-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context
{
}

@end
