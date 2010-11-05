//
//  ResourceImageView.h
//  CollectionTest
//
//  Created by Joachim Fornallaz on 04.10.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ResourceCache.h"
#import "ResourceLoader.h"


@interface ResourceImageView : UIImageView <ResourceLoaderDelegate> {
	NSURL *imageURL;
	BOOL preliminary;
	ResourceCache *resourceCache;	
	ResourceLoader *resourceLoader;
}

@property (nonatomic, copy) NSURL *imageURL;
@property (nonatomic, assign) BOOL preliminary;
@property (nonatomic, retain) ResourceCache *resourceCache;

- (id)initWithFrame:(CGRect)frame URL:(NSURL *)theURL preliminary:(BOOL)preliminary resourceCache:(ResourceCache *)cache;

@end
