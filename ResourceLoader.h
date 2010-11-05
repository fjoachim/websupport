//
//  ResourceLoader.h
//  CollectionTest
//
//  Created by Joachim Fornallaz on 25.09.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResourceCache.h"


typedef enum {
	ResourceLoaderResponseFormatData,
	ResourceLoaderResponseFormatImage
} ResourceLoaderResponseFormat;

@protocol ResourceLoaderDelegate;

@interface ResourceLoader : NSObject {
	NSURL *responseURL;
	NSString *responseEtag;
	NSString *responseContentType;
	NSInteger httpResponseStatusCode;
    NSMutableData *responseData;
	NSURLConnection *URLConnection;
	ResourceLoaderResponseFormat responseFormat;
	ResourceCache *resourceCache;
	id<ResourceLoaderDelegate> delegate;
}

@property (nonatomic, assign) id<ResourceLoaderDelegate> delegate;
@property (nonatomic, assign) ResourceLoaderResponseFormat responseFormat;
@property (nonatomic, retain) ResourceCache *resourceCache;

+ (NSData *)dataForURL:(NSURL *)dataURL delegate:(id<ResourceLoaderDelegate>)delegate  preliminary:(BOOL)preliminary resourceCache:(ResourceCache *)resourceCache;
+ (UIImage *)imageForURL:(NSURL *)imageURL delegate:(id<ResourceLoaderDelegate>)delegate preliminary:(BOOL)preliminary resourceCache:(ResourceCache *)resourceCache;
- (void)loadRequest:(NSURLRequest *)request;
- (void)stopLoading;
- (NSData *)dataForURL:(NSURL *)dataURL preliminary:(BOOL)preliminary;
- (UIImage *)imageForURL:(NSURL *)imageURL preliminary:(BOOL)preliminary;

@end


@protocol ResourceLoaderDelegate <NSObject>

- (BOOL)resourceLoader:(ResourceLoader *)loader shouldStartLoadWithRequest:(NSURLRequest *)request;
- (void)resourceLoaderDidFailLoad;
- (void)resourceLoaderDidReturnNotModifiedData;

@optional

- (void)resourceLoaderDidFinishLoadingData:(NSData *)data withMIMEType:(NSString *)MIMEType;
- (void)resourceLoaderDidFinishLoadingImage:(UIImage *)image;

@end
