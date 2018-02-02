//
//  PrintRenderer.h
//  FoxitApp
//
//  Created by Michael Xie on 5/22/12.
//  Copyright (c) 2012 Foxit. All rights reserved.
//

#import <FoxitRDK/FSPDFObjC.h>
#import <UIKit/UIKit.h>

@interface PrintRenderer : UIPrintPageRenderer

@property (nonatomic, weak) FSPDFDoc *document;

// document not retained
- (id)initWithDocument:(FSPDFDoc *)document;

@end
