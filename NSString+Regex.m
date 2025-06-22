//
//  NSString+Regex.m
//  Pastie
//
//  Created by Tanner Bennett on 3/31/24.
//  
//

#import "NSString+Regex.h"

@implementation NSString (Regex)

- (BOOL)pastie_matches:(NSString *)regex {
    return [self pastie_matches:regex regex:YES];
}

- (BOOL)pastie_matches:(NSString *)stringOrPattern regex:(BOOL)regex {
    if (regex) {
        return [self rangeOfString:stringOrPattern options:NSRegularExpressionSearch].location != NSNotFound;
    }

    return [self localizedCaseInsensitiveContainsString:stringOrPattern];
}

@end
