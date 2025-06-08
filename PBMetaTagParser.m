//
//  PBMetaTagParser.m
//  Pastie
//
//  Created by Tanner Bennett on 3/10/24.
//

#import <UIKit/UIKit.h>
#import "PBMetaTagParser.h"
#import "NSArray+Map.h"

@interface PBMetaTagParser ()

/// The raw underlying tags, used to later populate `ogTags`
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

- (id)description {
    return [NSString
        stringWithFormat:@"<PBMetaTagParser: %p\n\tsite: %@,\n\ttitle: %@,\n\turl: %@,\n\timage: %@,\n\tdesc: %@>",
        self, self.site, self.title, self.url, self.image, self.desc
    ];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
    attributes:(NSDictionary<NSString *,NSString *> *)attributes {
    if ([elementName isEqualToString:@"meta"] && [attributes[@"property"] hasPrefix:@"og:"]) {
        [self.metaTags addObject:attributes];
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    // Not sure why this would be needed twice...
    NSArray *ogTags = [self.metaTags pastie_filtered:^BOOL(NSDictionary *attrs, NSUInteger idx) {
        return [attrs[@"property"] hasPrefix:@"og:"];
    }];
    
    // Pull the content out of the tag
    NSMutableDictionary *ogDict = [NSMutableDictionary new];
    for (NSDictionary *tag in ogTags) {
        ogDict[tag[@"property"]] = [self unescapedTagContent:tag[@"content"]];
    }
    
    _ogTags = ogDict;
    [self populateTagProperties];
}

- (NSString *)unescapedTagContent:(NSString *)content {
    NSParameterAssert(content);
    
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *options = @{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc]
        initWithData:data options:options documentAttributes:nil error:nil
    ];

    NSString *decodedString = attributedString.string;
    return decodedString;
}

- (void)populateTagProperties {
    _site = self.ogTags[@"og:site_name"];
    _title = self.ogTags[@"og:title"];
    _url = self.ogTags[@"og:url"];
    _image = self.ogTags[@"og:image"];
    _desc = self.ogTags[@"og:description"];
    
    // _url = [self cleanedURL:_url];
}

- (NSString *)cleanedURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Strip query parameters from these domains
    NSArray<NSString *> *stripDomains = @[
        @"tiktok.com"
    ];
    
    for (NSString *domain in stripDomains) {
        if ([url.host hasSuffix:domain]) {
            // Use URLComponents to strip the query
            NSURLComponents *components = [NSURLComponents
                componentsWithURL:url resolvingAgainstBaseURL:NO
            ];
            components.query = nil;
            return components.URL.absoluteString;
        }
    }
    
    return urlString;
}

+ (void)fetchMetaTagsForURL:(NSURL *)url completion:(void(^)(PBMetaTagParser *parser, NSError *error))callback {
    NSParameterAssert(url); NSParameterAssert(callback);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = @{
        @"User-Agent": @"facebookexternalhit/1.1"
    };

    NSURLSessionDataTask *task = [NSURLSession.sharedSession
        dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(nil, error);
                });
            } else {
                NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
                PBMetaTagParser *parser = [PBMetaTagParser new];
                xmlParser.delegate = parser;
                
                if (![xmlParser parse]) {
                    [parser parserDidEndDocument:xmlParser];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(parser, nil);
                });
            }
        }
    ];
    
    [task resume];
}

@end
