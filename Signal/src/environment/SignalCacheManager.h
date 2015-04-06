//
//  SignalCacheManager.h
//  Signal
//
//  Created by Frederic Jacobs on 05/04/15.
//  Copyright (c) 2015 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheObjectPath:NSURL

+ (NSString*)cacheFolderPath;

@end

@interface SignalCacheManager : NSObject

MacrosSingletonInterface

#pragma mark Bloom filter
- (NSData*)tryRetrieveBloomFilter;
- (void)storeBloomfilter:(NSData*)bloomFilterData;

#pragma mark Video processing cache
- (NSData*)retrieveAndClearVideoTemp;
- (NSURL*)tempVideoStorageURL;

#pragma mark Audio recording
- (NSURL*)audioRecordPath;
- (void)cancelAudioRecording;
- (NSData*)retrieveAudioTempAndCancel;

@end
