//
//  PBURLPaste.m
//  Pastie
//  
//  Created on 2025-06-08
//  Copyright © 2025 Tanner Bennett. All rights reserved.
//

#import "PBURLPaste.h"

@interface PBURLPaste ()

@end

@implementation PBURLPaste
    
+ (instancetype)url:(NSString *)originalURL
        resolvedURL:(nullable NSString *)resolvedURL
             domain:(nullable NSString *)domain
              title:(nullable NSString *)title
     dateLastCopied:(nullable NSDate *)dateLastCopied
          dateAdded:(NSDate *)dateAdded {
    PBURLPaste *paste = [PBURLPaste new];
    
    paste->_domain = domain;
    paste->_url = resolvedURL ?: originalURL;
    paste->_originalURL = originalURL;
    paste->_title = title;
    paste->_dateLastCopied = dateLastCopied;
    paste->_dateAdded = dateAdded;
    
    return paste;
}

+ (instancetype)pasteWithURL:(NSURL *)url title:(nullable NSString *)title {
    PBURLPaste *paste = [PBURLPaste new];
    
    paste->_url = url.absoluteString;
    paste->_domain = url.host;
    paste->_originalURL = url.absoluteString;
    paste->_title = title;
    
    NSDate *now = [NSDate date];
    paste->_dateLastCopied = now;
    paste->_dateAdded = now;
    
    return paste;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@", self.domain ?: @"URL", self.originalURL];
}

@end
