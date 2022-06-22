//
//  ZimFileService.h
//  Kiwix
//
//  Created by Chris Li on 8/17/17.
//  Copyright © 2017-2022 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZimFileMetaData.h"

@interface ZimFileService : NSObject

@property (nonatomic, strong) NSString *_Nonnull libkiwixVersion;
@property (nonatomic, strong) NSString *_Nonnull libzimVersion;

- (instancetype _Nonnull)init NS_REFINED_FOR_SWIFT;
+ (nonnull ZimFileService *)sharedInstance NS_REFINED_FOR_SWIFT;

#pragma mark - Reader Management

- (void)open:(NSURL *_Nonnull)url NS_REFINED_FOR_SWIFT;
- (void)close:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (NSArray *_Nonnull)getReaderIdentifiers NS_REFINED_FOR_SWIFT;
- (nonnull void *) getArchives;

# pragma mark - Metadata

- (nullable ZimFileMetaData *)getMetaData:(nonnull NSUUID *)zimFileID NS_REFINED_FOR_SWIFT;
- (nullable NSData *)getFavicon:(nonnull NSUUID *)zimFileID NS_REFINED_FOR_SWIFT;
+ (nullable ZimFileMetaData *)getMetaDataWithFileURL:(nonnull NSURL *)url NS_REFINED_FOR_SWIFT;

# pragma mark - URL Handling

- (NSURL *_Nullable)getFileURL:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (NSString *_Nullable)getRedirectedPath:(NSUUID *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath NS_REFINED_FOR_SWIFT;
- (NSString *_Nullable)getMainPagePath:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (NSString *_Nullable)getRandomPagePath:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (NSDictionary *_Nullable)getContent:(NSUUID *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath NS_REFINED_FOR_SWIFT;

@end
