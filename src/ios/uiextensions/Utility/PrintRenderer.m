//
//  PrintRenderer.m
//  FoxitApp
//
//  Created by Michael Xie on 5/22/12.
//  Copyright (c) 2012 Foxit. All rights reserved.
//

#import "PrintRenderer.h"
#import "Utility.h"

@implementation PrintRenderer

- (id)initWithDocument:(FSPDFDoc *)document {
    if (self = [super init]) {
        _document = document;
    }
    return self;
}

- (NSInteger)numberOfPages {
    return [self.document getPageCount];
}

- (void)drawPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)printableRect {
    FSPDFPage *page = nil;
    @try {
        page = [self.document getPage:(int) pageIndex];
    } @catch (NSException *exception) {
        return;
    }
    if (page == nil) {
        return;
    }
    CGRect contentRect = self.paperRect;
    int height = contentRect.size.height;
    CGSize size = CGSizeMake([page getWidth], [page getHeight]);
    int width = height * size.width / size.height;
    if (width > contentRect.size.width) {
        width = contentRect.size.width;
        height = width * size.height / size.width;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    [Utility printPage:page inContext:context inRect:CGRectMake(printableRect.origin.x, printableRect.origin.y, width, height) shouldDrawAnnotation:YES];

}

@end
