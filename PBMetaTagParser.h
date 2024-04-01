//
//  PBMetaTagParser.h
//  Pastie
//
//  Created by Tanner Bennett on 3/10/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PBMetaTagParser : NSObject <NSXMLParserDelegate>

@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *ogTags;

@end

NS_ASSUME_NONNULL_END
