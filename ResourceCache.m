//
//  ResourceCache.m
//  CollectionTest
//
//  Created by Joachim Fornallaz on 30.09.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import "ResourceCache.h"
#import "NSURL+CoreSupport.h"
#import <sys/xattr.h>


@implementation ResourceCache

+ (ResourceCache *)cacheWithIdentifier:(NSString *)anIdentifier
{
	return [[[ResourceCache alloc] initWithIdentifier:anIdentifier] autorelease];
}

+ (NSString *)cachesDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}

#pragma mark -
#pragma mark Object lifecycle

- (id)initWithIdentifier:(NSString *)anIdentifier
{
	self = [super init];
	if (self != nil) {
		identifier = [anIdentifier copy];
	}
	return self;
}

- (void)dealloc
{
	[directoryContents release];
	[identifier release];
	[super dealloc];
}

#pragma mark -
#pragma mark Private methods

- (NSString *)cachedDataDirectoryPath
{
	return [NSString pathWithComponents:[NSArray arrayWithObjects:[ResourceCache cachesDirectory], identifier, nil]];
}

- (NSString *)cachedDataPathForURL:(NSURL *)anURL
{
	return [[self cachedDataDirectoryPath] stringByAppendingPathComponent:[anURL md5HexDigest]];
}

- (void)setExtendedAttributes:(NSDictionary *)attributes forFileAtPath:(NSString *)path
{
	for (NSString *key in attributes) {
		NSString *string = [attributes objectForKey:key];
		NSData *value = [string dataUsingEncoding:NSUTF8StringEncoding];
		setxattr([path UTF8String], [key UTF8String], [value bytes], [value length], 0, 0);
	}
}

- (NSDictionary *)extendedAttributesForFileAtPath:(NSString *)path
{
	NSMutableArray *keys = [NSMutableArray arrayWithCapacity:1];
	// Find all extended attribute keys
	ssize_t size = listxattr([path UTF8String], NULL, 0, 0);
	if (size > 0) {
		char *characters = malloc(size);
		listxattr([path UTF8String], characters, size, 0);
		BOOL foundNullCharacter = YES;
		for (int i = 0; i < size; i++) {
			if (foundNullCharacter) {
				foundNullCharacter = NO;
				[keys addObject:[NSString stringWithCString:&(characters[i]) encoding:NSUTF8StringEncoding]];
			}
			if (characters[i] == 0x00) {
				foundNullCharacter = YES;
			}
		}
		free(characters);
	}
	// Find all key values
	NSMutableArray *values = [NSMutableArray arrayWithCapacity:[keys count]];
	for (NSString *key in keys) {
		size_t valueSize = getxattr([path UTF8String], [key UTF8String], NULL, 0, 0, 0);
		char *bytes = malloc(valueSize);
		getxattr([path UTF8String], [key UTF8String], bytes, valueSize, 0, 0);
		[values addObject:[NSData dataWithBytes:bytes length:valueSize]];
		free(bytes);
	}
	return [NSDictionary dictionaryWithObjects:values forKeys:keys];
}

#pragma mark -
#pragma mark Instance methods

- (void)setData:(NSData *)data forURL:(NSURL *)anURL etag:(NSString *)etag
{
	NSString *cachedDataPath = [self cachedDataPathForURL:anURL];
	NSString *cachedDataDirectoryPath = [cachedDataPath stringByDeletingLastPathComponent];
	if (![[NSFileManager defaultManager] fileExistsAtPath:cachedDataDirectoryPath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:cachedDataDirectoryPath withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	[data writeToFile:cachedDataPath atomically:NO];
	[self setExtendedAttributes:[NSDictionary dictionaryWithObject:etag forKey:@"resourceLoaderEtag"] forFileAtPath:cachedDataPath];
}

- (NSData *)dataForURL:(NSURL *)anURL preliminary:(BOOL)preliminary etag:(NSString **)etagRef
{
	if (!preliminary) {
		[directoryContents removeObject:[anURL md5HexDigest]];
	}
	NSData *data = nil;
	NSString *cachedDataPath = [self cachedDataPathForURL:anURL];
	if ([[NSFileManager defaultManager] fileExistsAtPath:cachedDataPath]) {
		NSData *etagData = [[self extendedAttributesForFileAtPath:cachedDataPath] objectForKey:@"resourceLoaderEtag"];
		NSString *etag = [[[NSString alloc] initWithData:etagData encoding:NSUTF8StringEncoding] autorelease];
		data = [NSData dataWithContentsOfFile:cachedDataPath];
		if (data && etagRef) {
			*etagRef = etag;
		}
	}
	return data;
}

- (void)beginLoading
{
	[directoryContents release];
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self cachedDataDirectoryPath] error:NULL];
	directoryContents = [contents mutableCopy];
//	NSLog(@">>> directoryContents:%@", directoryContents);
}

- (void)endLoading
{
//	NSLog(@"<<< directoryContents:%@", directoryContents);
	for (NSString *fileName in directoryContents) {
		NSString *filePath = [[self cachedDataDirectoryPath] stringByAppendingPathComponent:fileName];
		[[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
	}
}

@end
