//
//  ZimFileService.mm
//  Kiwix
//
//  Created by Chris Li on 8/17/17.
//  Copyright © 2017-2022 Chris Li. All rights reserved.
//

#include <set>
#include <unordered_map>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "kiwix/book.h"
#include "zim/archive.h"
#include "zim/entry.h"
#include "zim/error.h"
#include "zim/item.h"
#pragma clang diagnostic pop

#import "ZimFileService.h"
#import "ZimFileMetaData.h"

struct SharedReaders {
    NSArray *readerIDs;
    std::vector<std::shared_ptr<kiwix::Reader>> readers;
    std::vector<zim::Archive> archives;
};

@interface ZimFileService ()

@property (assign) std::unordered_map<std::string, std::shared_ptr<zim::Archive>> *archives;
@property (strong) NSMutableDictionary *fileURLs; // [NSUUID: URL]

@end

@implementation ZimFileService

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        self.archives = new std::unordered_map<std::string, std::shared_ptr<zim::Archive>>();
        self.fileURLs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (ZimFileService *)sharedInstance {
    static ZimFileService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ZimFileService alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc {
    delete self.archives;
    for (NSUUID *zimFileID in self.fileURLs) {
        [self.fileURLs[zimFileID] stopAccessingSecurityScopedResource];
    }
}

#pragma mark - Reader Management

- (void)open:(NSURL *)url {
    try {
        // if url does not ends with "zim", skip it
        NSString *pathExtension = [[url pathExtension] lowercaseString];
        if (![pathExtension isEqualToString:@"zim"]) {
            return;
        }
        
        // if we have previously added this url, skip it
        if ([[self.fileURLs allKeysForObject:url] count] > 0) {
            return;
        }

        // add the archive
        [url startAccessingSecurityScopedResource];
        std::shared_ptr<zim::Archive> archive = std::make_shared<zim::Archive>([url fileSystemRepresentation]);
        self.archives->insert(std::make_pair(std::string(archive->getUuid()), archive));
        
        // store file URL
        NSUUID *zimFileID = [[NSUUID alloc] initWithUUIDBytes:(unsigned char *)archive->getUuid().data];
        self.fileURLs[zimFileID] = url;
    } catch (std::exception) {
        NSLog(@"Error opening zim file.");
    }
}

- (void)close:(NSUUID *)zimFileID {
    self.archives->erase([[zimFileID UUIDString] cStringUsingEncoding:NSUTF8StringEncoding]);
    [self.fileURLs[zimFileID] stopAccessingSecurityScopedResource];
    [self.fileURLs removeObjectForKey:zimFileID];
}

- (NSArray *)getReaderIdentifiers {
    return [self.fileURLs allKeys];
}

- (struct SharedReaders)getSharedReaders:(nonnull NSSet *)identifiers {
    NSMutableArray *readerIDs = [[NSMutableArray alloc] initWithCapacity:[identifiers count]];
    auto archives = std::vector<zim::Archive>();
    
    for (NSString *identifier in identifiers) {
        try {
            auto archive = self.archives->at([identifier cStringUsingEncoding:NSUTF8StringEncoding]);
            [readerIDs addObject:identifier];
            archives.push_back(*archive);
        } catch (std::out_of_range) { }
    }
    
    struct SharedReaders sharedReaders;
    sharedReaders.readerIDs = readerIDs;
    sharedReaders.archives = archives;
    return sharedReaders;
}

# pragma mark - Metadata

- (ZimFileMetaData *)getMetaData:(NSUUID *)identifier {
    auto found = self.archives->find([[identifier UUIDString] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.archives->end()) {
        return nil;
    } else {
        kiwix::Book book = kiwix::Book();
        book.update(*found->second);
        return [[ZimFileMetaData alloc] initWithBook: &book];
    }
}

+ (ZimFileMetaData *)getMetaDataWithFileURL:(NSURL *)url {
    ZimFileMetaData *metaData = nil;
    [url startAccessingSecurityScopedResource];
    try {
        kiwix::Book book = kiwix::Book();
        book.update(zim::Archive([url fileSystemRepresentation]));
        metaData = [[ZimFileMetaData alloc] initWithBook: &book];
    } catch (std::exception e) { }
    [url stopAccessingSecurityScopedResource];
    return metaData;
}

# pragma mark - URL Handling

- (NSURL *)getFileURL:(NSUUID *)zimFileID {
    return self.fileURLs[zimFileID];
}

- (NSString *_Nullable)getRedirectedPath:(NSUUID *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath {
    auto found = self.archives->find([[zimFileID UUIDString] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.archives->end()) {
        return nil;
    }
    try {
        std::string contentPathC = [contentPath cStringUsingEncoding:NSUTF8StringEncoding];
        zim::Item item = found->second->getEntryByPath(contentPathC).getRedirect();
        return [NSString stringWithUTF8String:item.getPath().c_str()];
    } catch (std::exception) {
        return nil;
    }
}

- (NSString *)getMainPagePath:(NSUUID *)zimFileID {
    auto found = self.archives->find([[zimFileID UUIDString] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.archives->end()) {
        return nil;
    }
    try {
        zim::Entry entry = found->second->getMainEntry();
        return [NSString stringWithCString:entry.getPath().c_str() encoding:NSUTF8StringEncoding];
    } catch (std::exception) {
        return nil;
    }
}

- (NSString *)getRandomPagePath:(NSUUID *)zimFileID {
    auto found = self.archives->find([[zimFileID UUIDString] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.archives->end()) {
        return nil;
    }
    try {
        zim::Entry entry = found->second->getRandomEntry();
        return [NSString stringWithCString:entry.getPath().c_str() encoding:NSUTF8StringEncoding];
    } catch (std::exception) {
        return nil;
    }
}

- (NSDictionary *)getContent:(NSUUID *)zimFileID contentPath:(NSString *)contentPath {
    auto found = self.archives->find([[zimFileID UUIDString] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.archives->end()) {
        return nil;
    }
    try {
        zim::Entry entry = found->second->getEntryByPath([contentPath cStringUsingEncoding:NSUTF8StringEncoding]);
        zim::Item item = entry.getItem(entry.isRedirect());
        NSNumber *length = [NSNumber numberWithUnsignedLongLong:item.getSize()];
        NSData *data = [NSData dataWithBytes:item.getData().data() length:length.unsignedLongLongValue];
        NSString *mime = [NSString stringWithUTF8String:item.getMimetype().c_str()];
        return @{@"data": data, @"mime": mime, @"length": length};
    } catch (std::exception) {
        return nil;
    }
}

@end
