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

/** @brief The result search info. */
@interface SearchInfo : NSObject

@property (nonatomic,retain ) NSString       *snippet;
@property (nonatomic,assign ) int            keywordLocation;
@property (nonatomic,retain ) NSMutableArray *rects;
@property (nonatomic, retain) NSString       *rtText;
@property (nonatomic, assign) float          rtHeight;

@end

/** @brief All the found result for the current text search. */
@interface SearchResult : NSObject

@property (nonatomic,assign) int index;
@property (nonatomic,retain) NSMutableArray *infos;

@end
