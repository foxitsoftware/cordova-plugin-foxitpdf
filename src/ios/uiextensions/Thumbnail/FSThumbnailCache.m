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

#import "FSThumbnailCache.h"
#import "Utility.h"
#import "UIExtensionsManager.h"
#import "UIExtensionsManager+private.h"
#import "FSPDFReader.h"

NSMutableIndexSet *indexSetFromArray(NSArray<NSNumber *> *array);

@interface FSThumbnailCache ()

@property (nonatomic, weak) UIExtensionsManager *extensionsManager;
@property (nonatomic, readonly) FSPDFDoc *document;
@property (nonatomic, readonly) NSString *documentPath;
@property (nonatomic, readonly) NSString *thumbnailDirectory;

@end

@implementation FSThumbnailCache

- (id)initWithUIExtenionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        self.extensionsManager = extensionsManager;
    }
    return self;
}

- (void)getThumbnailForPageAtIndex:(NSUInteger)index withThumbnailSize:(CGSize)thumbnailSize callback:(void (^ __nonnull)(UIImage *))callback {
    NSString *thumbnailPath = [self getThumbnailPathForPageAtIndex:index withThumbnailSize:thumbnailSize];
    if (!thumbnailPath) {
        callback(nil);
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    @synchronized (self) {
        if ([fileManager fileExistsAtPath:thumbnailPath]) {
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:thumbnailPath];
            CGFloat mainScale = [[UIScreen mainScreen] scale];
            if (image && fabs(image.size.width/mainScale-thumbnailSize.width) < 1.0f
                && fabs(image.size.height/mainScale-thumbnailSize.height) < 1.0f) {
                callback(image);
                return;
            } else if (![fileManager removeItemAtPath:thumbnailPath error:nil]) {
                callback(nil);
                return;
            }
        }
    }
    FSPDFPage *page = nil;
    @try {
        page = [self.document getPage:(int)index];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
        callback(nil);
        return;
    }
    
    UIImage *thumbnailImage = [Utility drawPage:page targetSize:thumbnailSize shouldDrawAnnotation:YES isNightMode:NO];
    if (thumbnailImage) {
        @synchronized (self) {
            [UIImagePNGRepresentation(thumbnailImage) writeToFile:thumbnailPath atomically:YES];
        }
    }
    callback(thumbnailImage);
}

- (BOOL)removeThumbnailCacheOfPageAtIndex:(NSUInteger)pageIndex {
    NSString *fileName = [NSString stringWithFormat:@"%d.png", (int)pageIndex];
    NSString *filePath = [self.thumbnailDirectory stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    @synchronized (self) {
        if ([fileManager fileExistsAtPath:filePath]) {
            return [fileManager removeItemAtPath:filePath error:nil];
        }
    }
    return YES;
}

- (void)clearThumbnailCachesForCurrentDocument {
    @synchronized (self) {
        NSString *directory = [self thumbnailDirectory];
        if (!directory) {
            return;
        }
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (NSString *fileName in [fileManager contentsOfDirectoryAtPath:directory error:nil]) {
            NSString *filePath = [directory stringByAppendingPathComponent:fileName];
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }
}

#pragma mark <IPageEventListener>

- (void)onPagesRemoved:(NSArray<NSNumber*>*)indexes {
    if (indexes.count == 0) {
        return;
    }
    NSIndexSet *indexSet = indexSetFromArray(indexes);
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeThumbnailCacheOfPageAtIndex:idx];
    }];
    for (NSUInteger i = indexSet.firstIndex+1; i < [self.document getPageCount]; i ++) {
        NSUInteger numPrevPagesRemoved = [indexSet countOfIndexesInRange:NSMakeRange(0, i)];
        [self moveThumbnailOfPageAtIndex:i toIndex:i-numPrevPagesRemoved];
    }
}

- (void)onPagesMoved:(NSArray<NSNumber*>*)indexes dstIndex:(int)dstIndex {
    if (indexes.count == 0) {
        return;
    }
    NSArray<NSNumber *> *resultPageIndexes = [self getReorderedPageIndexesAfterMovingPagesAtIndexes:indexes toIndex:dstIndex];
    // move file to intermediate file first
    [resultPageIndexes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull oldPageIndex, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == oldPageIndex.unsignedIntegerValue) {
            return;
        }
        [self moveThumbnailOfPageAtIndex:oldPageIndex.unsignedIntegerValue withPrefix:nil toIndex:idx withPrefix:@"temp"];
    }];
    [resultPageIndexes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull newPageIndex, NSUInteger idx, BOOL * _Nonnull stop) {
        [self moveThumbnailOfPageAtIndex:newPageIndex.unsignedIntegerValue withPrefix:@"temp" toIndex:newPageIndex.unsignedIntegerValue withPrefix:nil];
    }];
}

- (void)onPagesRotated:(NSArray<NSNumber*>*)indexes rotation:(int)rotation {
    [indexes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeThumbnailCacheOfPageAtIndex:obj.unsignedIntegerValue];
    }];
}

- (void)onPagesInsertedAtRange:(NSRange)range {
    if (range.location == NSNotFound || range.length == 0) {
        return;
    }
    for (NSInteger i = [self.document getPageCount] - 1; i >= (NSInteger)range.location; i --) {
        [self moveThumbnailOfPageAtIndex:i toIndex:i+range.length];
    }
}

#pragma mark <IAnnotEventListener>

- (void)onAnnotAdded:(FSPDFPage* )page annot:(FSAnnot*)annot {
    [self removeThumbnailCacheOfPageAtIndex:[page getIndex]];
}

- (void)onAnnotDeleted:(FSPDFPage* )page annot:(FSAnnot*)annot {
    [self removeThumbnailCacheOfPageAtIndex:[page getIndex]];
}

- (void)onAnnotModified:(FSPDFPage* )page annot:(FSAnnot*)annot {
    [self removeThumbnailCacheOfPageAtIndex:[page getIndex]];
}

#pragma mark private methods

- (NSString *)getThumbnailPathForPageAtIndex:(NSUInteger)index withThumbnailSize:(CGSize)thumbnailSize {
    NSString *thumbnailPath = [self.thumbnailDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", (int)index]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:thumbnailPath]) {
        return thumbnailPath;
    }
    BOOL shouldUpdateThumbnail = NO;
    NSDate *thumbnailDate = [[fileManager attributesOfItemAtPath:thumbnailPath error:nil] fileCreationDate];
    NSDate *documentDate = [[fileManager attributesOfItemAtPath:self.documentPath error:nil] fileModificationDate];
    if ([thumbnailDate compare:documentDate] == NSOrderedAscending) {
        shouldUpdateThumbnail = YES;
    }
    if (shouldUpdateThumbnail && ![fileManager removeItemAtPath:thumbnailPath error:nil]) {
        return nil;
    }
    return thumbnailPath;
}

- (NSString *)thumbnailDirectory {
    NSString *thumbnailDirectory = [[DOCUMENT_PATH stringByDeletingLastPathComponent] stringByAppendingString:@"/Library/Data/PDFCache/Thumbnail/"];
    NSString *documentUUID = [Utility getStringMD5:self.documentPath];
    assert(documentUUID);
    thumbnailDirectory = [thumbnailDirectory stringByAppendingPathComponent:documentUUID];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:thumbnailDirectory]) {
        if (![fileManager createDirectoryAtPath:thumbnailDirectory withIntermediateDirectories:YES attributes:nil error:nil]) {
            return nil;
        }
    }
    return thumbnailDirectory;
}

- (BOOL)moveThumbnailOfPageAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex {
    return [self moveThumbnailOfPageAtIndex:sourceIndex withPrefix:nil toIndex:destinationIndex withPrefix:nil];
}

- (BOOL)moveThumbnailOfPageAtIndex:(NSUInteger)sourceIndex withPrefix:(NSString *)sourcePrefix toIndex:(NSUInteger)destinationIndex withPrefix:(NSString *)destinationPrefix {
    if (sourceIndex == destinationIndex &&
        (sourcePrefix == destinationPrefix || [sourcePrefix isEqualToString:destinationPrefix])) {
        return YES;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *sourceFileName = [NSString stringWithFormat:@"%@%d.png", sourcePrefix?:@"", (int)sourceIndex];
    NSString *sourceFilePath = [self.thumbnailDirectory stringByAppendingPathComponent:sourceFileName];
    @synchronized (self) {
        if ([fileManager fileExistsAtPath:sourceFilePath]) {
            NSString *destinationFileName = [NSString stringWithFormat:@"%@%d.png", destinationPrefix?:@"", (int)destinationIndex];
            NSString *destinationFilePath = [self.thumbnailDirectory stringByAppendingPathComponent:destinationFileName];
            //        NSLog(@"move %@ to %@", sourceFileName, destinationFileName);
            if ([fileManager fileExistsAtPath:destinationFilePath]) {
                [fileManager removeItemAtPath:destinationFilePath error:nil];
            }
            return [fileManager moveItemAtPath:sourceFilePath toPath:destinationFilePath error:nil];
        }
    }
    return YES;
}

// simulate moving operations and record all page movement in map
- (NSArray<NSNumber *> *)getReorderedPageIndexesAfterMovingPagesAtIndexes:(NSArray<NSNumber *> *)indexes toIndex:(NSUInteger)destinationIndex {
    NSUInteger pageCount = [self.document getPageCount];
    NSMutableArray<NSNumber *> *resultPageIndexes = [NSMutableArray<NSNumber *> arrayWithCapacity:pageCount];
    for (NSUInteger i = 0; i < pageCount; i ++) {
        [resultPageIndexes addObject:@(i)];
    }
    
    void (^movePage)(NSUInteger _sourceIndex, NSUInteger _destinatinoIndex) = ^(NSUInteger _sourceIndex, NSUInteger _destinatinoIndex) {
        if (_sourceIndex != _destinatinoIndex) {
            NSNumber *page = resultPageIndexes[_sourceIndex];
            [resultPageIndexes removeObject:page];
            if (_destinatinoIndex > _sourceIndex) {
                _destinatinoIndex --;
            }
            [resultPageIndexes insertObject:page atIndex:_destinatinoIndex];
        }
    };
    
    NSUInteger currentDestinationIndex = destinationIndex;
    NSMutableArray<NSNumber *> *mutableSourceIndexes = indexes.mutableCopy;
    while (mutableSourceIndexes.count > 0) {
        NSUInteger currentSourceIndex = mutableSourceIndexes[0].unsignedIntegerValue;
        [mutableSourceIndexes removeObjectAtIndex:0];
        movePage(currentSourceIndex, currentDestinationIndex);
        //update source indexes
        for (NSUInteger i = 0; i < mutableSourceIndexes.count; i ++) {
            NSInteger sourceIndex = mutableSourceIndexes[i].unsignedIntegerValue;
            assert(sourceIndex != currentSourceIndex);
            if (currentSourceIndex < sourceIndex && sourceIndex < currentDestinationIndex) {
                mutableSourceIndexes[i] = [NSNumber numberWithUnsignedInteger:sourceIndex-1];
            } else if (currentDestinationIndex <= sourceIndex && sourceIndex < currentSourceIndex) {
                mutableSourceIndexes[i] = [NSNumber numberWithUnsignedInteger:sourceIndex+1];
            }
        }
        //update destination index
        if (currentSourceIndex < currentDestinationIndex) {
            currentDestinationIndex --;
        }
        currentDestinationIndex ++;
    }
    return resultPageIndexes;
}

- (FSPDFDoc *)document {
    return self.extensionsManager.pdfViewCtrl.currentDoc;
}

- (NSString *)documentPath {
    return self.extensionsManager.pdfReader.filePath;
}

@end

NSMutableIndexSet *indexSetFromArray(NSArray<NSNumber *> *array) {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSNumber *number in array) {
        [indexSet addIndex:number.unsignedIntegerValue];
    }
    return indexSet;
}
