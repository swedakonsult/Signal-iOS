//
//  SignalCacheManager.m
//  Signal
//
//  Created by Frederic Jacobs on 05/04/15.
//  Copyright (c) 2015 Open Whisper Systems. All rights reserved.
//

#import "SignalCacheManager.h"

@interface CacheObjectPath ()

+ (instancetype)bloomFilterPath;
+ (instancetype)tempAudioPath;
+ (instancetype)tempVideoPath;

@end


@implementation CacheObjectPath

+ (NSString*)cacheFolderPath {
    NSArray  *cachesDir       = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheFolderPath = [cachesDir  objectAtIndex:0];
    return cacheFolderPath;
}

- (instancetype)initCacheObjectPathWithKey:(NSString*)key {
    NSFileManager *fm         = [NSFileManager defaultManager];
    NSString *cacheFolderPath = [[self class] cacheFolderPath];
    NSError  *error;
    
    if (![fm fileExistsAtPath:cacheFolderPath]) {
        [fm createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:@{} error:&error];
    }
    
    if (error) {
        DDLogError(@"Failed to create caches directory with error: %@", error.description);
        SignalAlertView(NSLocalizedString(@"STORAGE_ERROR_TITLE", nil), NSLocalizedString(@"STORAGE_ERROR_MESSAGE", nil));
        return nil;
    }
    
    NSString *path = [cacheFolderPath stringByAppendingPathComponent:key];
    
    return [self initWithString:path];
}

+ (instancetype)bloomFilterPath {
    return [[self alloc] initCacheObjectPathWithKey:@"bloomfilter"];
}

+ (instancetype)tempAudioPath {
    return [[self alloc] initCacheObjectPathWithKey:@"audioAttachmentTemp"];
}

+ (instancetype)tempVideoPath {
    return [[self alloc] initCacheObjectPathWithKey:@"videoAttachmentTemp"];
}

@end

@implementation SignalCacheManager

MacrosSingletonImplemention

#pragma mark Bloom filter

- (NSData*)tryRetrieveBloomFilter {
    return [NSData dataWithContentsOfFile:[CacheObjectPath bloomFilterPath].absoluteString];
}

- (void)storeBloomfilter:(NSData*)bloomFilterData {
    [self storeData:bloomFilterData inCacheFolderWithPath:[CacheObjectPath bloomFilterPath]];
}

#pragma mark Audio Attachment temp

- (NSURL*)audioRecordPath {
    return [CacheObjectPath tempAudioPath];
}

- (void)cancelAudioRecording {
    [self removeCacheObject:[CacheObjectPath tempAudioPath]];
}

- (NSData*)retrieveAudioTempAndCancel {
    return [NSData dataWithContentsOfFile:[CacheObjectPath tempAudioPath].absoluteString];
}

#pragma mark Video processing cache

- (NSData*)retrieveAndClearVideoTemp {
    NSData *videoData = [NSData dataWithContentsOfFile:[CacheObjectPath tempVideoPath].absoluteString];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError       *error;
    
    [fm removeItemAtPath:[CacheObjectPath tempVideoPath].absoluteString error:&error];
    
    if (error) {
        DDLogError(@"Error while clearing temp video path: %@", error.debugDescription);
    }
    
    return videoData;
}

- (NSURL*)tempVideoStorageURL {
    return [NSURL URLWithString:[CacheObjectPath tempVideoPath].absoluteString];
}

#pragma mark Cache Storage Util

- (BOOL)clearCache {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSString *cacheFolderPath = [CacheObjectPath cacheFolderPath];
    NSArray *cacheItems       = [fm contentsOfDirectoryAtPath:cacheFolderPath error:&error];
    
    for (NSString *cacheItemName in cacheItems) {
        [fm removeItemAtPath:[cacheFolderPath stringByAppendingString:cacheItemName] error:&error];
    }
    
    if (error) {
        DDLogVerbose(@"Failed to clear cache with error: %@", error.localizedDescription);
        return NO;
    }
    
    return YES;
}

- (BOOL)removeCacheObject:(CacheObjectPath*)cacheObject {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    
    [fm removeItemAtPath:cacheObject.absoluteString error:&error];
    
    if (error) {
        DDLogError(@"Failed to remove object from cache: %@", error.debugDescription);
        return NO;
    }
    
    return YES;
}

- (BOOL)storeData:(NSData*)data inCacheFolderWithPath:(CacheObjectPath*)filePath {
    if (!data) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError       *error;
        
        if ([fileManager fileExistsAtPath:filePath.absoluteString]) {
            [fileManager removeItemAtPath:filePath.absoluteString error:&error];
        }
        
        if (error) {
            DDLogError(@"Failed to remove bloomfilter with error: %@", error);
            return NO;
        }
        
        return YES;
    }
    
    NSError *error;
    [data writeToFile:filePath.absoluteString options:NSDataWritingAtomic error:&error];
    if (error) {
        DDLogError(@"Failed to store bloomfilter with error: %@", error);
        return NO;
    }
    
    return YES;
}

@end
