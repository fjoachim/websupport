//
//  ResourceLoader.m
//  CollectionTest
//
//  Created by Joachim Fornallaz on 25.09.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import "ResourceLoader.h"


@interface ResourceLoader ()

@property (nonatomic, copy) NSURL *responseURL;
@property (nonatomic, copy) NSString *responseEtag;
@property (nonatomic, copy) NSString *responseContentType;
@property (nonatomic, retain) NSMutableData *responseData;

@end


@implementation ResourceLoader

@synthesize responseFormat, resourceCache, delegate;
@synthesize responseURL, responseEtag, responseContentType, responseData;

#pragma mark -
#pragma mark Class methods

+ (NSData *)dataForURL:(NSURL *)dataURL delegate:(id<ResourceLoaderDelegate>)delegate preliminary:(BOOL)preliminary resourceCache:(ResourceCache *)resourceCache
{
	ResourceLoader *loader = [[[ResourceLoader alloc] init] autorelease];
	loader.resourceCache = resourceCache;
	loader.delegate = delegate;
	return [loader dataForURL:dataURL preliminary:preliminary];
}

+ (UIImage *)imageForURL:(NSURL *)imageURL delegate:(id<ResourceLoaderDelegate>)delegate preliminary:(BOOL)preliminary resourceCache:(ResourceCache *)resourceCache
{
	ResourceLoader *loader = [[[ResourceLoader alloc] init] autorelease];
	loader.responseFormat = ResourceLoaderResponseFormatImage;
	loader.resourceCache = resourceCache;
	loader.delegate = delegate;
	return [loader imageForURL:imageURL preliminary:preliminary];
}

#pragma mark -
#pragma mark Object lifecycle

- (id)init
{
	self = [super init];
	if (self != nil) {
		responseFormat = ResourceLoaderResponseFormatData;
	}
	return self;
}

- (void)dealloc
{
	self.responseContentType = nil;
	self.responseData = nil;
	self.responseURL = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Instance methods

- (void)loadRequest:(NSURLRequest *)request
{
	[self retain];
	[NSURLConnection connectionWithRequest:request delegate:self];
}

- (UIImage *)imageForURL:(NSURL *)imageURL preliminary:(BOOL)preliminary
{
	NSData *imageData = [self dataForURL:imageURL preliminary:preliminary];
	return [UIImage imageWithData:imageData];
}

- (NSData *)dataForURL:(NSURL *)dataURL preliminary:(BOOL)preliminary
{
	NSLog(@"%@ dataForURL:%@ preliminary:%d", self, dataURL, preliminary);
	NSString *etag = nil;
	NSData *data = [self.resourceCache dataForURL:dataURL preliminary:preliminary etag:&etag];
	
	if (!preliminary) {
		if (data == nil) {
			[self loadRequest:[NSURLRequest requestWithURL:dataURL]];
		} else {
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:dataURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
			[request addValue:etag forHTTPHeaderField:@"If-None-Match"];
			[self loadRequest:request];
		}		
	}
		
	return data;
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.responseURL = [response URL];
	self.responseContentType = [response MIMEType];
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
		httpResponseStatusCode = [httpResponse statusCode];
		NSDictionary *headers = [httpResponse allHeaderFields];
		self.responseEtag = [headers objectForKey:@"Etag"];
	//	NSLog(@"%@ got etag: %@", self, self.responseEtag);
	}
	long long contentLength = [response expectedContentLength];
	if (contentLength == NSURLResponseUnknownLength) {
		contentLength = 50000;
	}
	self.responseData = [NSMutableData dataWithCapacity:(NSUInteger)contentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (httpResponseStatusCode >= 200 && httpResponseStatusCode < 300) {
		[self.resourceCache setData:self.responseData forURL:self.responseURL etag:self.responseEtag];
		if (self.delegate) {
			if (self.responseFormat == ResourceLoaderResponseFormatImage && [self.delegate respondsToSelector:@selector(resourceLoaderDidFinishLoadingImage:)]) {
				UIImage *image = [UIImage imageWithData:self.responseData];
				if (image) {
					[self.delegate resourceLoaderDidFinishLoadingImage:image];
				} else {
					[self.delegate resourceLoaderDidFailLoad];
				}
			} else {
				[self.delegate resourceLoaderDidFinishLoadingData:self.responseData withMIMEType:self.responseContentType];
			}
		}
	} else if (httpResponseStatusCode == 304) {
		[self.delegate resourceLoaderDidReturnNotModifiedData];
	} else {
		NSLog(@"%@ httpResponseStatusCode: %d", self, httpResponseStatusCode);
	}

	[self release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self.delegate resourceLoaderDidFailLoad];
	[self release];
}

@end
