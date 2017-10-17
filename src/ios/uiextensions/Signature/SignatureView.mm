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

#import "SignatureView.h"
#import "UIExtensionsManager+Private.h"
#import "UIExtensionsManager.h"

@implementation FSPSICallbackImp

- (id)initWithSigView:(SignatureView *)view {
    self = [super init];
    if (self) {
        // Initialization code
        self.sigView = view;
    }
    return self;
}

- (void)refresh:(FSPSI *)PSIHandle Rect:(FSRectF *)flushRect {
    [self.sigView invalidateRect:flushRect];
}

@end

@interface SignatureView ()
@property (nonatomic, strong) FSPSI *psiHandler;
@property (nonatomic, assign) int dibWidth;
@property (nonatomic, assign) int dibHeight;
@property (nonatomic, assign) CGRect nextRect;
@property (nonatomic, assign) BOOL beDrawing;
@property (nonatomic, strong) NSData *tempData;
@property (nonatomic, assign) CGRect tempRect;
@end

@implementation SignatureView

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialization code
        self.opaque = NO;
        self.frame = CGRectMake(0, 64, SCREENWIDTH, SCREENHEIGHT - 64);
        if (DEVICE_iPHONE) {
            self.frame = CGRectMake(0, 64, STYLE_CELLHEIHGT_IPHONE, STYLE_CELLWIDTH_IPHONE - 64);
        }
        self.backgroundColor = [UIColor whiteColor];
        self.dibWidth = MAX(SCREENWIDTH, SCREENHEIGHT);
        self.dibHeight = MAX(SCREENWIDTH, SCREENHEIGHT);
        self.tempData = nil;

        [self initCanvas];

        dibBuf = malloc(self.dibWidth * self.dibHeight * 4);
        self.dib = [[FSBitmap alloc] initWithWidth:self.dibWidth height:self.dibHeight format:e_dibArgb buffer:(unsigned char *) dibBuf pitch:0];
        memset(dibBuf, 0x00, self.dibWidth * self.dibHeight * 4);
    }
    return self;
}

- (void)initCanvas {
    self.psiHandler = [[FSPSI alloc] initWithWidth:self.dibWidth height:self.dibHeight simulate:YES];
    [self.psiHandler setOpacity:1.0];
    [self.psiHandler setColor:self.color];
    [self.psiHandler setDiameter:self.diameter / 0.2];
    FSPSICallback* callback = [[FSPSICallbackImp alloc] initWithSigView:self];
    [self.psiHandler setCallback:callback];

    self.rectSigPart = CGRectZero;
    self.hasChanged = NO;
}

- (void)reInitCanvas {
    memset(dibBuf, 0x00, self.dibWidth * self.dibHeight * 4);
    [self initCanvas];
    [self setNeedsDisplay];
}

- (void)dealloc {
    [self destoryEnvironment];
    free(dibBuf);
}

- (void)destoryEnvironment {
    self.dibWidth = self.dibHeight = 0;
    self.psiHandler = nil;
    self.dib = nil;
}

#pragma mark -  Outer Function
- (void)clear {
    [self reInitCanvas];
}

- (void)setColor:(int)aColor {
    [self.psiHandler setColor:aColor];
    _color = aColor;
}

- (void)setDiameter:(int)aDiameter {
    [self.psiHandler setDiameter:aDiameter / 0.2];
    _diameter = aDiameter;
}

- (void)setOpacity:(float)aOpacity {
    [self.psiHandler setOpacity:aOpacity];
}

- (void)loadSignature:(NSData *)dibData rect:(CGRect)rect {
    [self reInitCanvas];
    [dibData getBytes:dibBuf length:dibData.length];
    self.rectSigPart = rect;
    [self setNeedsDisplayInRect:self.rectSigPart];
}

- (UIImage *)getCurrentImage {
    return [self getCurrentImage:self.rectSigPart];
}

- (UIImage *)getCurrentImage:(CGRect)rect {
    int stride = rect.size.width * 4;
    int size = stride * rect.size.height;
    void *pBuf = malloc(size);
    memset(pBuf, 0x00, size);

    for (int i = 0; i < rect.size.height; i++) {
        memcpy((void *) ((long) pBuf + i * stride), (void *) ((long) dibBuf + ((int) self.dibWidth * 4) * (i + (int) rect.origin.y) + (int) rect.origin.x * 4), stride);
    }

    UIImage *img = [Utility dib2img:pBuf size:size dibWidth:rect.size.width dibHeight:rect.size.height withAlpha:YES];

    return img;
}

- (NSData *)getCurrentDib {
    return [NSData dataWithBytesNoCopy:dibBuf length:self.dibWidth * self.dibHeight * 4 freeWhenDone:NO];
}

- (void)invalidateRect:(FSRectF *)rect {
    [self invalidateRect:rect.left top:rect.top right:rect.right bottom:rect.bottom];
}

- (void)invalidateRect:(int)left top:(int)top right:(int)right bottom:(int)bottom {
    if (right - left == 0 || bottom - top == 0) {
        return;
    }
    self.nextRect = CGRectMake(left, top, (right - left), (bottom - top));
    self.nextRect = CGRectIntersection(self.nextRect, self.bounds);

    if (CGRectEqualToRect(self.rectSigPart, CGRectZero)) {
        self.rectSigPart = self.nextRect;
    } else {
        self.rectSigPart = CGRectUnion(self.rectSigPart, self.nextRect);
    }

    FSRenderer *renderer = [[FSRenderer alloc] initWithBitmap:self.dib rgbOrder:NO];
    FSRectI *clipRect = [[FSRectI alloc] init];
    [clipRect set:left top:top right:right bottom:bottom];
    FSBitmap *bitmap = [self.psiHandler getBitmap];
    FSMatrix *matrix = [[FSMatrix alloc] init];
    //The image is upside down, so the matrix should be reversed.
    [matrix set:[bitmap getWidth] b:0 c:0 d:-[bitmap getHeight] e:0 f:[bitmap getHeight]];
    [renderer startRenderBitmap:bitmap matrix:matrix clipRect:clipRect interpolation:0 pause:nil];
    [self setNeedsDisplayInRect:self.nextRect];
}

#pragma mark -  Touch function
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.beDrawing = YES;
    CGPoint pt = [[touches anyObject] locationInView:self];
    FSPointF *point = [[FSPointF alloc] init];
    [point set:pt.x y:pt.y];
    [self.psiHandler addPoint:point ptType:e_pointTypeMoveTo pressure:1];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.beDrawing) {
        CGPoint pt = [[touches anyObject] locationInView:self];
        FSPointF *point = [[FSPointF alloc] init];
        [point set:pt.x y:pt.y];
        [self.psiHandler addPoint:point ptType:e_pointTypeLineTo pressure:1];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint pt = [[touches anyObject] locationInView:self];
    FSPointF *point = [[FSPointF alloc] init];
    [point set:pt.x y:pt.y];
    [self.psiHandler addPoint:point ptType:e_pointTypeLineToCloseFigure pressure:1];
    self.beDrawing = NO;
    self.hasChanged = YES;

    //    NSLog(@"%d   %d", self.dibWidth, self.dibHeight);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)setHasChanged:(BOOL)hasChanged {
    _hasChanged = hasChanged;
    if (self.signHasChangedCallback) {
        self.signHasChangedCallback(hasChanged);
    }
}

#pragma mark -  Draw Function

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    rect = CGRectIntersection(rect, self.rectSigPart);
    if (rect.size.width > 0 && rect.size.height > 0) {
        UIImage *img = [self getCurrentImage:rect];
        [img drawInRect:rect];
    }
}

@end
