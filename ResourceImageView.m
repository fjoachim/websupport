//
//  ResourceImageView.m
//  CollectionTest
//
//  Created by Joachim Fornallaz on 04.10.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import "ResourceImageView.h"


@implementation ResourceImageView

@synthesize preliminary, resourceCache;

#pragma mark -
#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame URL:(NSURL *)anImageURL preliminary:(BOOL)isPreliminary resourceCache:(ResourceCache *)aResourceCache
{
    if ((self = [super initWithFrame:frame])) {
		self.resourceCache = aResourceCache;
        self.preliminary = isPreliminary;
		self.imageURL = anImageURL;
    }
    return self;
}

- (void)dealloc
{
	[resourceLoader stopLoading];
    [super dealloc];
}

#pragma mark -
#pragma mark Accessor methods

- (void)setImageURL:(NSURL *)anImageURL
{
	[imageURL release];
	imageURL = [anImageURL retain];
	self.image = [ResourceLoader imageForURL:anImageURL delegate:self preliminary:self.preliminary resourceCache:self.resourceCache];
}

- (NSURL *)imageURL
{
	return imageURL;
}

#pragma mark -
#pragma mark ResourceLoaderDelegate methods

- (BOOL)resourceLoader:(ResourceLoader *)loader shouldStartLoadWithRequest:(NSURLRequest *)request
{
	resourceLoader = loader;
	return YES;
}

- (void)resourceLoaderDidFinishLoadingImage:(UIImage *)anImage
{
	resourceLoader = nil;
	self.image = anImage;
}

- (void)resourceLoaderDidReturnNotModifiedData
{
	resourceLoader = nil;	
}

- (void)resourceLoaderDidFailLoad
{
	resourceLoader = nil;	
}

@end
