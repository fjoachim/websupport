//
//  ParseOperation.m
//  CollectionTest
//
//  Created by Joachim Fornallaz on 25.09.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import "FeedParseOperation.h"

static NSString *kImageStr   = @"image";
static NSString *kChannelStr = @"channel";
static NSString *kItemStr    = @"item";

@interface FeedParseOperation ()
@property (nonatomic, assign) id <FeedParseOperationDelegate> delegate;
@property (nonatomic, retain) NSData *dataToParse;
@property (nonatomic, copy) NSString *channelTitle;
@property (nonatomic, copy) NSString *channelDescription;
@property (nonatomic, retain) NSMutableDictionary *workingImage;
@property (nonatomic, retain) NSMutableArray *workingArray;
@property (nonatomic, retain) NSMutableDictionary *workingEntry;
@property (nonatomic, retain) NSMutableString *workingPropertyString;
@property (nonatomic, retain) NSDictionary *workingItemAttributes;
@property (nonatomic, assign) BOOL storingCharacterData;
- (void)notifyDidFinishParsing;
@end

@implementation FeedParseOperation

@synthesize elementsToParse;
@synthesize delegate, dataToParse, channelTitle, channelDescription, workingImage, workingArray, workingEntry, workingPropertyString, workingItemAttributes, storingCharacterData;

#pragma mark -
#pragma mark Object Lifecycle

- (id)initWithData:(NSData *)data delegate:(id <FeedParseOperationDelegate>)theDelegate
{
    self = [super init];
    if (self != nil)
    {
        self.dataToParse = data;
        self.delegate = theDelegate;
    }
    return self;
}

- (void)dealloc
{
    [dataToParse release];
    [workingEntry release];
    [workingPropertyString release];
	[workingItemAttributes release];
    [workingArray release];
	[workingImage release];
	[channelDescription release];
	[channelTitle release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark NSOperation methods

- (void)main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	self.workingArray = [NSMutableArray array];
    self.workingPropertyString = [NSMutableString string];
    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not
	// desirable because it gives less control over the network, particularly in responding to
	// connection errors.
    //
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:dataToParse];
	[parser setDelegate:self];
    [parser parse];
	
	if (![self isCancelled]) {
		[self performSelectorOnMainThread:@selector(notifyDidFinishParsing) withObject:nil waitUntilDone:YES];
    }
    
	self.channelTitle = nil;
	self.channelDescription = nil;
	self.workingImage = nil;
    self.workingArray = nil;
    self.workingPropertyString = nil;
    self.dataToParse = nil;
    
    [parser release];

	[pool release];
}

- (void)notifyDidFinishParsing
{
	[self.delegate didFinishParsing:self.workingArray title:self.channelDescription image:self.workingImage];
}

#pragma mark -
#pragma mark RSS processing

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:kItemStr])	{
        self.workingEntry = [NSMutableDictionary dictionaryWithCapacity:4];
    } else if ([elementName isEqualToString:kImageStr]) {
		inImageElement = YES;
		self.workingEntry = [NSMutableDictionary dictionaryWithCapacity:4];
	} else if ([elementName isEqualToString:kChannelStr]) {
		inChannelElement = YES;
	}
	
	if (self.workingEntry) {
		self.workingItemAttributes = attributeDict;
		if (inImageElement) {
			storingCharacterData = [[NSArray arrayWithObjects:@"url", @"title", @"link", @"width", @"height", @"description", nil] containsObject:elementName];
		} else {
			storingCharacterData = [elementsToParse containsObject:elementName];
		}
	} else if (inChannelElement) {
		storingCharacterData = [[NSArray arrayWithObjects:@"title", @"description", nil] containsObject:elementName];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	NSString *trimmedString = nil;
	if (storingCharacterData) {
		trimmedString = [workingPropertyString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[workingPropertyString setString:@""];  // clear the string for next time
	}
	
    if (self.workingEntry) {
        if (trimmedString) {
			id entryObject = [self.delegate objectForElement:elementName text:trimmedString attributes:self.workingItemAttributes];
			if (entryObject == nil) {
				entryObject = trimmedString;
			}
			[self.workingEntry setObject:entryObject forKey:elementName];
			storingCharacterData = NO;
        } else if ([elementName isEqualToString:kItemStr]) {
            [self.workingArray addObject:self.workingEntry];  
            self.workingEntry = nil;
		} else if ([elementName isEqualToString:kImageStr]) {
			self.workingImage = self.workingEntry;
			self.workingEntry = nil;
			inImageElement = NO;
		}
	} else if (trimmedString) {
		if ([elementName isEqualToString:@"title"]) {
			self.channelTitle = trimmedString;
		} else if ([elementName isEqualToString:@"description"]) {
			self.channelDescription = trimmedString;
		}
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (storingCharacterData) {
        [workingPropertyString appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [delegate parseErrorOccurred:parseError];
}

@end
