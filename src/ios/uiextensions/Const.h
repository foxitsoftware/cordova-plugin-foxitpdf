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

/** Whether it is iphone. */
#define DEVICE_iPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)

//iOS version
#define OS_VERSION [NSString stringWithFormat:@"%@", [[UIDevice currentDevice] systemVersion]]
#define OS_ISVERSION6 (BOOL)(OS_VERSION.integerValue >= 6)
#define OS_ISVERSION7 (BOOL)(OS_VERSION.integerValue >= 7)
#define OS_ISVERSION8 (BOOL)(OS_VERSION.integerValue >= 8)
#define OS_ISVERSION9 (BOOL)(OS_VERSION.integerValue >= 9)

//Screen frame
#define SCREENWIDTH  [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height

/** Define notification center observer messages for annotation events. */
#define ANNOLIST_UPDADELETETOTAL     @"AnnoList_UpdateDeleteTotal"
#define ANNOLIST_UPDATETOTAL         @"AnnoList_UpdateTotal"
#define ANNOTATION_UNREAD_TOTALCOUNT @"AnnotationUnreadTotalcount"
#define CLEAN_ANNOTATIONLIST         @"CLEAN_ANNOTATIONLIST"
#define ORIENTATIONCHANGED           @"ORIENTATIONCHANGED"

//Define the internal used paths
#define TEMP_PATH NSTemporaryDirectory()

//post Notification name
#define NOTIFICATION_NAME_APP_HANDLE_OPEN_URL @"app_handle_open_url"

/** Shorter side of main screen. */
#define STYLE_CELLWIDTH_IPHONE ([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height)
/** longer side of main screen. */
#define STYLE_CELLHEIHGT_IPHONE ([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height)

/** Note icon width. */
#define NOTE_ANNOTATION_WIDTH 36

/** Rectangle inset distance.*/
#define RECT_INSET -15

/** Operation types of annotation. */
#define AnnotationOperation_Add 1
#define AnnotationOperation_Delete 2
#define AnnotationOperation_Modify 3

typedef enum
{
    EDIT_ANNOT_RECT_TYPE_UNKNOWN = -1,
    EDIT_ANNOT_RECT_TYPE_LEFTTOP = 0,
    EDIT_ANNOT_RECT_TYPE_LEFTMIDDLE,
    EDIT_ANNOT_RECT_TYPE_LEFTBOTTOM,
    EDIT_ANNOT_RECT_TYPE_MIDDLETOP,
    EDIT_ANNOT_RECT_TYPE_MIDDLEBOTTOM,
    EDIT_ANNOT_RECT_TYPE_RIGHTTOP,
    EDIT_ANNOT_RECT_TYPE_RIGHTMIDDLE,
    EDIT_ANNOT_RECT_TYPE_RIGHTBOTTOM,
    EDIT_ANNOT_RECT_TYPE_FULL,
} EDIT_ANNOT_RECT_TYPE;

#define APPLICATION_ISFULLSCREEN [UIApplication sharedApplication].statusBarHidden

