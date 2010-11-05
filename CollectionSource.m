//
//  CollectionSource.m
//  CollectionTest
//
//  Created by Joachim Fornallaz on 24.09.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import "CollectionSource.h"
#import "ResourceLoader.h"


@implementation CollectionSource

@synthesize queue, title, imageDict, itemList, preliminary, resourceCache, delegate;

#pragma mark -
#pragma mark Object lifecycle

- (id)initWithFeedURL:(NSURL *)feedURL
{
	self = [super init];
	if (self != nil) {
		self.itemList = [NSArray array];
		sourceURL = [feedURL copy];
	}
	return self;
}

- (void)dealloc
{
	[resourceLoader stopLoading];
	self.itemList = nil;
	[sourceURL release];
	[super dealloc];
}

#pragma mark -
#pragma mark Instance methods

- (void)sync
{
	if ([sourceURL isFileURL]) {
		//	<#statements#>
	} else {
		NSData *data = [ResourceLoader dataForURL:sourceURL delegate:self preliminary:NO resourceCache:self.resourceCache];
		if (data) {
			preliminary = YES;
			[self parseData:data];
		}
	}
}

- (void)parseData:(NSData *)data
{
	self.queue = [[NSOperationQueue alloc] init];
	FeedParseOperation *parser = [[FeedParseOperation alloc] initWithData:data delegate:self];
	parser.elementsToParse = [NSArray arrayWithObjects:@"title", @"enclosure", nil];
	[self.queue addOperation:parser]; // this will start the "ParseOperation"
	[parser release];
}

#pragma mark -
#pragma mark ResourceLoaderDelegate methods

- (BOOL)resourceLoader:(ResourceLoader *)loader shouldStartLoadWithRequest:(NSURLRequest *)request
{
	resourceLoader = loader;
	return YES;
}

- (void)resourceLoaderDidFinishLoadingData:(NSData *)data withMIMEType:(NSString *)MIMEType
{
	preliminary = NO;
	resourceLoader = nil;
    [self parseData:data];
}

- (void)resourceLoaderDidReturnNotModifiedData
{
	preliminary = NO;
	resourceLoader = nil;
	[self.delegate collectionSourceDidRefresh:self];
}

- (void)resourceLoaderDidFailLoad
{
	resourceLoader = nil;
	[self.delegate collectionSourceRefreshDidFail:self];
}

#pragma mark -
#pragma mark FeedParseOperationDelegate methods

- (id)objectForElement:(NSString *)elementName text:(NSString *)nodeText attributes:(NSDictionary *)attributeDict
{
	id object = nil;
	if ([elementName isEqualToString:@"enclosure"]) {
		object = [attributeDict objectForKey:@"url"];
	}
	return object;
}

- (void)didFinishParsing:(NSArray *)anItemList title:(NSString *)aTitle image:(NSDictionary *)anImageDict
{
	self.title = aTitle;
	self.imageDict = anImageDict;
	self.itemList = anItemList;
	[self.delegate collectionSourceDidRefresh:self];
}

- (void)parseErrorOccurred:(NSError *)error
{
	[self.delegate collectionSourceRefreshDidFail:self];
}

@end
