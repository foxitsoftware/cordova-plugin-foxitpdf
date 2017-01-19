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

#import "FbFileItem.h"
#import <FoxitRDK/FSPDFObjC.h>
#import "AppDelegate.h"
#import "Utility+Demo.h"

@implementation FbFileItem

- (id)initWithPath:(NSString *)filePath modifiedDate:(NSDate *)lastModifiedDate isFavorite:(NSNumber *)isFavorite
{
    //lastModifiedDate is used to judge if the PDF is updated outside and not the same file recorded in App.
    //however it will cause recent and favorite file disappear if the file is changed outside and confusing.
    //so this condition is deprecated.
    lastModifiedDate = nil;
    _isTouchMoving = NO;
    _reserveData = 0;
    if(self = [super init])
    {
        self.isValidPDF = YES;
        //Not a reasonable file path, initialize fail and return nil.
        if(filePath == nil)
        {
            self.isValidPDF = NO;
        }
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if(self.isValidPDF)
        {
            //If the file path cannot find PDF file, initialize fail and return nil.
            BOOL isDirectory;
            if(![fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] || isDirectory)
            {
                self.isValidPDF = NO;
            }
        }
        if(self.isValidPDF)
        {
            //get the file attribute and initialize the object
            self.path = filePath;
            NSString *fileNameExt = [filePath lastPathComponent];
            self.fileExt = [fileNameExt pathExtension];
            if ([Utility isPDFExtension:self.fileExt])
                self.fileName = [fileNameExt stringByDeletingPathExtension];
            else
                self.fileName = fileNameExt;

            NSDictionary *fileAttribute = [fileManager attributesOfItemAtPath:filePath error:nil]; //not use error here. by testing error is not nil even when get the attribute successfully.
            if(fileAttribute != nil)
            {
                self.fileSize = (NSUInteger)[fileAttribute fileSize];
                self.modifiedDate = [fileAttribute fileModificationDate];
                //if pass in modified date, check it's the same date. otherwise it's not the same file looking for
                if(lastModifiedDate != nil && ![self.modifiedDate isEqualToDate:lastModifiedDate])
                    self.isValidPDF = NO;
            }
            else
            {
                FoxitLog(@"Cannot get file attribute. File: %@.", self.path);
                self.isValidPDF = NO;
            }
            self.lastViewDate = nil;
        }
        if(self.isValidPDF && !self.isFolder)
        {
            _isOpen = NO;
        }
        [fileManager release];
    }
    return self;
}

+ (float )folderSizeAtPath:(NSString *)folderPath{
    
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize;
}
+ (long long) fileSizeAtPath:(NSString *)filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

- (void)getThumbnailForPageIndex:(int)pageIndex dispatchQueue:(dispatch_queue_t)queue WithHandler:(getThumbnailHandler)handler
{
    self.reserveData = 0;
    //Verify if it's pdf file first
    NSString *realName = [self.path lastPathComponent];
    if (pageIndex >= 0) {
        if (![Utility isPDFPath:realName])
        {
            if(handler)
            {
                handler([UIImage imageNamed:pageIndex >= 0 ? [Utility getIconName:realName] : [Utility getThumbnailName:realName]], pageIndex, self.path);
            }
            return;
        }
    } else {
        if (![Utility isPDFPath:realName])
        {
            if(handler)
            {
                handler([UIImage imageNamed:pageIndex >= 0 ? [Utility getIconName:realName] : [Utility getThumbnailName:realName]], pageIndex, self.path);
            }
            return;
        }
    }
	
    NSString* cacheFolder = [FbFileItem getCacheDirectoryPath:self.path];
    NSString *thumbnailFolder = [cacheFolder stringByAppendingPathComponent:THUMBNAIL_FOLDER_NAME];
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    if(![fileManager fileExistsAtPath:thumbnailFolder])
    {
        [fileManager createDirectoryAtPath:thumbnailFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    float maxWidth = ((pageIndex != -1)&&(pageIndex != -2)) ? OVERVIEW_IMAGE_WIDTH : ((pageIndex != -2) ? THUMBNAIL_IMAGE_WIDTH : (DEVICE_iPHONE ? THUMBNAIL_IMAGE_WIDTH_EX : THUMBNAIL_IMAGE_WIDTH_LARGE_EX));
    float maxHeight = ((pageIndex != -1)&&(pageIndex != -2)) ? OVERVIEW_IMAGE_HEIGHT :((pageIndex != -2) ?THUMBNAIL_IMAGR_HEIGHT : (DEVICE_iPHONE ? THUMBNAIL_IMAGE_HEIGHT_EX : THUMBNAIL_IMAGE_HEIGHT_LARGE_EX));
    BOOL isHighResolution = ([UIScreen mainScreen].scale >= 2);
    BOOL isDir;
    if (![fileManager fileExistsAtPath:thumbnailFolder isDirectory:&isDir]) {
        [fileManager createDirectoryAtPath:thumbnailFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *thumbnailPath = [thumbnailFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", pageIndex]];
    if([fileManager fileExistsAtPath:thumbnailPath])
    {
        NSData *imageData = [NSData dataWithContentsOfFile:thumbnailPath];
        UIImage *imageThumbnail = [UIImage imageWithData:imageData];
        if(imageThumbnail != nil)
        {
            NSString *lockFileDataPath = [[thumbnailPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"lockfiledata"];
            _reserveData = [fileManager fileExistsAtPath:lockFileDataPath] ? 1 : 0;
            //need to check this image meet the resolution
            if ((!isHighResolution && imageThumbnail.size.width <= maxWidth && imageThumbnail.size.height <= maxHeight)
                || (isHighResolution && (imageThumbnail.size.width > maxWidth || imageThumbnail.size.height > maxHeight)))
            {
                //find the cached thumbnail, just return
                if(handler)
                {
                    handler(imageThumbnail, pageIndex, self.path);
                }
                return;
            }
        }
    }
    //cannot find cached thumbnail, start to create files into this folder
    if(handler)
    {
        //return the temp file first
        if((pageIndex != -1) && (pageIndex != -2))
        {
            handler([UIImage imageNamed:@"list_pdf_bgx"], pageIndex, self.path);
        }
        else
        {
            handler([UIImage imageNamed:DEVICE_iPHONE ? @"thumbnail_pdf_iphone" : @"thumbnail_pdf_ipad"], pageIndex, self.path);
        }
    }
    dispatch_async(queue, ^{
        //create thumbnail and close
        UIImage *imageThumbnail = nil;
        CGSize realSize =  [Utility getPDFPageSizeWithIndex:1 pdfPath:self.path];
        float realWidth = maxWidth;
        float realHeight = maxHeight;
        self.reserveData = 0;
        if(realSize.width > 0 && realSize.height > 0)
        {
            if(realWidth/realHeight > realSize.width/realSize.height)  //width is less than height
            {
                realHeight = maxHeight;
                realWidth = realSize.width/realSize.height*realHeight;
            }
            else //height is less than width
            {
                realWidth = maxWidth;
                realHeight = realSize.height/realSize.width*realWidth;
            }
        }
        //draw thumbnail automatically do *2, not need to double size again.
        if((pageIndex != -1) && (pageIndex != -2))
        {
            imageThumbnail = [Utility drawPageThumbnailWithPDFPath:self.path pageIndex:pageIndex pageSize:CGSizeMake(realWidth, realHeight)];
        }
        else
        {
            enum FS_ENCRYPTTYPE encryptType = [Utility getDocumentSecurityType:self.path taskServer:nil];
    
            imageThumbnail = [Utility drawPageThumbnailWithPDFPath:self.path pageIndex:0 pageSize:CGSizeMake(realWidth, realHeight)];
            if (encryptType == e_encryptPassword)
            {
                //save lock icon to disk to improve performance
                imageThumbnail = [UIImage imageNamed:DEVICE_iPHONE ? @"thumbnail_pdflock_iphone" : @"thumbnail_pdflock_ipad"];
                self.reserveData = 1; //file is locked;
            }
            else if (encryptType == e_encryptRMS)
            {
                imageThumbnail = [UIImage imageNamed:DEVICE_iPHONE ? @"thumbnail_pdflock_iphone" : @"thumbnail_pdflock_ipad"];
                self.reserveData = 1; //file is locked;
            }
        }
        if(imageThumbnail != nil)
        {
            //save to disk
            NSData *imageData = UIImagePNGRepresentation(imageThumbnail);
            if(![imageData writeToFile:thumbnailPath atomically:YES])
            {
                FoxitLog(@"Cannot save thumbnail image to %@", thumbnailPath);
            }
            if (_reserveData == 1)
            {
                NSData *lockFileData = [@"lockfiledata" dataUsingEncoding:NSUTF8StringEncoding];
                NSString *lockFileDataPath = [[thumbnailPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"lockfiledata"];
                if (![lockFileData writeToFile:lockFileDataPath atomically:YES])
                {
                    FoxitLog(@"Cannot save lockfiledata to %@", lockFileDataPath);
                }
            }
            //return to handler
            if(handler)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(imageThumbnail, pageIndex, self.path);
                });
            }
        }
    });
}

static NSString* getAbsolutePathFromRelativePath(NSString* relativePath)
{
    //icloud drive outside file
    if ([[NSFileManager defaultManager] fileExistsAtPath:relativePath])
    {
        return relativePath;
    }
    
    NSString *bundlePath = DOCUMENT_PATH;
    NSString *parentPath = [bundlePath stringByDeletingLastPathComponent];
    
    return [parentPath stringByAppendingString:relativePath];
}

+ (NSString *)getCacheDirectoryPath:(NSString *)path
{
    NSString* cachePath = [getAbsolutePathFromRelativePath(@"/Library/Data/PDFCache/") stringByAppendingPathComponent:[path lastPathComponent]];
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    if(![fileManager fileExistsAtPath:cachePath])
    {
        [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return cachePath;
}

//Avi - Added to run the copy method
- (id)copyWithZone:(NSZone *)zone {
    
    FbFileItem *fbfile  = [[FbFileItem alloc] init];
    if (fbfile) {
        
        fbfile.parentPath  = [[self.parentPath copyWithZone:zone] autorelease];
        fbfile.type  = [[self.type copyWithZone:zone] autorelease];
        fbfile.fileName  = [[self.fileName copyWithZone:zone] autorelease];
        fbfile.createTime  = [[self.createTime copyWithZone:zone] autorelease];
        fbfile.fileSize  = self.fileSize;
        fbfile.directorySize  = self.directorySize;
        fbfile.isFolder = self.isFolder;
        fbfile.isOpen = self.isOpen;
        fbfile.isValidPDF = self.isValidPDF;
        fbfile.path = [[self.path copyWithZone:zone] autorelease];
        fbfile.modifiedDate = [[self.modifiedDate copyWithZone:zone] autorelease];
        fbfile.lastViewDate = [[self.lastViewDate copyWithZone:zone] autorelease];
        fbfile.isTouchMoving = self.isTouchMoving;
        fbfile.fileExt = [[self.fileExt copyWithZone:zone] autorelease];
        fbfile.reserveData = self.reserveData;
        
    }
    return fbfile;
}

- (void)dealloc
{
    [_parentPath release];
    [_type release];
    [_fileName release];
    [_createTime release];
    [_path release];
    [_modifiedDate release];
    [_lastViewDate release];
    [_fileExt release];
    
    [super dealloc];
}

@end
