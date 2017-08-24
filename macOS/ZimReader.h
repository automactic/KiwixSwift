//
//  ZimReader.h
//  KiwixTest
//
//  Created by Chris Li on 8/1/14.
//  Copyright (c) 2014 Chris. All rights reserved.
//
//  This is the wrapper class that converts all C++ functions in reader.h to Objective-C methods

#import <Foundation/Foundation.h>

@interface ZimReader : NSObject

- (instancetype)initWithZIMFileURL:(NSURL *)url;
@property (strong, nonatomic) NSURL *fileURL;
@property (strong, nonatomic) NSURL *idxFolderURL;

#pragma mark - index
- (BOOL)hasIndex;

#pragma mark - validation
- (BOOL)isCorrupted;

#pragma mark - getData
- (NSDictionary *)dataWithContentURLString:(NSString *)contentURLString;

#pragma mark - getURLs
- (NSString *)pageURLFromTitle:(NSString *)title;//Will return nil if there is no such page with the specific title
- (NSString *)mainPageURL;//Will return nil if the zim file have no main page, not sure if this will ever happen(Does every zim file have a main page?)
- (NSString *)getRandomPageUrl;

#pragma mark - search
- (NSArray *)searchSuggestionsSmart:(NSString *)searchTerm;
- (NSArray *)searchUsingIndex:(NSString *)searchTerm;

#pragma mark - get meta data
- (NSString *)getArticleCount;
- (NSString *)getMediaCount;
- (NSString *)getGlobalCount;

- (NSString *)getID;
- (NSString *)getTitle;
- (NSString *)getDesc;
- (NSString *)getLanguage;
- (NSString *)getName;
- (NSString *)getTags;
- (NSString *)getDate;
- (NSString *)getCreator;
- (NSString *)getPublisher;
- (NSString *)getOriginID;
- (NSString *)getFileSize;
- (NSString *)getFavicon;

- (NSString *)parseURL:(NSString *)urlPath;

- (void)dealloc;

- (NSURL *)fileURL;

+ (NSInteger)levenshtein:(NSString *)string anotherString:(NSString *)anotherString;

@end
