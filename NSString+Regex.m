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
    return [self rangeOfString:regex options:NSRegularExpressionSearch].location != NSNotFound;
}

@end
