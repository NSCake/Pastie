//
//  PBURLPaste.h
//  Pastie
//  
//  Created on 2025-06-08
//  Copyright © 2025 Tanner Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Represents a URL paste entry from the database
@interface PBURLPaste : NSObject

/// The originally copied URL.
@property (nonatomic, readonly) NSString *originalURL;
/// The result of a redirect from the original URL, or the original URL, if no redirect occurred.
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly, nullable) NSString *domain;
@property (nonatomic, readonly, nullable) NSString *title;
@property (nonatomic, readonly, nullable) NSDate *dateLastCopied;
@property (nonatomic, readonly) NSDate *dateAdded;

/// Create a URL paste from database row data
+ (instancetype)url:(NSString *)originalURL
        resolvedURL:(nullable NSString *)resolvedURL
             domain:(nullable NSString *)domain
              title:(nullable NSString *)title
     dateLastCopied:(nullable NSDate *)dateLastCopied
          dateAdded:(NSDate *)dateAdded;

/// Create a URL paste from a URL and optional title
+ (instancetype)pasteWithURL:(NSURL *)url title:(nullable NSString *)title;

@end

NS_ASSUME_NONNULL_END
