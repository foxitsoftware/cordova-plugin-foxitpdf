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


#define TAG_GROUP_FILE 1
#define TAG_GROUP_FORM 7

#define TAG_ITEM_FILEINFO 10
#define TAG_ITEM_RESETFORM 24
#define TAG_ITEM_IMPORTFORM 25
#define TAG_ITEM_EXPORTFORM 26

#define EDIT_ITEM_STROKEOUT 8
#define EDIT_ITEM_UNDERLINE 10
#define EDIT_ITEM_HIGHLIGHT 12
#define EDIT_ITEM_NOTE 14
#define EDIT_ITEM_RECTANGLE 2
#define EDIT_ITEM_FREETEXT 6
#define EDIT_ITEM_PENCIL 4



#define Module_Link @"Module_Link"
#define Module_Note @"Module_Note"
#define Module_Markup @"Module_Markup"
#define Module_UnSupport @"Module_UnSupport"

#define THUMBNAIL_FOLDER_NAME @"Thumbnail"
#define DOCUMENT_PATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

//Define thumbnail/overview image size
//old Width = 58.0
#define THUMBNAIL_IMAGE_WIDTH 58.0
#define THUMBNAIL_IMAGR_HEIGHT 58.0
#define THUMBNAIL_IMAGE_WIDTH_EX 84.0
#define THUMBNAIL_IMAGE_HEIGHT_EX 87.0
#define THUMBNAIL_IMAGE_WIDTH_LARGE_EX 128.0
#define THUMBNAIL_IMAGE_HEIGHT_LARGE_EX 134.0f
#define FILE_IMAGE_WIDTH 50.0
#define FILE_IMAGE_HEIGHT 54.0
#define OVERVIEW_IMAGE_WIDTH 160.0
#define OVERVIEW_IMAGE_HEIGHT 200.0
#define OVERVIEW_IMAGE_WIDTH_IPHONE 142.0
#define OVERVIEW_IMAGE_HEIGHT_IPHONE 177.0