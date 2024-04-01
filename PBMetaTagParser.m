//
//  PBMetaTagParser.m
//  Pastie
//
//  Created by Tanner Bennett on 3/10/24.
//

#import "PBMetaTagParser.h"
#import "NSArray+Map.h"

@interface PBMetaTagParser ()

@property (nonatomic) NSMutableArray<NSDictionary *> *metaTags;

@end

@implementation PBMetaTagParser

- (instancetype)init {
    self = [super init];
    if (self) {
        _metaTags = [NSMutableArray new];
    }
    return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
    attributes:(NSDictionary<NSString *,NSString *> *)attributes {
    if ([elementName isEqualToString:@"meta"] && [attributes[@"property"] hasPrefix:@"og:"]) {
        [self.metaTags addObject:attributes];
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    NSArray *ogTags = [self.metaTags pastie_filtered:^BOOL(NSDictionary *attrs, NSUInteger idx) {
        return [attrs[@"property"] hasPrefix:@"og:"];
    }];
    
    NSMutableDictionary *ogDict = [NSMutableDictionary new];
    for (NSDictionary *tag in ogTags) {
        ogDict[tag[@"property"]] = tag[@"content"];
    }
    
    _ogTags = ogDict;
}

@end
