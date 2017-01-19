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

#ifndef FoxitApp_FB_FileEnum_h
#define FoxitApp_FB_FileEnum_h

typedef  enum FileListType
{
    FileListType_Local = 0
} FileListType;

typedef enum DisplayStyle
{
    DetailStyle,
    ThumbStyle,
    
} DisplayStyle;

typedef void (^getFileListHandler)(NSMutableArray *fileList);
typedef void (^getThumbnailHandler)(UIImage *imageThumbnail, int pageIndex, NSString *pdfPath);

#endif