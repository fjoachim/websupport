//
//  ResourceCache.h
//  CollectionTest
//
//  Created by Joachim Fornallaz on 30.09.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ResourceCache : NSObject {
	NSString *identifier;
	NSMutableArray *directoryContents;
}

- (id)initWithIdentifier:(NSString *)anIdentifier;
- (void)setData:(NSData *)data forURL:(NSURL *)anURL etag:(NSString *)etag;
- (NSData *)dataForURL:(NSURL *)anURL preliminary:(BOOL)preliminary etag:(NSString **)etagRef;
- (void)beginLoading;
- (void)endLoading;

@end
