//
//  ParseOperation.m
//  CollectionTest
//
//  Created by Joachim Fornallaz on 25.09.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

@protocol FeedParseOperationDelegate;

@interface FeedParseOperation : NSOperation <NSXMLParserDelegate>
{
@private
    id <FeedParseOperationDelegate> delegate;
    
    NSData				*dataToParse;
    
    NSMutableDictionary *workingImage;
    NSMutableArray		*workingArray;
    NSMutableDictionary *workingEntry;
    NSMutableString		*workingPropertyString;
	NSDictionary		*workingItemAttributes;
    NSArray				*elementsToParse;
    BOOL				storingCharacterData;
	BOOL				inImageElement;
}

- (id)initWithData:(NSData *)data delegate:(id <FeedParseOperationDelegate>)theDelegate;

@property (nonatomic, retain) NSArray *elementsToParse;

@end

@protocol FeedParseOperationDelegate <NSObject>
- (id)objectForElement:(NSString *)elementName text:(NSString *)nodeText attributes:(NSDictionary *)attributeDict;
- (void)didFinishParsing:(NSArray *)itemList image:(NSDictionary *)imageDict;
- (void)parseErrorOccurred:(NSError *)error;
@end
