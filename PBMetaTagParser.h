//
//  PBMetaTagParser.h
//  Pastie
//
//  Created by Tanner Bennett on 3/10/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PBMetaTagParser : NSObject <NSXMLParserDelegate>

+ (void)fetchMetaTagsForURL:(NSURL *)url completion:(void(^)(PBMetaTagParser *parser, NSError *error))callback;

@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *ogTags;

/// Such as "TikTok"
@property (nonatomic, readonly) NSString *site;
// Such as "TikTok · Some Creator"
@property (nonatomic, readonly) NSString *title;
/// The URL of the page
@property (nonatomic, readonly) NSString *url;
/// A thumbnail for the page; it may expire over time
@property (nonatomic, readonly) NSString *image;
/// A short description of the page
@property (nonatomic, readonly) NSString *desc;

@end

NS_ASSUME_NONNULL_END
