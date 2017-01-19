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
#import "UIExtensionsManager.h"
#import "UIExtensionsManager+Private.h"

@interface EraseToolHandler : NSObject<IToolHandler>
{
    int _radius;
    BOOL _isChanged;
    CGRect _allRect;
    int _changedPointCount;
    
    
    BOOL _isBegin;
    BOOL _isMoving;
    BOOL _isZooming;
    CGPoint _lastPoint;
    CGRect _lastRect;
    FSRectF* _penclRect;
}
@property (nonatomic, assign)enum FS_ANNOTTYPE type;
@property (nonatomic, assign) NSValue *lastBeginValue;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager*)extensionsManager;

@end
