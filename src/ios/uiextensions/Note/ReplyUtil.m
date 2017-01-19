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
#import "ReplyUtil.h"
#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

@implementation ReplyUtil

+ (void)getReplysInDocument:(FSPDFDoc* )document annot:(FSAnnot*)rootAnnot replys:(NSMutableArray*)replys
{
    if(![rootAnnot isMarkup])
        return;
    int countOfReplies = [(FSMarkup*)rootAnnot getReplyCount];
    for(int i=0; i<countOfReplies; i++)
    {
        FSNote* reply = [(FSMarkup*)rootAnnot getReply:i];
        for(FSNote* note in replys)
        {
            //Loop detect!
            if([note.NM isEqualToString:reply.NM])
                return;
        }
        [replys addObject:reply];
        [ReplyUtil getReplysInDocument:document annot:reply replys:replys];
    }
}

@end
