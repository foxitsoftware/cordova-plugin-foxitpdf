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
#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>
#import <UIKit/UIButton.h>
#import "SegmentView.h"

@class SegmentView;
@protocol IPanelSpec;
@interface PanelButton : UIButton

@property(nonatomic,assign)id<IPanelSpec> spec;

@end

/** @brief Panel UI implementation. */
@interface PanelHost : NSObject<SegmentDelegate>
{
    SegmentView *segmentView;
    
}
@property(nonatomic,retain) NSMutableArray *spaces;
@property(nonatomic,strong) id<IPanelSpec> currentSpace;
@property (nonatomic, strong) UIView* contentView;

-(void)addSpec:(id<IPanelSpec>)spec;
-(void)removeSpec:(id<IPanelSpec>)spec;
@end
