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
#import "StampToolHandler.h"
#import "UIExtensionsManager+Private.h"

@interface StampToolHandler ()

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

- (CGRect) getStampDefaultRect:(int) pageIndex
{
    FSRectF* pdfRect = [[FSRectF alloc] init];
    [pdfRect set:0 bottom:0 right:STANDARD_STAMP_WIDTH top:STANDARD_STAMP_HEIGHT];
    
    return [_pdfViewCtrl convertPdfRectToPageViewRect:pdfRect pageIndex:pageIndex];
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer
{
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer
{
    UIView* pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    
    
    CGRect  stampDefRect = [self getStampDefaultRect:pageIndex];
    float width = stampDefRect.size.width; //STANDARD_STAMP_WIDTH*scale;
    float height = stampDefRect.size.height; //width * STANDARD_STAMP_HEIGHT / STANDARD_STAMP_WIDTH;
    
    CGRect rect = CGRectMake(point.x - width/2.0, point.y - height/2.0, width, height);
    FSPDFPage* page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
    if (!page) return;
    float pageWidth = [_pdfViewCtrl getPageViewWidth:pageIndex];
    float pageHeight = [_pdfViewCtrl getPageViewHeight:pageIndex];
    
    if (pageHeight - (rect.origin.y + rect.size.height) < 0) {
        rect.origin.y = pageHeight - height;
    }
    if (rect.origin.y < 0) {
        rect.origin.y = 0;
    }
    
    if (pageWidth - (rect.origin.x + rect.size.width) < 0) {
        rect.origin.y = pageWidth - width;
    }
    if (rect.origin.x < 0) {
        rect.origin.x = 0;
    }
    
    FSRectF* pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:rect pageIndex:pageIndex];
    FSStamp* annot = (FSStamp*)[page addAnnot:e_annotStamp rect:pdfRect];
    annot.NM = [Utility getUUID];
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.createDate = [NSDate date];
    annot.modifiedDate = [NSDate date];
    annot.flags = e_annotFlagPrint;
    annot.icon = _extensionsManager.stampIcon;
    
    Task *task = [[[Task alloc] init] autorelease];
    task.run = ^(){
        [_extensionsManager onAnnotAdded:page annot:annot];
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    };
    [_taskServer executeSync:task];
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
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    return NO;
}

-(void)onDraw:(int)pageIndex inContext:(CGContextRef)context
{
}

@end
