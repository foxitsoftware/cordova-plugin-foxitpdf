/**
 * Copyright (C) 2003-2018, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "InsertToolHandler.h"
#import "MenuControl.h"
#import "NoteDialog.h"
#import "UIExtensionsManager+Private.h"

@interface InsertToolHandler ()

@property (nonatomic, weak) FSPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, weak) UIExtensionsManager *extensionsManager;
@property (nonatomic, weak) TaskServer *taskServer;
@property (nonatomic, assign) BOOL isTextSelect;
@property (nonatomic, assign) int currentPageIndex;
@property (nonatomic, strong) FSPointF *currentPoint;
@property (nonatomic, assign) int startPosIndex;
@property (nonatomic, assign) int endPosIndex;
@property (nonatomic, strong) NSArray *arraySelectedRect;
@property (nonatomic, strong) FSRectF *currentEditPdfRect;
@property (nonatomic, strong) NSArray *colors;
@end

@implementation InsertToolHandler {
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        self.extensionsManager = extensionsManager;
        self.pdfViewCtrl = extensionsManager.pdfViewCtrl;
        self.taskServer = self.extensionsManager.taskServer;
        self.type = e_annotCaret;
    }
    return self;
}

- (int)getCharIndexAtPos:(int)pageIndex point:(CGPoint)point {
    FSPointF *dibPoint = [self.pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSPDFTextSelect *textPage = [Utility getTextSelect:self.pdfViewCtrl.currentDoc pageIndex:pageIndex];
    return [textPage getIndexAtPos:dibPoint.x y:dibPoint.y tolerance:0];
}

- (NSArray *)getCurrentSelectRects:(int)pageIndex {
    __block CGRect unionRect = CGRectZero;
    NSMutableArray *retArray = [NSMutableArray array];

    FSPDFTextSelect *textPage = [Utility getTextSelect:self.pdfViewCtrl.currentDoc pageIndex:pageIndex];
    NSArray *array = [Utility getTextRects:textPage start:MIN(_startPosIndex, _endPosIndex) count:ABS(_endPosIndex - _startPosIndex) + 1];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGRect rect = [[obj objectAtIndex:0] CGRectValue];
        [retArray addObject:[NSValue valueWithCGRect:rect]];
        if (CGRectEqualToRect(unionRect, CGRectZero)) {
            unionRect = rect;
        } else {
            unionRect = CGRectUnion(unionRect, rect);
        }

    }];
    self.currentEditPdfRect = [Utility normalizeFSRect:[Utility CGRect2FSRectF:unionRect]];
    return retArray;
}

- (void)getTheCurrentRowPdfRectWithCurrentSelectedIndex:(int)index pageIndex:(int)pageIndex {
    FSRectF *selectCharpdfRect = self.currentEditPdfRect;
    int firstIndex = index;
    FSPDFTextSelect *textPage = [Utility getTextSelect:self.pdfViewCtrl.currentDoc pageIndex:pageIndex];
    for (int i = index; i > -1; i--) {
        NSArray *array = [Utility getTextRects:textPage start:i count:1];
        __block CGRect unionRect = CGRectZero;
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect rect = [[obj objectAtIndex:0] CGRectValue];
            if (CGRectEqualToRect(unionRect, CGRectZero)) {
                unionRect = rect;
            } else {
                unionRect = CGRectUnion(unionRect, rect);
            }
        }];
        self.currentEditPdfRect = [Utility normalizeFSRect:[Utility CGRect2FSRectF:unionRect]];
        if (selectCharpdfRect.top < self.currentEditPdfRect.bottom) {
            firstIndex = i;
            break;
        }
        if (i == 0) {
            firstIndex = i;
            break;
        }
    }

    int lastIndex = index;
    int pageCharCount = [textPage getCharCount];
    for (int i = index; i < pageCharCount; i++) {
        NSArray *array = [Utility getTextRects:textPage start:i count:1];
        if (array.count == 0 || !array) {
            break;
        }
        __block CGRect unionRect = CGRectZero;
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect rect = [[obj objectAtIndex:0] CGRectValue];
            if (CGRectEqualToRect(unionRect, CGRectZero)) {
                unionRect = rect;
            } else {
                unionRect = CGRectUnion(unionRect, rect);
            }
        }];
        self.currentEditPdfRect = [Utility normalizeFSRect:[Utility CGRect2FSRectF:unionRect]];
        if (selectCharpdfRect.bottom > self.currentEditPdfRect.top) {
            lastIndex = i;
            break;
        }
    }

    __block CGRect unionRect = CGRectZero;

    int startIndex = firstIndex == index ? index : firstIndex + 1;
    int endIndex = lastIndex == index ? index : lastIndex - 1;
    NSArray *array = [Utility getTextRects:textPage start:MIN(startIndex, endIndex) count:ABS(endIndex - startIndex) + 1];

    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGRect rect = [[obj objectAtIndex:0] CGRectValue];
        unionRect = CGRectZero;
        if (CGRectEqualToRect(unionRect, CGRectZero)) {
            unionRect = rect;
        } else {
            unionRect = CGRectUnion(unionRect, rect);
        }
    }];
    self.currentEditPdfRect = [Utility normalizeFSRect:[Utility CGRect2FSRectF:unionRect]];
}

- (void)clearSelection {
    self.isEdit = NO;
    self.startPosIndex = -1;
    self.endPosIndex = -1;
    self.arraySelectedRect = nil;
    if ([self.extensionsManager.menuControl isMenuVisible]) {
        [self.extensionsManager.menuControl hideMenu];
    }
    [self.pdfViewCtrl refresh:self.currentPageIndex needRender:NO];
}

- (NSString *)getName {
    return Tool_Insert;
}

- (BOOL)isEnabled {
    return YES;
}

- (void)onActivate {
}

- (void)onDeactivate {
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:[self.pdfViewCtrl getPageView:pageIndex]];
    FSPointF *fspoint = [self.pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    FSPDFTextSelect *textPage = [Utility getTextSelect:self.pdfViewCtrl.currentDoc pageIndex:pageIndex];
    self.currentPageIndex = pageIndex;
    BOOL isHorizontal = YES;
    BOOL isLeftToRight = YES;
    BOOL isTopToBottom = YES;
    FSRotation textRotation = e_rotationUnknown;

    int index = [self getCharIndexAtPos:pageIndex point:point];
    [self clearSelection];
    if (index > -1) {
        self.isEdit = YES;
        self.isTextSelect = YES;
        self.startPosIndex = index;
        self.endPosIndex = index;
        [self.pdfViewCtrl refresh:pageIndex needRender:NO];

        for (int i = 0; i < [textPage getTextRectCount:index count:1]; i++) {
            textRotation = [textPage getBaselineRotation:i];
            if (textRotation == e_rotationUnknown)
                continue;
            isLeftToRight = (textRotation == e_rotation0 || textRotation == e_rotation270);
            isTopToBottom = (textRotation == e_rotation0 || textRotation == e_rotation90);
            isHorizontal = (textRotation == e_rotation0 || textRotation == e_rotation180);
            break;
        }
    } else {
        self.isTextSelect = NO;
        self.isEdit = YES;
        self.startPosIndex = -1;
        self.endPosIndex = -1;
        self.currentEditPdfRect = [Utility makeFSRectWithLeft:0 top:0 right:0 bottom:0];
        return YES;
    }

    for (int i = 0; i < 4; i++) {
        __block CGRect unionRect = CGRectZero;
        int startIndex = self.startPosIndex - i;
        int endIndex = self.endPosIndex - i;
        NSArray *array = [Utility getTextRects:textPage start:MIN(startIndex, endIndex) count:ABS(endIndex - startIndex) + 1];

        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect rect = [[obj objectAtIndex:0] CGRectValue];
            if (CGRectEqualToRect(unionRect, CGRectZero)) {
                unionRect = rect;
            } else {
                unionRect = CGRectUnion(unionRect, rect);
            }
        }];
        self.currentEditPdfRect = [Utility normalizeFSRect:[Utility CGRect2FSRectF:unionRect]];
        if (unionRect.origin.x != 0 && unionRect.origin.y != 0) {
            self.startPosIndex = self.startPosIndex - i;
            self.endPosIndex = self.endPosIndex - i;
            break;
        }
    }

    FSRectF *rectChar = self.currentEditPdfRect;
    if (ABS(rectChar.left - rectChar.right) < 1E-5 || ABS(rectChar.top - rectChar.bottom) < 1E-5) {
        return YES;
    }

    [self getTheCurrentRowPdfRectWithCurrentSelectedIndex:index pageIndex:pageIndex];
    FSRectF *rectWord = self.currentEditPdfRect;
    if (ABS(rectWord.left - rectWord.right) < 1E-5 || ABS(rectWord.top - rectWord.bottom) < 1E-5) {
        return YES;
    }

    float width, height, left, top;
    if (isHorizontal) {
        height = (rectWord.top - rectWord.bottom) * (8.5 / 10.0);
        width = height * (2.0 / 3.0);
        left = fspoint.x > ((rectChar.left + rectChar.right) / 2.0) ? rectChar.right - (width / 2.0) : rectChar.left - (width / 2.0);
        if (isTopToBottom) {
            top = rectWord.top - (height * (7.5 / 10.0));
        } else {
            top = rectWord.bottom + (height * (7.5 / 10.0)) + height;
        }
    } else {
        width = (rectWord.right - rectWord.left) * (8.5 / 10.0);
        height = width * (2.0 / 3.0);
        top = fspoint.y > ((rectChar.top + rectChar.bottom) / 2.0) ? rectChar.top + (height / 2.0) : rectChar.bottom + (height / 2.0);
        if (isLeftToRight) {
            left = rectWord.left + width * (7.5 / 10.0);
        } else {
            left = rectWord.right - width * (7.5 / 10.0) - width;
        }
    }

    NoteDialog *noteDialog = [[NoteDialog alloc] init];
    [noteDialog show:nil replyAnnots:nil title:FSLocalizedString(@"kInsertText")];
    self.currentVC = noteDialog;
    typeof(self) __weak weakSelf = self;
    noteDialog.noteEditDone = ^(NoteDialog *dialog) {
        weakSelf.currentVC = nil;
        FSPDFPage *page = [weakSelf.pdfViewCtrl.currentDoc getPage:pageIndex];
        if (!page)
            return;
        FSRectF *dibRect = [Utility makeFSRectWithLeft:left top:top right:(left + width) bottom:(top - height)];
        FSCaret *annot = (FSCaret *) [page addAnnot:e_annotCaret rect:dibRect];
        annot.NM = [Utility getUUID];
        annot.author = [SettingPreference getAnnotationAuthor];
        annot.color = [weakSelf.extensionsManager getPropertyBarSettingColor:weakSelf.type];
        annot.opacity = [weakSelf.extensionsManager getAnnotOpacity:weakSelf.type] / 100.0f;
        annot.subject = @"Insert Text";
        annot.contents = [dialog getContent];
        annot.intent = @"Insert Text";
        {
            FSPDFDictionary *dict = [annot getDict];
            int iRotation = 360 - textRotation * 90;
            [dict setAt:@"Rotate" object:[FSPDFObject createFromInteger:iRotation]];
            [annot resetAppearanceStream];
        }

        NSDate *now = [NSDate date];
        FSDateTime *time = [Utility convert2FSDateTime:now];
        [annot setCreationDateTime:time];
        [annot setModifiedDateTime:time];

        if (annot) {
            [[weakSelf.extensionsManager getAnnotHandlerByAnnot:annot] addAnnot:annot addUndo:YES];
        }
        [weakSelf clearSelection];
    };
    noteDialog.noteEditCancel = ^(NoteDialog *dialog) {
        weakSelf.currentVC = nil;
        [weakSelf clearSelection];
    };
    return YES;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (self != self.extensionsManager.currentToolHandler) {
        return NO;
    }
    return YES;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
    if (pageIndex != self.currentPageIndex) {
        return;
    }

    if (self.isEdit && self.isTextSelect) {
        if (self.startPosIndex == -1 || self.endPosIndex == -1) {
            return;
        }

        self.arraySelectedRect = [self getCurrentSelectRects:pageIndex];
        [self.arraySelectedRect enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect selfRect = [obj CGRectValue];
            FSRectF *docRect = [Utility CGRect2FSRectF:selfRect];
            CGRect pvRect = [self.pdfViewCtrl convertPdfRectToPageViewRect:docRect pageIndex:pageIndex];
            CGContextSetRGBFillColor(context, 0, 0, 1, 0.3);
            CGContextFillRect(context, pvRect);

            //draw the drag dot
            if (idx == 0) {
                UIImage *dragDot = [UIImage imageNamed:@"annotation_dragdot.png"];
                CGRect leftCursor = CGRectMake((int) (pvRect.origin.x - 7.5), (int) (pvRect.origin.y - 12), 15, 17);
                [dragDot drawAtPoint:leftCursor.origin];
            }
            if (idx + 1 == self.arraySelectedRect.count) {
                UIImage *dragDot = [UIImage imageNamed:@"annotation_dragdot.png"];
                CGRect rightCursor = CGRectMake((int) (pvRect.origin.x + pvRect.size.width - 7.5), (int) (pvRect.origin.y + pvRect.size.height - 5), 15, 17);
                [dragDot drawAtPoint:rightCursor.origin];
            }
        }];
    }
}

@end
