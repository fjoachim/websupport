//
//  CollectionSource.h
//  CollectionTest
//
//  Created by Joachim Fornallaz on 24.09.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResourceLoader.h"
#import "FeedParseOperation.h"


@protocol CollectionSourceDelegate;

@interface CollectionSource : NSObject <ResourceLoaderDelegate, FeedParseOperationDelegate> {
    NSOperationQueue *queue;
	NSDictionary *imageDict;
	NSArray *itemList;
	NSURL *sourceURL;
	BOOL preliminary;
	ResourceCache *resourceCache;
	id<CollectionSourceDelegate> delegate;
}

@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) NSDictionary *imageDict;
@property (nonatomic, retain) NSArray *itemList;
@property (nonatomic, retain) ResourceCache *resourceCache;
@property (nonatomic, readonly) BOOL preliminary;
@property (nonatomic, assign) id<CollectionSourceDelegate> delegate;

- (id)initWithFeedURL:(NSURL *)feedURL;
- (void)parseData:(NSData *)data;
- (void)sync;

@end


@protocol CollectionSourceDelegate <NSObject>

- (void)collectionSourceDidRefresh:(CollectionSource *)collectionSource;
- (void)collectionSourceRefreshDidFail:(CollectionSource *)collectionSource;

@end
