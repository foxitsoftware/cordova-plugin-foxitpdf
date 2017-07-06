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

#import "AnnotationSignature.h"

#define DEFAULT_COLOR 0x000000
#define DEFAULT_DIAMETER 5

@implementation AnnotationSignature

- (void)initValue
{
    self.name  = nil;
    self.rectSigPart = CGRectZero;
    self.color = DEFAULT_COLOR;
    self.diameter = DEFAULT_DIAMETER;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        [self initValue];
    }
    return self;
}

+ (AnnotationSignature *)createWithDefaultOptionForPageIndex:(int)pageIndex rect:(FSRectF*)rect
{
    AnnotationSignature *annot = [[AnnotationSignature alloc] init];
    annot.pageIndex = pageIndex;
    annot.rect = rect;
    annot.author = [SettingPreference getAnnotationAuthor];
    annot.color = 0;
    annot.opacity = 100;
    annot.contents = @"";
    annot.name = @"FoxitMobilePDFSignature";
    return annot;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeCGRect:self.rectSigPart forKey:@"rectSigPart"];
    [coder encodeInt:self.color forKey:@"color"];
    [coder encodeInt:self.diameter forKey:@"diameter"];
    [coder encodeObject:self.certFileName forKey:@"certFileName"];
    [coder encodeObject:self.certPasswd forKey:@"certPasswd"];
    [coder encodeObject:self.certMD5 forKey:@"certMD5"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self) {
        [self initValue];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.rectSigPart = [decoder decodeCGRectForKey:@"rectSigPart"];
        self.color = [decoder decodeIntForKey:@"color"];
        self.diameter = [decoder decodeIntForKey:@"diameter"];
        self.certFileName = [decoder decodeObjectForKey:@"certFileName"];
        self.certPasswd = [decoder decodeObjectForKey:@"certPasswd"];
        self.certMD5 = [decoder decodeObjectForKey:@"certMD5"];
    }
    
    return self;
}

- (void)dealloc
{
    self.name = nil;
}

+ (NSMutableArray*)getSignatureArray
{
    NSMutableArray *array = nil;
    NSData *data = [[NSUserDefaults standardUserDefaults] valueForKey:SETTING_SIGNATURE];
    if (data && data.length > 0)
    {
        array = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
    }
    else
    {
        array = [NSMutableArray array];
    }
    
    return array;
}

+ (void)saveSignature:(NSArray*)array
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:SETTING_SIGNATURE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSMutableArray*)getSignatureList
{
    NSMutableArray *ret = [NSMutableArray array];
    NSArray *array = [AnnotationSignature getSignatureArray];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AnnotationSignature *sig = obj;
        [ret addObject:sig.name];
    }];
    
    return ret;
}

+ (NSMutableArray*)getCertSignatureList
{
    NSMutableArray *ret = [NSMutableArray array];
    NSArray *array = [AnnotationSignature getSignatureArray];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AnnotationSignature *sig = obj;
        if (sig.certMD5 && sig.certPasswd && sig.certFileName) {
            [ret addObject:sig.name];
        }
    }];
    
    return ret;
}

+ (UIImage*)getSignatureImage:(NSString*)name
{
    if (name == nil) {
        return nil;
    }
    name = [name stringByAppendingString:@"_i"];
    return [UIImage imageWithContentsOfFile:[SIGNATURE_PATH stringByAppendingPathComponent:name]];
}

+ (NSData*)getSignatureData:(NSString*)name
{
    if (name == nil) {
        return nil;
    }
    name = [name stringByAppendingString:@"_i"];
    return [NSData dataWithContentsOfFile:[SIGNATURE_PATH stringByAppendingPathComponent:name]];
}

+ (void)setSignatureImage:(NSString*)name img:(UIImage*)img
{
    name = [name stringByAppendingString:@"_i"];
    NSData *data = UIImagePNGRepresentation(img);
    [data writeToFile:[SIGNATURE_PATH stringByAppendingPathComponent:name] atomically:YES];
}

+ (void)setCertFileToSiganatureSpace:(NSString *)name path:(NSString *)path
{
    NSFileManager *fileM = [NSFileManager defaultManager];
    NSString *newPath = [SIGNATURE_PATH stringByAppendingPathComponent:name];
    NSError *error;
    if ([fileM fileExistsAtPath:newPath]) {
        [fileM removeItemAtPath:newPath error:&error];
    }
    [fileM copyItemAtPath:path toPath:newPath error:&error];
}

+ (NSData*)getSignatureDib:(NSString*)name
{
    name = [name stringByAppendingString:@"_d"];
    return [NSData dataWithContentsOfFile:[SIGNATURE_PATH stringByAppendingPathComponent:name]];
}

+ (void)setSignatureDib:(NSString*)name data:(NSData*)data
{
    name = [name stringByAppendingString:@"_d"];
    [data writeToFile:[SIGNATURE_PATH stringByAppendingPathComponent:name] atomically:YES];
}

+ (void)removeSignatureResource:(NSString*)name
{
    NSFileManager *file = [[NSFileManager alloc] init];
    NSString *imgPath = [SIGNATURE_PATH stringByAppendingPathComponent:[name stringByAppendingString:@"_i"]];
    NSString *dibPath = [SIGNATURE_PATH stringByAppendingPathComponent:[name stringByAppendingString:@"_d"]];
    [file removeItemAtPath:imgPath error:nil];
    [file removeItemAtPath:dibPath error:nil];
    }

+ (AnnotationSignature*)getSignature:(NSString*)name
{
    __block AnnotationSignature *ret = nil;
    NSArray *array = [AnnotationSignature getSignatureArray];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AnnotationSignature *sig = obj;
        if ([sig.name isEqualToString:name])
        {
            ret = sig;
            *stop = YES;
        }
    }];
    
    return ret;
}

- (NSString*)add
{
    self.name = [Utility getUUID];
    
    NSMutableArray *array = [AnnotationSignature getSignatureArray];
    [array addObject:self];
    
    [AnnotationSignature saveSignature:array];
    
    if (array.count == 1)
    {
        [AnnotationSignature setSignatureSelected:self.name];
    }
    
    return self.name;
}

- (void)update
{
    NSMutableArray *array = [AnnotationSignature getSignatureArray];
    for (int i = 0; i < array.count; i++)
    {
        AnnotationSignature *sig = [array objectAtIndex:i];
        if ([sig.name isEqualToString:self.name])
        {
            [array replaceObjectAtIndex:i withObject:self];
            break;
        }
    }
    
    [AnnotationSignature saveSignature:array];
}

- (void)remove
{
    NSMutableArray *array = [AnnotationSignature getSignatureArray];
    for (int i = 0; i < array.count; i++)
    {
        AnnotationSignature *sig = [array objectAtIndex:i];
        if ([sig.name isEqualToString:self.name])
        {
            [array removeObject:sig];
            break;
        }
    }
    
    [AnnotationSignature saveSignature:array];
    
    NSString *selectedName = [AnnotationSignature getSignatureSelected];
    if ([selectedName isEqualToString:self.name])
    {
        if (array.count == 0)
        {
            [AnnotationSignature setSignatureSelected:@""];
        }
        else
        {
            AnnotationSignature *sig = [array objectAtIndex:0];
            [AnnotationSignature setSignatureSelected:sig.name];
        }
    }
}

+ (AnnotationSignature*)getSignatureOption
{
    AnnotationSignature *option = nil;
    NSData *data = [[NSUserDefaults standardUserDefaults] valueForKey:SETTING_SIGNATURE_OPTION];
    if (data && data.length > 0)
    {
        option = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else
    {
        option = [[AnnotationSignature alloc] init];
        option.color = DEFAULT_COLOR;
        option.diameter = DEFAULT_DIAMETER;
    }
    
    return option;
}

- (void)setOption
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:SETTING_SIGNATURE_OPTION];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*)getSignatureSelected
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:SETTING_SIGNATURE_SELECTED];
}

+ (void)setSignatureSelected:(NSString*)name
{
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:SETTING_SIGNATURE_SELECTED];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
