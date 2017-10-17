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

#import "UIExtensionsModulesConfig.h"
#import "Common/UIExtensionsModulesConfig+private.h"
#import "UIExtensionsManager.h"
#import "Utility.h"
#import <FoxitRDK/FSPDFObjC.h>

@interface UIExtensionsModulesConfig ()

+ (NSSet<NSString *> *)standardTools;

@end

@implementation UIExtensionsModulesConfig {
    
}

+ (NSSet<NSString *> *) standardTools {
    // exclude Tool_Attachment, Tool_Signature which are explicitly controlled by loadXXX property
    return [NSSet setWithObjects:Tool_Select, Tool_Note, Tool_Freetext, Tool_Pencil, Tool_Eraser,
                                 Tool_Stamp, Tool_Insert, Tool_Replace, Tool_Highlight, Tool_Squiggly, Tool_StrikeOut,
                                 Tool_Underline, Tool_Rectangle, Tool_Oval, Tool_Line, Tool_Arrow, nil];
}

- (id)init {
    if ((self = [super init])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithJSONData:(NSData *__nonnull)data {
    if (self = [super init]) {
        [self commonInit];

        NSError *error = nil;
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
        if (error) {
            return nil;
        }
        if ([JSONObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *modules = [((NSDictionary *) JSONObject) objectForKey:@"modules"];
            if ([modules isKindOfClass:[NSDictionary class]]) {
                id thumbnail = [modules objectForKey:@"thumbnail"];
                if (thumbnail)
                    self.loadThumbnail = [thumbnail boolValue];
                id outline = [modules objectForKey:@"outline"];
                if (outline)
                    self.loadOutline = [outline boolValue];
                id readingBookmark = [modules objectForKey:@"readingBookmark"];
                if (readingBookmark)
                    self.loadReadingBookmark = [readingBookmark boolValue];
                id attachment = [modules objectForKey:@"attachment"];
                if (attachment)
                    self.loadAttachment = [attachment boolValue];
                id signature = [modules objectForKey:@"signature"];
                if (signature)
                    self.loadSignature = [signature boolValue];
                id search = [modules objectForKey:@"search"];
                if (search)
                    self.loadSearch = [search boolValue];
                id pageNavigation = [modules objectForKey:@"pageNavigation"];
                if (pageNavigation)
                    self.loadPageNavigation = [pageNavigation boolValue];
                id form = [modules objectForKey:@"form"];
                if (form)
                    self.loadForm = [form boolValue];
                id encryption = [modules objectForKey:@"encryption"];
                if (encryption)
                    self.loadEncryption = [encryption boolValue];
                id tools = [modules objectForKey:@"tools"];
                if (!tools) {
                    tools = [modules objectForKey:@"annotations"];
                }
                if (tools) {
                    [self loadToolsFromJSONObject:tools];
                }
                // back comparability, selection option is now moved to "tools"
                id selection = [modules objectForKey:@"selection"];
                if (selection && ![selection boolValue]) {
                    [_tools removeObject:Tool_Select];
                }
            } else {
                if ([(id) modules boolValue] == false) {
                    self.loadThumbnail = false;
                    self.loadReadingBookmark = false;
                    self.loadOutline = false;
                    self.loadAttachment = false;
                    self.loadForm = false;
                    self.loadSignature = false;
                    self.loadSearch = false;
                    self.loadPageNavigation = false;
                    self.loadEncryption = false;
                    self.tools = nil;
                }
            }
        }
    }
    return self;
}

- (void)commonInit {
    _loadThumbnail = YES;
    _loadReadingBookmark = YES;
    _loadOutline = YES;
    _loadAttachment = YES;
    _loadSignature = YES;
    _loadSearch = YES;
    _loadPageNavigation = YES;
    _loadForm = YES;
    _loadEncryption = YES;
    _tools = self.class.standardTools.mutableCopy;
    //    _supportedAnnotationTypes = [NSMutableArray arrayWithObjects:@(e_annotNote), @(e_annotHighlight),
    //                                 @(e_annotUnderline), @(e_annotSquiggly), @(e_annotStrikeOut), @(e_annotSquare),
    //                                 @(e_annotCircle), @(e_annotFreeText), @(e_annotStamp), @(e_annotInk),
    //                                 @(e_annotCaret), @(e_annotLine), @(e_annotFileAttachment), nil];
}

- (void)loadToolsFromJSONObject:(id __nonnull)tools {
    if ([tools isKindOfClass:[NSDictionary class]]) {
        [(NSDictionary *) tools enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
            if ([obj boolValue]) {
                return;
            }
            if (![key isKindOfClass:[NSString class]]) {
                return;
            }
            [self removeTool:key];
        }];
    } else if ([tools boolValue] == false) {
        _tools = nil;
    }
}

- (BOOL)canInteractWithAnnot:(FSAnnot *)annot {
    NSString *tool = nil;
    const FSAnnotType type = [annot getType];
    switch (type) {
    case e_annotFileAttachment:
        return self.loadAttachment;
    case e_annotWidget: {
        FSWidget *widget = (FSWidget *) annot;
        if ([[widget getField] getType] == e_formFieldSignature) {
            return self.loadSignature;
        } else {
            return self.loadForm;
        }
    }
    case e_annotNote:
        tool = Tool_Note;
        break;
    case e_annotInk:
        tool = Tool_Pencil;
        break;
    case e_annotStamp:
        tool = Tool_Stamp;
        break;
    case e_annotCaret:
        tool = [Utility isReplaceText:(FSCaret *) annot] ? Tool_Replace : Tool_Insert;
        break;
    case e_annotHighlight:
        tool = Tool_Highlight;
        break;
    case e_annotSquiggly:
        tool = Tool_Squiggly;
        break;
    case e_annotStrikeOut:
        tool = [Utility isReplaceText:(FSStrikeOut *) annot] ? Tool_Replace : Tool_StrikeOut;
        break;
    case e_annotUnderline:
        tool = Tool_Underline;
        break;
    case e_annotSquare:
        tool = Tool_Rectangle;
        break;
    case e_annotCircle:
        tool = Tool_Oval;
        break;
    case e_annotFreeText:
        tool = Tool_Freetext;
        break;
    case e_annotLine: {
        BOOL isArrow = [[(FSMarkup *) annot getIntent] caseInsensitiveCompare:@"LineArrow"] == NSOrderedSame;
        tool = isArrow ? Tool_Arrow : Tool_Line;
        break;
    }
    default:
        break;
    }
    if (!tool) {
        return false;
    }
    return [_tools containsObject:tool];
}

- (BOOL)isToolEnabled:(NSString *)tool {
    tool = [self getStandardNameForTool:tool];
    if (tool) {
        return [_tools containsObject:tool];
    }
    return false;
}

- (void)addTool:(NSString *)tool {
    tool = [self getStandardNameForTool:tool];
    if (tool) {
        [_tools addObject:tool];
    }
}

- (void)removeTool:(NSString *)tool {
    tool = [self getStandardNameForTool:tool];
    if (tool) {
        [_tools removeObject:tool];
    }
}

- (BOOL)isTool:(NSString *)tool1 equivalentToTool:(NSString *)tool2 {
    if (([tool1 caseInsensitiveCompare:tool2] == NSOrderedSame)) {
        return true;
    }
    tool1 = [tool1 lowercaseString];
    tool2 = [tool2 lowercaseString];
    for (NSArray *aliasArray in @[ @[ @"note", @"comment" ],
                                   @[ @"freetext", @"free text", @"typewriter", @"type writer" ],
                                   @[ @"ink", @"pencil" ],
                                   @[ @"replace", @"replace text", @"replacetext" ],
                                   @[ @"insert", @"insert text", @"inserttext" ],
                                   @[ @"circle", @"oval" ],
                                   @[ @"rectangle", @"square" ],
                                   @[ @"arrow", @"arrow line" ],
                                   @[ @"attachment", @"fileattachment", @"file attachment" ],
                                   @[ @"select", @"selection", @"select text", @"selecttext" ] ]) {
        if ([aliasArray containsObject:tool1] && [aliasArray containsObject:tool2]) {
            return true;
        }
    }
    return false;
}

- (NSString *)getStandardNameForTool:(NSString *)tool {
    if ([self.class.standardTools containsObject:tool]) {
        return tool;
    }
    for (NSString *standardTool in self.class.standardTools) {
        if ([self isTool:standardTool equivalentToTool:tool]) {
            return standardTool;
        }
    }
    return nil;
}

@end
